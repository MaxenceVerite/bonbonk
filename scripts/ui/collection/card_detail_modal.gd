class_name CardDetailModal
extends Control

## Modale de détail d'une carte bonbon.
## Seul endroit où le joueur peut consulter les statistiques et déclencher l'amélioration.

signal card_upgraded_locally(card_id: StringName)
signal replace_requested(slot_index: int, current_card_id: StringName)

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var modal_card: PanelContainer = $CenterAnchor/ModalCard
@onready var btn_close: Button = $CenterAnchor/ModalCard/BtnClose
@onready var card_name_label: Label = $CenterAnchor/ModalCard/VBox/Header/NameLabel
@onready var card_subtitle_label: Label = $CenterAnchor/ModalCard/VBox/Header/SubtitleLabel
@onready var rarity_badge: Label = $CenterAnchor/ModalCard/VBox/Header/RarityBadge
@onready var icon_rect: TextureRect = $CenterAnchor/ModalCard/VBox/IconBox/Icon
@onready var icon_halo: TextureRect = $CenterAnchor/ModalCard/VBox/IconBox/Halo
@onready var level_transition_label: Label = $CenterAnchor/ModalCard/VBox/LevelTransitionLabel
@onready var desc_label: Label = $CenterAnchor/ModalCard/VBox/DescLabel

# Stats rows
@onready var stats_vbox: VBoxContainer = $CenterAnchor/ModalCard/VBox/StatsBox

# Gauge & Upgrade button
@onready var gauge_bar: TextureProgressBar = $CenterAnchor/ModalCard/VBox/GaugeContainer/GaugeBar
@onready var gauge_text: Label = $CenterAnchor/ModalCard/VBox/GaugeContainer/GaugeText
@onready var btn_upgrade: Button = $CenterAnchor/ModalCard/VBox/BtnUpgrade
@onready var btn_replace: Button = $CenterAnchor/ModalCard/VBox/BtnReplace

var current_card_id: StringName = &""
var current_deck_slot: int = -1
var _state: Dictionary = {}

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_modal)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	if btn_replace != null:
		btn_replace.pressed.connect(_on_replace_pressed)
	dark_overlay.gui_input.connect(_on_overlay_gui_input)

func open_for_card(card_id: StringName) -> void:
	current_deck_slot = -1
	if btn_replace != null:
		btn_replace.visible = false
	_show_modal_for_card(card_id)

func open_for_deck_slot(slot_index: int, card_id: StringName) -> void:
	current_deck_slot = slot_index
	if btn_replace != null:
		btn_replace.visible = true
	_show_modal_for_card(card_id)

