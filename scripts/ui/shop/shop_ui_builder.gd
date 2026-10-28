class_name ShopUIBuilder
extends RefCounted

## Générateur dynamique d'interface pour la boutique (ShopTab).
## Fidèle pixel-perfect à la maquette de référence (Image 1) :
## - Contenu hébergé sur une grande planche biscuit/crème unifiée
## - Cartes biscuit/café-au-lait chaleureuses avec biseau 3D
## - Cadeaux gratuits présentés en grille 2 colonnes avec boutons verts pilule
## - Sachets et pièces/diamants en 2 colonnes avec boutons pilules Jaune/Bleu/Désactivé
## - Carte Héro Offre du Jour avec ruban rouge supérieur et bouton bleu "4,99€" inférieur

const ShopItemData = preload("res://scripts/data/shop_item_data.gd")
const ShopSectionData = preload("res://scripts/data/shop_section_data.gd")

const RIBBON_TEXTURE_PATH: String = "res://assets/ui/ribbon_red_banner.png"
const FALLBACK_ICON_PATH: String = "res://assets/ui/cards/fizzball_ball_sprite.png"

# ==============================================================================
# STYLES BOX FIDÈLES À L'IMAGE 1
# ==============================================================================

## Ruban rouge pour la carte Héro (OFFRE DU JOUR)
static func get_red_ribbon_style() -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = load(RIBBON_TEXTURE_PATH)
	sb.content_margin_left = 34.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 34.0
	sb.content_margin_bottom = 14.0
	sb.texture_margin_left = 74.0
	sb.texture_margin_top = 10.0
	sb.texture_margin_right = 74.0
	sb.texture_margin_bottom = 18.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

## Ruban rouge pleine largeur pour les catégories (déborde du plateau comme dans Collection)
static func get_category_ribbon_style() -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = load(RIBBON_TEXTURE_PATH)
	sb.content_margin_left = 36.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 36.0
	sb.content_margin_bottom = 14.0
	sb.texture_margin_left = 74.0
	sb.texture_margin_top = 10.0
	sb.texture_margin_right = 74.0
	sb.texture_margin_bottom = 18.0
	# Déborde du plateau (12px de marge interne + 24px de débordement extérieur = 36px)
	sb.expand_margin_left = 36.0
	sb.expand_margin_right = 36.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

## Style des cartes biscuit / café-au-lait (identique dans toute la boutique)
static func get_card_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.85, 0.79, 0.72, 1.0) # #D9C9B8
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 5
	sb.border_color = Color(0.67, 0.59, 0.49, 1.0) # #AC977D
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.shadow_color = Color(0.24, 0.12, 0.04, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 10.0
	sb.content_margin_top = 12.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 14.0
	return sb

## Cadre Héro doré / bois avec biseau 3D
static func get_hero_frame_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.48, 0.12, 0.52, 1.0) # Fond violet magenta riche
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 7
	sb.border_color = Color(0.78, 0.52, 0.08, 1.0) # Contour doré bois
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_right = 22
	sb.corner_radius_bottom_left = 22
	sb.shadow_color = Color(0.25, 0.10, 0.04, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb

## Bouton pilule vert ("GRATUIT" / "OBTENIR")
static func get_green_pill_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.24, 0.78, 0.42, 1.0) # #3ED16F
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.10, 0.44, 0.24, 1.0) # #1A703D
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.content_margin_left = 12.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 6.0
	return sb

static func get_green_pill_pressed_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.65, 0.35, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.08, 0.35, 0.18, 1.0)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.content_margin_left = 12.0
	sb.content_margin_top = 7.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 3.0
	return sb

## Bouton pilule jaune ("200 🪙" / "500 🪙")
static func get_yellow_pill_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.72, 0.16, 1.0) # #F7B829
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.55, 0.32, 0.05, 1.0) # #8C520D
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 6.0
	return sb

static func get_yellow_pill_pressed_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.85, 0.60, 0.10, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.25, 0.04, 1.0)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8.0
	sb.content_margin_top = 7.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 3.0
	return sb

## Bouton pilule bleu / cyan ("15 💎" / "10 💎" / "4,99€")
static func get_blue_pill_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.68, 0.96, 1.0) # #2EAEF5
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.04, 0.32, 0.58, 1.0) # #0B5294
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 6.0
	return sb

static func get_blue_pill_pressed_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.55, 0.82, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.03, 0.24, 0.45, 1.0)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8.0
	sb.content_margin_top = 7.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 3.0
	return sb

