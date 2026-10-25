class_name BoosterOpeningModal
extends Control

## Modal interactif d'ouverture de sachet de bonbons haute fidélité :
## 1. Arrivée du sachet au centre avec animation d'anticipation (wobble).
## 2. Déchirement tactile progressif : la languette se déchire et s'enroule sur elle-même (curl) sous le doigt !
## 3. Le sachet descend en bas de l'écran, son col ouvert et argenté servant de distributeur.
## 4. Au toucher : le sachet s'écrase (squash & pop) et le BONBON SEUL jaillit de l'ouverture en fade-in,
##    avec au-dessus son cadre/bannière coloré selon la rareté et son compteur.
## 5. Résumé factuel final avec or, diamants et réouverture directe du sachet suivant.

signal opening_finished

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var spiral_backdrop: ColorRect = $SpiralBackdrop
@onready var instruction_label: Label = $InstructionLabel

@onready var pack_container: Control = $PackContainer
@onready var pack_body: TextureRect = $PackContainer/PackBody
@onready var untorn_strip_clip: Control = $PackContainer/UntornStripClip
@onready var pack_top: TextureRect = $PackContainer/UntornStripClip/PackTop
@onready var tear_curl: Control = $PackContainer/TearCurl
@onready var curl_sprite: TextureRect = $PackContainer/TearCurl/CurlSprite

@onready var single_reveal_area: Control = $SingleRevealArea
@onready var rarity_badge_panel: PanelContainer = $SingleRevealArea/RarityBadgePanel
@onready var rarity_badge_label: Label = $SingleRevealArea/RarityBadgePanel/RarityBadgeLabel
@onready var banner_panel: PanelContainer = $SingleRevealArea/BannerPanel
@onready var candy_title: Label = $SingleRevealArea/BannerPanel/CandyTitle
@onready var candy_center: Control = $SingleRevealArea/CandyCenter
@onready var candy_aura: TextureRect = $SingleRevealArea/CandyCenter/CandyAura
@onready var candy_icon: TextureRect = $SingleRevealArea/CandyCenter/Icon
@onready var count_badge_panel: PanelContainer = $SingleRevealArea/CountBadgePanel
@onready var count_badge: Label = $SingleRevealArea/CountBadgePanel/CountBadge
@onready var new_ribbon: Label = $SingleRevealArea/NewRibbon
@onready var rarity_subtitle: Label = $SingleRevealArea/RaritySubtitle

@onready var sparkles_root: Node2D = $SparklesRoot

# Récapitulatif
@onready var summary_container: Control = $SummaryContainer
@onready var summary_card: PanelContainer = $SummaryContainer/SummaryCard
@onready var drops_list: VBoxContainer = $SummaryContainer/SummaryCard/VBox/DropsList
@onready var gold_label: Label = $SummaryContainer/SummaryCard/VBox/RewardsRow/GoldCard/GoldLabel
@onready var diamond_card: PanelContainer = $SummaryContainer/SummaryCard/VBox/RewardsRow/DiamondCard
@onready var diamond_label: Label = $SummaryContainer/SummaryCard/VBox/RewardsRow/DiamondCard/DiamondLabel
@onready var btn_collect: Button = $SummaryContainer/SummaryCard/VBox/ButtonsRow/BtnCollect
@onready var btn_open_next: Button = $SummaryContainer/SummaryCard/VBox/ButtonsRow/BtnOpenNext

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
	CANDY_EXITING,
	SUMMARY
}
var _state: ModalState = ModalState.IDLE

# Gestuelle de déchirure
var _touch_start_pos: Vector2 = Vector2.ZERO
var _current_rip_offset: float = 0.0
var _is_dragging_tear: bool = false
const RIP_DISTANCE_THRESHOLD: float = 160.0

var _idle_shake_tween: Tween = null
var _burst_tween: Tween = null
var _orig_pack_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	z_index = 100
	btn_collect.pressed.connect(_on_collect_pressed)
	btn_open_next.pressed.connect(_on_open_next_pressed)

