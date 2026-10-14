extends Node

## Autoload global pour découpler les signaux transverses du jeu.

# Signaux du jeu
signal score_changed(new_score: int, delta: int)
signal combo_multiplier_changed(multiplier: float)
signal enemy_defeated(enemy_type: StringName, position: Vector2)
signal enemy_escaped(damage: int)
signal health_changed(current_health: int, max_health: int)
signal game_over
signal game_restarted

# Signaux de navigation & UI
signal start_game_requested
signal return_to_menu_requested
signal main_menu_tab_changed(tab_name: StringName)

# Économie & Progression
signal gold_changed(new_gold: int, delta: int)
signal diamonds_changed(new_diamonds: int, delta: int)
signal card_upgraded(card_id: StringName, new_level: int)
signal booster_opened(booster_result: Dictionary)
signal open_booster_modal_requested
signal open_shop_requested(category_hint: StringName)
signal shop_item_purchased(item_id: StringName, currency_used: StringName)
signal deck_changed(deck_index: int)


