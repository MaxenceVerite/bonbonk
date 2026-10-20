extends Node

## Gestionnaire d'état persistant & Comptes joueurs :
## - Chiffrement local AES-256 via SaveCipher
## - Architecture multi-profils (Profil Joueur & Profil Sandbox Dev)
## - Synchronisation Cloud offline-first avec résolution de conflits
## - Délégation modulaire aux services (DeckService, InventoryService, EconomyService)

const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")
const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")
const CloudSyncService = preload("res://scripts/core/account/cloud_sync_service.gd")
const DeckServiceScript = preload("res://scripts/core/account/deck_service.gd")
const InventoryServiceScript = preload("res://scripts/core/account/inventory_service.gd")
const EconomyServiceScript = preload("res://scripts/core/account/economy_service.gd")

const PROFILES_DIR: String = "user://profiles/"
const ACTIVE_PROFILE_FILE: String = "user://active_profile.cfg"

var current_profile: PlayerProfileScript = null
var active_profile_id: String = "main"

# Services spécialisés découplés
var inventory_service: RefCounted = null
var economy_service: RefCounted = null
var deck_service: RefCounted = null

# Propriétés avec accesseurs délégués au profil actif
var gold: int:
	get:
		return current_profile.gold if current_profile != null else 0
	set(val):
		if current_profile != null:
			current_profile.gold = val
			request_save()

var diamonds: int:
	get:
		return current_profile.diamonds if current_profile != null else 0
	set(val):
		if current_profile != null:
			current_profile.diamonds = val
			request_save()

var cards_inventory: Dictionary:
	get:
		return current_profile.cards_inventory if current_profile != null else {}
	set(val):
		if current_profile != null:
			current_profile.cards_inventory = val
			request_save()

var decks: Array:
	get:
		return current_profile.decks if current_profile != null else []
	set(val):
		if current_profile != null:
			current_profile.decks = val
			request_save()

var active_deck_index: int:
	get:
		return current_profile.active_deck_index if current_profile != null else 0
	set(val):
		if current_profile != null:
			current_profile.active_deck_index = val
			request_save()

# Boosters instanciés en mémoire
var available_boosters: Array[BoosterData] = []
var registered_card_defs: Dictionary = {} # id -> CandyCardData
var shop_catalog: Array[ShopItemData] = []

# Service Cloud Sync
var cloud_sync: Node = null
var _save_timer: Timer = null

func _init() -> void:
	deck_service = DeckServiceScript.new()
	inventory_service = InventoryServiceScript.new()
	economy_service = EconomyServiceScript.new()

func _ready() -> void:
	_init_save_timer()
	_init_cloud_service()
	_init_default_definitions()
	_init_shop_catalog()
	_init_profile_and_storage()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_to_disk()

func _init_save_timer() -> void:
	_save_timer = Timer.new()
	_save_timer.wait_time = 0.4
	_save_timer.one_shot = true
	_save_timer.timeout.connect(save_to_disk)
	add_child(_save_timer)

func _init_cloud_service() -> void:
	cloud_sync = CloudSyncService.new()
	add_child(cloud_sync)
	cloud_sync.sync_completed.connect(_on_cloud_sync_completed)
	cloud_sync.status_changed.connect(_on_cloud_status_changed)

func request_save() -> void:
	if _save_timer != null:
		_save_timer.start()

# ==============================================================================
# GESTION DES PROFILS & PERSISTANCE CHIFFRÉE
# ==============================================================================

func _init_profile_and_storage() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)

	# 1. Lire le dernier profil utilisé
	active_profile_id = _read_last_active_profile_id()

	# 2. Charger la sauvegarde chiffrée
	if not load_profile(active_profile_id):
		# Création d'un nouveau profil par défaut
		current_profile = PlayerProfileScript.create_default(active_profile_id, active_profile_id == "sandbox")
		save_to_disk()

	_sync_boosters_from_profile()
	_validate_decks()

	# 3. Tentative de synchronisation cloud transparente en tâche de fond (si non-sandbox)
	if active_profile_id != "sandbox":
		cloud_sync.sync_profile(current_profile)

func get_profile_path(p_id: String) -> String:
	return PROFILES_DIR + p_id + ".sav"

func save_to_disk() -> bool:
	if current_profile == null:
		return false

	_sync_boosters_to_profile()
	current_profile.last_saved_at = int(Time.get_unix_time_from_system())

	var path: String = get_profile_path(current_profile.profile_id)
	var success: bool = SaveCipher.save_encrypted_json(path, current_profile.to_dict())

	_write_last_active_profile_id(current_profile.profile_id)
	return success

