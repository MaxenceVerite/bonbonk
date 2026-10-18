class_name StickyStatusEffect
extends StatusEffect

## Altération d'état Ralentissement Collant (Caramel).
## Ralentit l'ennemi et s'attache à lui jusqu'à sa mort ou détachement.

var attached_ball: Node2D = null
var slow_multiplier: float = 0.35

func _init(p_ball: Node2D = null, p_slow: float = 0.35) -> void:
	id = &"sticky"
	attached_ball = p_ball
	slow_multiplier = p_slow
	duration = 9999.0
	max_duration = 9999.0

func on_applied(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		var tw: Tween = visual.create_tween()
		visual.modulate = Color(1.8, 1.2, 0.4, 1.0)
		tw.tween_property(visual, "modulate", Color(1.2, 0.9, 0.6, 1.0), 0.2)

func on_removed(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		visual.modulate = Color.WHITE

func cleanup_on_death() -> void:
	if attached_ball != null and is_instance_valid(attached_ball):
		if attached_ball.has_method(&"shatter"):
			attached_ball.shatter()
		else:
			attached_ball.queue_free()
		attached_ball = null

func get_speed_multiplier() -> float:
	return slow_multiplier
