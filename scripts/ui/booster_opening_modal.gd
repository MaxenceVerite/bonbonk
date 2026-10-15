class_name BoosterOpeningModal
extends Control

## Modal interactif d'ouverture de sachet de bonbons haute fidélité (Schéma utilisateur) :
## 1. Arrivée du sachet au centre avec animation d'anticipation (wobble) et spirale sucette tournoyante rouge/blanc en arrière-plan.
## 2. Déchirement progressif au Swipe sur la languette du haut (le lambeau suit le geste jusqu'à s'arracher avec éclat).
## 3. Le sachet ouvert s'avance (scale up) et descend en bas de l'écran pour ne laisser visible que sa bouche ouverte.
## 4. Au toucher / clic de l'écran : les bonbons jaillissent un par un, triés du plus commun au plus rare, avec leur nom dans un bandeau festif, quantité 'x N' et particules.
## 5. Résumé factuel final bien lisible et fermeture garantie sans écran noir résiduel.

signal opening_finished

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var spiral_backdrop: ColorRect = $SpiralBackdrop
@onready var instruction_label: Label = $InstructionLabel

@onready var pack_container: Control = $PackContainer
@onready var pack_body: TextureRect = $PackContainer/PackBody
@onready var pack_top: TextureRect = $PackContainer/PackTop
@onready var tear_line: Line2D = $PackContainer/TearLine
@onready var tear_prompt: Label = $PackContainer/TearPrompt

@onready var single_reveal_area: Control = $SingleRevealArea
@onready var rarity_badge_panel: PanelContainer = $SingleRevealArea/RarityBadgePanel
@onready var rarity_badge_label: Label = $SingleRevealArea/RarityBadgePanel/RarityBadgeLabel
@onready var banner_panel: PanelContainer = $SingleRevealArea/BannerPanel
@onready var candy_title: Label = $SingleRevealArea/BannerPanel/CandyTitle
@onready var big_candy_center: Control = $SingleRevealArea/BigCandyCenter
@onready var candy_icon: TextureRect = $SingleRevealArea/BigCandyCenter/Icon
@onready var candy_count_badge: Label = $SingleRevealArea/BigCandyCenter/CountBadge
@onready var rarity_subtitle: Label = $SingleRevealArea/RaritySubtitle

@onready var sparkles_root: Node2D = $SparklesRoot

# Récapitulatif
@onready var summary_container: Control = $SummaryContainer
@onready var summary_card: PanelContainer = $SummaryContainer/SummaryCard
@onready var drops_list: VBoxContainer = $SummaryContainer/SummaryCard/VBox/DropsList
@onready var gold_label: Label = $SummaryContainer/SummaryCard/VBox/GoldCard/GoldLabel
@onready var btn_collect: Button = $SummaryContainer/SummaryCard/VBox/BtnCollect

var _current_booster: BoosterData = null
var _booster_results: Dictionary = {}
var _sorted_drops: Array[Dictionary] = []
var _current_drop_index: int = -1

enum ModalState {
	IDLE,
	PACK_READY,
	TEARING_INTERACTIVE,
	RIPPING_AWAY,
	ZOOMING_TO_BOTTOM,
	READY_FOR_NEXT_CANDY,
	CANDY_BURSTING,
	SUMMARY
}
var _state: ModalState = ModalState.IDLE

# Gestuelle de déchirure progressive
var _touch_start_pos: Vector2 = Vector2.ZERO
var _current_rip_offset: float = 0.0
var _is_dragging_tear: bool = false
const RIP_DISTANCE_THRESHOLD: float = 70.0

var _idle_shake_tween: Tween = null
var _orig_pack_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	btn_collect.pressed.connect(_on_collect_pressed)

