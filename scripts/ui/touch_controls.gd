class_name TouchControls
extends Control

## Gère les zones tactiles d'activation des batteurs (gauche et droite)
## avec support naturel du multi-touch à deux pouces.

@export var action_left: StringName = &"flip_left"
@export var action_right: StringName = &"flip_right"

var _touch_left_indices: Dictionary = {}
var _touch_right_indices: Dictionary = {}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var mid_x: float = size.x * 0.5
	var is_on_right_side: bool = event.position.x >= mid_x

	if event.pressed:
		if is_on_right_side:
			_touch_right_indices[event.index] = true
			Input.action_press(action_right)
		else:
			_touch_left_indices[event.index] = true
			Input.action_press(action_left)
	else:
		_touch_left_indices.erase(event.index)
		_touch_right_indices.erase(event.index)
		
		if _touch_left_indices.is_empty():
			Input.action_release(action_left)
		if _touch_right_indices.is_empty():
			Input.action_release(action_right)

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	var mid_x: float = size.x * 0.5
	var was_left: bool = _touch_left_indices.has(event.index)
	var was_right: bool = _touch_right_indices.has(event.index)
	var is_on_right_side: bool = event.position.x >= mid_x
	
	if was_left and is_on_right_side:
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
