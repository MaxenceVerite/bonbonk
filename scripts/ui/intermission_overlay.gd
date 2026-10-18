class_name IntermissionOverlay
extends Control

## Écran de transition et de draft Roguelike entre les manches.
## Affiche le bilan de la manche et permet de choisir 1 relique parmi 3.

signal next_wave_pressed

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var info_label: Label = $CenterContainer/Panel/VBox/InfoLabel
@onready var relics_section: VBoxContainer = $CenterContainer/Panel/VBox/RelicsSection
@onready var relics_header: Label = $CenterContainer/Panel/VBox/RelicsSection/RelicsHeaderLabel
@onready var relics_list: VBoxContainer = $CenterContainer/Panel/VBox/RelicsSection/RelicsList
@onready var btn_next: Button = $CenterContainer/Panel/VBox/BtnNextWave

var _has_chosen_relic: bool = false
var _relic_buttons: Array[Button] = []

func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)

func show_intermission(completed_wave: int, next_wave_num: int, next_budget: int) -> void:
	title_label.text = "🎉 MANCHE %d RÉUSSIE !" % completed_wave
	info_label.text = "Manche %d (Menace : %d pts)" % [next_wave_num, next_budget]
	visible = true

	# Préparer le choix de relique
	_populate_relic_offerings()

	# Animation pop-in gourmande
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _populate_relic_offerings() -> void:
	# Nettoyer les boutons précédents
	for child in relics_list.get_children():
		child.queue_free()
	_relic_buttons.clear()

	var offerings: Array[Relic] = RelicManager.pick_relic_offerings(3)
	if offerings.is_empty():
		relics_section.visible = false
		_has_chosen_relic = true
		btn_next.disabled = false
		btn_next.text = "MANCHE SUIVANTE ➔"
		return

	relics_section.visible = true
	_has_chosen_relic = false
	btn_next.disabled = true
	btn_next.text = "CHOISIS UNE RELIQUE D'ABORD"

	for relic in offerings:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(460, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = " ⭐ %s\n   %s" % [relic.display_name, relic.description]
		btn.theme_type_variation = &"ButtonPink"
		btn.pressed.connect(_on_relic_selected.bind(relic, btn))
		relics_list.add_child(btn)
		_relic_buttons.append(btn)

func _on_relic_selected(relic: Relic, selected_btn: Button) -> void:
	if _has_chosen_relic:
		return
	_has_chosen_relic = true

	# Ajouter la relique via l'autoload
	RelicManager.add_relic(relic)

	# Feedback visuel sur le bouton choisi
	for b in _relic_buttons:
		if b == selected_btn:
			b.theme_type_variation = &"ButtonMint"
			b.text = " ✅ " + b.text.substr(3)
		else:
			b.disabled = true
			b.modulate.a = 0.45

	btn_next.disabled = false
	btn_next.text = "MANCHE SUIVANTE ➔"

	# Petit bond dynamique sur le bouton suivant
	var tw: Tween = btn_next.create_tween()
	tw.tween_property(btn_next, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn_next, "scale", Vector2.ONE, 0.1)

func _on_next_pressed() -> void:
	if not _has_chosen_relic and relics_section.visible:
		return
	next_wave_pressed.emit()

func hide_intermission() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(func() -> void: visible = false)
