class_name KeywordFreeze
extends BallKeyword

## Mot-clé "Givré / Glacé" (Mentox Givrée) :
## Givre l'ennemi percuté pendant 2 secondes.

@export var freeze_duration: float = 2.0
@export var impact_damage: int = 1

func _init() -> void:
	id = &"freeze"
	display_name = "Givré"
	description = "Immobilise l'ennemi percuté sous un bloc de givre pendant quelques secondes."

func apply_card_scaling(card_def: CandyCardData, lvl: int) -> void:
	if card_def == null:
		return
	impact_damage = card_def.get_damage_for_level(lvl)
	freeze_duration = card_def.get_keyword_stat_value(&"freeze_duration", lvl, 1.8)

func on_hit_enemy(ball: Ball, enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if ball == null or not is_instance_valid(ball):
		return
		
	enemy.apply_freeze(impact_damage, freeze_duration)
	_spawn_freeze_frost_effect(ball, enemy.global_position)

func _spawn_freeze_frost_effect(ball: Ball, pos: Vector2) -> void:
	var frost: Node2D = Node2D.new()
	frost.global_position = pos
	frost.top_level = true
	
	for i in range(8):
		var flake: Line2D = Line2D.new()
		flake.width = 3.0
		flake.default_color = Color(0.7, 1.2, 1.6, 0.9)
		var angle: float = float(i) * TAU / 8.0
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		flake.points = PackedVector2Array([Vector2.ZERO, dir * randf_range(16.0, 32.0)])
		frost.add_child(flake)
		
	ball.get_tree().root.add_child(frost)
	
	var tw: Tween = frost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(frost, "scale", Vector2(1.5, 1.5), 0.35)
	tw.tween_property(frost, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(frost.queue_free)
