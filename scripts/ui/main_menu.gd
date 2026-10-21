class_name MainMenu
extends Control

## Menu principal avec Navbar mobile inférieure pour switcher entre les onglets :
## - Collection (déblocages, boosters à ouvrir)
## - Play / Jeu (dernier score, bouton Jouer)
## - Leaderboard (meilleurs scores)

signal play_pressed

@onready var tab_collection: Control = $ContentContainer/CollectionTab
@onready var tab_play: Control = $ContentContainer/PlayTab
@onready var tab_leaderboard: Control = $ContentContainer/LeaderboardTab
@onready var tab_shop: Control = $ContentContainer/ShopTab

# Boutons Navbar
@onready var btn_shop: Button = $NavBar/HBoxContainer/BtnShop
@onready var btn_collection: Button = $NavBar/HBoxContainer/BtnCollection
@onready var btn_play: Button = $NavBar/HBoxContainer/BtnPlay
@onready var btn_leaderboard: Button = $NavBar/HBoxContainer/BtnLeaderboard

# Éléments Header
@onready var btn_account: Button = $TopGoldBar/HBox/BtnAccount
@onready var gold_label: Label = $TopGoldBar/HBox/GoldBadge/HBoxG/GoldLabel
@onready var diamond_label: Label = $TopGoldBar/HBox/DiamondBadge/HBoxD/DiamondLabel
@onready var btn_add_gold: Button = $TopGoldBar/HBox/GoldBadge/HBoxG/BtnAddGold
@onready var btn_add_diamonds: Button = $TopGoldBar/HBox/DiamondBadge/HBoxD/BtnAddDiamonds
@onready var account_modal: Control = $AccountModal


# Éléments Collection
@onready var booster_title_label: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/Title
@onready var btn_open_booster: Button = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/BtnsHBox/OpenBtn
@onready var btn_shop_shortcut: Button = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/BtnsHBox/ShopShortcutBtn
@onready var booster_badge_count: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BadgeCount
@onready var booster_glow: TextureRect = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BoosterGlow
@onready var booster_icon: TextureRect = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BoosterIcon
@onready var balls_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsBanner/BallsHeaderLabel
@onready var balls_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsGrid
@onready var bumpers_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersBanner/BumpersHeaderLabel
@onready var bumpers_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersGrid

# Filtres Collection
@onready var btn_filter_upgradable: Button = $ContentContainer/CollectionTab/VBox/FilterBar/HBox/BtnFilterUpgradable
@onready var filter_rarity_option: OptionButton = $ContentContainer/CollectionTab/VBox/FilterBar/HBox/FilterRarityOption
@onready var filter_sort_option: OptionButton = $ContentContainer/CollectionTab/VBox/FilterBar/HBox/FilterSortOption

# Modale Détail Carte
@onready var card_detail_modal: CardDetailModal = $CardDetailModal
@onready var card_picker_modal: CardPickerModal = $CardPickerModal

# Éléments Shop Tab
@onready var shop_scroll: ScrollContainer = $ContentContainer/ShopTab/VBox/ScrollContainer
@onready var shop_boosters_grid: GridContainer = $ContentContainer/ShopTab/VBox/ScrollContainer/SectionsVBox/BoostersGrid
@onready var shop_cards_grid: GridContainer = $ContentContainer/ShopTab/VBox/ScrollContainer/SectionsVBox/CardsGrid
@onready var shop_currency_grid: GridContainer = $ContentContainer/ShopTab/VBox/ScrollContainer/SectionsVBox/CurrencyGrid

