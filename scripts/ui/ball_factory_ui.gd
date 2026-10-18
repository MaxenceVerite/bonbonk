class_name BallFactoryUI
extends Control

## Machine de synthèse de bonbons avec Dual-Pod Launcher.
## Affiche en haut la turbine et le tube vertical de réserve,
## et dans l'espace libre en bas : deux alvéoles tactiles (Pods) interactives
## permettant de choisir entre deux billes prêtes et de décider du moment du tir.

const CardCatalogScript = preload("res://scripts/data/card_catalog.gd")
const CandyTextureHelper = preload("res://scripts/core/candy_texture_helper.gd")

signal pod_launch_requested(pod_index: int)

# Textures préchargées
var _tex_tube_bg: Texture2D = preload("res://assets/ui/candy_dispenser_tube.png")
var _tex_machine_cap: Texture2D = preload("res://assets/ui/candy_machine_cap.png")

# États de jeu
var reserve_balls: Array[StringName] = []
var pod_slots: Array[StringName] = [&"", &""]
var is_synthesizing: bool = false
var next_synthesis_type: StringName = &"fizz"
var synthesis_progress: float = 0.0 # 0.0 à 1.0
var drum_rotation_angle: float = 0.0
var _pulse_timer: float = 0.0
var is_interaction_enabled: bool = true

# Animation de pression sur les pods
var _pod_scales: Array[float] = [1.0, 1.0]

# Boutons enfants invisibles pour la détection tactile
var pod_button_0: Control = null
var pod_button_1: Control = null

# Coordonnées des Pods (abaissés pour un confort optimal sous le pouce droit)
const POD_0_Y: float = 1000.0 # Pod Bas (hauteur directe du pouce)
const POD_1_Y: float = 880.0  # Pod Haut (immédiatement au-dessus)
const POD_RADIUS: float = 42.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_pod_buttons()

func _setup_pod_buttons() -> void:
	# Pod 0 (Bas)
	pod_button_0 = Control.new()
	pod_button_0.name = "PodButton0"
	pod_button_0.mouse_filter = Control.MOUSE_FILTER_STOP
	pod_button_0.position = Vector2(size.x * 0.5 - POD_RADIUS - 6.0, POD_0_Y - POD_RADIUS - 6.0)
	pod_button_0.size = Vector2((POD_RADIUS + 6.0) * 2.0, (POD_RADIUS + 6.0) * 2.0)
	pod_button_0.gui_input.connect(func(event: InputEvent) -> void: _on_pod_input(0, event))
	add_child(pod_button_0)

	# Pod 1 (Haut)
	pod_button_1 = Control.new()
	pod_button_1.name = "PodButton1"
	pod_button_1.mouse_filter = Control.MOUSE_FILTER_STOP
	pod_button_1.position = Vector2(size.x * 0.5 - POD_RADIUS - 6.0, POD_1_Y - POD_RADIUS - 6.0)
	pod_button_1.size = Vector2((POD_RADIUS + 6.0) * 2.0, (POD_RADIUS + 6.0) * 2.0)
	pod_button_1.gui_input.connect(func(event: InputEvent) -> void: _on_pod_input(1, event))
	add_child(pod_button_1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_button_positions()

func _update_button_positions() -> void:
	var cx: float = size.x * 0.5
	if pod_button_0 != null:
		pod_button_0.position = Vector2(cx - POD_RADIUS - 6.0, POD_0_Y - POD_RADIUS - 6.0)
	if pod_button_1 != null:
		pod_button_1.position = Vector2(cx - POD_RADIUS - 6.0, POD_1_Y - POD_RADIUS - 6.0)

func _process(delta: float) -> void:
	_pulse_timer += delta * 4.0
	if is_synthesizing:
		drum_rotation_angle += delta * 7.5
	queue_redraw()

func set_factory_state(_types_queue: Array[StringName], synthesizing: bool, next_type: StringName, progress: float, pods: Array[StringName] = []) -> void:
	if pods.size() >= 2:
		pod_slots = pods.duplicate()
	is_synthesizing = synthesizing
	next_synthesis_type = next_type
	synthesis_progress = progress

	# Calcul de la réserve à partir de la file globale
	reserve_balls.clear()
	if _types_queue.size() > 2:
		for i in range(2, _types_queue.size()):
			reserve_balls.append(_types_queue[i])

	queue_redraw()

var _last_launch_time: float = -999.0

func _on_pod_input(pod_index: int, event: InputEvent) -> void:
	var is_press: bool = false
	if event is InputEventScreenTouch:
		if event.pressed:
			is_press = true
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_press = true
		accept_event()

	if is_press:
		# Empêcher l'activation involontaire du batteur droit lors du tir d'un bonbon
		Input.action_release(&"flip_right")
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if (now - _last_launch_time) >= 0.22:
			_last_launch_time = now
			_trigger_pod_launch(pod_index)

func _trigger_pod_launch(pod_index: int) -> void:
	if not is_interaction_enabled:
		return
	if pod_index < 0 or pod_index >= pod_slots.size():
		return
	if pod_slots[pod_index].is_empty():
		_play_empty_pod_jiggle(pod_index)
		return

	# Animation squash & stretch dynamique
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		_pod_scales[pod_index] = v
		queue_redraw()
	, 1.0, 0.82, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void:
		_pod_scales[pod_index] = v
		queue_redraw()
	, 0.82, 1.16, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void:
		_pod_scales[pod_index] = v
		queue_redraw()
	, 1.16, 1.0, 0.10)

	# Vibration haptique
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(25)

	pod_launch_requested.emit(pod_index)

