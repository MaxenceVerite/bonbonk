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
@onready var gold_label: Label = $TopGoldBar/HBox/GoldBadge/HBoxG/GoldLabel
@onready var diamond_label: Label = $TopGoldBar/HBox/DiamondBadge/HBoxD/DiamondLabel
@onready var btn_add_gold: Button = $TopGoldBar/HBox/GoldBadge/HBoxG/BtnAddGold
@onready var btn_add_diamonds: Button = $TopGoldBar/HBox/DiamondBadge/HBoxD/BtnAddDiamonds

# Éléments Collection
@onready var booster_title_label: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/Title
@onready var btn_open_booster: Button = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/BtnsHBox/OpenBtn
@onready var btn_shop_shortcut: Button = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/VBoxB/BtnsHBox/ShopShortcutBtn
@onready var booster_badge_count: Label = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BadgeCount
@onready var booster_glow: TextureRect = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BoosterGlow
@onready var booster_icon: TextureRect = $ContentContainer/CollectionTab/VBox/BoostersCard/HBox/BagAnchor/BoosterIcon
@onready var balls_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsHeaderLabel
@onready var balls_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BallsGrid
@onready var bumpers_header_label: Label = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersHeaderLabel
@onready var bumpers_grid: GridContainer = $ContentContainer/CollectionTab/VBox/ScrollContainer/SectionsVBox/BumpersGrid

# Filtres Collection
@onready var btn_filter_upgradable: Button = $ContentContainer/CollectionTab/VBox/FilterBar/BtnFilterUpgradable
@onready var filter_rarity_option: OptionButton = $ContentContainer/CollectionTab/VBox/FilterBar/FilterRarityOption
@onready var filter_sort_option: OptionButton = $ContentContainer/CollectionTab/VBox/FilterBar/FilterSortOption

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

func _ready() -> void:
	btn_shop.pressed.connect(func() -> void: switch_tab(&"shop"))
	btn_collection.pressed.connect(func() -> void: switch_tab(&"collection"))
	btn_play.pressed.connect(func() -> void: switch_tab(&"play"))
	btn_leaderboard.pressed.connect(func() -> void: switch_tab(&"leaderboard"))
	
	btn_add_gold.pressed.connect(func() -> void:
		switch_tab(&"shop")
		_scroll_to_currency_section()
	)
	btn_add_diamonds.pressed.connect(func() -> void:
		switch_tab(&"shop")
		_scroll_to_currency_section()
	)
	btn_shop_shortcut.pressed.connect(func() -> void:
		switch_tab(&"shop")
	)

	btn_launch_game.pressed.connect(_on_launch_game)
	btn_open_booster.pressed.connect(_on_open_booster)
	
	# Filtres Collection
	btn_filter_upgradable.toggled.connect(func(_toggled: bool) -> void: _refresh_collection_ui())
	filter_rarity_option.item_selected.connect(func(_idx: int) -> void: _refresh_collection_ui())
	filter_sort_option.item_selected.connect(func(_idx: int) -> void: _refresh_collection_ui())
	
	# Modale
	card_detail_modal.card_upgraded_locally.connect(func(_id: StringName) -> void:
		_refresh_collection_ui()
		_refresh_deck_ui()
		_update_currency_display()
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

	_animate_booster_banner()
	_update_currency_display()
	_refresh_collection_ui()
	_refresh_shop_ui()
	_refresh_deck_ui()
	switch_tab(&"play")

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

func switch_tab(tab_name: StringName) -> void:
	tab_shop.visible = (tab_name == &"shop")
	tab_collection.visible = (tab_name == &"collection")
	tab_play.visible = (tab_name == &"play")
	tab_leaderboard.visible = (tab_name == &"leaderboard")
	
	# Mise en valeur du bouton actif
	_style_nav_button(btn_shop, tab_name == &"shop")
	_style_nav_button(btn_collection, tab_name == &"collection")
	_style_nav_button(btn_play, tab_name == &"play")
	_style_nav_button(btn_leaderboard, tab_name == &"leaderboard")
	
	if tab_name == &"collection":
		_refresh_collection_ui()
	elif tab_name == &"shop":
		_refresh_shop_ui()
		
	EventBus.main_menu_tab_changed.emit(tab_name)

func _style_nav_button(btn: Button, is_active: bool) -> void:
	btn.modulate = Color.WHITE
	btn.theme_type_variation = &"NavButtonActive" if is_active else &"NavButton"

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
	icon.texture = item.icon_texture if item.icon_texture != null else load("res://assets/ui/icon_ball_standard.png")
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

