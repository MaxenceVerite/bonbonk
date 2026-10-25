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

	# =========================================================================
	# MONDE 1 : PLAGE SUCRÉE
	# =========================================================================
	var w1: WorldData = WorldData.new()
	w1.id = &"world_1"
	w1.world_number = 1
	w1.display_name = "Plage Sucrée"
	w1.subtitle = "Le rivage de sucre rose et d'océan pétillant"
	w1.arena_texture = beach_texture
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

	# Niveau 1-10 (Le Boss du Trône : Brocolino Suprême)
	var l10: LevelData = LevelData.new()
	l10.id = &"w1_10"
	l10.world_id = w1.id
	l10.level_number = 10
	l10.display_title = "Le Boss du Trône"
	l10.description = "Le terrible Brocolino t'attend sur son trône royal ! Repousse l'assaut final !"
	l10.star_thresholds = [2800, 5500, 8000]
	l10.first_clear_gold = 500
	l10.first_clear_diamonds = 30
	l10.first_clear_booster_id = &"diamond_dust"
	l10.waves = [
		_create_wave(1, [
			{ "unit": "tomato", "delay": 0.5, "x_ratio": 0.2 },
			{ "unit": "tomato", "delay": 0.8, "x_ratio": 0.8 },
			{ "unit": "ananas", "delay": 1.8, "x_ratio": 0.5 },
			{ "unit": "watermelon", "delay": 2.8, "x_ratio": 0.5 },
		]),
		_create_wave(2, [
			{ "unit": "boss_brocolino", "delay": 0.8, "x_ratio": 0.5 },
			{ "unit": "coconut", "delay": 3.5, "x_ratio": 0.2 },
			{ "unit": "pomegranate", "delay": 5.0, "x_ratio": 0.8 },
		]),
		_create_wave(3, [
			{ "unit": "watermelon", "delay": 0.5, "x_ratio": 0.3 },
			{ "unit": "watermelon", "delay": 1.0, "x_ratio": 0.7 },
			{ "unit": "grape_bunch", "delay": 2.5, "x_ratio": 0.5 },
			{ "unit": "ananas", "delay": 3.5, "x_ratio": 0.2 },
			{ "unit": "ananas", "delay": 4.0, "x_ratio": 0.8 },
		])
	]
	w1.levels.append(l10)
	list.append(w1)

	# =========================================================================
	# MONDE 2 : VERGER ACIDULÉ
	# =========================================================================
	var w2: WorldData = WorldData.new()
	w2.id = &"world_2"
	w2.world_number = 2
	w2.display_name = "Verger Acidulé"
	w2.subtitle = "Un verger vibrant aux senteurs d'agrumes et de bonbons piquants"
	w2.arena_texture = beach_texture
	# Teinte acidulée distinctive (vert menthe / citron)
	w2.arena_modulate = Color(0.82, 1.05, 0.78, 1.0)
	w2.completion_reward_booster_id = &"mystery_mix"

	# Niveau 2-1
	var l21: LevelData = LevelData.new()
	l21.id = &"w2_01"
	l21.world_id = w2.id
	l21.level_number = 1
	l21.display_title = "Zeste d'Énergie"
	l21.description = "Bienvenue dans le verger ! Les grenades font leur apparition."
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

	# Niveau 2-2
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

	# Niveau 2-3
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
	list.append(w2)

	return list

static func _create_wave(wave_num: int, spawns: Array[Dictionary]) -> LevelWaveData:
	var w: LevelWaveData = LevelWaveData.new()
	w.wave_number = wave_num
	w.spawns = spawns
	return w
