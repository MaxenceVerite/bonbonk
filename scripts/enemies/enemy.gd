class_name Enemy
extends CharacterBody2D

## Ennemi pouvant marcher, rouler ou sautiller en diagonale.
## Supporte les caractéristiques :
## - Tomate : rapide, 1 PV, 1 dégât, léger (expulsé en cloche par la bille)
## - Ananas : sauts en diagonale, 10 PV, 3 dégâts, piquant (abîme la bille et blesse les ennemis heurtés)
## - Pastèque : roulement continu, 30 PV, 20 dégâts, insensibilité au batteur, accélération passive si non touchée

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")
const DiveTelegraphScript = preload("res://scripts/effects/dive_telegraph_visual.gd")
const EnemyHealthBarScript = preload("res://scripts/components/enemy_health_bar.gd")
const EnemyExpulsionScript = preload("res://scripts/components/enemy_expulsion_component.gd")

@export var enemy_data: EnemyData
@export var target_door_y: float = 1140.0

@onready var visual_container: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var status_component: StatusEffectComponent = null
var telegraph_visual: DiveTelegraphVisual = null
var dive_component: SuicideDiveComponent = null
var visual_overlay: StatusVisualOverlay = null
var is_boss: bool = false
var health_bar: Node2D = null
var expulsion_component: Node = null

# Registre statique O(1) de tous les ennemis vivants sur le terrain
static var active_enemies: Array[Enemy] = []

static func get_active_enemies() -> Array[Enemy]:
	return active_enemies

static func get_nearest(from_pos: Vector2, max_distance: float = INF) -> Enemy:
	var nearest: Enemy = null
	var min_dist_sq: float = max_distance * max_distance
	for e in active_enemies:
		if e != null and is_instance_valid(e) and not e.is_dying():
			var d_sq: float = from_pos.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = e
	return nearest

