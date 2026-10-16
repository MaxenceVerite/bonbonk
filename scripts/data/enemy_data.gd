class_name EnemyData
extends Resource

## Configuration de données pour un type d'ennemi.

# Échelle de vitesse standardisée du jeu
enum SpeedTier {
	VERY_SLOW,  # ~35 px/s (ex: Pastèque initiale)
	SLOW,       # ~55 px/s (ex: Ananas)
	SOMEWHAT_SLOW, # ~75 px/s (ex: Pastèque accélérée)
	NORMAL,     # ~95 px/s
	SOMEWHAT_FAST, # ~115 px/s (ex: Tomate)
	FAST,       # ~140 px/s
	VERY_FAST   # ~180 px/s
}

enum MovePattern {
	WALK_STRAIGHT,   # Marche directe vers le bas
	ROLL_STRAIGHT,   # Roulement sur soi-même avec inertie (Pastèque)
	DIAGONAL_HOPPER  # Petits sauts en zig-zag diagonal imprévisible (Ananas)
}

@export var enemy_name: StringName = &"Tomato"
@export var max_health: int = 1
@export var speed_tier: SpeedTier = SpeedTier.SOMEWHAT_FAST
@export var move_speed: float = 115.0 # Calculé par speed_tier ou override
@export var damage_on_escape: int = 1 # Dégâts infligés au joueur quand il franchit le bas
@export var score_value: int = 100

# Propriétés de propulsion par le batteur
@export var can_be_kicked_by_gate: bool = true
@export var mass_weight: float = 1.0
@export var kick_rebound_factor: float = 1.0
@export var collision_damage_when_projected: int = 1 # Dégâts infligés aux autres ennemis lors d'un choc en vol


# Trait spécial : PIQUANT (enfonce la durabilité de la balle et blesse les ennemis percutés)
@export var is_spiky: bool = false
@export var spiky_ball_durability_loss: int = 2

# Trait spécial : PASTÈQUE (accélération passive si pas touchée)
@export var can_accelerate_when_idle: bool = false

# Charge suicidaire sur les portes (Suicide Dive & Parry Timing)
@export var can_suicide_dive: bool = true
@export var dive_trigger_distance: float = 200.0   # Déclenchement à ~200px de la porte
@export var dive_windup_time: float = 0.35         # Durée de l'anticipation (telegraph)
@export var dive_speed: float = 520.0              # Vitesse de la ruée vers la porte
@export var can_be_parried: bool = true            # False pour les boss/tanks inébranlables comme la Pastèque

@export var move_pattern: MovePattern = MovePattern.WALK_STRAIGHT

# Visuels / Juicy Juice
@export var wobble_frequency: float = 6.0
@export var wobble_amplitude: float = 0.12
@export var squash_frequency: float = 4.0
# Propriétés de mort et feedback
@export var is_lightweight: bool = false # Si true, expulsé en cloche lors du coup fatal direct d'une bille
@export var juice_primary_color: Color = Color(0.92, 0.2, 0.18, 1.0)
@export var juice_secondary_color: Color = Color(1.0, 0.45, 0.3, 1.0)
@export var juice_accent_color: Color = Color(0.95, 0.85, 0.3, 1.0)
@export var juice_droplet_count: int = 18
@export_enum("auto", "fly_away", "explode", "flatten") var death_effect_type: String = "auto"


func get_speed_from_tier() -> float:
	match speed_tier:
		SpeedTier.VERY_SLOW:
			return 38.0
		SpeedTier.SLOW:
			return 55.0
		SpeedTier.SOMEWHAT_SLOW:
			return 75.0
		SpeedTier.NORMAL:
			return 95.0
		SpeedTier.SOMEWHAT_FAST:
			return 115.0
		SpeedTier.FAST:
			return 140.0
		SpeedTier.VERY_FAST:
			return 180.0
	return move_speed