func load_profile(p_id: String) -> bool:
	var path: String = get_profile_path(p_id)
	var data: Dictionary = SaveCipher.load_encrypted_json(path)
	if data.is_empty():
		return false

	current_profile = PlayerProfileScript.new()
	current_profile.from_dict(data)
	active_profile_id = p_id
	_sync_boosters_from_profile()
	_validate_decks()
	return true

func switch_profile(target_profile_id: String) -> void:
	if current_profile != null and current_profile.profile_id == target_profile_id:
		return

	# Sauvegarder l'état actuel avant bascule
	save_to_disk()

	active_profile_id = target_profile_id
	if not load_profile(active_profile_id):
		current_profile = PlayerProfileScript.create_default(active_profile_id, active_profile_id == "sandbox")
		save_to_disk()

	_sync_boosters_from_profile()
	_validate_decks()
	_write_last_active_profile_id(active_profile_id)

	# Émettre les signaux de rafraîchissement global
	EventBus.gold_changed.emit(gold, 0)
	EventBus.diamonds_changed.emit(diamonds, 0)
	EventBus.deck_changed.emit(active_deck_index)
	EventBus.profile_loaded.emit(active_profile_id)

	# Déclencher la synchro cloud si profil standard
	if active_profile_id != "sandbox":
		cloud_sync.sync_profile(current_profile)

func sync_cloud() -> void:
	if current_profile == null:
		return
	cloud_sync.sync_profile(current_profile)

func _on_cloud_sync_completed(merged: PlayerProfileScript) -> void:
	if current_profile != null and current_profile.profile_id == merged.profile_id:
		current_profile = merged
		_sync_boosters_from_profile()
		_validate_decks()
		save_to_disk()
		EventBus.gold_changed.emit(gold, 0)
		EventBus.diamonds_changed.emit(diamonds, 0)
		EventBus.deck_changed.emit(active_deck_index)
		EventBus.cloud_sync_completed.emit(true)

func _on_cloud_status_changed(status: int, message: String) -> void:
	var status_str: String = "IDLE"
	match status:
		1: status_str = "SYNCING"
		2: status_str = "SUCCESS"
		4: status_str = "OFFLINE"
		3: status_str = "ERROR"
	EventBus.cloud_sync_status_changed.emit(status_str, message)

func _read_last_active_profile_id() -> String:
	if FileAccess.file_exists(ACTIVE_PROFILE_FILE):
		var f: FileAccess = FileAccess.open(ACTIVE_PROFILE_FILE, FileAccess.READ)
		if f != null:
			var id_str: String = f.get_as_text().strip_edges()
			f.close()
			if not id_str.is_empty():
				return id_str
	return "main"

