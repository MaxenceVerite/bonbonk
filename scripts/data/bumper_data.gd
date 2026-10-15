class_name BumperData
extends Resource

## Données et configuration d'un type de bumper bonbon.

enum TriggerType { ON_HIT, PERIODIC, BOTH }

@export var id: StringName = &"dragiburst"
@export var display_name: String = "Dragiburst"
@export var description: String = "Souffle de dragon circulaire ! Inflige de lourds dégâts et brûle les ennemis proches."
@export var icon_texture: Texture2D
@export var sprite_texture: Texture2D

@export var trigger_type: TriggerType = TriggerType.ON_HIT
@export var effect_strategy: BumperEffect = null
@export var bounce_force: float = 650.0 # Force de répulsion sur la bille
@export var attraction_radius: float = 240.0 # Rayon d'attraction vers le bumper
@export var attraction_strength: float = 480.0
@export var periodic_interval: float = 3.0 # Intervalle si PERIODIC ou BOTH
@export var score_on_hit: int = 50
@export var has_spin_animation: bool = false # Si vrai, tourne en continu sur lui-même (ex: Sucette Twistypop)
@export var spin_speed: float = 2.4 # Vitesse de rotation en rad/s
