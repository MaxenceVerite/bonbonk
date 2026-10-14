class_name DeckSlotButton
extends PanelContainer

## Bouton d'un slot de deck (6 slots dans un deck).
## Affiche la carte au format CollectionCard (icône, nom, rareté, niveau, jauge d'amélioration).

signal slot_pressed(slot_index: int)

@export var slot_index: int = 0

@onready var icon_rect: TextureRect = $VBox/IconContainer/IconRect
@onready var halo_rect: TextureRect = $VBox/IconContainer/HaloRect
@onready var name_label: Label = $VBox/NameLabel
@onready var level_label: Label = $LevelBadge/LevelLabel
@onready var level_badge: PanelContainer = $LevelBadge
@onready var gauge_bar: TextureProgressBar = $VBox/GaugeContainer/GaugeBar
@onready var gauge_label: Label = $VBox/GaugeContainer/GaugeLabel
@onready var upgrade_arrow: Label = $VBox/GaugeContainer/UpgradeArrow
@onready var btn_click: Button = $BtnClick

var current_card_id: StringName = &""
var _pulse_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(170, 190)
	pivot_offset = Vector2(85, 95)
	if btn_click != null:
		btn_click.pressed.connect(func() -> void:
			slot_pressed.emit(slot_index)
		)

func set_card(card_id: StringName) -> void:
	current_card_id = card_id
	var state: Dictionary = SaveManager.get_card_state(card_id)
	if state.is_empty():
		var def: CandyCardData = SaveManager.registered_card_defs.get(card_id, null)
		if def != null:
			state = {
				"id": card_id,
				"def": def,
				"unlocked": true,
				"level": 1,
				"cards": 0,
				"req_cards": 2,
				"req_gold": 50,
				"can_upgrade": false,
				"has_enough_cards": false,
				"has_enough_gold": false
			}
		else:
			if name_label != null:
				name_label.text = "Vide"
			return

	var cdef: CandyCardData = state.get("def", null)
	var lvl: int = state.get("level", 1)
	var cards: int = state.get("cards", 0)
	var req_cards: int = state.get("req_cards", 2)
	var can_upgrade: bool = state.get("can_upgrade", false)
	var has_enough_cards: bool = state.get("has_enough_cards", false)
	
	if name_label != null:
		name_label.text = cdef.display_name if cdef != null else str(card_id)
		
	if icon_rect != null and cdef != null and cdef.icon_texture != null:
		icon_rect.texture = cdef.icon_texture
		
	if level_label != null:
		level_label.text = "NIV. %d" % lvl

	# Jauge de progression
	if gauge_bar != null and gauge_label != null:
		gauge_bar.max_value = float(maxi(1, req_cards))
		gauge_bar.value = float(cards)
		gauge_label.text = "%d / %d" % [cards, req_cards]
		
		if has_enough_cards:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill_green.png")
		else:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill.png")

	if upgrade_arrow != null:
		upgrade_arrow.visible = can_upgrade

	if cdef != null:
		_apply_rarity_style(cdef.rarity, can_upgrade)

	if can_upgrade:
		_start_upgrade_glow()
	else:
		_stop_upgrade_glow()

func _apply_rarity_style(r: CandyCardData.Rarity, can_up: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(16)
	sb.corner_detail = 10
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	
	var border_c: Color = Color(0.55, 0.60, 0.65)
	var bg_c: Color = Color(0.98, 0.96, 0.94)
	
	match r:
		CandyCardData.Rarity.COMMON:
			border_c = Color(0.55, 0.60, 0.65)
			bg_c = Color(0.98, 0.96, 0.94)
		CandyCardData.Rarity.RARE:
			border_c = Color(0.20, 0.55, 0.90)
			bg_c = Color(0.92, 0.96, 1.0)
		CandyCardData.Rarity.EPIC:
			border_c = Color(0.68, 0.22, 0.85)
			bg_c = Color(0.97, 0.92, 1.0)
		CandyCardData.Rarity.LEGENDARY:
			border_c = Color(0.95, 0.72, 0.12)
			bg_c = Color(1.0, 0.97, 0.88)
			
	if can_up:
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = Color(0.3, 0.85, 0.35)
		sb.shadow_color = Color(0.2, 0.7, 0.2, 0.4)
	else:
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = border_c
		sb.shadow_color = Color(0.15, 0.08, 0.05, 0.22)
		
	sb.bg_color = bg_c
	add_theme_stylebox_override("panel", sb)

func _start_upgrade_glow() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		return
	if halo_rect != null:
		halo_rect.visible = true
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(halo_rect, "modulate:a", 0.9, 0.7).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(halo_rect, "modulate:a", 0.3, 0.7).set_trans(Tween.TRANS_SINE)

func _stop_upgrade_glow() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	if halo_rect != null:
		halo_rect.visible = false
