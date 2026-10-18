class_name Ball
extends RigidBody2D

## Contrôleur universel de bille de flipper modulaire.
## Fonctionne avec un système de MOTS-CLÉS :
## - native_keywords : mots-clés de base du bonbon (ex: Collant pour le Caramel, Électrique pour la Fizzball)
## - temporary_keywords : mots-clés temporaires acquis en jeu (améliorations, boosters de manche)
## - skin / couleurs personnalisables par ressource ou code

signal durability_changed(current: int, max_val: int)
signal ball_shattered(ball: Ball)
signal split_requested(ball_types: Array[StringName], spawn_pos: Vector2, directions: Array[Vector2], speed: float)

@export var ball_id: StringName = &"fizz"
@export var impact_damage: int = 1
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
var _cached_keywords: Array[BallKeyword] = []

# Assistance à la visée (Magnétisme subtil vers les ennemis)
@export_group("Aim Assist")
@export var aim_assist_enabled: bool = true
@export var aim_assist_force: float = 450.0
@export var aim_assist_max_distance: float = 400.0
@export var aim_assist_max_angle_deg: float = 28.0

var current_durability: int = 3
var _stuck_timer: float = 0.0
var _is_shattering: bool = false
var _aim_assist_scan_timer: float = 0.0
var _current_aim_target: Enemy = null

@onready var visual_ball: Polygon2D = $VisualBall
@onready var core_glow: Polygon2D = $VisualBall/CoreGlow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Polygon2D = $Shadow
@onready var trail: Line2D = $BallTrail

# Registre statique O(1) de toutes les billes actives dans l'arène
static var active_balls: Array[Ball] = []

func _enter_tree() -> void:
	if not active_balls.has(self):
		active_balls.append(self)

func _exit_tree() -> void:
	active_balls.erase(self)

func _ready() -> void:
	current_durability = max_durability
	durability_changed.emit(current_durability, max_durability)
	body_entered.connect(_on_body_entered)
	apply_skin(ball_color, core_color, trail_color)
	_refresh_cached_keywords()

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
		_refresh_cached_keywords()
		print("Ball [%s]: Mot-clé temporaire ajouté -> %s" % [ball_id, keyword.display_name])

func remove_temporary_keyword(keyword_id: StringName) -> void:
	for i in range(temporary_keywords.size() - 1, -1, -1):
		if temporary_keywords[i].id == keyword_id:
			temporary_keywords.remove_at(i)
	_refresh_cached_keywords()

func _refresh_cached_keywords() -> void:
	_cached_keywords.clear()
	for kw in native_keywords:
		if kw != null:
			_cached_keywords.append(kw)
	for kw in temporary_keywords:
		if kw != null:
			_cached_keywords.append(kw)

func has_keyword(keyword_id: StringName) -> bool:
	for kw in _cached_keywords:
		if kw != null and kw.id == keyword_id:
			return true
	return false

func get_all_keywords() -> Array[BallKeyword]:
	return _cached_keywords

func _on_body_entered(body: Node) -> void:
	if body is CandyBumper:
		var bumper: CandyBumper = body as CandyBumper
		bumper.on_hit_by_ball(self, global_position)
		for kw in get_all_keywords():
			kw.on_hit_bumper(self, bumper)
	elif body is WoodenGateFlipper:
		for kw in get_all_keywords():
			kw.on_hit_flipper(self, body)
	elif body is Enemy:
		var enemy: Enemy = body as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
			var durability_penalty: int = enemy.enemy_data.spiky_ball_durability_loss if (enemy.enemy_data and enemy.enemy_data.is_spiky) else 1
			hit_enemy_with_target(enemy, durability_penalty)
			var ctx: HitContext = HitContext.create(self, enemy, impact_damage, global_position, linear_velocity, HitContext.DamageType.PHYSICAL)
			EventBus.ball_hit_enemy.emit(ctx)
			enemy.take_hit_with_context(ctx)

## Configure la bille de manière universelle selon son type et son niveau (Data-Driven)
func configure_for_type(p_ball_type: StringName, lvl: int = 1) -> void:
	ball_id = p_ball_type

	# 1. Skin & Palette
	var pal: Dictionary = CardCatalog.get_candy_palette(p_ball_type)
	apply_skin(pal.color, pal.core, pal.ring)

	# 2. Mots-clés natifs selon le type (remplace le besoin de sous-classes)
	native_keywords.clear()
	match p_ball_type:
		&"fizz":
			native_keywords.append(KeywordElectric.new())
		&"caramel":
			native_keywords.append(KeywordSticky.new())
		&"mentox":
			native_keywords.append(KeywordFreeze.new())
		&"jawbreaker":
			native_keywords.append(KeywordJawbreaker.new())
			mass = 1.8
			max_durability = 1
			current_durability = 1
			if visual_ball != null:
				visual_ball.scale = Vector2(1.25, 1.25)
		_:
			mass = 1.2

	_refresh_cached_keywords()

	# 3. Statistiques de carte
	var card_state: Dictionary = SaveManager.get_card_state(p_ball_type)
	var def: CandyCardData = card_state.get("def", null) if not card_state.is_empty() else null
	if def == null:
		var defs: Dictionary = CardCatalog.get_default_definitions()
		def = defs.get(p_ball_type, null)
	var card_lvl: int = card_state.get("level", lvl) if not card_state.is_empty() else lvl
	if def != null:
		configure_from_card(def, card_lvl)