func _play_empty_pod_jiggle(pod_index: int) -> void:
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		_pod_scales[pod_index] = v
		queue_redraw()
	, 1.0, 0.94, 0.05)
	tw.tween_method(func(v: float) -> void:
		_pod_scales[pod_index] = v
		queue_redraw()
	, 0.94, 1.0, 0.08)

func _draw() -> void:
	var w: float = size.x
	var center_x: float = w * 0.5

	# 1. TUBE VERTICAL DE RÉSERVE EN HAUT
	var tube_top_y: float = 84.0
	var tube_h: float = (POD_1_Y - POD_RADIUS) - tube_top_y - 18.0
	var tube_rect: Rect2 = Rect2(8.0, tube_top_y, w - 16.0, tube_h)

	if _tex_tube_bg:
		draw_texture_rect(_tex_tube_bg, tube_rect, false)
	else:
		draw_rect(tube_rect, Color(0.14, 0.08, 0.2, 0.75), true)

	# Étagères en verre de réserve
	var num_shelves: int = 4
	var shelf_step: float = tube_h / float(num_shelves)
	for s in range(1, num_shelves):
		var shelf_y: float = tube_top_y + (float(s) * shelf_step)
		draw_line(Vector2(20.0, shelf_y), Vector2(w - 20.0, shelf_y), Color(0.9, 0.7, 0.4, 0.35), 2.0)

	# Bonbons en réserve dans le tube
	for i in range(mini(3, reserve_balls.size())):
		var ball_y: float = tube_top_y + tube_h - (float(i) * shelf_step) - (shelf_step * 0.5)
		var b_type: StringName = reserve_balls[i]
		_draw_candy_ball(Vector2(center_x, ball_y), 21.0, b_type, 0.85)

	# 2. TOBOGGAN EN SUCRE TRANSPARENT COURBE
	_draw_delivery_chute(center_x)

	# 3. DUAL-POD LAUNCHER (LES 2 ALVÉOLES TACTILES DANS L'ESPACE LIBRE)
	_draw_pod_chamber(Vector2(center_x, POD_1_Y), 1, "B")
	_draw_pod_chamber(Vector2(center_x, POD_0_Y), 0, "A")

	# 4. TURBINE & DÔME SUPÉRIEUR
	var cap_rect: Rect2 = Rect2(0.0, 0.0, w, 96.0)
	if _tex_machine_cap:
		draw_texture_rect(_tex_machine_cap, cap_rect, false)

	# Hublot rotatif au cœur du dôme
	var drum_center: Vector2 = Vector2(center_x, 38.0)
	var drum_radius: float = 26.0

	var active_color: Color = CardCatalogScript.get_candy_palette(next_synthesis_type).color
	if is_synthesizing:
		draw_circle(drum_center, drum_radius + 4.0, Color(active_color.r, active_color.g, active_color.b, 0.35))

	var num_blades: int = 4
	for i in range(num_blades):
		var blade_angle: float = drum_rotation_angle + (i * TAU / num_blades)
		var blade_end: Vector2 = drum_center + Vector2(cos(blade_angle), sin(blade_angle)) * (drum_radius - 5.0)
		draw_line(drum_center, blade_end, Color(1.0, 0.85, 0.45, 0.85), 3.0)

	if is_synthesizing:
		var synth_rad: float = 22.0 * clampf(synthesis_progress, 0.35, 0.95)
		if next_synthesis_type == &"jawbreaker":
			synth_rad *= 1.15
		var synth_alpha: float = clampf(synthesis_progress, 0.3, 1.0)
		_draw_candy_ball(drum_center, synth_rad, next_synthesis_type, synth_alpha)

