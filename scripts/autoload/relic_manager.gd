extends Node

## Autoload orchestrateur des reliques et modificateurs Roguelike.
## Écoute l'EventBus global et distribue les événements aux reliques actives.

signal relic_acquired(relic: Relic)
signal relic_removed(relic: Relic)
signal relics_cleared

var active_relics: Array[Relic] = []

func _ready() -> void:
	EventBus.ball_hit_enemy.connect(_on_ball_hit_enemy)
	EventBus.ball_hit_bumper.connect(_on_ball_hit_bumper)
	EventBus.flipper_parried.connect(_on_flipper_parried)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.start_game_requested.connect(clear_all_relics)

func add_relic(relic: Relic) -> void:
	if relic == null or has_relic(relic.id):
		return
	active_relics.append(relic)
	relic.on_acquired()
	relic_acquired.emit(relic)
	print("RelicManager: Relique acquise -> [%s] %s" % [relic.id, relic.display_name])

func remove_relic(relic_id: StringName) -> void:
	for i in range(active_relics.size() - 1, -1, -1):
		if active_relics[i].id == relic_id:
			var rel: Relic = active_relics[i]
			active_relics.remove_at(i)
			rel.on_removed()
			relic_removed.emit(rel)
			print("RelicManager: Relique retirée -> [%s]" % [relic_id])

func has_relic(relic_id: StringName) -> bool:
	for r in active_relics:
		if r.id == relic_id:
			return true
	return false

func get_active_relics() -> Array[Relic]:
	return active_relics

func clear_all_relics() -> void:
	for r in active_relics:
		r.on_removed()
	active_relics.clear()
	relics_cleared.emit()

func notify_wave_started(wave_number: int) -> void:
	for r in active_relics:
		r.on_wave_started(wave_number)

func notify_wave_cleared(wave_number: int) -> void:
	for r in active_relics:
		r.on_wave_cleared(wave_number)

func _on_ball_hit_enemy(context: HitContext) -> void:
	for r in active_relics:
		r.on_ball_hit_enemy(context)

func _on_ball_hit_bumper(ball: RigidBody2D, bumper: Node2D) -> void:
	for r in active_relics:
		r.on_ball_hit_bumper(ball, bumper)

func _on_flipper_parried(flipper: Node2D, enemy: Node2D, context: HitContext) -> void:
	for r in active_relics:
		r.on_flipper_parried(flipper, enemy, context)

func _on_enemy_damaged(enemy: Node2D, context: HitContext) -> void:
	for r in active_relics:
		r.on_enemy_damaged(enemy, context)

func _on_enemy_killed(enemy: Node2D, context: HitContext) -> void:
	for r in active_relics:
		r.on_enemy_killed(enemy, context)

func _on_status_applied(target: Node2D, status_id: StringName) -> void:
	for r in active_relics:
		r.on_status_applied(target, status_id)
