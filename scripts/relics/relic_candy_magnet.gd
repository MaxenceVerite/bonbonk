class_name RelicCandyMagnet
extends Relic

## Relique "Aimant Sucré" :
## Augmente l'attraction magnétique de toutes les billes vers les fruits ennemis (+50%).

func _init() -> void:
	id = &"candy_magnet"
	display_name = "Aimant Sucré"
	description = "Les bonbons-balles sont irrésistiblement attirés vers les ennemis (+50% magnétisme) !"

func on_wave_started(_wave_number: int) -> void:
	for b in Ball.active_balls:
		if b != null and is_instance_valid(b):
			b.aim_assist_force *= 1.5

func on_ball_hit_bumper(ball: RigidBody2D, _bumper: Node2D) -> void:
	if ball is Ball:
		(ball as Ball).aim_assist_force = 650.0
