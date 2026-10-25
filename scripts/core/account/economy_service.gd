class_name EconomyService
extends RefCounted

## Service spécialisé dans l'économie (or, diamants), la boutique et les récompenses de boosters.

const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")
const InventoryServiceScript = preload("res://scripts/core/account/inventory_service.gd")

func add_gold(amount: int, profile: PlayerProfileScript) -> int:
	if profile == null:
		return 0
	profile.gold += amount
	EventBus.gold_changed.emit(profile.gold, amount)
	return profile.gold

func spend_gold(amount: int, profile: PlayerProfileScript) -> bool:
	if profile != null and profile.gold >= amount:
		profile.gold -= amount
		EventBus.gold_changed.emit(profile.gold, -amount)
		return true
	return false

func add_diamonds(amount: int, profile: PlayerProfileScript) -> int:
	if profile == null:
		return 0
	profile.diamonds += amount
	EventBus.diamonds_changed.emit(profile.diamonds, amount)
	return profile.diamonds

func spend_diamonds(amount: int, profile: PlayerProfileScript) -> bool:
	if profile != null and profile.diamonds >= amount:
		profile.diamonds -= amount
		EventBus.diamonds_changed.emit(profile.diamonds, -amount)
		return true
	return false

func record_game_results(profile: PlayerProfileScript, final_score: int, waves_cleared: int, gold_earned: int) -> Dictionary:
	var is_new_record: bool = false
	if profile != null:
		var best: int = profile.stats.get("best_score", 0)
		if final_score > best:
			profile.stats["best_score"] = final_score
			is_new_record = true
		profile.stats["games_played"] = profile.stats.get("games_played", 0) + 1

	if gold_earned > 0:
		add_gold(gold_earned, profile)

	return {
		"final_score": final_score,
		"waves_cleared": waves_cleared,
		"gold_earned": gold_earned,
		"is_new_record": is_new_record,
		"best_score": profile.stats.get("best_score", final_score) if profile != null else final_score
	}

func purchase_item(
	item: ShopItemData,
	use_diamonds: bool,
	profile: PlayerProfileScript,
	available_boosters: Array[BoosterData],
	inventory_service: RefCounted
) -> bool:
	if profile == null or item == null:
		return false

	# 1. Flux achat argent réel (in-app purchase)
	if item.is_real_money():
		EventBus.shop_real_money_offer_requested.emit(item.id)
		return true

	# 2. Récompense déjà récupérée (ex: cadeau unique du jour)
	if item.is_claimed:
		return false

	# 3. Débit de monnaie (si non gratuit)
	if not item.is_free():
		if use_diamonds:
			if item.diamond_price < 0 or profile.diamonds < item.diamond_price:
				return false
			if not spend_diamonds(item.diamond_price, profile):
				return false
		else:
			if item.gold_price < 0 or profile.gold < item.gold_price:
				return false
			if not spend_gold(item.gold_price, profile):
				return false

	# 4. Attribution des récompenses (les bundles sont dépliés)
	for reward in item.get_reward_entries():
		_grant_reward(reward, item, profile, available_boosters, inventory_service)

	if item.is_free():
		item.is_claimed = true

	var currency_used: StringName = &"free" if item.is_free() else (&"diamonds" if use_diamonds else &"gold")
	EventBus.shop_item_purchased.emit(item.id, currency_used)
	return true

func _grant_reward(
	payload: Dictionary,
	item: ShopItemData,
	profile: PlayerProfileScript,
	available_boosters: Array[BoosterData],
	inventory_service: RefCounted
) -> void:
	var ptype: String = payload.get("type", "")
	match ptype:
		"gold":
			add_gold(payload.get("amount", 0), profile)
		"diamonds":
			add_diamonds(payload.get("amount", 0), profile)
		"booster":
			var b: BoosterData = BoosterData.new()
			b.id = payload.get("id", &"booster")
			b.display_name = payload.get("display_name", "Sachet")
			b.booster_type = payload.get("booster_type", BoosterData.BoosterType.SILVER_POP)
			b.min_gold = payload.get("min_gold", 40)
			b.max_gold = payload.get("max_gold", 100)
			b.icon_texture = payload.get("icon_texture", item.icon_texture)
			available_boosters.append(b)
		"cards":
			var cid: StringName = payload.get("card_id", &"fizz")
			var count: int = payload.get("count", 1)
			if inventory_service != null:
				inventory_service.add_cards_to_inventory(cid, count, profile.cards_inventory)

func apply_booster_rewards(
	result: Dictionary,
	profile: PlayerProfileScript,
	inventory_service: RefCounted
) -> void:
	if profile == null:
		return

	if result.has("gold"):
		add_gold(result["gold"], profile)

	if result.has("diamonds") and int(result["diamonds"]) > 0:
		add_diamonds(int(result["diamonds"]), profile)

	if result.has("drops") and inventory_service != null:
		for drop in result["drops"]:
			var card_def: CandyCardData = drop["card"]
			var cid: StringName = card_def.id
			var count: int = drop["count"]
			inventory_service.add_cards_to_inventory(cid, count, profile.cards_inventory)

	EventBus.booster_opened.emit(result)
