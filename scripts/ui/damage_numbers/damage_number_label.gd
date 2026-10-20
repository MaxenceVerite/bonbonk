class_name DamageNumberLabel
extends Node2D

## Étiquette de texte flottant unitaire pour les dégâts et soins (Floating Combat Text).
## Totalement vectorielle avec outline contrasté, animation "Pop & Drift", et support du stacking.

signal animation_finished(label_instance: DamageNumberLabel)

var label: Label = null

var current_value: int = 0
var current_prefix: String = ""
var target_ref: Node = null

var _elapsed_time: float = 0.0
var _duration: float = 0.68
var _is_active: bool = false
var _active_tween: Tween = null
var _base_position: Vector2 = Vector2.ZERO

const FONT_FREDOKA: FontFile = preload("res://assets/fonts/Fredoka-Variable.ttf")

func _init() -> void:
	z_index = 50
	z_as_relative = true
	visible = false

	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Taille fixe avec pivot centré exactement en (0, 0)
	label.custom_minimum_size = Vector2(120.0, 36.0)
	label.position = Vector2(-60.0, -18.0)

	# Configuration de la typographie Fredoka
	label.add_theme_font_override(&"font", FONT_FREDOKA)
	label.add_theme_font_size_override(&"font_size", 22)
	label.add_theme_color_override(&"font_outline_color", Color(0.10, 0.04, 0.03, 0.95))
	label.add_theme_constant_override(&"outline_size", 6)
	label.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	label.add_theme_constant_override(&"shadow_offset_y", 2)

	add_child(label)

func play_number(
	p_target: Node,
	p_value: int,
	p_prefix: String,
	p_color: Color,
	p_spawn_pos: Vector2,
	p_font_size: int = 22,
	p_is_crit: bool = false
) -> void:
	target_ref = p_target
	current_value = p_value
	current_prefix = p_prefix
	_base_position = p_spawn_pos
	global_position = p_spawn_pos
	_elapsed_time = 0.0
	_is_active = true

	# Mise à jour du texte et du style
	label.text = "%s%d" % [current_prefix, current_value]
	label.add_theme_color_override(&"font_color", p_color)
	label.add_theme_font_size_override(&"font_size", p_font_size)

	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)

	_kill_tween()

	# Animation "Juicy" Pop & Float
	var tw: Tween = create_tween().set_parallel(true)
	_active_tween = tw

	# 1. Échelle : Pop-in énergique
	var start_scale: Vector2 = Vector2(0.4, 0.4)
	var peak_scale: Vector2 = Vector2(1.45, 1.45) if p_is_crit else Vector2(1.25, 1.25)
	scale = start_scale

	var scale_seq: Tween = create_tween()
	scale_seq.tween_property(self, "scale", peak_scale, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_seq.tween_property(self, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Dérive verticale fluide avec dispersion latérale douce
	var drift_x: float = randf_range(-14.0, 14.0)
	var drift_y: float = -randf_range(44.0, 58.0)
	var target_pos: Vector2 = _base_position + Vector2(drift_x, drift_y)
	tw.tween_property(self, "global_position", target_pos, _duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. Fondu de sortie vers la fin
	tw.tween_property(self, "modulate:a", 0.0, 0.22).set_delay(_duration - 0.22)

	# 4. Fin et recyclage
	tw.chain().tween_callback(_on_tween_finished)

## Empile les dégâts en temps réel si plusieurs coups touchent la même cible très vite (Anti-Flood)
func stack_damage(added_value: int) -> void:
	current_value += added_value
	label.text = "%s%d" % [current_prefix, current_value]

	# Micro-rebond de feedback
	var bounce_tw: Tween = create_tween()
	scale = Vector2(1.3, 1.3)
	bounce_tw.tween_property(self, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func can_stack_with(p_target: Node) -> bool:
	return _is_active and target_ref == p_target and _elapsed_time < 0.25

func _process(delta: float) -> void:
	if _is_active:
		_elapsed_time += delta

func _kill_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null

func _on_tween_finished() -> void:
	_is_active = false
	visible = false
	target_ref = null
	animation_finished.emit(self)

func reset_state() -> void:
	_kill_tween()
	_is_active = false
	visible = false
	target_ref = null
	scale = Vector2.ONE
	modulate = Color(1.0, 1.0, 1.0, 1.0)
