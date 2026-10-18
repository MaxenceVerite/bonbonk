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
	description = "Propulse des arcs d'éclairs en chaîne et étourdit plusieurs ennemis."

func apply_card_scaling(card_def: CandyCardData, lvl: int) -> void:
	if card_def == null:
		return
	zap_damage = card_def.get_damage_for_level(lvl)
	max_chain_targets = maxi(1, int(roundf(card_def.get_keyword_stat_value(&"chain_targets", lvl, 2.0))))
	primary_stun_duration = card_def.get_keyword_stat_value(&"stun_duration", lvl, 1.0)
	secondary_stun_duration = primary_stun_duration * 0.5

func on_hit_enemy(ball: Ball, primary_enemy: Enemy) -> void:
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return
	if ball == null or not is_instance_valid(ball):
		return
		
	# Effet sur la cible principale (1s de stun)
	primary_enemy.apply_electric_zap(zap_damage, primary_stun_duration)
	_draw_lightning_bolt(ball, ball.global_position, primary_enemy.global_position)
	
	# Recherche des ennemis proches
	var candidates: Array[Enemy] = []
	for e in Enemy.get_active_enemies():
		if e != primary_enemy and e != null and is_instance_valid(e) and not e.is_dying():
			var dist: float = primary_enemy.global_position.distance_to(e.global_position)
			if dist <= chain_radius:
				candidates.append(e)

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

static var _bolt_pool: Array[Line2D] = []

func _draw_lightning_bolt(ball: Ball, from: Vector2, to: Vector2) -> void:
	var bolt: Line2D = null
	while not _bolt_pool.is_empty():
		var candidate: Line2D = _bolt_pool.pop_back()
		if is_instance_valid(candidate):
			bolt = candidate
			break

	if bolt == null:
		bolt = Line2D.new()
		bolt.width = 4.5
		bolt.default_color = Color(0.7, 1.5, 0.4, 1.0)
		bolt.top_level = true

	bolt.modulate.a = 1.0

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
	
	if bolt.get_parent() == null:
		ball.get_tree().root.add_child(bolt)
	
	var tween: Tween = bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		if bolt != null and is_instance_valid(bolt):
			if bolt.get_parent() != null:
				bolt.get_parent().remove_child(bolt)
			_bolt_pool.append(bolt)
	)
