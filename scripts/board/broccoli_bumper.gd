class_name BroccoliBumper
extends CandyBumper

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

## Bumper Brocoli invoqué par le Boss Brocolino.
## Se détruit en 1 seul rebond de bille, provoquant une explosion de jus végétal
## et restaurant le bumper originellement placé sur cet emplacement.

signal broccoli_broken(bumper: BroccoliBumper)

@export var max_hits: int = 1
var _hits_taken: int = 0
var _is_broken: bool = false
var assigned_slot: BumperSlot = null

func _ready() -> void:
	z_index = 10
	add_to_group(&"bumpers")
	add_to_group(&"broccoli_bumpers")
	if not active_bumpers.has(self):
		active_bumpers.append(self)
	if sprite != null:
		_original_scale = sprite.scale

	# Animation d'apparition rebondissante
	scale = Vector2.ZERO
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func on_hit_by_ball(ball: RigidBody2D, _hit_point: Vector2) -> void:
	if _is_broken:
		return

	# Rebond dynamique de la bille
	var push_direction: Vector2 = (ball.global_position - global_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.UP
	var force: float = 720.0
	if ball.has_method(&"apply_bumper_bounce"):
		ball.apply_bumper_bounce(push_direction, force)
	else:
		ball.linear_velocity = push_direction * force

	EventBus.score_changed.emit(75, 75)
	EventBus.ball_hit_bumper.emit(ball, self)

	_hits_taken += 1
	if _hits_taken >= max_hits:
		break_broccoli()
	else:
		_play_jiggle_animation()

func break_broccoli() -> void:
	if _is_broken:
		return
	_is_broken = true
	broccoli_broken.emit(self)

	# Éclaboussure de jus vert végétal
	var spawn_parent: Node = get_parent()
	if spawn_parent != null and spawn_parent.get_parent() != null:
		spawn_parent = spawn_parent.get_parent()
	if spawn_parent == null:
		spawn_parent = self

	JuiceSplatScript.spawn(
		spawn_parent,
		global_position,
		Color(0.28, 0.75, 0.18, 1.0),
		Color(0.18, 0.55, 0.12, 1.0),
		Color(0.85, 0.95, 0.35, 1.0),
		14
	)

	# Vibration haptique
	Input.vibrate_handheld(25)

	# Désactive la collision immédiatement
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", true)

	# Animation d'écrasement et disparition
	var tw: Tween = create_tween().set_parallel(true)
	if sprite != null:
		tw.tween_property(sprite, "scale", _original_scale * 1.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(_finalize_break)

func _finalize_break() -> void:
	if assigned_slot != null and is_instance_valid(assigned_slot):
		assigned_slot.restore_from_temporary_override()
	else:
		queue_free()
