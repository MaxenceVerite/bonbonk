class_name TouchControls
extends Control

## Gère les zones tactiles d'activation des batteurs (gauche et droite)
## avec support naturel du multi-touch à deux pouces.

@export var action_left: StringName = &"flip_left"
@export var action_right: StringName = &"flip_right"

signal mega_slam_requested

var _touch_left_indices: Dictionary = {}
var _touch_right_indices: Dictionary = {}
var _last_left_touch_time: float = -100.0
var _last_right_touch_time: float = -100.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mega_slam"):
		EventBus.mega_slam_requested.emit()
		mega_slam_requested.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var mid_x: float = size.x * 0.5
	var factory_margin_right: float = 120.0
	var is_on_factory_strip: bool = event.position.x >= (size.x - factory_margin_right)
	var is_on_right_side: bool = event.position.x >= mid_x and not is_on_factory_strip

	if event.pressed:
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if is_on_right_side:
			_touch_right_indices[event.index] = true
			_last_right_touch_time = now
			Input.action_press(action_right)
		elif event.position.x < mid_x:
			_touch_left_indices[event.index] = true
			_last_left_touch_time = now
			Input.action_press(action_left)

		# Détection du Dual Slam (les deux pouces tapent en quasi-simultané dans une fenêtre de 140ms)
		if absf(_last_left_touch_time - _last_right_touch_time) <= 0.14:
			EventBus.mega_slam_requested.emit()
			mega_slam_requested.emit()
			Input.action_press(&"mega_slam")
			_last_left_touch_time = -100.0
			_last_right_touch_time = -100.0

	else:
		_touch_left_indices.erase(event.index)
		_touch_right_indices.erase(event.index)
		
		if _touch_left_indices.is_empty():
			Input.action_release(action_left)
		if _touch_right_indices.is_empty():
			Input.action_release(action_right)
		if _touch_left_indices.is_empty() and _touch_right_indices.is_empty():
			Input.action_release(&"mega_slam")

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	var mid_x: float = size.x * 0.5
	var factory_margin_right: float = 120.0
	var is_on_factory_strip: bool = event.position.x >= (size.x - factory_margin_right)
	var was_left: bool = _touch_left_indices.has(event.index)
	var was_right: bool = _touch_right_indices.has(event.index)
	var is_on_right_side: bool = event.position.x >= mid_x and not is_on_factory_strip
	
	if is_on_factory_strip:
		_touch_right_indices.erase(event.index)
	elif was_left and is_on_right_side:
		_touch_left_indices.erase(event.index)
		_touch_right_indices[event.index] = true
	elif was_right and not is_on_right_side:
		_touch_right_indices.erase(event.index)
		_touch_left_indices[event.index] = true

	if _touch_left_indices.is_empty():
		Input.action_release(action_left)
	else:
		Input.action_press(action_left)

	if _touch_right_indices.is_empty():
		Input.action_release(action_right)
	else:
		Input.action_press(action_right)
