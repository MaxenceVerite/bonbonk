class_name Enemy
extends CharacterBody2D

## Ennemi pouvant marcher, rouler ou sautiller en diagonale.
## Supporte les caractéristiques :
## - Tomate : rapide, 1 PV, 1 dégât
## - Ananas : sauts en diagonale, 10 PV, 3 dégâts, piquant (abîme la bille et blesse les ennemis heurtés)
## - Pastèque : roulement continu, 30 PV, 20 dégâts, insensibilité au batteur, accélération passive si non touchée

@export var enemy_data: EnemyData
@export var target_door_y: float = 1140.0

@onready var visual_container: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _time_alive: float = 0.0
var _is_dying: bool = false
var _target_door_x: float = 310.0 # Centre de l'ouverture entre les deux batteurs

# Gestion du knockback (projection physique)
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_friction: float = 850.0
var _is_squashing_from_hit: bool = false
var _is_projected_by_gate: bool = false
var _projection_time: float = 0.0

# Gestion du Zap électrique / Stun (Fizzball)
var _is_stunned: bool = false
var _stun_timer: float = 0.0

# Trait Pastèque : Accélération progressive si pas de dégât
var _time_since_last_damage: float = 0.0
var _current_move_speed: float = 50.0

# Trait Ananas : Déplacement par sauts diagonaux imprévisibles
var _hop_dir_x: float = 1.0
var _hop_timer: float = 0.0
var _hop_interval: float = 0.65

# Trait Caramel Collant
var _attached_caramel_ball: Node2D = null
var _slow_factor: float = 1.0

func attach_caramel_ball(caramel_ball: Node2D, speed_multiplier: float = 0.35) -> void:
	if _is_dying:
		return
	_attached_caramel_ball = caramel_ball
	_slow_factor = speed_multiplier
	
	# Teinte ambrée / caramel fondant
	var tween: Tween = create_tween()
	visual_container.modulate = Color(1.8, 1.2, 0.4, 1.0)
	tween.tween_property(visual_container, "modulate", Color(1.2, 0.9, 0.6, 1.0), 0.2)

func detach_caramel_ball() -> void:
	_attached_caramel_ball = null
	_slow_factor = 1.0
	visual_container.modulate = Color.WHITE

func apply_electric_zap(damage: int = 1, stun_duration: float = 2.0) -> void:
	if _is_dying:
		return
	_is_stunned = true
	_stun_timer = stun_duration
	_knockback_velocity = Vector2.ZERO
	take_hit(damage)
	
	var tween: Tween = create_tween()
	visual_container.modulate = Color(1.8, 2.2, 0.4, 1.0)
	tween.tween_property(visual_container, "modulate", Color(0.6, 1.3, 1.5, 1.0), 0.2)

