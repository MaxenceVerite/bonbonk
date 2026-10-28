class_name MainMenu
extends Control

## Menu principal avec Navbar mobile inférieure pour switcher entre les onglets :
## - Collection (déblocages, boosters à ouvrir)
## - Play / Jeu (dernier score, bouton Jouer)
## - Leaderboard (meilleurs scores)

const ShopUIBuilder = preload("res://scripts/ui/shop/shop_ui_builder.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const CampaignCatalog = preload("res://scripts/data/campaign_catalog.gd")
const AdventureView = preload("res://scripts/ui/play/adventure_view.gd")
const SurvivalView = preload("res://scripts/ui/play/survival_view.gd")

const LeaderboardView = preload("res://scripts/ui/play/leaderboard_view.gd")

signal play_pressed

@onready var tab_collection: Control = $ContentContainer/CollectionTab
@onready var tab_play: Control = $ContentContainer/PlayTab
@onready var tab_leaderboard: Control = $ContentContainer/LeaderboardTab
@onready var tab_shop: Control = $ContentContainer/ShopTab

@onready var btn_shop: Button = $NavBar/HBoxContainer/BtnShop
@onready var btn_collection: Button = $NavBar/HBoxContainer/BtnCollection
@onready var btn_play: Button = $NavBar/HBoxContainer/BtnPlay
@onready var btn_leaderboard: Button = $NavBar/HBoxContainer/BtnLeaderboard
@onready var leaderboard_view: LeaderboardView = $ContentContainer/LeaderboardTab/LeaderboardView

# Éléments Header
@onready var btn_account: Button = $TopGoldBar/HBox/BtnAccount
@onready var gold_badge: PanelContainer = $TopGoldBar/HBox/GoldBadge
@onready var diamond_badge: PanelContainer = $TopGoldBar/HBox/DiamondBadge
@onready var gold_label: Label = $TopGoldBar/HBox/GoldBadge/HBoxG/GoldLabel
@onready var diamond_label: Label = $TopGoldBar/HBox/DiamondBadge/HBoxD/DiamondLabel
@onready var btn_add_gold: Button = $TopGoldBar/HBox/GoldBadge/HBoxG/BtnAddGold
@onready var btn_add_diamonds: Button = $TopGoldBar/HBox/DiamondBadge/HBoxD/BtnAddDiamonds
@onready var account_modal: Control = $AccountModal
@onready var player_name_modal: Control = $PlayerNameModal
@onready var shop_reward_modal: ShopRewardModal = $ShopRewardModal
@onready var currency_fly_layer: Control = $CurrencyFlyLayer

const COIN_3D_TEX: Texture2D = preload("res://assets/ui/coin_gold_3d.png")
const GEM_3D_TEX: Texture2D = preload("res://assets/ui/gem_diamond_3d.png")
const SPARKLE_TEX: Texture2D = preload("res://assets/ui/sparkle_star.png")

var _pending_reward_item: ShopItemData = null
var _pending_start_gold: int = 0
var _pending_start_diamonds: int = 0
var _is_flying_currency: bool = false


# Éléments Rack de Sachets (4 slots façon Clash Royale)
@onready var booster_rack_title: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/VBox/HeaderHBox/Title
@onready var booster_rack_badge: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/VBox/HeaderHBox/Badge
@onready var btn_shop_shortcut: Button = $ContentContainer/CollectionTab/VBox/BoostersCard/VBox/HeaderHBox/ShopShortcutBtn
@onready var slots_hbox: HBoxContainer = $ContentContainer/CollectionTab/VBox/BoostersCard/VBox/SlotsHBox
@onready var balls_tray: Control = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsTrayMargin/BallsTray
@onready var balls_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsTrayMargin/BallsTray/VBox/BallsBanner/BallsHeaderLabel
@onready var balls_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsTrayMargin/BallsTray/VBox/BallsGridMargin/BallsGrid
@onready var bumpers_tray: Control = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersTrayMargin/BumpersTray
@onready var bumpers_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersTrayMargin/BumpersTray/VBox/BumpersBanner/BumpersHeaderLabel
@onready var bumpers_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersTrayMargin/BumpersTray/VBox/BumpersGridMargin/BumpersGrid

# Filtres Collection (Tactile façon Clash Royale)
@onready var btn_sort_rarity: Button = $ContentContainer/CollectionTab/VBox/FilterBar/HBox/BtnSortRarity
@onready var btn_sort_level: Button = $ContentContainer/CollectionTab/VBox/FilterBar/HBox/BtnSortLevel

enum SortMode { LEVEL, RARITY }
var current_sort_mode: SortMode = SortMode.LEVEL
var is_sort_descending: bool = true

# Modale Détail Carte
@onready var card_detail_modal: CardDetailModal = $CardDetailModal
@onready var card_picker_modal: CardPickerModal = $CardPickerModal

# Éléments Shop Tab
@onready var shop_scroll: ScrollContainer = $ContentContainer/ShopTab/VBox/ScrollContainer
@onready var shop_sections_vbox: VBoxContainer = $ContentContainer/ShopTab/VBox/ScrollContainer/ShopBoardMargin/ShopBoardPanel/SectionsVBox

# Éléments Play Tab (Vues Aventure & Survie)
@onready var btn_subtab_adventure: Button = $ContentContainer/PlayTab/VBox/SubNavModeBar/ModeTabsRow/BtnSubTabAdventure
@onready var btn_subtab_survival: Button = $ContentContainer/PlayTab/VBox/SubNavModeBar/ModeTabsRow/BtnSubTabSurvival
@onready var adventure_view: AdventureView = $ContentContainer/PlayTab/VBox/ViewsContainer/AdventureView
@onready var survival_view: SurvivalView = $ContentContainer/PlayTab/VBox/ViewsContainer/SurvivalView

var selected_campaign_level: int = 1
var last_score: int = 0
var collection_card_scene: PackedScene = preload("res://scenes/ui/collection/collection_card.tscn")

# Carrousel horizontal continu (façon Clash Royale / ViewPager)
const TAB_WIDTH: float = 720.0
const TAB_KEYS: Array[StringName] = [&"shop", &"collection", &"play", &"leaderboard"]

var tabs_track: Control = null
var current_tab_index: int = 2
var _tab_tween: Tween = null

# Détection et suivi du swipe tactile
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: int = 0
var _track_start_x: float = 0.0
var _is_touching: bool = false
var _is_dragging_horizontal: bool = false
var _gesture_locked: bool = false

# Badge notification façon Clash Royale
var notif_badge: PanelContainer = null
var notif_label: Label = null

func _ready() -> void:
	_setup_horizontal_carousel()

	if "--screenshot" in OS.get_cmdline_args() or "--screenshot" in OS.get_cmdline_user_args():
		call_deferred("_take_menu_screenshot")

	btn_shop.pressed.connect(func() -> void: switch_to_tab_index(0, true))
	btn_collection.pressed.connect(func() -> void: switch_to_tab_index(1, true))
	btn_play.pressed.connect(func() -> void: switch_to_tab_index(2, true))
	btn_leaderboard.pressed.connect(func() -> void: switch_to_tab_index(3, true))
	
	btn_add_gold.pressed.connect(func() -> void:
		switch_to_tab_index(0, true)
		_scroll_to_currency_section()
	)
	btn_add_diamonds.pressed.connect(func() -> void:
		switch_to_tab_index(0, true)
		_scroll_to_currency_section()
	)
	btn_shop_shortcut.pressed.connect(func() -> void:
		switch_to_tab_index(0, true)
	)
	_setup_booster_slots()

	# Filtres Collection (Touch toggle)
	btn_sort_rarity.pressed.connect(_on_btn_sort_rarity_pressed)
	btn_sort_level.pressed.connect(_on_btn_sort_level_pressed)
	_update_sort_buttons_ui()
	
	# Modale
	card_detail_modal.card_upgraded_locally.connect(func(_id: StringName) -> void:
		_refresh_collection_ui()
		_refresh_deck_ui()
		_update_currency_display()
		_update_collection_badge()
	)
	card_detail_modal.replace_requested.connect(func(slot_idx: int, _cid: StringName) -> void:
		if card_picker_modal != null:
			card_picker_modal.open_for_slot(slot_idx)
	)

	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.diamonds_changed.connect(_on_diamonds_changed)
	EventBus.card_upgraded.connect(_on_card_upgraded)
	EventBus.booster_opened.connect(_on_booster_opened)
	EventBus.shop_item_purchased.connect(_on_shop_purchased)
	EventBus.open_shop_requested.connect(_on_open_shop_requested)
	EventBus.deck_changed.connect(func(_idx: int) -> void: _refresh_deck_ui())

	# Sélecteur de Mode (Aventure / Survie)
	if btn_subtab_adventure != null:
		btn_subtab_adventure.pressed.connect(func() -> void:
			SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
			_refresh_play_tab()
		)
	if btn_subtab_survival != null:
		btn_subtab_survival.pressed.connect(func() -> void:
			SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
			_refresh_play_tab()
		)

	if adventure_view != null:
		adventure_view.level_play_requested.connect(_on_adventure_play_requested)
		adventure_view.deck_edit_requested.connect(_on_deck_slot_clicked)

	if survival_view != null:
		survival_view.survival_play_requested.connect(_on_survival_play_requested)
		survival_view.deck_slot_clicked.connect(_on_deck_slot_clicked)

	if card_picker_modal != null:
		card_picker_modal.card_chosen.connect(func(_cid: StringName) -> void:
			_refresh_deck_ui()
		)

	if leaderboard_view != null:
		leaderboard_view.open_account_requested.connect(func() -> void:
			if account_modal != null:
				account_modal.open()
		)
		leaderboard_view.play_survival_requested.connect(func() -> void:
			SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
			switch_to_tab_index(2, true)
		)

	if shop_reward_modal != null:
		shop_reward_modal.purchase_confirmed.connect(_on_shop_purchase_confirmed)
		shop_reward_modal.purchase_cancelled.connect(_on_shop_purchase_cancelled)
		shop_reward_modal.reward_claimed.connect(_on_shop_reward_claimed)
		shop_reward_modal.open_booster_requested.connect(_on_shop_reward_open_booster)

	visibility_changed.connect(func() -> void:
		if visible:
			refresh()
	)

	if btn_account != null and account_modal != null:
		btn_account.pressed.connect(account_modal.open)
		if account_modal.has_signal(&"edit_name_requested") and player_name_modal != null:
			account_modal.edit_name_requested.connect(player_name_modal.open)

	if player_name_modal != null:
		player_name_modal.name_confirmed.connect(func(_new_name: String) -> void:
			_refresh_account_button()
			if account_modal != null and account_modal.has_method(&"_refresh_ui"):
				account_modal._refresh_ui()
		)
		# Demande de pseudo à l'accueil uniquement pour un tout nouveau compte sans nom
		var current_name: String = SaveManager.current_profile.display_name if SaveManager.current_profile != null else ""
		var is_default_name: bool = current_name.is_empty() or current_name == "Gourmand" or current_name.begins_with("Gourmand_")
		if SaveManager.current_profile != null and (not SaveManager.current_profile.has_chosen_name and is_default_name):
			get_tree().create_timer(0.4).timeout.connect(func() -> void:
				if player_name_modal != null and SaveManager.current_profile != null:
					var p_name: String = SaveManager.current_profile.display_name
					if not SaveManager.current_profile.has_chosen_name and (p_name == "Gourmand" or p_name.begins_with("Gourmand_")):
						player_name_modal.open()
			)
		elif SaveManager.current_profile != null and not is_default_name:
			SaveManager.current_profile.has_chosen_name = true

	EventBus.profile_loaded.connect(func(_pid: String) -> void:
		_refresh_account_button()
		_update_currency_display()
		_refresh_collection_ui()
		_refresh_deck_ui()
		_refresh_leaderboard_ui()
		_update_collection_badge()
	)
	EventBus.cloud_sync_status_changed.connect(func(_s: String, _m: String) -> void:
		_refresh_account_button()
	)
	EventBus.open_account_modal_requested.connect(func() -> void:
		if account_modal != null:
			account_modal.open()
	)

	_animate_booster_banner()
	_update_currency_display()
	_refresh_account_button()
	_refresh_collection_ui()
	_refresh_shop_ui()
	_refresh_play_tab()
	_refresh_leaderboard_ui()
	_update_collection_badge()
	switch_to_tab_index(2, false) # Démarre sur le jeu sans animation

func _refresh_leaderboard_ui() -> void:
	if leaderboard_view != null:
		leaderboard_view.refresh()

func _refresh_account_button() -> void:
	if btn_account == null or SaveManager.current_profile == null:
		return
	var prof: RefCounted = SaveManager.current_profile
	var cloud_icon: String = "⚪"
	if SaveManager.cloud_sync != null and SaveManager.cloud_sync.is_online():
		cloud_icon = "🟢"
	btn_account.text = "%s 👤 %s" % [cloud_icon, prof.display_name]

func set_last_score(val: int) -> void:
	last_score = val

func _on_deck_slot_clicked(slot_idx: int) -> void:
	var deck: Array = SaveManager.get_active_deck()
	if slot_idx >= 0 and slot_idx < deck.size():
		var card_id: StringName = deck[slot_idx]
		if card_detail_modal != null:
			card_detail_modal.open_for_deck_slot(slot_idx, card_id)
			return
	if card_picker_modal != null:
		card_picker_modal.open_for_slot(slot_idx)

func _refresh_deck_ui() -> void:
	if adventure_view != null:
		adventure_view.refresh()
	if survival_view != null:
		survival_view.refresh()

func _refresh_play_tab() -> void:
	var is_campaign: bool = SaveManager.is_campaign()

	if btn_subtab_adventure != null:
		btn_subtab_adventure.button_pressed = is_campaign
	if btn_subtab_survival != null:
		btn_subtab_survival.button_pressed = not is_campaign

	if adventure_view != null:
		adventure_view.visible = is_campaign
		if is_campaign:
			adventure_view.refresh()

	if survival_view != null:
		survival_view.visible = not is_campaign
		if not is_campaign:
			survival_view.refresh()

func _setup_horizontal_carousel() -> void:
	var content_container: Control = $ContentContainer
	content_container.clip_contents = true
	
	tabs_track = Control.new()
	tabs_track.name = "TabsTrack"
	tabs_track.layout_mode = 1
	tabs_track.anchors_preset = Control.PRESET_FULL_RECT
	tabs_track.anchor_right = 1.0
	tabs_track.anchor_bottom = 1.0
	tabs_track.offset_right = 0.0
	tabs_track.offset_bottom = 0.0
	tabs_track.mouse_filter = Control.MOUSE_FILTER_PASS
	content_container.add_child(tabs_track)
	
	# Ordre Clash Royale: 0=Boutique, 1=Collection/Cartes, 2=Jeu/Bataille, 3=Classement
	var ordered_tabs: Array[Control] = [tab_shop, tab_collection, tab_play, tab_leaderboard]
	for i in range(ordered_tabs.size()):
		var t: Control = ordered_tabs[i]
		t.reparent(tabs_track)
		t.visible = true
		t.layout_mode = 0
		t.position = Vector2(float(i) * TAB_WIDTH, 0.0)
		t.size = Vector2(TAB_WIDTH, content_container.size.y)
		t.custom_minimum_size = Vector2(TAB_WIDTH, 0.0)

	_setup_navbar_badges()

func _setup_navbar_badges() -> void:
	pass

func _update_collection_badge() -> void:
	pass
func _on_btn_sort_rarity_pressed() -> void:
	if current_sort_mode == SortMode.RARITY:
		is_sort_descending = not is_sort_descending
	else:
		current_sort_mode = SortMode.RARITY
		is_sort_descending = true
	_update_sort_buttons_ui()
	_refresh_collection_ui()

func _on_btn_sort_level_pressed() -> void:
	if current_sort_mode == SortMode.LEVEL:
		is_sort_descending = not is_sort_descending
	else:
		current_sort_mode = SortMode.LEVEL
		is_sort_descending = true
	_update_sort_buttons_ui()
	_refresh_collection_ui()

func _update_sort_buttons_ui() -> void:
	if btn_sort_level != null:
		var arrow_lvl: String = "↓" if is_sort_descending else "↑"
		if current_sort_mode == SortMode.LEVEL:
			btn_sort_level.text = "Niveau %s" % arrow_lvl
			btn_sort_level.modulate = Color.WHITE
		else:
			btn_sort_level.text = "Niveau"
			btn_sort_level.modulate = Color(0.75, 0.85, 0.95, 0.8)
			
	if btn_sort_rarity != null:
		var arrow_rar: String = "↓" if is_sort_descending else "↑"
		if current_sort_mode == SortMode.RARITY:
			btn_sort_rarity.text = "Rareté %s" % arrow_rar
			btn_sort_rarity.modulate = Color.WHITE
		else:
			btn_sort_rarity.text = "Rareté"
			btn_sort_rarity.modulate = Color(0.75, 0.85, 0.95, 0.8)

func switch_tab(tab_name: StringName) -> void:
	var idx: int = TAB_KEYS.find(tab_name)
	if idx >= 0:
		switch_to_tab_index(idx, true)

func switch_to_tab_index(idx: int, animated: bool = true) -> void:
	idx = clampi(idx, 0, TAB_KEYS.size() - 1)
	current_tab_index = idx
	var target_x: float = -float(idx) * TAB_WIDTH
	
	if tabs_track != null:
		if animated:
			if _tab_tween != null and _tab_tween.is_valid():
				_tab_tween.kill()
			_tab_tween = create_tween()
			_tab_tween.tween_property(tabs_track, "position:x", target_x, 0.28)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
		else:
			tabs_track.position.x = target_x
			
	_update_navbar_ui(idx)
	
	if idx == 1:
		_refresh_collection_ui()
	elif idx == 0:
		_refresh_shop_ui()
	elif idx == 2:
		_refresh_play_tab()
	elif idx == 3:
		_refresh_leaderboard_ui()
		
	_update_collection_badge()
	EventBus.main_menu_tab_changed.emit(TAB_KEYS[idx])

## Rafraîchit l'ensemble des données visibles du menu (devises, badges, cartes d'aventure)
func refresh() -> void:
	_update_currency_display()
	_update_collection_badge()
	_refresh_play_tab()
	if current_tab_index == 0:
		_refresh_shop_ui()
	elif current_tab_index == 1:
		_refresh_collection_ui()
	elif current_tab_index == 3:
		_refresh_leaderboard_ui()

func _update_navbar_ui(active_idx: int) -> void:
	var nav_buttons: Array[Button] = [btn_shop, btn_collection, btn_play, btn_leaderboard]
	var tab_names: Array[String] = ["SHOP", "COLLECTION", "JOUER", "TOP"]
	
	for i in range(nav_buttons.size()):
		var btn: Button = nav_buttons[i]
		if btn == null:
			continue
		var is_active: bool = (i == active_idx)
		btn.text = ""
		btn.size_flags_stretch_ratio = 1.35 if is_active else 0.88
		_style_nav_button(btn, is_active)
		
		# Icône : agrandie et ressortant nettement en haut de l'onglet actif
		var icon: TextureRect = btn.get_node_or_null("VBox/IconAnchor/Icon") as TextureRect
		if icon != null:
			if is_active:
				btn.z_index = 1
				icon.z_index = 2
				icon.custom_minimum_size = Vector2(92, 80)
				icon.offset_left = -46.0
				icon.offset_top = -68.0
				icon.offset_right = 46.0
				icon.offset_bottom = 12.0
			else:
				btn.z_index = 0
				icon.z_index = 0
				icon.custom_minimum_size = Vector2(62, 54)
				icon.offset_left = -31.0
				icon.offset_top = -27.0
				icon.offset_right = 31.0
				icon.offset_bottom = 27.0
		
		var arrow_l: Control = btn.get_node_or_null("VBox/HBoxLbl/ArrowL")
		var arrow_r: Control = btn.get_node_or_null("VBox/HBoxLbl/ArrowR")
		var lbl: Label = btn.get_node_or_null("VBox/HBoxLbl/Label")
		if arrow_l != null:
			arrow_l.visible = is_active
		if arrow_r != null:
			arrow_r.visible = is_active
		if lbl != null:
			lbl.text = tab_names[i]
			if is_active:
				lbl.add_theme_color_override("font_color", Color(0.28, 0.12, 0.04, 1.0))
				lbl.remove_theme_color_override("font_outline_color")
				lbl.add_theme_constant_override("outline_size", 0)
			else:
				lbl.add_theme_color_override("font_color", Color.WHITE)
				lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.20, 0.32, 1.0))
				lbl.add_theme_constant_override("outline_size", 4)

