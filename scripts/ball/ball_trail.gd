class_name BallTrail
extends Line2D

## Trail lumineux / traînée dynamique pour la balle avec fondu dégressif.

@export var max_length: int = 14

func _physics_process(_delta: float) -> void:
	global_position = Vector2.ZERO
	global_rotation = 0.0
	
	var parent_node: Node2D = get_parent() as Node2D
	if parent_node != null:
		add_point(parent_node.global_position)
		while get_point_count() > max_length:
			remove_point(0)
