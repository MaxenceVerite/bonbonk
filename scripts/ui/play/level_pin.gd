class_name LevelPin
extends Control

## Pin interactif sur la carte Saga (Aventure) - Style Macaron Sucré 3D.
## Représente un niveau (1 à 10), avec état verrouillé / actif / réussi et nombre d'étoiles.

signal pin_clicked(level_number: int)

enum Status { LOCKED, UNLOCKED, CLEARED }

@export var level_number: int = 1
@export var is_boss: bool = false

var current_status: Status = Status.LOCKED
var current_stars: int = 0

@onready var ground_shadow: Panel = $GroundShadow
@onready var pin_anchor: Control = $PinAnchor
@onready var button: Button = $PinAnchor/Button
@onready var number_label: Label = $PinAnchor/Button/CenterContainer/NumberLabel
@onready var lock_icon: Label = $PinAnchor/Button/CenterContainer/LockIcon
@onready var boss_crown: Label = $PinAnchor/BossCrown
@onready var stars_banner: PanelContainer = $PinAnchor/StarsBanner
@onready var star_1: Label = $PinAnchor/StarsBanner/StarsHBox/Star1
@onready var star_2: Label = $PinAnchor/StarsBanner/StarsHBox/Star2
@onready var star_3: Label = $PinAnchor/StarsBanner/StarsHBox/Star3
@onready var glow_pulse: TextureRect = $PinAnchor/GlowPulse
@onready var active_pointer: Control = $PinAnchor/ActivePointer

var _pulse_tween: Tween = null
var _pointer_tween: Tween = null
var _crown_tween: Tween = null

# Styles préconfigurés pour chaque état visuel
var _style_cleared_normal: StyleBox = null
var _style_cleared_pressed: StyleBox = null
var _style_active_normal: StyleBox = null
var _style_active_pressed: StyleBox = null
var _style_locked_normal: StyleBox = null
var _style_boss_normal: StyleBox = null

func _ready() -> void:
	_init_styles()
	if button != null:
		button.pressed.connect(_on_button_pressed)
	_refresh_display()

func _init_styles() -> void:
	# Récupération ou création des styles visuels dédiés
	var sb_cleared_n: StyleBoxFlat = StyleBoxFlat.new()
	sb_cleared_n.bg_color = Color(0.24, 0.78, 0.44, 1.0) # Vert bonbon menthe éclatant
	sb_cleared_n.border_width_left = 3
	sb_cleared_n.border_width_top = 3
	sb_cleared_n.border_width_right = 3
	sb_cleared_n.border_width_bottom = 7
	sb_cleared_n.border_color = Color(0.10, 0.48, 0.24, 1.0)
	sb_cleared_n.set_corner_radius_all(32)
	sb_cleared_n.shadow_color = Color(0.08, 0.25, 0.12, 0.35)
	sb_cleared_n.shadow_size = 5
	sb_cleared_n.shadow_offset = Vector2(0, 3)
	_style_cleared_normal = sb_cleared_n

	var sb_cleared_p: StyleBoxFlat = StyleBoxFlat.new()
	sb_cleared_p.bg_color = Color(0.18, 0.68, 0.36, 1.0)
	sb_cleared_p.border_width_left = 3
	sb_cleared_p.border_width_top = 6
	sb_cleared_p.border_width_right = 3
	sb_cleared_p.border_width_bottom = 2
	sb_cleared_p.border_color = Color(0.08, 0.38, 0.18, 1.0)
	sb_cleared_p.set_corner_radius_all(32)
	_style_cleared_pressed = sb_cleared_p

	var sb_active_n: StyleBoxFlat = StyleBoxFlat.new()
	sb_active_n.bg_color = Color(1.0, 0.22, 0.38, 1.0) # Rouge framboise néon
	sb_active_n.border_width_left = 3
	sb_active_n.border_width_top = 3
	sb_active_n.border_width_right = 3
	sb_active_n.border_width_bottom = 7
	sb_active_n.border_color = Color(0.70, 0.08, 0.20, 1.0)
	sb_active_n.set_corner_radius_all(32)
	sb_active_n.shadow_color = Color(1.0, 0.20, 0.35, 0.45)
	sb_active_n.shadow_size = 8
	sb_active_n.shadow_offset = Vector2(0, 4)
	_style_active_normal = sb_active_n

	var sb_active_p: StyleBoxFlat = StyleBoxFlat.new()
	sb_active_p.bg_color = Color(0.85, 0.15, 0.28, 1.0)
	sb_active_p.border_width_left = 3
	sb_active_p.border_width_top = 6
	sb_active_p.border_width_right = 3
	sb_active_p.border_width_bottom = 2
	sb_active_p.border_color = Color(0.55, 0.05, 0.15, 1.0)
	sb_active_p.set_corner_radius_all(32)
	_style_active_pressed = sb_active_p

	var sb_locked_n: StyleBoxFlat = StyleBoxFlat.new()
	sb_locked_n.bg_color = Color(0.50, 0.44, 0.42, 1.0) # Chocolat biscuit mat
	sb_locked_n.border_width_left = 3
	sb_locked_n.border_width_top = 2
	sb_locked_n.border_width_right = 3
	sb_locked_n.border_width_bottom = 5
	sb_locked_n.border_color = Color(0.32, 0.26, 0.24, 1.0)
	sb_locked_n.set_corner_radius_all(32)
	_style_locked_normal = sb_locked_n

	var sb_boss_n: StyleBoxFlat = StyleBoxFlat.new()
	sb_boss_n.bg_color = Color(0.62, 0.20, 0.88, 1.0) # Pourpre Royal Boss
	sb_boss_n.border_width_left = 3
	sb_boss_n.border_width_top = 3
	sb_boss_n.border_width_right = 3
	sb_boss_n.border_width_bottom = 7
	sb_boss_n.border_color = Color(1.0, 0.84, 0.20, 1.0) # Or royal
	sb_boss_n.set_corner_radius_all(32)
	sb_boss_n.shadow_color = Color(0.40, 0.10, 0.55, 0.55)
	sb_boss_n.shadow_size = 8
	sb_boss_n.shadow_offset = Vector2(0, 4)
	_style_boss_normal = sb_boss_n

