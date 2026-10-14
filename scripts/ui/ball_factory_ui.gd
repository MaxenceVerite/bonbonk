class_name BallFactoryUI
extends Control

## Machine de synthèse de bonbons / distributeur gumball vertical
## Affiche le dôme supérieur avec l'engrenage / turbine rotative et le tube en verre translucide
## contenant les bonbons prêts à être tirés.

@export var max_slots: int = 5
@export var slot_height: float = 126.0
@export var ball_radius: float = 23.0


# Textures préchargées
var _tex_tube_bg: Texture2D = preload("res://assets/ui/candy_dispenser_tube.png")
var _tex_machine_cap: Texture2D = preload("res://assets/ui/candy_machine_cap.png")

# États de jeu
var ball_types_in_tube: Array[StringName] = []
var is_synthesizing: bool = false
var next_synthesis_type: StringName = &"standard"
var synthesis_progress: float = 0.0 # 0.0 à 1.0
var drum_rotation_angle: float = 0.0

func _process(delta: float) -> void:
	if is_synthesizing:
		drum_rotation_angle += delta * 7.5
		queue_redraw()

func set_factory_state(types_queue: Array[StringName], synthesizing: bool, next_type: StringName, progress: float) -> void:
	ball_types_in_tube = types_queue
	is_synthesizing = synthesizing
	next_synthesis_type = next_type
	synthesis_progress = progress
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var center_x: float = w * 0.5
	
	# 1. TUBE VERTICAL EN VERRE & CADRE CARAMEL
	var tube_top_y: float = 84.0
	var tube_h: float = float(max_slots) * slot_height + 24.0
	var tube_rect: Rect2 = Rect2(6.0, tube_top_y, w - 12.0, tube_h)
	
	if _tex_tube_bg:
		draw_texture_rect(_tex_tube_bg, tube_rect, false)
	else:
		draw_rect(tube_rect, Color(0.14, 0.08, 0.2, 0.75), true)
	
	# Repères des compartiments / étagères de bonbons
	var tube_bottom_y: float = tube_top_y + (max_slots * slot_height) + 12.0
	for s in range(1, max_slots):
		var shelf_y: float = tube_bottom_y - (s * slot_height)
		# Support doré sous chaque bonbon
		draw_line(Vector2(20.0, shelf_y), Vector2(w - 20.0, shelf_y), Color(0.9, 0.7, 0.4, 0.45), 2.0)
		draw_line(Vector2(24.0, shelf_y + 1.0), Vector2(w - 24.0, shelf_y + 1.0), Color(0.2, 0.1, 0.05, 0.35), 1.0)
	
	# 2. BONBONS DANS LE TUBE
	# ball_types_in_tube[0] = prochaine bille prête en bas (slot 0)
	for i in range(ball_types_in_tube.size()):
		var slot_index: int = i
		var slot_y_center: float = tube_bottom_y - (slot_index * slot_height) - (slot_height * 0.5)
		var ball_pos: Vector2 = Vector2(center_x, slot_y_center)
		var b_type: StringName = ball_types_in_tube[i]
		var b_rad: float = ball_radius * (1.18 if b_type == &"jawbreaker" else 1.0)
		_draw_candy_ball(ball_pos, b_rad, b_type, 1.0)
	
	# 3. DÔME / TURBINE DE LA MACHINE EN HAUT
	var cap_w: float = w
	var cap_h: float = 96.0
	var cap_rect: Rect2 = Rect2(0.0, 0.0, cap_w, cap_h)
	if _tex_machine_cap:
		draw_texture_rect(_tex_machine_cap, cap_rect, false)
	
	# Hublot rotatif au cœur du dôme
	var drum_center: Vector2 = Vector2(center_x, 38.0)
	var drum_radius: float = 26.0
	
	# Lueur active du distributeur
	var active_color: Color = CardCatalog.get_candy_palette(next_synthesis_type).color
		
	if is_synthesizing:
		draw_circle(drum_center, drum_radius + 4.0, Color(active_color.r, active_color.g, active_color.b, 0.35))
	
	# Rotor à ailettes bonbon
	var num_blades: int = 4
	for i in range(num_blades):
		var blade_angle: float = drum_rotation_angle + (i * TAU / num_blades)
		var blade_end: Vector2 = drum_center + Vector2(cos(blade_angle), sin(blade_angle)) * (drum_radius - 5.0)
		draw_line(drum_center, blade_end, Color(1.0, 0.85, 0.45, 0.85), 3.0)
	
	# Bonbon en formation dans la chambre
	if is_synthesizing:
		var synth_rad: float = ball_radius * clampf(synthesis_progress, 0.35, 0.95)
		if next_synthesis_type == &"jawbreaker":
			synth_rad *= 1.15
		var synth_alpha: float = clampf(synthesis_progress, 0.3, 1.0)
		_draw_candy_ball(drum_center, synth_rad, next_synthesis_type, synth_alpha)

