class_name RelicSugarShield
extends Relic

## Relique "Flasque Sucrée" :
## Régénère 20 PV au joueur à la fin de chaque manche pacifiée.

@export var heal_amount: int = 20

func _init() -> void:
	id = &"sugar_shield"
	display_name = "Flasque Sucrée"
	description = "Régénère +20 PV à la fin de chaque manche pacifiée !"

func on_wave_cleared(_wave_number: int) -> void:
	EventBus.player_healed.emit(heal_amount)
	print("Relic [Flasque Sucrée] déclenchée ! +%d PV restaurés." % heal_amount)
