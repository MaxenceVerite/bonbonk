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

# Point d'injection où la balle arrive dans l'arène (en haut de la rampe droite)
@export var tube_exit_position: Vector2 = Vector2(570, 1055)

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
var ball_pool: NodePool = NodePool.new()
var enemy_pool: NodePool = NodePool.new()

func _ready() -> void:
	add_child(ball_pool)
	add_child(enemy_pool)
	danger_zone.body_entered.connect(_on_danger_zone_body_entered)
	ball_tube.initialize(max_tube_capacity, synthesis_time_seconds)
	ball_tube.factory_state_changed.connect(func(q, s, n, p, pods): factory_state_changed.emit(q, s, n, p, pods))
	EventBus.flipper_parried.connect(_on_flipper_parried)

const _HitstopManagerScript = preload("res://scripts/core/hitstop_manager.gd")
const _ParryImpactEffectScript = preload("res://scripts/effects/parry_impact_effect.gd")

func _on_flipper_parried(_flipper: Node2D, _target: Node2D, context: HitContext) -> void:
	# Feedback haptique
	Input.vibrate_handheld(45)

	# Micro-gel temporel (Hitstop 45ms)
	_HitstopManagerScript.trigger(0.045, 0.04)

	# Effet d'impact vectoriel doré (Starburst + Onde de choc + Étincelles)
	var spawn_pos: Vector2 = context.impact_point if context != null else global_position
	var push_dir: Vector2 = context.impact_velocity.normalized() if (context != null and context.impact_velocity != Vector2.ZERO) else Vector2.UP
	_ParryImpactEffectScript.spawn(self, spawn_pos, push_dir)

func start_game() -> void:
	is_game_running = true
	set_bumper_slots_placement_mode(false)
	# Le joueur choisit quand lancer sa première bille en touchant un Pod !

func on_wave_cleared_stability() -> void:
	is_game_running = false

	# 1. Stopper immédiatement la fabrique de billes
	if ball_tube != null:
		ball_tube.pause_synthesis()

	# 2. Faire exploser toutes les billes actives restantes sur le terrain (enfants du container + active_balls)
	if ball_container != null:
		for child in ball_container.get_children():
			if child is Ball and is_instance_valid(child) and not child.is_queued_for_deletion():
				child.shatter()
	for b in active_balls:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			b.shatter()
	active_balls.clear()

	# 3. Remise au repos des batteurs
	if left_gate != null:
		left_gate.deactivate()
	if right_gate != null:
		right_gate.deactivate()

	restore_temporary_bumper_overrides()

func resume_for_next_wave() -> void:
	is_game_running = true

func reset_board() -> void:
	is_game_running = false
	_spawn_timer = 0.0
	restore_temporary_bumper_overrides()

	# Interrompt immédiatement toute animation de ruée de fin de partie
	Enemy.stop_game_over_horde_rush()
	
	# Remise à neuf des portes en bois
	if left_gate != null:
		left_gate.reset_gate()
	if right_gate != null:
		right_gate.reset_gate()

	# Nettoie les balles et ennemis en cours via recyclage
	for b in active_balls:
		if is_instance_valid(b):
			b.despawn()
	active_balls.clear()
		
	for child in enemy_container.get_children():
		if child.has_method(&"despawn"):
			child.despawn()
		else:
			child.queue_free()
		
	# Remplissage du tube avec les bonbons-balles du Deck actif
	ball_tube.reset(SaveManager.get_active_deck_balls())

## Cinématique de défaite : écroulement des portes et neutralisation des billes
func play_game_over_sequence() -> void:
	is_game_running = false

	# 1. Élimine les billes actives
	if ball_container != null:
		for child in ball_container.get_children():
			if child is Ball and is_instance_valid(child) and not child.is_queued_for_deletion():
				child.shatter()
	for b in active_balls:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			b.shatter()
	active_balls.clear()

	# 2. Stopper la fabrique
	if ball_tube != null:
		ball_tube.pause_synthesis()

	# 3. Écroulement physique des deux portes en bois
	if left_gate != null:
		left_gate.collapse_and_fall()
	if right_gate != null:
		right_gate.collapse_and_fall()

	# 4. Éclaboussures de débris au niveau des portes brisées
	var JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")
	JuiceSplatScript.spawn(self, Vector2(175, 1195), Color(0.35, 0.18, 0.08, 1.0), Color(0.5, 0.28, 0.12, 1.0), Color(1.0, 1.0, 1.0, 1.0), 16)
	JuiceSplatScript.spawn(self, Vector2(440, 1195), Color(0.35, 0.18, 0.08, 1.0), Color(0.5, 0.28, 0.12, 1.0), Color(1.0, 1.0, 1.0, 1.0), 16)

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

const BroccoliBumperScene: PackedScene = preload("res://scenes/board/broccoli_bumper.tscn")

func restore_temporary_bumper_overrides() -> void:
	if bumper_slot_container != null:
		for slot in bumper_slot_container.get_children():
			if slot is BumperSlot and slot.has_temporary_override():
				slot.restore_from_temporary_override()

