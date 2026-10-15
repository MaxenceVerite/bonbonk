class_name Board
extends Node2D

## Table de jeu rectangulaire (arène verte) avec portes en bois en bas et injection par le tube latéral droit.

@export var ball_scene: PackedScene
@export var fizzball_scene: PackedScene
@export var caramel_ball_scene: PackedScene
@export var mentox_ball_scene: PackedScene
@export var jawbreaker_ball_scene: PackedScene
@export var enemy_tomato_scene: PackedScene
@export var enemy_ananas_scene: PackedScene
@export var enemy_watermelon_scene: PackedScene

@export var bumper_scene: PackedScene

# Point d'injection où la balle arrive dans l'arène (directement sur le plan incliné droit à x = 540, y = 1010)
@export var tube_exit_position: Vector2 = Vector2(540, 1010)

@onready var left_gate: WoodenGateFlipper = $Gates/LeftGate
@onready var right_gate: WoodenGateFlipper = $Gates/RightGate
@onready var ball_container: Node2D = $BallContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var danger_zone: Area2D = $DangerZone
@onready var bumper_container: Node2D = $BumperContainer
@onready var bumper_slot_container: Node2D = $BumperSlotContainer

var active_balls: Array[Ball] = []
var active_ball: Ball:
	get:
		for b in active_balls:
			if is_instance_valid(b) and not b.is_queued_for_deletion():
				return b
		return null

var _spawn_timer: float = 0.0
@export var enemy_spawn_interval: float = 3.5

# --- SYSTÈME DE FABRIQUE & TUBE DE MUNITIONS ---
@export var max_tube_capacity: int = 5
@export var synthesis_time_seconds: float = 2.4

var ball_tube: BallTubeController = BallTubeController.new()

# Accesseur de rétrocompatibilité
var tube_ball_queue: Array[StringName]:
	get:
		return ball_tube.queue if ball_tube != null else []

signal factory_state_changed(types_queue: Array[StringName], is_synthesizing: bool, next_type: StringName, progress: float, pod_slots: Array[StringName])

var is_game_running: bool = false

func _ready() -> void:
	danger_zone.body_entered.connect(_on_danger_zone_body_entered)
	ball_tube.initialize(max_tube_capacity, synthesis_time_seconds)
	ball_tube.factory_state_changed.connect(func(q, s, n, p, pods): factory_state_changed.emit(q, s, n, p, pods))

func start_game() -> void:
	is_game_running = true
	set_bumper_slots_placement_mode(false)
	# Le joueur choisit quand lancer sa première bille en touchant un Pod !

func reset_board() -> void:
	is_game_running = false
	_spawn_timer = 0.0
	
	# Nettoie les balles et ennemis en cours
	for b in active_balls:
		if is_instance_valid(b):
			b.queue_free()
	active_balls.clear()
		
	for child in enemy_container.get_children():
		child.queue_free()
		
	# Remplissage du tube avec les bonbons-balles du Deck actif
	ball_tube.reset(SaveManager.get_active_deck_balls())

func set_bumper_slots_placement_mode(active: bool) -> void:
	if bumper_slot_container != null:
		for slot in bumper_slot_container.get_children():
			if slot is BumperSlot:
				slot.set_placement_mode(active)

func get_bumper_slots() -> Array:
	if bumper_slot_container != null:
		return bumper_slot_container.get_children()
	return []

func clear_all_bumpers() -> void:
	if bumper_slot_container != null:
		for slot in bumper_slot_container.get_children():
			if slot is BumperSlot:
				slot.clear_bumper()
	if bumper_container != null:
		for child in bumper_container.get_children():
			child.queue_free()

func place_bumper_at_slot(slot: BumperSlot, bumper_id: StringName) -> bool:
	if slot == null or slot.is_occupied():
		return false
	var scene_to_use: PackedScene = bumper_scene
	if scene_to_use == null:
		scene_to_use = load("res://scenes/board/candy_bumper.tscn")
	if scene_to_use == null:
		push_error("Flip: Impossible de charger candy_bumper.tscn")
		return false

	var bumper: CandyBumper = scene_to_use.instantiate() as CandyBumper
	if bumper == null:
		return false

	var res_path: String = "res://resources/%s_bumper.tres" % [String(bumper_id)]
	var b_data: BumperData = null
	if ResourceLoader.exists(res_path):
		b_data = load(res_path) as BumperData
	if b_data == null:
		b_data = load("res://resources/dragiburst_bumper.tres") as BumperData
	if b_data != null:
		bumper.setup_bumper(b_data)

	var st: Dictionary = SaveManager.get_card_state(bumper_id)
	bumper.current_level = st.get("level", 1)

	slot.attach_bumper(bumper)
	return true

func _physics_process(delta: float) -> void:
	if not is_game_running:
		return
		
	# 1. Machine de synthèse de balles continue (Dual-Pods + Réserve)
	var has_balls_in_arena: bool = not active_balls.is_empty()
	ball_tube.update(delta, has_balls_in_arena)
	
	# 2. Nettoyage des billes sorties des limites de l'arène
	for i in range(active_balls.size() - 1, -1, -1):
		var b: Ball = active_balls[i]
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			active_balls.remove_at(i)
		elif b.global_position.y > 1250.0 or b.global_position.x > 620.0 or b.global_position.x < 10.0:
			b.queue_free()
			active_balls.remove_at(i)

