class_name LevelPin
extends Control

## Pin interactif sur la carte Saga (Aventure).
## Représente un niveau (1 à 10), avec état verrouillé / actif / réussi et nombre d'étoiles.

signal pin_clicked(level_number: int)

enum Status { LOCKED, UNLOCKED, CLEARED }

@export var level_number: int = 1
@export var is_boss: bool = false

var current_status: Status = Status.LOCKED
var current_stars: int = 0

@onready var button: Button = $Button
@onready var number_label: Label = $Button/CenterContainer/NumberLabel
@onready var lock_icon: Label = $Button/CenterContainer/LockIcon
@onready var boss_crown: Label = $BossCrown
@onready var stars_container: HBoxContainer = $StarsHBox
@onready var star_1: Label = $StarsHBox/Star1
@onready var star_2: Label = $StarsHBox/Star2
@onready var star_3: Label = $StarsHBox/Star3
@onready var glow_pulse: TextureRect = $GlowPulse

var _pulse_tween: Tween = null

func _ready() -> void:
	if button != null:
		button.pressed.connect(_on_button_pressed)
	_refresh_display()

func set_level_info(p_num: int, p_status: Status, p_stars: int, p_is_boss: bool = false) -> void:
	level_number = p_num
	current_status = p_status
	current_stars = clampi(p_stars, 0, 3)
	is_boss = p_is_boss or (p_num == 10)
	_refresh_display()

func _refresh_display() -> void:
	if button == null:
		return

	if is_boss_crown_visible():
		if boss_crown != null:
			boss_crown.visible = true
	elif boss_crown != null:
		boss_crown.visible = false

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	match current_status:
		Status.LOCKED:
			button.disabled = false # On laisse cliquable pour voir les détails/conditions
			button.modulate = Color(0.7, 0.7, 0.75, 0.95)
			if number_label != null:
				number_label.visible = false
			if lock_icon != null:
				lock_icon.visible = true
			if stars_container != null:
				stars_container.visible = false
			if glow_pulse != null:
				glow_pulse.visible = false

		Status.UNLOCKED:
			# Niveau courant à faire : pulse lumineux et vibrant
			button.disabled = false
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if number_label != null:
				number_label.visible = true
				number_label.text = str(level_number)
			if lock_icon != null:
				lock_icon.visible = false
			if stars_container != null:
				stars_container.visible = false
			if glow_pulse != null:
				glow_pulse.visible = true
				_start_pulse_animation()

		Status.CLEARED:
			button.disabled = false
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if number_label != null:
				number_label.visible = true
				number_label.text = str(level_number)
			if lock_icon != null:
				lock_icon.visible = false
			if glow_pulse != null:
				glow_pulse.visible = false
			if stars_container != null:
				stars_container.visible = true
				_update_stars(current_stars)

func is_boss_crown_visible() -> bool:
	return is_boss

func _update_stars(stars: int) -> void:
	if star_1 != null:
		star_1.modulate = Color(1.0, 0.85, 0.2, 1.0) if stars >= 1 else Color(0.4, 0.35, 0.3, 0.5)
	if star_2 != null:
		star_2.modulate = Color(1.0, 0.85, 0.2, 1.0) if stars >= 2 else Color(0.4, 0.35, 0.3, 0.5)
	if star_3 != null:
		star_3.modulate = Color(1.0, 0.85, 0.2, 1.0) if stars >= 3 else Color(0.4, 0.35, 0.3, 0.5)

func _start_pulse_animation() -> void:
	if glow_pulse == null:
		return
	glow_pulse.scale = Vector2(0.9, 0.9)
	glow_pulse.modulate.a = 0.4
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(glow_pulse, "scale", Vector2(1.25, 1.25), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(glow_pulse, "modulate:a", 0.85, 0.75)
	_pulse_tween.tween_property(glow_pulse, "scale", Vector2(0.9, 0.9), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(glow_pulse, "modulate:a", 0.4, 0.75)

func _on_button_pressed() -> void:
	# Petit pop de rebond au clic
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(0.88, 0.88), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE)
	pin_clicked.emit(level_number)