static func wire_tactile_button(btn: Button, item: Resource, is_diamonds: bool, on_purchase_callable: Callable) -> void:
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	btn.pressed.connect(func() -> void:
		Input.vibrate_handheld(25)
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if on_purchase_callable.is_valid():
			on_purchase_callable.call(item, is_diamonds)
	)

## Bouton pilule désactivé / grisé (ex: "35 💎" si pas assez de gemmes)
static func get_disabled_pill_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.68, 0.67, 0.65, 1.0) # #AEA8A2
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	sb.border_color = Color(0.48, 0.46, 0.44, 1.0)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 6.0
	return sb

# ==============================================================================
# ORCHESTRATION COMPLÈTE DE LA BOUTIQUE
# ==============================================================================

static func build_shop_sections(
	container: VBoxContainer,
	layout: Array,
	catalog: Array,
	on_purchase_callable: Callable,
	player_gold: int = -1,
	player_diamonds: int = -1
) -> void:
	if container == null:
		return

	if player_gold < 0 or player_diamonds < 0:
		var root: Node = Engine.get_main_loop().root if Engine.get_main_loop() != null else null
		if root != null and root.has_node("SaveManager"):
			var sm: Node = root.get_node("SaveManager")
			if player_gold < 0:
				player_gold = int(sm.get("gold"))
			if player_diamonds < 0:
				player_diamonds = int(sm.get("diamonds"))
	if player_gold < 0:
		player_gold = 0
	if player_diamonds < 0:
		player_diamonds = 0

	# Nettoyage
	for child in container.get_children():
		child.queue_free()

	for section in layout:
		var items: Array = []
		for item in catalog:
			if item.category == section.category:
				items.append(item)

		# Masque entièrement le rayon si aucun article disponible (ex: Hero s'il n'y a pas d'offre)
		if section.hide_when_empty and items.is_empty():
			continue

		var section_box: VBoxContainer = VBoxContainer.new()
		section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section_box.add_theme_constant_override("separation", 20)

		# 1. HÉRO : OFFRE DU JOUR
		if section.layout == ShopSectionData.Layout.FEATURED_GALLERY:
			var hero_gallery: Control = _build_featured_gallery(items, on_purchase_callable, player_gold, player_diamonds)
			section_box.add_child(hero_gallery)
		else:
			# Ruban titre de section (Cadeaux Gratuits, Sachets de bonbons, Pièces & Diamants)
			var banner: Control = create_section_banner(section.title)
			section_box.add_child(banner)

			# 2. CADEAUX GRATUITS (Grille 2 colonnes avec boutons verts pilule)
			if section.layout == ShopSectionData.Layout.REWARD_ROWS:
				var free_grid: GridContainer = GridContainer.new()
				free_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				free_grid.columns = maxi(1, section.columns)
				free_grid.add_theme_constant_override("h_separation", 12)
				free_grid.add_theme_constant_override("v_separation", 14)
				for it in items:
					var free_card: Control = create_reward_card_2col(it, on_purchase_callable, player_gold, player_diamonds)
					free_grid.add_child(free_card)
				section_box.add_child(free_grid)

			# 3. SACHETS DE BONBONS & PIÈCES / DIAMANTS (Grille 2 colonnes)
			else:
				var grid: GridContainer = GridContainer.new()
				grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.columns = maxi(1, section.columns)
				grid.add_theme_constant_override("h_separation", 12)
				grid.add_theme_constant_override("v_separation", 16)
				for it in items:
					var tile_card: Control = create_item_tile_card(it, on_purchase_callable, player_gold, player_diamonds)
					grid.add_child(tile_card)
				section_box.add_child(grid)

		container.add_child(section_box)

# ==============================================================================
# RUBAN TITRE DE SECTION
# ==============================================================================

static func create_section_banner(title_text: String) -> Control:
	var banner: PanelContainer = PanelContainer.new()
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.custom_minimum_size = Vector2(0, 58)
	banner.add_theme_stylebox_override("panel", get_category_ribbon_style())

	var lbl: Label = Label.new()
	lbl.text = title_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.28, 0.04, 0.06, 0.98))
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0.38, 0.06, 0.08, 1.0))
	lbl.add_theme_constant_override("outline_size", 4)

	banner.add_child(lbl)
	return banner

# ==============================================================================
# 1. CARTE HÉRO / OFFRE DU JOUR (FEATURED GALLERY)
# ==============================================================================

static func _build_featured_gallery(
	items: Array,
	on_purchase_callable: Callable,
	player_gold: int,
	player_diamonds: int
) -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)

	for it in items:
		var hero_card: Control = create_featured_card(it, on_purchase_callable, player_gold, player_diamonds)
		root.add_child(hero_card)

	return root

