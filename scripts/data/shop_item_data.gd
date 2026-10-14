class_name ShopItemData
extends Resource

## Définition d'un article disponible dans la boutique.

enum Category {
	BOOSTERS,    # Sachets de bonbons
	CARDS_DAILY, # Lots de cartes de bonbons directes
	CURRENCY,    # Or ou Diamants
	SPECIAL      # Packs spéciaux
}

@export var id: StringName = &"item_default"
@export var display_name: String = "Article"
@export var description: String = ""
@export var category: Category = Category.BOOSTERS
@export var icon_texture: Texture2D

## Prix en monnaie standard (-1 si non disponible avec cette devise)
@export var gold_price: int = -1

## Prix en monnaie premium (-1 si non disponible avec cette devise)
@export var diamond_price: int = -1

## Payload de récompense lors de l'achat :
## Exemples :
## { "type": "booster", "booster_type": BoosterData.BoosterType.CLASSIC_SOLO, "booster_name": "🍬 Sachet Classique" }
## { "type": "gold", "amount": 1000 }
## { "type": "diamonds", "amount": 50 }
## { "type": "cards", "card_id": &"caramel", "count": 5 }
@export var reward_payload: Dictionary = {}
