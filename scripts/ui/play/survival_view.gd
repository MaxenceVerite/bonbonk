class_name SurvivalView
extends Control

## Vue Mode Survie : Hub Roguelike dédié.
## Affiche les records de vagues et scores, le deck de départ survie (6 slots) et le bouton de lancement direct.

signal survival_play_requested
signal deck_slot_clicked(slot_index: int)

@onready var best_wave_label: Label = $VBox/StatsCard/HBox/BestWaveBox/ValueLabel
@onready var best_score_label: Label = $VBox/StatsCard/HBox/BestScoreBox/ValueLabel
@onready var btn_prev_arena: Button = get_node_or_null("VBox/ArenaSelectorCard/HBox/BtnPrevArena") as Button
@onready var btn_next_arena: Button = get_node_or_null("VBox/ArenaSelectorCard/HBox/BtnNextArena") as Button
@onready var arena_name_label: Label = get_node_or_null("VBox/ArenaSelectorCard/HBox/ArenaInfoVBox/ArenaNameLabel") as Label
@onready var deck_slots_grid: GridContainer = $VBox/DeckCard/VBox/DeckSlotsGrid
@onready var btn_launch: Button = $VBox/BtnLaunchSurvival

func _ready() -> void:
	if btn_launch != null:
		btn_launch.pressed.connect(func() -> void:
			survival_play_requested.emit()
		)

	if btn_prev_arena != null:
		btn_prev_arena.pressed.connect(_on_prev_arena_pressed)
	if btn_next_arena != null:
		btn_next_arena.pressed.connect(_on_next_arena_pressed)

	if deck_slots_grid != null:
		var slot_children: Array = deck_slots_grid.get_children()
		for i in range(slot_children.size()):
			var slot_btn: DeckSlotButton = slot_children[i] as DeckSlotButton
			if slot_btn != null:
				slot_btn.slot_index = i
				slot_btn.slot_pressed.connect(_on_slot_pressed)

	refresh()

func _on_prev_arena_pressed() -> void:
	var worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if worlds.is_empty():
		return
	var cur_num: int = SaveManager.survival_selected_world
	var next_num: int = cur_num - 1
	if next_num < 1:
		next_num = worlds.size()
	SaveManager.survival_selected_world = next_num
	_refresh_arena()

func _on_next_arena_pressed() -> void:
	var worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if worlds.is_empty():
		return
	var cur_num: int = SaveManager.survival_selected_world
	var next_num: int = cur_num + 1
	if next_num > worlds.size():
		next_num = 1
	SaveManager.survival_selected_world = next_num
	_refresh_arena()

func refresh() -> void:
	_refresh_stats()
	_refresh_arena()
	_refresh_deck()

func _refresh_arena() -> void:
	var w: WorldData = CampaignCatalog.get_world_by_number(SaveManager.survival_selected_world)
	if arena_name_label != null and w != null:
		arena_name_label.text = w.display_name.to_upper()

func _refresh_stats() -> void:
	var prof: RefCounted = SaveManager.current_profile
	var best_score: int = 0
	var best_wave: int = 1
	if prof != null:
		best_score = int(prof.stats.get("best_score", 0))
		best_wave = int(prof.stats.get("best_wave", 1))

	if best_wave_label != null:
		best_wave_label.text = "VAGUE %d" % best_wave
	if best_score_label != null:
		best_score_label.text = "%d PTS" % best_score

func _refresh_deck() -> void:
	# En mode survie, on utilise le deck actif de survie
	var cur_deck: Array = SaveManager.get_active_deck()
	if deck_slots_grid != null:
		var slot_children: Array = deck_slots_grid.get_children()
		for i in range(slot_children.size()):
			var slot_btn: DeckSlotButton = slot_children[i] as DeckSlotButton
			if slot_btn != null:
				if i < cur_deck.size():
					slot_btn.set_card(cur_deck[i])
				else:
					slot_btn.set_card(&"")

func _on_slot_pressed(slot_idx: int) -> void:
	deck_slot_clicked.emit(slot_idx)