static func get_in_radius(from_pos: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var r_sq: float = radius * radius
	for e in active_enemies:
		if e != null and is_instance_valid(e) and not e.is_dying():
			if from_pos.distance_squared_to(e.global_position) <= r_sq:
				result.append(e)
	return result

func _enter_tree() -> void:
	if not active_enemies.has(self):
		active_enemies.append(self)

func _exit_tree() -> void:
	active_enemies.erase(self)

var _time_alive: float = 0.0
var _is_dying: bool = false
var _is_game_over_charging: bool = false
var _target_door_x: float = 310.0 # Centre de l'ouverture entre les deux batteurs

static func trigger_game_over_horde_rush() -> void:
	for e in active_enemies:
		if e != null and is_instance_valid(e) and not e.is_dying():
			e.start_game_over_rush()

static func stop_game_over_horde_rush() -> void:
	for e in active_enemies:
		if e != null and is_instance_valid(e):
			e._is_game_over_charging = false
			e.modulate.a = 1.0
			e.scale = Vector2.ONE
			if e.collision_shape != null:
				e.collision_shape.set_deferred(&"disabled", false)

func start_game_over_rush() -> void:
	_is_game_over_charging = true
	_knockback_velocity = Vector2.ZERO
	_is_projected_by_gate = false
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", true)

# Gestion du knockback (projection physique)
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_friction: float = 850.0
var _is_squashing_from_hit: bool = false
var _is_projected_by_gate: bool = false
var _projection_time: float = 0.0

# Contexte du dernier coup reçu
var _last_hit_source: Node = null
var _last_hit_context: HitContext = null
var _last_hit_direction: Vector2 = Vector2.UP
var _last_impact_velocity: Vector2 = Vector2.ZERO
var _last_hit_timestamp: float = -999.0

# Expulsion en cloche hors de l'arène (déléguée au composant d'expulsion)
var _is_expelled: bool:
	get:
		return expulsion_component != null and expulsion_component.is_active()
	set(_val):
		pass

# Trait Pastèque : Accélération progressive si pas de dégât
var _time_since_last_damage: float = 0.0
var _current_move_speed: float = 50.0

# Stratégie de déplacement modulaire (Strategy Pattern)
var movement_strategy: EnemyMovementStrategy = null
# Préférence organique de contournement d'obstacles (-1.0 = gauche, 1.0 = droite)
var bypass_bias: float = 0.0

func attach_caramel_ball(caramel_ball: Node2D, speed_multiplier: float = 0.35) -> void:
	if _is_dying or _is_expelled:
		return
	if status_component != null:
		status_component.attach_caramel_ball(caramel_ball, speed_multiplier)

func detach_caramel_ball() -> void:
	if status_component != null:
		status_component.detach_caramel_ball()

func apply_electric_zap(damage: int = 1, stun_duration: float = 2.0) -> void:
	if _is_dying or _is_expelled:
		return
	_knockback_velocity = Vector2.ZERO
	if status_component != null:
		status_component.apply_electric_zap(stun_duration)
	take_hit(damage, null, Vector2.ZERO)

func apply_freeze(damage: int = 1, freeze_duration: float = 2.0) -> void:
	if _is_dying or _is_expelled:
		return
	_knockback_velocity = Vector2.ZERO
	if status_component != null:
		status_component.apply_freeze(freeze_duration)
	take_hit(damage, null, Vector2.ZERO)

func apply_burn(duration: float = 3.0, damage_per_tick: int = 1, tick_interval: float = 0.5) -> void:
	if _is_dying or _is_expelled:
		return
	if status_component != null:
		status_component.apply_burn(duration, damage_per_tick, tick_interval)

func _ready() -> void:
	add_to_group(&"enemies")
	if not active_enemies.has(self):
		active_enemies.append(self)

	status_component = StatusEffectComponent.new()
	add_child(status_component)
	status_component.setup(self, visual_container)

	visual_overlay = StatusVisualOverlay.new()
	visual_container.add_child(visual_overlay)
	visual_overlay.setup(self, sprite)
	status_component.attach_visual_overlay(visual_overlay)

	telegraph_visual = DiveTelegraphScript.new()
	add_child(telegraph_visual)
	telegraph_visual.setup(enemy_data.can_be_parried if enemy_data != null else true)

	dive_component = SuicideDiveComponent.new()
	add_child(dive_component)
	dive_component.setup(self, visual_container, telegraph_visual)

	if not is_boss:
		health_bar = EnemyHealthBarScript.new()
		add_child(health_bar)
		health_bar.setup(self, health_component, sprite, collision_shape)

	expulsion_component = EnemyExpulsionScript.new()
	add_child(expulsion_component)
	expulsion_component.setup(self, visual_container, collision_shape, enemy_data, despawn)

	if enemy_data != null:
		health_component.set_max_health(enemy_data.max_health)
		_current_move_speed = enemy_data.get_speed_from_tier()
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_time_alive = randf_range(0.0, 5.0)
	bypass_bias = -1.0 if randf() < 0.5 else 1.0
	_init_movement_strategy()

func _on_health_changed(_cur: int, _max_h: int) -> void:
	pass

func _init_movement_strategy() -> void:
	var pattern: int = enemy_data.move_pattern if enemy_data != null else 0
	match pattern:
		EnemyData.MovePattern.ROLL_STRAIGHT:
			movement_strategy = RollStraightStrategy.new()
		EnemyData.MovePattern.DIAGONAL_HOPPER:
			movement_strategy = DiagonalHopStrategy.new()
		_:
			movement_strategy = WalkStraightStrategy.new()

func _compute_bumper_avoidance(_current_dir: Vector2, speed: float) -> Vector2:
	return ObstacleAvoidance.compute_bumper_avoidance(global_position, bypass_bias, speed, CandyBumper.active_bumpers)

func _physics_process(delta: float) -> void:
	# Trajectoire balistique en cloche hors de l'arène (gérée par le composant)
	if expulsion_component != null and expulsion_component.update(delta):
		return

	if _is_dying or is_boss:
		return

	# Ruée triomphale de la horde lors du Game Over
	if _is_game_over_charging:
		_time_alive += delta
		var rush_dir: Vector2 = (Vector2(308.0, 1340.0) - global_position).normalized()
		global_position += rush_dir * 320.0 * delta
		if visual_container != null:
			visual_container.rotation = sin(_time_alive * 16.0) * 0.15
		if global_position.y > 1240.0:
			var fade: float = clampf((1320.0 - global_position.y) / 80.0, 0.0, 1.0)
			modulate.a = fade
			scale = Vector2.ONE * (0.4 + 0.6 * fade)
			if global_position.y > 1310.0 or fade <= 0.05:
				despawn()
		return

	_time_alive += delta
	_time_since_last_damage += delta

	# Mise à jour des altérations d'état via le composant
	if status_component != null:
		status_component.update_status(delta)

	# 1. Calcul du déplacement selon l'état d'action (Normal, Windup télégraphié ou Dive)
	var effective_speed: float = 0.0
	var walk_velocity: Vector2 = Vector2.ZERO
	var is_immobile: bool = status_component.is_immobilized() if status_component != null else false

	if dive_component != null and dive_component.is_active():
		walk_velocity = dive_component.update_dive(delta, enemy_data)

	elif not is_immobile:
		# Déplacement normal : vérifier si on approche de la porte pour déclencher la charge
		if dive_component != null:
			dive_component.check_for_dive(enemy_data)

		var base_speed: float = enemy_data.get_speed_from_tier() if enemy_data else 80.0

		# Trait Pastèque : Accélération progressive après 3s sans dégât
		if enemy_data != null and enemy_data.can_accelerate_when_idle:
			if _time_since_last_damage > 3.0:
				_current_move_speed = move_toward(_current_move_speed, 75.0, 10.0 * delta)
			else:
				_current_move_speed = base_speed
		else:
			_current_move_speed = base_speed

		var slow_factor: float = status_component.get_speed_multiplier() if status_component != null else 1.0
		effective_speed = _current_move_speed * slow_factor
		if movement_strategy != null:
			walk_velocity = movement_strategy.compute_velocity(self, delta, effective_speed, Vector2(_target_door_x, target_door_y))
			var avoidance: Vector2 = _compute_bumper_avoidance(walk_velocity, effective_speed)
			if avoidance != Vector2.ZERO:
				walk_velocity = (walk_velocity + avoidance).normalized() * effective_speed

	# 2. Gestion knockback & Projection par le flipper
	if _knockback_velocity.length() > 5.0:
		velocity = _knockback_velocity
		var friction: float = 350.0 if _is_projected_by_gate else _knockback_friction
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, friction * delta)

		if _is_projected_by_gate:
			_projection_time += delta
			# Si l'ennemi ralentit après un long vol sans collision, il reprend sa marche normale
			if _knockback_velocity.length() < 50.0 or _projection_time > 2.0:
				_is_projected_by_gate = false
	else:
		_knockback_velocity = Vector2.ZERO
		velocity = walk_velocity
		_is_projected_by_gate = false

	# 3. Collision
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		var collider: Object = collision.get_collider()

		# CAS SPÉCIFIQUE : L'ennemi projeté par le flipper heurte un obstacle (mur ou ennemi)
		if _is_projected_by_gate:
			_handle_projected_collision(collision, collider)
			return

		# Collision avec la bille : résolution gérée par le RigidBody2D de la Ball (_on_body_entered)
		if collider is Ball:
			pass

		# Collision avec un Bumper : glissement fluide le long du cercle ou rebond si projeté
		elif collider is CandyBumper:
			var collision_normal: Vector2 = collision.get_normal()
			if _is_projected_by_gate:
				_knockback_velocity = _knockback_velocity.bounce(collision_normal) * 0.75
				var bumper_obj: CandyBumper = collider as CandyBumper
				if bumper_obj != null:
					bumper_obj.play_jiggle()
			else:
				# Si l'ennemi percute le sommet du bumper (normale vers le haut y < -0.3)
				# On injecte une impulsion tangentielle latérale pour le faire glisser sur le flanc
				var slide_vel: Vector2 = velocity.slide(collision_normal)
				if collision_normal.y < -0.2:
					var push_side: float = 1.0 if (collision_normal.x > 0.0 or (collision_normal.x == 0.0 and bypass_bias > 0.0)) else -1.0
					if global_position.x < 130.0:
						push_side = 1.0
					elif global_position.x > 470.0:
						push_side = -1.0
					var tangent: Vector2 = Vector2(push_side * absf(collision_normal.y), absf(collision_normal.x)).normalized()
					slide_vel = tangent * maxi(80, int(velocity.length()))
				move_and_collide(slide_vel * delta)

		# Collision avec la porte / batteur en chocolat
		elif collider is WoodenGateFlipper:
			var gate: WoodenGateFlipper = collider as WoodenGateFlipper
			var impact_point: Vector2 = collision.get_position()
			var collision_normal: Vector2 = collision.get_normal()
			var parried: bool = gate.try_parry_enemy(self, impact_point, collision_normal)
			if not parried:
				# Contre raté (porte statique, maintenue levée, ou ennemie lourde type Pastèque) :
				# L'ennemi s'écrase sur la porte, éclate en jus et inflige ses dégâts au joueur
				var dmg: int = enemy_data.damage_on_escape if (enemy_data != null) else 1
				EventBus.enemy_escaped.emit(dmg)
				_explode_at_gate(collision_normal)

		# Collision avec un autre ennemi en marche normale
		elif collider is Enemy:
			var other_enemy: Enemy = collider as Enemy
			if _knockback_velocity.length() > 120.0:
				var push_dir: Vector2 = (other_enemy.global_position - global_position).normalized()
				if enemy_data != null and enemy_data.is_spiky:
					other_enemy.take_hit(2, self, _knockback_velocity)
				other_enemy.apply_knockback(push_dir * (_knockback_velocity.length() * 0.75), 0.0)
				_knockback_velocity *= 0.65

	# 4. Juice procédural fluide (pas de vibration violente)
	if not _is_squashing_from_hit and (enemy_data == null or enemy_data.move_pattern != EnemyData.MovePattern.ROLL_STRAIGHT):
		_apply_walk_juice()