static func create_featured_card(
	item: Resource,
	on_purchase_callable: Callable,
	player_gold: int,
	player_diamonds: int
) -> Control:
	# Conteneur racine avec marges pour laisser déborder le ruban supérieur et le bouton inférieur
	var root_container: MarginContainer = MarginContainer.new()
	root_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_container.custom_minimum_size = Vector2(0, 245)
	root_container.add_theme_constant_override("margin_top", 20)
	root_container.add_theme_constant_override("margin_bottom", 22)

	# 1. Le cadre Héro (texture pré-rendue avec rayons et double liséré doré/bois)
	var hero_frame: PanelContainer = PanelContainer.new()
	hero_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_frame.custom_minimum_size = Vector2(0, 200)
	hero_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root_container.add_child(hero_frame)

	# 2. Illustration de fond : rayons en étoile et cadre doré 3D
	var burst_rect: TextureRect = TextureRect.new()
	burst_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	burst_rect.texture = item.background_texture if item.background_texture != null else load("res://assets/ui/hero_card_frame_bg.png")
	burst_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst_rect.stretch_mode = TextureRect.STRETCH_SCALE
	hero_frame.add_child(burst_rect)

	# Étoiles scintillantes
	var bg_art: Control = Control.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero_frame.add_child(bg_art)

	var star_colors: Array[Color] = [Color(1.0, 0.85, 0.2), Color(0.2, 0.9, 1.0), Color(0.4, 1.0, 0.4), Color(1.0, 0.5, 0.8)]
	var star_positions: Array[Vector2] = [Vector2(20, 20), Vector2(430, 20), Vector2(45, 125), Vector2(415, 120)]
	for i in range(star_positions.size()):
		var star: TextureRect = TextureRect.new()
		star.texture = load("res://assets/ui/sparkle_star.png")
		star.modulate = star_colors[i % star_colors.size()]
		star.position = star_positions[i]
		star.custom_minimum_size = Vector2(26, 26)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg_art.add_child(star)

	# 3. Composition d'articles au centre (Sachet Silver Pop à gauche, Golden Crush au milieu, Tas de pièces à droite)
	var art_hbox: HBoxContainer = HBoxContainer.new()
	art_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	art_hbox.add_theme_constant_override("separation", 14)

	var bag_silver: TextureRect = TextureRect.new()
	bag_silver.texture = load("res://assets/ui/pack_silver_full.png")
	bag_silver.custom_minimum_size = Vector2(92, 124)
	bag_silver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bag_silver.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_silver.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_hbox.add_child(bag_silver)

	var bag_gold: TextureRect = TextureRect.new()
	bag_gold.texture = load("res://assets/ui/pack_gold_full.png")
	bag_gold.custom_minimum_size = Vector2(108, 144)
	bag_gold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bag_gold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_gold.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_hbox.add_child(bag_gold)

	var coins_art: TextureRect = TextureRect.new()
	coins_art.texture = load("res://assets/ui/icon_gold_pile.png")
	coins_art.custom_minimum_size = Vector2(98, 94)
	coins_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coins_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coins_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_hbox.add_child(coins_art)

	hero_frame.add_child(art_hbox)

	# 4. Ruban rouge supérieur "OFFRE DU JOUR" qui chevauche le haut du cadre
	# Plus large et imposant sur la carte héro, mais reste centré sans traverser tout le plateau
	var top_ribbon_anchor: Control = Control.new()
	top_ribbon_anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_ribbon_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_ribbon: PanelContainer = PanelContainer.new()
	top_ribbon.custom_minimum_size = Vector2(380, 58)
	top_ribbon.add_theme_stylebox_override("panel", get_red_ribbon_style())
	top_ribbon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top_ribbon.offset_top = -18.0
	top_ribbon.offset_left = -190.0
	top_ribbon.offset_right = 190.0
	top_ribbon.offset_bottom = 40.0

	var top_lbl: Label = Label.new()
	top_lbl.text = "OFFRE DU JOUR"
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.add_theme_font_size_override("font_size", 24)
	top_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.65, 1.0))
	top_lbl.add_theme_color_override("font_shadow_color", Color(0.30, 0.04, 0.06, 0.98))
	top_lbl.add_theme_constant_override("shadow_offset_y", 2)
	top_lbl.add_theme_color_override("font_outline_color", Color(0.38, 0.06, 0.08, 1.0))
	top_lbl.add_theme_constant_override("outline_size", 4)
	top_ribbon.add_child(top_lbl)

	top_ribbon_anchor.add_child(top_ribbon)
	root_container.add_child(top_ribbon_anchor)

	# 5. Bouton bleu "4,99€" centré au bas qui chevauche le bas du cadre
	var bottom_btn_anchor: Control = Control.new()
	bottom_btn_anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom_btn_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var blue_btn: Button = Button.new()
	blue_btn.text = item.real_price_label if not item.real_price_label.is_empty() else "4,99€"
	blue_btn.custom_minimum_size = Vector2(180, 52)
	blue_btn.add_theme_stylebox_override("normal", get_blue_pill_style())
	blue_btn.add_theme_stylebox_override("hover", get_blue_pill_style())
	blue_btn.add_theme_stylebox_override("pressed", get_blue_pill_pressed_style())
	blue_btn.add_theme_font_size_override("font_size", 23)
	blue_btn.add_theme_color_override("font_color", Color.WHITE)
	blue_btn.add_theme_color_override("font_outline_color", Color(0.04, 0.22, 0.45, 1.0))
	blue_btn.add_theme_constant_override("outline_size", 4)
	blue_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	blue_btn.offset_top = -24.0
	blue_btn.offset_left = -90.0
	blue_btn.offset_right = 90.0
	blue_btn.offset_bottom = 28.0

	wire_tactile_button(blue_btn, item, false, on_purchase_callable)

	bottom_btn_anchor.add_child(blue_btn)
	root_container.add_child(bottom_btn_anchor)

	return root_container

