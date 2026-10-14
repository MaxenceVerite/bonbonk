class_name EnemyMovementStrategy
extends RefCounted

## Stratégie abstraite de déplacement et d'animation procédurale d'un ennemi (Strategy Pattern).

func compute_velocity(_enemy: CharacterBody2D, _delta: float, _effective_speed: float, _target_door: Vector2) -> Vector2:
	return Vector2.DOWN * _effective_speed

func apply_visual_juice(_enemy: CharacterBody2D, _visual_container: Node2D, _time_alive: float, _delta: float) -> void:
	pass
