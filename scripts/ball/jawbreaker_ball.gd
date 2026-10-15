class_name JawbreakerBall
extends Ball

## Casse-bonbon (Inspiration Jawbreaker / Boule Magique)
## - Plus grosse (radius 20 px) et plus lourde (mass 1.8).
## - Ne casse JAMAIS contre les murs ou les flippers.
## - Ne casse que lors d'un impact contre un ENNEMI ou un BUMPER,
##   et UNIQUEMENT après avoir été frappé au moins une fois par un flipper.
## - À la casse, il projette 2 sous-bonbons tirés aléatoirement parmi les bonbons du deck actif,
##   propulsés dans des directions opposées avec 1 de durabilité.

@export var split_count: int = 2
@export var split_speed: float = 650.0

var _has_fragmented: bool = false
var has_been_struck_by_flipper: bool = false

func _ready() -> void:
	super._ready()
	max_durability = 1
	current_durability = 1

func _on_body_entered(body: Node) -> void:
	if _has_fragmented or _is_shattering:
		return

	# 1. Contact avec le flipper / batteur : arme la bille sans la casser
	if body is WoodenGateFlipper:
		has_been_struck_by_flipper = true
		return

	# 2. Contact avec un Bumper : ne casse que si la bille a été frappée au moins une fois
	if body is CandyBumper:
		var bumper: CandyBumper = body as CandyBumper
		bumper.on_hit_by_ball(self, global_position)
		if has_been_struck_by_flipper:
			_fragment_and_split()
		return

	# 3. Contact avec un Ennemi : inflige les dégâts de la bille, et casse uniquement si déjà frappée par le flipper
	elif body is Enemy:
		var enemy: Enemy = body as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
			enemy.take_hit(impact_damage, self, linear_velocity)
		if has_been_struck_by_flipper:
			_fragment_and_split()
		return

	# Les murs, bordures et rampes ne cassent JAMAIS le Casse-bonbon.

func hit_enemy_with_target(enemy: Enemy, _durability_loss: int = 1) -> void:
	if _has_fragmented or _is_shattering:
		return
	if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
		enemy.take_hit(impact_damage, self, linear_velocity)
	if has_been_struck_by_flipper:
		_fragment_and_split()

func configure_from_card(card_def: CandyCardData, lvl: int) -> void:
	super.configure_from_card(card_def, lvl)
	if card_def != null:
		split_count = maxi(2, int(roundf(card_def.get_keyword_stat_value(&"split_count", lvl, 2.0))))

func _fragment_and_split() -> void:
	if _has_fragmented or _is_shattering:
		return
	_has_fragmented = true

	var impact_pos: Vector2 = global_position
	var base_velocity: Vector2 = linear_velocity
	if base_velocity.length() < 50.0:
		base_velocity = Vector2.UP * 300.0

	# Effets visuels & sonores d'éclatement
	_spawn_confetti_burst(impact_pos)

	# Récupérer les bonbons du deck actif
	var deck_balls: Array[StringName] = SaveManager.get_active_deck_balls()
	var candidate_pool: Array[StringName] = []
	for b in deck_balls:
		if b != &"jawbreaker":
			candidate_pool.append(b)
	if candidate_pool.is_empty():
		candidate_pool.append(&"fizz")

	var normal_dir: Vector2 = base_velocity.normalized().orthogonal()
	var dirs: Array[Vector2] = [
		(base_velocity.normalized() + normal_dir * 0.85).normalized(),
		(base_velocity.normalized() - normal_dir * 0.85).normalized()
	]

	var chosen_sub_types: Array[StringName] = []
	for i in range(split_count):
		chosen_sub_types.append(candidate_pool.pick_random())

	split_requested.emit(chosen_sub_types, impact_pos, dirs, split_speed)

	# Détruire le jawbreaker
	shatter()

func _spawn_confetti_burst(pos: Vector2) -> void:
	var burst: Node2D = Node2D.new()
	burst.global_position = pos
	burst.top_level = true

	var colors: Array[Color] = [
		Color(1.0, 0.25, 0.45, 1.0),
		Color(0.2, 0.9, 0.4, 1.0),
		Color(0.2, 0.6, 1.0, 1.0),
		Color(1.0, 0.85, 0.2, 1.0),
		Color(0.9, 0.3, 0.9, 1.0)
	]

	for i in range(12):
		var spark: Polygon2D = Polygon2D.new()
		var s: float = randf_range(3.0, 6.0)
		spark.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		spark.color = colors[i % colors.size()]
		var angle: float = randf_range(0.0, TAU)
		var dist: float = randf_range(25.0, 60.0)
		burst.add_child(spark)

		var tw_spark: Tween = spark.create_tween().set_parallel(true)
		tw_spark.tween_property(spark, "position", Vector2(cos(angle), sin(angle)) * dist, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_spark.tween_property(spark, "rotation", randf_range(-PI, PI), 0.28)
		tw_spark.tween_property(spark, "modulate:a", 0.0, 0.28)

	get_tree().root.add_child.call_deferred(burst)

	var tw: Tween = burst.create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(burst.queue_free)
