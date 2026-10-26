class_name CarambineStarProjectile
extends ParryableProjectile

## Projectile étoile filante rapide et ultra-lisible tiré par la Boss Carambine.
## - DA Star-Shooting percutante : Étoile dorée lumineuse avec contour prune sombre et aura néon rose fuchsia.
## - Traînée de comète (ribbon trail) pour une trajectoire parfaitement identifiable sur le sable et la pelouse.
## - Timing équilibré (0.88s) pour laisser une fenêtre de lecture et de réflexe satisfaisante au flipper.

const HitstopManagerScript = preload("res://scripts/core/hitstop_manager.gd")

var _trail_history: Array[Vector2] = []
const MAX_TRAIL_LENGTH: int = 14

func _init() -> void:
	flight_duration = 0.82
	reflected_speed = 1650.0
	damage_to_player = 2
	_radius = 30.0

func _ready() -> void:
	super._ready()
	_trail_history.clear()

func _physics_process(delta: float) -> void:
	# Enregistre l'historique des positions pour la traînée de comète
	_trail_history.push_front(global_position)
	if _trail_history.size() > MAX_TRAIL_LENGTH:
		_trail_history.pop_back()

	super._physics_process(delta)

@export var damage_to_boss: int = 3

func _impact_boss(target: Node2D) -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	var dmg: int = damage_to_boss
	hit_boss.emit(dmg, is_perfect_parry)
	Input.vibrate_handheld(50)
	HitstopManagerScript.trigger(0.045, 0.04)

	if target.has_method(&"take_hit"):
		target.take_hit(dmg, self, velocity)

	# Explosion d'étoiles dorées et roses éclatantes
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(1.0, 0.92, 0.2, 1.0),
		Color(1.0, 0.18, 0.65, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		24
	)

	EventBus.score_changed.emit(350, 350)
	queue_free()

func _explode_at_player() -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	EventBus.enemy_escaped.emit(damage_to_player)

	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(1.0, 0.25, 0.45, 1.0),
		Color(0.85, 0.1, 0.5, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		20
	)

	queue_free()

func _draw() -> void:
	var c: Vector2 = Vector2.ZERO
	var pulse: float = 0.88 + 0.12 * sin(_time_alive * 24.0)

	# 1. Dessin de la traînée de comète éclatante (ruban dégradé)
	if _trail_history.size() >= 2:
		for i in range(_trail_history.size() - 1):
			var p0: Vector2 = to_local(_trail_history[i])
			var p1: Vector2 = to_local(_trail_history[i + 1])
			var ratio: float = 1.0 - (float(i) / float(_trail_history.size()))
			var trail_w: float = (_radius * 0.9) * ratio
			var trail_col: Color = Color(1.0, 0.2, 0.65, 0.55 * ratio)
			if current_state == State.REFLECTED_TO_BOSS:
				trail_col = Color(1.0, 0.9, 0.25, 0.7 * ratio)
			draw_line(p0, p1, trail_col, trail_w)
			# Ligne centrale blanche incandescente
			draw_line(p0, p1, Color(1.0, 1.0, 1.0, 0.7 * ratio), trail_w * 0.45)

	if current_state == State.FALLING_FROM_BOSS:
		# 2. Halo d'énergie radiale magenta vibrant
		draw_circle(c, _radius * 1.5 * pulse, Color(1.0, 0.15, 0.65, 0.35))

		# 3. Indicateur de parade avec timing visuel clair
		var is_parry_window: bool = current_progress >= 0.68
		var target_ring_col: Color = Color(1.0, 1.0, 0.35, 1.0) if is_parry_window else Color(1.0, 0.35, 0.75, 0.9)
		draw_arc(c, _radius + 8.0, 0.0, TAU, 32, target_ring_col, 3.5, true)

		var ring_r: float = lerpf(_radius + 44.0, _radius + 8.0, clampf(current_progress, 0.0, 1.0))
		var shrinking_col: Color = Color(1.0, 1.0, 1.0, 1.0) if is_parry_window else Color(1.0, 0.88, 0.4, 0.9)
		draw_arc(c, ring_r, 0.0, TAU, 32, shrinking_col, 4.0, true)

		# 4. Étoile multicouche à fort contraste (lisible sur sable et herbe)
		# A) Silhouette d'ombre/contour sombre pour détacher nettement du fond sable
		_draw_star(c, 5, _radius * 1.35, _radius * 0.62, _spin_angle, Color(0.18, 0.04, 0.16, 0.95))
		# B) Étoile néon magenta / rose bandana
		_draw_star(c, 5, _radius * 1.20, _radius * 0.54, _spin_angle, Color(1.0, 0.18, 0.60, 1.0))
		# C) Étoile dorée carambole brillante
		_draw_star(c, 5, _radius * 0.85, _radius * 0.38, _spin_angle, Color(1.0, 0.94, 0.28, 1.0))
		# D) Cœur étincelant blanc pur
		_draw_star(c, 5, _radius * 0.42, _radius * 0.18, _spin_angle, Color.WHITE)

	elif current_state == State.REFLECTED_TO_BOSS:
		# Étoile renvoyée ultra-lumineuse et triomphale
		draw_circle(c, _radius * 1.8 * pulse, Color(1.0, 0.9, 0.3, 0.45))
		_draw_star(c, 5, _radius * 1.45, _radius * 0.68, -_spin_angle * 2.5, Color(0.25, 0.15, 0.0, 0.9))
		_draw_star(c, 5, _radius * 1.30, _radius * 0.58, -_spin_angle * 2.5, Color(1.0, 0.95, 0.35, 1.0))
		_draw_star(c, 5, _radius * 0.85, _radius * 0.38, -_spin_angle * 2.5, Color(1.0, 0.4, 0.75, 1.0))
		draw_circle(c, _radius * 0.35, Color.WHITE)

func _draw_star(center: Vector2, points: int, r_outer: float, r_inner: float, angle_offset: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var step: float = PI / float(points)
	for i in range(points * 2):
		var r: float = r_outer if (i % 2 == 0) else r_inner
		var a: float = angle_offset + float(i) * step - PI * 0.5
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)
