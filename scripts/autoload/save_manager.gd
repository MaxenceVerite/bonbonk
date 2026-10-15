extends Node

## Gestionnaire d'état persistant & Comptes joueurs :
## - Chiffrement local AES-256 via SaveCipher
## - Architecture multi-profils (Profil Joueur & Profil Sandbox Dev)
## - Synchronisation Cloud offline-first avec résolution de conflits

const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")
const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")
const CloudSyncService = preload("res://scripts/core/account/cloud_sync_service.gd")

const PROFILES_DIR: String = "user://profiles/"
const ACTIVE_PROFILE_FILE: String = "user://active_profile.cfg"

var current_profile: PlayerProfileScript = null
var active_profile_id: String = "main"


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
# GESTION DES RESSOURCES & CARTES
# ==============================================================================

func get_unlocked_card_ids() -> Array[StringName]:
	var res: Array[StringName] = []
	for cid in cards_inventory:
		if cards_inventory[cid].get("unlocked", false):
			res.append(cid)
	return res

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)
	request_save()

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		EventBus.gold_changed.emit(gold, -amount)
		request_save()
		return true
	return false

func add_diamonds(amount: int) -> void:
	diamonds += amount
	EventBus.diamonds_changed.emit(diamonds, amount)
	request_save()

func spend_diamonds(amount: int) -> bool:
	if diamonds >= amount:
		diamonds -= amount
		EventBus.diamonds_changed.emit(diamonds, -amount)
		request_save()
		return true
	return false

func can_upgrade_card(card_id: StringName) -> bool:
	if not cards_inventory.has(card_id) or not registered_card_defs.has(card_id):
		return false
	var inv: Dictionary = cards_inventory[card_id]
	if not inv.get("unlocked", false):
		return false

	var def: CandyCardData = registered_card_defs[card_id]
	var cur_lvl: int = inv.get("level", 1)
	var req_cards: int = def.get_required_cards_for_level(cur_lvl)
	var req_gold: int = def.get_gold_cost_for_level(cur_lvl)

	return inv.get("cards", 0) >= req_cards and gold >= req_gold

func upgrade_card(card_id: StringName) -> bool:
	if not can_upgrade_card(card_id):
		return false

	var inv: Dictionary = cards_inventory[card_id]
	var def: CandyCardData = registered_card_defs[card_id]
	var cur_lvl: int = inv.get("level", 1)
	var req_cards: int = def.get_required_cards_for_level(cur_lvl)
	var req_gold: int = def.get_gold_cost_for_level(cur_lvl)

	if spend_gold(req_gold):
		inv["cards"] -= req_cards
		inv["level"] = cur_lvl + 1
		EventBus.card_upgraded.emit(card_id, inv["level"])
		request_save()
		return true
	return false

func get_card_state(card_id: StringName) -> Dictionary:
	if not registered_card_defs.has(card_id):
		return {}
	var def: CandyCardData = registered_card_defs[card_id]
	var inv: Dictionary = cards_inventory.get(card_id, { "unlocked": false, "level": 1, "cards": 0 })
	var is_unlocked: bool = inv.get("unlocked", false)
	var lvl: int = inv.get("level", 1)
	var cards: int = inv.get("cards", 0)
	var req_cards: int = def.get_required_cards_for_level(lvl)
	var req_gold: int = def.get_gold_cost_for_level(lvl)
	var has_enough_cards: bool = (cards >= req_cards)
	var has_enough_gold: bool = (gold >= req_gold)
	var can_up: bool = is_unlocked and has_enough_cards and has_enough_gold

	return {
		"id": card_id,
		"def": def,
		"unlocked": is_unlocked,
		"level": lvl,
		"cards": cards,
		"req_cards": req_cards,
		"req_gold": req_gold,
		"has_enough_cards": has_enough_cards,
		"has_enough_gold": has_enough_gold,
		"can_upgrade": can_up,
		"ratio": float(cards) / float(maxi(1, req_cards))
	}

