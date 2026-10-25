class_name CollectionCard
extends PanelContainer

## Carte individuelle dans la grille de la collection (style Clash Royale / Brawl Stars).
## Affiche l'icône, le nom, le niveau, la jauge (ex: 10/2) et un halo/indicateur quand améliorable.

signal card_clicked(card_id: StringName)

@onready var card_frame: TextureRect = $CardFrame
@onready var empty_slot: Panel = get_node_or_null("EmptySlot")
@onready var content_control: Control = $ContentControl
@onready var icon_rect: TextureRect = $ContentControl/IconContainer/IconRect
@onready var halo_rect: TextureRect = $ContentControl/IconContainer/HaloRect
@onready var name_label: Label = $ContentControl/NameLabel
@onready var level_badge: Control = $ContentControl/LevelBadge
@onready var level_label: Label = $ContentControl/LevelBadge/LevelLabel
@onready var gauge_bar: TextureProgressBar = $ContentControl/GaugeContainer/GaugeBar
@onready var gauge_label: Label = $ContentControl/GaugeContainer/GaugeLabel
@onready var upgrade_arrow: Label = $ContentControl/GaugeContainer/UpgradeArrow
@onready var locked_overlay: Control = $LockedOverlay
@onready var locked_icon: TextureRect = $LockedOverlay/LockedIcon

var card_id: StringName = &""
var is_unlocked: bool = false
var can_upgrade: bool = false
var current_level: int = 1
var rarity: CandyCardData.Rarity = CandyCardData.Rarity.COMMON

var _is_hovered: bool = false
var _is_pressed: bool = false
var _pulse_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(196, 258)
	pivot_offset = Vector2(98, 129)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(state: Dictionary) -> void:
	card_id = state.get("id", &"")
	var def: CandyCardData = state.get("def", null)
	if def == null:
		return
		
	is_unlocked = state.get("unlocked", false)
	current_level = state.get("level", 1)
	var cards: int = state.get("cards", 0)
	var req_cards: int = state.get("req_cards", 2)
	can_upgrade = state.get("can_upgrade", false)
	var has_enough_cards: bool = state.get("has_enough_cards", false)
	rarity = def.rarity
	
	if is_unlocked:
		if empty_slot != null:
			empty_slot.visible = false
		card_frame.visible = true
		content_control.visible = true
		if locked_overlay != null:
			locked_overlay.visible = false
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		name_label.text = def.display_name
		_apply_rarity_style(def.rarity, is_unlocked, can_upgrade)
		
		level_badge.visible = true
		level_label.text = "NV. %d" % current_level
		icon_rect.texture = def.icon_texture
		icon_rect.modulate = Color.WHITE
		
		# Jauge de progression
		gauge_bar.max_value = float(maxi(1, req_cards))
		gauge_bar.value = float(cards)
		gauge_label.text = "%d / %d" % [cards, req_cards]
		
		gauge_bar.texture_progress = preload("res://assets/ui/card_gauge_fill.png")
		if has_enough_cards:
			gauge_bar.tint_progress = Color(0.35, 1.0, 0.45, 1.0) # Sirop menthe/pomme étincelant
			upgrade_arrow.visible = true
			_start_upgrade_glow()
		else:
			gauge_bar.tint_progress = Color(0.96, 0.68, 0.22, 1.0) # Sirop caramel ambré gourmand
			upgrade_arrow.visible = false
			_stop_upgrade_glow()
	else:
		# Emplacement vide creusé dans le plateau
		if empty_slot != null:
			empty_slot.visible = true
		card_frame.visible = false
		content_control.visible = false
		if locked_overlay != null:
			locked_overlay.visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stop_upgrade_glow()

const RARITY_FRAMES: Dictionary = {
	CandyCardData.Rarity.COMMON: preload("res://assets/ui/card_frame_common.png"),
	CandyCardData.Rarity.UNCOMMON: preload("res://assets/ui/card_frame_uncommon.png"),
	CandyCardData.Rarity.RARE: preload("res://assets/ui/card_frame_rare.png"),
	CandyCardData.Rarity.EPIC: preload("res://assets/ui/card_frame_epic.png"),
	CandyCardData.Rarity.LEGENDARY: preload("res://assets/ui/card_frame_legendary.png"),
	CandyCardData.Rarity.MYTHIC: preload("res://assets/ui/card_frame_mythic.png"),
}

func _apply_rarity_style(r: CandyCardData.Rarity, unlocked: bool, can_up: bool) -> void:
	if card_frame != null:
		var tex: Texture2D = RARITY_FRAMES.get(r, RARITY_FRAMES[CandyCardData.Rarity.COMMON])
		card_frame.texture = tex
		if not unlocked:
			card_frame.modulate = Color(0.40, 0.35, 0.32, 0.85)
		elif can_up:
			card_frame.modulate = Color(1.05, 1.02, 0.95, 1.0)
		else:
			card_frame.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _start_upgrade_glow() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		return
	halo_rect.visible = true
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(halo_rect, "modulate:a", 0.9, 0.7).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(halo_rect, "modulate:a", 0.3, 0.7).set_trans(Tween.TRANS_SINE)

func _stop_upgrade_glow() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	halo_rect.visible = false

func _on_mouse_entered() -> void:
	if not is_unlocked:
		return
	_is_hovered = true
	_animate_scale(Vector2(1.04, 1.04))

func _on_mouse_exited() -> void:
	if not is_unlocked:
		return
	_is_hovered = false
	if not _is_pressed:
		_animate_scale(Vector2(1.0, 1.0))

func _on_gui_input(event: InputEvent) -> void:
	if not is_unlocked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_animate_scale(Vector2(0.95, 0.95))
		else:
			var was_pressed: bool = _is_pressed
			_is_pressed = false
			_animate_scale(Vector2(1.04, 1.04) if _is_hovered else Vector2(1.0, 1.0))
			if was_pressed:
				card_clicked.emit(card_id)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_is_pressed = true
			_animate_scale(Vector2(0.95, 0.95))
		else:
			if _is_pressed:
				_is_pressed = false
				_animate_scale(Vector2(1.0, 1.0))
				card_clicked.emit(card_id)

func _animate_scale(target_scale: Vector2) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", target_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
