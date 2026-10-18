class_name Main
extends Node2D

## Scène racine orchestratrice du jeu de flipper.
## Gère la cinématique des écrans :
## 1. TitleScreen (Écran d'accueil avec 'Appuyer pour jouer')
## 2. MainMenu (Navbar : Collection, Jeu / Dernier score, Leaderboard)
## 3. Game Play (Arène active, HUD, TouchControls)

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

func _on_score_changed(new_score: int, _delta: int) -> void:
	current_score += new_score
	score_label.text = "SCORE: %d" % current_score

func _on_game_over() -> void:
	last_score = current_score
	if intermission_overlay != null:
		intermission_overlay.visible = false
	if wave_director != null:
		wave_director.stop_waves()
	if board != null:
		board.on_wave_cleared_stability()
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = false
	touch_controls.visible = false
	
	# Calcul du gain d'or : 15 pièces par manche réussie + bonus de 1 pièce par tranche de 200 pts
	var waves_survived: int = maxi(0, current_wave - 1)
	var gold_earned: int = (waves_survived * 15) + int(current_score / 200)
	gold_earned = maxi(5, gold_earned) # Récompense minimale de participation
	
	# Enregistrement dans SaveManager & Profil
	var summary_data: Dictionary = SaveManager.record_game_results(current_score, waves_survived, gold_earned)
	
	# Affichage de la modale récapitulative
	if game_over_modal != null:
		game_over_modal.show_game_over(summary_data)
	else:
		# Fallback vers le menu si absent
		var tween: Tween = create_tween()
		tween.tween_interval(1.2)
		tween.tween_callback(show_main_menu)