func _ready() -> void:
	add_to_group(&"enemies")
	if enemy_data != null:
		health_component.set_max_health(enemy_data.max_health)
		_current_move_speed = enemy_data.get_speed_from_tier()
	health_component.died.connect(_on_died)
	_time_alive = randf_range(0.0, 5.0)
	_hop_dir_x = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
		
	_time_alive += delta
	_time_since_last_damage += delta
	
	# Stun électrique
	if _is_stunned:
		_stun_timer -= delta
		visual_container.position = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		if _stun_timer <= 0.0:
			_is_stunned = false
			visual_container.position = Vector2.ZERO
			visual_container.modulate = Color.WHITE
	else:
		visual_container.position = Vector2.ZERO
	
	# 1. Calcul de la vitesse et de la direction selon le pattern
	var effective_speed: float = 0.0
	var walk_velocity: Vector2 = Vector2.ZERO
	
	if not _is_stunned:
		var base_speed: float = enemy_data.get_speed_from_tier() if enemy_data else 80.0
		
		# Trait Pastèque : Accélération progressive après 3s sans dégât (de 38 px/s jusqu'à 75 px/s)
		if enemy_data != null and enemy_data.can_accelerate_when_idle:
			if _time_since_last_damage > 3.0:
				_current_move_speed = move_toward(_current_move_speed, 75.0, 10.0 * delta)
			else:
				_current_move_speed = base_speed
		else:
			_current_move_speed = base_speed

		effective_speed = _current_move_speed * _slow_factor
		var pattern: int = enemy_data.move_pattern if enemy_data else 0
		
		match pattern:
			EnemyData.MovePattern.WALK_STRAIGHT:
				# Marche vers le trou central entre les portes
				var dir_to_gate: Vector2 = Vector2(_target_door_x - global_position.x, target_door_y - global_position.y).normalized()
				walk_velocity = Vector2(dir_to_gate.x * 0.45, 1.0).normalized() * effective_speed
				
			EnemyData.MovePattern.ROLL_STRAIGHT:
				# Pastèque : Ligne droite pesante vers le bas avec légère inclinaison vers le centre
				var dir_to_center: float = signf(_target_door_x - global_position.x)
				walk_velocity = Vector2(dir_to_center * 0.25, 1.0).normalized() * effective_speed
				# Roulement physique continu de la pastèque
				visual_container.rotation += (effective_speed * 0.035) * delta * dir_to_center
				
			EnemyData.MovePattern.DIAGONAL_HOPPER:
				# Ananas : Sauts diagonaux saccadés (gauche/droite)
				_hop_timer += delta
				if _hop_timer >= _hop_interval:
					_hop_timer = 0.0
					# Change de diagonale ou maintient de façon imprévisible
					if randf() > 0.35 or global_position.x < 80.0 or global_position.x > 540.0:
						_hop_dir_x *= -1.0
				
				var hop_phase: float = sin((_hop_timer / _hop_interval) * PI) # 0 -> 1 -> 0 pour l'impulsion du saut
				var horiz: float = _hop_dir_x * 0.8
				walk_velocity = Vector2(horiz, 0.7).normalized() * (effective_speed * (0.4 + hop_phase * 1.2))


	# 2. Gestion knockback & Projection par la porte
	if _knockback_velocity.length() > 5.0:
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _knockback_friction * delta)
		
		# Si l'ennemi a été projeté par le batteur, on surveille la fin de sa trajectoire pour le faire exploser
		if _is_projected_by_gate:
			_projection_time += delta
			# Quand la projection retombe sous un certain seuil ou après un temps maximal de vol
			if _knockback_velocity.length() < 90.0 or _projection_time > 1.2 or global_position.y < 80.0:
				_is_projected_by_gate = false
				_explode_after_projection()
	else:
		_knockback_velocity = Vector2.ZERO
		velocity = walk_velocity
		if _is_projected_by_gate:
			_is_projected_by_gate = false
			_explode_after_projection()

	# 3. Collision
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		var collider: Object = collision.get_collider()
		
		# Collision avec la bille (Système universel de mots-clés)
		if collider is Ball:
			var durability_penalty: int = enemy_data.spiky_ball_durability_loss if (enemy_data and enemy_data.is_spiky) else 1
			(collider as Ball).hit_enemy_with_target(self, durability_penalty)
			take_hit(1)
			
		# Collision avec la porte / batteur en chocolat
		elif collider is WoodenGateFlipper:
			var gate: WoodenGateFlipper = collider as WoodenGateFlipper
			var impact_point: Vector2 = collision.get_position()
			var gate_vel: Vector2 = gate.get_velocity_at_point(impact_point)
			var collision_normal: Vector2 = collision.get_normal()
			var dmg: int = enemy_data.damage_on_escape if (enemy_data != null) else 1
			
			if gate.is_kicking() and enemy_data != null and enemy_data.can_be_kicked_by_gate:
				# 1. Poussée active par la porte en mouvement :
				# Inflige ses dommages à la porte / joueur
				EventBus.enemy_escaped.emit(dmg)
				# Est projeté vers le haut du terrain
				var gate_speed: float = gate_vel.length()
				var push_direction: Vector2 = (gate_vel.normalized() + Vector2.UP * 0.85).normalized()
				var kick_speed: float = maxf(gate_speed, 950.0) * (enemy_data.kick_rebound_factor / maxf(0.2, enemy_data.mass_weight))
				
				_is_projected_by_gate = true
				_projection_time = 0.0
				apply_knockback(push_direction * kick_speed, collision_normal.angle())
			else:
				# 2. Porte au repos OU ennemie inébranlable (Pastèque) :
				# Inflige immédiatement des dégâts au joueur et explose
				EventBus.enemy_escaped.emit(dmg)
				_explode_at_gate(collision_normal)

		# Collision avec un autre ennemi
		elif collider is Enemy:
			var other_enemy: Enemy = collider as Enemy
			if _knockback_velocity.length() > 120.0:
				var push_dir: Vector2 = (other_enemy.global_position - global_position).normalized()
				# Si l'ennemi projeté est piquant (Ananas), il blesse l'autre ennemi !
				if enemy_data != null and enemy_data.is_spiky:
					other_enemy.take_hit(2)
				other_enemy.apply_knockback(push_dir * (_knockback_velocity.length() * 0.75), 0.0)
				_knockback_velocity *= 0.65

	# 4. Juice procédural (sauf Pastèque qui utilise son roulement)
	if not _is_squashing_from_hit and (enemy_data == null or enemy_data.move_pattern != EnemyData.MovePattern.ROLL_STRAIGHT):
		_apply_walk_juice()

