class_name StatusEffect
extends RefCounted

## Classe de base modulaire pour toutes les altérations d'état (Strategy Pattern).
## Permet d'étendre facilement le jeu avec de nouveaux effets (Poison, Faiblesse, Huile, etc.)
## sans jamais devoir modifier StatusEffectComponent.

signal expired(effect: StatusEffect)

var id: StringName = &"base_status"
var duration: float = 0.0
var max_duration: float = 0.0
var is_expired: bool = false

func on_applied(_target: CharacterBody2D, _visual: Node2D) -> void:
	pass

func on_tick(_target: CharacterBody2D, _visual: Node2D, _delta: float) -> void:
	pass

func on_removed(_target: CharacterBody2D, _visual: Node2D) -> void:
	pass

func is_immobilizing() -> bool:
	return false

func get_speed_multiplier() -> float:
	return 1.0

func refresh_duration(new_duration: float) -> void:
	duration = maxf(duration, new_duration)
	max_duration = maxf(max_duration, new_duration)