func _handle_projected_collision(collision: KinematicCollision2D, collider: Object) -> void:
	# 1. Dégâts subis par l'ennemi projeté : la moitié de sa vie max (1 minimum)
	var half_health: int = maxi(1, int(ceil(float(health_component.max_health) / 2.0)))

	# 2. Si la collision est avec un autre ennemi, lui inflige de légers dégâts selon son type
	if collider is Enemy:
		var other_enemy: Enemy = collider as Enemy
		if not other_enemy.is_dying():
			var dmg_to_other: int = enemy_data.collision_damage_when_projected if enemy_data else 1
			other_enemy.take_hit(dmg_to_other, self, velocity)
			var push_dir: Vector2 = (other_enemy.global_position - global_position).normalized()
			other_enemy.apply_knockback(push_dir * 380.0, 0.0)

	# 3. L'ennemi projeté subit ses dégâts
	take_hit(half_health, collider as Node, velocity)

	# 4. Éclaboussure de jus au point d'impact
	if enemy_data != null:
		JuiceSplatScript.spawn(
			get_parent(),
			collision.get_position(),
			enemy_data.juice_primary_color,
			enemy_data.juice_secondary_color,
			enemy_data.juice_accent_color,
			8
		)

	# 5. Reprise immédiate du déplacement normal sans délai
	_is_projected_by_gate = false
	_knockback_velocity = Vector2.ZERO


