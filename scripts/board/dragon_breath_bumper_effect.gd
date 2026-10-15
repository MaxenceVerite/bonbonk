class_name DragonBreathBumperEffect
extends BumperEffect

## Stratégie de souffle draconique circulaire (Dragiburst).
## Déclenche une onde de flammes qui s'étend rapidement depuis le dessus du bumper,
## inflige des dégâts directs, repousse les ennemis et applique le statut Burn.

@export var radius: float = 260.0
@export var impact_damage: int = 2
@export var burn_duration: float = 3.5
@export var burn_damage_per_tick: int = 1
@export var burn_tick_interval: float = 0.5
@export var push_force: float = 450.0
@export var spawn_vertical_offset: float = -18.0 # Légèrement au-dessus du bonbon

const DragonBreathWaveScript = preload("res://scripts/effects/dragon_breath_wave.gd")

func execute(bumper: Node2D) -> void:
	if bumper == null or not bumper.is_inside_tree():
		return

	DragonBreathWaveScript.spawn(
		bumper,
		Vector2(0.0, spawn_vertical_offset),
		radius,
		impact_damage,
		burn_duration,
		burn_damage_per_tick
	)
