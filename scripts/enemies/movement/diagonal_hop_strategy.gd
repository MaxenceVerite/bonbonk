class_name DiagonalHopStrategy
extends EnemyMovementStrategy

## Sauts en diagonale imprévisibles avec étirement élastique (Ananas).

var hop_dir_x: float = 1.0
var hop_timer: float = 0.0
var hop_interval: float = 0.65

func _init() -> void:
	hop_dir_x = 1.0 if randf() > 0.5 else -1.0

func compute_velocity(enemy: CharacterBody2D, delta: float, effective_speed: float, _target_door: Vector2) -> Vector2:
	hop_timer += delta
	if hop_timer >= hop_interval:
		hop_timer = 0.0
		if randf() > 0.35 or enemy.global_position.x < 80.0 or enemy.global_position.x > 540.0:
			hop_dir_x *= -1.0

	var hop_phase: float = sin((hop_timer / hop_interval) * PI)
	var horiz: float = hop_dir_x * 0.8
	return Vector2(horiz, 0.7).normalized() * (effective_speed * (0.4 + hop_phase * 1.2))

func apply_visual_juice(_enemy: CharacterBody2D, visual_container: Node2D, _time_alive: float, _delta: float) -> void:
	var hop_t: float = hop_timer / maxf(0.01, hop_interval)
	var hop_curve: float = sin(hop_t * PI)
	var hop_stretch: float = (hop_curve - 0.25) * 0.08
	visual_container.scale = Vector2(1.0 - hop_stretch, 1.0 + hop_stretch)
	visual_container.rotation = hop_dir_x * 0.07 * hop_curve
