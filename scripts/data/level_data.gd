class_name LevelData
extends Resource

const LevelWaveData = preload("res://scripts/data/level_wave_data.gd")

## Configuration d'un niveau individuel pour le mode Campagne.

@export var id: StringName = &"w1_01"
@export var world_id: StringName = &"world_1"
@export var level_number: int = 1
@export var display_title: String = "Premiers Pas Croquants"
@export var description: String = "Repousse les premières tomates maraîchères."

## Seuils de score pour décrocher les étoiles : [1 étoile, 2 étoiles, 3 étoiles]
@export var star_thresholds: Array[int] = [600, 1400, 2400]

## Séquence des sous-vagues d'ennemis du niveau
@export var waves: Array[LevelWaveData] = []

## Récompenses au premier succès (First Clear)
@export var first_clear_gold: int = 100
@export var first_clear_diamonds: int = 5
@export var first_clear_booster_id: StringName = &"silver_pop"

## Retourne le numéro du monde (ex: 1 pour world_1)
func get_world_number() -> int:
	var w_str: String = String(world_id).trim_prefix("world_")
	return int(w_str) if w_str.is_valid_int() else 1

## Calcule le nombre d'étoiles (de 1 à 3) mérité selon le score et les PV restants
func calculate_stars(score: int, hp_left: int, max_hp: int) -> int:
	if hp_left <= 0:
		return 0
	var stars: int = 1 # Réussite du niveau = 1 étoile garantie
	if star_thresholds.size() >= 2 and score >= star_thresholds[1]:
		stars = 2
	if star_thresholds.size() >= 3 and score >= star_thresholds[2] and hp_left >= int(max_hp * 0.7):
		stars = 3
	return stars

## Retourne le nombre total d'ennemis prévus dans ce niveau
func get_total_enemy_count() -> int:
	var total: int = 0
	for w in waves:
		if w != null:
			total += w.spawns.size()
	return total
