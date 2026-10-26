class_name Main
extends Node2D

## Scène racine orchestratrice du jeu de flipper.
## Gère la cinématique des écrans :
## 1. TitleScreen (Écran d'accueil avec 'Appuyer pour jouer')
## 2. MainMenu (Navbar : Collection, Jeu / Dernier score, Leaderboard)
## 3. Game Play (Arène active, HUD, TouchControls)

const DamageNumberManagerScript = preload("res://scripts/ui/damage_numbers/damage_number_manager.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const CampaignCatalog = preload("res://scripts/data/campaign_catalog.gd")
const LevelCompleteModal = preload("res://scripts/ui/level_complete_modal.gd")
const StageIntroOverlay = preload("res://scripts/ui/stage_intro_overlay.gd")

enum ScreenState { TITLE, MENU, GAME }
var current_screen_state: ScreenState = ScreenState.TITLE

@onready var board: Board = %Board
@onready var touch_controls: TouchControls = %TouchControls
@onready var hud: Control = %HUD
@onready var title_screen: TitleScreen = %TitleScreen
@onready var main_menu: MainMenu = %MainMenu
@onready var booster_modal: BoosterOpeningModal = %BoosterOpeningModal
@onready var intermission_overlay: IntermissionOverlay = %IntermissionOverlay
@onready var bumper_placement_overlay: BumperPlacementOverlay = %BumperPlacementOverlay
@onready var game_over_modal: GameOverModal = %GameOverModal
@onready var level_complete_modal: LevelCompleteModal = %LevelCompleteModal
@onready var stage_intro_overlay: StageIntroOverlay = %StageIntroOverlay

# HUD
@onready var btn_back_to_menu: Button = %BtnBackMenu
@onready var score_label: Label = %ScoreLabel
@onready var wave_label: Label = %WaveLabel
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_text_label: Label = %HPTextLabel
@onready var ball_factory_ui: BallFactoryUI = %BallFactoryUI

var wave_director: WaveDirector = null
var damage_number_manager: Node = null
var current_wave: int = 1
var max_hp: int = 100
var current_hp: int = 100
var current_score: int = 0
var last_score: int = 0

# Données de Campagne active
var active_level_data: LevelData = null
var active_world_data: WorldData = null

func _ready() -> void:
	print("Flip - Initialisation de l'orchestrateur d'écrans")
	
	# Signaux EventBus
	EventBus.enemy_escaped.connect(_on_enemy_escaped)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.start_game_requested.connect(launch_game)
	EventBus.return_to_menu_requested.connect(show_main_menu)
	EventBus.open_booster_modal_requested.connect(_on_open_booster_requested)
	
	# Signaux TitleScreen & MainMenu
	title_screen.screen_tapped.connect(show_main_menu)
	btn_back_to_menu.pressed.connect(show_main_menu)

	
	# Initialisation du WaveDirector
	wave_director = WaveDirector.new()
	add_child(wave_director)
	wave_director.initialize(board.enemy_container)
	wave_director.enemy_spawn_requested.connect(_on_wave_spawn_enemy)
	wave_director.wave_cleared.connect(_on_wave_cleared)
	wave_director.campaign_subwave_started.connect(_on_campaign_subwave_started)
	wave_director.campaign_level_completed.connect(_on_campaign_level_completed)
	
	if intermission_overlay != null:
		intermission_overlay.next_wave_pressed.connect(_on_next_wave_pressed)

	if bumper_placement_overlay != null:
		bumper_placement_overlay.placement_completed.connect(_on_bumper_placement_completed)
	
	if game_over_modal != null:
		game_over_modal.replay_pressed.connect(launch_game)
		game_over_modal.return_to_menu_pressed.connect(show_main_menu)

	if level_complete_modal != null:
		level_complete_modal.next_level_pressed.connect(_on_next_level_pressed)
		level_complete_modal.replay_pressed.connect(launch_game)
		level_complete_modal.return_to_menu_pressed.connect(show_main_menu)
	
	# Liaison Fabrique, Tube & Dual-Pods
	if board != null and ball_factory_ui != null:
		board.factory_state_changed.connect(ball_factory_ui.set_factory_state)
		ball_factory_ui.pod_launch_requested.connect(board.launch_ball_from_pod)
		
	# Centrage dynamique du plateau lors du redimensionnement (mode plein écran / bureau / tablette)
	get_viewport().size_changed.connect(_update_board_position)
	_update_board_position()
	
	# Initialisation du DamageNumberManager poolé
	damage_number_manager = DamageNumberManagerScript.new()
	add_child(damage_number_manager)
	damage_number_manager.setup(board, hud, hp_bar)

	# Démarrage au TitleScreen
	show_title_screen()

func _update_board_position() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var content_x: float = maxf(0.0, (vp_size.x - 720.0) * 0.5)
	# Centrage vertical équilibré si la hauteur dépasse la base de 1280
	var extra_y: float = maxf(0.0, vp_size.y - 1280.0)
	var content_y: float = extra_y * 0.5
	if board != null:
		board.position = Vector2(content_x, content_y)
	if hud != null:
		hud.position = Vector2.ZERO
	if ball_factory_ui != null:
		ball_factory_ui.position.y = 24.0 + content_y

func _on_open_booster_requested(booster: BoosterData = null) -> void:
	if booster == null:
		if SaveManager.available_boosters.is_empty():
			return
		booster = SaveManager.available_boosters.pop_front()
	else:
		SaveManager.available_boosters.erase(booster)
	booster_modal.start_opening(booster)

func show_title_screen() -> void:
	current_screen_state = ScreenState.TITLE
	title_screen.visible = true
	main_menu.visible = false
	hud.visible = false
	touch_controls.visible = false
	if ball_factory_ui != null:
		ball_factory_ui.visible = false
	if intermission_overlay != null:
		intermission_overlay.visible = false
	if bumper_placement_overlay != null:
		bumper_placement_overlay.visible = false
	if game_over_modal != null:
		game_over_modal.visible = false
	if level_complete_modal != null:
		level_complete_modal.visible = false
	if stage_intro_overlay != null:
		stage_intro_overlay.visible = false
	if wave_director != null:
		wave_director.stop_waves()
	if board != null:
		board.visible = false
		board.reset_board()

func show_main_menu() -> void:
	current_screen_state = ScreenState.MENU
	title_screen.visible = false
	main_menu.visible = true
	hud.visible = false
	touch_controls.visible = false
	if ball_factory_ui != null:
		ball_factory_ui.visible = false
	if intermission_overlay != null:
		intermission_overlay.visible = false
	if bumper_placement_overlay != null:
		bumper_placement_overlay.visible = false
	if game_over_modal != null:
		game_over_modal.visible = false
	if level_complete_modal != null:
		level_complete_modal.visible = false
	if stage_intro_overlay != null:
		stage_intro_overlay.visible = false
	if wave_director != null:
		wave_director.stop_waves()
	
	main_menu.set_last_score(last_score)
	if damage_number_manager != null:
		damage_number_manager.clear_all()
	if board != null:
		board.visible = false
		board.reset_board()

func launch_game() -> void:
	current_screen_state = ScreenState.GAME
	title_screen.visible = false
	main_menu.visible = false
	hud.visible = true
	touch_controls.visible = true
	if ball_factory_ui != null:
		ball_factory_ui.visible = true

	intermission_overlay.visible = false
	if game_over_modal != null:
		game_over_modal.visible = false
	if level_complete_modal != null:
		level_complete_modal.visible = false
	if wave_director != null:
		wave_director.stop_waves()

	# Configuration selon le mode de jeu
	var is_campaign: bool = SaveManager.is_campaign()
	if is_campaign:
		active_world_data = CampaignCatalog.get_world_by_number(SaveManager.campaign_selected_world)
		active_level_data = active_world_data.get_level(SaveManager.campaign_selected_level) if active_world_data != null else null
		if active_level_data == null and active_world_data != null and not active_world_data.levels.is_empty():
			active_level_data = active_world_data.levels[0]
		if board != null and active_world_data != null:
			board.set_world_theme(active_world_data)
	else:
		active_world_data = CampaignCatalog.get_world_by_number(SaveManager.survival_selected_world)
		if active_world_data == null:
			active_world_data = CampaignCatalog.get_world_by_number(1)
		active_level_data = null
		if board != null and active_world_data != null:
			board.set_world_theme(active_world_data)

	# Réinitialisation de la partie
	if damage_number_manager != null:
		damage_number_manager.clear_all()
	current_score = 0
	current_hp = max_hp
	current_wave = 1
	_update_hp_display(false)
	_update_wave_display()
	score_label.text = "SCORE: %d" % current_score
	
	if board != null:
		board.visible = true
		board.reset_board()

	# Vérifier si le deck contient des bumpers à placer
	var deck_bumpers: Array[StringName] = SaveManager.get_active_deck_bumpers()
	if not deck_bumpers.is_empty() and bumper_placement_overlay != null:
		hud.visible = false
		touch_controls.visible = false
		bumper_placement_overlay.open_placement(board)
	else:
		_play_stage_intro_and_start()

func _on_bumper_placement_completed() -> void:
	_play_stage_intro_and_start()

func _play_stage_intro_and_start() -> void:
	hud.visible = true
	touch_controls.visible = true

	# Prépare les données de la bannière
	var is_campaign: bool = SaveManager.is_campaign()
	var intro_info: Dictionary = {}
	if is_campaign and active_level_data != null:
		intro_info = {
			"mode": "campaign",
			"world_title": active_world_data.display_name if active_world_data != null else "Monde 1",
			"level_title": active_level_data.display_title,
			"subtitle": "Défendez les portes sucrées !"
		}
	else:
		intro_info = {
			"mode": "survival",
			"world_title": "SURVIE ARCADE",
			"level_title": "MANCHE %d" % current_wave,
			"subtitle": "Repoussez les vagues de bonbons !"
		}

	# Animation d'entrée du plateau (pop des bumpers et éveil des portes)
	if board != null:
		board.play_board_intro_reveal()

	# Animation de descente fluide du HUD
	_animate_hud_entry()

	if stage_intro_overlay != null:
		stage_intro_overlay.play_intro(intro_info, func() -> void:
			_start_board_gameplay()
		)
	else:
		_start_board_gameplay()

func _animate_hud_entry() -> void:
	if hud != null:
		hud.position.y = -90.0
		var tw: Tween = create_tween()
		tw.tween_property(hud, "position:y", 0.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if ball_factory_ui != null:
		ball_factory_ui.modulate.a = 0.0
		var tw_fac: Tween = create_tween()
		tw_fac.tween_property(ball_factory_ui, "modulate:a", 1.0, 0.35)

func _start_board_gameplay() -> void:
	if board != null:
		board.start_game()
	if wave_director != null:
		if SaveManager.is_campaign() and active_level_data != null:
			wave_director.start_campaign_level(active_level_data)
		else:
			wave_director.start_wave(current_wave)
			RelicManager.notify_wave_started(current_wave)

func _update_wave_display() -> void:
	if wave_label != null:
		if SaveManager.is_campaign() and active_level_data != null:
			wave_label.text = "NIV. %d (1/%d)" % [active_level_data.level_number, active_level_data.waves.size()]
		else:
			wave_label.text = "MANCHE %d" % current_wave

func _on_campaign_subwave_started(sub_idx: int, total_subwaves: int) -> void:
	if wave_label != null:
		if active_level_data != null:
			wave_label.text = "NIV. %d (%d/%d)" % [active_level_data.level_number, sub_idx, total_subwaves]
		else:
			wave_label.text = "VAGUE %d / %d" % [sub_idx, total_subwaves]

func _on_campaign_level_completed() -> void:
	if current_screen_state != ScreenState.GAME or current_hp <= 0 or active_level_data == null:
		return
	if board != null:
		board.on_wave_cleared_stability()
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = false
	touch_controls.visible = false

	var stars: int = active_level_data.calculate_stars(current_score, current_hp, max_hp)
	var summary: Dictionary = SaveManager.record_campaign_level_results(active_level_data, current_score, stars, current_hp)
	summary["level_title"] = "%s - %s" % [active_world_data.display_name if active_world_data else "Monde", active_level_data.display_title]
	summary["booster_awarded"] = (active_level_data.first_clear_booster_id != &"")

	if level_complete_modal != null:
		level_complete_modal.show_level_complete(summary)

func _on_next_level_pressed() -> void:
	if active_world_data == null or active_level_data == null:
		show_main_menu()
		return

	var next_num: int = active_level_data.level_number + 1
	var next_lvl: LevelData = active_world_data.get_level(next_num)
	if next_lvl != null:
		SaveManager.campaign_selected_level = next_num
		launch_game()
	else:
		# Passage au monde suivant
		var next_w_num: int = active_world_data.world_number + 1
		var next_w: WorldData = CampaignCatalog.get_world_by_number(next_w_num)
		if next_w != null:
			SaveManager.campaign_unlocked_world = maxi(SaveManager.campaign_unlocked_world, next_w_num)
			SaveManager.campaign_selected_world = next_w_num
			SaveManager.campaign_selected_level = 1
			launch_game()
		else:
			show_main_menu()

func _on_wave_spawn_enemy(scene_path: String, spawn_x: float) -> void:
	if board != null and board.is_game_running:
		board.spawn_enemy_by_path(scene_path, spawn_x)

func _on_wave_cleared(cleared_wave_num: int) -> void:
	# Sécurité stricte : ignorer si on n'est plus en partie active ou si mort ou en mode campagne
	if current_screen_state != ScreenState.GAME or current_hp <= 0 or SaveManager.is_campaign():
		return

	if board != null:
		board.on_wave_cleared_stability()
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = false
	RelicManager.notify_wave_cleared(cleared_wave_num)
	var next_w: int = cleared_wave_num + 1
	var next_budget: int = wave_director.calculate_budget_for_wave(next_w) if wave_director != null else 12
	intermission_overlay.show_intermission(cleared_wave_num, next_w, next_budget)

func _on_next_wave_pressed() -> void:
	intermission_overlay.hide_intermission()
	current_wave += 1
	_update_wave_display()
	
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = true

	if board != null:
		board.resume_for_next_wave()

	if wave_director != null:
		wave_director.start_wave(current_wave)
	RelicManager.notify_wave_started(current_wave)

func _update_hp_display(animate: bool = true) -> void:
	hp_text_label.text = "%d / %d" % [current_hp, max_hp]
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(hp_bar, "value", float(current_hp), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		hp_bar.value = float(current_hp)

func _on_enemy_escaped(damage: int) -> void:
	if is_god_mode:
		return
	current_hp = maxi(0, current_hp - damage)
	_update_hp_display(true)
	
	# Petit shake d'impact sur la barre de vie
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(hp_bar, "position:x", hp_bar.position.x + 4.0, 0.04)
	shake_tween.tween_property(hp_bar, "position:x", hp_bar.position.x - 4.0, 0.04)
	shake_tween.tween_property(hp_bar, "position:x", hp_bar.position.x, 0.04)
	
	if current_hp <= 0:
		EventBus.game_over.emit()

func _on_player_healed(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
	_update_hp_display(true)

# ==============================================================================
# COMMANDES DEV CONSOLE
# ==============================================================================

var is_god_mode: bool = false

func dev_jump_to_wave(target_wave: int) -> void:
	if current_screen_state != ScreenState.GAME:
		# Si on est dans le menu, lance d'abord la partie
		launch_game()

	if intermission_overlay != null:
		intermission_overlay.hide_intermission()

	current_wave = maxi(1, target_wave)
	_update_wave_display()

	# Nettoyage des ennemis actuels et des balles en cours
	if board != null:
		board.on_wave_cleared_stability()
		for child in board.enemy_container.get_children():
			if child.has_method(&"despawn"):
				child.despawn()
			else:
				child.queue_free()
		board.resume_for_next_wave()

	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = true

	if wave_director != null:
		wave_director.stop_waves()
		wave_director.start_wave(current_wave)

	RelicManager.notify_wave_started(current_wave)

func dev_kill_all_enemies() -> void:
	if board != null and board.enemy_container != null:
		for child in board.enemy_container.get_children():
			if child.has_method(&"take_hit"):
				child.take_hit(9999, null, Vector2.ZERO)
			elif child.has_method(&"despawn"):
				child.despawn()
			else:
				child.queue_free()

func dev_heal_full() -> void:
	current_hp = max_hp
	_update_hp_display(true)

func dev_set_hp(hp_val: int) -> void:
	current_hp = clamp(hp_val, 0, max_hp)
	_update_hp_display(true)

func dev_toggle_god_mode() -> bool:
	is_god_mode = not is_god_mode
	return is_god_mode

func _on_score_changed(new_score: int, _delta: int) -> void:
	current_score += new_score
	score_label.text = "SCORE: %d" % current_score

var _is_game_over_cinematic: bool = false
var _game_over_summary_data: Dictionary = {}
var _game_over_cinematic_tween: Tween = null

func _unhandled_input(event: InputEvent) -> void:
	# Permet de passer (skip) l'animation de fin de partie en touchant ou cliquant l'écran
	if _is_game_over_cinematic and (event is InputEventMouseButton or event is InputEventScreenTouch):
		if event.is_pressed():
			_skip_game_over_cinematic()

func _skip_game_over_cinematic() -> void:
	if not _is_game_over_cinematic:
		return
	_is_game_over_cinematic = false
	if _game_over_cinematic_tween != null and _game_over_cinematic_tween.is_valid():
		_game_over_cinematic_tween.kill()

	# Nettoie les ennemis restants
	if board != null and board.enemy_container != null:
		for child in board.enemy_container.get_children():
			if child.has_method(&"despawn"):
				child.despawn()
			else:
				child.queue_free()

	_display_game_over_modal()

func _display_game_over_modal() -> void:
	_is_game_over_cinematic = false
	if game_over_modal != null:
		game_over_modal.show_game_over(_game_over_summary_data)
	else:
		show_main_menu()

func _on_game_over() -> void:
	last_score = current_score
	if intermission_overlay != null:
		intermission_overlay.visible = false
	if wave_director != null:
		wave_director.stop_waves()
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = false
	touch_controls.visible = false
	
	if SaveManager.is_campaign():
		# Défaite en mode Campagne : participation minimale, sans polluer les statistiques de Survie
		var gold_earned: int = maxi(5, int(current_score / 250))
		var defeat_summary: Dictionary = SaveManager.record_campaign_defeat(active_level_data, current_score, gold_earned)
		var sub_txt: String = "1 / %d" % (active_level_data.waves.size() if active_level_data else 1)
		if wave_director != null and wave_director.total_subwaves > 0:
			sub_txt = "%d / %d" % [wave_director.current_subwave_index, wave_director.total_subwaves]

		_game_over_summary_data = {
			"mode": "campaign",
			"final_score": current_score,
			"subwave_text": sub_txt,
			"gold_earned": gold_earned,
			"best_score": defeat_summary.get("best_score", current_score),
			"is_new_record": defeat_summary.get("is_new_record", false)
		}
	else:
		# Fin de partie en mode Survie
		var waves_survived: int = maxi(0, current_wave - 1)
		var gold_earned: int = (waves_survived * 15) + int(current_score / 200)
		gold_earned = maxi(5, gold_earned)
		_game_over_summary_data = SaveManager.record_game_results(current_score, waves_survived, gold_earned)
		_game_over_summary_data["mode"] = "survival"
	
	# Déclenchement de la cinématique de fin de partie
	_is_game_over_cinematic = true

	# 1. Écroulement des portes et neutralisation des billes sur le plateau
	if board != null:
		board.play_game_over_sequence()

	# 2. Ruée de la horde d'ennemis vers la brèche sous le motif chocolat
	Enemy.trigger_game_over_horde_rush()

	# 3. Minuteur cinématique (1.8s) avant d'afficher la modale, skippable à tout moment par tap
	_game_over_cinematic_tween = create_tween()
	_game_over_cinematic_tween.tween_interval(1.8)
	_game_over_cinematic_tween.tween_callback(func() -> void:
		if _is_game_over_cinematic:
			_display_game_over_modal()
	)
