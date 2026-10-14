class_name WalkStraightStrategy
extends EnemyMovementStrategy

## Marche directe vers la porte centrale avec dandinement organique (Tomate).

func compute_velocity(enemy: CharacterBody2D, _delta: float, effective_speed: float, target_door: Vector2) -> Vector2:
	var dir_to_gate: Vector2 = Vector2(target_door.x - enemy.global_position.x, target_door.y - enemy.global_position.y).normalized()
	return Vector2(dir_to_gate.x * 0.45, 1.0).normalized() * effective_speed

func apply_visual_juice(enemy: CharacterBody2D, visual_container: Node2D, time_alive: float, _delta: float) -> void:
	var data: EnemyData = enemy.enemy_data if "enemy_data" in enemy else null
	var wobble_freq: float = data.wobble_frequency if data != null else 6.0
	var wobble_amp: float = data.wobble_amplitude if data != null else 0.12
	var squash_freq: float = data.squash_frequency if data != null else 4.0
	var squash_amt: float = 0.08

	var step_wave: float = sin(time_alive * squash_freq)
	var squash_factor: float = step_wave * squash_amt
	visual_container.scale = Vector2(1.0 + squash_factor * 0.5, 1.0 - squash_factor * 0.7)
	visual_container.rotation = sin(time_alive * wobble_freq) * wobble_amp