func _explode_at_gate(normal: Vector2) -> void:
	if _is_dying:
		return
	_is_dying = true
	collision_shape.set_deferred(&"disabled", true)
	
	# Éclatement avec flash et onde de choc immédiate sur la porte
	var tw: Tween = create_tween().set_parallel(true)
	visual_container.modulate = Color(3.0, 1.5, 1.5, 1.0)
	tw.tween_property(visual_container, "scale", Vector2(1.8, 1.8), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "modulate:a", 0.0, 0.22)
	tw.tween_property(self, "position", position + normal * 20.0, 0.16)
	tw.chain().tween_callback(queue_free)

func _explode_after_projection() -> void:
	if _is_dying:
		return
	_is_dying = true
	collision_shape.set_deferred(&"disabled", true)
	
	# Explosion après avoir résolu ses effets de vol
	var tw: Tween = create_tween().set_parallel(true)
	visual_container.modulate = Color(2.5, 2.0, 1.0, 1.0)
	tw.tween_property(visual_container, "scale", Vector2(2.2, 2.2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(queue_free)

func apply_knockback(impulse: Vector2, hit_angle: float) -> void:
	if enemy_data != null and not enemy_data.can_be_kicked_by_gate:
		return # Pastèque inébranlable
	_knockback_velocity = impulse
	_trigger_impact_squash(hit_angle)

func _trigger_impact_squash(hit_angle: float) -> void:
	_is_squashing_from_hit = true
	visual_container.rotation = hit_angle
	var tween: Tween = create_tween()
	tween.tween_property(visual_container, "scale", Vector2(1.4, 0.6), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "scale", Vector2(0.85, 1.25), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "scale", Vector2.ONE, 0.15)
	tween.tween_callback(func() -> void: _is_squashing_from_hit = false)

func _apply_walk_juice() -> void:
	var wobble_freq: float = enemy_data.wobble_frequency if enemy_data else 6.0
	var wobble_amp: float = enemy_data.wobble_amplitude if enemy_data else 0.12
	var squash_freq: float = enemy_data.squash_frequency if enemy_data else 4.0
	var squash_amt: float = enemy_data.squash_amount if enemy_data else 0.14
	
	visual_container.rotation = sin(_time_alive * wobble_freq) * wobble_amp
	var squash_factor: float = sin(_time_alive * squash_freq) * squash_amt
	visual_container.scale = Vector2(1.0 + squash_factor, 1.0 - squash_factor)

func is_dying() -> bool:
	return _is_dying

var _last_hit_timestamp: float = -999.0

func take_hit(amount: int = 1) -> void:
	if _is_dying:
		return
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_hit_timestamp < 0.08:
		return
	_last_hit_timestamp = current_time
	_time_since_last_damage = 0.0
	health_component.take_damage(amount)
	
	# Flash blanc de dégât
	var tw: Tween = create_tween()
	visual_container.modulate = Color(2.5, 2.5, 2.5, 1.0)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.12)

func _on_died() -> void:
	_is_dying = true
	collision_shape.set_deferred(&"disabled", true)
	
	# Si une bille caramel était accrochée à cet ennemi, elle est détruite avec lui
	if _attached_caramel_ball != null and is_instance_valid(_attached_caramel_ball):
		if _attached_caramel_ball.has_method(&"shatter"):
			_attached_caramel_ball.shatter()
		else:
			_attached_caramel_ball.queue_free()
		_attached_caramel_ball = null
	
	var score_val: int = enemy_data.score_value if enemy_data else 100
	var e_name: StringName = enemy_data.enemy_name if enemy_data else &"Tomato"
	EventBus.enemy_defeated.emit(e_name, global_position)
	EventBus.score_changed.emit(score_val, score_val)
	
	var effect_type: String = enemy_data.death_effect_type if enemy_data else "fly_away"
	match effect_type:
		"fly_away":
			_play_fly_away_death()
		"flatten":
			_play_flatten_death()
		"burst":
			_play_burst_death()
		_:
			_play_fly_away_death()

func _play_fly_away_death() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	var random_x_dir: float = randf_range(-140.0, 140.0)
	var target_pos: Vector2 = position + Vector2(random_x_dir, -260.0)
	
	tween.tween_property(self, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "rotation", rotation + (PI * 4.0 * signf(random_x_dir)), 0.45)
	tween.tween_property(visual_container, "scale", Vector2(0.2, 0.2), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visual_container, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)

func _play_flatten_death() -> void:
	# Écrasement façon pastèque
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visual_container, "scale", Vector2(2.5, 0.2), 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)

func _play_burst_death() -> void:
	# Explosion d'éclats (Ananas)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visual_container, "scale", Vector2(2.0, 2.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_container, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
