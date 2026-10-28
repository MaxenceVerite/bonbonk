extends Node

## Autoload global pour découpler les signaux transverses du jeu.

# Signaux de combat & Roguelike (triggers modulaires)
signal ball_hit_enemy(context: HitContext)
signal ball_hit_bumper(ball: RigidBody2D, bumper: Node2D)
signal flipper_parried(flipper: Node2D, enemy: Node2D, context: HitContext)
signal enemy_damaged(enemy: Node2D, context: HitContext)
signal enemy_killed(enemy: Node2D, context: HitContext)
signal status_applied(target: Node2D, status_id: StringName)

# Signaux du jeu
signal score_changed(new_score: int, delta: int)
signal combo_multiplier_changed(multiplier: float)
signal enemy_defeated(enemy_type: StringName, position: Vector2)
signal enemy_escaped(damage: int)
signal player_healed(amount: int)
signal health_changed(current_health: int, max_health: int)
signal game_over
signal game_restarted

# Signaux Boss
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_invulnerability_changed(is_invulnerable: bool)
signal boss_defeated(boss_name: String)

# Signaux de navigation & UI
signal start_game_requested
signal return_to_menu_requested
signal main_menu_tab_changed(tab_name: StringName)

# Économie & Progression
signal gold_changed(new_gold: int, delta: int)
signal diamonds_changed(new_diamonds: int, delta: int)
signal card_upgraded(card_id: StringName, new_level: int)
signal booster_opened(booster_result: Dictionary)
signal open_booster_modal_requested(booster: BoosterData)
signal open_shop_requested(category_hint: StringName)
signal shop_item_purchased(item_id: StringName, currency_used: StringName)
## Offre payante en argent réel sélectionnée (flux d'achat in-app à brancher plus tard)
signal shop_real_money_offer_requested(item_id: StringName)
signal deck_changed(deck_index: int)

# Compte & Synchronisation Cloud
signal profile_loaded(profile_id: String)
signal cloud_sync_status_changed(status: String, message: String)
signal cloud_sync_completed(success: bool)
signal open_account_modal_requested

# Mécanique Avancée : Mega Slam & Super Chain
signal mega_slam_requested
signal mega_slam_activated
signal mega_slam_cooldown_updated(current: float, max_duration: float, is_ready: bool)
signal super_chain_started(ball: RigidBody2D)
signal super_chain_enemy_hit(ball: RigidBody2D, enemy: Node2D, combo_count: int)
signal super_chain_completed(ball: RigidBody2D)
