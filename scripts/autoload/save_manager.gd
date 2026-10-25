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
const ShopItemDataScript = preload("res://scripts/data/shop_item_data.gd")
const ShopSectionDataScript = preload("res://scripts/data/shop_section_data.gd")
const ShopCatalogScript = preload("res://scripts/data/shop_catalog.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

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

enum GameMode { CAMPAIGN, SURVIVAL }

# Mode de jeu actif et deck de survie dédié
var active_game_mode: String:
	get:
		return current_profile.active_game_mode if current_profile != null else "campaign"
	set(val):
		if current_profile != null and (val == "campaign" or val == "survival"):
			current_profile.active_game_mode = val
			request_save()

func is_campaign() -> bool:
	return active_game_mode == "campaign"

func is_survival() -> bool:
	return active_game_mode == "survival"

func set_game_mode(mode: GameMode) -> void:
	match mode:
		GameMode.CAMPAIGN:
			active_game_mode = "campaign"
		GameMode.SURVIVAL:
			active_game_mode = "survival"

var survival_deck: Array:
	get:
		return current_profile.survival_deck if current_profile != null else []
	set(val):
		if current_profile != null:
			current_profile.survival_deck = val
			request_save()

# Progression maximale débloquée en Campagne (persitée dans le profil)
var campaign_unlocked_world: int:
	get:
		return current_profile.campaign_unlocked_world if current_profile != null else 1
	set(val):
		if current_profile != null:
			current_profile.campaign_unlocked_world = val
			request_save()

var campaign_unlocked_level: int:
	get:
		return current_profile.campaign_unlocked_level if current_profile != null else 1
	set(val):
		if current_profile != null:
			current_profile.campaign_unlocked_level = val
			request_save()

# Sélection active de niveau en Campagne (session de jeu dans le menu)
var campaign_selected_world: int = 1
var campaign_selected_level: int = 1

var campaign_levels_data: Dictionary:
	get:
		return current_profile.campaign_levels_data if current_profile != null else {}
	set(val):
		if current_profile != null:
			current_profile.campaign_levels_data = val
			request_save()

# Boosters instanciés en mémoire
var available_boosters: Array[BoosterData] = []
var registered_card_defs: Dictionary = {} # id -> CandyCardData
var shop_catalog: Array = []
var shop_layout: Array = []

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
			"max_gold": b.max_gold,
			"min_diamonds": b.min_diamonds,
			"max_diamonds": b.max_diamonds
		})
	current_profile.available_boosters = serialized

func _sync_boosters_from_profile() -> void:
	available_boosters.clear()
	if current_profile == null:
		return
	for item in current_profile.available_boosters:
		var b: BoosterData = BoosterData.new()
		b.id = StringName(item.get("id", "silver_pop"))
		b.display_name = item.get("display_name", "Sachet Silver Pop")
		b.booster_type = item.get("booster_type", BoosterData.BoosterType.SILVER_POP)
		b.min_gold = item.get("min_gold", 50)
		b.max_gold = item.get("max_gold", 100)
		b.min_diamonds = item.get("min_diamonds", 0)
		b.max_diamonds = item.get("max_diamonds", 0)
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

func sandbox_add_featured_offer() -> void:
	for it in shop_catalog:
		if it.id == &"hero_daily_pack":
			return
	shop_catalog.insert(0, ShopCatalogScript.create_sample_featured_offer())
	EventBus.gold_changed.emit(gold, 0)

# ==============================================================================
# INITIALISATIONS DES DÉFINITIONS DE CARTES & BOUTIQUE
# ==============================================================================

func _init_default_definitions() -> void:
	registered_card_defs = CardCatalog.get_default_definitions()

func _init_shop_catalog() -> void:
	shop_catalog = ShopCatalogScript.get_default_catalog()
	shop_layout = ShopCatalogScript.get_default_layout()

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
	if current_profile != null:
		deck_service.validate_single_deck(current_profile.survival_deck)

func get_active_deck() -> Array:
	if current_profile == null:
		return []
	if is_survival():
		return current_profile.survival_deck
	return deck_service.get_active_deck(decks, active_deck_index)

func set_active_deck(index: int) -> void:
	active_deck_index = deck_service.set_active_deck(index, decks.size())
	EventBus.deck_changed.emit(active_deck_index)
	request_save()

func set_card_in_deck(deck_idx: int, slot_idx: int, card_id: StringName) -> void:
	if deck_service.set_card_in_deck(deck_idx, slot_idx, card_id, decks):
		EventBus.deck_changed.emit(deck_idx)
		request_save()

