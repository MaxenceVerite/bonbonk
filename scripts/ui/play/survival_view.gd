class_name SurvivalView
extends Control

## Vue Mode Survie : Hub Roguelike dédié.
## Affiche les records de vagues et scores, le deck de départ survie (6 slots) et le bouton de lancement direct.

signal survival_play_requested
signal deck_slot_clicked(slot_index: int)

@onready var best_wave_label: Label = $VBox/StatsCard/HBox/BestWaveBox/ValueLabel
@onready var best_score_label: Label = $VBox/StatsCard/HBox/BestScoreBox/ValueLabel

@onready var btn_prev_arena: Button = get_node_or_null("VBox/ArenaSelectorCard/Margin/HBox/BtnPrevArena") as Button
@onready var btn_next_arena: Button = get_node_or_null("VBox/ArenaSelectorCard/Margin/HBox/BtnNextArena") as Button
@onready var arena_name_label: Label = get_node_or_null("VBox/ArenaSelectorCard/Margin/HBox/ArenaInfoVBox/ArenaNameLabel") as Label
@onready var arena_header_label: Label = get_node_or_null("VBox/ArenaSelectorCard/Margin/HBox/ArenaInfoVBox/ArenaHeaderLabel") as Label
@onready var arena_banner_tex: TextureRect = get_node_or_null("VBox/ArenaSelectorCard/BannerTexture") as TextureRect
@onready var arena_info_vbox: VBoxContainer = get_node_or_null("VBox/ArenaSelectorCard/Margin/HBox/ArenaInfoVBox") as VBoxContainer

@onready var deck_slots_grid: GridContainer = $VBox/DeckCard/VBox/DeckSlotsGrid
@onready var btn_launch: Button = $VBox/BtnLaunchSurvival

var _arena_switch_tween: Tween = null

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
	_navigate_arena(-1)

func _on_next_arena_pressed() -> void:
	_navigate_arena(1)

func _navigate_arena(direction: int) -> void:
	var worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	if worlds.is_empty():
		return
	var cur_num: int = SaveManager.survival_selected_world
	var total: int = worlds.size()
	var next_num: int = posmod((cur_num - 1) + direction, total) + 1
	SaveManager.survival_selected_world = next_num
	_animate_arena_switch(direction)

func _animate_arena_switch(dir: int) -> void:
	if _arena_switch_tween != null and _arena_switch_tween.is_valid():
		_arena_switch_tween.kill()

	if arena_info_vbox != null:
		arena_info_vbox.position.x = 0.0
		arena_info_vbox.modulate.a = 1.0
	if arena_banner_tex != null:
		arena_banner_tex.modulate.a = 1.0

	_arena_switch_tween = create_tween()

	# Phase 1 : sortie rapide (0.10s)
	# Phase 1 : sortie rapide (0.10s)
	if arena_info_vbox != null:
		_arena_switch_tween.tween_property(arena_info_vbox, "position:x", float(-dir * 45), 0.10).as_relative()
		_arena_switch_tween.parallel().tween_property(arena_info_vbox, "modulate:a", 0.0, 0.10)
	if arena_banner_tex != null:
		_arena_switch_tween.parallel().tween_property(arena_banner_tex, "modulate:a", 0.25, 0.10)

	# Phase 2 : transition chaînée
	_arena_switch_tween.chain().tween_callback(func() -> void:
		_refresh_arena()
		if arena_info_vbox != null:
			arena_info_vbox.position.x = float(dir * 45)
			arena_info_vbox.modulate.a = 0.0
	)

	# Phase 3 : entrée rebondissante chaînée (0.20s)
	if arena_info_vbox != null:
		_arena_switch_tween.chain().tween_property(arena_info_vbox, "position:x", 0.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_arena_switch_tween.parallel().tween_property(arena_info_vbox, "modulate:a", 1.0, 0.16)
	if arena_banner_tex != null:
		_arena_switch_tween.parallel().tween_property(arena_banner_tex, "modulate:a", 1.0, 0.20)

func refresh() -> void:
	_refresh_stats()
	_refresh_arena()
	_refresh_deck()

func _refresh_arena() -> void:
	var w: WorldData = CampaignCatalog.get_world_by_number(SaveManager.survival_selected_world)
	if w == null:
		return
	if arena_name_label != null:
		arena_name_label.text = w.display_name.to_upper()
	if arena_header_label != null:
		arena_header_label.text = "ARÈNE %d • SURVIE" % w.world_number
	if arena_banner_tex != null and w.banner_texture != null:
		arena_banner_tex.texture = w.banner_texture

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
