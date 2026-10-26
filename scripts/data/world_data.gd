class_name WorldData
extends Resource

const LevelData = preload("res://scripts/data/level_data.gd")

## Configuration d'un Monde de Campagne regroupant ses niveaux et son thème d'arène.

@export var id: StringName = &"world_1"
@export var world_number: int = 1
@export var display_name: String = "Plage Sucrée"
@export var subtitle: String = "Le rivage de sucre rose et d'océan pétillant"
@export var arena_texture: Texture2D
@export var arena_modulate: Color = Color.WHITE
@export var canopy_texture: Texture2D
@export var flipper_texture: Texture2D
@export var wall_left_texture: Texture2D
@export var wall_right_texture: Texture2D
@export var top_extension_texture: Texture2D
@export var saga_map_texture: Texture2D
@export var pin_positions: Array[Vector2] = []
@export var levels: Array[LevelData] = []
@export var completion_reward_booster_id: StringName = &"golden_crush"

func get_level(lvl_num: int) -> LevelData:
	for lvl in levels:
		if lvl != null and lvl.level_number == lvl_num:
			return lvl
	return null

func get_max_possible_stars() -> int:
	return levels.size() * 3

func get_total_stars(campaign_levels_data: Dictionary) -> int:
	var total: int = 0
	for lvl in levels:
		if lvl != null:
			var info: Dictionary = campaign_levels_data.get(String(lvl.id), {})
			total += int(info.get("stars", 0))
	return total