## Configure la bille et ses mots-clés selon la carte et son niveau
func configure_from_card(card_def: CandyCardData, lvl: int) -> void:
	if card_def == null:
		return
	impact_damage = card_def.get_damage_for_level(lvl)
	aim_assist_force = card_def.get_magnetism_for_level(lvl)
	if physics_material_override != null:
		physics_material_override.bounce = clampf(card_def.get_bounce_for_level(lvl) * 0.55, 0.2, 0.98)

	for kw in get_all_keywords():
		if kw != null:
			kw.apply_card_scaling(card_def, lvl)


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
			var nudge_x: float = 160.0 if position.x < 310.0 else -160.0
			var nudge_y: float = -140.0 if position.y > 1110.0 else 100.0
			apply_central_impulse(Vector2(nudge_x, nudge_y))
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0

	# Assistance à la visée magnétique (courbure douce vers les ennemis en ascension)
	if aim_assist_enabled:
		_apply_aim_assist(delta)

	# Mots-clés continus
	for kw in get_all_keywords():
		kw.on_physics_tick(self, delta)

## Assistance à la visée par magnétisme centripète
func _apply_aim_assist(delta: float) -> void:
	# Ne s'active que si la bille monte de façon dynamique
	if linear_velocity.y >= -120.0:
		_current_aim_target = null
		_aim_assist_scan_timer = 0.0
		return

	# Recherche de cible périodique (~16 Hz) pour éviter toute allocation frame par frame
	_aim_assist_scan_timer -= delta
	if _aim_assist_scan_timer <= 0.0:
		_aim_assist_scan_timer = 0.06
		_find_best_aim_target()

	if _current_aim_target == null:
		return

	if not is_instance_valid(_current_aim_target) or _current_aim_target.is_dying():
		_current_aim_target = null
		return

	var to_enemy: Vector2 = _current_aim_target.global_position - global_position
	# Doit rester strictement au-dessus de la bille
	if to_enemy.y >= 0.0:
		_current_aim_target = null
		return

	var dist: float = to_enemy.length()
	if dist > aim_assist_max_distance or dist < 20.0:
		_current_aim_target = null
		return

	var vel_len: float = linear_velocity.length()
	if vel_len < 100.0:
		return

	var vel_dir: Vector2 = linear_velocity / vel_len
	var to_dir: Vector2 = to_enemy / dist
	var angle_diff: float = absf(vel_dir.angle_to(to_dir))
	var max_angle_rad: float = deg_to_rad(aim_assist_max_angle_deg)

	if angle_diff > max_angle_rad:
		_current_aim_target = null
		return

	# Composante latérale perpendiculaire (effet centripète pur : incurve sans altérer la vitesse scalaire)
	var perp: Vector2 = Vector2(-vel_dir.y, vel_dir.x)
	var lateral_sign: float = signf(perp.dot(to_dir))
	var alignment_factor: float = 1.0 - (angle_diff / max_angle_rad)
	var distance_factor: float = 1.0 - (dist / aim_assist_max_distance)
	var steer_weight: float = clampf(alignment_factor * 0.7 + distance_factor * 0.3, 0.2, 1.0)

	var lateral_force: Vector2 = perp * lateral_sign * (aim_assist_force * steer_weight)
	apply_central_force(lateral_force)

func _find_best_aim_target() -> void:
	var enemies: Array[Enemy] = Enemy.get_active_enemies()
	if enemies.is_empty():
		_current_aim_target = null
		return

	var vel_len: float = linear_velocity.length()
	if vel_len < 100.0:
		_current_aim_target = null
		return

	var vel_dir: Vector2 = linear_velocity / vel_len
	var max_angle_rad: float = deg_to_rad(aim_assist_max_angle_deg)
	var best_score: float = -1.0
	var chosen: Enemy = null

	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dying():
			continue

		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.y >= 0.0:
			continue

		var dist: float = to_enemy.length()
		if dist > aim_assist_max_distance or dist < 20.0:
			continue

		var to_dir: Vector2 = to_enemy / dist
		var angle_diff: float = absf(vel_dir.angle_to(to_dir))
		if angle_diff <= max_angle_rad:
			var alignment_factor: float = 1.0 - (angle_diff / max_angle_rad)
			var distance_factor: float = 1.0 - (dist / aim_assist_max_distance)
			var score: float = alignment_factor * 0.7 + distance_factor * 0.3
			if score > best_score:
				best_score = score
				chosen = enemy

	_current_aim_target = chosen

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
	ball_shattered.emit(self)
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
	tween.chain().tween_callback(despawn)

## Applique une répulsion franche par un bumper via le solver physique
func apply_bumper_bounce(push_direction: Vector2, bounce_force: float) -> void:
	linear_velocity = push_direction * bounce_force
	apply_central_impulse(push_direction * (bounce_force * 0.2))

var pool_source: NodePool = null

func despawn() -> void:
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", true)
	if pool_source != null:
		pool_source.release(self)
	else:
		queue_free()

func on_pool_acquire() -> void:
	_is_shattering = false
	freeze = false
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", false)
	if visual_ball != null:
		visual_ball.scale = Vector2.ONE
		visual_ball.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if trail != null:
		trail.visible = true
		trail.clear_points()
	if shadow != null:
		shadow.visible = true
	_stuck_timer = 0.0
	_aim_assist_scan_timer = 0.0
	_current_aim_target = null
	current_durability = max_durability
	durability_changed.emit(current_durability, max_durability)

func reset_position(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	current_durability = max_durability
