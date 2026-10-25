class_name BoosterData
extends Resource

## Configuration d'un paquet de bonbons (booster) et de son algorithme de tirage.
## Gère 4 types : Silver Pop, Golden Crush, Diamond Dust et Mystery Mix.

enum BoosterType {
	SILVER_POP = 0,    # Sachet Silver Pop (2 tirages, min Peu Commun+, 50-100 or)
	GOLDEN_CRUSH = 1,  # Sachet Golden Crush (3 tirages, min 1 RARE garantie, 180-350 or)
	DIAMOND_DUST = 2,  # Sachet Diamond Dust (4 tirages, min 1 ÉPIQUE garantie, 600-1200 or + diamants)
	MYSTERY_MIX = 3,   # Sachet Mystery Mix (4-5 tirages, Balle + Bumper garantis, Jackpot Roll)
	# Alias rétrocompatibles pour préserver les profils existants
	CLASSIC_SOLO = 0,
	POP_SOLO = 1,
	CLASSIC_MIX = 3,
	PIQUANT_MIX = 2
}

@export var id: StringName = &"silver_pop"
@export var display_name: String = "Sachet Silver Pop"
@export var booster_type: BoosterType = BoosterType.SILVER_POP
@export var icon_texture: Texture2D

@export var min_gold: int = 50
@export var max_gold: int = 100
@export var min_diamonds: int = 0
@export var max_diamonds: int = 0

## Retourne le préfixe de chemin de texture pour ce type de sachet
func get_texture_prefix() -> String:
	match booster_type:
		BoosterType.SILVER_POP:
			return "res://assets/ui/pack_silver_"
		BoosterType.GOLDEN_CRUSH:
			return "res://assets/ui/pack_gold_"
		BoosterType.DIAMOND_DUST:
			return "res://assets/ui/pack_diamond_"
		BoosterType.MYSTERY_MIX:
			return "res://assets/ui/pack_mystery_"
		_:
			return "res://assets/ui/pack_silver_"

func get_full_texture() -> Texture2D:
	return load(get_texture_prefix() + "full.png")

func get_open_body_texture() -> Texture2D:
	return load(get_texture_prefix() + "open_body.png")

func get_top_texture() -> Texture2D:
	return load(get_texture_prefix() + "top.png")

## Couleur d'ambiance et de lueur du sachet
func get_accent_color() -> Color:
	match booster_type:
		BoosterType.SILVER_POP:
			return Color(0.35, 0.85, 0.95, 1.0) # Menthe / Argent
		BoosterType.GOLDEN_CRUSH:
			return Color(1.0, 0.78, 0.12, 1.0) # Or étincelant
		BoosterType.DIAMOND_DUST:
			return Color(0.25, 0.65, 1.0, 1.0)  # Saphir / Diamant
		BoosterType.MYSTERY_MIX:
			return Color(0.85, 0.25, 0.95, 1.0) # Violet cosmique
		_:
			return Color(0.35, 0.85, 0.95, 1.0)