func _style_nav_button(btn: Button, is_active: bool) -> void:
	btn.modulate = Color.WHITE
	btn.theme_type_variation = &"NavButtonActive" if is_active else &"NavButton"

func _input(event: InputEvent) -> void:
	# Ignore les swipes si une modale est ouverte
	if card_detail_modal != null and card_detail_modal.visible:
		return
	if card_picker_modal != null and card_picker_modal.visible:
		return
	if account_modal != null and account_modal.visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.position.y >= 70.0 and event.position.y <= 1180.0:
					_start_touch(event.position)
			else:
				if _is_touching:
					_end_touch(event.position)
	elif event is InputEventMouseMotion:
		if _is_touching:
			_move_touch(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.y >= 70.0 and event.position.y <= 1180.0:
				_start_touch(event.position)
		else:
			if _is_touching:
				_end_touch(event.position)
	elif event is InputEventScreenDrag:
		if _is_touching:
			_move_touch(event.position)

func _start_touch(pos: Vector2) -> void:
	_is_touching = true
	_touch_start_pos = pos
	_touch_start_time = Time.get_ticks_msec()
	_track_start_x = tabs_track.position.x if tabs_track != null else -float(current_tab_index) * TAB_WIDTH
	_is_dragging_horizontal = false
	_gesture_locked = false

func _move_touch(pos: Vector2) -> void:
	var diff: Vector2 = pos - _touch_start_pos
	if not _gesture_locked:
		if absf(diff.x) > 12.0 or absf(diff.y) > 12.0:
			_gesture_locked = true
			if absf(diff.x) > absf(diff.y) * 1.15:
				_is_dragging_horizontal = true
				if _tab_tween != null and _tab_tween.is_valid():
					_tab_tween.kill()
			else:
				_is_dragging_horizontal = false
				
	if _is_dragging_horizontal and tabs_track != null:
		var tx: float = _track_start_x + diff.x
		var min_bound: float = -3.0 * TAB_WIDTH
		var max_bound: float = 0.0
		# Résistance élastique aux extrémités
		if tx > max_bound:
			tx = max_bound + (tx - max_bound) * 0.32
		elif tx < min_bound:
			tx = min_bound + (tx - min_bound) * 0.32
		tabs_track.position.x = tx

func _end_touch(pos: Vector2) -> void:
	_is_touching = false
	if _is_dragging_horizontal:
		_is_dragging_horizontal = false
		var delta_x: float = pos.x - _touch_start_pos.x
		var duration_s: float = float(maxi(1, Time.get_ticks_msec() - _touch_start_time)) / 1000.0
		var vx: float = delta_x / duration_s
		
		# Swipe franc ou flick rapide
		if delta_x < -100.0 or (vx < -450.0 and delta_x < -30.0):
			switch_to_tab_index(current_tab_index + 1, true)
		elif delta_x > 100.0 or (vx > 450.0 and delta_x > 30.0):
			switch_to_tab_index(current_tab_index - 1, true)
		else:
			# Rebond sur l'onglet actuel
			switch_to_tab_index(current_tab_index, true)

func _update_currency_display() -> void:
	if not _is_flying_currency:
		if gold_label != null:
			gold_label.text = "%d 🪙" % SaveManager.gold
		if diamond_label != null:
			diamond_label.text = "%d 💎" % SaveManager.diamonds

func _on_gold_changed(_new_val: int, _delta: int) -> void:
	if not _is_flying_currency:
		_update_currency_display()
	_refresh_collection_ui()
	_refresh_shop_ui()

func _on_diamonds_changed(_new_val: int, _delta: int) -> void:
	if not _is_flying_currency:
		_update_currency_display()
	_refresh_shop_ui()

func _on_card_upgraded(_card_id: StringName, _lvl: int) -> void:
	_refresh_collection_ui()

func _on_booster_opened(_result: Dictionary) -> void:
	_update_currency_display()
	_refresh_collection_ui()

func _on_shop_purchased(_item_id: StringName, _currency: StringName) -> void:
	_update_currency_display()
	_refresh_collection_ui()
	_refresh_shop_ui()

func _on_open_shop_requested(_hint: StringName) -> void:
	switch_tab(&"shop")

func _scroll_to_currency_section() -> void:
	if shop_scroll != null:
		shop_scroll.scroll_vertical = 600

static func get_slot_occupied_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_content_margin_all(6.0)
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.bg_color = Color(0.96, 0.91, 0.82, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 5
	sb.border_color = Color(0.78, 0.64, 0.48, 1.0)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0.18, 0.08, 0.03, 0.20)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	return sb

static func get_slot_empty_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_content_margin_all(6.0)
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.bg_color = Color(0.85, 0.77, 0.67, 0.45)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.72, 0.62, 0.50, 0.50)
	sb.set_corner_radius_all(18)
	return sb

