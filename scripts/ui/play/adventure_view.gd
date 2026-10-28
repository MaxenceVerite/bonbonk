class_name AdventureView
extends Control

## Vue Mode Aventure : Carte Saga interactive (Monde 1 : Plage Sucrée).
## Affiche les 10 niveaux le long du chemin sablonneux, les étoiles, le boss au trône,
## et la barre de sélection/modification de deck aventure.

signal level_play_requested(level_data: LevelData)
signal deck_edit_requested(slot_index: int)

const LevelData = preload("res://scripts/data/level_data.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const CampaignCatalog = preload("res://scripts/data/campaign_catalog.gd")
const LevelPinScript = preload("res://scripts/ui/play/level_pin.gd")
const LevelDetailModalScript = preload("res://scripts/ui/play/level_detail_modal.gd")
const CandyCardData = preload("res://scripts/data/candy_card_data.gd")

# Éléments Carte & Scroll
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var map_texture: TextureRect = $ScrollContainer/MapContainer/MapTexture
@onready var pins_parent: Control = $ScrollContainer/MapContainer/PinsContainer
@onready var btn_prev_world: Button = $TopHeaderBar/Margin/HBox/BtnPrevWorld
@onready var btn_next_world: Button = $TopHeaderBar/Margin/HBox/BtnNextWorld
@onready var world_title_label: Label = $TopHeaderBar/Margin/HBox/WorldInfoVBox/WorldTitleLabel
@onready var world_sub_label: Label = $TopHeaderBar/Margin/HBox/WorldInfoVBox/WorldSubLabel
@onready var world_stars_label: Label = $TopHeaderBar/Margin/HBox/StarsBadge/HBoxStars/Label
@onready var world_banner_tex: TextureRect = $TopHeaderBar/BannerTexture
@onready var world_info_vbox: VBoxContainer = $TopHeaderBar/Margin/HBox/WorldInfoVBox

# Barre de Deck Inférieure / Flottante
@onready var floating_deck_dock: PanelContainer = $FloatingDeckDock
@onready var btn_toggle_dock: Button = $FloatingDeckDock/VBox/TopRow/BtnToggleDock
@onready var btn_deck_1: Button = $FloatingDeckDock/VBox/TopRow/DeckTabsRow/BtnDeck1
@onready var btn_deck_2: Button = $FloatingDeckDock/VBox/TopRow/DeckTabsRow/BtnDeck2
@onready var btn_deck_3: Button = $FloatingDeckDock/VBox/TopRow/DeckTabsRow/BtnDeck3
@onready var mini_cards_hbox: HBoxContainer = $FloatingDeckDock/VBox/MiniCardsHBox

# Modale Détail
@onready var level_detail_modal: LevelDetailModalScript = $LevelDetailModal

var _pins: Array[LevelPinScript] = []
var _has_scrolled_to_current: bool = false
var is_dock_expanded: bool = true
var current_world_num: int = 1

# Coordonnées normalisées par défaut si non spécifiées dans WorldData
const PIN_RATIOS: Array[Vector2] = [
	Vector2(0.50, 0.84),
	Vector2(0.44, 0.77),
	Vector2(0.42, 0.70),
	Vector2(0.57, 0.63),
	Vector2(0.44, 0.55),
	Vector2(0.47, 0.47),
	Vector2(0.53, 0.39),
	Vector2(0.40, 0.30),
	Vector2(0.47, 0.20),
	Vector2(0.49, 0.135),
]

func _ready() -> void:
	current_world_num = clampi(SaveManager.campaign_selected_world, 1, CampaignCatalog.get_all_worlds().size())
	_setup_deck_buttons()
	_setup_world_nav_buttons()
	_setup_pins()
	if level_detail_modal != null:
		level_detail_modal.play_level_requested.connect(_on_modal_play_requested)

	refresh()
	call_deferred("_scroll_to_current_level")

func _setup_world_nav_buttons() -> void:
	if btn_prev_world != null:
		btn_prev_world.pressed.connect(func() -> void:
			_navigate_world(-1)
		)
	if btn_next_world != null:
		btn_next_world.pressed.connect(func() -> void:
			_navigate_world(1)
		)

var _world_switch_tween: Tween = null

func _navigate_world(direction: int) -> void:
	var all_worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if all_worlds.is_empty():
		return

	var total: int = all_worlds.size()
	# Navigation circulaire : 1 -> total et total -> 1
	var next_num: int = posmod((current_world_num - 1) + direction, total) + 1
	current_world_num = next_num
	SaveManager.campaign_selected_world = current_world_num
	_has_scrolled_to_current = false
	_animate_world_switch(direction)

func _change_world(target_num: int) -> void:
	var all_worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if all_worlds.is_empty():
		return
	var total: int = all_worlds.size()
	var next_num: int = posmod(target_num - 1, total) + 1
	var dir: int = 1 if target_num >= current_world_num else -1
	current_world_num = next_num
	SaveManager.campaign_selected_world = current_world_num
	_has_scrolled_to_current = false
	_animate_world_switch(dir)

func _animate_world_switch(dir: int) -> void:
	# Si un clic rapide survient pendant l'animation, interrompre proprement le tween en cours
	if _world_switch_tween != null and _world_switch_tween.is_valid():
		_world_switch_tween.kill()

	# Réinitialiser immédiatement les positions et opacités pour la nouvelle transition
	if world_info_vbox != null:
		world_info_vbox.position.x = 0.0
		world_info_vbox.modulate.a = 1.0
	if world_banner_tex != null:
		world_banner_tex.modulate.a = 1.0
	if map_container != null:
		map_container.modulate.a = 1.0

	_world_switch_tween = create_tween()

	# Étape 1 : glissement & fondu de sortie rapide (0.10s)
	if world_info_vbox != null:
		_world_switch_tween.tween_property(world_info_vbox, "position:x", float(-dir * 50), 0.10).as_relative()
		_world_switch_tween.parallel().tween_property(world_info_vbox, "modulate:a", 0.0, 0.10)
	if world_banner_tex != null:
		_world_switch_tween.parallel().tween_property(world_banner_tex, "modulate:a", 0.35, 0.10)
	if map_container != null:
		_world_switch_tween.parallel().tween_property(map_container, "modulate:a", 0.30, 0.10)

	# Étape 2 : Transition chaînée des infos et pins
	_world_switch_tween.chain().tween_callback(func() -> void:
		_update_pins_positions()
		refresh()
		if world_info_vbox != null:
			world_info_vbox.position.x = float(dir * 50)
			world_info_vbox.modulate.a = 0.0
	)

	# Étape 3 : entrée rebondissante chaînée (0.22s)
	if world_info_vbox != null:
		_world_switch_tween.chain().tween_property(world_info_vbox, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_world_switch_tween.parallel().tween_property(world_info_vbox, "modulate:a", 1.0, 0.18)
	if world_banner_tex != null:
		_world_switch_tween.parallel().tween_property(world_banner_tex, "modulate:a", 1.0, 0.22)
	if map_container != null:
		_world_switch_tween.parallel().tween_property(map_container, "modulate:a", 1.0, 0.20)

	# Étape 4 : Cascade pop-in sur les pins
	_world_switch_tween.chain().tween_callback(func() -> void:
		for i in range(_pins.size()):
			var pin = _pins[i]
			pin.scale = Vector2.ZERO
			var delay: float = 0.012 * float(i)
			var pin_tw: Tween = create_tween()
			pin_tw.tween_interval(delay)
			pin_tw.tween_property(pin, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		call_deferred("_scroll_to_current_level")
	)

func _update_pins_positions() -> void:
	var w: WorldData = CampaignCatalog.get_world_by_number(current_world_num)
	if w == null:
		return
	if map_texture != null and w.saga_map_texture != null:
		map_texture.texture = w.saga_map_texture

	var map_size: Vector2 = Vector2(720.0, 1450.0)
	var ratios: Array[Vector2] = w.pin_positions if not w.pin_positions.is_empty() else PIN_RATIOS
	for i in range(_pins.size()):
		if i < ratios.size():
			var r: Vector2 = ratios[i]
			var px: float = r.x * map_size.x - 32.0
			var py: float = r.y * map_size.y - 32.0
			_pins[i].position = Vector2(px, py)

func _setup_deck_buttons() -> void:
	if btn_toggle_dock != null:
		btn_toggle_dock.pressed.connect(_toggle_deck_dock)

	if btn_deck_1 != null:
		btn_deck_1.pressed.connect(func() -> void:
			SaveManager.set_active_deck(0)
			_refresh_deck_dock()
		)
	if btn_deck_2 != null:
		btn_deck_2.pressed.connect(func() -> void:
			SaveManager.set_active_deck(1)
			_refresh_deck_dock()
		)
	if btn_deck_3 != null:
		btn_deck_3.pressed.connect(func() -> void:
			SaveManager.set_active_deck(2)
			_refresh_deck_dock()
		)

func _toggle_deck_dock() -> void:
	is_dock_expanded = not is_dock_expanded
	var tw: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if is_dock_expanded:
		if btn_toggle_dock != null:
			btn_toggle_dock.text = "▼ FERMER"
		if mini_cards_hbox != null:
			mini_cards_hbox.visible = true
			mini_cards_hbox.modulate.a = 0.0
			tw.tween_property(mini_cards_hbox, "modulate:a", 1.0, 0.18)
		if floating_deck_dock != null:
			tw.tween_property(floating_deck_dock, "offset_top", -148.0, 0.22)
	else:
		if btn_toggle_dock != null:
			btn_toggle_dock.text = "▲ MON DECK"
		if mini_cards_hbox != null:
			tw.tween_property(mini_cards_hbox, "modulate:a", 0.0, 0.14)
		if floating_deck_dock != null:
			tw.tween_property(floating_deck_dock, "offset_top", -48.0, 0.20)
		tw.finished.connect(func() -> void:
			if not is_dock_expanded and mini_cards_hbox != null:
				mini_cards_hbox.visible = false
		, CONNECT_ONE_SHOT)

func _setup_pins() -> void:
	_pins.clear()
	var pin_scene: PackedScene = preload("res://scenes/ui/play/level_pin.tscn")

	for i in range(10):
		var pin_num: int = i + 1
		var pin: LevelPinScript = pin_scene.instantiate() as LevelPinScript
		pin.name = "Pin%d" % pin_num
		pin.level_number = pin_num
		pin.is_boss = (pin_num == 10)

		pin.pin_clicked.connect(_on_pin_clicked)
		pins_parent.add_child(pin)
		_pins.append(pin)

	_update_pins_positions()

func refresh() -> void:
	current_world_num = clampi(SaveManager.campaign_selected_world, 1, CampaignCatalog.get_all_worlds().size())
	_update_pins_positions()
	_refresh_pins_display()
	_refresh_header_info()
	_refresh_deck_dock()

func _refresh_pins_display() -> void:
	var world_unlocked: bool = SaveManager.is_campaign_world_unlocked(current_world_num)

	for pin in _pins:
		var num: int = pin.level_number
		var info: Dictionary = SaveManager.get_campaign_level_info(current_world_num, num)
		var stars: int = int(info.get("stars", 0))
		var is_cleared: bool = bool(info.get("cleared", false)) or (stars > 0)

		var st: LevelPinScript.Status = LevelPinScript.Status.LOCKED
		if not world_unlocked:
			st = LevelPinScript.Status.LOCKED
		elif is_cleared:
			st = LevelPinScript.Status.CLEARED
		elif SaveManager.is_campaign_level_unlocked(current_world_num, num):
			st = LevelPinScript.Status.UNLOCKED
		else:
			st = LevelPinScript.Status.LOCKED

		pin.set_level_info(num, st, stars, num == 10)

func _refresh_header_info() -> void:
	var w: WorldData = CampaignCatalog.get_world_by_number(current_world_num)
	if w == null:
		return
	var is_world_locked: bool = not SaveManager.is_campaign_world_unlocked(current_world_num)
	if world_sub_label != null:
		var prefix: String = "🔒 " if is_world_locked else ""
		world_sub_label.text = "%sMONDE %d" % [prefix, w.world_number]
	if world_title_label != null:
		world_title_label.text = w.display_name.to_upper()
	if world_banner_tex != null and w.banner_texture != null:
		world_banner_tex.texture = w.banner_texture

	var all_worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if btn_prev_world != null:
		btn_prev_world.disabled = (all_worlds.size() <= 1)
	if btn_next_world != null:
		btn_next_world.disabled = (all_worlds.size() <= 1)

	# Compte total des étoiles du monde actif
	var total_stars: int = 0
	for i in range(1, 11):
		var info: Dictionary = SaveManager.get_campaign_level_info(current_world_num, i)
		total_stars += int(info.get("stars", 0))

	if world_stars_label != null:
		world_stars_label.text = "%d / 30" % total_stars

func _refresh_deck_dock() -> void:
	var active_idx: int = SaveManager.active_deck_index
	if btn_deck_1 != null:
		btn_deck_1.button_pressed = (active_idx == 0)
	if btn_deck_2 != null:
		btn_deck_2.button_pressed = (active_idx == 1)
	if btn_deck_3 != null:
		btn_deck_3.button_pressed = (active_idx == 2)

	# Aperçu des 6 cartes du deck (billes centrées, agrandies à 64x64)
	if mini_cards_hbox != null:
		for c in mini_cards_hbox.get_children():
			c.queue_free()

		var cur_deck: Array = SaveManager.get_active_deck()
		for slot_i in range(cur_deck.size()):
			var card_id: StringName = cur_deck[slot_i]
			var card_def: CandyCardData = SaveManager.registered_card_defs.get(card_id, null)

			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(64, 64)
			btn.focus_mode = Control.FOCUS_NONE

			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = Color(0.98, 0.94, 0.86, 1.0)
			sb.border_width_left = 3
			sb.border_width_top = 2
			sb.border_width_right = 3
			sb.border_width_bottom = 5
			sb.border_color = Color(0.74, 0.58, 0.42, 1.0)
			sb.set_corner_radius_all(16)
			sb.shadow_color = Color(0.20, 0.10, 0.04, 0.25)
			sb.shadow_size = 4
			sb.shadow_offset = Vector2(0, 2)
			btn.add_theme_stylebox_override("normal", sb)

			var sb_p: StyleBoxFlat = sb.duplicate()
			sb_p.bg_color = Color(0.92, 0.86, 0.76, 1.0)
			sb_p.border_width_bottom = 2
			sb_p.content_margin_top = 3.0
			btn.add_theme_stylebox_override("pressed", sb_p)
			btn.add_theme_stylebox_override("hover", sb)

			# Centrage parfait de la bille au milieu du bouton
			var center_box: CenterContainer = CenterContainer.new()
			center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
			center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

			if card_def != null and card_def.icon_texture != null:
				var tex: TextureRect = TextureRect.new()
				tex.texture = card_def.icon_texture
				tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex.custom_minimum_size = Vector2(50, 50)
				tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
				center_box.add_child(tex)
			else:
				var empty_lbl: Label = Label.new()
				empty_lbl.text = "＋"
				empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.62, 0.50, 0.8))
				empty_lbl.add_theme_font_size_override("font_size", 24)
				empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				center_box.add_child(empty_lbl)

			btn.add_child(center_box)

			var captured_slot: int = slot_i
			btn.pressed.connect(func() -> void:
				deck_edit_requested.emit(captured_slot)
			)
			mini_cards_hbox.add_child(btn)

func _scroll_to_current_level() -> void:
	if scroll_container == null:
		return
	var cur_lvl: int = 1
	for pin in _pins:
		if pin.current_status == LevelPinScript.Status.UNLOCKED:
			cur_lvl = pin.level_number
			break
		elif pin.current_status == LevelPinScript.Status.CLEARED:
			cur_lvl = pin.level_number

	var w: WorldData = CampaignCatalog.get_world_by_number(current_world_num)
	var ratios: Array[Vector2] = w.pin_positions if (w != null and not w.pin_positions.is_empty()) else PIN_RATIOS
	if cur_lvl - 1 < ratios.size():
		var ratio: Vector2 = ratios[cur_lvl - 1]
		var target_y: float = ratio.y * 1450.0 - (scroll_container.size.y * 0.5)
		target_y = clampf(target_y, 0.0, maxf(0.0, 1450.0 - scroll_container.size.y))
		scroll_container.scroll_vertical = int(target_y)

func _on_pin_clicked(level_number: int) -> void:
	var w: WorldData = CampaignCatalog.get_world_by_number(current_world_num)
	if w == null:
		return
	var lvl_data: LevelData = w.get_level(level_number)
	if lvl_data != null and level_detail_modal != null:
		level_detail_modal.open(lvl_data)

func _on_modal_play_requested(level_data: LevelData) -> void:
	if level_data != null:
		SaveManager.campaign_selected_world = current_world_num
		SaveManager.campaign_selected_level = level_data.level_number
		level_play_requested.emit(level_data)
