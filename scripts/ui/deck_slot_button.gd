class_name DeckSlotButton
extends PanelContainer

## Bouton d'un slot de deck (6 slots dans un deck).
## Affiche la carte au format CollectionCard (icône, nom, rareté, niveau, jauge d'amélioration).

signal slot_pressed(slot_index: int)

@export var slot_index: int = 0

@onready var card_frame: TextureRect = $CardFrame
@onready var icon_rect: TextureRect = $ContentControl/IconContainer/IconRect
@onready var halo_rect: TextureRect = $ContentControl/IconContainer/HaloRect
@onready var name_label: Label = $ContentControl/NameLabel
@onready var level_label: Label = $ContentControl/LevelBadge/LevelLabel
@onready var level_badge: Control = $ContentControl/LevelBadge
@onready var gauge_bar: TextureProgressBar = $ContentControl/GaugeContainer/GaugeBar
@onready var gauge_label: Label = $ContentControl/GaugeContainer/GaugeLabel
@onready var upgrade_arrow: Label = $ContentControl/GaugeContainer/UpgradeArrow
@onready var btn_click: Button = $BtnClick

var current_card_id: StringName = &""
var _pulse_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(192, 254)
	pivot_offset = Vector2(96, 127)
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
		
		# Texture de jauge gourmande sirop étincelant ou caramel ambré
		gauge_bar.texture_progress = preload("res://assets/ui/card_gauge_fill.png")
		if has_enough_cards:
			gauge_bar.tint_progress = Color(0.35, 1.0, 0.45, 1.0) # Sirop menthe/pomme étincelant
		else:
			gauge_bar.tint_progress = Color(0.96, 0.68, 0.22, 1.0) # Sirop caramel ambré gourmand

	if upgrade_arrow != null:
		upgrade_arrow.visible = can_upgrade

	if cdef != null:
		_apply_rarity_style(cdef.rarity, can_upgrade)

	if can_upgrade:
		_start_upgrade_glow()
	else:
		_stop_upgrade_glow()

const RARITY_FRAMES: Dictionary = {
	CandyCardData.Rarity.COMMON: preload("res://assets/ui/card_frame_common.png"),
	CandyCardData.Rarity.UNCOMMON: preload("res://assets/ui/card_frame_uncommon.png"),
	CandyCardData.Rarity.RARE: preload("res://assets/ui/card_frame_rare.png"),
	CandyCardData.Rarity.EPIC: preload("res://assets/ui/card_frame_epic.png"),
	CandyCardData.Rarity.LEGENDARY: preload("res://assets/ui/card_frame_legendary.png"),
	CandyCardData.Rarity.MYTHIC: preload("res://assets/ui/card_frame_mythic.png"),
}

func _apply_rarity_style(r: CandyCardData.Rarity, can_up: bool) -> void:
	if card_frame != null:
		var tex: Texture2D = RARITY_FRAMES.get(r, RARITY_FRAMES[CandyCardData.Rarity.COMMON])
		card_frame.texture = tex
		if can_up:
			card_frame.modulate = Color(1.05, 1.02, 0.95, 1.0)
		else:
			card_frame.modulate = Color(1.0, 1.0, 1.0, 1.0)

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
