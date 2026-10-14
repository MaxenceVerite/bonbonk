class_name Ball
extends RigidBody2D

## Contrôleur universel de bille de flipper modulaire.
## Fonctionne avec un système de MOTS-CLÉS :
## - native_keywords : mots-clés de base du bonbon (ex: Collant pour le Caramel, Électrique pour la Fizzball)
## - temporary_keywords : mots-clés temporaires acquis en jeu (améliorations, boosters de manche)
## - skin / couleurs personnalisables par ressource ou code

signal durability_changed(current: int, max_val: int)
signal ball_shattered

@export var ball_id: StringName = &"standard"
@export var max_durability: int = 3
@export var max_linear_velocity: float = 2400.0
@export var min_vertical_speed: float = 25.0

# Couleurs du skin bonbon
@export var ball_color: Color = Color(1.0, 0.28, 0.45, 1.0)
@export var core_color: Color = Color(1.0, 0.55, 0.68, 1.0)
@export var trail_color: Color = Color(1.0, 0.35, 0.52, 0.45)

# Système de mots-clés modulaires
@export var native_keywords: Array[BallKeyword] = []
var temporary_keywords: Array[BallKeyword] = []

var current_durability: int = 3
var _stuck_timer: float = 0.0
var _is_shattering: bool = false

@onready var visual_ball: Polygon2D = $VisualBall
@onready var core_glow: Polygon2D = $VisualBall/CoreGlow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Polygon2D = $Shadow
@onready var trail: Line2D = $BallTrail

func _ready() -> void:
	current_durability = max_durability
	durability_changed.emit(current_durability, max_durability)
	body_entered.connect(_on_body_entered)
	apply_skin(ball_color, core_color, trail_color)

func apply_skin(p_ball_color: Color, p_core_color: Color, p_trail_color: Color) -> void:
	ball_color = p_ball_color
	core_color = p_core_color
	trail_color = p_trail_color
	
	if visual_ball != null:
		visual_ball.color = ball_color
	if core_glow != null:
		core_glow.color = core_color
	if trail != null:
		trail.default_color = trail_color

func add_temporary_keyword(keyword: BallKeyword) -> void:
	if keyword != null and not has_keyword(keyword.id):
		temporary_keywords.append(keyword)
		print("Ball [%s]: Mot-clé temporaire ajouté -> %s" % [ball_id, keyword.display_name])

func remove_temporary_keyword(keyword_id: StringName) -> void:
	for i in range(temporary_keywords.size() - 1, -1, -1):
		if temporary_keywords[i].id == keyword_id:
			temporary_keywords.remove_at(i)

func has_keyword(keyword_id: StringName) -> bool:
	for kw in native_keywords:
		if kw != null and kw.id == keyword_id:
			return true
	for kw in temporary_keywords:
		if kw != null and kw.id == keyword_id:
			return true
	return false

func get_all_keywords() -> Array[BallKeyword]:
	var result: Array[BallKeyword] = []
	for kw in native_keywords:
		if kw != null:
			result.append(kw)
	for kw in temporary_keywords:
		if kw != null:
			result.append(kw)
	return result

func _on_body_entered(body: Node) -> void:
	if body is CandyBumper:
		var bumper: CandyBumper = body as CandyBumper
		bumper.on_hit_by_ball(self, global_position)
		for kw in get_all_keywords():
			kw.on_hit_bumper(self, bumper)
	elif body is Enemy:
		var enemy: Enemy = body as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
			var durability_penalty: int = enemy.enemy_data.spiky_ball_durability_loss if (enemy.enemy_data and enemy.enemy_data.is_spiky) else 1
			hit_enemy_with_target(enemy, durability_penalty)
			enemy.take_hit(1)

func _physics_process(delta: float) -> void:
	if _is_shattering or freeze:
		return
		
	# Limite de vitesse maximale
	if linear_velocity.length() > max_linear_velocity:
		linear_velocity = linear_velocity.normalized() * max_linear_velocity
	
	# Anti-blocage
	if linear_velocity.length() < 35.0:
		_stuck_timer += delta
		if _stuck_timer > 0.35:
			var nudge_x: float = 160.0 if global_position.x < 360.0 else -160.0
			var nudge_y: float = -140.0 if global_position.y > 1110.0 else 100.0
			apply_central_impulse(Vector2(nudge_x, nudge_y))
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0

	# Guidage doux passif en zone basse
	if global_position.y > 900.0 and global_position.y < 1140.0:
		var dir_to_center: float = signf(310.0 - global_position.x)
		apply_central_force(Vector2(dir_to_center * 190.0, 0.0))

	# Mots-clés continus
	for kw in get_all_keywords():
		kw.on_physics_tick(self, delta)

## Appelé lors d'un choc avec un ennemi spécifique
func hit_enemy_with_target(enemy: Enemy, durability_loss: int = 1) -> void:
	# 1. Exécution de la chaîne de mots-clés
	var keywords_list: Array[BallKeyword] = get_all_keywords()
	for kw in keywords_list:
		kw.on_hit_enemy(self, enemy)
		
	# 2. Gestion de la durabilité
	hit_enemy(durability_loss)

## Décrémente la durabilité lors d'un choc
func hit_enemy(durability_loss: int = 1) -> void:
	if _is_shattering:
		return
		
	current_durability = maxi(0, current_durability - durability_loss)
	durability_changed.emit(current_durability, max_durability)
	
	# Flash blanc de dégât et micro-squash
	var tween: Tween = create_tween()
	visual_ball.modulate = Color(2.5, 2.5, 2.5, 1.0)
	tween.tween_property(visual_ball, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	
	if current_durability == 2:
		core_glow.color = Color(1.0, 0.7, 0.4, 1.0)
	elif current_durability == 1:
		core_glow.color = Color(0.9, 0.2, 0.2, 1.0)
		
	if current_durability <= 0:
		shatter()

## Explosion et destruction de la bille
func shatter() -> void:
	if _is_shattering:
		return
	_is_shattering = true
	ball_shattered.emit()
	collision_shape.set_deferred(&"disabled", true)
	freeze = true
	
	if trail != null:
		trail.visible = false
	if shadow != null:
		shadow.visible = false
		
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_ball, "scale", Vector2(2.2, 2.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_ball, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)

func reset_position(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	current_durability = max_durability
