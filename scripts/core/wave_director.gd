class_name WaveDirector
extends Node

## Directeur de vagues dynamique basé sur un budget de menace exponentiel.
## Charge la configuration depuis 'res://data/waves_config.json' :
## - Calcule le budget de points de la manche en cours
## - Sélectionne des compositions de groupes compatibles selon les points disponibles et le seuil min_wave_points
## - Gère les apparitions séquencées avec délai
## - Notifie quand tous les ennemis sont apparus et quand le terrain est pacifié.

signal enemy_spawn_requested(scene_path: String, spawn_x: float)
signal wave_started(wave_number: int, total_budget: int)
signal wave_all_enemies_spawned(wave_number: int)
signal wave_cleared(wave_number: int)

const CONFIG_PATH: String = "res://data/waves_config.json"

var current_wave: int = 1
var wave_points_budget: int = 0
var is_wave_active: bool = false
var all_enemies_spawned: bool = false

# Configuration chargée
var difficulty_curve: Dictionary = {
	"base_budget": 8,
	"budget_growth_rate": 1.45,
	"linear_bonus_per_wave": 4
}
var unit_costs: Dictionary = {}
var squad_compositions: Array = []

# File d'apparitions ordonnées : [{ "time_left": float, "scene_path": String, "spawn_x": float }]
var _pending_spawns: Array[Dictionary] = []
var _target_enemy_container: Node2D = null

func initialize(enemy_container: Node2D) -> void:
	_target_enemy_container = enemy_container
	load_config()

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("WaveDirector: Fichier de configuration introuvable: %s" % CONFIG_PATH)
		return
		
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var text: String = file.get_as_text()
	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK:
		push_error("WaveDirector: Erreur de parsing JSON dans %s: %s" % [CONFIG_PATH, json.get_error_message()])
		return
		
	var data: Dictionary = json.data as Dictionary
	if data.has("difficulty_curve"):
		difficulty_curve = data["difficulty_curve"]
	if data.has("unit_costs"):
		unit_costs = data["unit_costs"]
	if data.has("squad_compositions"):
		squad_compositions = data["squad_compositions"]
	print("WaveDirector: Configuration chargée avec succès (%d compositions)" % squad_compositions.size())

func calculate_budget_for_wave(wave_num: int) -> int:
	var base: float = float(difficulty_curve.get("base_budget", 8))
	var growth: float = float(difficulty_curve.get("budget_growth_rate", 1.18))
	var linear_b: float = float(difficulty_curve.get("linear_bonus_per_wave", 2.5))

	# Progression douce jusqu'à la manche 10 (apprentissage)
	if wave_num <= 10:
		var early_budget: float = base * pow(growth, wave_num - 1.0)
		return clampi(int(round(early_budget)), 8, 45)

	# Au-delà de la manche 10 : progression linéaire avec plafond dur de sécurité (90 points max)
	# Cela évite toute surcharge mémoire ou physique même à la manche 100+
	var budget: float = 45.0 + (linear_b * float(wave_num - 10))
	return clampi(int(round(budget)), 8, 90)

func is_boss_wave(wave_num: int) -> bool:
	return wave_num == 10 or (wave_num > 10 and wave_num % 10 == 0)

func _build_boss_wave_schedule() -> void:
	# Apparition du Boss Brocolino au centre de l'arène
	_pending_spawns.append({
		"time_left": 0.8,
		"scene_path": "res://scenes/enemies/boss_brocolino.tscn",
		"spawn_x": 310.0
	})

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	is_wave_active = true
	all_enemies_spawned = false
	_pending_spawns.clear()

	if is_boss_wave(wave_num):
		wave_points_budget = 50
		print("--- WaveDirector: DÉBUT DE LA MANCHE BOSS %d (Brocolino) ---" % current_wave)
		_build_boss_wave_schedule()
		wave_started.emit(current_wave, wave_points_budget)
		return

	wave_points_budget = calculate_budget_for_wave(wave_num)
	print("--- WaveDirector: DÉBUT DE LA MANCHE %d (Budget: %d points) ---" % [current_wave, wave_points_budget])
	_build_wave_schedule(wave_points_budget)
	wave_started.emit(current_wave, wave_points_budget)

