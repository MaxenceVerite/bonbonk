class_name StatusEffectComponent
extends Node

## Composant gérant les altérations d'état (Stun, Freeze, Slow/Glu) sur une entité.
## Isole les timers, modulations visuelles et calculs de vitesse pour alléger l'entité hôte.

signal status_changed(is_immobilized: bool)

var _is_stunned: bool = false
var _stun_timer: float = 0.0

var _is_frozen: bool = false
var _freeze_timer: float = 0.0

var _attached_caramel_ball: Node2D = null
var _slow_factor: float = 1.0

var _target_node: CharacterBody2D = null
var _visual_container: Node2D = null

func setup(target: CharacterBody2D, visual: Node2D) -> void:
	_target_node = target
	_visual_container = visual

func is_immobilized() -> bool:
	return _is_stunned or _is_frozen

func is_stunned() -> bool:
	return _is_stunned

func is_frozen() -> bool:
	return _is_frozen

func get_speed_multiplier() -> float:
	return _slow_factor

func apply_electric_zap(duration: float = 2.0) -> void:
	_is_stunned = true
	_stun_timer = duration
	if _visual_container != null:
		var tw: Tween = _visual_container.create_tween()
		_visual_container.modulate = Color(1.8, 2.2, 0.4, 1.0)
		tw.tween_property(_visual_container, "modulate", Color(0.6, 1.3, 1.5, 1.0), 0.2)
	status_changed.emit(true)

func apply_freeze(duration: float = 2.0) -> void:
	_is_frozen = true
	_freeze_timer = duration
	if _visual_container != null:
		var tw: Tween = _visual_container.create_tween()
		_visual_container.modulate = Color(1.2, 2.0, 2.5, 1.0)
		tw.tween_property(_visual_container, "modulate", Color(0.65, 0.9, 1.25, 1.0), 0.2)
	status_changed.emit(true)

func attach_caramel_ball(caramel_ball: Node2D, speed_multiplier: float = 0.35) -> void:
	_attached_caramel_ball = caramel_ball
	_slow_factor = speed_multiplier
	if _visual_container != null:
		var tw: Tween = _visual_container.create_tween()
		_visual_container.modulate = Color(1.8, 1.2, 0.4, 1.0)
		tw.tween_property(_visual_container, "modulate", Color(1.2, 0.9, 0.6, 1.0), 0.2)

func detach_caramel_ball() -> void:
	_attached_caramel_ball = null
	_slow_factor = 1.0
	if _visual_container != null and not is_immobilized():
		_visual_container.modulate = Color.WHITE

func cleanup_on_death() -> void:
	if _attached_caramel_ball != null and is_instance_valid(_attached_caramel_ball):
		if _attached_caramel_ball.has_method(&"shatter"):
			_attached_caramel_ball.shatter()
		else:
			_attached_caramel_ball.queue_free()
		_attached_caramel_ball = null

func update_status(delta: float) -> void:
	# Gel givré
	if _is_frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			_is_frozen = false
			if not _is_stunned and _visual_container != null:
				_visual_container.modulate = Color.WHITE if _slow_factor >= 1.0 else Color(1.2, 0.9, 0.6, 1.0)
			status_changed.emit(is_immobilized())

	# Stun électrique (secousse visuelle)
	if _is_stunned:
		_stun_timer -= delta
		if _visual_container != null:
			_visual_container.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		if _stun_timer <= 0.0:
			_is_stunned = false
			if _visual_container != null:
				_visual_container.position = Vector2.ZERO
				if not _is_frozen:
					_visual_container.modulate = Color.WHITE if _slow_factor >= 1.0 else Color(1.2, 0.9, 0.6, 1.0)
			status_changed.emit(is_immobilized())
	else:
		if _visual_container != null and not _is_frozen:
			_visual_container.position = Vector2.ZERO
