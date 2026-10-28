class_name ShopRewardModal
extends Control

## Modal de confirmation d'achat et de célébration de la boutique.
## Garantit l'absence d'achat involontaire :
## 1. Mode CONFIRMATION : Aperçu clair du sachet/trésor, détail de son contenu,
##    prix explicite et solde restant avec boutons "ANNULER" et "CONFIRMER".
##    Tant qu'on n'a pas appuyé sur "Confirmer", l'achat n'est pas validé !
## 2. Mode CÉLÉBRATION (REWARD) : Après validation, pop-in festif, spirale rotative,
##    et ouverture directe du sachet ou envol dynamique des devises !

signal purchase_confirmed(item: ShopItemData, use_diamonds: bool, origin_global_pos: Vector2)
signal purchase_cancelled()
signal reward_claimed(item: ShopItemData, origin_global_pos: Vector2)
signal open_booster_requested(booster: BoosterData)

const ShopItemDataScript = preload("res://scripts/data/shop_item_data.gd")
const BoosterDataScript = preload("res://scripts/data/booster_data.gd")
const CandyCardDataScript = preload("res://scripts/data/candy_card_data.gd")

enum Mode { CONFIRMATION, REWARD }
var current_mode: Mode = Mode.CONFIRMATION

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var spiral_backdrop: ColorRect = $SpiralBackdrop
@onready var card_container: PanelContainer = $CardCenter/CardContainer
@onready var btn_close: Button = $CardCenter/CardContainer/BtnClose
@onready var ribbon_label: Label = $CardCenter/CardContainer/VBox/RibbonBanner/RibbonLabel
@onready var item_icon: TextureRect = $CardCenter/CardContainer/VBox/IconCenter/AuraAnchor/ItemIcon
@onready var aura_anchor: Control = $CardCenter/CardContainer/VBox/IconCenter/AuraAnchor
@onready var title_label: Label = $CardCenter/CardContainer/VBox/TitleLabel
@onready var desc_label: Label = $CardCenter/CardContainer/VBox/DescLabel
@onready var rewards_vbox: VBoxContainer = $CardCenter/CardContainer/VBox/RewardsVBox

# Panneau de Coût & Solde
@onready var cost_panel: PanelContainer = $CardCenter/CardContainer/VBox/CostPanel
@onready var price_label: Label = $CardCenter/CardContainer/VBox/CostPanel/CostVBox/PriceLabel
@onready var balance_label: Label = $CardCenter/CardContainer/VBox/CostPanel/CostVBox/BalanceLabel

# Boutons
@onready var buttons_container: VBoxContainer = $CardCenter/CardContainer/VBox/ButtonsContainer
@onready var confirm_buttons: HBoxContainer = $CardCenter/CardContainer/VBox/ButtonsContainer/ConfirmButtonsHBox
@onready var btn_cancel: Button = $CardCenter/CardContainer/VBox/ButtonsContainer/ConfirmButtonsHBox/BtnCancel
@onready var btn_confirm: Button = $CardCenter/CardContainer/VBox/ButtonsContainer/ConfirmButtonsHBox/BtnConfirm
@onready var btn_claim: Button = $CardCenter/CardContainer/VBox/ButtonsContainer/BtnClaim
@onready var booster_buttons: HBoxContainer = $CardCenter/CardContainer/VBox/ButtonsContainer/BoosterButtonsHBox
@onready var btn_open_booster: Button = $CardCenter/CardContainer/VBox/ButtonsContainer/BoosterButtonsHBox/BtnOpenBooster
@onready var btn_later: Button = $CardCenter/CardContainer/VBox/ButtonsContainer/BoosterButtonsHBox/BtnLater

var _current_item: ShopItemDataScript = null
var _use_diamonds: bool = false
var _has_booster: bool = false
var _gained_booster: BoosterDataScript = null
var _open_tween: Tween = null

func _ready() -> void:
	visible = false
	z_index = 100

	if btn_close != null:
		btn_close.pressed.connect(_on_cancel_pressed)
	if btn_cancel != null:
		btn_cancel.pressed.connect(_on_cancel_pressed)
	if btn_confirm != null:
		btn_confirm.pressed.connect(_on_confirm_pressed)
	if btn_claim != null:
		btn_claim.pressed.connect(_on_claim_pressed)
	if btn_open_booster != null:
		btn_open_booster.pressed.connect(_on_open_booster_pressed)
	if btn_later != null:
		btn_later.pressed.connect(_on_claim_pressed)

	if dark_overlay != null:
		dark_overlay.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if current_mode == Mode.CONFIRMATION:
					_on_cancel_pressed()
		)

