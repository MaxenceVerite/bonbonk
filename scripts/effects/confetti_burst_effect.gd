class_name ConfettiBurstEffect
extends Node2D

## Éclat de confettis multicolores lors de l'éclatement d'une bille Brise-Dents (Jawbreaker).
## Rendu vectoriel pur en un seul draw call, avec Object Pooling statique (0 allocation).

static var _pool: Array[ConfettiBurstEffect] = []

const SPARK_COUNT: int = 14
const DURATION: float = 0.30

var _elapsed: float = 0.0
var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _rot: PackedFloat32Array = PackedFloat32Array()
var _rot_speed: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _color_idx: PackedInt32Array = PackedInt32Array()

const COLORS: Array[Color] = [
	Color(1.0, 0.25, 0.45, 1.0),
	Color(0.2, 0.92, 0.4, 1.0),
	Color(0.2, 0.65, 1.0, 1.0),
	Color(1.0, 0.85, 0.2, 1.0),
	Color(0.92, 0.32, 0.92, 1.0)
]

func _init() -> void:
	top_level = true
	z_index = 35
	visible = false
	set_process(false)

	_pos.resize(SPARK_COUNT)
	_vel.resize(SPARK_COUNT)
	_rot.resize(SPARK_COUNT)
	_rot_speed.resize(SPARK_COUNT)
	_size.resize(SPARK_COUNT)
	_color_idx.resize(SPARK_COUNT)

static func spawn(tree: SceneTree, at_pos: Vector2) -> ConfettiBurstEffect:
	if tree == null or tree.root == null:
		return null

	var effect: ConfettiBurstEffect = null
	while not _pool.is_empty():
		var candidate: ConfettiBurstEffect = _pool.pop_back()
		if is_instance_valid(candidate):
			effect = candidate
			break

	if effect == null:
		effect = ConfettiBurstEffect.new()

	if effect.get_parent() == null:
		tree.root.add_child.call_deferred(effect)

	effect._activate(at_pos)
	return effect

func _activate(at_pos: Vector2) -> void:
	global_position = at_pos
	_elapsed = 0.0

	for i in range(SPARK_COUNT):
		var ang: float = randf_range(0.0, TAU)
		var spd: float = randf_range(140.0, 280.0)
		_pos[i] = Vector2.ZERO
		_vel[i] = Vector2(cos(ang), sin(ang)) * spd
		_rot[i] = randf_range(0.0, TAU)
		_rot_speed[i] = randf_range(-12.0, 12.0)
		_size[i] = randf_range(3.5, 6.0)
		_color_idx[i] = i % COLORS.size()

	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		_recycle()
		return

	# Mise à jour balistique avec friction
	var drag: float = 1.0 - (2.5 * delta)
	for i in range(SPARK_COUNT):
		_vel[i] *= drag
		_pos[i] += _vel[i] * delta
		_rot[i] += _rot_speed[i] * delta

	queue_redraw()

func _recycle() -> void:
	visible = false
	set_process(false)
	if not _pool.has(self):
		_pool.append(self)

func _draw() -> void:
	var progress: float = clampf(_elapsed / DURATION, 0.0, 1.0)
	var alpha: float = (1.0 - progress)

	for i in range(SPARK_COUNT):
		var base_col: Color = COLORS[_color_idx[i]]
		var col: Color = Color(base_col.r, base_col.g, base_col.b, alpha)
		var p: Vector2 = _pos[i]
		var r: float = _rot[i]
		var s: float = _size[i] * (1.0 - progress * 0.3)

		var c_rad: float = cos(r)
		var s_rad: float = sin(r)
		var rx: Vector2 = Vector2(c_rad, s_rad) * s
		var ry: Vector2 = Vector2(-s_rad, c_rad) * (s * 0.7)

		var poly: PackedVector2Array = PackedVector2Array([
			p - rx - ry,
			p + rx - ry,
			p + rx + ry,
			p - rx + ry
		])
		draw_colored_polygon(poly, col)