func set_level_info(p_num: int, p_status: Status, p_stars: int, p_is_boss: bool = false) -> void:
	level_number = p_num
	current_status = p_status
	current_stars = clampi(p_stars, 0, 3)
	is_boss = p_is_boss or (p_num == 10)
	_refresh_display()

func _refresh_display() -> void:
	if button == null:
		return

	_stop_all_tweens()

	# 1. Gestion de la Couronne de Boss
	if is_boss and boss_crown != null:
		boss_crown.visible = true
		_start_crown_float()
	elif boss_crown != null:
		boss_crown.visible = false

	# 2. Adaptation visuelle selon le statut
	match current_status:
		Status.LOCKED:
			button.disabled = false
			if _style_locked_normal != null:
				button.add_theme_stylebox_override("normal", _style_locked_normal)
				button.add_theme_stylebox_override("pressed", _style_locked_normal)

			if pin_anchor != null:
				pin_anchor.scale = Vector2(0.92, 0.92)

			if number_label != null:
				number_label.visible = false
			if lock_icon != null:
				lock_icon.visible = true
			if stars_banner != null:
				stars_banner.visible = false
			if glow_pulse != null:
				glow_pulse.visible = false
			if active_pointer != null:
				active_pointer.visible = false
			if ground_shadow != null:
				ground_shadow.modulate.a = 0.5

		Status.UNLOCKED:
			# NIVEAU COURANT À FAIRE : Pop, grand, flèche bondissante et halo
			button.disabled = false
			var active_style: StyleBox = _style_boss_normal if is_boss else _style_active_normal
			var active_pressed_style: StyleBox = _style_active_pressed if not is_boss else _style_boss_normal
			if active_style != null:
				button.add_theme_stylebox_override("normal", active_style)
				button.add_theme_stylebox_override("pressed", active_pressed_style)

			if number_label != null:
				number_label.visible = true
				number_label.text = str(level_number)
			if lock_icon != null:
				lock_icon.visible = false
			if stars_banner != null:
				stars_banner.visible = false
			if ground_shadow != null:
				ground_shadow.modulate.a = 0.9

			# Flèche bondissante
			if active_pointer != null:
				active_pointer.visible = true
				_start_pointer_bounce()

			# Halo lumineux et pulsation douce
			if glow_pulse != null:
				glow_pulse.visible = true
				_start_pulse_animation()

		Status.CLEARED:
			# NIVEAU RÉUSSI : Vert Menthe éclatant (ou Pourpre Boss) + Bandeau d'étoiles
			button.disabled = false
			var cleared_style: StyleBox = _style_boss_normal if is_boss else _style_cleared_normal
			var cleared_pressed_style: StyleBox = _style_cleared_pressed if not is_boss else _style_boss_normal
			if cleared_style != null:
				button.add_theme_stylebox_override("normal", cleared_style)
				button.add_theme_stylebox_override("pressed", cleared_pressed_style)

			if pin_anchor != null:
				pin_anchor.scale = Vector2(1.0, 1.0)

			if number_label != null:
				number_label.visible = true
				number_label.text = str(level_number)
			if lock_icon != null:
				lock_icon.visible = false
			if glow_pulse != null:
				glow_pulse.visible = false
			if active_pointer != null:
				active_pointer.visible = false
			if ground_shadow != null:
				ground_shadow.modulate.a = 0.7

			# Bandeau des 3 étoiles
			if stars_banner != null:
				stars_banner.visible = true
				_update_stars(current_stars)

