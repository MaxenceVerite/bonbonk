class_name CandyShardProjectile
extends Node2D

## Projectile éclat de bonbon multicolore (Lollipop / Twistypop).
## Éjecté en gerbe radiale, puis traque avec agilité un ennemi vivant aléatoire.
## Dispose d'un Object Pooling intégré pour garantir 0 allocation saccadée sur mobile.

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

static var _pool: Array[CandyShardProjectile] = []

var target_enemy: Node2D = null
var shard_color: Color = Color.WHITE
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO

var _burst_timer: float = 0.14
var _current_speed: float = 400.0
var _max_speed: float = 850.0
var _steer_rate: float = 12.0
var _lifetime: float = 0.0
var _shard_rotation: float = 0.0
var _spin_speed: float = 16.0

# Traînée lumineuse fluide (Buffer circulaire fixe de positions)
var _trail: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 5

func _init() -> void:
	z_index = 25

func _ready() -> void:
	for i in range(MAX_TRAIL_POINTS):
		_trail.append(global_position)

static func spawn(
	parent: Node,
	start_pos: Vector2,
	target: Node2D,
	color: Color,
	dmg: int,
	initial_angle: float
) -> CandyShardProjectile:
	var proj: CandyShardProjectile = null
	if not _pool.is_empty():
		proj = _pool.pop_back()
	else:
		proj = CandyShardProjectile.new()

	if proj.get_parent() != parent:
		if proj.get_parent() != null:
			proj.get_parent().remove_child(proj)
		parent.add_child(proj)

	proj.global_position = start_pos
	proj.setup(target, color, dmg, initial_angle)
	return proj

func setup(target: Node2D, color: Color, dmg: int, initial_angle: float) -> void:
	target_enemy = target
	shard_color = color
	damage = dmg
	_lifetime = 0.0
	_burst_timer = randf_range(0.10, 0.16)
	_current_speed = randf_range(380.0, 520.0)
	_spin_speed = randf_range(12.0, 22.0) * (1.0 if randf() > 0.5 else -1.0)
	_shard_rotation = randf() * TAU

	# Impulsion initiale éclatante radiale
	velocity = Vector2.from_angle(initial_angle) * _current_speed

	_trail.clear()
	for i in range(MAX_TRAIL_POINTS):
		_trail.append(global_position)

	visible = true
	set_physics_process(true)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_lifetime += delta
	_shard_rotation += _spin_speed * delta

	# Mise à jour du buffer de traînée
	_trail.push_front(global_position)
	if _trail.size() > MAX_TRAIL_POINTS:
		_trail.pop_back()

	if _burst_timer > 0.0:
		# 1. Phase de projection initiale
		_burst_timer -= delta
		global_position += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)
	else:
		# 2. Phase de guidage agile vers la cible (Homing)
		var valid_target: bool = (
			target_enemy != null and 
			is_instance_valid(target_enemy) and 
			not (target_enemy is Enemy and (target_enemy as Enemy).is_dying())
		)

		if not valid_target:
			# Tentative de réassignation vers un autre ennemi vivant
			target_enemy = _find_alternate_target()
			valid_target = (target_enemy != null)

		if valid_target:
			var to_target: Vector2 = target_enemy.global_position - global_position
			var dist: float = to_target.length()

			# Vérification d'impact
			if dist <= 24.0:
				_on_hit_target()
				return

			var desired_dir: Vector2 = to_target.normalized()
			_current_speed = move_toward(_current_speed, _max_speed, 950.0 * delta)
			velocity = velocity.move_toward(desired_dir * _current_speed, _steer_rate * _current_speed * delta)
		else:
			# Aucun ennemi restant : s'envole gracieusement vers le haut
			var escape_dir: Vector2 = Vector2.UP.rotated(randf_range(-0.3, 0.3))
			_current_speed = move_toward(_current_speed, _max_speed * 0.8, 600.0 * delta)
			velocity = velocity.move_toward(escape_dir * _current_speed, 10.0 * delta)

		global_position += velocity * delta

	# Sécurité durée de vie ou sortie de table
	if _lifetime > 2.8 or global_position.y < -80.0 or global_position.y > 1320.0:
		despawn()
		return

	queue_redraw()

func _find_alternate_target() -> Node2D:
	var alive: Array[Enemy] = []
	for e in Enemy.get_active_enemies():
		if e != null and is_instance_valid(e) and not e.is_dying():
			alive.append(e)
	if alive.is_empty():
		return null
	return alive.pick_random()

func _on_hit_target() -> void:
	if target_enemy != null and is_instance_valid(target_enemy):
		if target_enemy.has_method("take_hit"):
			target_enemy.take_hit(damage, self, velocity)

	# Éclatement de bonbon / étincelles sucrées colorées
	if get_parent() != null:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			shard_color,
			shard_color.lightened(0.45),
			Color.WHITE,
			10
		)

	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(20)

	despawn()

func despawn() -> void:
	set_physics_process(false)
	visible = false
	target_enemy = null
	if not _pool.has(self):
		_pool.append(self)

func _draw() -> void:
	# 1. Traînée lumineuse derrière l'éclat
	if _trail.size() > 1:
		for i in range(1, _trail.size()):
			var local_pos: Vector2 = _trail[i] - global_position
			var alpha: float = (1.0 - float(i) / float(_trail.size())) * 0.45
			var trail_radius: float = maxf(1.5, 4.5 * (1.0 - float(i) / float(_trail.size())))
			draw_circle(local_pos, trail_radius, Color(shard_color.r, shard_color.g, shard_color.b, alpha))

	# 2. Halo lumineux extérieur
	draw_circle(Vector2.ZERO, 9.0, Color(shard_color.r, shard_color.g, shard_color.b, 0.35))

	# 3. Cristal / Éclat de sucre facetté en losange
	var c: float = cos(_shard_rotation)
	var s: float = sin(_shard_rotation)

	var p_top: Vector2 = Vector2(-s * -10.0, c * -10.0)
	var p_bottom: Vector2 = Vector2(-s * 10.0, c * 10.0)
	var p_right: Vector2 = Vector2(c * 6.0, s * 6.0)
	var p_left: Vector2 = Vector2(c * -6.0, s * -6.0)

	var diamond_poly: PackedVector2Array = PackedVector2Array([p_top, p_right, p_bottom, p_left])
	draw_colored_polygon(diamond_poly, shard_color)

	# 4. Facette interne claire et reflet éclatant
	var p_in_top: Vector2 = p_top * 0.65
	var p_in_right: Vector2 = p_right * 0.65
	var p_in_bottom: Vector2 = p_bottom * 0.65
	var p_in_left: Vector2 = p_left * 0.65
	var inner_poly: PackedVector2Array = PackedVector2Array([p_in_top, p_in_right, p_in_bottom, p_in_left])
	draw_colored_polygon(inner_poly, shard_color.lightened(0.55))

	# 5. Point central scintillant blanc
	draw_circle(Vector2.ZERO, 2.2, Color.WHITE)