func _process(delta: float) -> void:
	if single_reveal_area != null and single_reveal_area.visible and candy_aura != null:
		candy_aura.rotation += delta * 0.65

func start_opening(booster: BoosterData) -> void:
	_current_booster = booster
	visible = true
	modulate.a = 1.0
	_current_drop_index = -1
	_current_rip_offset = 0.0
	_is_dragging_tear = false

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			screen_w = vs.x
			screen_h = vs.y

	_orig_pack_pos = Vector2(
		(screen_w * 0.5) - (pack_container.size.x * 0.5),
		(screen_h * 0.5) - (pack_container.size.y * 0.5) - 20.0
	)

	pack_container.visible = true
	pack_container.position = _orig_pack_pos
	pack_container.rotation = 0.0
	pack_container.modulate = Color.WHITE

	# Textures selon le booster
	pack_body.texture = booster.get_open_body_texture()
	pack_body.scale = Vector2.ONE
	pack_body.position = Vector2.ZERO

	pack_top.texture = booster.get_top_texture()
	curl_sprite.texture = booster.get_top_texture()

	untorn_strip_clip.visible = true
	untorn_strip_clip.offset_left = 0.0
	pack_top.position.x = 0.0

	tear_curl.visible = false
	tear_curl.position = Vector2.ZERO
	tear_curl.rotation = 0.0
	tear_curl.scale = Vector2.ONE
	tear_curl.modulate.a = 1.0

	instruction_label.visible = true
	instruction_label.text = "✂️ GLISSEZ POUR DÉCHIRER LE SACHET ✂️"

	single_reveal_area.visible = false
	single_reveal_area.modulate.a = 1.0
	summary_container.visible = false
	btn_collect.disabled = false
	btn_open_next.disabled = false
	spiral_backdrop.visible = true
	spiral_backdrop.modulate.a = 1.0

	var mat: ShaderMaterial = spiral_backdrop.material as ShaderMaterial
	if mat != null:
		var acc: Color = booster.get_accent_color()
		mat.set_shader_parameter("color_red", Color(acc.r, acc.g, acc.b, 0.45))

	# Calcul des drops et tri par rareté
	var all_cards: Array[CandyCardData] = []
	for cid in SaveManager.registered_card_defs:
		all_cards.append(SaveManager.registered_card_defs[cid])
	var unlocked_ids: Array[StringName] = SaveManager.get_unlocked_card_ids()

	_booster_results = booster.generate_drops(all_cards, unlocked_ids)
	var raw_drops: Array = _booster_results.get("drops", []).duplicate()

	# Fusion défensive des doublons : regrouper les quantités par bonbon
	var merged_map: Dictionary = {}
	var unique_drops: Array[Dictionary] = []
	for d in raw_drops:
		var c: CandyCardData = d["card"]
		var cid: StringName = c.id
		if merged_map.has(cid):
			var existing: Dictionary = merged_map[cid]
			existing["count"] = int(existing["count"]) + int(d["count"])
			if d.get("is_new", false):
				existing["is_new"] = true
		else:
			var entry: Dictionary = {
				"card": c,
				"count": int(d["count"]),
				"is_new": d.get("is_new", false)
			}
			merged_map[cid] = entry
			unique_drops.append(entry)

	# Tri par rareté croissante : du moins rare au plus rare (le climax à la fin)
	unique_drops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rarity_a: int = a["card"].rarity
		var rarity_b: int = b["card"].rarity
		if rarity_a != rarity_b:
			return rarity_a < rarity_b
		return a["card"].display_name < b["card"].display_name
	)

	_sorted_drops = unique_drops
	_booster_results["drops"] = _sorted_drops

	# Arrivée rebondie du sachet au centre
	pack_container.scale = Vector2(0.5, 0.5)
	var tw: Tween = create_tween()
	tw.tween_property(pack_container, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_start_excited_wobble()
	_state = ModalState.PACK_READY

func _start_excited_wobble() -> void:
	if _idle_shake_tween != null and _idle_shake_tween.is_valid():
		_idle_shake_tween.kill()

	_idle_shake_tween = create_tween().set_loops()
	_idle_shake_tween.tween_property(pack_container, "rotation", deg_to_rad(3.0), 0.08)
	_idle_shake_tween.tween_property(pack_container, "rotation", deg_to_rad(-3.0), 0.08)
	_idle_shake_tween.tween_property(pack_container, "rotation", 0.0, 0.08)
	_idle_shake_tween.tween_interval(0.25)

## Capture directe des événements d'entrée pour garantir le multitouch / glissement tactile sur mobile
func _input(event: InputEvent) -> void:
	if not visible or _state == ModalState.IDLE:
		return

	# Étape 1 : Glissement progressif sur la languette avec enroulement
	if _state == ModalState.PACK_READY or _state == ModalState.TEARING_INTERACTIVE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_touch_start_pos = event.position
				_is_dragging_tear = true
				_state = ModalState.TEARING_INTERACTIVE
				if _idle_shake_tween != null and _idle_shake_tween.is_valid():
					_idle_shake_tween.kill()
					pack_container.rotation = 0.0
				get_viewport().set_input_as_handled()
			elif _is_dragging_tear:
				_is_dragging_tear = false
				var swipe_dist: float = event.position.x - _touch_start_pos.x
				if swipe_dist >= RIP_DISTANCE_THRESHOLD or swipe_dist > 50.0:
					_complete_pack_rip()
				elif (event.position - _touch_start_pos).length() < 14.0:
					_animate_auto_tear()
				else:
					_on_tear_drag_released()
				get_viewport().set_input_as_handled()

		elif event is InputEventMouseMotion and _is_dragging_tear:
			var delta_x: float = maxf(0.0, event.position.x - _touch_start_pos.x)
			_update_interactive_tear(delta_x)
			get_viewport().set_input_as_handled()

		elif event is InputEventScreenTouch:
			if event.pressed:
				_touch_start_pos = event.position
				_is_dragging_tear = true
				_state = ModalState.TEARING_INTERACTIVE
				if _idle_shake_tween != null and _idle_shake_tween.is_valid():
					_idle_shake_tween.kill()
					pack_container.rotation = 0.0
				get_viewport().set_input_as_handled()
			elif _is_dragging_tear:
				_is_dragging_tear = false
				var swipe_dist: float = event.position.x - _touch_start_pos.x
				if swipe_dist >= RIP_DISTANCE_THRESHOLD or swipe_dist > 50.0:
					_complete_pack_rip()
				elif (event.position - _touch_start_pos).length() < 14.0:
					_animate_auto_tear()
				else:
					_on_tear_drag_released()
				get_viewport().set_input_as_handled()

		elif event is InputEventScreenDrag and _is_dragging_tear:
			var delta_x: float = maxf(0.0, event.position.x - _touch_start_pos.x)
			_update_interactive_tear(delta_x)
			get_viewport().set_input_as_handled()
		return

	# Étape 2 : Toucher pour sortir le bonbon suivant OU accélérer
	var is_tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if is_tap:
		if _state == ModalState.READY_FOR_NEXT_CANDY:
			_transition_to_next_candy()
			get_viewport().set_input_as_handled()
		elif _state == ModalState.CANDY_BURSTING:
			_skip_current_burst()
			get_viewport().set_input_as_handled()
		# En ModalState.CANDY_EXITING ou SUMMARY : aucun tap accidentel ne ferme le résumé ni n'interrompt la sortie.

func _animate_auto_tear() -> void:
	_state = ModalState.TEARING_INTERACTIVE
	if _idle_shake_tween != null and _idle_shake_tween.is_valid():
		_idle_shake_tween.kill()
		pack_container.rotation = 0.0

	var tw: Tween = create_tween()
	tw.tween_method(func(prog: float) -> void:
		_update_interactive_tear_progress(prog)
	, 0.0, 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_complete_pack_rip)

## Déchirement et enroulement progressif de la languette (Curl)
func _update_interactive_tear(delta_x: float) -> void:
	_current_rip_offset = delta_x
	var progress: float = clampf(delta_x / RIP_DISTANCE_THRESHOLD, 0.0, 1.0)
	_update_interactive_tear_progress(progress)

	if delta_x >= RIP_DISTANCE_THRESHOLD:
		_is_dragging_tear = false
		_complete_pack_rip()

func _update_interactive_tear_progress(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	var pack_w: float = pack_container.size.x

	var cut_x: float = progress * pack_w

	# 1. Découpage progressif de la bande plate
	untorn_strip_clip.offset_left = cut_x
	pack_top.position.x = -cut_x

	# 2. Le rouleau s'enroule sur lui-même à la tête de déchirure
	if progress > 0.01:
		tear_curl.visible = true
		tear_curl.position = Vector2(cut_x - 18.0, -progress * 12.0)
		tear_curl.rotation = progress * TAU * 3.5
		tear_curl.scale = Vector2(0.6 + progress * 0.6, 0.85 + progress * 0.25)
	else:
		tear_curl.visible = false


## Retour fluide si glissement relâché avant d'avoir déchiré complètement
func _on_tear_drag_released() -> void:
	var return_tw: Tween = create_tween().set_parallel(true)
	return_tw.tween_property(untorn_strip_clip, "offset_left", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tw.tween_property(pack_top, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tw.tween_property(tear_curl, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tw.tween_property(tear_curl, "rotation", 0.0, 0.18)
	return_tw.chain().tween_callback(func() -> void:
		tear_curl.visible = false
		_state = ModalState.PACK_READY
		_start_excited_wobble()
	)

## Déchirure complète : le rouleau s'envole en tournoyant
func _complete_pack_rip() -> void:
	_state = ModalState.RIPPING_AWAY
	instruction_label.text = "💥 SCRIIIIITCH ! 💥"

	Input.vibrate_handheld(75)

	var rip_pos: Vector2 = pack_container.global_position + Vector2(pack_container.size.x * 0.5, 36.0)
	_spawn_sparkle_burst(rip_pos, 26, Color(1.0, 0.95, 0.4))

	untorn_strip_clip.visible = false
	tear_curl.visible = true

	var fly_tw: Tween = create_tween().set_parallel(true)
	fly_tw.tween_property(tear_curl, "position", Vector2(460.0, -180.0), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly_tw.tween_property(tear_curl, "rotation", deg_to_rad(720.0), 0.38)
	fly_tw.tween_property(tear_curl, "modulate:a", 0.0, 0.32)

	fly_tw.chain().tween_callback(_zoom_pack_to_bottom)

## Descente du sachet en bas de l'écran (le col ouvert devient le distributeur)
func _zoom_pack_to_bottom() -> void:
	_state = ModalState.ZOOMING_TO_BOTTOM
	instruction_label.visible = false

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			screen_w = vs.x
			screen_h = vs.y

	var target_scale: Vector2 = Vector2(1.22, 1.22)
	var target_pos: Vector2 = Vector2(
		(screen_w * 0.5) - (pack_container.size.x * target_scale.x * 0.5),
		screen_h - 225.0
	)

	var zoom_tw: Tween = create_tween().set_parallel(true)
	zoom_tw.tween_property(pack_container, "position", target_pos, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	zoom_tw.tween_property(pack_container, "scale", target_scale, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	zoom_tw.chain().tween_callback(func() -> void:
		_state = ModalState.READY_FOR_NEXT_CANDY
		_reveal_next_candy()
	)

func _get_rarity_color(rarity: CandyCardData.Rarity) -> Color:
	match rarity:
		CandyCardData.Rarity.MYTHIC:
			return Color(1.0, 0.25, 0.85, 1.0) # Magenta étincelant
		CandyCardData.Rarity.LEGENDARY:
			return Color(1.0, 0.82, 0.15, 1.0) # Or solaire
		CandyCardData.Rarity.EPIC:
			return Color(0.80, 0.22, 0.95, 1.0) # Violet améthyste
		CandyCardData.Rarity.RARE:
			return Color(0.18, 0.65, 1.0, 1.0) # Bleu électrique
		CandyCardData.Rarity.UNCOMMON:
			return Color(0.20, 0.95, 0.75, 1.0) # Menthe fluo
		_:
			return Color(1.0, 0.90, 0.68, 1.0) # Crème biscuit

## Révélation d'un bonbon : jaillit depuis le col ouvert du sachet avec fade-in
func _reveal_next_candy() -> void:
	_current_drop_index += 1
	if _current_drop_index >= _sorted_drops.size():
		_state = ModalState.SUMMARY
		var fade_last: Tween = create_tween()
		fade_last.tween_property(single_reveal_area, "modulate:a", 0.0, 0.16)
		fade_last.tween_callback(_show_factual_summary)
		return

	_state = ModalState.CANDY_BURSTING
	var drop: Dictionary = _sorted_drops[_current_drop_index]
	var card: CandyCardData = drop["card"]
	var count: int = drop["count"]
	var is_new: bool = drop.get("is_new", false)
	var rarity_col: Color = _get_rarity_color(card.rarity)

	instruction_label.visible = false

	# Données du bonbon
	single_reveal_area.visible = true
	single_reveal_area.modulate.a = 1.0
	candy_title.text = card.display_name
	candy_icon.texture = card.icon_texture
	count_badge.text = "x %d" % count
	new_ribbon.visible = is_new

	_apply_rarity_style_to_banner(card.rarity, rarity_col)

	var is_last_candy: bool = (_current_drop_index == _sorted_drops.size() - 1)
	if is_last_candy:
		rarity_subtitle.text = "▶ Touchez pour voir le butin ◀"
	else:
		rarity_subtitle.text = "▶ Touchez pour continuer ◀"

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			screen_w = vs.x
			screen_h = vs.y

	var bag_mouth_pos: Vector2 = Vector2(screen_w * 0.5, screen_h - 190.0)
	var spawn_pos: Vector2 = Vector2(screen_w * 0.5 - 110.0, screen_h - 220.0)
	var target_pos: Vector2 = Vector2(screen_w * 0.5 - 110.0, screen_h * 0.51 - 110.0)

	# Squash & Pop du sachet au bas : même impulsion dynamique et punchy pour chaque bonbon tiré
	var pack_squash: Tween = create_tween()
	pack_squash.tween_property(pack_body, "scale", Vector2(1.16, 0.84), 0.07)
	pack_squash.tween_property(pack_body, "scale", Vector2(0.92, 1.14), 0.10)
	pack_squash.tween_property(pack_body, "scale", Vector2.ONE, 0.10)

	# Étoiles de la rareté émises au col
	_spawn_sparkle_burst(bag_mouth_pos, 16, rarity_col)

	# Positionnement initial du bonbon : au niveau du col ouvert du sachet, réduit et transparent
	candy_center.position = spawn_pos
	candy_center.scale = Vector2(0.25, 0.25)
	candy_center.modulate.a = 0.0

	banner_panel.modulate.a = 0.0
	banner_panel.scale = Vector2(0.85, 0.85)
	banner_panel.pivot_offset = banner_panel.size * 0.5

	rarity_badge_panel.modulate.a = 0.0
	rarity_badge_panel.scale = Vector2(0.85, 0.85)
	rarity_badge_panel.pivot_offset = rarity_badge_panel.size * 0.5

	count_badge_panel.modulate.a = 0.0
	count_badge_panel.scale = Vector2(0.85, 0.85)
	count_badge_panel.pivot_offset = count_badge_panel.size * 0.5

	rarity_subtitle.modulate.a = 0.0

	var vib_ms: int = 40
	if card.rarity >= CandyCardData.Rarity.EPIC:
		vib_ms = 85
	Input.vibrate_handheld(vib_ms)

	if _burst_tween != null and _burst_tween.is_valid():
		_burst_tween.kill()

	_burst_tween = create_tween().set_parallel(true)
	# 1. Envol et grossissement du bonbon depuis l'ouverture du sachet jusqu'au centre
	_burst_tween.tween_property(candy_center, "position", target_pos, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst_tween.tween_property(candy_center, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst_tween.tween_property(candy_center, "modulate:a", 1.0, 0.16)

	# 2. Arrivée synchronisée du cadre de rareté et du nom au-dessus
	_burst_tween.chain().set_parallel(true)
	_burst_tween.tween_property(banner_panel, "modulate:a", 1.0, 0.18)
	_burst_tween.tween_property(banner_panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst_tween.tween_property(rarity_badge_panel, "modulate:a", 1.0, 0.18)
	_burst_tween.tween_property(rarity_badge_panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst_tween.tween_property(count_badge_panel, "modulate:a", 1.0, 0.18)
	_burst_tween.tween_property(count_badge_panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst_tween.tween_property(rarity_subtitle, "modulate:a", 1.0, 0.22)

	_burst_tween.chain().tween_callback(func() -> void:
		var sparkle_count: int = 16
		if card.rarity >= CandyCardData.Rarity.EPIC:
			sparkle_count = 28
		_spawn_sparkle_burst(Vector2(screen_w * 0.5, screen_h * 0.51), sparkle_count, rarity_col)
		_state = ModalState.READY_FOR_NEXT_CANDY
	)

## Transition fluide entre bonbons : fait sortir le bonbon actuel avant d'éjecter le suivant du sachet
func _transition_to_next_candy() -> void:
	if _state != ModalState.READY_FOR_NEXT_CANDY:
		return

	var is_last_candy: bool = (_current_drop_index >= _sorted_drops.size() - 1)
	_state = ModalState.CANDY_EXITING

	var exit_tw: Tween = create_tween().set_parallel(true)
	exit_tw.tween_property(candy_center, "position:y", candy_center.position.y - 60.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tw.tween_property(candy_center, "scale", Vector2(0.8, 0.8), 0.15)
	exit_tw.tween_property(candy_center, "modulate:a", 0.0, 0.14)
	exit_tw.tween_property(banner_panel, "modulate:a", 0.0, 0.11)
	exit_tw.tween_property(rarity_badge_panel, "modulate:a", 0.0, 0.11)
	exit_tw.tween_property(count_badge_panel, "modulate:a", 0.0, 0.11)
	exit_tw.tween_property(rarity_subtitle, "modulate:a", 0.0, 0.09)

	if is_last_candy:
		exit_tw.chain().tween_callback(_show_factual_summary)
	else:
		exit_tw.chain().tween_callback(_reveal_next_candy)

func _skip_current_burst() -> void:
	if _burst_tween != null and _burst_tween.is_valid():
		_burst_tween.kill()

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			screen_w = vs.x
			screen_h = vs.y

	candy_center.position = Vector2(screen_w * 0.5 - 110.0, screen_h * 0.51 - 110.0)
	candy_center.scale = Vector2.ONE
	candy_center.modulate.a = 1.0

	banner_panel.modulate.a = 1.0
	banner_panel.scale = Vector2.ONE
	rarity_badge_panel.modulate.a = 1.0
	rarity_badge_panel.scale = Vector2.ONE
	count_badge_panel.modulate.a = 1.0
	count_badge_panel.scale = Vector2.ONE
	rarity_subtitle.modulate.a = 1.0

	pack_body.scale = Vector2.ONE
	_state = ModalState.READY_FOR_NEXT_CANDY

## Style personnalisé du cadre au-dessus du bonbon selon sa couleur de rareté
func _apply_rarity_style_to_banner(rarity: CandyCardData.Rarity, rarity_col: Color) -> void:
	# Halo d'aura tournoyant derrière le bonbon
	candy_aura.modulate = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.5)

	# 1. Bannière du Nom
	var title_sb: StyleBoxFlat = StyleBoxFlat.new()
	title_sb.corner_radius_top_left = 20
	title_sb.corner_radius_top_right = 20
	title_sb.corner_radius_bottom_left = 20
	title_sb.corner_radius_bottom_right = 20
	title_sb.content_margin_left = 28.0
	title_sb.content_margin_right = 28.0
	title_sb.content_margin_top = 10.0
	title_sb.content_margin_bottom = 10.0
	title_sb.bg_color = Color(0.14, 0.06, 0.16, 0.94)
	title_sb.border_width_left = 3
	title_sb.border_width_top = 3
	title_sb.border_width_right = 3
	title_sb.border_width_bottom = 3
	title_sb.border_color = rarity_col
	title_sb.shadow_size = 12
	title_sb.shadow_color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.4)
	banner_panel.add_theme_stylebox_override("panel", title_sb)

	# 2. Badge de rareté au-dessus de la bannière
	var badge_sb: StyleBoxFlat = StyleBoxFlat.new()
	badge_sb.corner_radius_top_left = 12
	badge_sb.corner_radius_top_right = 12
	badge_sb.corner_radius_bottom_left = 12
	badge_sb.corner_radius_bottom_right = 12
	badge_sb.content_margin_left = 16.0
	badge_sb.content_margin_right = 16.0
	badge_sb.content_margin_top = 4.0
	badge_sb.content_margin_bottom = 4.0
	badge_sb.bg_color = rarity_col
	badge_sb.border_width_left = 2
	badge_sb.border_width_top = 2
	badge_sb.border_width_right = 2
	badge_sb.border_width_bottom = 2
	badge_sb.border_color = Color(1, 1, 1, 0.9)
	badge_sb.shadow_size = 6
	badge_sb.shadow_color = Color(0, 0, 0, 0.4)
	rarity_badge_panel.add_theme_stylebox_override("panel", badge_sb)

	match rarity:
		CandyCardData.Rarity.MYTHIC:
			rarity_badge_label.text = "✨ MYTHIQUE ✨"
		CandyCardData.Rarity.LEGENDARY:
			rarity_badge_label.text = "★★★ LÉGENDAIRE ★★★"
		CandyCardData.Rarity.EPIC:
			rarity_badge_label.text = "★★ ÉPIQUE ★★"
		CandyCardData.Rarity.RARE:
			rarity_badge_label.text = "★ RARE ★"
		CandyCardData.Rarity.UNCOMMON:
			rarity_badge_label.text = "PEU COMMUN"
		_:
			rarity_badge_label.text = "COMMUN"

	# 3. Badge du compteur "x N"
	var count_sb: StyleBoxFlat = StyleBoxFlat.new()
	count_sb.corner_radius_top_left = 14
	count_sb.corner_radius_top_right = 14
	count_sb.corner_radius_bottom_left = 14
	count_sb.corner_radius_bottom_right = 14
	count_sb.content_margin_left = 18.0
	count_sb.content_margin_right = 18.0
	count_sb.content_margin_top = 4.0
	count_sb.content_margin_bottom = 4.0
	count_sb.bg_color = Color(0.12, 0.05, 0.02, 0.92)
	count_sb.border_width_left = 2
	count_sb.border_width_top = 2
	count_sb.border_width_right = 2
	count_sb.border_width_bottom = 2
	count_sb.border_color = Color(1.0, 0.88, 0.25, 0.95)
	count_sb.shadow_size = 6
	count_sb.shadow_color = Color(0, 0, 0, 0.45)
	count_badge_panel.add_theme_stylebox_override("panel", count_sb)

func _show_factual_summary() -> void:
	_state = ModalState.SUMMARY
	single_reveal_area.visible = false
	instruction_label.visible = false

	# Verrouillage temporaire des boutons pour éviter tout double-clic résiduel
	btn_collect.disabled = true
	btn_open_next.disabled = true

	var fade_pack: Tween = create_tween()
	fade_pack.tween_property(pack_container, "modulate:a", 0.0, 0.25)
	fade_pack.tween_property(spiral_backdrop, "modulate:a", 0.35, 0.25)

	for child in drops_list.get_children():
		child.queue_free()

	var total_gold: int = _booster_results.get("gold", 50)
	gold_label.text = "+ %d 🪙 D'OR" % total_gold

	var total_dia: int = _booster_results.get("diamonds", 0)
	if total_dia > 0:
		diamond_card.visible = true
		diamond_label.text = "+ %d 💎" % total_dia
	else:
		diamond_card.visible = false

	for drop in _sorted_drops:
		var card: CandyCardData = drop["card"]
		var count: int = drop["count"]
		var is_new: bool = drop.get("is_new", false)

		var item_row: PanelContainer = PanelContainer.new()
		item_row.custom_minimum_size = Vector2(0, 48)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon: TextureRect = TextureRect.new()
		icon.texture = card.icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44, 44)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon)

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

	var remaining_boosters_count: int = SaveManager.available_boosters.size()
	if remaining_boosters_count > 0:
		btn_open_next.visible = true
		btn_open_next.text = "✨ SUIVANT (x%d)" % remaining_boosters_count
		btn_collect.text = "FERMER"
	else:
		btn_open_next.visible = false
		btn_collect.text = "RÉCUPÉRER TOUT"

	summary_container.visible = true
	summary_container.modulate.a = 0.0
	summary_card.scale = Vector2(0.85, 0.85)
	summary_card.pivot_offset = summary_card.size * 0.5

	var sum_tw: Tween = create_tween().set_parallel(true)
	sum_tw.tween_property(summary_container, "modulate:a", 1.0, 0.22)
	sum_tw.tween_property(summary_card, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sum_tw.chain().tween_callback(func() -> void:
		if is_instance_valid(btn_collect):
			btn_collect.disabled = false
		if is_instance_valid(btn_open_next):
			btn_open_next.disabled = false
	)

	var screen_w: float = 720.0
	var screen_h: float = 1280.0
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var vs: Vector2 = viewport.get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			screen_w = vs.x
			screen_h = vs.y

	_spawn_sparkle_burst(Vector2(screen_w * 0.5, screen_h * 0.5), 25, Color(1.0, 0.85, 0.2))

func _on_collect_pressed() -> void:
	if _state == ModalState.IDLE:
		return
	_state = ModalState.IDLE
	btn_collect.disabled = true
	btn_open_next.disabled = true
	SaveManager.apply_booster_rewards(_booster_results)

	var close_tw: Tween = create_tween()
	close_tw.tween_property(self, "modulate:a", 0.0, 0.2)
	close_tw.tween_callback(func() -> void:
		visible = false
		opening_finished.emit()
	)

func _on_open_next_pressed() -> void:
	if _state == ModalState.IDLE:
		return
	_state = ModalState.IDLE
	btn_collect.disabled = true
	btn_open_next.disabled = true
	SaveManager.apply_booster_rewards(_booster_results)

	if SaveManager.available_boosters.is_empty():
		_on_collect_pressed()
		return

	var next_booster: BoosterData = SaveManager.available_boosters.pop_front()
	start_opening(next_booster)

func _spawn_sparkle_burst(origin_pos: Vector2, count: int, tint: Color = Color.WHITE) -> void:
	var sparkle_tex: Texture2D = load("res://assets/ui/sparkle_star.png")
	for i in range(count):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = sparkle_tex
		spr.global_position = origin_pos
		spr.modulate = Color(tint.r, tint.g, tint.b, 0.9)
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
