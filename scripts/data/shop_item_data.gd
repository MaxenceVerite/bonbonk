class_name ShopItemData
extends Resource

## Définition d'un article disponible dans la boutique.
## Entièrement data-driven : la boutique affiche ce que lui fournit le catalogue
## (local aujourd'hui, distant plus tard), sans contenu codé en dur dans l'UI.

enum Category {
	BOOSTERS,    # Sachets de bonbons
	CARDS_DAILY, # Lots de cartes de bonbons directes
	CURRENCY,    # Or ou Diamants
	SPECIAL,     # Packs spéciaux
	FEATURED,    # Offres mises en avant (galerie "Offre du jour")
	FREE         # Cadeaux gratuits à récupérer
}

## Taille occupée par une offre dans la galerie mise en avant.
enum FeaturedSize {
	FULL, # Pleine largeur
	HALF  # Demi-largeur (deux offres côte à côte)
}

@export var id: StringName = &"item_default"
@export var display_name: String = "Article"
@export var description: String = ""
@export var category: Category = Category.BOOSTERS
@export var icon_texture: Texture2D

@export_group("Présentation")
## Image de fond (utilisée par les cartes de la galerie mise en avant).
@export var background_texture: Texture2D
## Pastille optionnelle affichée en coin de carte (ex: "-30%", "NOUVEAU").
@export var badge_text: String = ""
## Taille dans la galerie mise en avant.
@export var featured_size: FeaturedSize = FeaturedSize.FULL

@export_group("Prix")
## Prix en monnaie standard (-1 si non disponible avec cette devise, 0 = gratuit)
@export var gold_price: int = -1
## Prix en monnaie premium (-1 si non disponible avec cette devise, 0 = gratuit)
@export var diamond_price: int = -1
## Prix en argent réel déjà formaté (ex: "4,99 €"). Vide si non concerné.
@export var real_price_label: String = ""

@export_group("Récompense")
## Texte explicite résumant ce qui est offert (ex: "+150 🪙 Or sucré", "+5 Cartes Fizzball").
## Si vide, il est généré automatiquement à partir de `reward_payload`.
@export var reward_text: String = ""
## Indique si la récompense / l'offre a déjà été récupérée lors de la session courante.
@export var is_claimed: bool = false
## Payload de récompense lors de l'achat :
## Exemples :
## { "type": "booster", "booster_type": BoosterData.BoosterType.SILVER_POP, "display_name": "🥈 Sachet Silver Pop" }
## { "type": "gold", "amount": 1000 }
## { "type": "diamonds", "amount": 50 }
## { "type": "cards", "card_id": &"caramel", "count": 5 }
## { "type": "bundle", "rewards": [ {...}, {...} ] }
@export var reward_payload: Dictionary = {}

func is_real_money() -> bool:
	return not real_price_label.is_empty()

func is_free() -> bool:
	if is_real_money():
		return false
	return gold_price == 0 or diamond_price == 0

func get_formatted_reward_text() -> String:
	if not reward_text.is_empty():
		return reward_text
	var entries: Array[Dictionary] = get_reward_entries()
	if entries.is_empty():
		return description
	var parts: Array[String] = []
	for e in entries:
		var ptype: String = e.get("type", "")
		match ptype:
			"gold":
				parts.append("+%d 🪙" % e.get("amount", 0))
			"diamonds":
				parts.append("+%d 💎" % e.get("amount", 0))
			"cards":
				parts.append("+%d Cartes" % e.get("count", 1))
			"booster":
				parts.append(e.get("display_name", "🍬 Sachet"))
			_:
				if e.has("display_name"):
					parts.append(e["display_name"])
	if parts.is_empty():
		return description
	return " + ".join(parts)

## Devise à utiliser pour une récupération gratuite.
func free_uses_diamonds() -> bool:
	return gold_price != 0 and diamond_price == 0

## Liste à plat des récompenses élémentaires (déplie les bundles).
func get_reward_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_collect_rewards(reward_payload, out)
	return out

static func _collect_rewards(payload: Dictionary, out: Array[Dictionary]) -> void:
	if payload.is_empty():
		return
	if payload.get("type", "") == "bundle":
		var rewards: Array = payload.get("rewards", [])
		for r in rewards:
			if r is Dictionary:
				_collect_rewards(r, out)
	else:
		out.append(payload)
