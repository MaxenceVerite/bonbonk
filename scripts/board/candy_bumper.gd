class_name CandyBumper
extends StaticBody2D

const CandyTextureHelper = preload("res://scripts/core/candy_texture_helper.gd")

## Bumper interactif en bonbon.
## Réagit au contact de la bille : rebond dynamique, jiggle incandescent,
## et déclenchement de son pouvoir (ex: souffle de dragon pour le Dragiburst).

@export var bumper_data: BumperData
@export var current_level: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _periodic_timer: float = 0.0
var _is_jiggling: bool = false
var _original_scale: Vector2 = Vector2.ONE
var _spin_speed: float = 2.4
var _spin_boost: float = 1.0

static var active_bumpers: Array[CandyBumper] = []

func _enter_tree() -> void:
	if not active_bumpers.has(self):
		active_bumpers.append(self)

func _exit_tree() -> void:
	active_bumpers.erase(self)

func _ready() -> void:
	z_index = 10
	add_to_group(&"bumpers")
	if not active_bumpers.has(self):
		active_bumpers.append(self)
	if sprite != null:
		_original_scale = sprite.scale
	update_visuals()

func setup_bumper(data: BumperData) -> void:
	bumper_data = data
	update_visuals()

func update_visuals() -> void:
	if sprite == null:
		return
	var b_id: StringName = bumper_data.id if bumper_data != null else &"dragiburst"
	var path: String = "res://assets/board/%s_sprite.png" % [String(b_id)]
	var tex: Texture2D = CandyTextureHelper.load_texture(path)
	if tex == null and bumper_data != null and bumper_data.sprite_texture != null:
		tex = bumper_data.sprite_texture
	if tex != null:
		sprite.texture = tex
	
	if bumper_data != null:
		_spin_speed = bumper_data.spin_speed if bumper_data.has_spin_animation else 0.0

func _process(delta: float) -> void:
	# Animation de rotation continue (ex: Sucette Twistypop)
	if bumper_data != null and (bumper_data.has_spin_animation or bumper_data.id == &"twistypop"):
		if sprite != null:
			sprite.rotation += _spin_speed * _spin_boost * delta
		if _spin_boost > 1.0:
			_spin_boost = move_toward(_spin_boost, 1.0, delta * 4.0)

func _draw() -> void:
	if sprite == null or sprite.texture == null:
		var c: Vector2 = Vector2.ZERO
		var b_id: StringName = bumper_data.id if bumper_data != null else &"dragiburst"
		if b_id == &"twistypop":
			draw_circle(c + Vector2(0, 4), 38.0, Color(0.1, 0.1, 0.15, 0.4))
			draw_circle(c, 36.0, Color(0.95, 0.25, 0.65, 1.0))
			draw_arc(c, 36.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.2, 0.9), 3.0, true)
			draw_circle(c, 24.0, Color(0.2, 0.85, 0.95, 0.9))
			draw_circle(c, 12.0, Color(1.0, 0.95, 0.35, 1.0))
		else:
			draw_circle(c + Vector2(0, 4), 38.0, Color(0.2, 0.05, 0.08, 0.5))
			draw_circle(c, 36.0, Color(0.92, 0.12, 0.18, 1.0))
			draw_arc(c, 36.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.15, 0.9), 3.0, true)
			draw_circle(c, 24.0, Color(1.0, 0.32, 0.12, 0.9))
			draw_circle(c + Vector2(-10, -10), 8.0, Color(1.0, 1.0, 1.0, 0.85))

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
	if ball.has_method(&"apply_bumper_bounce"):
		ball.apply_bumper_bounce(push_direction, force)
	else:
		ball.linear_velocity = push_direction * force
	
	# 2. Score & Événements
	var score_val: int = bumper_data.score_on_hit if bumper_data else 50
	EventBus.score_changed.emit(score_val, score_val)
	EventBus.ball_hit_bumper.emit(ball, self)
	
	# 3. Tremblotement visuel (Juice / Jiggle)
	_play_jiggle_animation()
	
	# 4. Effet de jeu (Strategy Pattern)
	trigger_bumper_effect()

func trigger_bumper_effect() -> void:
	if bumper_data != null and bumper_data.effect_strategy != null:
		bumper_data.effect_strategy.execute(self)

func play_jiggle() -> void:
	_play_jiggle_animation()

func _play_jiggle_animation() -> void:
	if _is_jiggling:
		return
	_is_jiggling = true
	_spin_boost = 3.6
	
	var tween: Tween = create_tween()
	# Squash & Stretch élastique éclatant
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.35, 0.7), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(0.8, 1.25), 0.08).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.1, 0.95), 0.08)
	tween.tween_property(sprite, "scale", _original_scale, 0.1)
	
	# Lueur / flash éclatant
	var glow_tween: Tween = create_tween()
	var flash_col: Color = Color(2.4, 2.4, 2.8, 1.0) if (bumper_data != null and bumper_data.id == &"twistypop") else Color(2.8, 1.2, 0.5, 1.0)
	sprite.modulate = flash_col
	glow_tween.tween_property(sprite, "modulate", Color.WHITE, 0.28)
	
	tween.tween_callback(func() -> void: _is_jiggling = false)
