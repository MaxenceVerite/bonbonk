class_name ParryableProjectile
extends Area2D

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

## Projectile de tir lancé par le Boss (ex: Spore d'énergie végétale de Brocolino).
## Trajectoire en cloche/courbe avec effet brossé vers le centre d'une des portes.
## - Possède l'indicateur visuel de parade (DiveTelegraphVisual) qui rétrécit vers le moment de frappe parfait.
## - Si le batteur le frappe durant la fenêtre idéale (Parade Parfaite) :
##   Reflète à toute vitesse vers le Boss, stun le Boss et inflige un bonus de combo si la série est parfaite !
## - Si le joueur frappe hors timing ou laisse passer :
##   Le tir explose et inflige 1 dégât au joueur.

signal parried(is_perfect: bool)
signal hit_boss(damage: int, caused_stun: bool)

enum State { FALLING_FROM_BOSS, REFLECTED_TO_BOSS, EXPLODING }
var current_state: State = State.FALLING_FROM_BOSS

# Trajectoire paramétrique en courbe de Bézier
var start_pos: Vector2 = Vector2.ZERO
var control_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var flight_duration: float = 1.35
var current_progress: float = 0.0

@export var reflected_speed: float = 1250.0
@export var damage_to_player: int = 2

var velocity: Vector2 = Vector2.ZERO
var target_boss: Node2D = null
var _time_alive: float = 0.0
var _radius: float = 22.0
var _spin_angle: float = 0.0

# Combo & Perfection du renvoi
var is_perfect_parry: bool = false
var series_index: int = 0
var series_total: int = 1

func setup_curved(p_start: Vector2, p_target: Vector2, p_curve_offset_x: float, p_boss: Node2D, p_duration: float = 0.85, p_series_idx: int = 0, p_series_tot: int = 1) -> void:
	start_pos = p_start
	target_pos = p_target
	target_boss = p_boss
	flight_duration = maxf(0.5, p_duration)
	series_index = p_series_idx
	series_total = p_series_tot
	current_progress = 0.0
	current_state = State.FALLING_FROM_BOSS

	# Point de contrôle créant une belle courbe parabolique dynamique
	var mid: Vector2 = (start_pos + target_pos) * 0.5
	control_pos = mid + Vector2(p_curve_offset_x, -140.0)

	global_position = start_pos

func _ready() -> void:
	z_index = 18
	collision_layer = 0
	# Masque initial : Layer 2 (Flippers) = 2, Layer 6 (Danger Zone) = 32
	collision_mask = 2 | 32
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	_spin_angle += delta * 4.5
	queue_redraw()

	match current_state:
		State.FALLING_FROM_BOSS:
			current_progress += delta / flight_duration
			var t: float = clampf(current_progress, 0.0, 1.0)

			# Évaluation de la courbe quadratique de Bézier : B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
			var prev_pos: Vector2 = global_position
			var one_minus: float = 1.0 - t
			global_position = (one_minus * one_minus * start_pos) + (2.0 * one_minus * t * control_pos) + (t * t * target_pos)
			if delta > 0.0:
				velocity = (global_position - prev_pos) / delta

			# Si arrivée en bout de course sans parade -> explosion
			if t >= 1.0 or global_position.y > 1250.0:
				_explode_at_player()

		State.REFLECTED_TO_BOSS:
			if target_boss != null and is_instance_valid(target_boss):
				var to_boss: Vector2 = (target_boss.global_position - global_position).normalized()
				velocity = velocity.lerp(to_boss * reflected_speed, delta * 16.0)
				if global_position.distance_to(target_boss.global_position) < 75.0:
					_impact_boss(target_boss)
					return
			global_position += velocity * delta
			if global_position.y < -120.0:
				queue_free()

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.FALLING_FROM_BOSS:
		if body is WoodenGateFlipper:
			var gate: WoodenGateFlipper = body as WoodenGateFlipper
			if gate.is_in_parry_window():
				# Détermine si la parade est PARFAITE (au moment où le progress télégraphe approche de 1.0)
				var perfect: bool = (current_progress >= 0.78)
				reflect_projectile(gate, perfect)
			else:
				_explode_at_player()
		elif body is Enemy and current_state == State.REFLECTED_TO_BOSS:
			_impact_boss(body)

	elif current_state == State.REFLECTED_TO_BOSS:
		if body is Enemy or (target_boss != null and body == target_boss):
			_impact_boss(body)

func _on_area_entered(area: Area2D) -> void:
	if current_state == State.FALLING_FROM_BOSS:
		if area.name == "DangerZone" or area.collision_layer & 32:
			_explode_at_player()

## Renvoi dynamique par le batteur
func reflect_projectile(_flipper: WoodenGateFlipper, p_is_perfect: bool) -> void:
	if not p_is_perfect:
		# Parade non parfaite : le projectile est détruit net (sans renvoi ni dégât au joueur)
		_explode_harmless()
		return

	current_state = State.REFLECTED_TO_BOSS
	is_perfect_parry = true
	parried.emit(true)

	# Vitesse et trajectoire fulgurante vers le Boss
	var target_dest: Vector2 = target_boss.global_position if (target_boss != null and is_instance_valid(target_boss)) else (global_position + Vector2.UP * 900.0)
	var dir: Vector2 = (target_dest - global_position).normalized()
	velocity = dir * reflected_speed

	# Masque ajusté : Layer 4 (Enemies) = 8
	collision_mask = 8

	# Retours haptiques et score
	Input.vibrate_handheld(50)
	EventBus.score_changed.emit(300, 300)
	# Éclat étincelant multicolore / doré
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(1.0, 0.95, 0.4, 1.0),
		Color(0.2, 1.0, 0.5, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		16
	)