func purchase_item(item: ShopItemData, use_diamonds: bool) -> bool:
	if use_diamonds:
		if item.diamond_price < 0 or diamonds < item.diamond_price:
			return false
		if not spend_diamonds(item.diamond_price):
			return false
	else:
		if item.gold_price < 0 or gold < item.gold_price:
			return false
		if not spend_gold(item.gold_price):
			return false

	var payload: Dictionary = item.reward_payload
	var ptype: String = payload.get("type", "")
	match ptype:
		"gold":
			add_gold(payload.get("amount", 0))
		"diamonds":
			add_diamonds(payload.get("amount", 0))
		"booster":
			var b: BoosterData = BoosterData.new()
			b.id = payload.get("id", &"booster")
			b.display_name = payload.get("display_name", "Sachet")
			b.booster_type = payload.get("booster_type", BoosterData.BoosterType.CLASSIC_SOLO)
			b.min_gold = payload.get("min_gold", 40)
			b.max_gold = payload.get("max_gold", 100)
			b.icon_texture = item.icon_texture
			available_boosters.append(b)
		"cards":
			var cid: StringName = payload.get("card_id", &"fizz")
			var count: int = payload.get("count", 1)
			if not cards_inventory.has(cid):
				cards_inventory[cid] = { "unlocked": true, "level": 1, "cards": count }
			else:
				var inv: Dictionary = cards_inventory[cid]
				inv["unlocked"] = true
				inv["cards"] = inv.get("cards", 0) + count

	EventBus.shop_item_purchased.emit(item.id, "diamonds" if use_diamonds else "gold")
	request_save()
	return true

func apply_booster_rewards(result: Dictionary) -> void:
	if result.has("gold"):
		add_gold(result["gold"])

	if result.has("drops"):
		for drop in result["drops"]:
			var card_def: CandyCardData = drop["card"]
			var cid: StringName = card_def.id
			var count: int = drop["count"]

			if not cards_inventory.has(cid):
				cards_inventory[cid] = { "unlocked": true, "level": 1, "cards": count }
			else:
				var inv: Dictionary = cards_inventory[cid]
				inv["unlocked"] = true
				inv["cards"] = inv.get("cards", 0) + count

	request_save()
	EventBus.booster_opened.emit(result)

func _validate_decks() -> void:
	for i in range(decks.size()):
		var d: Array = decks[i]
		for j in range(d.size()):
			if d[j] == &"standard" or d[j] == &"cherry" or d[j] == &"mint":
				d[j] = &"fizz"
		while d.size() < 6:
			d.append(&"fizz")
		if d.size() > 6:
			d.resize(6)

func get_active_deck() -> Array:
	if active_deck_index < 0 or active_deck_index >= decks.size():
		active_deck_index = 0
	return decks[active_deck_index]

func set_active_deck(index: int) -> void:
	if index >= 0 and index < decks.size():
		active_deck_index = index
		EventBus.deck_changed.emit(active_deck_index)
		request_save()

func set_card_in_deck(deck_idx: int, slot_idx: int, card_id: StringName) -> void:
	if deck_idx >= 0 and deck_idx < decks.size():
		var d: Array = decks[deck_idx]
		if slot_idx >= 0 and slot_idx < d.size():
			d[slot_idx] = card_id
			EventBus.deck_changed.emit(deck_idx)
			request_save()

func get_active_deck_balls() -> Array[StringName]:
	var balls: Array[StringName] = []
	var cur_deck: Array = get_active_deck()
	for card_id in cur_deck:
		var c_id: StringName = card_id as StringName
		var c_def: CandyCardData = registered_card_defs.get(c_id, null)
		if c_def != null and c_def.card_type == CandyCardData.CardType.BALL:
			balls.append(c_id)
	if balls.is_empty():
		balls.append(&"fizz")
	return balls

func get_active_deck_bumpers() -> Array[StringName]:
	var bumpers: Array[StringName] = []
	var cur_deck: Array = get_active_deck()
	for card_id in cur_deck:
		var c_id: StringName = card_id as StringName
		var c_def: CandyCardData = registered_card_defs.get(c_id, null)
		if c_def != null and c_def.card_type == CandyCardData.CardType.BUMPER:
			bumpers.append(c_id)
	return bumpers
