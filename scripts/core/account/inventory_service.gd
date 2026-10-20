class_name InventoryService
extends RefCounted

## Service spécialisé dans la gestion de l'inventaire des cartes et de leur montée de niveau.

func get_unlocked_card_ids(cards_inventory: Dictionary) -> Array[StringName]:
	var res: Array[StringName] = []
	for cid in cards_inventory:
		if cards_inventory[cid].get("unlocked", false):
			res.append(cid)
	return res

func can_upgrade_card(card_id: StringName, cards_inventory: Dictionary, card_defs: Dictionary, current_gold: int) -> bool:
	if not cards_inventory.has(card_id) or not card_defs.has(card_id):
		return false
	var inv: Dictionary = cards_inventory[card_id]
	if not inv.get("unlocked", false):
		return false

	var def: CandyCardData = card_defs[card_id]
	var cur_lvl: int = inv.get("level", 1)
	var req_cards: int = def.get_required_cards_for_level(cur_lvl)
	var req_gold: int = def.get_gold_cost_for_level(cur_lvl)

	return inv.get("cards", 0) >= req_cards and current_gold >= req_gold

func upgrade_card(card_id: StringName, cards_inventory: Dictionary, card_defs: Dictionary, current_gold: int, spend_gold_cb: Callable) -> bool:
	if not can_upgrade_card(card_id, cards_inventory, card_defs, current_gold):
		return false

	var inv: Dictionary = cards_inventory[card_id]
	var def: CandyCardData = card_defs[card_id]
	var cur_lvl: int = inv.get("level", 1)
	var req_cards: int = def.get_required_cards_for_level(cur_lvl)
	var req_gold: int = def.get_gold_cost_for_level(cur_lvl)

	if spend_gold_cb.call(req_gold):
		inv["cards"] -= req_cards
		inv["level"] = cur_lvl + 1
		EventBus.card_upgraded.emit(card_id, inv["level"])
		return true
	return false

func get_card_state(card_id: StringName, cards_inventory: Dictionary, card_defs: Dictionary, current_gold: int) -> Dictionary:
	if not card_defs.has(card_id):
		return {}
	var def: CandyCardData = card_defs[card_id]
	var inv: Dictionary = cards_inventory.get(card_id, { "unlocked": false, "level": 1, "cards": 0 })
	var is_unlocked: bool = inv.get("unlocked", false)
	var lvl: int = inv.get("level", 1)
	var cards: int = inv.get("cards", 0)
	var req_cards: int = def.get_required_cards_for_level(lvl)
	var req_gold: int = def.get_gold_cost_for_level(lvl)
	var has_enough_cards: bool = (cards >= req_cards)
	var has_enough_gold: bool = (current_gold >= req_gold)
	var can_up: bool = is_unlocked and has_enough_cards and has_enough_gold

	return {
		"id": card_id,
		"def": def,
		"unlocked": is_unlocked,
		"level": lvl,
		"cards": cards,
		"req_cards": req_cards,
		"req_gold": req_gold,
		"has_enough_cards": has_enough_cards,
		"has_enough_gold": has_enough_gold,
		"can_upgrade": can_up,
		"ratio": float(cards) / float(maxi(1, req_cards))
	}

func add_cards_to_inventory(card_id: StringName, count: int, cards_inventory: Dictionary) -> void:
	if not cards_inventory.has(card_id):
		cards_inventory[card_id] = { "unlocked": true, "level": 1, "cards": count }
	else:
		var inv: Dictionary = cards_inventory[card_id]
		inv["unlocked"] = true
		inv["cards"] = inv.get("cards", 0) + count
