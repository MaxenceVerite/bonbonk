class_name DraggableBumperItem
extends Control

## Miniature de carte Bumper dans le volet latéral de préparation.
## Supporte le glisser-déposer au doigt (touch/drag) vers les BumperSlots du plateau.

signal drag_started(item: DraggableBumperItem)
signal drag_moved(item: DraggableBumperItem, global_pos: Vector2)
signal drag_ended(item: DraggableBumperItem, global_drop_pos: Vector2)

@export var bumper_card_id: StringName = &"dragiburst"

@onready var icon_rect: TextureRect = $Panel/VBox/IconRect
@onready var name_label: Label = $Panel/VBox/NameLabel

var is_dragging: bool = false
var _drag_preview: Control = null

func _ready() -> void:
	custom_minimum_size = Vector2(90, 110)
	var cdef: CandyCardData = SaveManager.registered_card_defs.get(bumper_card_id, null)
	if cdef != null:
		if icon_rect != null and cdef.icon_texture != null:
			icon_rect.texture = cdef.icon_texture
		if name_label != null:
			name_label.text = cdef.display_name

func _exit_tree() -> void:
	_cleanup_preview()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(get_global_mouse_position())
			else:
				if is_dragging:
					_end_drag(get_global_mouse_position())
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(get_global_mouse_position())
		else:
			if is_dragging:
				_end_drag(get_global_mouse_position())
	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(get_global_mouse_position())

func _start_drag(start_global_pos: Vector2) -> void:
	is_dragging = true
	modulate = Color(1, 1, 1, 0.4)
	
	_cleanup_preview()
	
	# Création d'une miniature fantôme flottante
	_drag_preview = Control.new()
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.size = Vector2(70, 70)
	_drag_preview.z_index = 100
	
	var tex_rect: TextureRect = TextureRect.new()
	tex_rect.size = Vector2(70, 70)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = icon_rect.texture if icon_rect != null else null
	_drag_preview.add_child(tex_rect)
	
	get_tree().root.add_child(_drag_preview)
	_drag_preview.global_position = start_global_pos - Vector2(35, 35)
	drag_started.emit(self)

func _update_drag(current_global_pos: Vector2) -> void:
	if _drag_preview != null:
		_drag_preview.global_position = current_global_pos - Vector2(35, 35)
	drag_moved.emit(self, current_global_pos)

func _end_drag(drop_global_pos: Vector2) -> void:
	is_dragging = false
	modulate = Color(1, 1, 1, 1.0)
	_cleanup_preview()
	drag_ended.emit(self, drop_global_pos)

func _cleanup_preview() -> void:
	if _drag_preview != null:
		if is_instance_valid(_drag_preview):
			_drag_preview.queue_free()
		_drag_preview = null