func _draw_pod_chamber(pos: Vector2, pod_index: int, pod_label: String) -> void:
	var scale_factor: float = _pod_scales[pod_index]
	var r: float = POD_RADIUS * scale_factor
	var b_type: StringName = pod_slots[pod_index] if pod_index < pod_slots.size() else &""
	var is_ready: bool = not b_type.is_empty()

	# 1. Ombre portée douce sous le Pod
	draw_circle(pos + Vector2(0.0, 5.0), r + 4.0, Color(0.08, 0.03, 0.12, 0.45))

	# 2. Anneau métallique doré / caramel
	draw_circle(pos, r + 4.0, Color(0.85, 0.58, 0.22, 1.0))
	draw_circle(pos, r + 1.0, Color(0.24, 0.12, 0.08, 1.0))
	draw_circle(pos, r - 2.0, Color(0.12, 0.08, 0.18, 0.92))

	if is_ready:
		var pal: Dictionary = CardCatalogScript.get_candy_palette(b_type)
		var p_color: Color = pal.color

		# Halo pulsant d'énergie prête
		var pulse: float = 0.5 + 0.5 * sin(_pulse_timer + float(pod_index) * 1.5)
		var halo_col: Color = Color(p_color.r, p_color.g, p_color.b, 0.30 + pulse * 0.25)
		draw_circle(pos, r + 6.0 + pulse * 4.0, halo_col)

		# Dessin du bonbon au centre
		var ball_rad: float = (r - 12.0) * (1.12 if b_type == &"jawbreaker" else 1.0)
		_draw_candy_ball(pos, ball_rad, b_type, 1.0)

		# Cloche de verre avec reflet supérieur éclatant
		draw_arc(pos + Vector2(-r * 0.2, -r * 0.2), r * 0.55, -PI * 0.8, -PI * 0.1, 16, Color(1.0, 1.0, 1.0, 0.75), 2.5)

		# Petit badge "TAP" stylisé à gauche du Pod
		var tag_pos: Vector2 = pos + Vector2(-r - 14.0, 0.0)
		draw_circle(tag_pos, 9.0, Color(1.0, 0.9, 0.2, 0.95))
		draw_line(tag_pos + Vector2(2.0, -4.0), tag_pos + Vector2(-3.0, 0.0), Color(0.3, 0.1, 0.05, 1.0), 2.2)
		draw_line(tag_pos + Vector2(-3.0, 0.0), tag_pos + Vector2(2.0, 4.0), Color(0.3, 0.1, 0.05, 1.0), 2.2)
	else:
		# Pod vide en cours de fabrication : jauge circulaire animée
		if is_synthesizing:
			var fill_angle: float = synthesis_progress * TAU
			draw_arc(pos, r - 8.0, -PI * 0.5, -PI * 0.5 + fill_angle, 28, Color(1.0, 0.85, 0.35, 0.9), 3.5)
			# Icône sablier / engrenage discret
			draw_circle(pos, 4.0, Color(1.0, 1.0, 1.0, 0.5))
		else:
			draw_arc(pos, r - 8.0, 0.0, TAU, 24, Color(0.5, 0.4, 0.6, 0.3), 2.0)

	# Étiquette A / B discrète dorée
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var lbl_str: String = "P%d" % (pod_index + 1)
		draw_string(font, pos + Vector2(-9.0, r + 16.0), lbl_str, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 13, Color(1.0, 0.9, 0.65, 0.75))

