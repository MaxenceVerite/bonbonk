class_name AttractionBumperEffect
extends BumperEffect

## Stratégie d'attraction gravitationnelle des ennemis proches (ex: Dragibump).

@export var radius: float = 240.0
@export var strength: float = 480.0

func execute(bumper: Node2D) -> void:
	if bumper == null or not bumper.is_inside_tree():
		return

	var enemies: Array[Node] = bumper.get_tree().get_nodes_in_group(&"enemies")
	for node in enemies:
		if node is CharacterBody2D and is_instance_valid(node):
			var dist: float = bumper.global_position.distance_to(node.global_position)
			if dist <= radius and dist > 10.0:
				var pull_direction: Vector2 = (bumper.global_position - node.global_position).normalized()
				var factor: float = 1.0 - (dist / radius) # Plus intense près du centre
				var impulse: Vector2 = pull_direction * (strength * factor)
				if node.has_method(&"apply_knockback"):
					node.apply_knockback(impulse, pull_direction.angle())
