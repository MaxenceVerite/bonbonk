class_name StunStatusEffect
extends StatusEffect

## Altération d'état Étourdissement / Choc électrique (Stun).
## Immobilise la cible avec secousses visuelles rapides.

func _init(p_duration: float = 2.0) -> void:
	id = &"stun"
	duration = p_duration
	max_duration = p_duration

func on_applied(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		var tw: Tween = visual.create_tween()
		visual.modulate = Color(1.8, 2.2, 0.4, 1.0)
		tw.tween_property(visual, "modulate", Color(0.6, 1.3, 1.5, 1.0), 0.2)

func on_tick(_target: CharacterBody2D, visual: Node2D, delta: float) -> void:
	duration -= delta
	if visual != null:
		visual.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))

	if duration <= 0.0:
		is_expired = true

func on_removed(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		visual.position = Vector2.ZERO
		visual.modulate = Color.WHITE

func is_immobilizing() -> bool:
	return true
