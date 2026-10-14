class_name ShopCatalog
extends RefCounted

## Répertoire centralisé et définitions des articles de la boutique (ShopItemData).
## Isole la configuration marchande pour alléger SaveManager.

static func get_default_catalog() -> Array[ShopItemData]:
	var catalog: Array[ShopItemData] = []

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
	catalog.append(it_pack_classic)

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
	catalog.append(it_pack_pop)

	var it_pack_piquant: ShopItemData = ShopItemData.new()
	it_pack_piquant.id = &"shop_pack_piquant"
	it_pack_piquant.display_name = "🔥 Mix Acidulé"
	it_pack_piquant.description = "Mélange généreux de cartes rares & or abondant"
	it_pack_piquant.category = ShopItemData.Category.BOOSTERS
	it_pack_piquant.icon_texture = load("res://assets/ui/pack_mix_piquant.png")
	it_pack_piquant.gold_price = -1
	it_pack_piquant.diamond_price = 70
	it_pack_piquant.reward_payload = {
		"type": "booster",
		"id": &"piquant_mix",
		"display_name": "🔥 Sachet Piquant Mix",
		"booster_type": BoosterData.BoosterType.PIQUANT_MIX,
		"min_gold": 250,
		"max_gold": 450
	}
	catalog.append(it_pack_piquant)

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
	catalog.append(it_card_caramel)

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
	catalog.append(it_card_cherry)

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
	catalog.append(it_gold_pouch)

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
	catalog.append(it_gold_chest)

	var it_dia_pack: ShopItemData = ShopItemData.new()
	it_dia_pack.id = &"currency_dia_reward"
	it_dia_pack.display_name = "💎 Lot Découverte (Offert)"
	it_dia_pack.description = "Pack de bienvenue : 50 Diamants pour tester la boutique"
	it_dia_pack.category = ShopItemData.Category.CURRENCY
	it_dia_pack.icon_texture = load("res://assets/ui/sparkle_star.png")
	it_dia_pack.gold_price = 50
	it_dia_pack.diamond_price = -1
	it_dia_pack.reward_payload = {
		"type": "diamonds",
		"amount": 50
	}
	catalog.append(it_dia_pack)

	return catalog
