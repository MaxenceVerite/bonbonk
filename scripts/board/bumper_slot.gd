class_name BumperSlot
extends Node2D

## Emplacement de bumper sur le plateau.
## Dessine un cercle en pointillés élégant, réactif au mode placement et au survol.

signal slot_clicked(slot: BumperSlot)

@export var slot_id: int = 0
@export var radius: float = 40.0

var occupied_bumper_instance: Node2D = null
var _saved_original_bumper: Node2D = null
var _is_temporary_override: bool = false
var is_highlighted: bool = false
var is_placement_active: bool = false

# Couleurs bonbon bien visibles et contrastées sur le sable
const COLOR_IDLE_OUTLINE: Color = Color(0.35, 0.15, 0.08, 0.45)
const COLOR_IDLE_FILL: Color = Color(1.0, 1.0, 1.0, 0.15)
const COLOR_ACTIVE_OUTLINE: Color = Color(0.98, 0.28, 0.55, 1.0) # Rose bonbon vibrant
const COLOR_ACTIVE_DASH: Color = Color(1.0, 0.95, 0.4, 1.0)     # Jaune éclatant
const COLOR_ACTIVE_FILL: Color = Color(0.98, 0.28, 0.55, 0.28)   # Pastille rosée bien distincte
const COLOR_HIGHLIGHT_OUTLINE: Color = Color(0.2, 1.0, 0.45, 1.0)
const COLOR_HIGHLIGHT_FILL: Color = Color(0.2, 1.0, 0.45, 0.38)

var _pulse_t: float = 0.0

func _ready() -> void:
	z_index = 5

func _process(delta: float) -> void:
	if is_placement_active:
		_pulse_t += delta * 4.0
		queue_redraw()

func set_placement_mode(active: bool) -> void:
	is_placement_active = active
	queue_redraw()

func set_highlight(highlight: bool) -> void:
	if is_highlighted != highlight:
		is_highlighted = highlight
		queue_redraw()

func is_occupied() -> bool:
	return occupied_bumper_instance != null and is_instance_valid(occupied_bumper_instance)

func has_temporary_override() -> bool:
	return _is_temporary_override

func attach_bumper(bumper_node: Node2D) -> void:
	occupied_bumper_instance = bumper_node
	if bumper_node.get_parent() != self:
		if bumper_node.get_parent() != null:
			bumper_node.get_parent().remove_child(bumper_node)
		add_child(bumper_node)
	bumper_node.position = Vector2.ZERO
	bumper_node.visible = true
	queue_redraw()

## Remplace temporairement le bumper du slot (ex: Bumper Brocoli du Boss)
func override_with_temporary_bumper(temp_bumper: Node2D) -> void:
	if _is_temporary_override:
		restore_from_temporary_override()

	_saved_original_bumper = occupied_bumper_instance
	_is_temporary_override = true

	if _saved_original_bumper != null and is_instance_valid(_saved_original_bumper):
		_saved_original_bumper.visible = false
		_saved_original_bumper.set_process(false)
		_saved_original_bumper.set_physics_process(false)
		for child in _saved_original_bumper.get_children():
			if child is CollisionShape2D:
				child.set_deferred(&"disabled", true)

	occupied_bumper_instance = temp_bumper
	if temp_bumper.get_parent() != self:
		if temp_bumper.get_parent() != null:
			temp_bumper.get_parent().remove_child(temp_bumper)
		add_child(temp_bumper)
	temp_bumper.position = Vector2.ZERO
	temp_bumper.visible = true
	queue_redraw()