func start_opening(booster: BoosterData) -> void:
	_current_booster = booster
	visible = true
	modulate.a = 0.0
	_current_drop_index = -1
	_current_rip_offset = 0.0
	_is_dragging_tear = false

	# Positionnement propre du sachet au centre
	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0 and vs.y > 0:
			screen_w = vs.x
			screen_h = vs.y

	_orig_pack_pos = Vector2(
		(screen_w * 0.5) - (pack_container.size.x * 0.5),
		(screen_h * 0.5) - (pack_container.size.y * 0.5)
	)

	pack_container.visible = true
	pack_container.scale = Vector2.ONE
	pack_container.position = _orig_pack_pos
	pack_container.rotation = 0.0
	pack_container.modulate = Color.WHITE

	pack_body.visible = true
	pack_body.modulate = Color.WHITE
	pack_body.scale = Vector2.ONE
	pack_body.position = Vector2.ZERO

	pack_top.visible = true
	pack_top.modulate = Color.WHITE
	pack_top.position = Vector2.ZERO
	pack_top.rotation = 0.0
	pack_top.scale = Vector2.ONE

	tear_line.visible = true
	tear_prompt.visible = true
	tear_line.modulate.a = 1.0

	instruction_label.visible = true
	instruction_label.text = "✂️ GLISSEZ LA LANGUETTE DU SACHET ! ✂️"

	single_reveal_area.visible = false
	summary_container.visible = false
	spiral_backdrop.visible = true
	spiral_backdrop.modulate.a = 1.0

	# Textures selon le type de sachet
	match booster.booster_type:
		BoosterData.BoosterType.CLASSIC_SOLO:
			pack_top.texture = load("res://assets/ui/pack_classic_top.png")
			pack_body.texture = load("res://assets/ui/pack_classic_body.png")
		BoosterData.BoosterType.POP_SOLO:
			pack_top.texture = load("res://assets/ui/pack_pop_top.png")
			pack_body.texture = load("res://assets/ui/pack_pop_body.png")
		_:
			pack_top.texture = load("res://assets/ui/pack_piquant_top.png")
			pack_body.texture = load("res://assets/ui/pack_piquant_body.png")

	# Calcul des drops et tri par rareté (Commun -> Rare -> Épique)
	var all_cards: Array[CandyCardData] = []
	for cid in SaveManager.registered_card_defs:
		all_cards.append(SaveManager.registered_card_defs[cid])
	var unlocked_ids: Array[StringName] = SaveManager.get_unlocked_card_ids()

	_booster_results = booster.generate_drops(all_cards, unlocked_ids)
	var raw_drops: Array = _booster_results.get("drops", []).duplicate()
	
	raw_drops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rarity_a: int = a["card"].rarity
		var rarity_b: int = b["card"].rarity
		return rarity_a < rarity_b
	)
	_sorted_drops = []
	for d in raw_drops:
		_sorted_drops.append(d)

	# Fondu d'apparition du modal
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

	# Tremblement excité du sachet (Wobble / Frémissement)
	_start_excited_wobble()
	_state = ModalState.PACK_READY

func _start_excited_wobble() -> void:
	if _idle_shake_tween != null and _idle_shake_tween.is_valid():
		_idle_shake_tween.kill()

	_idle_shake_tween = create_tween().set_loops()
	_idle_shake_tween.tween_property(pack_container, "rotation", deg_to_rad(3.5), 0.08)
	_idle_shake_tween.tween_property(pack_container, "rotation", deg_to_rad(-3.5), 0.08)
	_idle_shake_tween.tween_property(pack_container, "rotation", 0.0, 0.08)
	_idle_shake_tween.tween_interval(0.2)

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	# Étape 1 : Glissement progressif sur la languette OU simple clic
	if _state == ModalState.PACK_READY or _state == ModalState.TEARING_INTERACTIVE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_touch_start_pos = event.position
				_is_dragging_tear = true
				_state = ModalState.TEARING_INTERACTIVE
				if _idle_shake_tween != null and _idle_shake_tween.is_valid():
					_idle_shake_tween.kill()
					pack_container.rotation = 0.0
			elif _is_dragging_tear:
				_is_dragging_tear = false
				var swipe_dist: float = event.position.x - _touch_start_pos.x
				# Si swipe suffisant OU simple tap rapide sur le sachet, on ouvre !
				if swipe_dist >= RIP_DISTANCE_THRESHOLD or (event.position - _touch_start_pos).length() < 12.0:
					_complete_pack_rip()
				else:
					_on_tear_drag_released()

		elif event is InputEventMouseMotion and _is_dragging_tear:
			var delta_x: float = maxf(0.0, event.position.x - _touch_start_pos.x)
			_update_interactive_tear(delta_x)

		elif event is InputEventScreenTouch:
			if event.pressed:
				_touch_start_pos = event.position
				_is_dragging_tear = true
				_state = ModalState.TEARING_INTERACTIVE
				if _idle_shake_tween != null and _idle_shake_tween.is_valid():
					_idle_shake_tween.kill()
					pack_container.rotation = 0.0
			elif _is_dragging_tear:
				_is_dragging_tear = false
				var swipe_dist: float = event.position.x - _touch_start_pos.x
				if swipe_dist >= RIP_DISTANCE_THRESHOLD or (event.position - _touch_start_pos).length() < 12.0:
					_complete_pack_rip()
				else:
					_on_tear_drag_released()

		elif event is InputEventScreenDrag and _is_dragging_tear:
			var delta_x: float = maxf(0.0, event.position.x - _touch_start_pos.x)
			_update_interactive_tear(delta_x)
		return

	# Étape 2 : Toucher pour faire sortir le bonbon suivant OU fermer le récapitulatif
	var is_tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if is_tap:
		if _state == ModalState.READY_FOR_NEXT_CANDY:
			_reveal_next_candy()
		elif _state == ModalState.SUMMARY:
			_on_collect_pressed()