# ==============================================================================
# 2. CARTE CADEAU 2 COLONNES (CADEAUX GRATUITS - IMAGE 1)
# ==============================================================================

static func create_reward_card_2col(
	item: Resource,
	on_purchase_callable: Callable,
	player_gold: int,
	player_diamonds: int
) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 148)
	panel.add_theme_stylebox_override("panel", get_card_style())

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# 1. Icône à gauche (agrandie pour plus de visibilité)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(104, 104)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = item.icon_texture if item.icon_texture != null else load(FALLBACK_ICON_PATH)
	hbox.add_child(icon)

	# 2. Titre et bouton vert à droite
	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_vbox.add_theme_constant_override("separation", 6)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_lbl: Label = Label.new()
	title_lbl.text = item.display_name
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.24, 0.12, 0.04, 1.0))
	right_vbox.add_child(title_lbl)

	# Bouton vert pilule ("GRATUIT" ou "OBTENIR")
	var btn_action: Button = Button.new()
	btn_action.custom_minimum_size = Vector2(116, 42)
	btn_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_txt: String = item.badge_text if not item.badge_text.is_empty() else "GRATUIT"
	if item.is_claimed:
		btn_action.text = "RÉCUPÉRÉ"
		btn_action.add_theme_stylebox_override("disabled", get_disabled_pill_style())
		btn_action.disabled = true
	else:
		btn_action.text = btn_txt
		btn_action.add_theme_stylebox_override("normal", get_green_pill_style())
		btn_action.add_theme_stylebox_override("hover", get_green_pill_style())
		btn_action.add_theme_stylebox_override("pressed", get_green_pill_pressed_style())
		btn_action.add_theme_font_size_override("font_size", 16)
		btn_action.add_theme_color_override("font_color", Color.WHITE)
		btn_action.add_theme_color_override("font_outline_color", Color(0.06, 0.28, 0.14, 1.0))
		btn_action.add_theme_constant_override("outline_size", 3)
		wire_tactile_button(btn_action, item, false, on_purchase_callable)
	right_vbox.add_child(btn_action)

	hbox.add_child(right_vbox)
	panel.add_child(hbox)
	return panel

# ==============================================================================
# 3. TUILE MARCHAUDE 2 COLONNES (SACHETS & OR/TRÉSORS - IMAGE 1)
# ==============================================================================