# Éléments Play Tab
@onready var btn_launch_game: Button = $ContentContainer/PlayTab/VBox/BtnLaunchGame
@onready var btn_deck_1: Button = $ContentContainer/PlayTab/VBox/DeckCard/VBox/DeckTabsRow/BtnDeck1
@onready var btn_deck_2: Button = $ContentContainer/PlayTab/VBox/DeckCard/VBox/DeckTabsRow/BtnDeck2
@onready var btn_deck_3: Button = $ContentContainer/PlayTab/VBox/DeckCard/VBox/DeckTabsRow/BtnDeck3
@onready var deck_slots_grid: GridContainer = $ContentContainer/PlayTab/VBox/DeckCard/VBox/DeckSlotsGrid

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

	btn_launch_game.pressed.connect(_on_launch_game)
	btn_open_booster.pressed.connect(_on_open_booster)
	
	# Filtres Collection
	btn_filter_upgradable.toggled.connect(func(toggled: bool) -> void:
		_update_filter_button_style(toggled)
		_refresh_collection_ui()
	)
	filter_rarity_option.item_selected.connect(func(_idx: int) -> void: _refresh_collection_ui())
	filter_sort_option.item_selected.connect(func(_idx: int) -> void: _refresh_collection_ui())
	
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
	
	# Onglets de Decks
	if btn_deck_1 != null:
		btn_deck_1.pressed.connect(func() -> void: SaveManager.set_active_deck(0))
	if btn_deck_2 != null:
		btn_deck_2.pressed.connect(func() -> void: SaveManager.set_active_deck(1))
	if btn_deck_3 != null:
		btn_deck_3.pressed.connect(func() -> void: SaveManager.set_active_deck(2))

	if deck_slots_grid != null:
		for slot in deck_slots_grid.get_children():
			if slot is DeckSlotButton:
				slot.slot_pressed.connect(_on_deck_slot_clicked)

	if card_picker_modal != null:
		card_picker_modal.card_chosen.connect(func(_cid: StringName) -> void:
			_refresh_deck_ui()
		)

	if btn_account != null and account_modal != null:
		btn_account.pressed.connect(account_modal.open)

	EventBus.profile_loaded.connect(func(_pid: String) -> void:
		_refresh_account_button()
		_update_currency_display()
		_refresh_collection_ui()
		_refresh_deck_ui()
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
	_refresh_deck_ui()
	_update_collection_badge()
	switch_to_tab_index(2, false) # Démarre sur le jeu sans animation

func _refresh_account_button() -> void:
	if btn_account == null or SaveManager.current_profile == null:
		return
	var prof: RefCounted = SaveManager.current_profile
	var is_sandbox: bool = SaveManager.is_sandbox_active()
	var cloud_icon: String = "⚪"
	if SaveManager.cloud_sync != null and SaveManager.cloud_sync.is_online():
		cloud_icon = "🟢"
	if is_sandbox:
		btn_account.text = "%s 🧪 %s" % [cloud_icon, prof.display_name]
	else:
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
	var active_idx: int = SaveManager.active_deck_index
	if btn_deck_1 != null:
		btn_deck_1.button_pressed = (active_idx == 0)
	if btn_deck_2 != null:
		btn_deck_2.button_pressed = (active_idx == 1)
	if btn_deck_3 != null:
		btn_deck_3.button_pressed = (active_idx == 2)

	var cur_deck: Array = SaveManager.get_active_deck()
	if deck_slots_grid != null:
		var slot_children: Array = deck_slots_grid.get_children()
		for i in range(slot_children.size()):
			var slot_btn: DeckSlotButton = slot_children[i] as DeckSlotButton
			if slot_btn != null and i < cur_deck.size():
				slot_btn.set_card(cur_deck[i])

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
	if btn_collection == null:
		return
	notif_badge = PanelContainer.new()
	notif_badge.name = "NotifBadge"
	notif_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.78, 0.25, 1.0) # Vert vif Clash Royale
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 1.0, 1.0, 0.95)
	sb.set_corner_radius_all(11)
	sb.content_margin_left = 6.0
	sb.content_margin_top = 1.0
	sb.content_margin_right = 6.0
	sb.content_margin_bottom = 1.0
	sb.shadow_color = Color(0.08, 0.40, 0.12, 0.5)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 1)
	notif_badge.add_theme_stylebox_override("panel", sb)
	
	notif_label = Label.new()
	notif_label.add_theme_font_size_override("font_size", 14)
	notif_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	notif_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	notif_label.add_theme_constant_override("shadow_offset_y", 1)
	notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notif_badge.add_child(notif_label)
	
	notif_badge.anchors_preset = Control.PRESET_TOP_RIGHT
	notif_badge.anchor_left = 1.0
	notif_badge.anchor_right = 1.0
	notif_badge.offset_left = -28.0
	notif_badge.offset_top = -6.0
	notif_badge.offset_right = 4.0
	notif_badge.offset_bottom = 18.0
	notif_badge.visible = false
	btn_collection.add_child(notif_badge)

func _update_collection_badge() -> void:
	if notif_badge == null or notif_label == null:
		return
	var count: int = 0
	for cid in SaveManager.registered_card_defs:
		var st: Dictionary = SaveManager.get_card_state(cid)
		if st.get("has_enough_cards", false):
			count += 1
	if count > 0:
		notif_badge.visible = true
		notif_label.text = str(count)
	else:
		notif_badge.visible = false

