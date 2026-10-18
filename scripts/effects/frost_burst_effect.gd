class_name FrostBurstEffect
extends Node2D

## Effet d'éclat de givre / flocon glacial lors d'un choc avec la Mentox Givrée.
## Rendu vectoriel pur en un seul draw call, avec Object Pooling statique (0 allocation).

static var _pool: Array[FrostBurstEffect] = []

var _elapsed: float = 0.0
var _duration: float = 0.32
var _branch_lengths: PackedFloat32Array = PackedFloat32Array()
const BRANCH_COUNT: int = 8

func _init() -> void:
	top_level = true
	z_index = 35
	visible = false
	set_process(false)
	_branch_lengths.resize(BRANCH_COUNT)
	for i in range(BRANCH_COUNT):
		_branch_lengths[i] = 24.0

static func spawn(tree: SceneTree, at_pos: Vector2) -> FrostBurstEffect:
	if tree == null or tree.root == null:
		return null

	var effect: FrostBurstEffect = null
	while not _pool.is_empty():
		var candidate: FrostBurstEffect = _pool.pop_back()
		if is_instance_valid(candidate):
			effect = candidate
			break

	if effect == null:
		effect = FrostBurstEffect.new()

	if effect.get_parent() == null:
		tree.root.add_child.call_deferred(effect)

	effect._activate(at_pos)
	return effect

func _activate(at_pos: Vector2) -> void:
	global_position = at_pos
	_elapsed = 0.0
	for i in range(BRANCH_COUNT):
		_branch_lengths[i] = randf_range(20.0, 36.0)

	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		_recycle()
		return
	queue_redraw()

func _recycle() -> void:
	visible = false
	set_process(false)
	if not _pool.has(self):
		_pool.append(self)

func _draw() -> void:
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var ease_expand: float = 1.0 - pow(1.0 - progress, 2.2)
	var alpha: float = (1.0 - progress) * 0.95

	var branch_color: Color = Color(0.7, 1.2, 1.6, alpha)
	var core_color: Color = Color(1.0, 1.0, 1.0, alpha)

	# 1. Petit éclat central blanc pur
	var center_radius: float = (1.0 - progress) * 5.0
	if center_radius > 0.5:
		draw_circle(Vector2.ZERO, center_radius, core_color)

	# 2. 8 branches cristallines de givre rayonnantes
	for i in range(BRANCH_COUNT):
		var angle: float = (float(i) * TAU / float(BRANCH_COUNT)) + (progress * 0.2)
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var max_len: float = _branch_lengths[i]
		var cur_len: float = max_len * ease_expand

		var start_pt: Vector2 = dir * (cur_len * 0.25)
		var end_pt: Vector2 = dir * cur_len

		# Ligne de la branche
		draw_line(start_pt, end_pt, branch_color, 2.6, true)

		# Petites ramifications latérales (barbillons de flocon)
		if cur_len > 12.0:
			var mid_pt: Vector2 = dir * (cur_len * 0.6)
			var side_norm: Vector2 = Vector2(-dir.y, dir.x)
			var barb_len: float = cur_len * 0.28
			draw_line(mid_pt, mid_pt + (dir * 0.4 + side_norm * 0.6).normalized() * barb_len, branch_color, 1.8, true)
			draw_line(mid_pt, mid_pt + (dir * 0.4 - side_norm * 0.6).normalized() * barb_len, branch_color, 1.8, true)

		# Cristal terminal
		draw_circle(end_pt, 1.8 * (1.0 - progress * 0.5), core_color)
