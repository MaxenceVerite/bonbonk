extends Node

## Gestionnaire d'état persistant : or, inventaire de bonbons, montée de niveau et boosters.

var gold: int = 250
var diamonds: int = 30

# Structure pour chaque bonbon : { "unlocked": bool, "level": int, "cards": int }
var cards_inventory: Dictionary = {
	&"standard": { "unlocked": true, "level": 1, "cards": 3 },
	&"fizz":     { "unlocked": true, "level": 1, "cards": 1 },
	&"caramel":  { "unlocked": true, "level": 1, "cards": 2 },
	&"cherry":   { "unlocked": false, "level": 1, "cards": 0 },
	&"mint":     { "unlocked": false, "level": 1, "cards": 0 },
	&"dragibump":{ "unlocked": true,  "level": 1, "cards": 2 },
}

# Nombre de boosters en attente dans chaque catégorie
var available_boosters: Array[BoosterData] = []
var registered_card_defs: Dictionary = {} # id -> CandyCardData
var shop_catalog: Array[ShopItemData] = []

# Système de Decks : 3 decks de 6 cartes max
var active_deck_index: int = 0
var decks: Array = [
	[&"standard", &"fizz", &"caramel", &"standard", &"fizz", &"dragibump"],
	[&"standard", &"caramel", &"caramel", &"dragibump", &"standard", &"standard"],
	[&"fizz", &"fizz", &"caramel", &"dragibump", &"standard", &"caramel"]
]

func _ready() -> void:
	_init_default_definitions()
	_init_default_boosters()
	_init_shop_catalog()
	_validate_decks()

func _init_default_definitions() -> void:
	# Bille Sucrée (Standard)
	var std_card: CandyCardData = CandyCardData.new()
	std_card.id = &"standard"
	std_card.display_name = "Bille Sucrée"
	std_card.subtitle = "Classique & Gourmande"
	std_card.description = "Une bille équilibrée et croustillante, parfaite pour éliminer les premiers bonbons."
	std_card.rarity = CandyCardData.Rarity.COMMON
	std_card.base_damage = 10
	std_card.damage_per_level = 3
	std_card.base_bounce = 1.0
	std_card.icon_texture = load("res://assets/ui/icon_ball_standard.png")
	registered_card_defs[&"standard"] = std_card

	# Fizzball
	var fizz_card: CandyCardData = CandyCardData.new()
	fizz_card.id = &"fizz"
	fizz_card.display_name = "Fizzball"
	fizz_card.subtitle = "Acidulée & Électrique"
	fizz_card.description = "Diffuse des décharges acidulées qui frappent plusieurs ennemis proches."
	fizz_card.rarity = CandyCardData.Rarity.RARE
	fizz_card.base_damage = 14
	fizz_card.damage_per_level = 4
	fizz_card.base_bounce = 1.15
	fizz_card.icon_texture = load("res://assets/ui/icon_ball_fizz.png")
	registered_card_defs[&"fizz"] = fizz_card

	# Bille Caramel (Collante & Gluante)
	var caramel_card: CandyCardData = CandyCardData.new()
	caramel_card.id = &"caramel"
	caramel_card.display_name = "Bille Caramel"
	caramel_card.subtitle = "Collante & Ralentissante"
	caramel_card.description = "Englue les bonbons adverses à chaque contact pour ralentir leur descente."
	caramel_card.rarity = CandyCardData.Rarity.RARE
	caramel_card.base_damage = 12
	caramel_card.damage_per_level = 3
	caramel_card.base_bounce = 0.95
	caramel_card.icon_texture = load("res://assets/ui/icon_ball_caramel.png")
	registered_card_defs[&"caramel"] = caramel_card

	# Bonbon Cerise Explosif
	var cherry_card: CandyCardData = CandyCardData.new()
	cherry_card.id = &"cherry"
	cherry_card.display_name = "Cerise Pop"
	cherry_card.subtitle = "Déflagration Fruitée"
	cherry_card.description = "Provoque une violente explosion fruitée dévastatrice lors des rebonds appuyés."
	cherry_card.rarity = CandyCardData.Rarity.EPIC
	cherry_card.base_damage = 22
	cherry_card.damage_per_level = 6
	cherry_card.base_bounce = 1.25
	cherry_card.icon_texture = load("res://assets/ui/icon_ball_fizz.png")
	registered_card_defs[&"cherry"] = cherry_card

	# Menthe Givrée
	var mint_card: CandyCardData = CandyCardData.new()
	mint_card.id = &"mint"
	mint_card.display_name = "Menthe Givrée"
	mint_card.subtitle = "Frisson Glacé"
	mint_card.description = "Diffuse une brise glaciale rafraîchissante qui immobilise brièvement les cibles."
	mint_card.rarity = CandyCardData.Rarity.COMMON
	mint_card.base_damage = 9
	mint_card.damage_per_level = 2
	mint_card.base_bounce = 1.05
	mint_card.icon_texture = load("res://assets/ui/icon_ball_standard.png")
	registered_card_defs[&"mint"] = mint_card

	# Dragibump (Bumper Bonbon)
	var dragi_card: CandyCardData = CandyCardData.new()
	dragi_card.id = &"dragibump"
	dragi_card.display_name = "Dragibump"
	dragi_card.subtitle = "Bumper Magnétique"
	dragi_card.description = "Bumper gélifié très rebondissant qui renvoie les billes avec une vélocité accrue."
	dragi_card.rarity = CandyCardData.Rarity.RARE
	dragi_card.card_type = CandyCardData.CardType.BUMPER
	dragi_card.base_damage = 16
	dragi_card.damage_per_level = 4
	dragi_card.base_bounce = 1.3
	dragi_card.icon_texture = load("res://assets/ui/icon_bumper_dragibump.png")
	registered_card_defs[&"dragibump"] = dragi_card

