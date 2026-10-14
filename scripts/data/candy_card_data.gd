class_name CandyCardData
extends Resource

## Définition d'un bonbon / bille à collectionner et améliorer.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CardType { BALL, BUMPER }

@export var id: StringName = &"standard"
@export var display_name: String = "Bille Sucrée"
@export var subtitle: String = "Classique & Croustillante"
@export var description: String = "Une bille équilibrée et croustillante, parfaite pour débuter."
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.BALL
@export var icon_texture: Texture2D
@export var scene_ref: PackedScene

# Statistiques de base et gains par niveau
@export var base_damage: int = 10
@export var damage_per_level: int = 3
@export var base_bounce: float = 1.0
@export var bounce_per_level: float = 0.05

func get_damage_for_level(lvl: int) -> int:
	return base_damage + (lvl - 1) * damage_per_level

func get_bounce_for_level(lvl: int) -> float:
	return base_bounce + float(lvl - 1) * bounce_per_level

# Paliers de cartes pour chaque niveau (ex: niveau 1 vers 2 = 2 cartes, etc.)
@export var cards_to_level: Array[int] = [2, 4, 10, 20, 50, 100]
# Coûts d'amélioration en or pour chaque niveau
@export var gold_cost_to_level: Array[int] = [20, 50, 150, 400, 1000, 2500]

func get_required_cards_for_level(current_lvl: int) -> int:
	var idx: int = maxi(0, current_lvl - 1)
	if idx < cards_to_level.size():
		return cards_to_level[idx]
	return 200 # Palier max

func get_gold_cost_for_level(current_lvl: int) -> int:
	var idx: int = maxi(0, current_lvl - 1)
	if idx < gold_cost_to_level.size():
		return gold_cost_to_level[idx]
	return 5000
