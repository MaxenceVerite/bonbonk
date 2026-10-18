class_name FreezeStatusEffect
extends StatusEffect

## Altération d'état Gel (Freeze).
## Immobilise complètement la cible et lui donne une teinte bleutée givrée.

func _init(p_duration: float = 2.0) -> void:
	id = &"freeze"
	duration = p_duration
	max_duration = p_duration

func on_applied(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		var tw: Tween = visual.create_tween()
		visual.modulate = Color(1.2, 2.0, 2.5, 1.0)
		tw.tween_property(visual, "modulate", Color(0.65, 0.9, 1.25, 1.0), 0.2)

func on_tick(_target: CharacterBody2D, _visual: Node2D, delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		is_expired = true

func on_removed(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		visual.modulate = Color.WHITE

func is_immobilizing() -> bool:
	return true
