class_name ShopCatalog
extends RefCounted

const ShopSectionData = preload("res://scripts/data/shop_section_data.gd")
const ShopItemData = preload("res://scripts/data/shop_item_data.gd")

## Répertoire centralisé et définitions des articles de la boutique (ShopItemData).
## Structure et contenu alignés sur la maquette de référence (Image 1).

## Structure de la boutique (ordre des rayons, titres des rubans, présentation).
## Les sections sans article sont masquées : les offres du jour (FEATURED)
## apparaîtront dès que le catalogue (local ou distant) en fournira.
static func get_default_layout() -> Array[ShopSectionData]:
	var layout: Array[ShopSectionData] = []
	layout.append(ShopSectionData.create(&"featured", "OFFRE DU JOUR", ShopItemData.Category.FEATURED, ShopSectionData.Layout.FEATURED_GALLERY, 1))
	layout.append(ShopSectionData.create(&"free", "CADEAUX GRATUITS", ShopItemData.Category.FREE, ShopSectionData.Layout.REWARD_ROWS, 2))
	layout.append(ShopSectionData.create(&"boosters", "SACHETS DE BONBONS", ShopItemData.Category.BOOSTERS, ShopSectionData.Layout.ITEM_TILES, 2))
	layout.append(ShopSectionData.create(&"currency", "PIÈCES & DIAMANTS", ShopItemData.Category.CURRENCY, ShopSectionData.Layout.ITEM_TILES, 2))
	return layout

## Générateur d'offre du jour fidèle à l'Image 1
static func create_sample_featured_offer(
	p_id: StringName = &"hero_daily_pack",
	p_title: String = "OFFRE DU JOUR",
	p_badge: String = "",
	p_reward_text: String = "",
	p_real_price: String = "4,99€"
) -> ShopItemData:
	var it: ShopItemData = ShopItemData.new()
	it.id = p_id
	it.display_name = p_title
	it.category = ShopItemData.Category.FEATURED
	it.badge_text = p_badge
	it.featured_size = ShopItemData.FeaturedSize.FULL
	it.real_price_label = p_real_price
	it.background_texture = load("res://assets/ui/hero_card_frame_bg.png")
	it.reward_payload = {
		"type": "bundle",
		"rewards": [
			{ "type": "gold", "amount": 1500 },
			{ "type": "booster", "id": &"silver_pop", "display_name": "🥈 Sachet Silver Pop", "booster_type": BoosterData.BoosterType.SILVER_POP },
			{ "type": "cards", "card_id": &"fizz", "count": 10 }
		]
	}
	return it

