class_name BallTubeController
extends RefCounted

## Contrôleur dédié à la gestion du tube de munitions et de la machine de synthèse de billes.
## Découple la logique de production de bonbons de la physique de l'arène (Board).

signal factory_state_changed(types_queue: Array[StringName], is_synthesizing: bool, next_type: StringName, progress: float)
signal ball_ready_to_launch(ball_type: StringName)

var max_capacity: int = 5
var synthesis_duration: float = 2.8

var queue: Array[StringName] = []
var next_synthesis_type: StringName = &"standard"
var is_synthesizing: bool = false
var synthesis_timer: float = 0.0

var _active_deck_types: Array[StringName] = []

func initialize(capacity: int = 5, duration: float = 2.8) -> void:
	max_capacity = capacity
	synthesis_duration = duration

func reset(deck_types: Array[StringName]) -> void:
	_active_deck_types = deck_types.duplicate()
	if _active_deck_types.is_empty():
		_active_deck_types.append(&"standard")

	queue.clear()
	synthesis_timer = 0.0
	is_synthesizing = false

	# Remplissage initial du tube avec le deck
	for i in range(max_capacity):
		var picked: StringName = _active_deck_types[randi() % _active_deck_types.size()]
		queue.append(picked)

	_pick_next_synthesis()
	emit_state()

func update(delta: float, has_active_ball_on_field: bool) -> void:
	if queue.size() < max_capacity:
		is_synthesizing = true
		synthesis_timer += delta
		var progress: float = clampf(synthesis_timer / synthesis_duration, 0.0, 1.0)
		emit_state(progress)

		if synthesis_timer >= synthesis_duration:
			synthesis_timer = 0.0
			queue.append(next_synthesis_type)
			_pick_next_synthesis()
			is_synthesizing = (queue.size() < max_capacity)
			emit_state(0.0)

			# Si aucune bille n'est sur le plateau, notifier qu'une bille est prête
			if not has_active_ball_on_field:
				ball_ready_to_launch.emit(pop_next_ball())
	else:
		if is_synthesizing:
			is_synthesizing = false
			synthesis_timer = 0.0
			emit_state(0.0)

func pop_next_ball() -> StringName:
	if queue.is_empty():
		return &""
	var b_type: StringName = queue.pop_front()
	emit_state(0.0)
	return b_type

func has_balls() -> bool:
	return not queue.is_empty()

func emit_state(progress: float = 0.0) -> void:
	factory_state_changed.emit(queue, is_synthesizing, next_synthesis_type, progress)

func _pick_next_synthesis() -> void:
	if _active_deck_types.is_empty():
		next_synthesis_type = &"standard"
	else:
		next_synthesis_type = _active_deck_types[randi() % _active_deck_types.size()]
