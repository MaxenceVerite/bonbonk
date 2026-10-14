class_name Flipper
extends AnimatableBody2D

## Contrôleur de Batteur / Flipper réactif.

@export var is_right: bool = false
@export var input_action: StringName = &"flip_left"
@export var rest_angle_deg: float = 30.0
@export var pressed_angle_deg: float = -32.0
@export var speed_up_deg_per_sec: float = 900.0
@export var speed_down_deg_per_sec: float = 550.0

var _target_angle_rad: float = 0.0
var _rest_angle_rad: float = 0.0
var _pressed_angle_rad: float = 0.0

@onready var visual_polygon: Polygon2D = $Polygon2D
@onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D

func _ready() -> void:
	_rest_angle_rad = deg_to_rad(rest_angle_deg)
	_pressed_angle_rad = deg_to_rad(pressed_angle_deg)
	
	rotation = _rest_angle_rad
	_target_angle_rad = _rest_angle_rad

func _physics_process(delta: float) -> void:
	var is_active: bool = Input.is_action_pressed(input_action)
	_target_angle_rad = _pressed_angle_rad if is_active else _rest_angle_rad

	var current_speed: float = speed_up_deg_per_sec if is_active else speed_down_deg_per_sec
	var max_step: float = deg_to_rad(current_speed) * delta
	
	# Rotation continue de l'AnimatableBody2D (transmet l'impulsion physique exacte à la bille)
	rotation = rotate_toward(rotation, _target_angle_rad, max_step)
