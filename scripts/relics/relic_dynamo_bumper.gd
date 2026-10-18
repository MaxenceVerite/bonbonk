class_name RelicDynamoBumper
extends Relic

## Relique "Bumper Dynamo" :
## Chaque fois qu'une bille heurte un bumper, propulse un arc électrique
## qui foudroie et étourdit l'ennemi le plus proche !

@export var zap_damage: int = 2
@export var stun_duration: float = 1.5

func _init() -> void:
	id = &"dynamo_bumper"
	display_name = "Bumper Dynamo"
	description = "Chaque choc de bille sur un bumper foudroie et étourdit l'ennemi le plus proche !"

func on_ball_hit_bumper(_ball: RigidBody2D, bumper: Node2D) -> void:
	if bumper == null or not bumper.is_inside_tree():
		return

	var nearest_enemy: Enemy = Enemy.get_nearest(bumper.global_position)
	if nearest_enemy != null:
		LightningBoltEffect.spawn(
			bumper.get_tree(),
			bumper.global_position,
			nearest_enemy.global_position,
			Color(0.4, 0.95, 1.2, 1.0),
			0.24
		)
		nearest_enemy.apply_electric_zap(zap_damage, stun_duration)
		print("Relic [Bumper Dynamo] déclenchée ! Éclair propulsé sur %s." % nearest_enemy.name)