func _update_stars(stars: int) -> void:
	if star_1 != null:
		star_1.modulate = Color(1.0, 0.90, 0.25, 1.0) if stars >= 1 else Color(0.40, 0.32, 0.28, 0.45)
	if star_2 != null:
		star_2.modulate = Color(1.0, 0.90, 0.25, 1.0) if stars >= 2 else Color(0.40, 0.32, 0.28, 0.45)
	if star_3 != null:
		star_3.modulate = Color(1.0, 0.90, 0.25, 1.0) if stars >= 3 else Color(0.40, 0.32, 0.28, 0.45)

func _start_pulse_animation() -> void:
	if glow_pulse == null or pin_anchor == null:
		return

	glow_pulse.scale = Vector2(0.9, 0.9)
	glow_pulse.modulate.a = 0.4
	pin_anchor.scale = Vector2(1.08, 1.08)

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(glow_pulse, "scale", Vector2(1.3, 1.3), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(glow_pulse, "modulate:a", 0.9, 0.75)
	_pulse_tween.parallel().tween_property(pin_anchor, "scale", Vector2(1.13, 1.13), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_pulse_tween.tween_property(glow_pulse, "scale", Vector2(0.9, 0.9), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(glow_pulse, "modulate:a", 0.4, 0.75)
	_pulse_tween.parallel().tween_property(pin_anchor, "scale", Vector2(1.08, 1.08), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_pointer_bounce() -> void:
	if active_pointer == null:
		return
	active_pointer.position.y = -32.0
	_pointer_tween = create_tween().set_loops()
	_pointer_tween.tween_property(active_pointer, "position:y", -40.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pointer_tween.tween_property(active_pointer, "position:y", -30.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)

func _start_crown_float() -> void:
	if boss_crown == null:
		return
	boss_crown.position.y = -28.0
	_crown_tween = create_tween().set_loops()
	_crown_tween.tween_property(boss_crown, "position:y", -34.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_crown_tween.tween_property(boss_crown, "position:y", -28.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_all_tweens() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if _pointer_tween != null and _pointer_tween.is_valid():
		_pointer_tween.kill()
	if _crown_tween != null and _crown_tween.is_valid():
		_crown_tween.kill()

func _on_button_pressed() -> void:
	# Rebond tactile dynamique avec squash & stretch cartoon
	if pin_anchor != null:
		var tw: Tween = create_tween()
		tw.tween_property(pin_anchor, "scale", Vector2(0.85, 0.85), 0.07).set_trans(Tween.TRANS_QUAD)
		var target_scale: Vector2 = Vector2(1.10, 1.10) if current_status == Status.UNLOCKED else Vector2.ONE
		tw.tween_property(pin_anchor, "scale", target_scale, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Retour haptique
	if SaveManager != null and SaveManager.has_method("vibrate"):
		SaveManager.vibrate(25)

	pin_clicked.emit(level_number)
