class_name RelicChiliCounter
extends Relic

## Relique "Contre Pimenté" :
## Chaque fois que le joueur réussit un Super-Contre (Parry) avec un flipper,
## embrase immédiatement tous les ennemis présents dans l'arène (Burn DoT pendant 3 secondes).

@export var burn_duration: float = 3.0
@export var burn_damage: int = 1

func _init() -> void:
	id = &"chili_counter"
	display_name = "Contre Pimenté"
	description = "Réussir un Super-Contre avec un batteur embrase tous les ennemis présents dans l'arène !"

func on_flipper_parried(flipper: Node2D, parried_enemy: Node2D, _context: HitContext) -> void:
	if flipper == null or not flipper.is_inside_tree():
		return

	var burned_count: int = 0
	for enemy in Enemy.get_active_enemies():
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
			enemy.apply_burn(burn_duration, burn_damage, 0.5)
			burned_count += 1

	print("Relic [Contre Pimenté] déclenchée ! %d ennemis embrasés." % burned_count)