func _setup_booster_slots() -> void:
	if slots_hbox == null:
		return
	for i in range(4):
		var slot_node: PanelContainer = slots_hbox.get_node_or_null("Slot%d" % i) as PanelContainer
		if slot_node == null:
			continue
		var btn: Button = slot_node.get_node_or_null("BtnSlotClick") as Button
		if btn == null:
			btn = slot_node.get_node_or_null("VBox/BtnAction") as Button
		if btn != null:
			var slot_idx: int = i
			btn.pressed.connect(func() -> void: _on_slot_clicked(slot_idx))

func _on_slot_clicked(slot_idx: int) -> void:
	if slot_idx < SaveManager.available_boosters.size():
		var booster: BoosterData = SaveManager.available_boosters[slot_idx]
		SaveManager.available_boosters.remove_at(slot_idx)
		EventBus.open_booster_modal_requested.emit(booster)
	else:
		# Emplacement vide : invite le joueur à jouer une partie pour gagner des sachets
		switch_to_tab_index(2, true)

func _animate_booster_banner() -> void:
	if slots_hbox == null:
		return
	for i in range(4):
		var slot_node: PanelContainer = slots_hbox.get_node_or_null("Slot%d" % i) as PanelContainer
		if slot_node == null:
			continue
		var icon: TextureRect = slot_node.get_node_or_null("VBox/IconAnchor/Icon") as TextureRect
		var glow: TextureRect = slot_node.get_node_or_null("VBox/IconAnchor/Glow") as TextureRect
		if icon != null and icon.visible:
			var tw_float: Tween = create_tween().set_loops()
			tw_float.tween_property(icon, "position:y", -4.0, 1.1 + i * 0.15).set_trans(Tween.TRANS_SINE).as_relative()
			tw_float.tween_property(icon, "position:y", 4.0, 1.1 + i * 0.15).set_trans(Tween.TRANS_SINE).as_relative()
		if glow != null and glow.visible:
			var tw_glow: Tween = create_tween().set_loops()
			tw_glow.tween_property(glow, "rotation_degrees", 360.0, 10.0 + i * 2.0).from(0.0)

