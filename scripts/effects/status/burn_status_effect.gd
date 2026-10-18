class_name BurnStatusEffect
extends StatusEffect

## Altération d'état Brûlure (Burn DoT).
## Inflige des dégâts périodiques et applique une pulsation incandescente sur le visuel.

var damage_per_tick: int = 1
var tick_interval: float = 0.5
var _tick_timer: float = 0.5
var _visual_flicker: float = 0.0

func _init(p_duration: float = 3.0, p_damage: int = 1, p_interval: float = 0.5) -> void:
	id = &"burn"
	duration = p_duration
	max_duration = p_duration
	damage_per_tick = p_damage
	tick_interval = p_interval
	_tick_timer = p_interval

func on_applied(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		var tw: Tween = visual.create_tween()
		visual.modulate = Color(2.6, 1.2, 0.4, 1.0)
		tw.tween_property(visual, "modulate", Color(1.7, 0.75, 0.4, 1.0), 0.15)

func on_tick(target: CharacterBody2D, visual: Node2D, delta: float) -> void:
	duration -= delta
	_tick_timer -= delta
	_visual_flicker += delta * 12.0

	if visual != null:
		var heat_pulse: float = 0.5 + 0.5 * sin(_visual_flicker)
		visual.modulate = Color(1.3 + 0.5 * heat_pulse, 0.6 + 0.3 * heat_pulse, 0.35, 1.0)

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		if target != null and is_instance_valid(target) and not target.is_queued_for_deletion():
			var hit_ctx: HitContext = HitContext.create(null, target, damage_per_tick, target.global_position, Vector2.ZERO, HitContext.DamageType.DOT)
			if target.has_method(&"take_hit_with_context"):
				target.take_hit_with_context(hit_ctx)
			elif target.has_method(&"take_hit"):
				target.take_hit(damage_per_tick, null, Vector2.ZERO)

			if visual != null:
				var tw: Tween = visual.create_tween()
				tw.tween_property(visual, "scale", Vector2(1.12, 0.88), 0.05)
				tw.tween_property(visual, "scale", Vector2.ONE, 0.08)

	if duration <= 0.0:
		is_expired = true

func on_removed(_target: CharacterBody2D, visual: Node2D) -> void:
	if visual != null:
		visual.modulate = Color.WHITE
