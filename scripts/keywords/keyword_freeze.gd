class_name KeywordFreeze
extends BallKeyword

## Mot-clé "Givré / Glacé" (Mentox Givrée) :
## Givre l'ennemi percuté pendant 2 secondes.

@export var freeze_duration: float = 2.0
@export var impact_damage: int = 1

func _init() -> void:
	id = &"freeze"
	display_name = "Givré"
	description = "Immobilise l'ennemi percuté sous un bloc de givre pendant quelques secondes."

func apply_card_scaling(card_def: CandyCardData, lvl: int) -> void:
	if card_def == null:
		return
	impact_damage = card_def.get_damage_for_level(lvl)
	freeze_duration = card_def.get_keyword_stat_value(&"freeze_duration", lvl, 1.8)

func on_hit_enemy(ball: Ball, enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if ball == null or not is_instance_valid(ball):
		return
		
	enemy.apply_freeze(impact_damage, freeze_duration)
	FrostBurstEffect.spawn(ball.get_tree(), enemy.global_position)