static func get_default_catalog() -> Array[ShopItemData]:
	var catalog: Array[ShopItemData] = []

	# ==========================================================================
	# 0. OFFRE DU JOUR (Hero pack actif par défaut)
	# ==========================================================================
	catalog.append(create_sample_featured_offer())

	# ==========================================================================
	# 1. CADEAUX GRATUITS (2 colonnes comme dans l'Image 1)
	# ==========================================================================
	var it_free_booster: ShopItemData = ShopItemData.new()
	it_free_booster.id = &"free_booster"
	it_free_booster.display_name = "Sachet\ngratuit"
	it_free_booster.description = "Sachet Bonbonk offert !"
	it_free_booster.category = ShopItemData.Category.FREE
	it_free_booster.icon_texture = load("res://assets/ui/pack_silver_full.png")
	it_free_booster.badge_text = "GRATUIT"
	it_free_booster.gold_price = 0
	it_free_booster.reward_payload = {
		"type": "booster",
		"id": &"silver_pop",
		"display_name": "🥈 Sachet Silver Pop",
		"booster_type": BoosterData.BoosterType.SILVER_POP,
		"min_gold": 50,
		"max_gold": 120
	}
	catalog.append(it_free_booster)

	var it_free_daily: ShopItemData = ShopItemData.new()
	it_free_daily.id = &"free_daily_gold"
	it_free_daily.display_name = "Récompense\nquotidienne"
	it_free_daily.description = "Or quotidien offert"
	it_free_daily.category = ShopItemData.Category.FREE
	it_free_daily.icon_texture = load("res://assets/ui/icon_gold_stack.png")
	it_free_daily.badge_text = "OBTENIR"
	it_free_daily.gold_price = 0
	it_free_daily.reward_payload = {
		"type": "gold",
		"amount": 100
	}
	catalog.append(it_free_daily)

	# ==========================================================================
	# 2. SACHETS DE BONBONS (Silver Pop, Golden Crush, Mystery Mix, Diamond Dust)
	# ==========================================================================
	var it_pack_silver: ShopItemData = ShopItemData.new()
	it_pack_silver.id = &"shop_pack_silver"
	it_pack_silver.display_name = "🥈 Silver Pop"
	it_pack_silver.category = ShopItemData.Category.BOOSTERS
	it_pack_silver.icon_texture = load("res://assets/ui/pack_silver_full.png")
	it_pack_silver.gold_price = 150
	it_pack_silver.diamond_price = 10
	it_pack_silver.reward_payload = {
		"type": "booster",
		"id": &"silver_pop",
		"display_name": "🥈 Sachet Silver Pop",
		"booster_type": BoosterData.BoosterType.SILVER_POP,
		"min_gold": 50,
		"max_gold": 100
	}
	catalog.append(it_pack_silver)

	var it_pack_gold: ShopItemData = ShopItemData.new()
	it_pack_gold.id = &"shop_pack_gold"
	it_pack_gold.display_name = "🥇 Golden Crush"
	it_pack_gold.category = ShopItemData.Category.BOOSTERS
	it_pack_gold.icon_texture = load("res://assets/ui/pack_gold_full.png")
	it_pack_gold.gold_price = 450
	it_pack_gold.diamond_price = 25
	it_pack_gold.reward_payload = {
		"type": "booster",
		"id": &"golden_crush",
		"display_name": "🥇 Sachet Golden Crush",
		"booster_type": BoosterData.BoosterType.GOLDEN_CRUSH,
		"min_gold": 180,
		"max_gold": 350
	}
	catalog.append(it_pack_gold)

	var it_pack_mystery: ShopItemData = ShopItemData.new()
	it_pack_mystery.id = &"shop_pack_mystery"
	it_pack_mystery.display_name = "🔮 Mystery Mix"
	it_pack_mystery.category = ShopItemData.Category.BOOSTERS
	it_pack_mystery.icon_texture = load("res://assets/ui/pack_mystery_full.png")
	it_pack_mystery.gold_price = 300
	it_pack_mystery.diamond_price = 20
	it_pack_mystery.reward_payload = {
		"type": "booster",
		"id": &"mystery_mix",
		"display_name": "🔮 Sachet Mystery Mix",
		"booster_type": BoosterData.BoosterType.MYSTERY_MIX,
		"min_gold": 100,
		"max_gold": 500
	}
	catalog.append(it_pack_mystery)

	var it_pack_diamond: ShopItemData = ShopItemData.new()
	it_pack_diamond.id = &"shop_pack_diamond"
	it_pack_diamond.display_name = "💎 Diamond Dust"
	it_pack_diamond.category = ShopItemData.Category.BOOSTERS
	it_pack_diamond.icon_texture = load("res://assets/ui/pack_diamond_full.png")
	it_pack_diamond.gold_price = -1
	it_pack_diamond.diamond_price = 75
	it_pack_diamond.reward_payload = {
		"type": "booster",
		"id": &"diamond_dust",
		"display_name": "💎 Sachet Diamond Dust",
		"booster_type": BoosterData.BoosterType.DIAMOND_DUST,
		"min_gold": 600,
		"max_gold": 1200,
		"min_diamonds": 5,
		"max_diamonds": 10
	}
	catalog.append(it_pack_diamond)

	# ==========================================================================
	# 3. PIÈCES & DIAMANTS (Image 1 : Bourse de pièces & Tas de pièces à 10 💎)
	# ==========================================================================
	var it_gold_pouch: ShopItemData = ShopItemData.new()
	it_gold_pouch.id = &"currency_gold_small"
	it_gold_pouch.display_name = "Bourse d'Or"
	it_gold_pouch.category = ShopItemData.Category.CURRENCY
	it_gold_pouch.icon_texture = load("res://assets/ui/icon_gold_sack.png")
	it_gold_pouch.gold_price = -1
	it_gold_pouch.diamond_price = 10
	it_gold_pouch.reward_payload = {
		"type": "gold",
		"amount": 500
	}
	catalog.append(it_gold_pouch)

	var it_gold_large: ShopItemData = ShopItemData.new()
	it_gold_large.id = &"currency_gold_large"
	it_gold_large.display_name = "Tas de Pièces"
	it_gold_large.category = ShopItemData.Category.CURRENCY
	it_gold_large.icon_texture = load("res://assets/ui/icon_gold_pile.png")
	it_gold_large.gold_price = -1
	it_gold_large.diamond_price = 10
	it_gold_large.reward_payload = {
		"type": "gold",
		"amount": 1000
	}
	catalog.append(it_gold_large)

	return catalog