func _update_filter_button_style(is_active: bool) -> void:
	if btn_filter_upgradable == null:
		return
	if is_active:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.76, 0.26, 1.0) # Vert émeraude Clash Royale
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 4
		sb.border_color = Color(0.96, 0.84, 0.20, 1.0) # Or
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 12.0
		sb.content_margin_top = 6.0
		sb.content_margin_right = 12.0
		sb.content_margin_bottom = 8.0
		sb.shadow_color = Color(0.1, 0.4, 0.15, 0.4)
		sb.shadow_size = 4
		btn_filter_upgradable.add_theme_stylebox_override("normal", sb)
		btn_filter_upgradable.add_theme_stylebox_override("pressed", sb)
		btn_filter_upgradable.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn_filter_upgradable.remove_theme_stylebox_override("normal")
		btn_filter_upgradable.remove_theme_stylebox_override("pressed")
		btn_filter_upgradable.remove_theme_color_override("font_color")

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
		
	_update_collection_badge()
	EventBus.main_menu_tab_changed.emit(TAB_KEYS[idx])

func _update_navbar_ui(active_idx: int) -> void:
	# Format façon Clash Royale : l'actif a les chevrons ◀ Nom ▶ et un style surélevé
	btn_shop.text = "◀ 🛍️ BOUTIQUE ▶" if active_idx == 0 else "🛍️ SHOP"
	btn_collection.text = "◀ 📦 CARTES ▶" if active_idx == 1 else "📦 CARTES"
	btn_play.text = "◀ ⚔️ BATAILLE ▶" if active_idx == 2 else "⚔️ BATAILLE"
	btn_leaderboard.text = "◀ 🏆 TOP ▶" if active_idx == 3 else "🏆 TOP"
	
	btn_shop.size_flags_stretch_ratio = 1.35 if active_idx == 0 else 0.88
	btn_collection.size_flags_stretch_ratio = 1.35 if active_idx == 1 else 0.88
	btn_play.size_flags_stretch_ratio = 1.35 if active_idx == 2 else 0.88
	btn_leaderboard.size_flags_stretch_ratio = 1.35 if active_idx == 3 else 0.88
	
	_style_nav_button(btn_shop, active_idx == 0)
	_style_nav_button(btn_collection, active_idx == 1)
	_style_nav_button(btn_play, active_idx == 2)
	_style_nav_button(btn_leaderboard, active_idx == 3)

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
	if gold_label != null:
		gold_label.text = "%d 🪙" % SaveManager.gold
	if diamond_label != null:
		diamond_label.text = "%d 💎" % SaveManager.diamonds

func _on_gold_changed(_new_val: int, _delta: int) -> void:
	_update_currency_display()
	_refresh_collection_ui()
	_refresh_shop_ui()

func _on_diamonds_changed(_new_val: int, _delta: int) -> void:
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

func _animate_booster_banner() -> void:
	if booster_icon == null or booster_glow == null:
		return
	# Flottement doux du sachet
	var tw_float: Tween = create_tween().set_loops()
	tw_float.tween_property(booster_icon, "position:y", -6.0, 1.2).set_trans(Tween.TRANS_SINE).as_relative()
	tw_float.tween_property(booster_icon, "position:y", 6.0, 1.2).set_trans(Tween.TRANS_SINE).as_relative()
	
	# Rotation lente des rayons/étincelles
	var tw_glow: Tween = create_tween().set_loops()
	tw_glow.tween_property(booster_glow, "rotation_degrees", 360.0, 12.0).from(0.0)