func _refresh_boosters_rack() -> void:
	if slots_hbox == null:
		return
	var total_boosters: int = SaveManager.available_boosters.size()
	if booster_rack_badge != null:
		if total_boosters <= 4:
			booster_rack_badge.text = "(%d / 4)" % mini(4, total_boosters)
		else:
			booster_rack_badge.text = "(4 / 4 +%d)" % [total_boosters - 4]

	var style_occ: StyleBoxFlat = get_slot_occupied_style()
	var style_emp: StyleBoxFlat = get_slot_empty_style()

	for i in range(4):
		var slot_node: PanelContainer = slots_hbox.get_node_or_null("Slot%d" % i) as PanelContainer
		if slot_node == null:
			continue
		var icon: TextureRect = slot_node.get_node_or_null("VBox/IconAnchor/Icon") as TextureRect
		var glow: TextureRect = slot_node.get_node_or_null("VBox/IconAnchor/Glow") as TextureRect
		var empty_icon: Label = slot_node.get_node_or_null("VBox/IconAnchor/EmptyIcon") as Label
		var name_lbl: Label = slot_node.get_node_or_null("VBox/Name") as Label

		if i < total_boosters:
			var booster: BoosterData = SaveManager.available_boosters[i]
			slot_node.add_theme_stylebox_override("panel", style_occ)
			if icon != null:
				icon.visible = true
				icon.texture = booster.get_full_texture()
			if glow != null:
				glow.visible = true
			if empty_icon != null:
				empty_icon.visible = false
			if name_lbl != null:
				var clean_name: String = booster.display_name
				for prefix in ["🥈 ", "🥇 ", "💎 ", "🔮 ", "Sachet "]:
					clean_name = clean_name.replace(prefix, "")
				name_lbl.text = clean_name
				name_lbl.add_theme_color_override("font_color", Color(0.24, 0.11, 0.04, 1.0))
		else:
			slot_node.add_theme_stylebox_override("panel", style_emp)
			if icon != null:
				icon.visible = false
			if glow != null:
				glow.visible = false
			if empty_icon != null:
				empty_icon.visible = true
			if name_lbl != null:
				name_lbl.text = "Libre"
				name_lbl.add_theme_color_override("font_color", Color(0.55, 0.44, 0.35, 0.75))

