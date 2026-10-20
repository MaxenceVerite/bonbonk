class_name ParryImpactEffect
extends Node2D

## Effet d'impact visuel lors d'une parade de flipper réussie (Starburst doré & Onde de choc).
## Entièrement vectoriel via _draw() : 0 allocation par frame, 60/120 FPS garanti, recyclé en pool.

class Spark:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var length: float = 8.0
	var color: Color = Color.WHITE

static var _pool: Array = []

var _sparks: Array[Spark] = []
var _time_alive: float = 0.0
var _duration: float = 0.18
var _is_active: bool = false
var _impact_angle: float = 0.0

const COLOR_STAR_CORE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_STAR_GOLD: Color = Color(1.0, 0.88, 0.28, 1.0)
const COLOR_SHOCKWAVE: Color = Color(1.0, 0.82, 0.18, 0.85)
const COLOR_SPARK: Color = Color(1.0, 0.94, 0.55, 1.0)

func _init() -> void:
	z_index = 25
	z_as_relative = true
	visible = false
	set_process(false)
	for i in range(8):
		_sparks.append(Spark.new())

static func spawn(parent: Node2D, spawn_pos: Vector2, push_dir: Vector2) -> Node2D:
	if parent == null or not parent.is_inside_tree():
		return null

	var effect: Node2D = null
	while not _pool.is_empty():
		var candidate: Variant = _pool.pop_back()
		if is_instance_valid(candidate) and candidate is Node2D:
			effect = candidate
			break

	if effect == null:
		var script_ref: GDScript = load("res://scripts/effects/parry_impact_effect.gd") as GDScript
		effect = script_ref.new() as Node2D

	if effect.get_parent() != parent:
		if effect.get_parent() != null:
			effect.get_parent().remove_child(effect)
		parent.add_child(effect)

	effect.global_position = spawn_pos
	if effect.has_method(&"activate"):
		effect.call(&"activate", push_dir)
	return effect

func activate(push_dir: Vector2) -> void:
	_time_alive = 0.0
	_is_active = true
	_impact_angle = push_dir.angle()
	visible = true
	set_process(true)

	var base_angle: float = push_dir.angle()
	for i in range(_sparks.size()):
		var s: Spark = _sparks[i]
		s.pos = Vector2.ZERO
		var spread: float = randf_range(-0.55, 0.55)
		var spd: float = randf_range(260.0, 480.0)
		var dir: Vector2 = Vector2.from_angle(base_angle + spread)
		s.vel = dir * spd
		s.length = randf_range(7.0, 14.0)
		s.color = COLOR_SPARK.lerp(COLOR_STAR_GOLD, randf_range(0.0, 0.5))

	queue_redraw()

func _process(delta: float) -> void:
	if not _is_active:
		return

	_time_alive += delta
	var progress: float = clampf(_time_alive / _duration, 0.0, 1.0)

	for s in _sparks:
		s.pos += s.vel * delta
		s.vel *= 0.88

	queue_redraw()

	if progress >= 1.0:
		_finish()

func _draw() -> void:
	if not _is_active:
		return

	var progress: float = clampf(_time_alive / _duration, 0.0, 1.0)
	var alpha: float = 1.0 - pow(progress, 1.8)

	# 1. Étoile centrale effilée à 4 branches (Starburst diamant)
	# Disparaît plus rapidement (en ~0.10s) pour un flash tranchant
	var star_prog: float = clampf(_time_alive / 0.10, 0.0, 1.0)
	if star_prog < 1.0:
		var star_alpha: float = (1.0 - star_prog)
		var long_arm: float = lerpf(12.0, 38.0, 1.0 - pow(1.0 - star_prog, 2.0))
		var short_arm: float = long_arm * 0.22

		# Branche horizontale & verticale orientées selon l'angle d'impact
		var forward: Vector2 = Vector2.from_angle(_impact_angle)
		var perp: Vector2 = Vector2(-forward.y, forward.x)

		# Polygone d'étoile effilée (Losange à pointes longues)
		var p_top: Vector2 = forward * long_arm
		var p_bot: Vector2 = -forward * long_arm
		var p_right: Vector2 = perp * short_arm
		var p_left: Vector2 = -perp * short_arm

		var star_col_gold: Color = COLOR_STAR_GOLD
		star_col_gold.a = star_alpha
		draw_colored_polygon(PackedVector2Array([p_top, p_right, p_bot, p_left]), star_col_gold)

		# Étoile transversale perpendiculaire (forme de croix scintillante)
		var t_top: Vector2 = perp * (long_arm * 0.7)
		var t_bot: Vector2 = -perp * (long_arm * 0.7)
		var t_right: Vector2 = forward * (short_arm * 0.8)
		var t_left: Vector2 = -forward * (short_arm * 0.8)
		draw_colored_polygon(PackedVector2Array([t_top, t_right, t_bot, t_left]), star_col_gold)

		# Cœur étincelant blanc
		var core_col: Color = COLOR_STAR_CORE
		core_col.a = star_alpha
		draw_circle(Vector2.ZERO, 5.0 * (1.0 - star_prog), core_col)

	# 2. Anneau d'onde de choc doré en expansion rapide (10px -> 52px)
	var ring_radius: float = lerpf(8.0, 52.0, 1.0 - pow(1.0 - progress, 2.5))
	var ring_col: Color = COLOR_SHOCKWAVE
	ring_col.a = alpha * 0.9
	var ring_width: float = maxf(1.0, 3.5 * alpha)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, ring_col, ring_width, true)

	# 3. Traits d'étincelles dorées jaillissant dans la direction de frappe
	for s in _sparks:
		var spark_col: Color = s.color
		spark_col.a = alpha
		var tail_dir: Vector2 = s.vel.normalized()
		var p1: Vector2 = s.pos
		var p2: Vector2 = s.pos - tail_dir * (s.length * alpha)
		draw_line(p1, p2, spark_col, 2.0 * alpha)

func _finish() -> void:
	_is_active = false
	visible = false
	set_process(false)
	if get_parent() != null:
		get_parent().remove_child(self)
	if not _pool.has(self):
		_pool.append(self)
