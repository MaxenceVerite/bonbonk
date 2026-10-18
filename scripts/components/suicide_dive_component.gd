class_name SuicideDiveComponent
extends Node

## Composant gérant la mécanique de plongeon suicide (Dive) des ennemis vers les batteurs.
## Gère la détection de proximité des batteurs, la télégraphie visuelle (windup)
## et la trajectoire de ruée vers la porte en bois ciblée.

enum DiveState { INACTIVE, WINDUP, DIVING }

var state: DiveState = DiveState.INACTIVE
var windup_timer: float = 0.0
var target_gate: WoodenGateFlipper = null
var target_pos: Vector2 = Vector2.ZERO

var _enemy: CharacterBody2D = null
var _visual_container: Node2D = null
var _telegraph_visual: DiveTelegraphVisual = null

func setup(enemy: CharacterBody2D, visual_container: Node2D, telegraph_visual: DiveTelegraphVisual) -> void:
	_enemy = enemy
	_visual_container = visual_container
	_telegraph_visual = telegraph_visual

func reset() -> void:
	state = DiveState.INACTIVE
	windup_timer = 0.0
	target_gate = null
	target_pos = Vector2.ZERO
	if _telegraph_visual != null:
		_telegraph_visual.stop_telegraph()
	if _visual_container != null:
		_visual_container.scale = Vector2.ONE
		_visual_container.modulate = Color.WHITE
		_visual_container.rotation = 0.0

func is_active() -> bool:
	return state != DiveState.INACTIVE

func is_winding_up() -> bool:
	return state == DiveState.WINDUP

func is_diving() -> bool:
	return state == DiveState.DIVING

## Recherche le batteur le plus proche et enclenche le windup si à portée
func check_for_dive(enemy_data: EnemyData) -> bool:
	if enemy_data == null or not enemy_data.can_suicide_dive:
		return false
	if state != DiveState.INACTIVE or _enemy == null:
		return false

	# Optimisation mobile : pas de calcul au-dessus de 700px
	var my_pos: Vector2 = _enemy.global_position
	if my_pos.y < 700.0:
		return false

	# Utilisation du registre statique optimisé O(1) de WoodenGateFlipper
	var gates: Array[WoodenGateFlipper] = WoodenGateFlipper.active_gates
	if gates.is_empty():
		return false

	var trigger_dist: float = enemy_data.dive_trigger_distance
	var nearest_gate: WoodenGateFlipper = null
	var min_dist: float = 999999.0

	for gate in gates:
		if gate == null or not is_instance_valid(gate):
			continue
		var gate_center: Vector2 = gate.global_position + gate.transform.x * 65.0
		var d: float = my_pos.distance_to(gate_center)
		# L'ennemi doit être situé au-dessus de la porte (y < gate.y)
		if my_pos.y < gate.global_position.y and d < min_dist:
			min_dist = d
			nearest_gate = gate

	if nearest_gate != null and min_dist <= trigger_dist:
		state = DiveState.WINDUP
		windup_timer = 0.0
		target_gate = nearest_gate
		target_pos = nearest_gate.global_position + nearest_gate.transform.x * randf_range(40.0, 95.0)

		if _telegraph_visual != null:
			_telegraph_visual.start_windup(enemy_data.can_be_parried)
		return true

	return false

## Met à jour le windup ou la trajectoire de plongeon. Retourne la vélocité résultante.
func update_dive(delta: float, enemy_data: EnemyData) -> Vector2:
	if _enemy == null:
		return Vector2.ZERO

	match state:
		DiveState.WINDUP:
			windup_timer += delta
			var windup_duration: float = enemy_data.dive_windup_time if enemy_data != null else 0.35
			var progress: float = clampf(windup_timer / windup_duration, 0.0, 1.0)

			if _telegraph_visual != null:
				_telegraph_visual.set_progress(progress)

			if _visual_container != null:
				var squash_f: float = 1.0 + sin(progress * PI) * 0.25
				_visual_container.scale = Vector2(1.0 / squash_f, squash_f)
				if progress >= 0.85:
					_visual_container.modulate = Color(1.8, 1.6, 0.8, 1.0)
				else:
					_visual_container.modulate = Color(1.8, 0.7, 0.7, 1.0)

			if windup_timer >= windup_duration:
				state = DiveState.DIVING
				if _telegraph_visual != null:
					_telegraph_visual.stop_telegraph()
				if _visual_container != null:
					_visual_container.scale = Vector2.ONE
					_visual_container.modulate = Color.WHITE

			return Vector2.ZERO

		DiveState.DIVING:
			var d_speed: float = enemy_data.dive_speed if enemy_data != null else 520.0
			var to_target: Vector2 = target_pos - _enemy.global_position
			var vel: Vector2
			if to_target.length() > 5.0:
				vel = to_target.normalized() * d_speed
			else:
				vel = Vector2.DOWN * d_speed

			if _visual_container != null:
				_visual_container.rotation = vel.angle() - (PI * 0.5)

			return vel

		_:
			return Vector2.ZERO