func _refresh_collection_ui() -> void:
	# 1. Mise à jour de la réserve de sachets (Rack 4 slots)
	_refresh_boosters_rack()

	# 2. Tri des cartes (façon Clash Royale : Niveau ou Rareté, Croissant/Décroissant au toucher)
	var filtered_list: Array[Dictionary] = []

	for cid in SaveManager.registered_card_defs:
		var st: Dictionary = SaveManager.get_card_state(cid)
		if st.is_empty():
			continue
		filtered_list.append(st)

	# Tri mobile
	filtered_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var def_a: CandyCardData = a["def"]
		var def_b: CandyCardData = b["def"]
		match current_sort_mode:
			SortMode.LEVEL:
				if a["level"] != b["level"]:
					return a["level"] > b["level"] if is_sort_descending else a["level"] < b["level"]
				return int(def_a.rarity) > int(def_b.rarity) if is_sort_descending else int(def_a.rarity) < int(def_b.rarity)
			SortMode.RARITY:
				if int(def_a.rarity) != int(def_b.rarity):
					return int(def_a.rarity) > int(def_b.rarity) if is_sort_descending else int(def_a.rarity) < int(def_b.rarity)
				return a["level"] > b["level"] if is_sort_descending else a["level"] < b["level"]
			_:
				return false
	)

	# 3. Rendu séparé : Billes et Bumpers
	for child in balls_grid.get_children():
		child.queue_free()
	for child in bumpers_grid.get_children():
		child.queue_free()

	var balls_count: int = 0
	var bumpers_count: int = 0

	for st in filtered_list:
		var def: CandyCardData = st["def"]
		var card_inst: CollectionCard = collection_card_scene.instantiate() as CollectionCard
		
		if def.card_type == CandyCardData.CardType.BUMPER:
			bumpers_grid.add_child(card_inst)
			bumpers_count += 1
		else:
			balls_grid.add_child(card_inst)
			balls_count += 1
			
		card_inst.setup(st)
		card_inst.card_clicked.connect(_on_collection_card_clicked)

	# Gestion de la visibilité des sections selon les filtres
	if balls_tray != null:
		balls_tray.visible = (balls_count > 0)
	if bumpers_tray != null:
		bumpers_tray.visible = (bumpers_count > 0)