func _init_default_boosters() -> void:
	# Donner 2 boosters de départ au joueur
	var b1: BoosterData = BoosterData.new()
	b1.id = &"classic_solo"
	b1.display_name = "🍬 Sachet Classique"
	b1.booster_type = BoosterData.BoosterType.CLASSIC_SOLO
	b1.min_gold = 40
	b1.max_gold = 80
	available_boosters.append(b1)

	var b2: BoosterData = BoosterData.new()
	b2.id = &"pop_solo"
	b2.display_name = "⭐ Sachet Pop Acidulé"
	b2.booster_type = BoosterData.BoosterType.POP_SOLO
	b2.min_gold = 120
	b2.max_gold = 220
	available_boosters.append(b2)

func get_unlocked_card_ids() -> Array[StringName]:
	var res: Array[StringName] = []
	for cid in cards_inventory:
		if cards_inventory[cid].get("unlocked", false):
			res.append(cid)
	return res

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		EventBus.gold_changed.emit(gold, -amount)
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

func _init_shop_catalog() -> void:
	shop_catalog.clear()

	# 1. Boosters
	var it_pack_classic: ShopItemData = ShopItemData.new()
	it_pack_classic.id = &"shop_pack_classic"
	it_pack_classic.display_name = "🍬 Sachet Solo"
	it_pack_classic.description = "1 bonbon commun en quantité + Or sucré"
	it_pack_classic.category = ShopItemData.Category.BOOSTERS
	it_pack_classic.icon_texture = load("res://assets/ui/pack_classic_solo.png")
	it_pack_classic.gold_price = 200
	it_pack_classic.diamond_price = 15
	it_pack_classic.reward_payload = {
		"type": "booster",
		"id": &"classic_solo",
		"display_name": "🍬 Sachet Classique",
		"booster_type": BoosterData.BoosterType.CLASSIC_SOLO,
		"min_gold": 40,
		"max_gold": 80
	}
	shop_catalog.append(it_pack_classic)

	var it_pack_pop: ShopItemData = ShopItemData.new()
	it_pack_pop.id = &"shop_pack_pop"
	it_pack_pop.display_name = "⭐ Sachet Pop"
	it_pack_pop.description = "Garanti un bonbon Rare ou Épique !"
	it_pack_pop.category = ShopItemData.Category.BOOSTERS
	it_pack_pop.icon_texture = load("res://assets/ui/pack_pop_solo.png")
	it_pack_pop.gold_price = 500
	it_pack_pop.diamond_price = 35
	it_pack_pop.reward_payload = {
		"type": "booster",
		"id": &"pop_solo",
		"display_name": "⭐ Sachet Pop Acidulé",
		"booster_type": BoosterData.BoosterType.POP_SOLO,
		"min_gold": 120,
		"max_gold": 220
	}
	shop_catalog.append(it_pack_pop)

	var it_pack_piquant: ShopItemData = ShopItemData.new()
	it_pack_piquant.id = &"shop_pack_piquant"
	it_pack_piquant.display_name = "🔥 Mix Acidulé"
	it_pack_piquant.description = "Mélange généreux de cartes rares & or abondant"
	it_pack_piquant.category = ShopItemData.Category.BOOSTERS
	it_pack_piquant.icon_texture = load("res://assets/ui/pack_mix_piquant.png")
	it_pack_piquant.gold_price = -1 # Achat exclusif en diamants
	it_pack_piquant.diamond_price = 70
	it_pack_piquant.reward_payload = {
		"type": "booster",
		"id": &"piquant_mix",
		"display_name": "🔥 Sachet Piquant Mix",
		"booster_type": BoosterData.BoosterType.PIQUANT_MIX,
		"min_gold": 250,
		"max_gold": 450
	}
	shop_catalog.append(it_pack_piquant)

	# 2. Cartes quotidiennes
	var it_card_caramel: ShopItemData = ShopItemData.new()
	it_card_caramel.id = &"daily_caramel_5"
	it_card_caramel.display_name = "x5 Bille Caramel"
	it_card_caramel.description = "Ralentit les bonbons adverses"
	it_card_caramel.category = ShopItemData.Category.CARDS_DAILY
	it_card_caramel.icon_texture = load("res://assets/ui/icon_ball_caramel.png")
	it_card_caramel.gold_price = 150
	it_card_caramel.diamond_price = 10
	it_card_caramel.reward_payload = {
		"type": "cards",
		"card_id": &"caramel",
		"count": 5
	}
	shop_catalog.append(it_card_caramel)

	var it_card_cherry: ShopItemData = ShopItemData.new()
	it_card_cherry.id = &"daily_cherry_3"
	it_card_cherry.display_name = "x3 Cerise Pop"
	it_card_cherry.description = "Cartes Épiques explosives !"
	it_card_cherry.category = ShopItemData.Category.CARDS_DAILY
	it_card_cherry.icon_texture = load("res://assets/ui/icon_ball_locked.png")
	it_card_cherry.gold_price = 300
	it_card_cherry.diamond_price = 25
	it_card_cherry.reward_payload = {
		"type": "cards",
		"card_id": &"cherry",
		"count": 3
	}
	shop_catalog.append(it_card_cherry)

	# 3. Monnaies & Trésorerie
	var it_gold_pouch: ShopItemData = ShopItemData.new()
	it_gold_pouch.id = &"currency_gold_small"
	it_gold_pouch.display_name = "🪙 Bourse de 500 Pièces"
	it_gold_pouch.description = "Échangez vos diamants contre de l'or immédiat"
	it_gold_pouch.category = ShopItemData.Category.CURRENCY
	it_gold_pouch.icon_texture = load("res://assets/ui/patch_badge_gold.png")
	it_gold_pouch.gold_price = -1
	it_gold_pouch.diamond_price = 20
	it_gold_pouch.reward_payload = {
		"type": "gold",
		"amount": 500
	}
	shop_catalog.append(it_gold_pouch)

	var it_gold_chest: ShopItemData = ShopItemData.new()
	it_gold_chest.id = &"currency_gold_large"
	it_gold_chest.display_name = "🪙 Coffre de 1 500 Pièces"
	it_gold_chest.description = "Grosse réserve d'or sucré pour vos améliorations"
	it_gold_chest.category = ShopItemData.Category.CURRENCY
	it_gold_chest.icon_texture = load("res://assets/ui/patch_badge_gold.png")
	it_gold_chest.gold_price = -1
	it_gold_chest.diamond_price = 50
	it_gold_chest.reward_payload = {
		"type": "gold",
		"amount": 1500
	}
	shop_catalog.append(it_gold_chest)

	var it_dia_pack: ShopItemData = ShopItemData.new()
	it_dia_pack.id = &"currency_dia_reward"
	it_dia_pack.display_name = "💎 Lot Découverte (Offert)"
	it_dia_pack.description = "Pack de bienvenue : 50 Diamants pour tester la boutique"
	it_dia_pack.category = ShopItemData.Category.CURRENCY
	it_dia_pack.icon_texture = load("res://assets/ui/sparkle_star.png")
	it_dia_pack.gold_price = 50 # Accessible pour un peu d'or !
	it_dia_pack.diamond_price = -1
	it_dia_pack.reward_payload = {
		"type": "diamonds",
		"amount": 50
	}
	shop_catalog.append(it_dia_pack)

