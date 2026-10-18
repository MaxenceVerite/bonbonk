class_name BallTrail
extends Line2D

## Trail lumineux / traînée dynamique pour la balle avec fondu dégressif.
## Optimisé pour 120 Hz : seuil de distance minimal et dissolution progressive à l'arrêt.

@export var max_length: int = 14
@export var min_point_distance: float = 5.0

var _min_dist_sq: float = 25.0
var _shrink_timer: float = 0.0

func _ready() -> void:
	_min_dist_sq = min_point_distance * min_point_distance

func _physics_process(delta: float) -> void:
	global_position = Vector2.ZERO
	global_rotation = 0.0

	var parent_node: Node2D = get_parent() as Node2D
	if parent_node == null:
		return

	var p_pos: Vector2 = parent_node.global_position
	var pt_count: int = get_point_count()

	if pt_count == 0:
		add_point(p_pos)
		return

	var last_pos: Vector2 = get_point_position(pt_count - 1)
	var dist_sq: float = p_pos.distance_squared_to(last_pos)

	if dist_sq >= _min_dist_sq:
		add_point(p_pos)
		while get_point_count() > max_length:
			remove_point(0)
		_shrink_timer = 0.0
	else:
		# Bille quasi-immobile : dissoudre doucement la queue sans surcharger les batches
		_shrink_timer += delta
		if _shrink_timer >= 0.035 and pt_count > 0:
			_shrink_timer = 0.0
			remove_point(0)