func _on_collection_card_clicked(card_id: StringName) -> void:
	if card_detail_modal != null:
		card_detail_modal.open_for_card(card_id)


func _refresh_shop_ui() -> void:
	if shop_sections_vbox == null:
		return
	ShopUIBuilder.build_shop_sections(
		shop_sections_vbox,
		SaveManager.shop_layout,
		SaveManager.shop_catalog,
		_on_shop_card_action
	)

func _on_shop_card_action(item: ShopItemData, use_diamonds: bool) -> void:
	if item == null:
		return
	if item.is_real_money():
		EventBus.shop_real_money_offer_requested.emit(item.id)
		return

	# TANT QU'ON N'A PAS APPUYÉ SUR "CONFIRMER", L'ACHAT N'EST PAS VALIDÉ !
	# On ouvre l'écran de prévisualisation et confirmation :
	if shop_reward_modal != null:
		shop_reward_modal.open_confirmation(item, use_diamonds, SaveManager.gold, SaveManager.diamonds)
	else:
		# Fallback direct
		_on_shop_purchase_confirmed(item, use_diamonds, get_viewport_rect().size * 0.5)

func _on_shop_purchase_cancelled() -> void:
	_pending_reward_item = null

func _on_shop_purchase_confirmed(item: ShopItemData, use_diamonds: bool, origin_pos: Vector2) -> void:
	if item == null:
		return

	var prev_gold: int = SaveManager.gold
	var prev_diamonds: int = SaveManager.diamonds
	var is_free: bool = item.is_free()

	# C'EST ICI ET SEULEMENT ICI QUE L'ACHAT EST VALIDÉ ET DÉBITÉ :
	var success: bool = SaveManager.purchase_item(item, use_diamonds)
	if not success:
		if shop_reward_modal != null:
			shop_reward_modal.close()
		return

	_pending_reward_item = item
	_pending_start_gold = prev_gold
	_pending_start_diamonds = prev_diamonds
	Input.vibrate_handheld(35)

	var final_gold: int = SaveManager.gold
	var final_diamonds: int = SaveManager.diamonds
	var gold_gain: int = maxi(0, final_gold - prev_gold)
	var dia_gain: int = maxi(0, final_diamonds - prev_diamonds)

	# Vérifier si l'article contient un sachet de cartes
	var has_booster: bool = false
	for entry in item.get_reward_entries():
		if entry.get("type", "") == "booster":
			has_booster = true
			break

	# Fermeture immédiate de la modale de confirmation pour ne pas perturber le joueur avec une 2e modale
	if shop_reward_modal != null:
		shop_reward_modal.close()

	if has_booster:
		# Animation du paquet de cartes qui s'envole vers la droite vers l'onglet Collection !
		_launch_booster_fly_animation(item.icon_texture, origin_pos)

	if gold_gain > 0 or dia_gain > 0:
		# Envol des pièces / diamants vers le HUD en haut
		_launch_currency_fly_animation(gold_gain, dia_gain, origin_pos, prev_gold, prev_diamonds)
	elif not has_booster:
		_launch_celebration_burst(origin_pos)
		_refresh_shop_ui()
		_refresh_collection_ui()

func _on_shop_reward_claimed(item: ShopItemData, origin_pos: Vector2) -> void:
	var final_gold: int = SaveManager.gold
	var final_diamonds: int = SaveManager.diamonds
	var gold_gain: int = maxi(0, final_gold - _pending_start_gold)
	var dia_gain: int = maxi(0, final_diamonds - _pending_start_diamonds)

	if gold_gain > 0 or dia_gain > 0:
		_launch_currency_fly_animation(gold_gain, dia_gain, origin_pos, _pending_start_gold, _pending_start_diamonds)
	else:
		_launch_celebration_burst(origin_pos)
		_refresh_shop_ui()
		_refresh_collection_ui()

func _on_shop_reward_open_booster(booster: BoosterData) -> void:
	_refresh_shop_ui()
	_refresh_collection_ui()
	if booster != null:
		EventBus.open_booster_modal_requested.emit(booster)