func _draw_delivery_chute(center_x: float) -> void:
	# Toboggan en verre translucide guidant les bonbons des Pods vers l'arène
	var p_start: Vector2 = Vector2(center_x, POD_0_Y + POD_RADIUS - 6.0)
	var p_ctrl: Vector2 = Vector2(center_x - 18.0, 1032.0)
	var p_end: Vector2 = Vector2(-16.0, 1032.0) # S'oriente directement vers le haut de la rampe droite

	# Courbe de verre extérieure
	var curve_pts_l: PackedVector2Array = PackedVector2Array()
	var curve_pts_r: PackedVector2Array = PackedVector2Array()

	var steps: int = 14
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		# Formule de Bézier quadratique : (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
		var pt: Vector2 = (1.0 - t) * (1.0 - t) * p_start + 2.0 * (1.0 - t) * t * p_ctrl + t * t * p_end
		curve_pts_l.append(pt + Vector2(-12.0, 0.0))
		curve_pts_r.append(pt + Vector2(12.0, 0.0))

	# Rails de guidage lumineux
	for i in range(steps):
		var alpha: float = 0.35 + 0.3 * sin(_pulse_timer * 1.5 - float(i) * 0.4)
		draw_line(curve_pts_l[i], curve_pts_l[i + 1], Color(0.85, 0.7, 0.95, alpha), 3.0)
		draw_line(curve_pts_r[i], curve_pts_r[i + 1], Color(1.0, 0.88, 0.45, alpha), 3.0)

func _draw_candy_ball(pos: Vector2, radius: float, b_type: StringName, alpha: float) -> void:
	var pal: Dictionary = CardCatalogScript.get_candy_palette(b_type)
	var b_col: Color = pal.color
	var c_col: Color = pal.core
	var r_col: Color = pal.ring

	# Ombre portée
	draw_circle(pos + Vector2(0.0, 3.5), radius * 0.95, Color(0.08, 0.03, 0.12, 0.38 * alpha))

	# Corps coloré
	draw_circle(pos, radius, Color(b_col.r, b_col.g, b_col.b, alpha))
	# Anneau extérieur
	draw_arc(pos, radius, 0, TAU, 32, Color(r_col.r, r_col.g, r_col.b, alpha), 2.5)
	# Cœur pulpeux translucide
	draw_circle(pos, radius * 0.58, Color(c_col.r, c_col.g, c_col.b, alpha * 0.9))
	# Reflet supérieur
	draw_arc(pos + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.55, -PI * 0.8, -PI * 0.1, 16, Color(1.0, 1.0, 1.0, 0.85 * alpha), 2.5)
	draw_circle(pos + Vector2(-radius * 0.32, -radius * 0.32), radius * 0.22, Color(1.0, 1.0, 1.0, 0.95 * alpha))

	# Motifs distinctifs selon le bonbon
	if b_type == &"fizz":
		draw_line(pos + Vector2(2.0, -8.0), pos + Vector2(-3.0, 1.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
		draw_line(pos + Vector2(-3.0, 1.0), pos + Vector2(3.0, 1.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
		draw_line(pos + Vector2(3.0, 1.0), pos + Vector2(-2.0, 8.0), Color(1.0, 1.0, 1.0, 0.95 * alpha), 2.2)
	elif b_type == &"caramel":
		draw_circle(pos, radius * 0.28, Color(0.65, 0.3, 0.05, 0.95 * alpha))
		draw_circle(pos + Vector2(-1, -1), radius * 0.12, Color(1.0, 0.95, 0.7, 0.95 * alpha))
	elif b_type == &"mentox":
		draw_line(pos + Vector2(-5.0, 0.0), pos + Vector2(5.0, 0.0), Color(0.2, 0.65, 0.88, 0.95 * alpha), 2.0)
		draw_line(pos + Vector2(0.0, -5.0), pos + Vector2(0.0, 5.0), Color(0.2, 0.65, 0.88, 0.95 * alpha), 2.0)
	elif b_type == &"jawbreaker":
		draw_circle(pos + Vector2(-5.0, 4.0), 2.2, Color(0.95, 0.2, 0.35, alpha))
		draw_circle(pos + Vector2(6.0, -4.0), 2.4, Color(0.15, 0.55, 0.95, alpha))
		draw_circle(pos + Vector2(-4.0, -5.0), 2.0, Color(1.0, 0.8, 0.1, alpha))
		draw_circle(pos + Vector2(4.0, 5.0), 2.0, Color(0.2, 0.85, 0.4, alpha))
	elif b_type == &"twistypop":
		draw_arc(pos, radius * 0.35, 0, TAU, 20, Color(1.0, 0.85, 0.2, 0.95 * alpha), 2.4)
		draw_circle(pos, radius * 0.18, Color(0.95, 0.25, 0.65, alpha))
	else:
		draw_arc(pos, radius * 0.32, 0, TAU, 20, Color(1.0, 1.0, 1.0, 0.85 * alpha), 1.8)