## Ouvre la modale en mode CONFIRMATION (l'achat n'est pas encore effectué !)
func open_confirmation(
	item: ShopItemDataScript,
	use_diamonds: bool,
	player_gold: int,
	player_diamonds: int
) -> void:
	if item == null:
		return
	_current_item = item
	_use_diamonds = use_diamonds
	_has_booster = false
	_gained_booster = null
	current_mode = Mode.CONFIRMATION

	# 1. Bannière haute
	if ribbon_label != null:
		ribbon_label.text = "🎁 CADEAU GRATUIT" if item.is_free() else "🛒 CONFIRMER L'ACHAT"

	# 2. Titre et icône agrandie
	if title_label != null:
		title_label.text = item.display_name.to_upper()
	if desc_label != null:
		desc_label.text = item.description if not item.description.is_empty() else "Appuyez sur Confirmer pour valider cet achat."
	if item_icon != null:
		if item.icon_texture != null:
			item_icon.texture = item.icon_texture
		else:
			item_icon.texture = preload("res://assets/ui/icon_gold_stack.png")

	# 3. Liste des récompenses contenues
	_populate_rewards(item)

	# 4. Panneau de prix et impact sur le solde
	if cost_panel != null:
		cost_panel.visible = true
	if price_label != null and balance_label != null and btn_confirm != null:
		if item.is_free():
			price_label.text = "CADEAU OFFERT !"
			balance_label.text = "Gratuit — Aucun débit requis"
			btn_confirm.text = "🎁 RÉCUPÉRER"
		elif use_diamonds:
			var cost: int = item.diamond_price
			var rem: int = maxi(0, player_diamonds - cost)
			price_label.text = "PRIX : %d 💎" % cost
			balance_label.text = "Votre solde : %d 💎  ➔  %d 💎" % [player_diamonds, rem]
			btn_confirm.text = "CONFIRMER (%d 💎)" % cost
		else:
			var cost: int = item.gold_price
			var rem: int = maxi(0, player_gold - cost)
			price_label.text = "PRIX : %d 🪙" % cost
			balance_label.text = "Votre solde : %d 🪙  ➔  %d 🪙" % [player_gold, rem]
			btn_confirm.text = "CONFIRMER (%d 🪙)" % cost

	# 5. Visibilité des boutons
	if confirm_buttons != null:
		confirm_buttons.visible = true
	if btn_claim != null:
		btn_claim.visible = false
	if booster_buttons != null:
		booster_buttons.visible = false

	_animate_entrance()

## Bascule en mode CÉLÉBRATION après confirmation de l'achat
func show_reward_mode(item: ShopItemDataScript, is_free_gift: bool = false) -> void:
	if item == null:
		return
	_current_item = item
	current_mode = Mode.REWARD

	if ribbon_label != null:
		ribbon_label.text = "🎁 CADEAU RÉCUPÉRÉ !" if is_free_gift else "🎉 ACHAT EFFECTUÉ !"

	if cost_panel != null:
		cost_panel.visible = false
	if confirm_buttons != null:
		confirm_buttons.visible = false

	if _has_booster:
		if btn_claim != null:
			btn_claim.visible = false
		if booster_buttons != null:
			booster_buttons.visible = true
	else:
		if btn_claim != null:
			btn_claim.visible = true
		if booster_buttons != null:
			booster_buttons.visible = false

	# Petite impulsion punch de célébration sur la boîte
	if card_container != null:
		var punch: Tween = create_tween()
		punch.tween_property(card_container, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		punch.tween_property(card_container, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Ouvre directement en mode célébration (compatibilité)
func open(item: ShopItemDataScript, is_free_gift: bool = false) -> void:
	if item == null:
		return
	_current_item = item
	_has_booster = false
	_gained_booster = null
	current_mode = Mode.REWARD

	if ribbon_label != null:
		ribbon_label.text = "🎁 CADEAU RÉCUPÉRÉ !" if is_free_gift else "🎉 ACHAT EFFECTUÉ !"
	if title_label != null:
		title_label.text = item.display_name.to_upper()
	if desc_label != null:
		desc_label.text = item.description if not item.description.is_empty() else "Récompenses ajoutées à votre compte !"
	if item_icon != null:
		if item.icon_texture != null:
			item_icon.texture = item.icon_texture
		else:
			item_icon.texture = preload("res://assets/ui/icon_gold_stack.png")

	_populate_rewards(item)

	if cost_panel != null:
		cost_panel.visible = false
	if confirm_buttons != null:
		confirm_buttons.visible = false

	if _has_booster:
		if btn_claim != null:
			btn_claim.visible = false
		if booster_buttons != null:
			booster_buttons.visible = true
	else:
		if btn_claim != null:
			btn_claim.visible = true
		if booster_buttons != null:
			booster_buttons.visible = false

	_animate_entrance()

func _populate_rewards(item: ShopItemDataScript) -> void:
	if rewards_vbox == null:
		return

	for c in rewards_vbox.get_children():
		c.queue_free()

	var entries: Array[Dictionary] = item.get_reward_entries()
	if entries.is_empty():
		return

	for entry in entries:
		var r_type: String = entry.get("type", "")
		var r_title: String = ""
		var r_tex: Texture2D = null

		match r_type:
			"gold":
				var amount: int = entry.get("amount", 0)
				r_title = "+%d Pièces d'Or" % amount
				r_tex = preload("res://assets/ui/coin_gold_3d.png")
			"diamonds":
				var amount: int = entry.get("amount", 0)
				r_title = "+%d Diamants" % amount
				r_tex = preload("res://assets/ui/gem_diamond_3d.png")
			"booster":
				_has_booster = true
				var b_type: BoosterData.BoosterType = entry.get("booster_type", BoosterData.BoosterType.SILVER_POP)
				var b_name: String = entry.get("display_name", "Sachet de cartes")
				r_title = "🍬 %s (4 Cartes)" % b_name
				r_tex = item.icon_texture
				_gained_booster = BoosterData.new()
				_gained_booster.id = entry.get("id", &"booster_pack")
				_gained_booster.display_name = b_name
				_gained_booster.booster_type = b_type
			"cards":
				var card_count: int = entry.get("count", 1)
				var cid: StringName = entry.get("card_id", &"")
				r_title = "+%d Cartes %s" % [card_count, cid.capitalize()]
				r_tex = preload("res://assets/ui/icon_nav_cards.png")
			_:
				if entry.has("display_name"):
					r_title = entry["display_name"]
				r_tex = preload("res://assets/ui/icon_gold_stack.png")

		var row: PanelContainer = _create_reward_badge(r_title, r_tex)
		rewards_vbox.add_child(row)

func _create_reward_badge(text_val: String, tex: Texture2D) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.content_margin_left = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 8.0
	sb.bg_color = Color(0.98, 0.76, 0.22, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.68, 0.44, 0.08, 1)
	sb.set_corner_radius_all(14)
	pc.add_theme_stylebox_override("panel", sb)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)

	if tex != null:
		var tr: TextureRect = TextureRect.new()
		tr.custom_minimum_size = Vector2(36, 36)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = tex
		hb.add_child(tr)

	var lbl: Label = Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.24, 0.12, 0.02, 1))
	lbl.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.82, 1))
	lbl.add_theme_constant_override("outline_size", 2)
	hb.add_child(lbl)

	pc.add_child(hb)
	return pc