func _explode_at_gate(normal: Vector2) -> void:
	if _is_dying or _is_expelled:
		return
	_is_dying = true
	collision_shape.set_deferred(&"disabled", true)
	if has_node("Shadow"):
		$Shadow.visible = false

	if enemy_data != null:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			enemy_data.juice_primary_color,
			enemy_data.juice_secondary_color,
			enemy_data.juice_accent_color,
			16
		)

	var tw: Tween = create_tween().set_parallel(true)
	visual_container.modulate = Color(3.0, 1.5, 1.5, 1.0)
	tw.tween_property(visual_container, "scale", Vector2(1.6, 1.6), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "modulate:a", 0.0, 0.16)
	tw.tween_property(self, "position", position + normal * 20.0, 0.12)
	tw.chain().tween_callback(despawn)


func on_parried_by_gate(push_velocity: Vector2, impact_angle: float) -> void:
	_is_projected_by_gate = true
	_projection_time = 0.0
	if dive_component != null:
		dive_component.reset()
	visual_container.rotation = 0.0
	_knockback_velocity = push_velocity
	_trigger_impact_squash(impact_angle)

	# Flash d'impact doré
	visual_container.modulate = Color(2.5, 2.5, 1.2, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.15)

func apply_knockback(impulse: Vector2, hit_angle: float) -> void:
	if enemy_data != null and not enemy_data.can_be_kicked_by_gate:
		return
	_knockback_velocity = impulse
	_trigger_impact_squash(hit_angle)