## Génère les récompenses du sachet selon ses tables de probabilités et garanties minimales.
func generate_drops(available_cards: Array[CandyCardData], unlocked_ids: Array[StringName]) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var drops: Array[Dictionary] = []
	var total_gold: int = rng.randi_range(min_gold, max_gold)
	var total_diamonds: int = 0
	if max_diamonds > 0:
		total_diamonds = rng.randi_range(min_diamonds, max_diamonds)

	# 1. Classement des cartes disponibles par rareté
	var by_rarity: Dictionary = {
		CandyCardData.Rarity.COMMON: [] as Array[CandyCardData],
		CandyCardData.Rarity.UNCOMMON: [] as Array[CandyCardData],
		CandyCardData.Rarity.RARE: [] as Array[CandyCardData],
		CandyCardData.Rarity.EPIC: [] as Array[CandyCardData],
		CandyCardData.Rarity.LEGENDARY: [] as Array[CandyCardData],
		CandyCardData.Rarity.MYTHIC: [] as Array[CandyCardData]
	}

	var balls: Array[CandyCardData] = []
	var bumpers: Array[CandyCardData] = []

	for card in available_cards:
		if by_rarity.has(card.rarity):
			by_rarity[card.rarity].append(card)
		if card.card_type == CandyCardData.CardType.BALL:
			balls.append(card)
		else:
			bumpers.append(card)

	# 2. Tirage selon le type de booster
	match booster_type:
		BoosterType.SILVER_POP:
			# 2 tirages (8 à 14 cartes au total)
			# Slot 1 : Garanti Peu Commun ou Rare
			var slot1_weights: Dictionary = {
				CandyCardData.Rarity.UNCOMMON: 70.0,
				CandyCardData.Rarity.RARE: 28.0,
				CandyCardData.Rarity.EPIC: 2.0
			}
			var card1: CandyCardData = _pick_by_weights(slot1_weights, by_rarity, rng, available_cards)
			drops.append({
				"card": card1,
				"count": rng.randi_range(4, 7),
				"is_new": not unlocked_ids.has(card1.id)
			})

			# Slot 2 : Tirage libre (dominé commun)
			var slot2_weights: Dictionary = {
				CandyCardData.Rarity.COMMON: 65.0,
				CandyCardData.Rarity.UNCOMMON: 25.0,
				CandyCardData.Rarity.RARE: 9.5,
				CandyCardData.Rarity.EPIC: 0.5
			}
			var card2: CandyCardData = _pick_by_weights(slot2_weights, by_rarity, rng, available_cards)
			# Éviter doublon strict si possible
			if card2.id == card1.id and available_cards.size() > 1:
				for alt in available_cards:
					if alt.id != card1.id:
						card2 = alt
						break
			drops.append({
				"card": card2,
				"count": rng.randi_range(4, 7),
				"is_new": not unlocked_ids.has(card2.id)
			})

		BoosterType.GOLDEN_CRUSH:
			# 3 tirages (15 à 22 cartes au total)
			# Slot 1 : Garanti RARE minimum (chance Épique / Légendaire)
			var slot1_weights: Dictionary = {
				CandyCardData.Rarity.RARE: 80.0,
				CandyCardData.Rarity.EPIC: 18.0,
				CandyCardData.Rarity.LEGENDARY: 2.0
			}
			var card1: CandyCardData = _pick_by_weights(slot1_weights, by_rarity, rng, available_cards)
			drops.append({
				"card": card1,
				"count": rng.randi_range(5, 8),
				"is_new": not unlocked_ids.has(card1.id)
			})

			# Slot 2 & Slot 3 : Tirages variés
			var normal_weights: Dictionary = {
				CandyCardData.Rarity.COMMON: 30.0,
				CandyCardData.Rarity.UNCOMMON: 45.0,
				CandyCardData.Rarity.RARE: 20.0,
				CandyCardData.Rarity.EPIC: 4.5,
				CandyCardData.Rarity.LEGENDARY: 0.5
			}
			var used_ids: Array[StringName] = [card1.id]
			for i in range(2):
				var card: CandyCardData = _pick_by_weights(normal_weights, by_rarity, rng, available_cards)
				if used_ids.has(card.id) and available_cards.size() > used_ids.size():
					for alt in available_cards:
						if not used_ids.has(alt.id):
							card = alt
							break
				used_ids.append(card.id)
				drops.append({
					"card": card,
					"count": rng.randi_range(5, 7),
					"is_new": not unlocked_ids.has(card.id)
				})

		BoosterType.DIAMOND_DUST:
			# 4 tirages (22 à 32 cartes au total) + Diamants
			if total_diamonds == 0:
				total_diamonds = rng.randi_range(5, 10)

			# Slot 1 : Garanti ÉPIQUE minimum (chance Légendaire / Mythique)
			var elite_slot_weights: Dictionary = {
				CandyCardData.Rarity.EPIC: 74.0,
				CandyCardData.Rarity.LEGENDARY: 21.0,
				CandyCardData.Rarity.MYTHIC: 5.0
			}
			var card1: CandyCardData = _pick_by_weights(elite_slot_weights, by_rarity, rng, available_cards)
			drops.append({
				"card": card1,
				"count": rng.randi_range(5, 8),
				"is_new": not unlocked_ids.has(card1.id)
			})

			# Slots 2, 3, 4 : Raretés élevées
			var high_weights: Dictionary = {
				CandyCardData.Rarity.UNCOMMON: 25.0,
				CandyCardData.Rarity.RARE: 45.0,
				CandyCardData.Rarity.EPIC: 22.0,
				CandyCardData.Rarity.LEGENDARY: 7.0,
				CandyCardData.Rarity.MYTHIC: 1.0
			}
			var used_ids: Array[StringName] = [card1.id]
			for i in range(3):
				var card: CandyCardData = _pick_by_weights(high_weights, by_rarity, rng, available_cards)
				if used_ids.has(card.id) and available_cards.size() > used_ids.size():
					for alt in available_cards:
						if not used_ids.has(alt.id):
							card = alt
							break
				used_ids.append(card.id)
				drops.append({
					"card": card,
					"count": rng.randi_range(5, 8),
					"is_new": not unlocked_ids.has(card.id)
				})

		BoosterType.MYSTERY_MIX:
			# 4 à 5 tirages variés avec Balle + Bumper garantis et Jackpot Roll
			var draw_count: int = rng.randi_range(4, 5)
			var used_ids: Array[StringName] = []

			# 1 Balle garantie
			var picked_ball: CandyCardData = balls[rng.randi_range(0, balls.size() - 1)] if not balls.is_empty() else available_cards[0]
			used_ids.append(picked_ball.id)
			drops.append({
				"card": picked_ball,
				"count": rng.randi_range(3, 6),
				"is_new": not unlocked_ids.has(picked_ball.id)
			})

			# 1 Bumper garanti
			var picked_bumper: CandyCardData = bumpers[rng.randi_range(0, bumpers.size() - 1)] if not bumpers.is_empty() else available_cards[0]
			used_ids.append(picked_bumper.id)
			drops.append({
				"card": picked_bumper,
				"count": rng.randi_range(3, 6),
				"is_new": not unlocked_ids.has(picked_bumper.id)
			})

			# Slot Jackpot (20% de chance d'un tirage géant x12 à x18)
			var is_jackpot: bool = rng.randf() < 0.25
			var jackpot_weights: Dictionary = {
				CandyCardData.Rarity.RARE: 50.0,
				CandyCardData.Rarity.EPIC: 35.0,
				CandyCardData.Rarity.LEGENDARY: 12.0,
				CandyCardData.Rarity.MYTHIC: 3.0
			}
			var jackpot_card: CandyCardData = _pick_by_weights(jackpot_weights, by_rarity, rng, available_cards)
			used_ids.append(jackpot_card.id)
			drops.append({
				"card": jackpot_card,
				"count": rng.randi_range(10, 16) if is_jackpot else rng.randi_range(4, 7),
				"is_new": not unlocked_ids.has(jackpot_card.id)
			})

			# Tirages restants
			var remaining_picks: int = draw_count - 3
			for i in range(remaining_picks):
				var pool: Array[CandyCardData] = []
				for c in available_cards:
					if not used_ids.has(c.id):
						pool.append(c)
				if pool.is_empty():
					pool = available_cards
				var c_pick: CandyCardData = pool[rng.randi_range(0, pool.size() - 1)]
				used_ids.append(c_pick.id)
				drops.append({
					"card": c_pick,
					"count": rng.randi_range(3, 6),
					"is_new": not unlocked_ids.has(c_pick.id)
				})

	# 3. Fusion systématique des doublons (regroupement des quantités par bonbon)
	var consolidated_drops: Array[Dictionary] = []
	var drop_map: Dictionary = {}

	for drop in drops:
		var card: CandyCardData = drop["card"]
		var cid: StringName = card.id
		if drop_map.has(cid):
			var existing: Dictionary = drop_map[cid]
			existing["count"] = int(existing["count"]) + int(drop["count"])
			if drop.get("is_new", false):
				existing["is_new"] = true
		else:
			var entry: Dictionary = {
				"card": card,
				"count": int(drop["count"]),
				"is_new": drop.get("is_new", false)
			}
			drop_map[cid] = entry
			consolidated_drops.append(entry)

	# 4. Tri strict par rareté croissante (COMMON -> UNCOMMON -> RARE -> EPIC -> LEGENDARY -> MYTHIC)
	consolidated_drops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rarity_a: int = a["card"].rarity
		var rarity_b: int = b["card"].rarity
		if rarity_a != rarity_b:
			return rarity_a < rarity_b
		return a["card"].display_name < b["card"].display_name
	)

	return {
		"gold": total_gold,
		"diamonds": total_diamonds,
		"drops": consolidated_drops
	}

## Sélectionne une carte selon un dictionnaire de poids par rareté
func _pick_by_weights(
	weights: Dictionary,
	by_rarity: Dictionary,
	rng: RandomNumberGenerator,
	fallback_pool: Array[CandyCardData]
) -> CandyCardData:
	var total_weight: float = 0.0
	for r in weights:
		var rarity_pool: Array = by_rarity.get(r, [])
		if not rarity_pool.is_empty():
			total_weight += float(weights[r])

	if total_weight <= 0.0:
		return fallback_pool[rng.randi_range(0, fallback_pool.size() - 1)]

	var roll: float = rng.randf_range(0.0, total_weight)
	var current: float = 0.0
	for r in weights:
		var rarity_pool: Array = by_rarity.get(r, [])
		if rarity_pool.is_empty():
			continue
		current += float(weights[r])
		if roll <= current:
			return rarity_pool[rng.randi_range(0, rarity_pool.size() - 1)]

	return fallback_pool[rng.randi_range(0, fallback_pool.size() - 1)]
