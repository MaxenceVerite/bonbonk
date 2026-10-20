class_name Main
extends Node2D

## Scène racine orchestratrice du jeu de flipper.
## Gère la cinématique des écrans :
## 1. TitleScreen (Écran d'accueil avec 'Appuyer pour jouer')
## 2. MainMenu (Navbar : Collection, Jeu / Dernier score, Leaderboard)
## 3. Game Play (Arène active, HUD, TouchControls)

const DamageNumberManagerScript = preload("res://scripts/ui/damage_numbers/damage_number_manager.gd")

enum ScreenState { TITLE, MENU, GAME }
var current_screen_state: ScreenState = ScreenState.TITLE

@onready var board: Board = $Board
@onready var touch_controls: TouchControls = $UI/TouchControls
@onready var hud: Control = $UI/HUD
@onready var title_screen: TitleScreen = $UI/TitleScreen
@onready var main_menu: MainMenu = $UI/MainMenu
@onready var booster_modal: BoosterOpeningModal = $UI/BoosterOpeningModal
@onready var intermission_overlay: IntermissionOverlay = $UI/IntermissionOverlay
@onready var bumper_placement_overlay: BumperPlacementOverlay = $UI/BumperPlacementOverlay
@onready var game_over_modal: GameOverModal = $UI/GameOverModal

# HUD
@onready var btn_back_to_menu: Button = $UI/HUD/TopBar/VBox/TopRow/BtnBackMenu
@onready var score_label: Label = $UI/HUD/TopBar/VBox/TopRow/ScoreBadge/ScoreLabel
@onready var wave_label: Label = $UI/HUD/TopBar/VBox/TopRow/WaveBadge/WaveLabel
@onready var hp_bar: TextureProgressBar = $UI/HUD/BottomBar/HPContainer/HPBar
@onready var hp_text_label: Label = $UI/HUD/BottomBar/HPContainer/HPTextLabel
@onready var ball_factory_ui: BallFactoryUI = $UI/BallFactoryUI

var wave_director: WaveDirector = null
var damage_number_manager: Node = null
var current_wave: int = 1
var max_hp: int = 100
var current_hp: int = 100
var current_score: int = 0
var last_score: int = 0

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
	
	if intermission_overlay != null:
		intermission_overlay.next_wave_pressed.connect(_on_next_wave_pressed)

	if bumper_placement_overlay != null:
		bumper_placement_overlay.placement_completed.connect(_on_bumper_placement_completed)
	
	if game_over_modal != null:
		game_over_modal.replay_pressed.connect(launch_game)
		game_over_modal.return_to_menu_pressed.connect(show_main_menu)
	
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

func _on_open_booster_requested() -> void:
	if SaveManager.available_boosters.is_empty():
		return
	var booster: BoosterData = SaveManager.available_boosters.pop_front()
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
	if wave_director != null:
		wave_director.stop_waves()

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
		_start_board_gameplay()

func _on_bumper_placement_completed() -> void:
	hud.visible = true
	touch_controls.visible = true
	_start_board_gameplay()

func _start_board_gameplay() -> void:
	if board != null:
		board.start_game()
	if wave_director != null:
		wave_director.start_wave(current_wave)
	RelicManager.notify_wave_started(current_wave)

func _update_wave_display() -> void:
	if wave_label != null:
		wave_label.text = "MANCHE %d" % current_wave

func _on_wave_spawn_enemy(scene_path: String, spawn_x: float) -> void:
	if board != null and board.is_game_running:
		board.spawn_enemy_by_path(scene_path, spawn_x)

func _on_wave_cleared(cleared_wave_num: int) -> void:
	# Sécurité stricte : ignorer si on n'est plus en partie active ou si mort
	if current_screen_state != ScreenState.GAME or current_hp <= 0:
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
	
	# Calcul du gain d'or : 15 pièces par manche réussie + bonus de 1 pièce par tranche de 200 pts
	var waves_survived: int = maxi(0, current_wave - 1)
	var gold_earned: int = (waves_survived * 15) + int(current_score / 200)
	gold_earned = maxi(5, gold_earned) # Récompense minimale de participation
	
	# Enregistrement dans SaveManager & Profil
	_game_over_summary_data = SaveManager.record_game_results(current_score, waves_survived, gold_earned)
	
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
