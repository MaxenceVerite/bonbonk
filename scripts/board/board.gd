class_name Board
extends Node2D

## Table de jeu rectangulaire (arène verte) avec portes en bois en bas et injection par le tube latéral droit.

@export var ball_scene: PackedScene
@export var fizzball_scene: PackedScene
@export var caramel_ball_scene: PackedScene
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

var active_ball: Ball = null
var _spawn_timer: float = 0.0
@export var enemy_spawn_interval: float = 3.5

# --- SYSTÈME DE FABRIQUE & TUBE DE MUNITIONS ---
@export var max_tube_capacity: int = 5
@export var synthesis_time_seconds: float = 2.8

# File ordonnée de types de billes : [0] = bas du tube (prochaine sortie), [max-1] = haut
var tube_ball_queue: Array[StringName] = []
var next_synthesis_type: StringName = &"standard"
var _synthesis_timer: float = 0.0
var _is_synthesizing: bool = false

signal factory_state_changed(types_queue: Array[StringName], is_synthesizing: bool, next_type: StringName, progress: float)

var is_game_running: bool = false

func _ready() -> void:
	danger_zone.body_entered.connect(_on_danger_zone_body_entered)

func start_game() -> void:
	is_game_running = true
	set_bumper_slots_placement_mode(false)
	# Injection de la première bille au départ de la partie
	feed_next_ball_from_tube()

func reset_board() -> void:
	is_game_running = false
	_spawn_timer = 0.0
	_synthesis_timer = 0.0
	
	# Nettoie les balles et ennemis en cours
	if active_ball != null and is_instance_valid(active_ball):
		active_ball.queue_free()
		active_ball = null
		
	for child in enemy_container.get_children():
		child.queue_free()
		
	# Remplissage du tube avec les bonbons-balles du Deck actif
	tube_ball_queue.clear()
	var deck_balls: Array[StringName] = SaveManager.get_active_deck_balls()
	for i in range(max_tube_capacity):
		var picked_type: StringName = deck_balls[randi() % deck_balls.size()]
		tube_ball_queue.append(picked_type)
	_pick_next_synthesis_from_deck()
	_emit_factory_state()

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
	if bumper_scene == null:
		return false
	var bumper: CandyBumper = bumper_scene.instantiate() as CandyBumper
	bumper_container.add_child(bumper)
	slot.attach_bumper(bumper)
	return true

func _pick_next_synthesis_from_deck() -> void:
	var deck_balls: Array[StringName] = SaveManager.get_active_deck_balls()
	next_synthesis_type = deck_balls[randi() % deck_balls.size()]

func _physics_process(delta: float) -> void:
	if not is_game_running:
		return
		
	# 1. Machine de synthèse de balles continue dès qu'un slot est libre
	_update_ball_synthesis(delta)
	
	# 3. Sécurité absolue : si aucune balle n'est présente sur le terrain (détruite ou sortie), on injecte immédiatement
	if active_ball == null or not is_instance_valid(active_ball):
		if not tube_ball_queue.is_empty() and not _is_synthesizing:
			feed_next_ball_from_tube()
	elif active_ball.global_position.y > 1250.0 or active_ball.global_position.x > 620.0 or active_ball.global_position.x < 10.0:
		active_ball.queue_free()
		active_ball = null
		if not tube_ball_queue.is_empty():
			feed_next_ball_from_tube()

func _update_ball_synthesis(delta: float) -> void:
	if tube_ball_queue.size() < max_tube_capacity:
		_is_synthesizing = true
		_synthesis_timer += delta
		var progress: float = clampf(_synthesis_timer / synthesis_time_seconds, 0.0, 1.0)
		_emit_factory_state(progress)
		
		if _synthesis_timer >= synthesis_time_seconds:
			# Une balle est achevée, elle entre en haut du tube
			_synthesis_timer = 0.0
			tube_ball_queue.append(next_synthesis_type)
			
			# Tire aléatoirement le prochain bonbon parmi les balles du deck actif
			_pick_next_synthesis_from_deck()
					
			_is_synthesizing = (tube_ball_queue.size() < max_tube_capacity)
			_emit_factory_state(0.0)
			
			if active_ball == null or not is_instance_valid(active_ball):
				feed_next_ball_from_tube()
	else:
		if _is_synthesizing:
			_is_synthesizing = false
			_synthesis_timer = 0.0
			_emit_factory_state(0.0)

func _emit_factory_state(progress: float = 0.0) -> void:
	factory_state_changed.emit(tube_ball_queue, _is_synthesizing, next_synthesis_type, progress)

func feed_next_ball_from_tube() -> void:
	if tube_ball_queue.is_empty():
		return

	if active_ball != null and is_instance_valid(active_ball):
		active_ball.queue_free()

	# La balle en bas du tube (indice 0) est extraite
	var ball_type_to_spawn: StringName = tube_ball_queue.pop_front()
	_emit_factory_state()
	
	var chosen_scene: PackedScene = ball_scene
	if ball_type_to_spawn == &"fizz" and fizzball_scene != null:
		chosen_scene = fizzball_scene
	elif ball_type_to_spawn == &"caramel" and caramel_ball_scene != null:
		chosen_scene = caramel_ball_scene
	
	if chosen_scene != null:
		active_ball = chosen_scene.instantiate() as Ball
		active_ball.position = tube_exit_position
		active_ball.ball_shattered.connect(_on_active_ball_shattered)
		# Impulsion diagonale vers la gauche et le flipper
		active_ball.linear_velocity = Vector2(-220.0, 180.0)
		ball_container.add_child(active_ball)

func _on_active_ball_shattered() -> void:
	active_ball = null
	if not tube_ball_queue.is_empty():
		feed_next_ball_from_tube()

func spawn_enemy_by_path(scene_path: String, spawn_x: float) -> void:
	var enemy_scn: PackedScene = load(scene_path) as PackedScene
	if enemy_scn != null:
		var enemy: Enemy = enemy_scn.instantiate() as Enemy
		enemy.position = Vector2(spawn_x, 80.0)
		enemy_container.add_child(enemy)

func spawn_enemy() -> void:
	var available_scenes: Array[PackedScene] = []
	if enemy_tomato_scene != null:
		# Tomate fréquente (poids 5)
		for i in range(5):
			available_scenes.append(enemy_tomato_scene)
	if enemy_ananas_scene != null:
		# Ananas intermédiaire (poids 3)
		for i in range(3):
			available_scenes.append(enemy_ananas_scene)
	if enemy_watermelon_scene != null:
		# Pastèque mini-tank (poids 2)
		for i in range(2):
			available_scenes.append(enemy_watermelon_scene)
			
	if available_scenes.is_empty():
		return
		
	var chosen_scene: PackedScene = available_scenes.pick_random()
	var enemy: Enemy = chosen_scene.instantiate() as Enemy
	var spawn_x: float = randf_range(90.0, 510.0)
	enemy.position = Vector2(spawn_x, 80.0)
	enemy_container.add_child(enemy)

func _on_danger_zone_body_entered(body: Node2D) -> void:
	if body is Ball:
		if not tube_ball_queue.is_empty():
			feed_next_ball_from_tube()
		else:
			if active_ball != null and is_instance_valid(active_ball):
				active_ball.queue_free()
				active_ball = null
	elif body is Enemy:
		var dmg: int = body.enemy_data.damage_on_escape if (body.enemy_data != null) else 1
		EventBus.enemy_escaped.emit(dmg)
		body.queue_free()
