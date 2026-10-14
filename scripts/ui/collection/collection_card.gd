class_name CollectionCard
extends PanelContainer

## Carte individuelle dans la grille de la collection (style Clash Royale / Brawl Stars).
## Affiche l'icône, le nom, le niveau, la jauge (ex: 10/2) et un halo/indicateur quand améliorable.

signal card_clicked(card_id: StringName)

@onready var icon_rect: TextureRect = $VBox/IconContainer/IconRect
@onready var halo_rect: TextureRect = $VBox/IconContainer/HaloRect
@onready var name_label: Label = $VBox/NameLabel
@onready var level_badge: PanelContainer = $LevelBadge
@onready var level_label: Label = $LevelBadge/LevelLabel
@onready var gauge_bar: TextureProgressBar = $VBox/GaugeContainer/GaugeBar
@onready var gauge_label: Label = $VBox/GaugeContainer/GaugeLabel
@onready var upgrade_arrow: Label = $VBox/GaugeContainer/UpgradeArrow
@onready var locked_overlay: Panel = $LockedOverlay
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
	custom_minimum_size = Vector2(200, 220)
	pivot_offset = Vector2(100, 110)
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
	
	name_label.text = def.display_name if is_unlocked else "Mystère"
	
	# Style de bordure selon la rareté
	_apply_rarity_style(def.rarity, is_unlocked, can_upgrade)
	
	if is_unlocked:
		locked_overlay.visible = false
		level_badge.visible = true
		level_label.text = "NIV. %d" % current_level
		icon_rect.texture = def.icon_texture
		icon_rect.modulate = Color.WHITE
		
		# Jauge de progression
		gauge_bar.max_value = float(maxi(1, req_cards))
		gauge_bar.value = float(cards) # La jauge ne s'arrête pas artificiellement
		gauge_label.text = "%d / %d" % [cards, req_cards]
		
		if has_enough_cards:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill_green.png") # Vert
			upgrade_arrow.visible = true
			_start_upgrade_glow()
		else:
			gauge_bar.texture_progress = preload("res://assets/ui/hp_bar_fill.png") # Orange / standard
			upgrade_arrow.visible = false
			_stop_upgrade_glow()
	else:
		locked_overlay.visible = true
		level_badge.visible = false
		icon_rect.texture = preload("res://assets/ui/icon_ball_locked.png")
		icon_rect.modulate = Color(0.7, 0.7, 0.7, 0.6)
		gauge_bar.value = 0
		gauge_label.text = "Verrouillé"
		upgrade_arrow.visible = false
		_stop_upgrade_glow()

func _apply_rarity_style(r: CandyCardData.Rarity, unlocked: bool, can_up: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(18)
	sb.corner_detail = 10
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	
	var border_c: Color = Color(0.5, 0.45, 0.4)
	var bg_c: Color = Color(0.96, 0.93, 0.88)
	
	if not unlocked:
		border_c = Color(0.35, 0.32, 0.3)
		bg_c = Color(0.85, 0.82, 0.78)
	else:
		match r:
			CandyCardData.Rarity.COMMON:
				border_c = Color(0.55, 0.60, 0.65) # Argent / Gris noble
				bg_c = Color(0.98, 0.96, 0.94)
			CandyCardData.Rarity.RARE:
				border_c = Color(0.20, 0.55, 0.90) # Bleu azur punchy
				bg_c = Color(0.92, 0.96, 1.0)
			CandyCardData.Rarity.EPIC:
				border_c = Color(0.68, 0.22, 0.85) # Violet vibrant
				bg_c = Color(0.97, 0.92, 1.0)
			CandyCardData.Rarity.LEGENDARY:
				border_c = Color(0.95, 0.72, 0.12) # Or étincelant
				bg_c = Color(1.0, 0.97, 0.88)
				
	if can_up:
		# Liseré renforcé si prêt pour l'amélioration
		sb.border_width_left = 4
		sb.border_width_top = 4
		sb.border_width_right = 4
		sb.border_width_bottom = 4
		sb.border_color = Color(0.3, 0.85, 0.35) # Bordure verte
		sb.shadow_color = Color(0.2, 0.7, 0.2, 0.45)
	else:
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 4
		sb.border_color = border_c
		sb.shadow_color = Color(0.15, 0.08, 0.05, 0.25)
		
	sb.bg_color = bg_c
	add_theme_stylebox_override("panel", sb)

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
	_is_hovered = true
	_animate_scale(Vector2(1.04, 1.04))

func _on_mouse_exited() -> void:
	_is_hovered = false
	if not _is_pressed:
		_animate_scale(Vector2(1.0, 1.0))

func _on_gui_input(event: InputEvent) -> void:
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
