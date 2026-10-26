class_name StageIntroFXCanvas
extends Control

## Canvas d'effets visuels ultra-juicy pour l'intro de stage :
## - Explosion de 70 confettis multicolores avec tumbling 3D (effet papier qui tournoie) et gravité
## - Onde de choc circulaire néon (Shockwave ring) qui s'étend
## - Rendu vectoriel ultra-performant en un seul draw call dans l'espace UI

const CONFETTI_COUNT: int = 70
const GRAVITY: float = 780.0

var _is_active: bool = false
var _elapsed: float = 0.0
var _duration: float = 1.4

# Confetti data
var _confetti_pos: PackedVector2Array = PackedVector2Array()
var _confetti_vel: PackedVector2Array = PackedVector2Array()
var _confetti_rot: PackedFloat32Array = PackedFloat32Array()
var _confetti_rot_spd: PackedFloat32Array = PackedFloat32Array()
var _confetti_size: PackedVector2Array = PackedVector2Array()
var _confetti_color: Array[Color] = []

# Shockwave ring data
var _shockwave_active: bool = false
var _shockwave_center: Vector2 = Vector2.ZERO
var _shockwave_radius: float = 0.0
var _shockwave_max_radius: float = 480.0
var _shockwave_alpha: float = 0.0

const PALETTE: Array[Color] = [
	Color(1.0, 0.16, 0.52), # Rose bonbon néon
	Color(1.0, 0.88, 0.18), # Jaune citron éclatant
	Color(0.08, 0.88, 1.0),  # Cyan électrique
	Color(0.48, 1.0, 0.18),  # Vert acidulé
	Color(1.0, 0.55, 0.12),  # Orange mandarine
	Color(0.85, 0.28, 1.0),  # Violet marshmallow
	Color(1.0, 1.0, 1.0)     # Blanc sucre glace
]

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_confetti_pos.resize(CONFETTI_COUNT)
	_confetti_vel.resize(CONFETTI_COUNT)
	_confetti_rot.resize(CONFETTI_COUNT)
	_confetti_rot_spd.resize(CONFETTI_COUNT)
	_confetti_size.resize(CONFETTI_COUNT)
	_confetti_color.resize(CONFETTI_COUNT)

func trigger_burst(center: Vector2) -> void:
	_is_active = true
	_elapsed = 0.0
	_shockwave_active = true
	_shockwave_center = center
	_shockwave_radius = 24.0
	_shockwave_alpha = 1.0

	for i in range(CONFETTI_COUNT):
		_confetti_pos[i] = center + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
		var angle: float = randf_range(0.0, TAU)
		var speed: float = randf_range(300.0, 720.0)
		var vx: float = cos(angle) * speed
		var vy: float = sin(angle) * speed - 160.0 # Biais ascensionnel
		_confetti_vel[i] = Vector2(vx, vy)
		_confetti_rot[i] = randf_range(0.0, TAU)
		_confetti_rot_spd[i] = randf_range(-12.0, 12.0)
		var base_w: float = randf_range(9.0, 16.0)
		var base_h: float = randf_range(6.0, 12.0)
		_confetti_size[i] = Vector2(base_w, base_h)
		_confetti_color[i] = PALETTE[randi() % PALETTE.size()]

	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not _is_active:
		set_process(false)
		return

	_elapsed += delta
	if _elapsed >= _duration:
		_is_active = false
		_shockwave_active = false
		set_process(false)
		queue_redraw()
		return

	# Mise à jour shockwave
	if _shockwave_active:
		_shockwave_radius += (620.0 * delta)
		_shockwave_alpha = maxf(0.0, 1.0 - (_shockwave_radius / _shockwave_max_radius))
		if _shockwave_radius >= _shockwave_max_radius:
			_shockwave_active = false

	# Mise à jour confettis
	var drag: float = 1.0 - (1.6 * delta)
	for i in range(CONFETTI_COUNT):
		_confetti_vel[i].x *= drag
		_confetti_vel[i].y += (GRAVITY * delta)
		_confetti_pos[i] += _confetti_vel[i] * delta
		_confetti_rot[i] += _confetti_rot_spd[i] * delta

	queue_redraw()

func _draw() -> void:
	if not _is_active:
		return

	# 1. Onde de choc néon
	if _shockwave_active and _shockwave_alpha > 0.01:
		var ring_color: Color = Color(1.0, 0.35, 0.75, _shockwave_alpha * 0.85)
		draw_arc(_shockwave_center, _shockwave_radius, 0.0, TAU, 40, ring_color, 7.0, true)
		var inner_color: Color = Color(1.0, 0.95, 0.45, _shockwave_alpha * 0.55)
		draw_arc(_shockwave_center, maxf(1.0, _shockwave_radius - 10.0), 0.0, TAU, 36, inner_color, 3.5, true)

	# 2. Confettis avec tumbling 3D
	var alpha_factor: float = clampf(1.0 - (_elapsed / _duration), 0.0, 1.0)
	for i in range(CONFETTI_COUNT):
		var col: Color = _confetti_color[i]
		col.a = alpha_factor
		var pos: Vector2 = _confetti_pos[i]
		var sz: Vector2 = _confetti_size[i]

		var aspect_x: float = cos(_confetti_rot[i])
		var w: float = sz.x * aspect_x
		var h: float = sz.y

		var rect: Rect2 = Rect2(-w * 0.5, -h * 0.5, w, h)
		draw_set_transform(pos, _confetti_rot[i] * 0.4, Vector2.ONE)
		draw_rect(rect, col)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
