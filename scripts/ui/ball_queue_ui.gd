class_name BallQueueUI
extends Control

## Affiche la file d'attente visuelle des balles prêtes à entrer dans la rampe.

@export var ball_radius: float = 14.0
@export var spacing: float = 34.0
@export var ball_color: Color = Color(1.0, 0.32, 0.46, 1.0)
@export var highlight_color: Color = Color(1.0, 1.0, 1.0, 0.8)

var remaining_balls: int = 3

func set_ball_count(count: int) -> void:
	remaining_balls = maxi(0, count)
	queue_redraw()

func _draw() -> void:
	# Affiche les billes en attente empilées verticalement le long du couloir droit
	for i in range(remaining_balls):
		var center: Vector2 = Vector2(size.x * 0.5, size.y - 20.0 - (i * spacing))
		draw_circle(center, ball_radius, ball_color)
		draw_circle(center + Vector2(-3, -3), ball_radius * 0.35, highlight_color)
