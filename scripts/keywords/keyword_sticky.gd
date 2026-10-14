class_name KeywordSticky
extends BallKeyword

## Mot-clé "Collant" (Sticky) :
## La bille s'accroche physiquement à l'ennemi percuté, le ralentit fortement,
## et est détruite lorsqu'il meurt.

@export var slow_multiplier: float = 0.35 # L'ennemi conserve 35% de sa vitesse
@export var initial_impact_damage: int = 1

func _init() -> void:
	id = &"sticky"
	display_name = "Collant"
	description = "S'accroche à l'ennemi à l'impact, le ralentit de 65% et explose à sa mort."

func on_hit_enemy(ball: Ball, enemy: Enemy) -> void:
	if ball == null or not is_instance_valid(ball):
		return
	if enemy == null or not is_instance_valid(enemy):
		return
		
	# Vérifie si la bille est déjà attachée
	if ball.get_meta(&"is_attached_to_enemy", false):
		return
		
	ball.set_meta(&"is_attached_to_enemy", true)
	ball.set_meta(&"attached_enemy", enemy)
	
	# Gèle la physique de flipper pour suivre l'ennemi
	ball.freeze = true
	if ball.collision_shape != null:
		ball.collision_shape.set_deferred(&"disabled", true)
	if ball.trail != null:
		ball.trail.visible = false
	if ball.shadow != null:
		ball.shadow.visible = false
		
	var local_offset: Vector2 = ball.global_position - enemy.global_position
	if local_offset.length() > 24.0:
		local_offset = local_offset.normalized() * 20.0
		
	ball.reparent(enemy)
	ball.position = local_offset
	
	# Ralentit l'ennemi et applique le coup
	enemy.attach_caramel_ball(ball, slow_multiplier)
	enemy.take_hit(initial_impact_damage)
	
	# Petit effet de squash caramel fondant
	if ball.visual_ball != null:
		var tw: Tween = ball.create_tween()
		tw.tween_property(ball.visual_ball, "scale", Vector2(1.6, 0.6), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(ball.visual_ball, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	# Libère le slot sur le plateau pour alimenter une nouvelle bille
	ball.ball_shattered.emit()

func on_attached_enemy_died(ball: Ball, _enemy: Enemy) -> void:
	if ball != null and is_instance_valid(ball):
		ball.shatter()
