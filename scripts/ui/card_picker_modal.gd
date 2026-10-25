class_name CardPickerModal
extends Control

## Modale pour choisir un bonbon parmi ceux débloqués pour l'assigner à un slot de deck.

signal card_chosen(card_id: StringName)

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var grid_container: GridContainer = $CenterAnchor/ModalCard/VBox/Scroll/CardsGrid
@onready var btn_close: Button = $CenterAnchor/ModalCard/BtnClose

var _target_slot_index: int = 0

func _ready() -> void:
	if btn_close != null:
		btn_close.pressed.connect(close)
	if dark_overlay != null:
		dark_overlay.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				close()
		)

func open_for_slot(slot_index: int) -> void:
	_target_slot_index = slot_index
	visible = true
	_populate_unlocked_cards()

func close() -> void:
	visible = false

var collection_card_scene: PackedScene = preload("res://scenes/ui/collection/collection_card.tscn")

func _populate_unlocked_cards() -> void:
	if grid_container == null:
		return
	for c in grid_container.get_children():
		c.queue_free()

	var unlocked_ids: Array[StringName] = SaveManager.get_unlocked_card_ids()
	for cid in unlocked_ids:
		var state: Dictionary = SaveManager.get_card_state(cid)
		if state.is_empty():
			continue

		var card: CollectionCard = collection_card_scene.instantiate() as CollectionCard
		grid_container.add_child(card)
		card.setup(state)
		# Dans le sélecteur de remplacement, on clique sur la carte pour l'assigner au slot
		card.card_clicked.connect(func(chosen_id: StringName) -> void:
			SaveManager.set_card_in_active_deck(_target_slot_index, chosen_id)
			card_chosen.emit(chosen_id)
			close()
		)