static func create_item_tile_card(
	item: Resource,
	on_purchase_callable: Callable,
	player_gold: int,
	player_diamonds: int
) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 252)
	panel.add_theme_stylebox_override("panel", get_card_style())

	var vb: VBoxContainer = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER

	# 1. Icône au centre (très grande pour valoriser les sachets & trésors)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(130, 130)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = item.icon_texture if item.icon_texture != null else load(FALLBACK_ICON_PATH)
	vb.add_child(icon)

	# 2. Nom de l'article (ex: 🍬 Sachet Solo) - épuré, sans sous-texte encombrant
	var name_lbl: Label = Label.new()
	name_lbl.text = item.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.24, 0.12, 0.04, 1.0))
	vb.add_child(name_lbl)

	# 3. Rangée des boutons d'achat
	var hb_btns: HBoxContainer = HBoxContainer.new()
	hb_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_btns.add_theme_constant_override("separation", 8)

	var has_gold: bool = item.gold_price >= 0
	var has_dia: bool = item.diamond_price >= 0

	if has_gold and has_dia:
		# Bouton Jaune (Or)
		var btn_g: Button = Button.new()
		btn_g.text = "%d 🪙" % item.gold_price
		btn_g.custom_minimum_size = Vector2(94, 42)
		btn_g.add_theme_font_size_override("font_size", 16)
		var can_gold: bool = (player_gold >= item.gold_price)
		if can_gold:
			btn_g.add_theme_stylebox_override("normal", get_yellow_pill_style())
			btn_g.add_theme_stylebox_override("hover", get_yellow_pill_style())
			btn_g.add_theme_stylebox_override("pressed", get_yellow_pill_pressed_style())
			btn_g.add_theme_color_override("font_color", Color(0.22, 0.11, 0.03, 1.0))
			wire_tactile_button(btn_g, item, false, on_purchase_callable)
		else:
			btn_g.add_theme_stylebox_override("disabled", get_disabled_pill_style())
			btn_g.disabled = true
			btn_g.add_theme_color_override("font_disabled_color", Color(0.40, 0.38, 0.36, 1.0))
		hb_btns.add_child(btn_g)

		# Bouton Bleu (Diamants)
		var btn_d: Button = Button.new()
		btn_d.text = "%d 💎" % item.diamond_price
		btn_d.custom_minimum_size = Vector2(94, 42)
		btn_d.add_theme_font_size_override("font_size", 16)
		var can_dia: bool = (player_diamonds >= item.diamond_price)
		if can_dia:
			btn_d.add_theme_stylebox_override("normal", get_blue_pill_style())
			btn_d.add_theme_stylebox_override("hover", get_blue_pill_style())
			btn_d.add_theme_stylebox_override("pressed", get_blue_pill_pressed_style())
			btn_d.add_theme_color_override("font_color", Color.WHITE)
			btn_d.add_theme_color_override("font_outline_color", Color(0.04, 0.22, 0.45, 1.0))
			btn_d.add_theme_constant_override("outline_size", 3)
			wire_tactile_button(btn_d, item, true, on_purchase_callable)
		else:
			btn_d.add_theme_stylebox_override("disabled", get_disabled_pill_style())
			btn_d.disabled = true
			btn_d.add_theme_color_override("font_disabled_color", Color(0.40, 0.38, 0.36, 1.0))
		hb_btns.add_child(btn_d)
	else:
		# Un seul bouton (ex: OR & TRÉSORS avec "10 💎")
		var single_btn: Button = Button.new()
		single_btn.custom_minimum_size = Vector2(120, 44)
		single_btn.add_theme_font_size_override("font_size", 17)
		if has_dia:
			single_btn.text = "%d 💎" % item.diamond_price
			var can_d: bool = (player_diamonds >= item.diamond_price)
			if can_d:
				single_btn.add_theme_stylebox_override("normal", get_blue_pill_style())
				single_btn.add_theme_stylebox_override("hover", get_blue_pill_style())
				single_btn.add_theme_stylebox_override("pressed", get_blue_pill_pressed_style())
				single_btn.add_theme_color_override("font_color", Color.WHITE)
				single_btn.add_theme_color_override("font_outline_color", Color(0.04, 0.22, 0.45, 1.0))
				single_btn.add_theme_constant_override("outline_size", 3)
				wire_tactile_button(single_btn, item, true, on_purchase_callable)
			else:
				single_btn.add_theme_stylebox_override("disabled", get_disabled_pill_style())
				single_btn.disabled = true
		else:
			single_btn.text = "%d 🪙" % maxi(0, item.gold_price)
			var can_g: bool = (player_gold >= item.gold_price)
			if can_g:
				single_btn.add_theme_stylebox_override("normal", get_yellow_pill_style())
				single_btn.add_theme_stylebox_override("hover", get_yellow_pill_style())
				single_btn.add_theme_stylebox_override("pressed", get_yellow_pill_pressed_style())
				single_btn.add_theme_color_override("font_color", Color(0.22, 0.11, 0.03, 1.0))
				wire_tactile_button(single_btn, item, false, on_purchase_callable)
			else:
				single_btn.add_theme_stylebox_override("disabled", get_disabled_pill_style())
				single_btn.disabled = true
		hb_btns.add_child(single_btn)

	vb.add_child(hb_btns)
	panel.add_child(vb)
	return panel
