class_name Fizzball
extends Ball

## Balle acidulée / électrique "Fizzball".
## Lors d'un impact sur un ennemi :
## - Déclenche un éclair / arc électrique qui frappe l'ennemi touché
## - Propage l'arc jusqu'à 2 ennemis proches supplémentaires
## - Inflige 1 dégât et paralyse (immobilise + secoue) pendant 2 secondes !

@export var max_chain_targets: int = 2
@export var chain_radius: float = 380.0

func _ready() -> void:
	super._ready()
	# Teinte acidulée / vert électrique
	if visual_ball != null:
		visual_ball.color = Color(0.2, 0.95, 0.75, 1.0)
	if core_glow != null:
		core_glow.color = Color(0.9, 1.0, 0.3, 1.0)
	if trail != null:
		trail.default_color = Color(0.3, 1.0, 0.8, 0.6)

func hit_enemy_with_target(primary_enemy: Enemy, durability_loss: int = 1) -> void:
	# 1. Traitement de la durabilité de la bille
	super.hit_enemy(durability_loss)
	
	# 2. Déclenchement de la chaîne d'arcs électriques
	_trigger_chain_lightning(primary_enemy)

func _trigger_chain_lightning(primary_enemy: Enemy) -> void:
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return
		
	# Effet sur la cible principale
	primary_enemy.apply_electric_zap(1, 1.0)
	_draw_lightning_bolt(global_position, primary_enemy.global_position)
	
	# Recherche des ennemis proches
	var enemies_in_tree: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
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
		chained_enemy.apply_electric_zap(1, 0.5)
		_draw_lightning_bolt(last_pos, chained_enemy.global_position)
		last_pos = chained_enemy.global_position

func _draw_lightning_bolt(from: Vector2, to: Vector2) -> void:
	# Génération d'un éclair en zigzag
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
	
	get_parent().add_child(bolt)
	
	# Disparition en flash
	var tween: Tween = bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.18)
	tween.tween_callback(bolt.queue_free)