func _update_interactive_tear(delta_x: float) -> void:
	_current_rip_offset = delta_x
	var progress: float = clampf(delta_x / RIP_DISTANCE_THRESHOLD, 0.0, 1.0)

	# La languette se décale vers la droite et pivote vers le haut
	pack_top.position = Vector2(progress * 70.0, -progress * 20.0)
	pack_top.rotation = deg_to_rad(progress * 28.0)
	tear_line.default_color.a = 1.0 - (progress * 0.7)

	# Si la languette est suffisamment étirée, on valide la déchirure complète !
	if delta_x >= RIP_DISTANCE_THRESHOLD:
		_is_dragging_tear = false
		_complete_pack_rip()

func _on_tear_drag_released() -> void:
	# Retour élastique si le geste n'est pas allé au bout
	var return_tw: Tween = create_tween().set_parallel(true)
	return_tw.tween_property(pack_top, "position", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tw.tween_property(pack_top, "rotation", 0.0, 0.15)
	return_tw.chain().tween_callback(func() -> void:
		_state = ModalState.PACK_READY
		_start_excited_wobble()
	)

func _complete_pack_rip() -> void:
	_state = ModalState.RIPPING_AWAY
	tear_line.visible = false
	tear_prompt.visible = false
	instruction_label.text = "💥 SCRIIIIITCH ! 💥"

	Input.vibrate_handheld(75)

	# 1. Éclat de confettis/étincelles le long de la ligne de déchirure
	var rip_global_pos: Vector2 = pack_container.global_position + Vector2(150.0, 78.0)
	_spawn_sparkle_burst(rip_global_pos, 28)

	# 2. Le lambeau du haut s'arrache et vole vers la droite
	var top_tw: Tween = create_tween().set_parallel(true)
	top_tw.tween_property(pack_top, "position", Vector2(500.0, -180.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	top_tw.tween_property(pack_top, "rotation", deg_to_rad(120.0), 0.42)
	top_tw.tween_property(pack_top, "modulate:a", 0.0, 0.38)

	# 3. Le sachet s'ouvre, s'agrandit et descend en bas de l'écran (Cadrage Schéma 3)
	top_tw.chain().tween_callback(_zoom_pack_to_bottom)

func _zoom_pack_to_bottom() -> void:
	_state = ModalState.ZOOMING_TO_BOTTOM

	# S'il y a plus d'un bonbon dans le sachet, inviter à sortir les bonbons
	if _sorted_drops.size() > 1:
		instruction_label.visible = true
		instruction_label.text = "🍬 TOUCHEZ POUR SORTIR LES BONBONS ! 🍬"
	else:
		instruction_label.visible = false

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0 and vs.y > 0:
			screen_w = vs.x
			screen_h = vs.y

	# On positionne le haut du sachet à environ 75% de la hauteur de l'écran avec une échelle agrandie (1.45)
	var target_scale: Vector2 = Vector2(1.45, 1.45)
	var target_pos: Vector2 = Vector2(
		(screen_w * 0.5) - (pack_container.size.x * target_scale.x * 0.5),
		screen_h - 220.0 # Seule l'ouverture dépasse en bas de l'écran
	)

	var zoom_tw: Tween = create_tween().set_parallel(true)
	zoom_tw.tween_property(pack_container, "position", target_pos, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	zoom_tw.tween_property(pack_container, "scale", target_scale, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	zoom_tw.chain().tween_callback(func() -> void:
		_state = ModalState.READY_FOR_NEXT_CANDY
		# Révéler immédiatement le premier bonbon
		_reveal_next_candy()
	)

func _reveal_next_candy() -> void:
	_current_drop_index += 1
	if _current_drop_index >= _sorted_drops.size():
		# Tous les bonbons sont sortis, passage au récapitulatif factuel !
		_show_factual_summary()
		return

	_state = ModalState.CANDY_BURSTING
	var drop: Dictionary = _sorted_drops[_current_drop_index]
	var card: CandyCardData = drop["card"]
	var count: int = drop["count"]
	var is_new: bool = drop.get("is_new", false)

	# Gestion de la mention en haut : ne s'affiche que s'il reste d'autres bonbons après celui-ci
	var remaining_after_this: int = _sorted_drops.size() - 1 - _current_drop_index
	if remaining_after_this > 0:
		instruction_label.visible = true
		instruction_label.text = "🍬 TOUCHEZ POUR SORTIR LES BONBONS ! 🍬"
	else:
		instruction_label.visible = false

	# Préparation de l'affichage unitaire
	single_reveal_area.visible = true
	candy_title.text = "%s%s" % [card.display_name, " (NOUVEAU !)" if is_new else ""]
	candy_icon.texture = card.icon_texture
	candy_count_badge.text = "x %d" % count

	# Habillage thématique du cadre selon la rareté
	_apply_rarity_style_to_banner(card.rarity)

	# Animation 1 : Le sachet en bas tressaute (squeeze & pop)
	var pack_squash: Tween = create_tween()
	pack_squash.tween_property(pack_body, "scale", Vector2(1.15, 0.85), 0.08)
	pack_squash.tween_property(pack_body, "scale", Vector2(0.9, 1.15), 0.12)
	pack_squash.tween_property(pack_body, "scale", Vector2.ONE, 0.1)

	# Animation 2 : Le bonbon jaillit du fond du paquet vers le centre de l'écran
	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0 and vs.y > 0:
			screen_w = vs.x
			screen_h = vs.y

	var spawn_pos: Vector2 = Vector2(screen_w * 0.5 - 100.0, screen_h - 180.0)
	var target_pos: Vector2 = Vector2(screen_w * 0.5 - 100.0, screen_h * 0.5 - 100.0)

	big_candy_center.position = spawn_pos
	big_candy_center.scale = Vector2(0.2, 0.2)
	big_candy_center.modulate.a = 0.0
	banner_panel.modulate.a = 0.0
	banner_panel.scale = Vector2(0.7, 0.7)
	banner_panel.pivot_offset = banner_panel.size * 0.5
	rarity_badge_panel.modulate.a = 0.0
	rarity_badge_panel.scale = Vector2(0.7, 0.7)
	rarity_badge_panel.pivot_offset = rarity_badge_panel.size * 0.5
	rarity_subtitle.modulate.a = 0.0

	Input.vibrate_handheld(45)

	var burst_tw: Tween = create_tween().set_parallel(true)
	burst_tw.tween_property(big_candy_center, "position", target_pos, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tw.tween_property(big_candy_center, "scale", Vector2(1.3, 1.3), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tw.tween_property(big_candy_center, "modulate:a", 1.0, 0.15)

	# Banderole de titre et sous-badge de rareté au-dessus, et invitation à continuer en-dessous
	burst_tw.chain().tween_property(banner_panel, "modulate:a", 1.0, 0.18)
	burst_tw.tween_property(banner_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tw.tween_property(rarity_badge_panel, "modulate:a", 1.0, 0.18)
	burst_tw.tween_property(rarity_badge_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tw.tween_property(rarity_subtitle, "modulate:a", 1.0, 0.22)

	# Étincelles festives au centre
	burst_tw.chain().tween_callback(func() -> void:
		_spawn_sparkle_burst(target_pos + Vector2(100.0, 100.0), 16)
		_state = ModalState.READY_FOR_NEXT_CANDY
	)

func _apply_rarity_style_to_banner(rarity: CandyCardData.Rarity) -> void:
	# 1. Style du cadre principal (titre)
	var title_style: StyleBoxFlat = StyleBoxFlat.new()
	title_style.corner_radius_top_left = 22
	title_style.corner_radius_top_right = 22
	title_style.corner_radius_bottom_left = 22
	title_style.corner_radius_bottom_right = 22
	title_style.content_margin_left = 28.0
	title_style.content_margin_right = 28.0
	title_style.content_margin_top = 12.0
	title_style.content_margin_bottom = 12.0
	title_style.border_width_left = 4
	title_style.border_width_top = 4
	title_style.border_width_right = 4
	title_style.border_width_bottom = 4
	title_style.shadow_size = 14
	title_style.shadow_offset = Vector2(0, 4)

	# 2. Style du sous-cadre de rareté (pastille supérieure)
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.corner_radius_bottom_right = 12
	badge_style.content_margin_left = 16.0
	badge_style.content_margin_right = 16.0
	badge_style.content_margin_top = 4.0
	badge_style.content_margin_bottom = 4.0
	badge_style.border_width_left = 2
	badge_style.border_width_top = 2
	badge_style.border_width_right = 2
	badge_style.border_width_bottom = 2
	badge_style.shadow_size = 8
	badge_style.shadow_offset = Vector2(0, 2)

	# Toujours sobre et dégagé en bas :
	rarity_subtitle.text = "Touchez pour continuer"

	match rarity:
		CandyCardData.Rarity.RARE:
			title_style.bg_color = Color(0.91, 0.95, 1.0, 0.98) # Bleu glacier très doux
			title_style.border_color = Color(0.18, 0.58, 0.98, 1.0) # Bleu électrique néon
			title_style.shadow_color = Color(0.1, 0.45, 0.95, 0.55)
			candy_title.add_theme_color_override("font_color", Color(0.05, 0.22, 0.62, 1.0))
			candy_title.add_theme_color_override("font_shadow_color", Color(0.85, 0.95, 1.0, 0.9))

			badge_style.bg_color = Color(0.18, 0.58, 0.98, 1.0)
			badge_style.border_color = Color(0.65, 0.88, 1.0, 1.0)
			badge_style.shadow_color = Color(0.1, 0.4, 0.9, 0.4)
			rarity_badge_label.text = "★ RARE ★"
			rarity_badge_label.add_theme_color_override("font_color", Color.WHITE)
			rarity_badge_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.15, 0.4, 0.8))

		CandyCardData.Rarity.EPIC:
			title_style.bg_color = Color(0.96, 0.90, 1.0, 0.98) # Doux éclat violet
			title_style.border_color = Color(0.80, 0.20, 0.92, 1.0) # Violet améthyste
			title_style.shadow_color = Color(0.70, 0.15, 0.85, 0.55)
			candy_title.add_theme_color_override("font_color", Color(0.40, 0.06, 0.52, 1.0))
			candy_title.add_theme_color_override("font_shadow_color", Color(0.95, 0.85, 1.0, 0.9))

			badge_style.bg_color = Color(0.78, 0.20, 0.92, 1.0)
			badge_style.border_color = Color(0.95, 0.70, 1.0, 1.0)
			badge_style.shadow_color = Color(0.5, 0.1, 0.65, 0.45)
			rarity_badge_label.text = "★★ ÉPIQUE ★★"
			rarity_badge_label.add_theme_color_override("font_color", Color.WHITE)
			rarity_badge_label.add_theme_color_override("font_shadow_color", Color(0.25, 0.05, 0.35, 0.8))

		CandyCardData.Rarity.LEGENDARY:
			title_style.bg_color = Color(1.0, 0.97, 0.88, 0.98) # Champagne lumineux
			title_style.border_color = Color(1.0, 0.78, 0.12, 1.0) # Or étincelant
			title_style.shadow_color = Color(0.95, 0.65, 0.05, 0.65)
			candy_title.add_theme_color_override("font_color", Color(0.52, 0.30, 0.0, 1.0))
			candy_title.add_theme_color_override("font_shadow_color", Color(1.0, 0.95, 0.75, 0.9))

			badge_style.bg_color = Color(0.95, 0.70, 0.10, 1.0)
			badge_style.border_color = Color(1.0, 0.95, 0.65, 1.0)
			badge_style.shadow_color = Color(0.7, 0.45, 0.0, 0.5)
			rarity_badge_label.text = "★★★ LÉGENDAIRE ★★★"
			rarity_badge_label.add_theme_color_override("font_color", Color.WHITE)
			rarity_badge_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.15, 0.0, 0.8))

		_: # COMMON
			title_style.bg_color = Color(0.98, 0.94, 0.88, 0.98) # Crème biscuit
			title_style.border_color = Color(0.65, 0.45, 0.32, 1.0) # Chocolat noisette
			title_style.shadow_color = Color(0.30, 0.15, 0.05, 0.35)
			candy_title.add_theme_color_override("font_color", Color(0.26, 0.12, 0.04, 1.0))
			candy_title.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.8))

			badge_style.bg_color = Color(0.65, 0.45, 0.32, 1.0)
			badge_style.border_color = Color(0.85, 0.72, 0.62, 1.0)
			badge_style.shadow_color = Color(0.2, 0.1, 0.05, 0.3)
			rarity_badge_label.text = "COMMUN"
			rarity_badge_label.add_theme_color_override("font_color", Color.WHITE)
			rarity_badge_label.add_theme_color_override("font_shadow_color", Color(0.15, 0.05, 0.02, 0.8))

	banner_panel.add_theme_stylebox_override("panel", title_style)
	rarity_badge_panel.add_theme_stylebox_override("panel", badge_style)

func _show_factual_summary() -> void:
	_state = ModalState.SUMMARY
	single_reveal_area.visible = false
	instruction_label.visible = false

	# Masquer le paquet du bas
	var fade_pack: Tween = create_tween()
	fade_pack.tween_property(pack_container, "modulate:a", 0.0, 0.25)
	fade_pack.tween_property(spiral_backdrop, "modulate:a", 0.4, 0.25)

	# Remplir le récapitulatif des bonbons
	for child in drops_list.get_children():
		child.queue_free()

	var total_gold: int = _booster_results.get("gold", 50)
	gold_label.text = "+ %d 🪙 D'OR" % total_gold

	for drop in _sorted_drops:
		var card: CandyCardData = drop["card"]
		var count: int = drop["count"]
		var is_new: bool = drop.get("is_new", false)

		var item_row: PanelContainer = PanelContainer.new()
		item_row.custom_minimum_size = Vector2(0, 50)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.theme_override_constants.set(&"separation", 14)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Icône du bonbon
		var icon: TextureRect = TextureRect.new()
		icon.texture = card.icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44, 44)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon)

		# Nom du bonbon
		var text_vbox: VBoxContainer = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_lbl: Label = Label.new()
		name_lbl.text = card.display_name
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color(0.18, 0.08, 0.02, 1.0))
		name_lbl.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		text_vbox.add_child(name_lbl)

		if is_new:
			var new_badge: Label = Label.new()
			new_badge.text = "★ NOUVEAU !"
			new_badge.add_theme_font_size_override("font_size", 14)
			new_badge.add_theme_color_override("font_color", Color(0.95, 0.45, 0.05, 1.0))
			text_vbox.add_child(new_badge)
		hbox.add_child(text_vbox)

		# Quantité "x N" bien contrastée
		var count_lbl: Label = Label.new()
		count_lbl.text = "x %d" % count
		count_lbl.custom_minimum_size = Vector2(70, 0)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", 26)
		count_lbl.add_theme_color_override("font_color", Color(0.85, 0.15, 0.35, 1.0))
		count_lbl.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.9))
		count_lbl.add_theme_constant_override("shadow_offset_y", 1)
		hbox.add_child(count_lbl)

		item_row.add_child(hbox)
		drops_list.add_child(item_row)

	# Affichage festif de la fiche
	summary_container.visible = true
	summary_container.modulate.a = 0.0
	summary_card.scale = Vector2(0.85, 0.85)
	summary_card.pivot_offset = summary_card.size * 0.5

	var sum_tw: Tween = create_tween().set_parallel(true)
	sum_tw.tween_property(summary_container, "modulate:a", 1.0, 0.22)
	sum_tw.tween_property(summary_card, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0 and vs.y > 0:
			screen_w = vs.x
			screen_h = vs.y

	_spawn_sparkle_burst(Vector2(screen_w * 0.5, screen_h * 0.5), 25)


func _on_collect_pressed() -> void:
	# 1. Sauvegarde et application immédiate des récompenses
	SaveManager.apply_booster_rewards(_booster_results)

	# 2. Fermeture garantie de tout l'overlay
	var close_tw: Tween = create_tween()
	close_tw.tween_property(self, "modulate:a", 0.0, 0.2)
	close_tw.tween_callback(func() -> void:
		visible = false
		_state = ModalState.IDLE
		opening_finished.emit()
	)

func _spawn_sparkle_burst(origin_pos: Vector2, count: int) -> void:
	var sparkle_tex: Texture2D = load("res://assets/ui/sparkle_star.png")
	for i in range(count):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = sparkle_tex
		spr.global_position = origin_pos
		spr.scale = Vector2(randf_range(0.6, 1.3), randf_range(0.6, 1.3))
		sparkles_root.add_child(spr)

		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(60.0, 260.0)
		var dest: Vector2 = origin_pos + Vector2(cos(angle), sin(angle)) * dist

		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(spr, "global_position", dest, randf_range(0.35, 0.65)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "rotation", randf_range(-5.0, 5.0), 0.6)
		tw.tween_property(spr, "modulate:a", 0.0, randf_range(0.35, 0.6)).set_delay(0.12)
		tw.chain().tween_callback(spr.queue_free)