func add_diamonds(amount: int) -> void:
	diamonds += amount
	EventBus.diamonds_changed.emit(diamonds, amount)

func spend_diamonds(amount: int) -> bool:
	if diamonds >= amount:
		diamonds -= amount
		EventBus.diamonds_changed.emit(diamonds, -amount)
		return true
	return false

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

	# Appliquer la récompense
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
			var cid: StringName = payload.get("card_id", &"standard")
			var count: int = payload.get("count", 1)
			if not cards_inventory.has(cid):
				cards_inventory[cid] = { "unlocked": true, "level": 1, "cards": count }
			else:
				var inv: Dictionary = cards_inventory[cid]
				inv["unlocked"] = true
				inv["cards"] = inv.get("cards", 0) + count

	EventBus.shop_item_purchased.emit(item.id, "diamonds" if use_diamonds else "gold")
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
				
	EventBus.booster_opened.emit(result)

func _validate_decks() -> void:
	# S'assurer que chaque deck a 6 slots et des cartes valides
	for i in range(decks.size()):
		var d: Array = decks[i]
		while d.size() < 6:
			d.append(&"standard")
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

func set_card_in_deck(deck_idx: int, slot_idx: int, card_id: StringName) -> void:
	if deck_idx >= 0 and deck_idx < decks.size():
		var d: Array = decks[deck_idx]
		if slot_idx >= 0 and slot_idx < d.size():
			d[slot_idx] = card_id
			EventBus.deck_changed.emit(deck_idx)

func get_active_deck_balls() -> Array[StringName]:
	var balls: Array[StringName] = []
	var cur_deck: Array = get_active_deck()
	for card_id in cur_deck:
		var c_id: StringName = card_id as StringName
		var c_def: CandyCardData = registered_card_defs.get(c_id, null)
		if c_def != null and c_def.card_type == CandyCardData.CardType.BALL:
			balls.append(c_id)
	if balls.is_empty():
		balls.append(&"standard")
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
