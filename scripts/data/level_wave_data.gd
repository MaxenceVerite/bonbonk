class_name LevelWaveData
extends Resource

## Configuration d'une sous-vague d'ennemis pour un niveau scénarisé de Campagne.

@export var wave_number: int = 1
## Liste des apparitions : [{ "unit": "tomato", "delay": 1.0, "x_ratio": 0.5 }]
## - unit: identifiant de l'ennemi (ex: "tomato", "ananas", "watermelon", "coconut", "pomegranate", "boss_brocolino")
## - delay: délai en secondes après le début de la sous-vague
## - x_ratio: ratio horizontal entre 0.0 (gauche) et 1.0 (droite), -1.0 pour aléatoire
@export var spawns: Array[Dictionary] = []
