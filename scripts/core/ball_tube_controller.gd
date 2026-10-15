class_name BallTubeController
extends RefCounted

## Contrôleur dédié à la machine de bonbons avec Dual-Pod Launcher.
## Gère deux alvéoles tactiles prêtes (Pod 0 = Bas, Pod 1 = Haut)
## et un tube vertical de réserve (jusqu'à 3 bonbons en attente).

signal factory_state_changed(types_queue: Array[StringName], is_synthesizing: bool, next_type: StringName, progress: float, pod_slots: Array[StringName])
signal ball_ready_to_launch(ball_type: StringName)

var max_reserve_capacity: int = 3
var synthesis_duration: float = 2.4

var pod_slots: Array[StringName] = [&"", &""]
var reserve_queue: Array[StringName] = []

var next_synthesis_type: StringName = &"fizz"
var is_synthesizing: bool = false
var synthesis_timer: float = 0.0

var _active_deck_types: Array[StringName] = []

# Accesseur de compatibilité
var queue: Array[StringName]:
	get:
		var list: Array[StringName] = []
		if pod_slots.size() > 0 and pod_slots[0] != &"":
			list.append(pod_slots[0])
		if pod_slots.size() > 1 and pod_slots[1] != &"":
			list.append(pod_slots[1])
		list.append_array(reserve_queue)
		return list

func initialize(_capacity: int = 5, duration: float = 2.4) -> void:
	synthesis_duration = duration

func reset(deck_types: Array[StringName]) -> void:
	_active_deck_types = deck_types.duplicate()
	if _active_deck_types.is_empty():
		_active_deck_types.append(&"fizz")

	pod_slots = [&"", &""]
	reserve_queue.clear()
	synthesis_timer = 0.0
	is_synthesizing = false

	# Remplissage initial des deux pods prêts
	pod_slots[0] = _pick_random_deck_ball()
	pod_slots[1] = _pick_random_deck_ball()

	# Remplissage de la réserve
	for i in range(max_reserve_capacity):
		reserve_queue.append(_pick_random_deck_ball())

	_pick_next_synthesis()
	emit_state(0.0)

func update(delta: float, _has_active_ball: bool = true) -> void:
	var needs_fill: bool = (
		pod_slots[0] == &"" or 
		pod_slots[1] == &"" or 
		reserve_queue.size() < max_reserve_capacity
	)

	if needs_fill:
		is_synthesizing = true
		synthesis_timer += delta
		var progress: float = clampf(synthesis_timer / synthesis_duration, 0.0, 1.0)
		emit_state(progress)

		if synthesis_timer >= synthesis_duration:
			synthesis_timer = 0.0
			_deposit_synthesized_ball(next_synthesis_type)
			_pick_next_synthesis()
			is_synthesizing = (
				pod_slots[0] == &"" or 
				pod_slots[1] == &"" or 
				reserve_queue.size() < max_reserve_capacity
			)
			emit_state(0.0)
	else:
		if is_synthesizing:
			is_synthesizing = false
			synthesis_timer = 0.0
			emit_state(0.0)

func pause_synthesis() -> void:
	is_synthesizing = false
	synthesis_timer = 0.0
	emit_state(0.0)

func launch_pod(pod_index: int) -> StringName:
	if pod_index < 0 or pod_index >= pod_slots.size():
		return &""

	var chosen: StringName = pod_slots[pod_index]
	if chosen.is_empty():
		return &""

	# Consommation de la bille du Pod
	pod_slots[pod_index] = &""

	# Réapprovisionnement immédiat depuis la réserve si disponible
	if not reserve_queue.is_empty():
		pod_slots[pod_index] = reserve_queue.pop_front()

	emit_state(0.0)
	return chosen

func has_any_ball_ready() -> bool:
	return (pod_slots.size() > 0 and pod_slots[0] != &"") or (pod_slots.size() > 1 and pod_slots[1] != &"")

func has_balls() -> bool:
	return has_any_ball_ready() or not reserve_queue.is_empty()

func pop_next_ball() -> StringName:
	# Compatibilité : tire du Pod 0 en priorité, sinon Pod 1
	if pod_slots[0] != &"":
		return launch_pod(0)
	elif pod_slots[1] != &"":
		return launch_pod(1)
	return &""

func emit_state(progress: float = 0.0) -> void:
	factory_state_changed.emit(queue, is_synthesizing, next_synthesis_type, progress, pod_slots)

func _deposit_synthesized_ball(ball_type: StringName) -> void:
	if pod_slots[0] == &"":
		pod_slots[0] = ball_type
	elif pod_slots[1] == &"":
		pod_slots[1] = ball_type
	elif reserve_queue.size() < max_reserve_capacity:
		reserve_queue.append(ball_type)

func _pick_next_synthesis() -> void:
	if _active_deck_types.is_empty():
		next_synthesis_type = &"fizz"
	else:
		next_synthesis_type = _active_deck_types[randi() % _active_deck_types.size()]

func _pick_random_deck_ball() -> StringName:
	if _active_deck_types.is_empty():
		return &"fizz"
	return _active_deck_types[randi() % _active_deck_types.size()]