func _write_last_active_profile_id(p_id: String) -> void:
	var f: FileAccess = FileAccess.open(ACTIVE_PROFILE_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(p_id)
		f.close()

func _sync_boosters_to_profile() -> void:
	if current_profile == null:
		return
	var serialized: Array = []
	for b in available_boosters:
		serialized.append({
			"id": String(b.id),
			"display_name": b.display_name,
			"booster_type": b.booster_type,
			"min_gold": b.min_gold,
			"max_gold": b.max_gold
		})
	current_profile.available_boosters = serialized

func _sync_boosters_from_profile() -> void:
	available_boosters.clear()
	if current_profile == null:
		return
	for item in current_profile.available_boosters:
		var b: BoosterData = BoosterData.new()
		b.id = StringName(item.get("id", "classic_solo"))
		b.display_name = item.get("display_name", "Sachet")
		b.booster_type = item.get("booster_type", BoosterData.BoosterType.CLASSIC_SOLO)
		b.min_gold = item.get("min_gold", 40)
		b.max_gold = item.get("max_gold", 80)
		available_boosters.append(b)

# ==============================================================================
# OUTILS SANDBOX (DÉVELOPPEUR SANS BIDOUILLE DANS LE GAMEPLAY)
# ==============================================================================

func is_sandbox_active() -> bool:
	return active_profile_id == "sandbox"

func is_dev_account() -> bool:
	if is_sandbox_active():
		return true
	if current_profile != null and (current_profile.account_type == "sandbox" or current_profile.account_type == "dev"):
		return true
	return OS.is_debug_build()

func sandbox_unlock_all() -> void:
	if not is_sandbox_active():
		return
	for cid in registered_card_defs:
		if not cards_inventory.has(cid):
			cards_inventory[cid] = { "unlocked": true, "level": 1, "cards": 50 }
		else:
			cards_inventory[cid]["unlocked"] = true
			cards_inventory[cid]["cards"] = maxi(cards_inventory[cid].get("cards", 0), 50)
	save_to_disk()
	EventBus.deck_changed.emit(active_deck_index)

func sandbox_add_resources(gold_amount: int = 10000, dia_amount: int = 500) -> void:
	if not is_sandbox_active():
		return
	add_gold(gold_amount)
	add_diamonds(dia_amount)
	save_to_disk()

func sandbox_set_all_max_level(target_lvl: int = 5) -> void:
	if not is_sandbox_active():
		return
	for cid in registered_card_defs:
		if not cards_inventory.has(cid):
			cards_inventory[cid] = { "unlocked": true, "level": target_lvl, "cards": 20 }
		else:
			cards_inventory[cid]["unlocked"] = true
			cards_inventory[cid]["level"] = target_lvl
	save_to_disk()
	EventBus.deck_changed.emit(active_deck_index)

func sandbox_reset() -> void:
	if not is_sandbox_active():
		return
	current_profile = PlayerProfileScript.create_default("sandbox", true)
	_sync_boosters_from_profile()
	_validate_decks()
	save_to_disk()
	EventBus.gold_changed.emit(gold, 0)
	EventBus.diamonds_changed.emit(diamonds, 0)
	EventBus.deck_changed.emit(active_deck_index)

# ==============================================================================
# INITIALISATIONS DES DÉFINITIONS DE CARTES & BOUTIQUE
# ==============================================================================

func _init_default_definitions() -> void:
	registered_card_defs = CardCatalog.get_default_definitions()

func _init_shop_catalog() -> void:
	shop_catalog = ShopCatalog.get_default_catalog()

# ==============================================================================
# DÉLÉGATION ÉCONOMIE, INVENTAIRE & DECKS
# ==============================================================================

func get_unlocked_card_ids() -> Array[StringName]:
	return inventory_service.get_unlocked_card_ids(cards_inventory)

func add_gold(amount: int) -> void:
	economy_service.add_gold(amount, current_profile)
	request_save()

func spend_gold(amount: int) -> bool:
	var success: bool = economy_service.spend_gold(amount, current_profile)
	if success:
		request_save()
	return success

func add_diamonds(amount: int) -> void:
	economy_service.add_diamonds(amount, current_profile)
	request_save()

func spend_diamonds(amount: int) -> bool:
	var success: bool = economy_service.spend_diamonds(amount, current_profile)
	if success:
		request_save()
	return success

func record_game_results(final_score: int, waves_cleared: int, gold_earned: int) -> Dictionary:
	var res: Dictionary = economy_service.record_game_results(current_profile, final_score, waves_cleared, gold_earned)
	request_save()
	return res

func can_upgrade_card(card_id: StringName) -> bool:
	return inventory_service.can_upgrade_card(card_id, cards_inventory, registered_card_defs, gold)

func upgrade_card(card_id: StringName) -> bool:
	var success: bool = inventory_service.upgrade_card(card_id, cards_inventory, registered_card_defs, gold, spend_gold)
	if success:
		request_save()
	return success

func get_card_state(card_id: StringName) -> Dictionary:
	return inventory_service.get_card_state(card_id, cards_inventory, registered_card_defs, gold)

func purchase_item(item: ShopItemData, use_diamonds: bool) -> bool:
	var success: bool = economy_service.purchase_item(item, use_diamonds, current_profile, available_boosters, inventory_service)
	if success:
		request_save()
	return success

func apply_booster_rewards(result: Dictionary) -> void:
	economy_service.apply_booster_rewards(result, current_profile, inventory_service)
	request_save()

func _validate_decks() -> void:
	deck_service.validate_decks(decks)

func get_active_deck() -> Array:
	return deck_service.get_active_deck(decks, active_deck_index)

func set_active_deck(index: int) -> void:
	active_deck_index = deck_service.set_active_deck(index, decks.size())
	EventBus.deck_changed.emit(active_deck_index)
	request_save()

func set_card_in_deck(deck_idx: int, slot_idx: int, card_id: StringName) -> void:
	if deck_service.set_card_in_deck(deck_idx, slot_idx, card_id, decks):
		EventBus.deck_changed.emit(deck_idx)
		request_save()

func get_active_deck_balls() -> Array[StringName]:
	return deck_service.get_active_deck_balls(get_active_deck(), registered_card_defs)

func get_active_deck_bumpers() -> Array[StringName]:
	return deck_service.get_active_deck_bumpers(get_active_deck(), registered_card_defs)
