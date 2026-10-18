class_name LightningBoltEffect
extends Node2D

## Effet d'éclair électrique procedural et percutant.
## Génère un arc principal en zigzag avec branches secondaires et éclat lumineux.
## Dispose d'un Object Pooling statique pour garantir 0 allocation sur mobile.

static var _pool: Array[LightningBoltEffect] = []

var _main_line: Line2D = null
var _core_line: Line2D = null
var _fork_line: Line2D = null

func _init() -> void:
	top_level = true
	z_index = 40

	# 1. Halo extérieur lumineux
	_main_line = Line2D.new()
	_main_line.width = 7.0
	_main_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_main_line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_main_line)

	# 2. Cœur blanc chaud intense
	_core_line = Line2D.new()
	_core_line.width = 2.5
	_core_line.default_color = Color(1.2, 1.2, 1.2, 1.0)
	_core_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_core_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_core_line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_core_line)

	# 3. Ramification secondaire (Fork)
	_fork_line = Line2D.new()
	_fork_line.width = 3.5
	_fork_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_fork_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_fork_line)

static func spawn(
	tree: SceneTree,
	from_pos: Vector2,
	to_pos: Vector2,
	bolt_color: Color = Color(0.35, 0.95, 1.0, 1.0),
	duration: float = 0.22
) -> LightningBoltEffect:
	if tree == null or tree.root == null:
		return null

	var effect: LightningBoltEffect = null
	while not _pool.is_empty():
		var candidate: LightningBoltEffect = _pool.pop_back()
		if is_instance_valid(candidate):
			effect = candidate
			break

	if effect == null:
		effect = LightningBoltEffect.new()

	if effect.get_parent() == null:
		tree.root.add_child.call_deferred(effect)

	effect._activate(from_pos, to_pos, bolt_color, duration)
	return effect

func _activate(from: Vector2, to: Vector2, bolt_color: Color, duration: float) -> void:
	visible = true
	modulate.a = 1.0
	_main_line.default_color = bolt_color
	_fork_line.default_color = bolt_color.lightened(0.2)

	var dir: Vector2 = to - from
	var dist: float = dir.length()
	var normal: Vector2 = Vector2(-dir.y, dir.x).normalized() if dist > 0.001 else Vector2.UP

	var steps: int = clampi(int(dist / 28.0), 5, 14)
	var main_pts: PackedVector2Array = PackedVector2Array()
	main_pts.append(from)

	var fork_start_idx: int = int(steps * 0.45)
	var fork_start_pt: Vector2 = Vector2.ZERO

	for i in range(1, steps):
		var t: float = float(i) / float(steps)
		var base_pt: Vector2 = from.lerp(to, t)
		# Enveloppe d'amplitude (plus d'amplitude au milieu de l'arc)
		var envelope: float = sin(t * PI)
		var jitter_mag: float = randf_range(-22.0, 22.0) * envelope
		var pt: Vector2 = base_pt + normal * jitter_mag
		main_pts.append(pt)
		if i == fork_start_idx:
			fork_start_pt = pt

	main_pts.append(to)
	_main_line.points = main_pts
	_core_line.points = main_pts

	# Génération de la ramification (Fork)
	if fork_start_pt != Vector2.ZERO:
		var fork_pts: PackedVector2Array = PackedVector2Array()
		fork_pts.append(fork_start_pt)
		var fork_dir: Vector2 = (dir.normalized() * 0.6 + normal * (1.0 if randf() < 0.5 else -1.0) * 0.8).normalized()
		var p1: Vector2 = fork_start_pt + fork_dir * randf_range(20.0, 35.0) + normal * randf_range(-8.0, 8.0)
		var p2: Vector2 = p1 + fork_dir * randf_range(20.0, 30.0)
		fork_pts.append(p1)
		fork_pts.append(p2)
		_fork_line.points = fork_pts
		_fork_line.visible = true
	else:
		_fork_line.visible = false

	# Disparition avec flash et fondu rapide
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		if not _pool.has(self):
			_pool.append(self)
	)