func _draw_candy_ball(pos: Vector2, radius: float, b_type: StringName, alpha: float) -> void:
	var pal: Dictionary = CardCatalog.get_candy_palette(b_type)
	var b_col: Color = pal.color
	var c_col: Color = pal.core
	var r_col: Color = pal.ring
	
	# Ombre portée de la boule
	draw_circle(pos + Vector2(0.0, 4.0), radius * 0.95, Color(0.08, 0.03, 0.12, 0.38 * alpha))
	
	# Corps brillant de la sucrerie
	draw_circle(pos, radius, Color(b_col.r, b_col.g, b_col.b, alpha))
	# Anneau extérieur
	draw_arc(pos, radius, 0, TAU, 32, Color(r_col.r, r_col.g, r_col.b, alpha), 2.5)
	# Cœur pulpeux translucide
	draw_circle(pos, radius * 0.58, Color(c_col.r, c_col.g, c_col.b, alpha * 0.9))
	# Reflet lumineux en arc supérieur
	draw_arc(pos + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.55, -PI * 0.8, -PI * 0.1, 16, Color(1.0, 1.0, 1.0, 0.85 * alpha), 2.5)
	# Point de brillance spéculaire
	draw_circle(pos + Vector2(-radius * 0.32, -radius * 0.32), radius * 0.22, Color(1.0, 1.0, 1.0, 0.95 * alpha))
	
	# Icône distinctive
	if b_type == &"fizz":
		# Éclair acidulé
		draw_line(pos + Vector2(2.0, -8.0), pos + Vector2(-3.0, 1.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
		draw_line(pos + Vector2(-3.0, 1.0), pos + Vector2(3.0, 1.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
		draw_line(pos + Vector2(3.0, 1.0), pos + Vector2(-2.0, 8.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
	elif b_type == &"caramel":
		# Gouttelette de caramel fondant au centre
		draw_circle(pos, radius * 0.28, Color(0.65, 0.3, 0.05, 0.95 * alpha))
		draw_circle(pos + Vector2(-1, -1), radius * 0.12, Color(1.0, 0.95, 0.7, 0.95 * alpha))
	elif b_type == &"mentox" or b_type == &"mint":
		# Flocon de givre / menthe fraîche
		draw_line(pos + Vector2(-5.0, 0.0), pos + Vector2(5.0, 0.0), Color(0.2, 0.65, 0.88, 0.95 * alpha), 2.0)
		draw_line(pos + Vector2(0.0, -5.0), pos + Vector2(0.0, 5.0), Color(0.2, 0.65, 0.88, 0.95 * alpha), 2.0)
		draw_line(pos + Vector2(-3.5, -3.5), pos + Vector2(3.5, 3.5), Color(0.2, 0.65, 0.88, 0.95 * alpha), 1.6)
		draw_line(pos + Vector2(-3.5, 3.5), pos + Vector2(3.5, -3.5), Color(0.2, 0.65, 0.88, 0.95 * alpha), 1.6)
	elif b_type == &"jawbreaker":
		# Piqueté multicolore confettis jawbreaker
		draw_circle(pos + Vector2(-5.0, 4.0), 2.2, Color(0.95, 0.2, 0.35, alpha))
		draw_circle(pos + Vector2(6.0, -4.0), 2.4, Color(0.15, 0.55, 0.95, alpha))
		draw_circle(pos + Vector2(-4.0, -5.0), 2.0, Color(1.0, 0.8, 0.1, alpha))
		draw_circle(pos + Vector2(4.0, 5.0), 2.0, Color(0.2, 0.85, 0.4, alpha))
	else:
		# Spirale / bonbon rond classique
		draw_arc(pos, radius * 0.32, 0, TAU, 20, Color(1.0, 1.0, 1.0, 0.85 * alpha), 1.8)

