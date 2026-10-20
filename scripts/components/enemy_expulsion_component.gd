class_name EnemyExpulsionComponent
extends Node

## Gère la trajectoire balistique en cloche hors de l'arène
## pour les ennemis légers éliminés par un impact de bille.

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

var _enemy: CharacterBody2D = null
var _visual_container: Node2D = null
var _collision_shape: CollisionShape2D = null
var _enemy_data: EnemyData = null
var _despawn_callback: Callable = Callable()

var _is_expelled: bool = false
var _expulsion_velocity: Vector2 = Vector2.ZERO
var _expulsion_spin: float = 0.0
var _expulsion_timer: float = 0.0

func setup(
	enemy: CharacterBody2D,
	visual_container: Node2D,
	collision_shape: CollisionShape2D,
	enemy_data: EnemyData,
	despawn_cb: Callable
) -> void:
	_enemy = enemy
	_visual_container = visual_container
	_collision_shape = collision_shape
	_enemy_data = enemy_data
	_despawn_callback = despawn_cb

func is_active() -> bool:
	return _is_expelled

func launch(hit_dir: Vector2) -> void:
	_is_expelled = true
	_expulsion_timer = 0.0

	if _collision_shape != null:
		_collision_shape.set_deferred(&"disabled", true)
	if _enemy != null and _enemy.has_node("Shadow"):
		var shadow_node: Node2D = _enemy.get_node("Shadow") as Node2D
		if shadow_node != null:
			shadow_node.visible = false

	if _enemy != null:
		_enemy.z_index = 100
		_enemy.z_as_relative = false

	var global_pos: Vector2 = _enemy.global_position if _enemy != null else Vector2.ZERO
	var x_sign: float = signf(hit_dir.x) if absf(hit_dir.x) > 0.15 else (signf(global_pos.x - 360.0) if absf(global_pos.x - 360.0) > 20.0 else (1.0 if randf() > 0.5 else -1.0))
	var launch_vx: float = x_sign * randf_range(520.0, 780.0)
	var launch_vy: float = -randf_range(1700.0, 2100.0)
	_expulsion_velocity = Vector2(launch_vx, launch_vy)
	_expulsion_spin = x_sign * randf_range(22.0, 32.0)

	if _visual_container != null:
		_visual_container.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var tw: Tween = _visual_container.create_tween()
		tw.tween_property(_visual_container, "modulate", Color.WHITE, 0.12)

	if _enemy_data != null and _enemy != null:
		JuiceSplatScript.spawn(
			_enemy.get_parent(),
			global_pos,
			_enemy_data.juice_primary_color,
			_enemy_data.juice_secondary_color,
			_enemy_data.juice_accent_color,
			8
		)

func update(delta: float) -> bool:
	if not _is_expelled or _enemy == null:
		return false

	_expulsion_timer += delta
	_enemy.global_position += _expulsion_velocity * delta
	_expulsion_velocity.y += 2100.0 * delta

	if _visual_container != null:
		_visual_container.rotation += _expulsion_spin * delta
		if _expulsion_timer < 0.25:
			var pop_ratio: float = _expulsion_timer / 0.25
			_visual_container.scale = Vector2.ONE * lerpf(1.0, 1.6, pop_ratio)
		else:
			_visual_container.scale = Vector2.ONE * 1.6

	var is_out_of_arena: bool = (
		_enemy.position.x < -120.0 or 
		_enemy.position.x > 840.0 or 
		_enemy.position.y < -150.0 or 
		_enemy.position.y > 1500.0
	)
	if is_out_of_arena or _expulsion_timer > 3.0:
		if _despawn_callback.is_valid():
			_despawn_callback.call()

	return true