func get_ball_scene_for_type(ball_type: StringName) -> PackedScene:
	match ball_type:
		&"fizz":
			return fizzball_scene if fizzball_scene != null else ball_scene
		&"caramel":
			return caramel_ball_scene if caramel_ball_scene != null else ball_scene
		&"mentox", &"mint":
			return mentox_ball_scene if mentox_ball_scene != null else ball_scene
		&"jawbreaker":
			return jawbreaker_ball_scene if jawbreaker_ball_scene != null else ball_scene
		_:
			return ball_scene

func launch_ball_from_pod(pod_index: int) -> bool:
	if not is_game_running:
		return false
	var b_type: StringName = ball_tube.launch_pod(pod_index)
	if b_type.is_empty():
		return false
	_spawn_active_ball(b_type)
	return true

func feed_next_ball_from_tube() -> void:
	if not ball_tube.has_balls():
		return
	var b_type: StringName = ball_tube.pop_next_ball()
	if not b_type.is_empty():
		_spawn_active_ball(b_type)

func _spawn_active_ball(ball_type: StringName) -> Ball:
	var chosen_scene: PackedScene = get_ball_scene_for_type(ball_type)
	if chosen_scene == null:
		return null
	var b: Ball = chosen_scene.instantiate() as Ball
	b.position = tube_exit_position
	b.ball_shattered.connect(func() -> void:
		active_balls.erase(b)
	)
	b.split_requested.connect(_on_ball_split_requested)
	_apply_card_stats_to_ball(b, ball_type)
	# Impulsion diagonale douce vers la gauche et le flipper
	b.linear_velocity = Vector2(-220.0, 180.0)
	ball_container.add_child(b)
	active_balls.append(b)
	return b

func _on_ball_split_requested(sub_types: Array[StringName], spawn_pos: Vector2, dirs: Array[Vector2], speed: float) -> void:
	for i in range(mini(sub_types.size(), dirs.size())):
		var scn: PackedScene = get_ball_scene_for_type(sub_types[i])
		if scn != null:
			var sub_ball: Ball = scn.instantiate() as Ball
			sub_ball.position = spawn_pos + dirs[i] * 22.0
			sub_ball.linear_velocity = dirs[i] * speed
			sub_ball.max_durability = 1
			sub_ball.current_durability = 1
			_apply_card_stats_to_ball(sub_ball, sub_types[i])
			ball_container.add_child(sub_ball)

func _apply_card_stats_to_ball(ball: Ball, ball_type: StringName) -> void:
	if ball == null:
		return
	var card_state: Dictionary = SaveManager.get_card_state(ball_type)
	if card_state.is_empty():
		return
	var def: CandyCardData = card_state.get("def", null)
	var lvl: int = card_state.get("level", 1)
	if def != null:
		ball.configure_from_card(def, lvl)


func spawn_sub_ball(sub_ball: Ball) -> void:
	if sub_ball == null or ball_container == null:
		return
	ball_container.add_child(sub_ball)

var _scene_cache: Dictionary = {}

func spawn_enemy_by_path(scene_path: String, spawn_x: float) -> void:
	if not _scene_cache.has(scene_path):
		_scene_cache[scene_path] = load(scene_path)
	var enemy_scn: PackedScene = _scene_cache.get(scene_path) as PackedScene
	if enemy_scn != null:
		var enemy: Enemy = enemy_scn.instantiate() as Enemy
		enemy.position = Vector2(spawn_x, 80.0)
		enemy_container.add_child(enemy)

func spawn_enemy() -> void:
	var pool: Array[PackedScene] = _get_default_enemy_pool()
	if pool.is_empty():
		return
		
	var chosen_scene: PackedScene = pool.pick_random()
	var enemy: Enemy = chosen_scene.instantiate() as Enemy
	var spawn_x: float = randf_range(90.0, 510.0)
	enemy.position = Vector2(spawn_x, 80.0)
	enemy_container.add_child(enemy)

var _cached_enemy_pool: Array[PackedScene] = []
func _get_default_enemy_pool() -> Array[PackedScene]:
	if _cached_enemy_pool.is_empty():
		if enemy_tomato_scene != null:
			for i in range(5):
				_cached_enemy_pool.append(enemy_tomato_scene)
		if enemy_ananas_scene != null:
			for i in range(3):
				_cached_enemy_pool.append(enemy_ananas_scene)
		if enemy_watermelon_scene != null:
			for i in range(2):
				_cached_enemy_pool.append(enemy_watermelon_scene)
	return _cached_enemy_pool

func _on_danger_zone_body_entered(body: Node2D) -> void:
	if body is Ball:
		active_balls.erase(body as Ball)
		body.queue_free()
	elif body is Enemy:
		var dmg: int = body.enemy_data.damage_on_escape if (body.enemy_data != null) else 1
		EventBus.enemy_escaped.emit(dmg)
		body.queue_free()
