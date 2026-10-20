class_name HitstopManager
extends RefCounted

## Gestionnaire de micro-gel temporel (Hitstop / Frame Freeze).
## Ralentit brièvement le temps lors d'un impact critique ou d'une parade
## pour procurer une sensation de masse et d'impact percutant (Game Feel).

static var _is_in_hitstop: bool = false
static var _active_timer: SceneTreeTimer = null

## Déclenche un micro-gel temporel pendant 'duration' secondes réelles
static func trigger(duration: float = 0.045, time_scale: float = 0.04) -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return

	var tree: SceneTree = main_loop as SceneTree
	if tree == null:
		return

	# Si déjà en hitstop, on ne cumule pas pour éviter d'accélérer ou casser le flux
	if _is_in_hitstop:
		return

	_is_in_hitstop = true
	Engine.time_scale = time_scale

	# Timer qui ignore l'échelle de temps (ignore_time_scale = true) pour rétablir en 45ms réelles
	_active_timer = tree.create_timer(duration, true, false, true)
	_active_timer.timeout.connect(_on_hitstop_ended)

static func _on_hitstop_ended() -> void:
	Engine.time_scale = 1.0
	_is_in_hitstop = false
	_active_timer = null

## Rétablissement d'urgence si la scène change ou en cas de pause
static func cancel() -> void:
	Engine.time_scale = 1.0
	_is_in_hitstop = false
	_active_timer = null
