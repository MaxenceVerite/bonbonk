class_name ObstacleAvoidance
extends RefCounted

## Calculateur d'évitement d'obstacles pour les ennemis (Steering Behavior).
## Permet aux ennemis de contourner naturellement les bumpers sans blocage physique.

static func compute_bumper_avoidance(
	enemy_pos: Vector2,
	bypass_bias: float,
	speed: float,
	bumpers: Array,
	lookahead_dist: float = 175.0,
	bumper_safe_radius: float = 95.0
) -> Vector2:
	if bumpers.is_empty():
		return Vector2.ZERO

	var avoid_force: Vector2 = Vector2.ZERO

	for node in bumpers:
		var bumper: Node2D = node as Node2D
		if bumper == null or not is_instance_valid(bumper):
			continue

		var to_bumper: Vector2 = bumper.global_position - enemy_pos
		var dist: float = to_bumper.length()

		# Détection si le bumper est devant (y > -20 pour inclure les contacts directs au sommet)
		if to_bumper.y < -20.0 or dist > lookahead_dist:
			continue

		var lateral_offset: float = to_bumper.x

		# Si l'ennemi est dans le cylindre ou heurte le sommet du bumper
		if absf(lateral_offset) < bumper_safe_radius:
			var chosen_dir_x: float = bypass_bias
			if absf(lateral_offset) > 2.0:
				chosen_dir_x = -1.0 if lateral_offset > 0.0 else 1.0

			# Contraintes de bordures arène (murs latéraux à ~130px et ~470px)
			if enemy_pos.x < 130.0:
				chosen_dir_x = 1.0
			elif enemy_pos.x > 470.0:
				chosen_dir_x = -1.0

			var proximity: float = 1.0 - clampf(dist / lookahead_dist, 0.0, 1.0)
			var steer_strength: float = (0.5 + proximity * 1.5) * speed * 2.8
			avoid_force.x += chosen_dir_x * steer_strength
			avoid_force.y += speed * 0.4
			break # Cible en priorité le bumper le plus proche

	return avoid_force