## Restaure l'état d'origine du slot après destruction du bumper temporaire
func restore_from_temporary_override() -> void:
	if not _is_temporary_override:
		return
	_is_temporary_override = false

	if occupied_bumper_instance != null and is_instance_valid(occupied_bumper_instance) and occupied_bumper_instance != _saved_original_bumper:
		occupied_bumper_instance.queue_free()

	if _saved_original_bumper != null and is_instance_valid(_saved_original_bumper):
		occupied_bumper_instance = _saved_original_bumper
		occupied_bumper_instance.visible = true
		occupied_bumper_instance.set_process(true)
		occupied_bumper_instance.set_physics_process(true)
		for child in occupied_bumper_instance.get_children():
			if child is CollisionShape2D:
				child.set_deferred(&"disabled", false)

		# Animation de libération éclatante du bumper originel
		occupied_bumper_instance.scale = Vector2(0.4, 0.4)
		var pop_tw: Tween = occupied_bumper_instance.create_tween()
		pop_tw.tween_property(occupied_bumper_instance, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		occupied_bumper_instance = null

	_saved_original_bumper = null
	queue_redraw()

var _is_hidden_temporarily: bool = false

## Masque ou réactive temporairement le bumper occupant ce slot
func set_bumper_hidden(is_hidden: bool) -> void:
	_is_hidden_temporarily = is_hidden
	if occupied_bumper_instance != null and is_instance_valid(occupied_bumper_instance):
		occupied_bumper_instance.visible = not is_hidden
		occupied_bumper_instance.set_process(not is_hidden)
		occupied_bumper_instance.set_physics_process(not is_hidden)
		for child in occupied_bumper_instance.get_children():
			if child is CollisionShape2D:
				child.set_deferred(&"disabled", is_hidden)
		if not is_hidden:
			occupied_bumper_instance.scale = Vector2(0.4, 0.4)
			var pop_tw: Tween = occupied_bumper_instance.create_tween()
			pop_tw.tween_property(occupied_bumper_instance, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func clear_bumper() -> void:
	if _is_temporary_override:
		restore_from_temporary_override()
	if occupied_bumper_instance != null and is_instance_valid(occupied_bumper_instance):
		occupied_bumper_instance.queue_free()
	occupied_bumper_instance = null
	_is_hidden_temporarily = false
	queue_redraw()

func _draw() -> void:
	# Si masqué temporairement ou si un bumper est posé sur ce slot, ne pas dessiner la pastille de fond
	if _is_hidden_temporarily or is_occupied():
		return

	var center: Vector2 = Vector2.ZERO
	var r: float = radius

	if is_placement_active:
		var pulse: float = 0.85 + 0.15 * sin(_pulse_t)
		var fill_color: Color = COLOR_HIGHLIGHT_FILL if is_highlighted else COLOR_ACTIVE_FILL
		var primary_outline: Color = COLOR_HIGHLIGHT_OUTLINE if is_highlighted else COLOR_ACTIVE_OUTLINE
		var dash_color: Color = COLOR_HIGHLIGHT_OUTLINE if is_highlighted else COLOR_ACTIVE_DASH
		if is_highlighted:
			r += 4.0

		# 1. Pastille de fond bien visible sur le sable
		draw_circle(center, r, fill_color)

		# 2. Anneau d'ombre / contour externe sombre pour détacher du fond
		draw_arc(center, r + 1.0, 0.0, TAU, 36, Color(0.2, 0.1, 0.05, 0.5), 3.0, true)

		# 3. Anneau en tirets bonbon contrastés
		var num_dots: int = 16
		var dot_angle: float = TAU / float(num_dots)
		for i in range(num_dots):
			var start_ang: float = float(i) * dot_angle + (_pulse_t * 0.5)
			var end_ang: float = start_ang + (dot_angle * 0.6)
			if i % 2 == 0:
				draw_arc(center, r, start_ang, end_ang, 4, dash_color, 3.5, true)
			else:
				draw_arc(center, r, start_ang, end_ang, 4, primary_outline, 2.5, true)

		# 4. Anneau intérieur fin pulsé
		var inner_r: float = r * (0.65 * pulse)
		draw_arc(center, inner_r, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.45), 2.0, true)

		# 5. Cible / Croix centrale nette
		if not is_occupied():
			var cross_s: float = 8.0
			draw_circle(center, 3.0, Color(1.0, 1.0, 1.0, 0.9))
			draw_line(center - Vector2(cross_s, 0), center + Vector2(cross_s, 0), primary_outline, 2.5)
			draw_line(center - Vector2(0, cross_s), center + Vector2(0, cross_s), primary_outline, 2.5)
	else:
		# En partie normale (inactif), discret mais visible
		draw_circle(center, r, COLOR_IDLE_FILL)
		draw_arc(center, r, 0.0, TAU, 24, COLOR_IDLE_OUTLINE, 2.0, true)
