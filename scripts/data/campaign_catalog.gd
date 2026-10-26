class_name CampaignCatalog
extends RefCounted

const LevelData = preload("res://scripts/data/level_data.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const LevelWaveData = preload("res://scripts/data/level_wave_data.gd")

## Catalogue et configuration par défaut des Mondes et Niveaux du mode Campagne.

static var _cached_worlds: Array[WorldData] = []

static func get_all_worlds() -> Array[WorldData]:
	if not _cached_worlds.is_empty():
		return _cached_worlds
	_cached_worlds = _build_default_worlds()
	return _cached_worlds

static func get_world(world_id: StringName) -> WorldData:
	for w in get_all_worlds():
		if w.id == world_id:
			return w
	return get_all_worlds()[0] if not get_all_worlds().is_empty() else null

static func get_world_by_number(num: int) -> WorldData:
	for w in get_all_worlds():
		if w.world_number == num:
			return w
	return get_all_worlds()[0] if not get_all_worlds().is_empty() else null

static func get_level(world_id: StringName, level_num: int) -> LevelData:
	var w: WorldData = get_world(world_id)
	if w != null:
		return w.get_level(level_num)
	return null

static func _build_default_worlds() -> Array[WorldData]:
	var list: Array[WorldData] = []
	var beach_texture: Texture2D = load("res://assets/board/arena_candy_beach_clean_1280.png")
	var beach_map: Texture2D = load("res://assets/maps/world_1_saga_map.png")
	var beach_flipper: Texture2D = load("res://assets/ui/flipper_chocolate.png")
	var beach_wall_l: Texture2D = load("res://assets/board/guide_wall_left.png")
	var beach_wall_r: Texture2D = load("res://assets/board/guide_wall_right.png")
	var beach_top_ext: Texture2D = load("res://assets/board/top_sand_seamless.png")

	var foret_texture: Texture2D = load("res://assets/board/arena_foret_dragee.png")
	var foret_map: Texture2D = load("res://assets/maps/foret_dragee_saga_map.png")
	var foret_canopy: Texture2D = load("res://assets/board/canopy_foret_dragee.png")
	var foret_flipper: Texture2D = load("res://assets/ui/flipper_dragee.png")
	var foret_wall_l: Texture2D = load("res://assets/board/guide_wall_dragee_left.png")
	var foret_wall_r: Texture2D = load("res://assets/board/guide_wall_dragee_right.png")
	var foret_top_ext: Texture2D = load("res://assets/board/top_dragee_seamless.png")

	var pin_ratios_foret: Array[Vector2] = [
		Vector2(0.40, 0.94), # 1: Entrée sous-bois
		Vector2(0.60, 0.86), # 2: Pain d'épices
		Vector2(0.64, 0.77), # 3: Sucettes tourbillons
		Vector2(0.44, 0.69), # 4: Pont de gaufre sur chocolat
		Vector2(0.35, 0.61), # 5: Champignons dragées
		Vector2(0.53, 0.53), # 6: Oursons gélifiés
		Vector2(0.35, 0.44), # 7: Maison cupcake
		Vector2(0.48, 0.35), # 8: Étang aux sucettes
		Vector2(0.45, 0.27), # 9: Allée des marches
		Vector2(0.50, 0.17), # 10: Trône de Brocolino
	]

	var pin_ratios_plage: Array[Vector2] = [
		Vector2(0.50, 0.84), # 1: Entrée / Devant le château
		Vector2(0.44, 0.77), # 2: Sentier sableux
		Vector2(0.42, 0.70), # 3: Courbe gauche
		Vector2(0.57, 0.63), # 4: Virage droit près des bonbons
		Vector2(0.44, 0.55), # 5: Milieu plage
		Vector2(0.47, 0.47), # 6: Traversée
		Vector2(0.53, 0.39), # 7: Palmier droit
		Vector2(0.40, 0.30), # 8: Courbe vers les marches
		Vector2(0.47, 0.20), # 9: Approche du trône
		Vector2(0.49, 0.135), # 10: Carambine au trône
	]

	# =========================================================================
	# MONDE 1 : FORÊT DRAGÉE
	# =========================================================================
	var w1: WorldData = WorldData.new()
	w1.id = &"world_1"
	w1.world_number = 1
	w1.display_name = "Forêt Dragée"
	w1.subtitle = "Un sous-bois féerique aux racines de réglisse et dragées pastel"
	w1.arena_texture = foret_texture
	w1.canopy_texture = foret_canopy
	w1.flipper_texture = foret_flipper
	w1.wall_left_texture = foret_wall_l
	w1.wall_right_texture = foret_wall_r
	w1.top_extension_texture = foret_top_ext
	w1.saga_map_texture = foret_map
	w1.pin_positions = pin_ratios_foret
	w1.arena_modulate = Color.WHITE
	w1.completion_reward_booster_id = &"golden_crush"

	# Niveau 1-1
	var l1: LevelData = LevelData.new()
	l1.id = &"w1_01"
	l1.world_id = w1.id
	l1.level_number = 1
	l1.display_title = "Premiers Pas Croquants"
	l1.description = "Repousse les premières tomates maraîchères."
	l1.star_thresholds = [400, 900, 1500]
	l1.first_clear_gold = 100
	l1.first_clear_diamonds = 5
	l1.first_clear_booster_id = &"silver_pop"
	l1.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.35 },
			{ "unit": "tomato", "delay": 1.8, "x_ratio": 0.65 },
		]),
		_create_wave(2, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 1.2, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 2.0, "x_ratio": 0.8 },
		]),
		_create_wave(3, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "tomato", "delay": 1.0, "x_ratio": 0.7 },
			{ "unit": "tomato", "delay": 2.5, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l1)

	# Niveau 1-2
	var l2: LevelData = LevelData.new()
	l2.id = &"w1_02"
	l2.world_id = w1.id
	l2.level_number = 2
	l2.display_title = "Sauts d'Ananas"
	l2.description = "Méfie-toi des ananas et de leurs rebonds en zigzag !"
	l2.star_thresholds = [600, 1400, 2200]
	l2.first_clear_gold = 120
	l2.first_clear_diamonds = 5
	l2.first_clear_booster_id = &"silver_pop"
	l2.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 1.5, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 1.0, "x_ratio": 0.8 },
			{ "unit": "ananas", "delay": 2.2, "x_ratio": 0.5 },
		]),
		_create_wave(3, [
			{ "unit": "ananas", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 1.2, "x_ratio": 0.7 },
			{ "unit": "tomato", "delay": 2.5, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l2)

	# Niveau 1-3
	var l3: LevelData = LevelData.new()
	l3.id = &"w1_03"
	l3.world_id = w1.id
	l3.level_number = 3
	l3.display_title = "La Vague Sucrée"
	l3.description = "Des groupes de tomates coordonnées prennent d'assaut la plage."
	l3.star_thresholds = [800, 1800, 2800]
	l3.first_clear_gold = 150
	l3.first_clear_diamonds = 8
	l3.first_clear_booster_id = &"silver_pop"
	l3.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 0.8, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 1.1, "x_ratio": 0.8 },
		]),
		_create_wave(2, [
			{ "unit": "ananas", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "tomato", "delay": 1.5, "x_ratio": 0.5 },
			{ "unit": "ananas", "delay": 2.2, "x_ratio": 0.75 },
		]),
		_create_wave(3, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.15 },
			{ "unit": "tomato", "delay": 0.8, "x_ratio": 0.85 },
			{ "unit": "ananas", "delay": 1.8, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 3.0, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l3)

	# Niveau 1-4
	var l4: LevelData = LevelData.new()
	l4.id = &"w1_04"
	l4.world_id = w1.id
	l4.level_number = 4
	l4.display_title = "Le Poids Lourd"
	l4.description = "Une pastèque blindée roule vers tes portes. Ralentis-la !"
	l4.star_thresholds = [1000, 2200, 3400]
	l4.first_clear_gold = 180
	l4.first_clear_diamonds = 10
	l4.first_clear_booster_id = &"golden_crush"
	l4.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 1.5, "x_ratio": 0.7 },
		]),
		_create_wave(2, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 2.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 3.0, "x_ratio": 0.8 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "ananas", "delay": 2.0, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 2.5, "x_ratio": 0.7 },
		])
	]
	w1.levels.append(l4)

	# Niveau 1-5 (Garde Côtière)
	var l5: LevelData = LevelData.new()
	l5.id = &"w1_05"
	l5.world_id = w1.id
	l5.level_number = 5
	l5.display_title = "Garde Côtière"
	l5.description = "Des pastèques et des ananas patrouillent le rivage !"
	l5.star_thresholds = [1200, 2600, 4000]
	l5.first_clear_gold = 200
	l5.first_clear_diamonds = 10
	l5.first_clear_booster_id = &"golden_crush"
	l5.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "ananas", "delay": 1.2, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 2.0, "x_ratio": 0.75 },
		]),
		_create_wave(2, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 1.8, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 2.4, "x_ratio": 0.8 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.35 },
			{ "unit": "ananas", "delay": 1.6, "x_ratio": 0.65 },
			{ "unit": "tomato", "delay": 2.8, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l5)

	# Niveau 1-6 (Grappes Explosives)
	var l6: LevelData = LevelData.new()
	l6.id = &"w1_06"
	l6.world_id = w1.id
	l6.level_number = 6
	l6.display_title = "Grappes Explosives"
	l6.description = "Les premières grappes de raisin apparaissent ! Attention aux éclats !"
	l6.star_thresholds = [1400, 3000, 4500]
	l6.first_clear_gold = 220
	l6.first_clear_diamonds = 12
	l6.first_clear_booster_id = &"golden_crush"
	l6.waves = [
		_create_wave(1, [
			{ "unit": "grape_bunch", "delay": 0.6, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 2.0, "x_ratio": 0.3 },
		]),
		_create_wave(2, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "grape_bunch", "delay": 1.4, "x_ratio": 0.7 },
			{ "unit": "ananas", "delay": 2.6, "x_ratio": 0.4 },
		]),
		_create_wave(3, [
			{ "unit": "grape_bunch", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "grape_bunch", "delay": 1.8, "x_ratio": 0.7 },
			{ "unit": "tomato", "delay": 3.0, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l6)

	# Niveau 1-7 (L'Ouragan Tropical)
	var l7: LevelData = LevelData.new()
	l7.id = &"w1_07"
	l7.world_id = w1.id
	l7.level_number = 7
	l7.display_title = "L'Ouragan Tropical"
	l7.description = "Des noix de coco ultra résistantes tombent des palmiers !"
	l7.star_thresholds = [1600, 3400, 5000]
	l7.first_clear_gold = 250
	l7.first_clear_diamonds = 15
	l7.first_clear_booster_id = &"golden_crush"
	l7.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.6, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 1.8, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 2.2, "x_ratio": 0.8 },
		]),
		_create_wave(2, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.35 },
			{ "unit": "ananas", "delay": 1.6, "x_ratio": 0.65 },
			{ "unit": "watermelon", "delay": 2.8, "x_ratio": 0.5 },
		]),
		_create_wave(3, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "coconut", "delay": 1.8, "x_ratio": 0.75 },
			{ "unit": "grape_bunch", "delay": 3.0, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l7)

	# Niveau 1-8 (Pluie de Grenades)
	var l8: LevelData = LevelData.new()
	l8.id = &"w1_08"
	l8.world_id = w1.id
	l8.level_number = 8
	l8.display_title = "Pluie de Grenades"
	l8.description = "Des grenades explosives avancent sur la plage avec la troupe."
	l8.star_thresholds = [1800, 3800, 5600]
	l8.first_clear_gold = 280
	l8.first_clear_diamonds = 15
	l8.first_clear_booster_id = &"golden_crush"
	l8.waves = [
		_create_wave(1, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.4 },
			{ "unit": "tomato", "delay": 1.5, "x_ratio": 0.7 },
		]),
		_create_wave(2, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "ananas", "delay": 1.4, "x_ratio": 0.75 },
			{ "unit": "pomegranate", "delay": 2.6, "x_ratio": 0.5 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "pomegranate", "delay": 1.6, "x_ratio": 0.25 },
			{ "unit": "pomegranate", "delay": 2.2, "x_ratio": 0.75 },
		])
	]
	w1.levels.append(l8)

	# Niveau 1-9 (L'Avant-Poste Royal)
	var l9: LevelData = LevelData.new()
	l9.id = &"w1_09"
	l9.world_id = w1.id
	l9.level_number = 9
	l9.display_title = "L'Avant-Poste Royal"
	l9.description = "Dernier rempart avant le trône ! Toute l'armée de fruits est déployée."
	l9.star_thresholds = [2200, 4400, 6500]
	l9.first_clear_gold = 320
	l9.first_clear_diamonds = 18
	l9.first_clear_booster_id = &"diamond_dust"
	l9.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "watermelon", "delay": 1.2, "x_ratio": 0.7 },
			{ "unit": "ananas", "delay": 2.2, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "grape_bunch", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "pomegranate", "delay": 1.5, "x_ratio": 0.75 },
			{ "unit": "watermelon", "delay": 2.5, "x_ratio": 0.5 },
		]),
		_create_wave(3, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "coconut", "delay": 1.2, "x_ratio": 0.8 },
			{ "unit": "pomegranate", "delay": 2.4, "x_ratio": 0.5 },
			{ "unit": "watermelon", "delay": 3.4, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l9)

	# Niveau 1-10 (Le Boss du Trône : Brocolino)
	var l10: LevelData = LevelData.new()
	l10.id = &"w1_10"
	l10.world_id = w1.id
	l10.level_number = 10
	l10.display_title = "Le Trône Végétal : Brocolino"
	l10.description = "Brocolino défend son trône au sommet de la forêt ! Brisez ses bumpers brocolis et esquivez ses pluies de spores !"
	l10.star_thresholds = [3000, 6000, 9000]
	l10.first_clear_gold = 500
	l10.first_clear_diamonds = 30
	l10.first_clear_booster_id = &"golden_crush"
	l10.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 0.8, "x_ratio": 0.8 },
			{ "unit": "watermelon", "delay": 2.0, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "boss_brocolino", "delay": 0.8, "x_ratio": 0.5 },
		])
	]
	w1.levels.append(l10)
	list.append(w1)

	# =========================================================================
	# MONDE 2 : PLAGE SUCRÉE
	# =========================================================================
	var w2: WorldData = WorldData.new()
	w2.id = &"world_2"
	w2.world_number = 2
	w2.display_name = "Plage Sucrée"
	w2.subtitle = "Le rivage de sucre rose et d'océan pétillant"
	w2.arena_texture = beach_texture
	w2.canopy_texture = null
	w2.flipper_texture = beach_flipper
	w2.wall_left_texture = beach_wall_l
	w2.wall_right_texture = beach_wall_r
	w2.top_extension_texture = beach_top_ext
	w2.saga_map_texture = beach_map
	w2.pin_positions = pin_ratios_plage
	w2.arena_modulate = Color.WHITE
	w2.completion_reward_booster_id = &"diamond_dust"

	# Niveau 2-1 (Arrivée sur la Plage)
	var l21: LevelData = LevelData.new()
	l21.id = &"w2_01"
	l21.world_id = w2.id
	l21.level_number = 1
	l21.display_title = "Arrivée sur la Plage"
	l21.description = "Bienvenue sur le rivage ! Les grenades font leur apparition."
	l21.star_thresholds = [600, 1500, 2600]
	l21.first_clear_gold = 150
	l21.first_clear_diamonds = 8
	l21.first_clear_booster_id = &"silver_pop"
	l21.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "pomegranate", "delay": 1.5, "x_ratio": 0.6 },
		]),
		_create_wave(2, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "ananas", "delay": 1.5, "x_ratio": 0.75 },
		]),
		_create_wave(3, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 1.8, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 2.2, "x_ratio": 0.8 },
		])
	]
	w2.levels.append(l21)

	# Niveau 2-2 (Grappes Rebelles)
	var l22: LevelData = LevelData.new()
	l22.id = &"w2_02"
	l22.world_id = w2.id
	l22.level_number = 2
	l22.display_title = "Grappes Rebelles"
	l22.description = "Des grappes de raisins qui se scindent à l'impact !"
	l22.star_thresholds = [800, 2000, 3200]
	l22.first_clear_gold = 180
	l22.first_clear_diamonds = 10
	l22.first_clear_booster_id = &"silver_pop"
	l22.waves = [
		_create_wave(1, [
			{ "unit": "grape_bunch", "delay": 0.8, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "grape_bunch", "delay": 1.5, "x_ratio": 0.7 },
		]),
		_create_wave(3, [
			{ "unit": "grape_bunch", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "pomegranate", "delay": 1.8, "x_ratio": 0.7 },
		])
	]
	w2.levels.append(l22)

	# Niveau 2-3 (Coques de Coco)
	var l23: LevelData = LevelData.new()
	l23.id = &"w2_03"
	l23.world_id = w2.id
	l23.level_number = 3
	l23.display_title = "Coques de Coco"
	l23.description = "Les noix de coco blindées tombent lourdement."
	l23.star_thresholds = [1000, 2400, 3800]
	l23.first_clear_gold = 200
	l23.first_clear_diamonds = 12
	l23.first_clear_booster_id = &"golden_crush"
	l23.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.8, "x_ratio": 0.5 },
			{ "unit": "tomato", "delay": 1.8, "x_ratio": 0.2 },
		]),
		_create_wave(2, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "coconut", "delay": 2.0, "x_ratio": 0.7 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 2.5, "x_ratio": 0.25 },
			{ "unit": "coconut", "delay": 3.0, "x_ratio": 0.75 },
		])
	]
	w2.levels.append(l23)

	# Niveau 2-4 (Sauts d'Ananas de Plage)
	var l24: LevelData = LevelData.new()
	l24.id = &"w2_04"
	l24.world_id = w2.id
	l24.level_number = 4
	l24.display_title = "Sauts d'Ananas de Plage"
	l24.description = "Les ananas rebondissent vigoureusement sur le sable chaud."
	l24.star_thresholds = [1200, 2800, 4200]
	l24.first_clear_gold = 220
	l24.first_clear_diamonds = 12
	l24.first_clear_booster_id = &"golden_crush"
	l24.waves = [
		_create_wave(1, [
			{ "unit": "ananas", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 1.2, "x_ratio": 0.7 },
		]),
		_create_wave(2, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "ananas", "delay": 1.6, "x_ratio": 0.25 },
			{ "unit": "tomato", "delay": 2.2, "x_ratio": 0.75 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "ananas", "delay": 1.8, "x_ratio": 0.3 },
			{ "unit": "ananas", "delay": 2.4, "x_ratio": 0.7 },
		])
	]
	w2.levels.append(l24)

	# Niveau 2-5 (Garde Côtière)
	var l25: LevelData = LevelData.new()
	l25.id = &"w2_05"
	l25.world_id = w2.id
	l25.level_number = 5
	l25.display_title = "Garde Côtière"
	l25.description = "Des pastèques et des ananas patrouillent le rivage !"
	l25.star_thresholds = [1400, 3200, 4800]
	l25.first_clear_gold = 250
	l25.first_clear_diamonds = 15
	l25.first_clear_booster_id = &"golden_crush"
	l25.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.35 },
			{ "unit": "grape_bunch", "delay": 1.2, "x_ratio": 0.65 },
		]),
		_create_wave(2, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 1.5, "x_ratio": 0.2 },
			{ "unit": "pomegranate", "delay": 2.2, "x_ratio": 0.8 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "coconut", "delay": 1.6, "x_ratio": 0.7 },
			{ "unit": "grape_bunch", "delay": 2.8, "x_ratio": 0.5 },
		])
	]
	w2.levels.append(l25)

	# Niveau 2-6 (Dunes de Sucre)
	var l26: LevelData = LevelData.new()
	l26.id = &"w2_06"
	l26.world_id = w2.id
	l26.level_number = 6
	l26.display_title = "Dunes de Sucre"
	l26.description = "Les rafales de grenades et de raisins balaient les dunes."
	l26.star_thresholds = [1600, 3600, 5200]
	l26.first_clear_gold = 280
	l26.first_clear_diamonds = 15
	l26.first_clear_booster_id = &"golden_crush"
	l26.waves = [
		_create_wave(1, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "pomegranate", "delay": 1.2, "x_ratio": 0.7 },
		]),
		_create_wave(2, [
			{ "unit": "grape_bunch", "delay": 0.5, "x_ratio": 0.4 },
			{ "unit": "coconut", "delay": 1.8, "x_ratio": 0.6 },
		]),
		_create_wave(3, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "grape_bunch", "delay": 1.5, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 2.5, "x_ratio": 0.8 },
		])
	]
	w2.levels.append(l26)

	# Niveau 2-7 (L'Ouragan Tropical)
	var l27: LevelData = LevelData.new()
	l27.id = &"w2_07"
	l27.world_id = w2.id
	l27.level_number = 7
	l27.display_title = "L'Ouragan Tropical"
	l27.description = "Des noix de coco ultra résistantes tombent en masse !"
	l27.star_thresholds = [1800, 4000, 5800]
	l27.first_clear_gold = 300
	l27.first_clear_diamonds = 18
	l27.first_clear_booster_id = &"golden_crush"
	l27.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "coconut", "delay": 1.0, "x_ratio": 0.75 },
		]),
		_create_wave(2, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 1.6, "x_ratio": 0.3 },
			{ "unit": "coconut", "delay": 2.2, "x_ratio": 0.7 },
		]),
		_create_wave(3, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "watermelon", "delay": 1.4, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 2.6, "x_ratio": 0.8 },
		])
	]
	w2.levels.append(l27)

	# Niveau 2-8 (Pluie de Grenades)
	var l28: LevelData = LevelData.new()
	l28.id = &"w2_08"
	l28.world_id = w2.id
	l28.level_number = 8
	l28.display_title = "Pluie de Grenades"
	l28.description = "Des grenades explosives avancent sur la plage avec la troupe."
	l28.star_thresholds = [2000, 4500, 6500]
	l28.first_clear_gold = 350
	l28.first_clear_diamonds = 20
	l28.first_clear_booster_id = &"diamond_dust"
	l28.waves = [
		_create_wave(1, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "grape_bunch", "delay": 1.2, "x_ratio": 0.7 },
		]),
		_create_wave(2, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.5 },
			{ "unit": "pomegranate", "delay": 1.5, "x_ratio": 0.25 },
			{ "unit": "pomegranate", "delay": 2.2, "x_ratio": 0.75 },
		]),
		_create_wave(3, [
			{ "unit": "pomegranate", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "coconut", "delay": 1.5, "x_ratio": 0.5 },
			{ "unit": "pomegranate", "delay": 2.5, "x_ratio": 0.8 },
		])
	]
	w2.levels.append(l28)

	# Niveau 2-9 (Le Belvédère Côtier)
	var l29: LevelData = LevelData.new()
	l29.id = &"w2_09"
	l29.world_id = w2.id
	l29.level_number = 9
	l29.display_title = "Le Belvédère Côtier"
	l29.description = "Dernier bastion avant le sommet ! L'armée côtière est au complet."
	l29.star_thresholds = [2400, 5000, 7200]
	l29.first_clear_gold = 400
	l29.first_clear_diamonds = 25
	l29.first_clear_booster_id = &"diamond_dust"
	l29.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "watermelon", "delay": 1.2, "x_ratio": 0.75 },
		]),
		_create_wave(2, [
			{ "unit": "grape_bunch", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "pomegranate", "delay": 1.4, "x_ratio": 0.7 },
			{ "unit": "coconut", "delay": 2.2, "x_ratio": 0.5 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.35 },
			{ "unit": "watermelon", "delay": 1.6, "x_ratio": 0.65 },
			{ "unit": "pomegranate", "delay": 2.8, "x_ratio": 0.5 },
		])
	]
	w2.levels.append(l29)

	# Niveau 2-10 (Le Boss du Rivage : Carambine)
	var l210: LevelData = LevelData.new()
	l210.id = &"w2_10"
	l210.world_id = w2.id
	l210.level_number = 10
	l210.display_title = "L'Étoile du Rivage : Carambine"
	l210.description = "La bondissante Carambine s'abat sur la Plage Sucrée ! Renvoyez ses étoiles et brisez son rayon avant l'impact fatal !"
	l210.star_thresholds = [3500, 7000, 10000]
	l210.first_clear_gold = 700
	l210.first_clear_diamonds = 40
	l210.first_clear_booster_id = &"diamond_dust"
	l210.waves = [
		_create_wave(1, [
			{ "unit": "coconut", "delay": 0.5, "x_ratio": 0.25 },
			{ "unit": "watermelon", "delay": 1.5, "x_ratio": 0.75 },
			{ "unit": "pomegranate", "delay": 2.5, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "boss_carambine", "delay": 0.8, "x_ratio": 0.5 },
		])
	]
	w2.levels.append(l210)
	list.append(w2)

	return list

static func _create_wave(wave_num: int, spawns: Array[Dictionary]) -> LevelWaveData:
	var w: LevelWaveData = LevelWaveData.new()
	w.wave_number = wave_num
	w.spawns = spawns
	return w