func _explode_harmless() -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING
	parried.emit(false)

	Input.vibrate_handheld(25)
	EventBus.score_changed.emit(100, 100)
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(0.4, 0.85, 0.3, 1.0),
		Color(0.2, 0.6, 0.2, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		10
	)
	queue_free()

func _impact_boss(target: Node2D) -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	# Ajustement gameplay : 1 point de dégât par projectile réfléchi
	var dmg: int = 1
	hit_boss.emit(dmg, is_perfect_parry)

	# Secousse légère lors de l'impact
	Input.vibrate_handheld(35)

	# Notification au Boss pour enregistrement du coup (3+ tirs en < 2s = 5s stun)
	if target is BrocolinoBoss:
		var broc: BrocolinoBoss = target as BrocolinoBoss
		broc.register_reflected_projectile_hit()

	if target.has_method(&"take_hit"):
		target.take_hit(dmg, self, velocity)

	# Éclat d'impact
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(0.3, 1.0, 0.4, 1.0),
		Color(1.0, 0.9, 0.2, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		20
	)

	EventBus.score_changed.emit(250, 250)
	queue_free()

func _explode_at_player() -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	# Dégât accru au joueur (ex: 2 PV de dégâts car tir massif de Boss)
	EventBus.enemy_escaped.emit(damage_to_player)

	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(0.22, 0.68, 0.18, 1.0),
		Color(0.12, 0.45, 0.1, 1.0),
		Color(0.95, 0.2, 0.2, 1.0),
		18
	)

	queue_free()

func _draw() -> void:
	var c: Vector2 = Vector2.ZERO
	var pulse: float = 0.88 + 0.12 * sin(_time_alive * 16.0)

	if current_state == State.FALLING_FROM_BOSS:
		# 1. Aura de spores / vapeurs végétales toxiques
		draw_circle(c, _radius * 1.55 * pulse, Color(0.22, 0.82, 0.2, 0.25))

		# 2. Indicateur de parade vectoriel (DiveTelegraphVisual synchronisé)
		var target_col: Color = Color(0.2, 1.0, 0.45, 0.95) if current_progress >= 0.78 else Color(1.0, 0.6, 0.15, 0.75)
		draw_arc(c, _radius + 7.0, 0.0, TAU, 32, target_col, 2.5, true)

		var ring_r: float = lerpf(_radius + 34.0, _radius + 7.0, clampf(current_progress, 0.0, 1.0))
		var shrinking_col: Color = Color(1.0, 1.0, 0.5, 1.0) if current_progress >= 0.78 else Color(1.0, 0.8, 0.2, 0.85)
		draw_arc(c, ring_r, 0.0, TAU, 32, shrinking_col, 3.0, true)

		# Étoile dorée quand la parade parfaite est active
		if current_progress >= 0.78:
			draw_circle(c, 8.0, Color(1.0, 0.95, 0.4, 0.95))
			draw_circle(c, 4.0, Color.WHITE)

		# 3. Corps "Brocolineux" (Tête de fleurette texturée, bourgeons multiples)
		# Tige / trognon arrière vert clair
		draw_circle(c + Vector2(0, -6), _radius * 0.45, Color(0.38, 0.72, 0.24, 0.95))

		# Masse principale vert forêt sombre
		draw_circle(c, _radius, Color(0.12, 0.38, 0.10, 1.0))

		# Fleurettes périphériques (bouquets de brocoli lobés) tournoyant lentement
		var num_florets: int = 6
		var floret_rad: float = _radius * 0.52
		for i in range(num_florets):
			var angle: float = _spin_angle + float(i) * (TAU / float(num_florets))
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * (_radius * 0.68)
			# Ombre du bouquet
			draw_circle(c + offset, floret_rad, Color(0.14, 0.44, 0.12, 1.0))
			# Centre du bouquet vert tendre
			draw_circle(c + offset, floret_rad * 0.75, Color(0.28, 0.68, 0.18, 1.0))
			# Pointes bourgeonnantes vert vif texturé
			draw_circle(c + offset + Vector2(-1.5, -1.5), floret_rad * 0.35, Color(0.62, 0.92, 0.30, 0.95))

		# Cœur central en bouquet dense
		draw_circle(c, _radius * 0.65, Color(0.18, 0.52, 0.14, 1.0))
		draw_circle(c + Vector2(-2, -2), _radius * 0.42, Color(0.35, 0.78, 0.22, 1.0))
		draw_circle(c + Vector2(-4, -4), _radius * 0.20, Color(0.85, 1.0, 0.55, 0.95))

	elif current_state == State.REFLECTED_TO_BOSS:
		# Rendu fulgurant du tir renvoyé (Parade Parfaite dorée / Cyan éclatant avec étincelles)
		var halo_col: Color = Color(1.0, 0.85, 0.25, 0.45) if is_perfect_parry else Color(0.2, 0.85, 1.0, 0.35)
		var core_col: Color = Color(1.0, 0.98, 0.8, 1.0) if is_perfect_parry else Color(0.85, 1.0, 0.95, 1.0)
		var ring_col: Color = Color(1.0, 0.9, 0.3, 1.0) if is_perfect_parry else Color(0.2, 0.95, 1.0, 1.0)

		draw_circle(c, _radius * 2.1 * pulse, halo_col)
		# Fleurettes luminescentes de retour vers l'expéditeur
		for i in range(5):
			var a: float = _spin_angle * 2.5 + float(i) * (TAU / 5.0)
			var off: Vector2 = Vector2(cos(a), sin(a)) * (_radius * 0.6)
			draw_circle(c + off, _radius * 0.35, ring_col)

		draw_circle(c, _radius * 1.3, ring_col)
		draw_circle(c, _radius * 0.8, core_col)
		draw_arc(c, _radius + 5.0, 0.0, TAU, 28, ring_col, 3.0, true)
