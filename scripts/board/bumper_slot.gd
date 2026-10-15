class_name BumperSlot
extends Node2D

## Emplacement de bumper sur le plateau.
## Dessine un cercle en pointillés élégant, réactif au mode placement et au survol.

signal slot_clicked(slot: BumperSlot)

@export var slot_id: int = 0
@export var radius: float = 40.0

var occupied_bumper_instance: Node2D = null
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

func attach_bumper(bumper_node: Node2D) -> void:
	occupied_bumper_instance = bumper_node
	if bumper_node.get_parent() != self:
		if bumper_node.get_parent() != null:
			bumper_node.get_parent().remove_child(bumper_node)
		add_child(bumper_node)
	bumper_node.position = Vector2.ZERO
	bumper_node.visible = true
	queue_redraw()

func clear_bumper() -> void:
	if occupied_bumper_instance != null and is_instance_valid(occupied_bumper_instance):
		occupied_bumper_instance.queue_free()
	occupied_bumper_instance = null
	queue_redraw()

func _draw() -> void:
	# Si un bumper est posé sur ce slot, laisser le bumper visible au premier plan
	if is_occupied():
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