func _trigger_impact_squash(hit_angle: float) -> void:
	_is_squashing_from_hit = true
	visual_container.rotation = hit_angle
	var tween: Tween = create_tween()
	tween.tween_property(visual_container, "scale", Vector2(1.25, 0.75), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "scale", Vector2(0.92, 1.12), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(func() -> void: _is_squashing_from_hit = false)

func _apply_walk_juice() -> void:
	if status_component != null and status_component.is_stunned():
		# Tanguement oscillatoire d'étourdissement
		if visual_container != null:
			visual_container.rotation = sin(_time_alive * 9.0) * 0.12
			visual_container.scale = Vector2(1.0 + sin(_time_alive * 7.0) * 0.04, 0.94 + cos(_time_alive * 7.0) * 0.04)
		return

	if movement_strategy != null and visual_container != null:
		movement_strategy.apply_visual_juice(self, visual_container, _time_alive, 0.0)

func is_dying() -> bool:
	return _is_dying or _is_expelled

func take_hit(amount: int = 1, hit_source: Node = null, impact_velocity: Vector2 = Vector2.ZERO) -> void:
	var ctx: HitContext = HitContext.create(hit_source, self, amount, global_position, impact_velocity)
	take_hit_with_context(ctx)

func take_hit_with_context(hit_ctx: HitContext) -> void:
	if _is_dying or _is_expelled or hit_ctx == null:
		return
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_hit_timestamp < 0.06:
		return
	_last_hit_timestamp = current_time
	_time_since_last_damage = 0.0

	_last_hit_context = hit_ctx
	_last_hit_source = hit_ctx.attacker
	_last_impact_velocity = hit_ctx.impact_velocity

	if hit_ctx.impact_velocity.length() > 20.0:
		_last_hit_direction = hit_ctx.impact_velocity.normalized()
	elif hit_ctx.attacker is Node2D:
		_last_hit_direction = (global_position - (hit_ctx.attacker as Node2D).global_position).normalized()
	else:
		_last_hit_direction = Vector2.UP

	health_component.take_damage(hit_ctx.final_damage)
	EventBus.enemy_damaged.emit(self, hit_ctx)

	# Flash blanc de dégât
	var tw: Tween = create_tween()
	visual_container.modulate = Color(2.5, 2.5, 2.5, 1.0)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.10)

func _on_died() -> void:
	if _is_dying or _is_expelled:
		return
	_is_dying = true
	active_enemies.erase(self)
	collision_shape.set_deferred(&"disabled", true)

	# Nettoyage des altérations d'état (détruit la bille caramel accrochée si besoin)
	if status_component != null:
		if status_component.is_frozen() and visual_overlay != null:
			visual_overlay.trigger_ice_shatter()
		status_component.cleanup_on_death()

	var score_val: int = enemy_data.score_value if enemy_data else 100
	var e_name: StringName = enemy_data.enemy_name if enemy_data else &"Tomato"
	EventBus.enemy_defeated.emit(e_name, global_position)
	EventBus.enemy_killed.emit(self, _last_hit_context)
	EventBus.score_changed.emit(score_val, score_val)

	# Décision du type de mort :
	# Les ennemis légers achevés par une bille directe sont expulsés en cloche hors de l'arène.
	# S'ils sont tués d'une autre façon (ou si ce sont des ennemis lourds), ils explosent en gouttelettes de jus !
	var is_lightweight: bool = (enemy_data != null and enemy_data.is_lightweight)
	var is_ball_impact: bool = (_last_hit_source is Ball)
	var forced_effect: String = enemy_data.death_effect_type if enemy_data else "auto"

	if forced_effect == "fly_away" or (forced_effect == "auto" and is_lightweight and is_ball_impact):
		_play_ejection_death(_last_hit_direction)
	else:
		_play_juice_explosion_death()

func _play_ejection_death(hit_dir: Vector2) -> void:
	if expulsion_component != null:
		expulsion_component.launch(hit_dir)

func _play_juice_explosion_death() -> void:
	_is_dying = true
	collision_shape.set_deferred(&"disabled", true)
	if has_node("Shadow"):
		$Shadow.visible = false

	if enemy_data != null:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			enemy_data.juice_primary_color,
			enemy_data.juice_secondary_color,
			enemy_data.juice_accent_color,
			enemy_data.juice_droplet_count
		)

	# Disparition très rapide du sprite avec flash et écrasement
	var tw: Tween = create_tween().set_parallel(true)
	visual_container.modulate = Color(3.0, 2.0, 2.0, 1.0)
	tw.tween_property(visual_container, "scale", Vector2(1.5, 0.35), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "modulate:a", 0.0, 0.06)
	tw.chain().tween_callback(despawn)

func despawn() -> void:
	_is_game_over_charging = false
	active_enemies.erase(self)
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", true)
	if dive_component != null:
		dive_component.reset()
	queue_free()
