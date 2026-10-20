class_name DeckService
extends RefCounted

## Service spécialisé dans la gestion, la validation et la manipulation des decks.

func validate_decks(decks: Array) -> void:
	for i in range(decks.size()):
		var d: Array = decks[i]
		for j in range(d.size()):
			if d[j] == &"standard" or d[j] == &"cherry" or d[j] == &"mint":
				d[j] = &"fizz"
		while d.size() < 6:
			d.append(&"fizz")
		if d.size() > 6:
			d.resize(6)

func get_active_deck(decks: Array, active_deck_index: int) -> Array:
	if decks.is_empty():
		return []
	var clamped_idx: int = clampi(active_deck_index, 0, decks.size() - 1)
	return decks[clamped_idx]

func set_active_deck(index: int, decks_count: int) -> int:
	if index >= 0 and index < decks_count:
		return index
	return 0

func set_card_in_deck(deck_idx: int, slot_idx: int, card_id: StringName, decks: Array) -> bool:
	if deck_idx >= 0 and deck_idx < decks.size():
		var d: Array = decks[deck_idx]
		if slot_idx >= 0 and slot_idx < d.size():
			d[slot_idx] = card_id
			return true
	return false

func get_active_deck_balls(active_deck: Array, card_defs: Dictionary) -> Array[StringName]:
	var balls: Array[StringName] = []
	for card_id in active_deck:
		var c_id: StringName = card_id as StringName
		var c_def: CandyCardData = card_defs.get(c_id, null)
		if c_def != null and c_def.card_type == CandyCardData.CardType.BALL:
			balls.append(c_id)
	if balls.is_empty():
		balls.append(&"fizz")
	return balls

func get_active_deck_bumpers(active_deck: Array, card_defs: Dictionary) -> Array[StringName]:
	var bumpers: Array[StringName] = []
	for card_id in active_deck:
		var c_id: StringName = card_id as StringName
		var c_def: CandyCardData = card_defs.get(c_id, null)
		if c_def != null and c_def.card_type == CandyCardData.CardType.BUMPER:
			bumpers.append(c_id)
	return bumpers