func _launch_booster_fly_animation(booster_tex: Texture2D, origin_pos: Vector2) -> void:
	if currency_fly_layer == null:
		_refresh_shop_ui()
		_refresh_collection_ui()
		return

	var booster_rect: TextureRect = TextureRect.new()
	booster_rect.texture = booster_tex if booster_tex != null else preload("res://assets/ui/booster_pack.png")
	var b_size: Vector2 = Vector2(150, 150)
	booster_rect.custom_minimum_size = b_size
	booster_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	booster_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	booster_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	booster_rect.pivot_offset = b_size * 0.5
	booster_rect.position = origin_pos - (b_size * 0.5)
	booster_rect.scale = Vector2(0.3, 0.3)
	currency_fly_layer.add_child(booster_rect)

	# Étoiles d'éclatement au centre
	_launch_celebration_burst(origin_pos)
	Input.vibrate_handheld(30)

	var vp_size: Vector2 = get_viewport_rect().size
	var target_x: float = vp_size.x + 120.0
	var target_y: float = origin_pos.y + 60.0

	var tw: Tween = create_tween()
	# 1. Pop-in & anticipation au centre avec tilt (0.16s)
	tw.tween_property(booster_rect, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(booster_rect, "rotation_degrees", -8.0, 0.16)

	# 2. Envol vif et accéléré vers la droite de l'écran (0.38s)
	tw.tween_property(booster_rect, "position:x", target_x, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(booster_rect, "position:y", target_y, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(booster_rect, "rotation_degrees", 24.0, 0.38)
	tw.parallel().tween_property(booster_rect, "scale", Vector2(0.7, 0.7), 0.38)

	# 3. Arrivée à droite & Punch rebond sur le bouton Collection
	tw.tween_callback(func() -> void:
		if is_instance_valid(booster_rect):
			booster_rect.queue_free()

		Input.vibrate_handheld(25)
		if btn_collection != null:
			btn_collection.pivot_offset = btn_collection.size * 0.5
			var b_tw: Tween = btn_collection.create_tween()
			b_tw.tween_property(btn_collection, "scale", Vector2(1.22, 1.22), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			b_tw.tween_property(btn_collection, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		_refresh_shop_ui()
		_refresh_collection_ui()
	)

func _launch_celebration_burst(origin_pos: Vector2) -> void:
	if currency_fly_layer == null:
		return
	for i in range(14):
		var star: TextureRect = TextureRect.new()
		star.texture = SPARKLE_TEX
		star.custom_minimum_size = Vector2(36, 36)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.pivot_offset = Vector2(18, 18)
		star.position = origin_pos - Vector2(18, 18)
		star.scale = Vector2(0.2, 0.2)
		currency_fly_layer.add_child(star)

		var angle: float = randf_range(0.0, TAU)
		var dist: float = randf_range(60.0, 160.0)
		var target_offset: Vector2 = Vector2(cos(angle), sin(angle)) * dist

		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(star, "position", star.position + target_offset, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "scale", Vector2.ONE * randf_range(0.8, 1.4), 0.22)
		tw.tween_property(star, "scale", Vector2.ZERO, 0.23).set_delay(0.22)
		tw.tween_property(star, "rotation", randf_range(-PI, PI), 0.45)
		tw.chain().tween_callback(star.queue_free)

func _launch_currency_fly_animation(
	gold_gain: int,
	dia_gain: int,
	origin_pos: Vector2,
	start_gold: int,
	start_diamonds: int
) -> void:
	if currency_fly_layer == null:
		_update_currency_display()
		_refresh_shop_ui()
		return

	_is_flying_currency = true

	# Garder le texte initial pendant le vol des pièces/diamants
	if gold_gain > 0 and gold_label != null:
		gold_label.text = "%d 🪙" % start_gold
	if dia_gain > 0 and diamond_label != null:
		diamond_label.text = "%d 💎" % start_diamonds

	var items_to_spawn: Array[Dictionary] = []
	if gold_gain > 0:
		var count: int = clampi(gold_gain / 25, 10, 18)
		for i in range(count):
			items_to_spawn.append({
				"is_gold": true,
				"texture": COIN_3D_TEX,
				"target_node": gold_badge,
				"target_label": gold_label,
				"start_val": start_gold,
				"target_val": SaveManager.gold,
				"suffix": "🪙",
				"index": i,
				"total": count
			})

	if dia_gain > 0:
		var count_dia: int = clampi(dia_gain, 6, 14)
		for i in range(count_dia):
			items_to_spawn.append({
				"is_gold": false,
				"texture": GEM_3D_TEX,
				"target_node": diamond_badge,
				"target_label": diamond_label,
				"start_val": start_diamonds,
				"target_val": SaveManager.diamonds,
				"suffix": "💎",
				"index": i,
				"total": count_dia
			})

	var progress_tracker: Dictionary = {"completed": 0}
	var total_items: int = items_to_spawn.size()

	# Minuteur de sécurité
	var safety_tw: Tween = create_tween()
	safety_tw.tween_interval(1.8)
	safety_tw.tween_callback(func() -> void:
		if _is_flying_currency:
			_is_flying_currency = false
			_update_currency_display()
			_refresh_shop_ui()
	)

	for data in items_to_spawn:
		var is_gold: bool = data["is_gold"]
		var tex: Texture2D = data["texture"]
		var target_badge: PanelContainer = data["target_node"]
		var target_lbl: Label = data["target_label"]
		var s_val: int = data["start_val"]
		var t_val: int = data["target_val"]
		var suffix: String = data["suffix"]
		var idx: int = data["index"]
		var total: int = data["total"]

		var p: TextureRect = TextureRect.new()
		p.texture = tex
		var p_size: Vector2 = Vector2(46, 46) if is_gold else Vector2(42, 42)
		p.custom_minimum_size = p_size
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.pivot_offset = p_size * 0.5
		p.position = origin_pos - (p_size * 0.5)
		p.scale = Vector2(0.2, 0.2)
		currency_fly_layer.add_child(p)

		# 1. Éclatement radial initial ("burst" jouissif)
		var angle: float = randf_range(0.0, TAU)
		var burst_dist: float = randf_range(40.0, 110.0)
		var burst_pos: Vector2 = origin_pos - (p_size * 0.5) + Vector2(cos(angle), sin(angle)) * burst_dist

		var tw_burst: Tween = create_tween().set_parallel(true)
		tw_burst.tween_property(p, "position", burst_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_burst.tween_property(p, "scale", Vector2(1.15, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# 2. Envol vers le badge en haut
		var delay: float = 0.14 + (float(idx) * 0.038)
		var target_center: Vector2 = (target_badge.global_position + (target_badge.size * 0.5)) - (p_size * 0.5) if target_badge != null else Vector2(360, 40)
		
		# Trajectoire arquée
		var control_x: float = lerpf(burst_pos.x, target_center.x, 0.5) + randf_range(-50.0, 50.0)
		var control_y: float = minf(burst_pos.y, target_center.y) - randf_range(60.0, 120.0)
		var p1: Vector2 = Vector2(control_x, control_y)

		var tw_fly: Tween = create_tween()
		tw_fly.tween_interval(delay)
		
		# Interpolation quadratique de Bézier
		var duration: float = 0.40
		var sub_steps: int = 12
		for s in range(1, sub_steps + 1):
			var t: float = float(s) / float(sub_steps)
			var inv_t: float = 1.0 - t
			var pt: Vector2 = (inv_t * inv_t * burst_pos) + (2.0 * inv_t * t * p1) + (t * t * target_center)
			tw_fly.tween_property(p, "position", pt, duration / float(sub_steps))
		
		# Scale down légèrement à l'approche et rotation
		var tw_scale: Tween = create_tween()
		tw_scale.tween_interval(delay + duration * 0.6)
		tw_scale.tween_property(p, "scale", Vector2(0.85, 0.85), duration * 0.4)

		# 3. Arrivée & Impact
		tw_fly.tween_callback(func() -> void:
			if is_instance_valid(p):
				p.queue_free()

			# Rebond punch sur le badge cible
			if target_badge != null:
				target_badge.pivot_offset = target_badge.size * 0.5
				var punch_tw: Tween = target_badge.create_tween()
				punch_tw.tween_property(target_badge, "scale", Vector2(1.22, 1.22), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				punch_tw.tween_property(target_badge, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			# Petite étoile étincelle à l'impact
			_spawn_arrival_sparkle(target_center + (p_size * 0.5))

			# Haptique par pièce qui tape
			Input.vibrate_handheld(12)

			# Rolling number progressif sur le label
			if target_lbl != null:
				var progress: float = float(idx + 1) / float(total)
				var current_val: int = int(lerpf(float(s_val), float(t_val), progress))
				target_lbl.text = "%d %s" % [current_val, suffix]

			progress_tracker["completed"] += 1
			if progress_tracker["completed"] >= total_items:
				_is_flying_currency = false
				_update_currency_display()
				_refresh_shop_ui()
				_refresh_collection_ui()
		)

func _spawn_arrival_sparkle(center_pos: Vector2) -> void:
	if currency_fly_layer == null:
		return
	var sp: TextureRect = TextureRect.new()
	sp.texture = SPARKLE_TEX
	sp.custom_minimum_size = Vector2(28, 28)
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.pivot_offset = Vector2(14, 14)
	sp.position = center_pos - Vector2(14, 14)
	sp.scale = Vector2(0.3, 0.3)
	currency_fly_layer.add_child(sp)

	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(sp, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sp, "modulate:a", 0.0, 0.20).set_delay(0.08)
	tw.chain().tween_callback(sp.queue_free)

func _on_open_booster() -> void:
	EventBus.open_booster_modal_requested.emit(null)

func _on_adventure_play_requested(level_data: LevelData) -> void:
	SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
	if level_data != null:
		selected_campaign_level = level_data.level_number
		SaveManager.campaign_selected_level = level_data.level_number
		if adventure_view != null:
			SaveManager.campaign_selected_world = adventure_view.current_world_num
	_on_launch_game()

func _on_survival_play_requested() -> void:
	SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
	_on_launch_game()

func _on_launch_game() -> void:
	if SaveManager.is_campaign():
		SaveManager.campaign_selected_level = selected_campaign_level
	play_pressed.emit()
	EventBus.start_game_requested.emit()


func _take_menu_screenshot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var title_node: CanvasItem = get_tree().root.find_child("TitleScreen", true, false) as CanvasItem
	if title_node != null:
		title_node.visible = false
	visible = true

	var args: PackedStringArray = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--add-hero-offer" in args:
		SaveManager.sandbox_add_featured_offer()
		_refresh_shop_ui()

	var tab_idx: int = 2
	if "--shop-tab" in args:
		tab_idx = 0
	elif "--collection-tab" in args:
		tab_idx = 1
	elif "--play-tab" in args:
		tab_idx = 2
	elif "--top-tab" in args:
		tab_idx = 3

	switch_to_tab_index(tab_idx, false)

	if "--unlock-boss" in args:
		SaveManager.campaign_unlocked_level = 10
		if adventure_view != null:
			adventure_view.refresh()
			adventure_view._scroll_to_current_level()
	elif "--survival-mode" in args:
		SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
		_refresh_play_tab()
	elif "--adventure-mode" in args:
		SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
		_refresh_play_tab()

	if "--collapse-dock" in args:
		if adventure_view != null and adventure_view.is_dock_expanded:
			adventure_view._toggle_deck_dock()

	if "--level-modal" in args:
		if adventure_view != null and adventure_view.level_detail_modal != null:
			var lvl: LevelData = CampaignCatalog.get_level(&"world_1", 1)
			adventure_view.level_detail_modal.open(lvl)
	elif "--card-modal" in args:
		card_detail_modal.open_for_card(&"mentox")
	elif "--card-modal-slot" in args:
		card_detail_modal.open_for_deck_slot(0, &"mentox")

	if "--top-tab" in args and leaderboard_view != null:
		var my_uid: String = SaveManager.current_profile.cloud_user_id if SaveManager.current_profile != null else "local"
		var my_name: String = SaveManager.current_profile.display_name if SaveManager.current_profile != null else "Moi"
		var demo_entries: Array = [
			{"user_id": "p1", "display_name": "SugarKing", "survival_best_wave": 45, "survival_best_score": 195400},
			{"user_id": "p2", "display_name": "BonbonMaster", "survival_best_wave": 38, "survival_best_score": 142100},
			{"user_id": "p3", "display_name": "ChocoKnight", "survival_best_wave": 33, "survival_best_score": 118900},
			{"user_id": my_uid, "display_name": my_name, "survival_best_wave": 24, "survival_best_score": 68400},
			{"user_id": "p5", "display_name": "GummyBear", "survival_best_wave": 19, "survival_best_score": 45200},
			{"user_id": "p6", "display_name": "LollipopNinja", "survival_best_wave": 16, "survival_best_score": 38900},
			{"user_id": "p7", "display_name": "CaramelCrush", "survival_best_wave": 14, "survival_best_score": 31050},
			{"user_id": "p8", "display_name": "PixelTart", "survival_best_wave": 12, "survival_best_score": 24800},
		]
		leaderboard_view._render_leaderboard(demo_entries)
		leaderboard_view._show_state("ready")

	for i in range(20):
		await get_tree().process_frame

	var out_path: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/428d5498-8612-413f-8f14-efd7bada7492/menu_screenshot.png"
	for a in args:
		if a.begins_with("--out-path="):
			out_path = a.substr("--out-path=".length())

	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(out_path)
	print("MENU_SCREENSHOT_CAPTURED_SUCCESSFULLY: %s" % out_path)
	get_tree().quit(0)



