class_name PlayerNameModal
extends Control

## Modale de saisie du pseudo (FTUE / Accueil / Paramètres).
## Inspirée du flow Supercell : demandée une fois la première étape franchie ou via le profil.

signal name_confirmed(new_name: String)

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var modal_card: PanelContainer = $CenterAnchor/ModalCard
@onready var edit_name: LineEdit = $CenterAnchor/ModalCard/VBox/WellPanel/WellVBox/EditName
@onready var label_error: Label = $CenterAnchor/ModalCard/VBox/WellPanel/WellVBox/LabelError
@onready var btn_confirm: Button = $CenterAnchor/ModalCard/VBox/BtnConfirm

func _ready() -> void:
	visible = false
	btn_confirm.pressed.connect(_on_confirm_pressed)
	edit_name.text_submitted.connect(func(_t: String) -> void: _on_confirm_pressed())
	edit_name.text_changed.connect(_on_text_changed)
	dark_overlay.gui_input.connect(_on_overlay_input)

func open() -> void:
	visible = true
	label_error.text = ""
	
	if SaveManager.current_profile != null:
		var current_name: String = SaveManager.current_profile.display_name
		if current_name != "Gourmand":
			edit_name.text = current_name
		else:
			edit_name.text = ""
	
	edit_name.grab_focus()

	# Animation pop-in dynamique
	modulate.a = 0.0
	modal_card.scale = Vector2(0.9, 0.9)
	modal_card.pivot_offset = modal_card.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(modal_card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_card, "scale", Vector2(0.9, 0.9), 0.15)
	await tween.finished
	visible = false

func _on_overlay_input(event: InputEvent) -> void:
	# Autorise la fermeture en touchant l'arrière-plan seulement si le joueur a déjà un nom
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if SaveManager.current_profile != null and SaveManager.current_profile.has_chosen_name:
			close()

func _on_text_changed(new_text: String) -> void:
	if not label_error.text.is_empty():
		label_error.text = ""
	btn_confirm.disabled = new_text.strip_edges().length() < 2

func _on_confirm_pressed() -> void:
	var chosen: String = edit_name.text.strip_edges()
	if chosen.length() < 2:
		label_error.text = "Le pseudo doit comporter au moins 2 caractères."
		return
	if chosen.length() > 16:
		label_error.text = "Le pseudo ne peut pas dépasser 16 caractères."
		return

	if SaveManager.current_profile != null:
		SaveManager.current_profile.display_name = chosen
		SaveManager.current_profile.has_chosen_name = true
		SaveManager.save_to_disk()
		if SaveManager.cloud_sync != null:
			SaveManager.cloud_sync.sync_now()

	name_confirmed.emit(chosen)
	close()
