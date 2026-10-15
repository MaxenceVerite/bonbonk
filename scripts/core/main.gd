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

# HUD
@onready var btn_back_to_menu: Button = $UI/HUD/TopBar/VBox/TopRow/BtnBackMenu
@onready var score_label: Label = $UI/HUD/TopBar/VBox/TopRow/ScoreBadge/ScoreLabel
@onready var wave_label: Label = $UI/HUD/TopBar/VBox/TopRow/WaveBadge/WaveLabel
@onready var hp_bar: TextureProgressBar = $UI/HUD/TopBar/VBox/HPContainer/HPBar
@onready var hp_text_label: Label = $UI/HUD/TopBar/VBox/HPContainer/HPTextLabel
@onready var ball_factory_ui: BallFactoryUI = $UI/HUD/BallFactoryUI

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
	
	# Liaison Fabrique, Tube & Dual-Pods
	if board != null and ball_factory_ui != null:
		board.factory_state_changed.connect(ball_factory_ui.set_factory_state)
		ball_factory_ui.pod_launch_requested.connect(board.launch_ball_from_pod)
		
	# Démarrage au TitleScreen
	show_title_screen()

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
	if bumper_placement_overlay != null:
		bumper_placement_overlay.visible = false
	if board != null:
		board.visible = false
		board.reset_board()

func show_main_menu() -> void:
	current_screen_state = ScreenState.MENU
	title_screen.visible = false
	main_menu.visible = true
	hud.visible = false
	touch_controls.visible = false
	if bumper_placement_overlay != null:
		bumper_placement_overlay.visible = false
	
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
	intermission_overlay.visible = false

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

func _update_wave_display() -> void:
	if wave_label != null:
		wave_label.text = "MANCHE %d" % current_wave

func _on_wave_spawn_enemy(scene_path: String, spawn_x: float) -> void:
	if board != null and board.is_game_running:
		board.spawn_enemy_by_path(scene_path, spawn_x)

func _on_wave_cleared(cleared_wave_num: int) -> void:
	if current_hp <= 0:
		return
	if board != null:
		board.on_wave_cleared_stability()
	if ball_factory_ui != null:
		ball_factory_ui.is_interaction_enabled = false
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

func _on_score_changed(new_score: int, _delta: int) -> void:
	current_score += new_score
	score_label.text = "SCORE: %d" % current_score

func _on_game_over() -> void:
	last_score = current_score
	intermission_overlay.visible = false
	if wave_director != null:
		wave_director.is_wave_active = false
	# Petit délai puis retour au menu principal
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(show_main_menu)
