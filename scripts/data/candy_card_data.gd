class_name CandyCardData
extends Resource

## Définition d'un bonbon / bille à collectionner et améliorer.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }
enum CardType { BALL, BUMPER }

@export var id: StringName = &"fizz"
@export var display_name: String = "Fizzball"
@export var subtitle: String = "Pétillante & Électrisante"
@export var description: String = "Une bille pétillante qui fend les airs à toute vitesse."
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.BALL
@export var icon_texture: Texture2D
@export var scene_ref: PackedScene

# Statistiques communes de base et scaling par niveau
@export_group("Common Stats")
@export var base_damage: int = 1
@export var damage_per_level: float = 0.5
@export var base_magnetism: float = 350.0
@export var magnetism_per_level: float = 30.0
@export var base_bounce: float = 1.0
@export var bounce_per_level: float = 0.04

# Statistiques spécifiques de mots-clés (ex: cibles foudroyées, durée de gel, % de ralentissement...)
@export_group("Keyword Stats")
@export var keyword_stats: Array[Dictionary] = []

func get_damage_for_level(lvl: int) -> int:
	return maxi(1, int(roundf(float(base_damage) + float(lvl - 1) * damage_per_level)))

func get_magnetism_for_level(lvl: int) -> float:
	return base_magnetism + float(lvl - 1) * magnetism_per_level

func get_bounce_for_level(lvl: int) -> float:
	return base_bounce + float(lvl - 1) * bounce_per_level

func get_keyword_stat_value(stat_id: StringName, lvl: int, default_val: float = 0.0) -> float:
	for entry in keyword_stats:
		if entry.get("id", &"") == stat_id:
			var base_val: float = float(entry.get("base", default_val))
			var step_val: float = float(entry.get("step", 0.0))
			return base_val + float(lvl - 1) * step_val
	return default_val

## Construit la liste formatée de toutes les statistiques à afficher dans l'UI de détail
func get_displayed_stats(lvl: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	# 1. Dégâts d'impact
	var cur_dmg: int = get_damage_for_level(lvl)
	var next_dmg: int = get_damage_for_level(lvl + 1)
	list.append({
		"id": &"damage",
		"icon": "💥",
		"label": "Dégâts d'impact",
		"cur_str": "%d" % cur_dmg,
		"next_str": "%d" % next_dmg,
		"gain_str": "+%d" % (next_dmg - cur_dmg),
		"has_gain": next_dmg > cur_dmg
	})

	# 2. Magnétisme (Aim-Assist vers les ennemis)
	var cur_mag: int = int(roundf(get_magnetism_for_level(lvl)))
	var next_mag: int = int(roundf(get_magnetism_for_level(lvl + 1)))
	list.append({
		"id": &"magnetism",
		"icon": "🧲",
		"label": "Magnétisme",
		"cur_str": "%d" % cur_mag,
		"next_str": "%d" % next_mag,
		"gain_str": "+%d" % (next_mag - cur_mag),
		"has_gain": next_mag > cur_mag
	})

	# 3. Rebond
	var cur_bnc: float = get_bounce_for_level(lvl)
	var next_bnc: float = get_bounce_for_level(lvl + 1)
	list.append({
		"id": &"bounce",
		"icon": "🎾",
		"label": "Rebond",
		"cur_str": "x%.2f" % cur_bnc,
		"next_str": "x%.2f" % next_bnc,
		"gain_str": "+%.2f" % (next_bnc - cur_bnc),
		"has_gain": (next_bnc - cur_bnc) >= 0.01
	})

	# 4. Statistiques spécifiques du mot-clé
	for ks in keyword_stats:
		var stat_id: StringName = ks.get("id", &"")
		var icon: String = ks.get("icon", "✨")
		var label: String = ks.get("name", "Effet")
		var fmt: String = ks.get("format", "int")
		var unit: String = ks.get("unit", "")
		var cur_val: float = get_keyword_stat_value(stat_id, lvl)
		var next_val: float = get_keyword_stat_value(stat_id, lvl + 1)

		var cur_s: String = ""
		var next_s: String = ""
		var gain_s: String = ""
		var has_gain: bool = false

		match fmt:
			"int":
				var c_i: int = int(roundf(cur_val))
				var n_i: int = int(roundf(next_val))
				cur_s = "%d%s" % [c_i, unit]
				next_s = "%d%s" % [n_i, unit]
				gain_s = "+%d%s" % [n_i - c_i, unit]
				has_gain = n_i > c_i
			"duration":
				cur_s = "%.1fs" % cur_val
				next_s = "%.1fs" % next_val
				gain_s = "+%.1fs" % (next_val - cur_val)
				has_gain = (next_val - cur_val) >= 0.05
			"percent":
				var c_p: int = int(roundf(cur_val * 100.0))
				var n_p: int = int(roundf(next_val * 100.0))
				cur_s = "%d%%" % c_p
				next_s = "%d%%" % n_p
				gain_s = "+%d%%" % (n_p - c_p)
				has_gain = n_p > c_p
			_:
				cur_s = "%.1f%s" % [cur_val, unit]
				next_s = "%.1f%s" % [next_val, unit]
				gain_s = "+%.1f%s" % [next_val - cur_val, unit]
				has_gain = (next_val - cur_val) >= 0.05

		list.append({
			"id": stat_id,
			"icon": icon,
			"label": label,
			"cur_str": cur_s,
			"next_str": next_s,
			"gain_str": gain_s,
			"has_gain": has_gain
		})

	return list

# Paliers de cartes pour chaque niveau (ex: niveau 1 vers 2 = 2 cartes, etc.)
@export var cards_to_level: Array[int] = [2, 4, 10, 20, 50, 100]
# Coûts d'amélioration en or pour chaque niveau
@export var gold_cost_to_level: Array[int] = [20, 50, 150, 400, 1000, 2500]

func get_required_cards_for_level(current_lvl: int) -> int:
	var idx: int = maxi(0, current_lvl - 1)
	if idx < cards_to_level.size():
		return cards_to_level[idx]
	return 200 # Palier max

func get_gold_cost_for_level(current_lvl: int) -> int:
	var idx: int = maxi(0, current_lvl - 1)
	if idx < gold_cost_to_level.size():
		return gold_cost_to_level[idx]
	return 5000
