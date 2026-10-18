class_name WoodenGateFlipper
extends AnimatableBody2D

## Porte en bois servant de batteur / flipper.
## Au repos : complètement horizontale (droite).
## À l'appui : recule légèrement (anticipation / recoil) puis s'ouvre brusquement vers le haut/extérieur
## pour projeter la bille vers le haut.

@export var is_right: bool = false
@export var input_action: StringName = &"flip_left"

# Angles en degrés relatifs (0 = droite / horizontal)
@export var rest_angle_deg: float = 0.0
@export var anticipation_angle_deg: float = 8.0     # Légère descente/recul au moment où on arme
@export var kick_angle_deg: float = -65.0           # Frappe brutale vers le haut

@export var kick_speed_deg: float = 1200.0          # Vitesse d'ouverture très vive
@export var return_speed_deg: float = 500.0         # Vitesse de retour au repos

enum State { REST, KICK, RETURN }
var _current_state: State = State.REST
var _was_pressed: bool = false
var current_angular_velocity: float = 0.0
var _prev_rotation: float = 0.0

func is_kicking() -> bool:
	return _current_state == State.KICK

## Fenêtre de contre active (Parry Window) :
## La batte n'est capable d'intercepter et smash l'ennemi QUE lors de son ascension rapide !
## Si la batte est maintenue levée au repos haut ou si elle redescend, la fenêtre est fermée.
func is_in_parry_window() -> bool:
	if _current_state != State.KICK:
		return false
	# Vitesse angulaire ascensionnelle significative
	if is_right:
		return current_angular_velocity > 2.0
	else:
		return current_angular_velocity < -2.0

## Calcule la vitesse linéaire vectorielle exacte de la porte à un point d'impact donné dans l'espace global
func get_velocity_at_point(point_global: Vector2) -> Vector2:
	var r: Vector2 = point_global - global_position
	# V = omega x r (en 2D : Vector2(-omega * r.y, omega * r.x))
	return Vector2(-current_angular_velocity * r.y, current_angular_velocity * r.x)

## Tente d'effectuer un Super-Contre (Parry) sur un ennemi entrant en contact.
## Retourne true si le contre est réussi et catapulté, false si le flipper est inactif/raté.
func try_parry_enemy(enemy: Enemy, impact_point: Vector2, collision_normal: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not is_in_parry_window():
		return false
	if enemy.enemy_data != null and not enemy.enemy_data.can_be_parried:
		return false

	var gate_vel: Vector2 = get_velocity_at_point(impact_point)
	var mass: float = maxf(0.3, enemy.enemy_data.mass_weight) if enemy.enemy_data != null else 1.0
	var rebound: float = enemy.enemy_data.kick_rebound_factor if enemy.enemy_data != null else 1.0
	var kick_speed: float = (1400.0 / mass) * rebound
	var push_direction: Vector2 = (gate_vel.normalized() * 0.4 + collision_normal * 1.0 + Vector2.UP * 1.2).normalized()
	var push_velocity: Vector2 = push_direction * kick_speed

	var hit_ctx: HitContext = HitContext.create(self, enemy, 0, impact_point, push_velocity, HitContext.DamageType.PARRY, true)
	EventBus.flipper_parried.emit(self, enemy, hit_ctx)

	enemy.on_parried_by_gate(push_velocity, collision_normal.angle())
	Input.vibrate_handheld(35)
	return true

static var active_gates: Array[WoodenGateFlipper] = []

func _enter_tree() -> void:
	if not active_gates.has(self):
		active_gates.append(self)

func _exit_tree() -> void:
	active_gates.erase(self)

var _initial_position: Vector2 = Vector2.ZERO
var _collapse_tween: Tween = null

func _ready() -> void:
	_initial_position = position
	add_to_group(&"flipper_gates")
	if not active_gates.has(self):
		active_gates.append(self)
	# Au repos : légère pente de 7° vers le centre pour que la bille roule naturellement
	# Porte gauche : orientée vers le centre avec +7° (vers le bas)
	# Porte droite : orientée vers le centre avec 180° - 7° = 173° (vers le bas)
	var base_rest: float = (180.0 - 7.0) if is_right else 7.0
	rotation_degrees = base_rest
	
	# Ajuste la projection de l'ombre portée (l'ombre doit toujours tomber vers le bas en coordonnées globales)
	var shadow: Node2D = get_node_or_null("GateShadow") as Node2D
	if shadow != null:
		shadow.position.y = -10.0 if is_right else 10.0

var _is_broken: bool = false

func _physics_process(delta: float) -> void:
	if _is_broken:
		return

	var is_pressed: bool = Input.is_action_pressed(input_action)
	var just_pressed: bool = is_pressed and not _was_pressed
	_was_pressed = is_pressed
	
	# Repos, Frappe (kick vers le haut)
	var rest_deg: float = (180.0 - 7.0) if is_right else 7.0
	var kick_deg: float = (180.0 + 65.0) if is_right else -65.0
	
	if is_pressed:
		_current_state = State.KICK
	else:
		_current_state = State.RETURN
		
	match _current_state:
		State.KICK:
			var step: float = deg_to_rad(kick_speed_deg) * delta
			rotation = rotate_toward(rotation, deg_to_rad(kick_deg), step)
		State.RETURN:
			var step: float = deg_to_rad(return_speed_deg) * delta
			rotation = rotate_toward(rotation, deg_to_rad(rest_deg), step)

	if delta > 0.0:
		current_angular_velocity = (rotation - _prev_rotation) / delta
	_prev_rotation = rotation

func deactivate() -> void:
	_was_pressed = false
	_current_state = State.RETURN
	var rest_deg: float = (180.0 - 7.0) if is_right else 7.0
	rotation_degrees = rest_deg
	current_angular_velocity = 0.0

## Écroulement dramatique lors du Game Over
func collapse_and_fall() -> void:
	if _is_broken:
		return
	_is_broken = true
	set_physics_process(false)

	if _collapse_tween != null and _collapse_tween.is_valid():
		_collapse_tween.kill()

	# Désactive la collision pour laisser la horde passer
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.set_deferred(&"disabled", true)

	var target_rot: float = rotation + (1.4 if is_right else -1.4)
	var target_y: float = _initial_position.y + 160.0

	_collapse_tween = create_tween().set_parallel(true)
	_collapse_tween.tween_property(self, "position:y", target_y, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_collapse_tween.tween_property(self, "rotation", target_rot, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_collapse_tween.tween_property(self, "modulate:a", 0.0, 0.75)

	Input.vibrate_handheld(40)

func reset_gate() -> void:
	if _collapse_tween != null and _collapse_tween.is_valid():
		_collapse_tween.kill()
		_collapse_tween = null

	_is_broken = false
	position = _initial_position
	modulate.a = 1.0
	visible = true

	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.set_deferred(&"disabled", false)

	set_physics_process(true)
	deactivate()


