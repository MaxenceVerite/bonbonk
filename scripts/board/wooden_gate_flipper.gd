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

## Calcule la vitesse linéaire vectorielle exacte de la porte à un point d'impact donné dans l'espace global
func get_velocity_at_point(point_global: Vector2) -> Vector2:
	var r: Vector2 = point_global - global_position
	# V = omega x r (en 2D : Vector2(-omega * r.y, omega * r.x))
	return Vector2(-current_angular_velocity * r.y, current_angular_velocity * r.x)

func _ready() -> void:
	# Au repos : légère pente de 7° vers le centre pour que la bille roule naturellement
	# Porte gauche : orientée vers le centre avec +7° (vers le bas)
	# Porte droite : orientée vers le centre avec 180° - 7° = 173° (vers le bas)
	var base_rest: float = (180.0 - 7.0) if is_right else 7.0
	rotation_degrees = base_rest

func _physics_process(delta: float) -> void:
	var is_pressed: bool = Input.is_action_pressed(input_action)
	var just_pressed: bool = is_pressed and not _was_pressed
	_was_pressed = is_pressed
	
	# Repos, Frappe (kick vers le haut), Recul (anticipation vers le bas)
	var rest_deg: float = (180.0 - 7.0) if is_right else 7.0
	var kick_deg: float = (180.0 + 65.0) if is_right else -65.0
	var antic_deg: float = (180.0 - 15.0) if is_right else 15.0
	
	if just_pressed:
		rotation_degrees = antic_deg
		_current_state = State.KICK
	elif is_pressed:
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