func _build_wave_schedule(budget: int) -> void:
	var remaining_budget: int = budget
	var timeline_cursor: float = 0.5 # Premier spawn après 0.5s de répit

	# 1. Sélection en boucle de groupes/compositions tant qu'il y a du budget
	var attempts: int = 0
	while remaining_budget > 0 and attempts < 100:
		attempts += 1
		var squad: Dictionary = _pick_squad_for_budget(remaining_budget, budget)
		if squad.is_empty():
			break

		var squad_cost: int = _calculate_squad_cost(squad)
		remaining_budget -= squad_cost

		# Planifie chaque unité du groupe
		var max_squad_delay: float = 0.0
		var spawns_list: Array = squad.get("spawns", [])
		for s in spawns_list:
			var u_key: String = s.get("unit", "tomato")
			var u_delay: float = float(s.get("delay", 0.0))
			var x_ratio: float = float(s.get("x_ratio", -1.0))
			max_squad_delay = maxf(max_squad_delay, u_delay)

			var spawn_x: float = randf_range(80.0, 520.0) if x_ratio < 0.0 else lerpf(80.0, 520.0, x_ratio)
			var scene_path: String = _get_unit_scene_path(u_key)

			_pending_spawns.append({
				"time_left": timeline_cursor + u_delay,
				"scene_path": scene_path,
				"spawn_x": spawn_x
			})

		# Intervalle de respiration entre deux groupes (1.8s à 3.2s)
		var squad_break: float = randf_range(1.8, 3.2)
		timeline_cursor += max_squad_delay + squad_break

	# 2. S'il reste un résidu de points (ex: 1 ou 2 pts), on comble avec 1 ou 2 Tomates max
	var residual_tomatoes: int = mini(remaining_budget, 2)
	for _i in range(residual_tomatoes):
		timeline_cursor += randf_range(0.8, 1.5)
		_pending_spawns.append({
			"time_left": timeline_cursor,
			"scene_path": _get_unit_scene_path("tomato"),
			"spawn_x": randf_range(80.0, 520.0)
		})

	# Cap absolu de sécurité sur le nombre d'ennemis par manche (max 28 ennemis)
	if _pending_spawns.size() > 28:
		_pending_spawns.resize(28)

	# Tri chronologique des apparitions
	_pending_spawns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["time_left"] < b["time_left"]
	)

func _pick_squad_for_budget(rem_budget: int, total_wave_budget: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var total_weight: float = 0.0
	
	for squad in squad_compositions:
		var cost: int = _calculate_squad_cost(squad)
		var min_points: int = int(squad.get("min_wave_points", 0))
		
		# Doit respecter le coût restant ET le palier minimal de points de la manche
		if cost <= rem_budget and total_wave_budget >= min_points:
			candidates.append(squad)
			total_weight += float(squad.get("weight", 1.0))
			
	if candidates.is_empty():
		return {}
		
	# Tirage pondéré
	var roll: float = randf_range(0.0, total_weight)
	var accum: float = 0.0
	for c in candidates:
		accum += float(c.get("weight", 1.0))
		if roll <= accum:
			return c
			
	return candidates.back()

func _calculate_squad_cost(squad: Dictionary) -> int:
	var total: int = 0
	var spawns_list: Array = squad.get("spawns", [])
	for s in spawns_list:
		var u_key: String = s.get("unit", "tomato")
		var u_info: Dictionary = unit_costs.get(u_key, {})
		total += int(u_info.get("cost", 1))
	return maxi(1, total)

func _get_unit_scene_path(u_key: String) -> String:
	var info: Dictionary = unit_costs.get(u_key, {})
	return info.get("scene_path", "res://scenes/enemies/enemy_tomato.tscn")

func stop_waves() -> void:
	is_wave_active = false
	all_enemies_spawned = false
	_pending_spawns.clear()

func _process(delta: float) -> void:
	if not is_wave_active:
		return
		
	# 1. Gestion des spawns en attente
	if not _pending_spawns.is_empty():
		var i: int = 0
		while i < _pending_spawns.size():
			_pending_spawns[i]["time_left"] -= delta
			if _pending_spawns[i]["time_left"] <= 0.0:
				var sp: Dictionary = _pending_spawns[i]
				enemy_spawn_requested.emit(sp["scene_path"], sp["spawn_x"])
				_pending_spawns.remove_at(i)
			else:
				i += 1
		if _pending_spawns.is_empty() and not all_enemies_spawned:
			all_enemies_spawned = true
			wave_all_enemies_spawned.emit(current_wave)
			print("WaveDirector: Tous les ennemis de la manche %d sont apparus !" % current_wave)
			
	# 2. Vérification de fin de manche (tous apparus ET terrain nettoyé d'ennemis vivants)
	elif all_enemies_spawned:
		if not _has_living_enemies():
			is_wave_active = false
			print("WaveDirector: MANCHE %d COMPLÈTE & NETTOYÉE !" % current_wave)
			wave_cleared.emit(current_wave)

func _has_living_enemies() -> bool:
	if _target_enemy_container == null:
		return false
	for child in _target_enemy_container.get_children():
		if child is Enemy and is_instance_valid(child) and not child.is_dying():
			return true
	return false
