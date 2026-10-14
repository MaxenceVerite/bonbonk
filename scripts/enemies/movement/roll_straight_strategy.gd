class_name RollStraightStrategy
extends EnemyMovementStrategy

## Roulement lourd en ligne droite avec rotation continue (Pastèque).

func compute_velocity(enemy: CharacterBody2D, delta: float, effective_speed: float, target_door: Vector2) -> Vector2:
	var dir_to_center: float = signf(target_door.x - enemy.global_position.x)
	var velocity: Vector2 = Vector2(dir_to_center * 0.25, 1.0).normalized() * effective_speed
	if "visual_container" in enemy and enemy.visual_container != null:
		enemy.visual_container.rotation += (effective_speed * 0.035) * delta * dir_to_center
	return velocity

func apply_visual_juice(_enemy: CharacterBody2D, _visual_container: Node2D, _time_alive: float, _delta: float) -> void:
	# Pas de squash/wobble car la rotation de roulement gère déjà le dynamisme visuel
	pass