func set_card_in_active_deck(slot_idx: int, card_id: StringName) -> void:
	if is_survival():
		if current_profile != null and deck_service.set_card_in_survival_deck(slot_idx, card_id, current_profile.survival_deck):
			EventBus.deck_changed.emit(-1)
			request_save()
	else:
		set_card_in_deck(active_deck_index, slot_idx, card_id)

func get_active_deck_balls() -> Array[StringName]:
	return deck_service.get_active_deck_balls(get_active_deck(), registered_card_defs)

func get_active_deck_bumpers() -> Array[StringName]:
	return deck_service.get_active_deck_bumpers(get_active_deck(), registered_card_defs)

func record_campaign_level_results(level: LevelData, score: int, stars: int, _hp_left: int) -> Dictionary:
	if current_profile == null or level == null:
		return {}

	var lvl_id_str: String = String(level.id)
	var prev_data: Dictionary = current_profile.campaign_levels_data.get(lvl_id_str, {})
	var is_first_clear: bool = not prev_data.get("cleared", false)
	var prev_stars: int = int(prev_data.get("stars", 0))
	var prev_best: int = int(prev_data.get("best_score", 0))

	var new_stars: int = maxi(prev_stars, stars)
	var new_best: int = maxi(prev_best, score)

	current_profile.campaign_levels_data[lvl_id_str] = {
		"stars": new_stars,
		"best_score": new_best,
		"cleared": true
	}

	# Progression du niveau suivant si premier succès (palier maximal conservé)
	if is_first_clear and level.level_number >= current_profile.campaign_unlocked_level:
		current_profile.campaign_unlocked_level = level.level_number + 1

	campaign_selected_level = level.level_number + 1

	# Récompenses : Or de complétion (50 or + score/150)
	var gold_earned: int = 50 + int(score / 150)
	var diamonds_earned: int = 0
	if is_first_clear:
		gold_earned += level.first_clear_gold
		diamonds_earned += level.first_clear_diamonds
		if level.first_clear_booster_id != &"":
			award_booster_by_id(level.first_clear_booster_id)

	if gold_earned > 0:
		add_gold(gold_earned)
	if diamonds_earned > 0:
		add_diamonds(diamonds_earned)

	request_save()

	return {
		"level_id": level.id,
		"stars": stars,
		"score": score,
		"gold_earned": gold_earned,
		"diamonds_earned": diamonds_earned,
		"is_first_clear": is_first_clear,
		"is_new_record": score > prev_best,
		"unlocked_next_level": is_first_clear
	}

func record_campaign_defeat(level: LevelData, score: int, gold_earned: int) -> Dictionary:
	if current_profile == null or level == null:
		return {}

	var lvl_id_str: String = String(level.id)
	var prev_data: Dictionary = current_profile.campaign_levels_data.get(lvl_id_str, {})
	var prev_best: int = int(prev_data.get("best_score", 0))
	var is_new_record: bool = score > prev_best

	if is_new_record:
		if not current_profile.campaign_levels_data.has(lvl_id_str):
			current_profile.campaign_levels_data[lvl_id_str] = {
				"stars": 0,
				"best_score": score,
				"cleared": false
			}
		else:
			current_profile.campaign_levels_data[lvl_id_str]["best_score"] = score

	if gold_earned > 0:
		add_gold(gold_earned)

	request_save()

	return {
		"level_id": level.id,
		"score": score,
		"gold_earned": gold_earned,
		"is_new_record": is_new_record,
		"best_score": maxi(prev_best, score)
	}

func award_booster_by_id(b_id: StringName) -> void:
	var b_type: BoosterData.BoosterType = BoosterData.BoosterType.SILVER_POP
	var b_name: String = "Sachet Silver Pop"
	var min_g: int = 50
	var max_g: int = 100
	var min_d: int = 0
	var max_d: int = 0

	match b_id:
		&"golden_crush":
			b_type = BoosterData.BoosterType.GOLDEN_CRUSH
			b_name = "Sachet Golden Crush"
			min_g = 180
			max_g = 350
		&"diamond_dust":
			b_type = BoosterData.BoosterType.DIAMOND_DUST
			b_name = "Sachet Diamond Dust"
			min_g = 600
			max_g = 1200
			min_d = 5
			max_d = 10
		&"mystery_mix":
			b_type = BoosterData.BoosterType.MYSTERY_MIX
			b_name = "Sachet Mystery Mix"
			min_g = 100
			max_g = 500

	var b: BoosterData = BoosterData.new()
	b.id = b_id
	b.display_name = b_name
	b.booster_type = b_type
	b.min_gold = min_g
	b.max_gold = max_g
	b.min_diamonds = min_d
	b.max_diamonds = max_d
	available_boosters.append(b)
	request_save()
