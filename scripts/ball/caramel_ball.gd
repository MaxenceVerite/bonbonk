class_name CaramelBall
extends Ball

## Bille de caramel fondant possédant le mot-clé "Collant".
## Dès qu'elle percute un ennemi :
## - Elle s'accroche physiquement à lui (devient son enfant ou le suit étroitement).
## - Elle réduit considérablement la vitesse de déplacement de l'ennemi (ralentissement de ~65%).
## - Elle cesse sa course physique de flipper et reste collée.
## - Lorsque l'ennemi meurt, la bille caramel est détruite avec lui dans un éclat sucré !

@export var slow_multiplier: float = 0.35 # L'ennemi conserve 35% de sa vitesse

var is_stuck_to_enemy: bool = false
var _target_enemy: Enemy = null

func _ready() -> void:
	super._ready()
	# Teinte caramel ambré / miel
	if visual_ball != null:
		visual_ball.color = Color(0.92, 0.55, 0.18, 1.0)
	if core_glow != null:
		core_glow.color = Color(1.0, 0.82, 0.35, 1.0)
	if trail != null:
		trail.default_color = Color(0.95, 0.65, 0.25, 0.55)

func hit_enemy_with_target(enemy: Enemy, _durability_loss: int = 1) -> void:
	if is_stuck_to_enemy or _is_shattering:
		return
		
	if enemy != null and is_instance_valid(enemy):
		stick_to_enemy(enemy)

func stick_to_enemy(enemy: Enemy) -> void:
	is_stuck_to_enemy = true
	_target_enemy = enemy
	
	# Désactiver la physique du Rigidbody de flipper
	freeze = true
	collision_shape.set_deferred(&"disabled", true)
	if trail != null:
		trail.visible = false
	if shadow != null:
		shadow.visible = false
		
	# Attacher la bille sur l'ennemi
	var local_offset: Vector2 = global_position - enemy.global_position
	# Limite la distance d'ancrage sur le sprite
	if local_offset.length() > 24.0:
		local_offset = local_offset.normalized() * 20.0
		
	reparent(enemy)
	position = local_offset
	
	# Ralentir l'ennemi
	enemy.attach_caramel_ball(self, slow_multiplier)
	enemy.take_hit(1) # Inflige 1 dégât initial lors de l'impact
	
	# Effet visuel : squash d'écrasement caramel fondant
	var tween: Tween = create_tween()
	tween.tween_property(visual_ball, "scale", Vector2(1.6, 0.6), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_ball, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Notifier le plateau qu'une nouvelle bille peut entrer en jeu si besoin
	ball_shattered.emit()
