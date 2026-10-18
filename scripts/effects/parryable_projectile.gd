class_name ParryableProjectile
extends Area2D

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

## Projectile de tir lancé par le Boss (ex: Spore d'énergie végétale de Brocolino).
## Descend vers les batteurs.
## - Si le batteur le frappe durant la fenêtre de contre (is_in_parry_window),
##   le projectile est PARÉ : il change de couleur, accélère fortement et repart vers le Boss pour le blesser !
## - Si le joueur rate le contre ou le laisse passer dans la DangerZone,
##   le projectile explose et inflige 1 dégât au joueur.

signal parried
signal hit_boss(damage: int)

enum State { FALLING_FROM_BOSS, REFLECTED_TO_BOSS, EXPLODING }
var current_state: State = State.FALLING_FROM_BOSS

@export var fall_speed: float = 280.0
@export var reflected_speed: float = 850.0
@export var reflected_damage: int = 20

var velocity: Vector2 = Vector2.ZERO
var target_boss: Node2D = null
var _time_alive: float = 0.0
var _radius: float = 18.0

func setup(origin_pos: Vector2, target_pos: Vector2, boss_node: Node2D) -> void:
	global_position = origin_pos
	target_boss = boss_node
	var dir: Vector2 = (target_pos - origin_pos).normalized()
	velocity = dir * fall_speed
	current_state = State.FALLING_FROM_BOSS

func _ready() -> void:
	z_index = 18
	collision_layer = 0
	# Masque initial : Layer 2 (Flippers) = 2, Layer 6 (Danger Zone) = 32
	collision_mask = 2 | 32
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	queue_redraw()

	match current_state:
		State.FALLING_FROM_BOSS:
			global_position += velocity * delta
			# Sécurité : si dépassement bas de l'arène
			if global_position.y > 1250.0:
				_explode_at_player()

		State.REFLECTED_TO_BOSS:
			# Si le boss est valide, recalcule la trajectoire vers son centre
			if target_boss != null and is_instance_valid(target_boss):
				var to_boss: Vector2 = (target_boss.global_position - global_position).normalized()
				velocity = velocity.lerp(to_boss * reflected_speed, delta * 12.0)
				# Détection d'impact de proximité sur le boss
				if global_position.distance_to(target_boss.global_position) < 70.0:
					_impact_boss(target_boss)
					return
			global_position += velocity * delta
			if global_position.y < -100.0:
				queue_free()

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.FALLING_FROM_BOSS:
		if body is WoodenGateFlipper:
			var gate: WoodenGateFlipper = body as WoodenGateFlipper
			if gate.is_in_parry_window():
				reflect_projectile(gate)
			else:
				_explode_at_player()
		elif body is Enemy and current_state == State.REFLECTED_TO_BOSS:
			_impact_boss(body)

	elif current_state == State.REFLECTED_TO_BOSS:
		if body is Enemy or (target_boss != null and body == target_boss):
			_impact_boss(body)

func _on_area_entered(area: Area2D) -> void:
	if current_state == State.FALLING_FROM_BOSS:
		# Collision avec la zone de danger
		if area.name == "DangerZone" or area.collision_layer & 32:
			_explode_at_player()

## Contre réussi par le batteur
func reflect_projectile(flipper: WoodenGateFlipper) -> void:
	current_state = State.REFLECTED_TO_BOSS
	parried.emit()

	# Inversion vers le Boss avec boost de vitesse
	var target_dest: Vector2 = target_boss.global_position if (target_boss != null and is_instance_valid(target_boss)) else (global_position + Vector2.UP * 800.0)
	var dir: Vector2 = (target_dest - global_position).normalized()
	velocity = dir * reflected_speed

	# Masque ajusté : Layer 4 (Enemies) = 8
	collision_mask = 8

	# Effets visuels & sonores de contre parfait
	Input.vibrate_handheld(45)
	EventBus.score_changed.emit(150, 150)

	# Éclat d'impact étincelant au point de contact
	var splat_color: Color = Color(1.0, 0.9, 0.25, 1.0)
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(1.0, 0.85, 0.2, 1.0),
		Color(0.2, 0.95, 0.9, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		10
	)

func _impact_boss(target: Node2D) -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	hit_boss.emit(reflected_damage)

	if target.has_method(&"take_hit"):
		target.take_hit(reflected_damage, self, velocity)

	# Éclat d'impact violent sur le boss
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(0.3, 0.95, 0.3, 1.0),
		Color(1.0, 0.85, 0.2, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		18
	)

	EventBus.score_changed.emit(250, 250)
	queue_free()

func _explode_at_player() -> void:
	if current_state == State.EXPLODING:
		return
	current_state = State.EXPLODING

	# Dégât au joueur
	EventBus.enemy_escaped.emit(1)

	# Éclaboussure acide/végétale
	JuiceSplatScript.spawn(
		get_parent(),
		global_position,
		Color(0.25, 0.65, 0.15, 1.0),
		Color(0.15, 0.45, 0.1, 1.0),
		Color(0.9, 0.2, 0.2, 1.0),
		12
	)

	queue_free()

func _draw() -> void:
	var c: Vector2 = Vector2.ZERO
	var pulse: float = 0.85 + 0.15 * sin(_time_alive * 14.0)

	if current_state == State.FALLING_FROM_BOSS:
		# 1. Aura toxique extérieure avec pulsation
		draw_circle(c, _radius * 1.5 * pulse, Color(0.3, 0.85, 0.2, 0.25))
		# 2. Anneau télégraphiant la possibilité de parade (liseré jaune étincelant)
		var ring_color: Color = Color(1.0, 0.9, 0.3, 0.85 + 0.15 * sin(_time_alive * 20.0))
		draw_arc(c, _radius + 3.0, 0.0, TAU, 24, ring_color, 2.5, true)
		# 3. Corps principal (globe végétal brocoli)
		draw_circle(c, _radius, Color(0.18, 0.58, 0.14, 1.0))
		# 4. Cœur dense
		draw_circle(c, _radius * 0.6, Color(0.45, 0.88, 0.28, 1.0))
		# 5. Point lumineux
		draw_circle(c + Vector2(-3, -3), _radius * 0.25, Color(0.95, 1.0, 0.7, 0.9))

	elif current_state == State.REFLECTED_TO_BOSS:
		# Projectile renvoyé : flamboyant doré / azur puissant
		draw_circle(c, _radius * 1.8 * pulse, Color(0.2, 0.85, 1.0, 0.35))
		draw_circle(c, _radius * 1.3, Color(1.0, 0.85, 0.2, 0.7))
		draw_circle(c, _radius, Color(1.0, 1.0, 0.85, 1.0))
		draw_arc(c, _radius + 4.0, 0.0, TAU, 24, Color(0.2, 0.9, 1.0, 1.0), 3.0, true)
