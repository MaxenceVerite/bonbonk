class_name MegaSlamController
extends Node2D

## Contrôleur d'orchestration du Mega Slam (Clutch Save) :
## - Cooldown stratégique (9s)
## - Allongement et synchronisation des deux batteurs vers le centre
## - Arc électrique entre les pointes des batteurs
## - Déclenchement de la Super Chain sur les billes interceptées
## - Secousse d'impact sur le plateau

signal cooldown_changed(current: float, max_duration: float, is_ready: bool)
signal mega_slam_activated

@export var cooldown_duration: float = 9.0
var current_cooldown: float = 0.0

@export var left_gate: WoodenGateFlipper = null
@export var right_gate: WoodenGateFlipper = null
@export var board: Node2D = null

var _lightning_line: Line2D = null
var _lightning_duration: float = 0.0
var _shake_tween: Tween = null
var _original_board_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_cooldown = 0.0
	EventBus.mega_slam_requested.connect(_on_mega_slam_requested)
	_setup_lightning_line()
	if board != null:
		_original_board_pos = board.position

func _setup_lightning_line() -> void:
	_lightning_line = Line2D.new()
	_lightning_line.width = 7.0
	_lightning_line.default_color = Color(1.8, 1.6, 0.4, 0.95) # HDR Jaune / Cyan éclatant
	_lightning_line.texture_mode = Line2D.LINE_TEXTURE_NONE
	_lightning_line.z_index = 25
	_lightning_line.visible = false
	add_child(_lightning_line)

var _last_left_press_time: float = -100.0
var _last_right_press_time: float = -100.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mega_slam"):
		trigger_mega_slam()
		return

	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if event.is_action_pressed(&"flip_left"):
		_last_left_press_time = now
		if (now - _last_right_press_time) <= 0.18 or Input.is_action_pressed(&"flip_right"):
			trigger_mega_slam()
			_last_left_press_time = -100.0
			_last_right_press_time = -100.0
	elif event.is_action_pressed(&"flip_right"):
		_last_right_press_time = now
		if (now - _last_left_press_time) <= 0.18 or Input.is_action_pressed(&"flip_left"):
			trigger_mega_slam()
			_last_left_press_time = -100.0
			_last_right_press_time = -100.0

func _process(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown = maxf(0.0, current_cooldown - delta)
		cooldown_changed.emit(current_cooldown, cooldown_duration, is_ready())
		EventBus.mega_slam_cooldown_updated.emit(current_cooldown, cooldown_duration, is_ready())

	# Détection directe clavier PC au cas où l'événement n'a pas transité
	if Input.is_action_just_pressed(&"mega_slam"):
		trigger_mega_slam()
	elif (Input.is_action_just_pressed(&"flip_left") and Input.is_action_pressed(&"flip_right")) or (Input.is_action_just_pressed(&"flip_right") and Input.is_action_pressed(&"flip_left")):
		trigger_mega_slam()

	# Animation de l'arc électrique qui crépite entre les batteurs
	if _lightning_duration > 0.0:
		_lightning_duration -= delta
		_update_lightning_arc()
		if _lightning_duration <= 0.0 and _lightning_line != null:
			_lightning_line.visible = false

func is_ready() -> bool:
	return current_cooldown <= 0.0

func _on_mega_slam_requested() -> void:
	trigger_mega_slam()

## Tente d'activer le Mega Slam. Retourne true si déclenché, false si en cooldown.
func trigger_mega_slam() -> bool:
	if not is_ready():
		# Petit feedback haptique de rejet
		Input.vibrate_handheld(12)
		return false

	current_cooldown = cooldown_duration
	cooldown_changed.emit(current_cooldown, cooldown_duration, false)
	EventBus.mega_slam_cooldown_updated.emit(current_cooldown, cooldown_duration, false)
	EventBus.mega_slam_activated.emit()
	mega_slam_activated.emit()

	# 1. Haptique lourde & Hitstop initial
	Input.vibrate_handheld(50)
	var HitstopScript = preload("res://scripts/core/hitstop_manager.gd")
	HitstopScript.trigger(0.04, 0.04)

	# 2. Déclenchement de l'allongement et de la frappe des batteurs
	if left_gate != null and is_instance_valid(left_gate):
		left_gate.trigger_mega_slam(0.55)
	if right_gate != null and is_instance_valid(right_gate):
		right_gate.trigger_mega_slam(0.55)

	# 3. Allumage de l'arc électrique
	_lightning_duration = 0.42
	if _lightning_line != null:
		_lightning_line.visible = true
		_update_lightning_arc()

	# 4. Secousse d'écran dynamique (Camera / Board Punch)
	_trigger_screen_shake()

	# 5. Détection immédiate des billes proches des batteurs / dans le trou central
	_supercharge_nearby_balls()

	return true

## Crée un arc électrique en zigzag entre les deux pointes de batteur
func _update_lightning_arc() -> void:
	if _lightning_line == null:
		return
	var p_start: Vector2 = Vector2(278.0, 1192.0)
	var p_end: Vector2 = Vector2(338.0, 1192.0)

	if left_gate != null and is_instance_valid(left_gate):
		p_start = left_gate.to_global(Vector2(190.0, 0.0))
	if right_gate != null and is_instance_valid(right_gate):
		p_end = right_gate.to_global(Vector2(190.0, 0.0))

	# Coordonnées locales pour le Line2D
	var local_start: Vector2 = to_local(p_start)
	var local_end: Vector2 = to_local(p_end)

	var points: PackedVector2Array = PackedVector2Array()
	points.append(local_start)
	
	var segments: int = 5
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var base_pt: Vector2 = local_start.lerp(local_end, t)
		var jitter: Vector2 = Vector2(randf_range(-6.0, 6.0), randf_range(-14.0, 14.0))
		points.append(base_pt + jitter)

	points.append(local_end)
	_lightning_line.points = points
	_lightning_line.default_color = Color(1.8, randf_range(1.4, 1.9), 0.3, randf_range(0.7, 1.0))

## Intercepte et propulse les billes se trouvant dans la zone basse des flippers
func _supercharge_nearby_balls() -> void:
	var balls: Array[Ball] = Ball.active_balls
	for ball in balls:
		if ball == null or not is_instance_valid(ball) or ball.is_super_chain:
			continue
		# Si la bille est au niveau des batteurs (y >= 1020)
		if ball.global_position.y >= 1020.0 and ball.global_position.y <= 1260.0:
			ball.enter_super_chain()

## Secousse percutante sur le plateau
func _trigger_screen_shake() -> void:
	if board == null:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var shake_offset: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(6.0, 12.0))
	_shake_tween.tween_property(board, "position", _original_board_pos + shake_offset, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(board, "position", _original_board_pos - shake_offset * 0.5, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(board, "position", _original_board_pos, 0.08).set_trans(Tween.TRANS_SINE)
