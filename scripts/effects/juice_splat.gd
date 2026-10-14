class_name JuiceSplatEffect
extends Node2D

## Effet visuel percutant d'éclatement de jus de fruit (splat, gouttelettes & pépins).
## Conçu pour être très léger (un seul draw call procédural) avec Object Pooling intégré (zéro GC).

class Droplet:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var base_radius: float = 5.0
	var current_radius: float = 5.0
	var color: Color = Color.WHITE
	var is_accent: bool = false
	var life: float = 0.0
	var max_life: float = 0.55

static var _pool: Array[JuiceSplatEffect] = []

var _droplets: Array[Droplet] = []
var _active_droplets_count: int = 0
var _time_alive: float = 0.0
var _total_duration: float = 0.6
var _shockwave_radius: float = 8.0
var _shockwave_max_radius: float = 46.0
var _shockwave_color: Color = Color.WHITE

func _init() -> void:
	# Pré-allocation d'un buffer fixe de gouttelettes pour éliminer tout 'Droplet.new()' frame par frame
	for i in range(32):
		_droplets.append(Droplet.new())

func setup(primary_color: Color, secondary_color: Color, accent_color: Color, count: int = 18) -> void:
	_shockwave_color = primary_color
	_shockwave_color.a = 0.8
	_time_alive = 0.0
	visible = true
	set_process(true)

	_active_droplets_count = mini(count, _droplets.size())
	for i in range(_active_droplets_count):
		var d: Droplet = _droplets[i]
		var angle: float = randf() * TAU
		# Vitesse variée avec forte dispersion radiale
		var speed: float = randf_range(160.0, 420.0)
		d.vel = Vector2.from_angle(angle) * speed
		# Légère impulsion vers le haut pour arc parabolique
		d.vel.y -= randf_range(40.0, 120.0)
		d.pos = Vector2.from_angle(angle) * randf_range(2.0, 10.0)

		var roll: float = randf()
		if roll < 0.60:
			# Jus principal (majoritaire)
			d.color = primary_color
			d.base_radius = randf_range(4.0, 7.5)
			d.is_accent = false
		elif roll < 0.85:
			# Pulpe / Jus secondaire
			d.color = secondary_color
			d.base_radius = randf_range(3.5, 6.0)
			d.is_accent = false
		else:
			# Pépins / zeste / graines
			d.color = accent_color
			d.base_radius = randf_range(2.0, 4.0)
			d.is_accent = true

		d.current_radius = d.base_radius
		d.max_life = randf_range(0.4, 0.6)
		d.life = 0.0

	queue_redraw()

func _process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= _total_duration:
		_recycle()
		return

	# Onde de choc centrale
	var shock_progress: float = clampf(_time_alive / 0.22, 0.0, 1.0)
	_shockwave_radius = lerpf(8.0, _shockwave_max_radius, ease(shock_progress, 0.4))
	_shockwave_color.a = clampf(1.0 - shock_progress, 0.0, 1.0) * 0.75

	# Simulation physique des gouttelettes
	for i in range(_active_droplets_count):
		var d: Droplet = _droplets[i]
		d.life += delta
		var life_ratio: float = clampf(d.life / d.max_life, 0.0, 1.0)
		d.pos += d.vel * delta
		# Gravité vers le bas
		d.vel.y += 650.0 * delta
		# Résistance de l'air
		d.vel *= (1.0 - 1.6 * delta)
		# Rétrécissement progressif et fondu
		d.current_radius = lerpf(d.base_radius, 0.5, life_ratio)
		d.color.a = clampf(1.0 - (life_ratio * life_ratio), 0.0, 1.0)

	queue_redraw()

func _recycle() -> void:
	set_process(false)
	visible = false
	if get_parent() != null:
		get_parent().remove_child(self)
	_pool.append(self)

func _draw() -> void:
	# 1. Onde de choc juteuse au centre
	if _shockwave_color.a > 0.05:
		draw_circle(Vector2.ZERO, _shockwave_radius, _shockwave_color)

	# 2. Gouttelettes projetées
	for i in range(_active_droplets_count):
		var d: Droplet = _droplets[i]
		if d.current_radius <= 0.2 or d.color.a <= 0.02:
			continue

		var speed: float = d.vel.length()
		if speed > 60.0 and not d.is_accent:
			# Gouttelette étirée le long de sa vitesse (effet cartoon dynamique)
			var dir: Vector2 = d.vel.normalized()
			var tail_length: float = clampf(speed * 0.035, d.current_radius * 0.8, d.current_radius * 2.8)
			var start_pt: Vector2 = d.pos - dir * tail_length
			var end_pt: Vector2 = d.pos + dir * (d.current_radius * 0.5)
			draw_line(start_pt, end_pt, d.color, d.current_radius * 1.8)
			draw_circle(end_pt, d.current_radius, d.color)
		else:
			# Pépin ou gouttelette ralentie : forme circulaire nette
			draw_circle(d.pos, d.current_radius, d.color)

static func spawn(parent: Node, at_pos: Vector2, p_col: Color, s_col: Color, a_col: Color, count: int = 18) -> Node2D:
	var fx: JuiceSplatEffect = null
	while not _pool.is_empty():
		var candidate: JuiceSplatEffect = _pool.pop_back()
		if is_instance_valid(candidate):
			fx = candidate
			break

	if fx == null:
		fx = JuiceSplatEffect.new()

	fx.global_position = at_pos
	if parent != null and fx.get_parent() != parent:
		parent.add_child(fx)
	fx.setup(p_col, s_col, a_col, count)
	return fx
