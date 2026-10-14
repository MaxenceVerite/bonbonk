class_name BumperData
extends Resource

## Données et configuration d'un type de bumper bonbon.

enum TriggerType { ON_HIT, PERIODIC, BOTH }

@export var id: StringName = &"dragibump"
@export var display_name: String = "Dragibump"
@export var description: String = "Attire les ennemis proches quand il est percuté !"
@export var icon_texture: Texture2D
@export var sprite_texture: Texture2D

@export var trigger_type: TriggerType = TriggerType.ON_HIT
@export var effect_strategy: BumperEffect = null
@export var bounce_force: float = 650.0 # Force de répulsion sur la bille
@export var attraction_radius: float = 240.0 # Rayon d'attraction vers le bumper
@export var attraction_strength: float = 480.0
@export var periodic_interval: float = 3.0 # Intervalle si PERIODIC ou BOTH
@export var score_on_hit: int = 50
