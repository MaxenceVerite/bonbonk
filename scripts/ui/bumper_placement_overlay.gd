class_name BumperPlacementOverlay
extends Control

## Volet latéral de préparation au placement des Bumpers du Deck actif.
## Apparaît avant le lancement de la partie si le deck contient des bumpers.

signal placement_completed

@export var board: Board

@onready var items_container: VBoxContainer = $RightDock/VBox/Scroll/ItemsVBox
@onready var btn_start: Button = $BottomBar/BtnStart
@onready var instruction_label: Label = $TopBanner/Label

var draggable_item_scene: PackedScene = preload("res://scenes/ui/draggable_bumper_item.tscn")
var _placed_count: int = 0
var _total_bumpers: int = 0

func _ready() -> void:
	if btn_start != null:
		btn_start.pressed.connect(_on_btn_start_pressed)

func open_placement(target_board: Board) -> void:
	board = target_board
	visible = true
	_placed_count = 0
	
	if board != null:
		board.clear_all_bumpers()
		board.set_bumper_slots_placement_mode(true)

	_populate_bumper_dock()

func close_placement() -> void:
	visible = false
	if board != null:
		board.set_bumper_slots_placement_mode(false)

func _populate_bumper_dock() -> void:
	if items_container == null:
		return
	for c in items_container.get_children():
		c.queue_free()

	var bumper_ids: Array[StringName] = SaveManager.get_active_deck_bumpers()
	_total_bumpers = bumper_ids.size()
	
	if instruction_label != null:
		instruction_label.text = "GLISSE TES BUMPERS SUR LE PLATEAU"

	for b_id in bumper_ids:
		var item: DraggableBumperItem = draggable_item_scene.instantiate() as DraggableBumperItem
		item.bumper_card_id = b_id
		item.drag_started.connect(_on_item_drag_started)
		item.drag_moved.connect(_on_item_drag_moved)
		item.drag_ended.connect(_on_item_dropped)
		items_container.add_child(item)

func _on_item_drag_started(_item: DraggableBumperItem) -> void:
	if instruction_label != null:
		instruction_label.text = "DÉPOSE LE SUR UN EMPLACEMENT DISPONIBLE"

func _on_item_drag_moved(_item: DraggableBumperItem, current_pos: Vector2) -> void:
	if board == null:
		return
	var nearest_slot: BumperSlot = _find_nearest_free_slot(current_pos, 130.0)
	for slot in board.get_bumper_slots():
		if slot is BumperSlot:
			slot.set_highlight(slot == nearest_slot)

func _on_item_dropped(item: DraggableBumperItem, drop_pos: Vector2) -> void:
	if board == null:
		return

	# Réinitialiser les surbrillances
	for slot in board.get_bumper_slots():
		if slot is BumperSlot:
			slot.set_highlight(false)

	# Trouver le slot le plus proche dans un rayon ergonomique généreux (180px)
	var nearest_slot: BumperSlot = _find_nearest_free_slot(drop_pos, 180.0)

	if nearest_slot != null:
		var placed: bool = board.place_bumper_at_slot(nearest_slot, item.bumper_card_id)
		if placed:
			_placed_count += 1
			item.queue_free()
			
			if Input.has_method("vibrate_handheld"):
				Input.vibrate_handheld(30)
				
			if _placed_count >= _total_bumpers:
				if instruction_label != null:
					instruction_label.text = "TOUS LES BUMPERS SONT PLACÉS ! ▶"
			else:
				if instruction_label != null:
					instruction_label.text = "GLISSE LE PROCHAIN BUMPER"
		else:
			item.visible = true
			item.modulate = Color(1, 1, 1, 1.0)
	else:
		item.visible = true
		item.modulate = Color(1, 1, 1, 1.0)
		if instruction_label != null:
			instruction_label.text = "GLISSE TES BUMPERS SUR LE PLATEAU"

func _find_nearest_free_slot(pos: Vector2, max_dist: float) -> BumperSlot:
	var best_slot: BumperSlot = null
	var min_dist: float = max_dist
	for slot in board.get_bumper_slots():
		if slot is BumperSlot and not slot.is_occupied():
			var d: float = slot.global_position.distance_to(pos)
			if d < min_dist:
				min_dist = d
				best_slot = slot
	return best_slot

func _on_btn_start_pressed() -> void:
	close_placement()
	placement_completed.emit()
