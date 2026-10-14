class_name CandyBumper
extends StaticBody2D

## Bumper interactif en bonbon.
## Réagit au contact de la bille : rebond dynamique, jiggle / tremblotement,
## et déclenchement de son pouvoir (ex: attraction des ennemis proches pour le Dragibump).

@export var bumper_data: BumperData

@onready var sprite: Sprite2D = $Sprite2D
@onready var attraction_area: Area2D = $AttractionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _periodic_timer: float = 0.0
var _is_jiggling: bool = false
var _original_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	if sprite != null:
		_original_scale = sprite.scale
	if bumper_data != null and bumper_data.sprite_texture != null and sprite != null:
		sprite.texture = bumper_data.sprite_texture

func _physics_process(delta: float) -> void:
	if bumper_data == null:
		return
		
	# Effet périodique
	if bumper_data.trigger_type == BumperData.TriggerType.PERIODIC or bumper_data.trigger_type == BumperData.TriggerType.BOTH:
		_periodic_timer += delta
		if _periodic_timer >= bumper_data.periodic_interval:
			_periodic_timer = 0.0
			trigger_bumper_effect()

func on_hit_by_ball(ball: RigidBody2D, hit_point: Vector2) -> void:
	# 1. Répulsion physique vive de la bille
	var push_direction: Vector2 = (ball.global_position - global_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.UP
	var force: float = bumper_data.bounce_force if bumper_data else 650.0
	ball.linear_velocity = push_direction * force
	
	# 2. Score
	var score_val: int = bumper_data.score_on_hit if bumper_data else 50
	EventBus.score_changed.emit(score_val, score_val)
	
	# 3. Tremblotement visuel (Juice / Jiggle)
	_play_jiggle_animation()
	
	# 4. Effet de jeu (ex: attraction)
	trigger_bumper_effect()

func trigger_bumper_effect() -> void:
	if bumper_data == null:
		return
		
	# Pour le Dragibump : attire les ennemis proches
	if bumper_data.id == &"dragibump":
		_pull_nearby_enemies()

func _pull_nearby_enemies() -> void:
	var radius: float = bumper_data.attraction_radius
	var strength: float = bumper_data.attraction_strength
	
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	for node in enemies:
		if node is CharacterBody2D and is_instance_valid(node):
			var dist: float = global_position.distance_to(node.global_position)
			if dist <= radius and dist > 10.0:
				var pull_direction: Vector2 = (global_position - node.global_position).normalized()
				var factor: float = 1.0 - (dist / radius) # Plus fort près du centre
				var impulse: Vector2 = pull_direction * (strength * factor)
				if node.has_method(&"apply_knockback"):
					node.apply_knockback(impulse, pull_direction.angle())

func _play_jiggle_animation() -> void:
	if _is_jiggling:
		return
	_is_jiggling = true
	
	var tween: Tween = create_tween()
	# Squash & Stretch gélifié Dragibus
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.35, 0.7), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(0.8, 1.25), 0.08).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.1, 0.95), 0.08)
	tween.tween_property(sprite, "scale", _original_scale, 0.1)
	
	# Lueur / flash
	var glow_tween: Tween = create_tween()
	sprite.modulate = Color(2.2, 1.4, 2.5, 1.0)
	glow_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	
	tween.tween_callback(func() -> void: _is_jiggling = false)
