class_name HealthComponent
extends Node

## Gère les points de vie et émet des signaux lors des dégâts ou de la destruction.

signal health_changed(current: int, max_hp: int)
signal damage_taken(amount: int)
signal died

@export var max_health: int = 1

var current_health: int = 1

func _ready() -> void:
	current_health = max_health

func set_max_health(amount: int) -> void:
	max_health = amount
	current_health = amount

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	
	current_health = maxi(0, current_health - amount)
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)
	
	if current_health == 0:
		died.emit()