func _refresh_collection_ui() -> void:
	# 1. Mise à jour de la bannière booster héroïque
	var count: int = SaveManager.available_boosters.size()
	if count > 0:
		var next_booster: BoosterData = SaveManager.available_boosters[0]
		booster_title_label.text = "%s\n(%d DISPONIBLE%s)" % [next_booster.display_name, count, "S" if count > 1 else ""]
		btn_open_booster.disabled = false
		btn_open_booster.text = "✨ OUVRIR"
		booster_badge_count.visible = true
		booster_badge_count.text = "x%d" % count
		booster_icon.modulate = Color.WHITE
		booster_glow.visible = true
	else:
		booster_title_label.text = "AUCUN SACHET EN ATTENTE\n(GAGNEZ-EN EN JEU !)"
		btn_open_booster.disabled = true
		btn_open_booster.text = "VIDE"
		booster_badge_count.visible = false
		booster_icon.modulate = Color(0.6, 0.6, 0.6, 0.8)
		booster_glow.visible = false

	# 2. Filtrage et tri des cartes
	var filtered_list: Array[Dictionary] = []
	var filter_only_upgradable: bool = btn_filter_upgradable.button_pressed if btn_filter_upgradable != null else false
	var selected_rarity: int = filter_rarity_option.selected if filter_rarity_option != null else 0 # 0=Toutes, 1=Common, 2=Rare, 3=Epic, 4=Legendary
	var selected_sort: int = filter_sort_option.selected if filter_sort_option != null else 0 # 0=Niveau, 1=Rareté, 2=Progression

	for cid in SaveManager.registered_card_defs:
		var st: Dictionary = SaveManager.get_card_state(cid)
		if st.is_empty():
			continue
		var def: CandyCardData = st.get("def", null)
		
		# Filtre "Prêts / Améliorables"
		if filter_only_upgradable and not st.get("has_enough_cards", false):
			continue
			
		# Filtre de rareté
		if selected_rarity > 0:
			var target_r: int = selected_rarity - 1
			if int(def.rarity) != target_r:
				continue
				
		filtered_list.append(st)

	# Tri mobile-friendly
	filtered_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var def_a: CandyCardData = a["def"]
		var def_b: CandyCardData = b["def"]
		match selected_sort:
			0: # Niveau décroissant
				if a["level"] != b["level"]:
					return a["level"] > b["level"]
				return a["ratio"] > b["ratio"]
			1: # Rareté décroissante
				if int(def_a.rarity) != int(def_b.rarity):
					return int(def_a.rarity) > int(def_b.rarity)
				return a["level"] > b["level"]
			2: # Progression ratio
				return a["ratio"] > b["ratio"]
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
	balls_header_label.visible = (balls_count > 0)
	balls_grid.visible = (balls_count > 0)
	bumpers_header_label.visible = (bumpers_count > 0)
	bumpers_grid.visible = (bumpers_count > 0)

func _on_collection_card_clicked(card_id: StringName) -> void:
	if card_detail_modal != null:
		card_detail_modal.open_for_card(card_id)


func _refresh_shop_ui() -> void:
	if shop_boosters_grid == null or shop_cards_grid == null or shop_currency_grid == null:
		return

	for child in shop_boosters_grid.get_children():
		child.queue_free()
	for child in shop_cards_grid.get_children():
		child.queue_free()
	for child in shop_currency_grid.get_children():
		child.queue_free()

	for item in SaveManager.shop_catalog:
		var target_grid: GridContainer = null
		match item.category:
			ShopItemData.Category.BOOSTERS:
				target_grid = shop_boosters_grid
			ShopItemData.Category.CARDS_DAILY:
				target_grid = shop_cards_grid
			_:
				target_grid = shop_currency_grid

		if target_grid != null:
			var card_node: Control = _create_shop_item_card(item)
			target_grid.add_child(card_node)

func _create_shop_item_card(item: ShopItemData) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 260)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER

	# Icône
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = item.icon_texture if item.icon_texture != null else CandyTextureHelper.load_texture("res://assets/ui/cards/fizzball_ball_sprite.png")
	vb.add_child(icon)

	# Nom
	var name_lbl: Label = Label.new()
	name_lbl.text = item.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.36, 0.17, 0.08, 1))
	vb.add_child(name_lbl)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = item.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.40, 0.32, 1))
	vb.add_child(desc_lbl)

	# Boutons d'achat (Or et/ou Diamant)
	var hb_btns: HBoxContainer = HBoxContainer.new()
	hb_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_btns.add_theme_constant_override("separation", 8)

	if item.gold_price >= 0:
		var btn_g: Button = Button.new()
		btn_g.text = "%d 🪙" % item.gold_price
		btn_g.custom_minimum_size = Vector2(110, 48)
		btn_g.disabled = (SaveManager.gold < item.gold_price)
		btn_g.pressed.connect(func() -> void:
			SaveManager.purchase_item(item, false)
		)
		hb_btns.add_child(btn_g)

	if item.diamond_price >= 0:
		var btn_d: Button = Button.new()
		btn_d.text = "%d 💎" % item.diamond_price
		btn_d.custom_minimum_size = Vector2(110, 48)
		btn_d.disabled = (SaveManager.diamonds < item.diamond_price)
		btn_d.pressed.connect(func() -> void:
			SaveManager.purchase_item(item, true)
		)
		hb_btns.add_child(btn_d)

	vb.add_child(hb_btns)
	panel.add_child(vb)
	return panel

func _on_open_booster() -> void:
	EventBus.open_booster_modal_requested.emit()

func _on_launch_game() -> void:
	play_pressed.emit()
	EventBus.start_game_requested.emit()

