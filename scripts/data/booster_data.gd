class_name BoosterData
extends Resource

## Configuration d'un paquet de bonbons (booster) et de son algorithme de tirage.

enum BoosterType {
	CLASSIC_SOLO,   # Sachet Classique (1 seul bonbon commun en quantité)
	POP_SOLO,       # Sachet Pop (1 seul bonbon de bonne rareté)
	CLASSIC_MIX,    # Sachet Mix Classique (plusieurs bonbons variés, dominé commune)
	PIQUANT_MIX     # Sachet Mix Piquant (plusieurs bonbons variés, axé rare/épique)
}

@export var id: StringName = &"classic_solo"
@export var display_name: String = "Sachet Classique"
@export var booster_type: BoosterType = BoosterType.CLASSIC_SOLO
@export var icon_texture: Texture2D

@export var min_gold: int = 40
@export var max_gold: int = 80

## Génère les récompenses de ce sachet : [ {"card_id": StringName, "count": int, "is_new": bool} ]
func generate_drops(available_cards: Array[CandyCardData], unlocked_ids: Array[StringName]) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var drops: Array[Dictionary] = []
	var total_gold: int = rng.randi_range(min_gold, max_gold)
	
	# Séparation par rareté
	var commons: Array[CandyCardData] = []
	var rares: Array[CandyCardData] = []
	var epics: Array[CandyCardData] = []
	
	for card in available_cards:
		match card.rarity:
			CandyCardData.Rarity.COMMON:
				commons.append(card)
			CandyCardData.Rarity.RARE:
				rares.append(card)
			_:
				epics.append(card)
				
	match booster_type:
		BoosterType.CLASSIC_SOLO:
			# Un seul type de bonbon commun en belle quantité (ex: 6 à 10)
			var target_pool: Array[CandyCardData] = commons if not commons.is_empty() else available_cards
			var picked: CandyCardData = target_pool[rng.randi_range(0, target_pool.size() - 1)]
			var count: int = rng.randi_range(6, 10)
			drops.append({
				"card": picked,
				"count": count,
				"is_new": not unlocked_ids.has(picked.id)
			})
			
		BoosterType.POP_SOLO:
			# Un seul type de bonbon de meilleure rareté (Rare ou Épique)
			var target_pool: Array[CandyCardData] = rares if not rares.is_empty() else available_cards
			var picked: CandyCardData = target_pool[rng.randi_range(0, target_pool.size() - 1)]
			var count: int = rng.randi_range(4, 7)
			drops.append({
				"card": picked,
				"count": count,
				"is_new": not unlocked_ids.has(picked.id)
			})
			
		BoosterType.CLASSIC_MIX:
			# 3 tirages de bonbons différents
			var pool: Array[CandyCardData] = available_cards.duplicate()
			pool.shuffle()
			var pick_count: int = mini(3, pool.size())
			for i in range(pick_count):
				var card: CandyCardData = pool[i]
				var count: int = rng.randi_range(2, 4)
				drops.append({
					"card": card,
					"count": count,
					"is_new": not unlocked_ids.has(card.id)
				})
				
		BoosterType.PIQUANT_MIX:
			# 3 à 4 tirages avec bonus sur les rares
			var pool: Array[CandyCardData] = available_cards.duplicate()
			pool.shuffle()
			var pick_count: int = mini(4, pool.size())
			for i in range(pick_count):
				var card: CandyCardData = pool[i]
				var count: int = rng.randi_range(3, 6)
				drops.append({
					"card": card,
					"count": count,
					"is_new": not unlocked_ids.has(card.id)
				})
				
	return {
		"gold": total_gold,
		"drops": drops
	}
