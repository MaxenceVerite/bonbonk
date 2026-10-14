class_name KeywordElectric
extends BallKeyword

## Mot-clé "Électrique / Fizz" (Electric) :
## Déclenche des arcs électriques en chaîne sur les ennemis proches et les étourdit.

@export var max_chain_targets: int = 2
@export var chain_radius: float = 380.0
@export var zap_damage: int = 1
@export var primary_stun_duration: float = 1.0
@export var secondary_stun_duration: float = 0.5

func _init() -> void:
	id = &"electric"
	display_name = "Électrique"
	description = "Propulse des arcs d'éclairs en chaîne et étourdit jusqu'à 3 ennemis."

func on_hit_enemy(ball: Ball, primary_enemy: Enemy) -> void:
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return
	if ball == null or not is_instance_valid(ball):
		return
		
	# Effet sur la cible principale (1s de stun)
	primary_enemy.apply_electric_zap(zap_damage, primary_stun_duration)
	_draw_lightning_bolt(ball, ball.global_position, primary_enemy.global_position)
	
	# Recherche des ennemis proches
	var enemies_in_tree: Array[Node] = ball.get_tree().get_nodes_in_group(&"enemies")
	var candidates: Array[Enemy] = []
	
	for node in enemies_in_tree:
		if node is Enemy and node != primary_enemy and is_instance_valid(node):
			var dist: float = primary_enemy.global_position.distance_to((node as Enemy).global_position)
			if dist <= chain_radius:
				candidates.append(node as Enemy)
				
	# Trier par proximité
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return primary_enemy.global_position.distance_squared_to(a.global_position) < primary_enemy.global_position.distance_squared_to(b.global_position)
	)
	
	var zap_count: int = mini(candidates.size(), max_chain_targets)
	var last_pos: Vector2 = primary_enemy.global_position
	
	for i in range(zap_count):
		var chained_enemy: Enemy = candidates[i]
		# Effet sur cibles secondaires (0.5s de stun)
		chained_enemy.apply_electric_zap(zap_damage, secondary_stun_duration)
		_draw_lightning_bolt(ball, last_pos, chained_enemy.global_position)
		last_pos = chained_enemy.global_position

func _draw_lightning_bolt(ball: Ball, from: Vector2, to: Vector2) -> void:
	var bolt: Line2D = Line2D.new()
	bolt.width = 4.5
	bolt.default_color = Color(0.7, 1.5, 0.4, 1.0)
	bolt.top_level = true
	
	var steps: int = 6
	var points_array: PackedVector2Array = PackedVector2Array()
	points_array.append(from)
	
	var dir: Vector2 = to - from
	var normal: Vector2 = Vector2(-dir.y, dir.x).normalized()
	
	for s in range(1, steps):
		var t: float = float(s) / float(steps)
		var base_pt: Vector2 = from.lerp(to, t)
		var jitter: float = randf_range(-18.0, 18.0)
		points_array.append(base_pt + normal * jitter)
		
	points_array.append(to)
	bolt.points = points_array
	
	ball.get_tree().root.add_child(bolt)
	
	var tween: Tween = bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.18)
	tween.tween_callback(bolt.queue_free)