func _show_modal_for_card(card_id: StringName) -> void:
	current_card_id = card_id
	_refresh_data()
	visible = true
	
	# Animation d'entrée pop punchy
	modal_card.scale = Vector2(0.7, 0.7)
	modal_card.modulate.a = 0.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(modal_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(modal_card, "modulate:a", 1.0, 0.15)

func _on_replace_pressed() -> void:
	var slot_to_replace: int = current_deck_slot
	var cid: StringName = current_card_id
	close_modal()
	replace_requested.emit(slot_to_replace, cid)

func close_modal() -> void:
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(modal_card, "scale", Vector2(0.8, 0.8), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(modal_card, "modulate:a", 0.0, 0.10)
	tw.finished.connect(func() -> void:
		visible = false
		modal_card.scale = Vector2.ONE
		modal_card.modulate.a = 1.0
	)

func _refresh_data() -> void:
	_state = SaveManager.get_card_state(current_card_id)
	if _state.is_empty():
		close_modal()
		return
		
	var def: CandyCardData = _state.get("def", null)
	var lvl: int = _state.get("level", 1)
	var cards: int = _state.get("cards", 0)
	var req_cards: int = _state.get("req_cards", 2)
	var req_gold: int = _state.get("req_gold", 20)
	var is_unlocked: bool = _state.get("unlocked", false)
	var has_cards: bool = _state.get("has_enough_cards", false)
	var has_gold: bool = _state.get("has_enough_gold", false)
	
	card_name_label.text = def.display_name if is_unlocked else "Mystère"
	card_subtitle_label.text = def.subtitle
	desc_label.text = def.description
	icon_rect.texture = def.icon_texture if is_unlocked else preload("res://assets/ui/icon_ball_locked.png")
	
	# Badge rareté
	match def.rarity:
		CandyCardData.Rarity.COMMON:
			rarity_badge.text = "COMMUNE"
			rarity_badge.modulate = Color(0.65, 0.70, 0.75)
		CandyCardData.Rarity.RARE:
			rarity_badge.text = "RARE"
			rarity_badge.modulate = Color(0.30, 0.65, 1.0)
		CandyCardData.Rarity.EPIC:
			rarity_badge.text = "ÉPIQUE"
			rarity_badge.modulate = Color(0.75, 0.35, 0.95)
		CandyCardData.Rarity.LEGENDARY:
			rarity_badge.text = "LÉGENDAIRE"
			rarity_badge.modulate = Color(1.0, 0.75, 0.2)
			
	# Niveau transition & Statistiques
	if is_unlocked:
		level_transition_label.text = "NIVEAU %d  ➔  NIVEAU %d" % [lvl, lvl + 1]
		_refresh_stats_rows(def, lvl)
		
		# Jauge
		gauge_bar.max_value = float(maxi(1, req_cards))
		gauge_bar.value = float(cards)
		gauge_text.text = "%d / %d Cartes" % [cards, req_cards]
		if has_cards:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill_green.png")
		else:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill.png")
			
		# Bouton Améliorer
		if not has_cards:
			btn_upgrade.disabled = true
			btn_upgrade.text = "Encore %d cartes requises" % (req_cards - cards)
			btn_upgrade.modulate = Color(0.8, 0.8, 0.8)
		elif not has_gold:
			btn_upgrade.disabled = false # Permet de cliquer pour ouvrir la boutique
			btn_upgrade.text = "Manque %d 🪙 (Boutique)" % (req_gold - SaveManager.gold)
			btn_upgrade.modulate = Color(1.0, 0.6, 0.6)
		else:
			btn_upgrade.disabled = false
			btn_upgrade.text = "✨ AMÉLIORER  •  %d 🪙" % req_gold
			btn_upgrade.modulate = Color.WHITE
	else:
		level_transition_label.text = "CARTE VERROUILLÉE"
		_refresh_locked_stats(def)
		gauge_bar.value = 0
		gauge_text.text = "À débloquer dans les sachets"
		btn_upgrade.disabled = true
		btn_upgrade.text = "VERROUILLÉ"

func _refresh_stats_rows(def: CandyCardData, lvl: int) -> void:
	for child in stats_vbox.get_children():
		child.queue_free()

	if def == null:
		return

	var stats: Array[Dictionary] = def.get_displayed_stats(lvl)
	for stat in stats:
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(340, 24)
		row.add_theme_constant_override(&"separation", 6)

		var name_lbl: Label = Label.new()
		name_lbl.text = "%s %s" % [stat.get("icon", "✨"), stat.get("label", "Stat")]
		name_lbl.add_theme_font_size_override(&"font_size", 14)
		name_lbl.add_theme_color_override(&"font_color", Color(0.35, 0.22, 0.15, 1.0))
		row.add_child(name_lbl)

		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

		var val_lbl: Label = Label.new()
		val_lbl.text = stat.get("cur_str", "")
		val_lbl.add_theme_font_size_override(&"font_size", 14)
		val_lbl.add_theme_color_override(&"font_color", Color(0.20, 0.12, 0.06, 1.0))
		row.add_child(val_lbl)

		if stat.get("has_gain", false):
			var gain_lbl: Label = Label.new()
			gain_lbl.text = "➔ %s (%s)" % [stat.get("next_str", ""), stat.get("gain_str", "")]
			gain_lbl.add_theme_font_size_override(&"font_size", 14)
			gain_lbl.add_theme_color_override(&"font_color", Color(0.18, 0.65, 0.25, 1.0))
			row.add_child(gain_lbl)

		stats_vbox.add_child(row)

func _refresh_locked_stats(def: CandyCardData) -> void:
	for child in stats_vbox.get_children():
		child.queue_free()

	if def == null:
		return

	var stats: Array[Dictionary] = def.get_displayed_stats(1)
	for stat in stats:
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(340, 24)
		row.add_theme_constant_override(&"separation", 6)

		var name_lbl: Label = Label.new()
		name_lbl.text = "%s %s" % [stat.get("icon", "✨"), stat.get("label", "Stat")]
		name_lbl.add_theme_font_size_override(&"font_size", 14)
		name_lbl.add_theme_color_override(&"font_color", Color(0.55, 0.50, 0.45, 1.0))
		row.add_child(name_lbl)

		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

		var val_lbl: Label = Label.new()
		val_lbl.text = "?"
		val_lbl.add_theme_font_size_override(&"font_size", 14)
		val_lbl.add_theme_color_override(&"font_color", Color(0.55, 0.50, 0.45, 1.0))
		row.add_child(val_lbl)

		stats_vbox.add_child(row)

func _on_upgrade_pressed() -> void:
	if _state.is_empty():
		return
	var has_cards: bool = _state.get("has_enough_cards", false)
	var has_gold: bool = _state.get("has_enough_gold", false)
	
	if has_cards and not has_gold:
		# Pas assez d'or -> raccourci vers la boutique
		close_modal()
		EventBus.open_shop_requested.emit(&"currency")
		return
		
	if SaveManager.upgrade_card(current_card_id):
		Input.vibrate_handheld(60)
		_play_upgrade_celebration()
		_refresh_data()
		card_upgraded_locally.emit(current_card_id)

func _play_upgrade_celebration() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(icon_rect, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(icon_rect, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE)

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()
	elif event is InputEventScreenTouch and event.pressed:
		close_modal()