func get_slots_available_for_broccoli() -> Array[BumperSlot]:
	var available: Array[BumperSlot] = []
	if bumper_slot_container != null:
		for slot in bumper_slot_container.get_children():
			if slot is BumperSlot:
				if not slot.has_temporary_override():
					available.append(slot)
	return available

func spawn_broccoli_bumpers(count: int = 3, on_broken_cb: Callable = Callable()) -> Array[BroccoliBumper]:
	var available: Array[BumperSlot] = get_slots_available_for_broccoli()
	available.shuffle()
	var spawned: Array[BroccoliBumper] = []
	var to_spawn: int = mini(count, available.size())
	for i in range(to_spawn):
		var slot: BumperSlot = available[i]
		var broc: BroccoliBumper = BroccoliBumperScene.instantiate() as BroccoliBumper
		broc.assigned_slot = slot
		if on_broken_cb.is_valid():
			broc.broccoli_broken.connect(on_broken_cb)
		slot.override_with_temporary_bumper(broc)
		spawned.append(broc)
	return spawned

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
		elif b.position.y > 1350.0 or b.position.x > 660.0 or b.position.x < -40.0:
			b.despawn()
			active_balls.remove_at(i)

func get_ball_scene_for_type(_ball_type: StringName) -> PackedScene:
	if ball_scene != null:
		return ball_scene
	return load("res://scenes/ball/ball.tscn") as PackedScene

func launch_ball_from_pod(pod_index: int) -> bool:
	if not is_game_running:
		return false
	var b_type: StringName = ball_tube.launch_pod(pod_index)
	if b_type.is_empty():
		return false
	_spawn_active_ball(b_type, pod_index)
	return true

func feed_next_ball_from_tube() -> void:
	if not ball_tube.has_balls():
		return
	var b_type: StringName = ball_tube.pop_next_ball()
	if not b_type.is_empty():
		_spawn_active_ball(b_type, 0)

func _spawn_active_ball(ball_type: StringName, _pod_index: int = 0) -> Ball:
	var chosen_scene: PackedScene = get_ball_scene_for_type(ball_type)
	if chosen_scene == null:
		return null
	var b: Ball = ball_pool.acquire(chosen_scene) as Ball
	b.pool_source = ball_pool
	b.position = tube_exit_position
	if not b.ball_shattered.is_connected(_on_active_ball_shattered):
		b.ball_shattered.connect(_on_active_ball_shattered)
	if not b.split_requested.is_connected(_on_ball_split_requested):
		b.split_requested.connect(_on_ball_split_requested)
	b.configure_for_type(ball_type)
	# Glisse naturelle douce le long de la rampe droite vers le batteur
	b.linear_velocity = Vector2(-25.0, 40.0)
	if b.get_parent() != ball_container:
		ball_container.add_child(b)
	active_balls.append(b)
	return b

func _on_active_ball_shattered(b: Ball) -> void:
	active_balls.erase(b)

func _on_ball_split_requested(sub_types: Array[StringName], spawn_pos: Vector2, dirs: Array[Vector2], speed: float) -> void:
	var chosen_scene: PackedScene = get_ball_scene_for_type(&"ball")
	for i in range(mini(sub_types.size(), dirs.size())):
		if chosen_scene != null:
			var sub_ball: Ball = ball_pool.acquire(chosen_scene) as Ball
			sub_ball.pool_source = ball_pool
			sub_ball.position = spawn_pos + dirs[i] * 22.0
			sub_ball.linear_velocity = dirs[i] * speed
			sub_ball.max_durability = 1
			sub_ball.current_durability = 1
			if not sub_ball.ball_shattered.is_connected(_on_active_ball_shattered):
				sub_ball.ball_shattered.connect(_on_active_ball_shattered)
			sub_ball.configure_for_type(sub_types[i])
			if sub_ball.get_parent() != ball_container:
				ball_container.add_child(sub_ball)
			active_balls.append(sub_ball)

func _apply_card_stats_to_ball(ball: Ball, ball_type: StringName) -> void:
	if ball != null:
		ball.configure_for_type(ball_type)

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
		if enemy != null:
			if scene_path.contains("boss"):
				enemy.position = Vector2(spawn_x, -140.0)
			else:
				enemy.position = Vector2(spawn_x, 80.0)
			if enemy_container != null:
				enemy_container.add_child(enemy)

func spawn_enemy() -> void:
	var pool: Array[PackedScene] = _get_default_enemy_pool()
	if pool.is_empty():
		return
		
	var chosen_scene: PackedScene = pool.pick_random()
	var enemy: Enemy = chosen_scene.instantiate() as Enemy
	if enemy != null:
		var spawn_x: float = randf_range(90.0, 510.0)
		enemy.position = Vector2(spawn_x, 80.0)
		if enemy_container != null:
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
	_handle_danger_zone_body.call_deferred(body)

func _handle_danger_zone_body(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body is Ball:
		active_balls.erase(body as Ball)
		if body.has_method(&"despawn"):
			body.despawn()
		else:
			body.queue_free()
	elif body is Enemy:
		var dmg: int = body.enemy_data.damage_on_escape if (body.enemy_data != null) else 1
		EventBus.enemy_escaped.emit(dmg)
		if body.has_method(&"despawn"):
			body.despawn()
		else:
			body.queue_free()