func _animate_entrance() -> void:
	visible = true
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()

	if dark_overlay != null:
		dark_overlay.modulate.a = 0.0
	if spiral_backdrop != null:
		spiral_backdrop.modulate.a = 0.0
	if card_container != null:
		card_container.scale = Vector2(0.3, 0.3)
		card_container.pivot_offset = card_container.size * 0.5
		card_container.modulate.a = 0.0
	if aura_anchor != null:
		aura_anchor.scale = Vector2.ZERO

	_open_tween = create_tween().set_parallel(true)
	if dark_overlay != null:
		_open_tween.tween_property(dark_overlay, "modulate:a", 1.0, 0.16)
	if spiral_backdrop != null:
		_open_tween.tween_property(spiral_backdrop, "modulate:a", 1.0, 0.22)
	if card_container != null:
		_open_tween.tween_property(card_container, "modulate:a", 1.0, 0.12)
		_open_tween.tween_property(card_container, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if aura_anchor != null:
		var icon_tw: Tween = create_tween()
		icon_tw.tween_interval(0.08)
		icon_tw.tween_property(aura_anchor, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_cancel_pressed() -> void:
	Input.vibrate_handheld(20)
	close()
	purchase_cancelled.emit()

func _on_confirm_pressed() -> void:
	var origin: Vector2 = item_icon.global_position + (item_icon.size * 0.5) if item_icon != null else get_viewport_rect().size * 0.5
	Input.vibrate_handheld(35)
	purchase_confirmed.emit(_current_item, _use_diamonds, origin)

func _on_claim_pressed() -> void:
	var origin: Vector2 = item_icon.global_position + (item_icon.size * 0.5) if item_icon != null else get_viewport_rect().size * 0.5
	Input.vibrate_handheld(30)
	close()
	reward_claimed.emit(_current_item, origin)

func _on_open_booster_pressed() -> void:
	var booster_to_open: BoosterDataScript = _gained_booster
	Input.vibrate_handheld(40)
	close()
	open_booster_requested.emit(booster_to_open)

func close() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()

	var tw: Tween = create_tween().set_parallel(true)
	if dark_overlay != null:
		tw.tween_property(dark_overlay, "modulate:a", 0.0, 0.15)
	if spiral_backdrop != null:
		tw.tween_property(spiral_backdrop, "modulate:a", 0.0, 0.12)
	if card_container != null:
		tw.tween_property(card_container, "scale", Vector2(0.7, 0.7), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(card_container, "modulate:a", 0.0, 0.14)

	await tw.finished
	visible = false
