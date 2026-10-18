class_name KeywordJawbreaker
extends BallKeyword

## Mot-clé "Casse-bonbon" (Jawbreaker / Joybreaker).
## - Arme la bille dès qu'elle est frappée par un batteur.
## - Éclate lors du premier contact avec un ennemi ou un bumper,
##   en projetant des sous-bonbons issus du deck actif.

@export var split_count: int = 2
@export var split_speed: float = 650.0

var _has_fragmented: bool = false
var has_been_struck_by_flipper: bool = false

func _init() -> void:
	id = &"jawbreaker"
	display_name = "Casse-bonbon"
	description = "Bille lourde qui éclate en sous-bonbons après avoir été frappée par un batteur."

func apply_card_scaling(card_def: CandyCardData, lvl: int) -> void:
	if card_def != null:
		split_count = maxi(2, int(roundf(card_def.get_keyword_stat_value(&"split_count", lvl, 2.0))))

func on_hit_flipper(_ball: Ball, _flipper: Node) -> void:
	has_been_struck_by_flipper = true

func on_hit_bumper(ball: Ball, _bumper: CandyBumper) -> void:
	if has_been_struck_by_flipper and not _has_fragmented:
		_fragment_and_split(ball)

func on_hit_enemy(ball: Ball, _enemy: Enemy) -> void:
	if has_been_struck_by_flipper and not _has_fragmented:
		_fragment_and_split(ball)

func _fragment_and_split(ball: Ball) -> void:
	if _has_fragmented or ball == null or not is_instance_valid(ball):
		return
	_has_fragmented = true

	var impact_pos: Vector2 = ball.global_position
	var base_velocity: Vector2 = ball.linear_velocity
	if base_velocity.length() < 50.0:
		base_velocity = Vector2.UP * 300.0

	# Effets visuels de confettis
	ConfettiBurstEffect.spawn(ball.get_tree(), impact_pos)

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

	ball.split_requested.emit(chosen_sub_types, impact_pos, dirs, split_speed)
	ball.shatter()
