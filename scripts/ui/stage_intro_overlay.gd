class_name StageIntroOverlay
extends Control

## Overlay cinématographique d'introduction de partie (Campagne & Survie).
## - Écran 1 : Carte de mission stylisée attendant la validation du joueur ("TOUCHER POUR JOUER").
## - Écran 2 (100% automatique) :
##     "PRÊT ?" éclatant doré avec étoiles scintillantes
##     suivi du slam magistral "BONBONK !" avec onde de choc, confettis UI, flash et secousse !

signal intro_finished

const StageIntroFXCanvas = preload("res://scripts/ui/stage_intro_fx_canvas.gd")
const MIN_TAP_DELAY: float = 0.35 ## Délai minimum (sec) pour empêcher qu'un clic de menu ne valide l'écran

@onready var darkener: ColorRect = $Darkener
@onready var banner_card: PanelContainer = $CenterContainer/BannerCard
@onready var world_tag_label: Label = $CenterContainer/BannerCard/Margin/CardVBox/WorldTagLabel
@onready var title_label: Label = $CenterContainer/BannerCard/Margin/CardVBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/BannerCard/Margin/CardVBox/SubtitleLabel
@onready var stars_container: HBoxContainer = $CenterContainer/BannerCard/Margin/CardVBox/StarsContainer
@onready var tap_prompt_box: PanelContainer = $CenterContainer/BannerCard/Margin/CardVBox/PromptMargin/TapPromptBox

@onready var callout_container: CenterContainer = $CalloutContainer
@onready var ready_box: HBoxContainer = $CalloutContainer/ReadyBox
@onready var ready_label: Label = $CalloutContainer/ReadyBox/ReadyLabel
@onready var sparkle_left: TextureRect = $CalloutContainer/ReadyBox/SparkleLeft
@onready var sparkle_right: TextureRect = $CalloutContainer/ReadyBox/SparkleRight
@onready var bonbonk_label: Label = $CalloutContainer/BonbonkLabel

@onready var fx_canvas: StageIntroFXCanvas = $FXCanvas
@onready var flash_overlay: ColorRect = $FlashOverlay

var _is_running: bool = false
var _waiting_for_card_tap: bool = false
var _active_tween: Tween = null
var _pulse_tween: Tween = null
var _shake_tween: Tween = null
var _on_finished_callback: Callable = Callable()
var _has_triggered_bonbonk: bool = false
var _intro_start_time: float = 0.0

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS

func play_intro(info: Dictionary, on_finished_cb: Callable = Callable()) -> void:
	_on_finished_callback = on_finished_cb
	_is_running = true
	_waiting_for_card_tap = false
	_has_triggered_bonbonk = false
	_intro_start_time = Time.get_ticks_msec() / 1000.0
	visible = true
	modulate.a = 1.0

	# 1. Remplissage des données de mission
	var world_txt: String = str(info.get("world_title", "MONDE 1")).to_upper()
	var lvl_title: String = str(info.get("level_title", "NIVEAU 1"))
	var sub_txt: String = str(info.get("subtitle", ""))
	var mode: String = str(info.get("mode", "campaign"))

	world_tag_label.text = "★ %s ★" % world_txt
	title_label.text = lvl_title
	subtitle_label.text = sub_txt
	subtitle_label.visible = not sub_txt.is_empty()

	if mode == "campaign":
		stars_container.visible = true
	else:
		stars_container.visible = false

	# 2. Réinitialisation des états visuels
	darkener.color.a = 0.0
	flash_overlay.color.a = 0.0
	banner_card.visible = true
	banner_card.scale = Vector2(0.55, 0.55)
	banner_card.modulate.a = 0.0
	banner_card.pivot_offset = banner_card.size * 0.5
	callout_container.visible = false
	ready_box.visible = false
	bonbonk_label.visible = false
	tap_prompt_box.scale = Vector2.ONE
	tap_prompt_box.pivot_offset = tap_prompt_box.size * 0.5

	_stop_all_tweens()
	_active_tween = create_tween()

	# ÉTAPE 1 : Apparition dynamique et élastique de la Carte
	_active_tween.set_parallel(true)
	_active_tween.tween_property(darkener, "color:a", 0.52, 0.28)
	_active_tween.tween_property(banner_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(banner_card, "modulate:a", 1.0, 0.25)

	# Dès que la carte est posée, on attend le tap du joueur et on active le pulsation du bouton
	_active_tween.chain().tween_callback(func() -> void:
		_waiting_for_card_tap = true
		_start_button_pulse()
	)

func _start_button_pulse() -> void:
	if tap_prompt_box == null:
		return
	tap_prompt_box.pivot_offset = tap_prompt_box.size * 0.5
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(tap_prompt_box, "scale", Vector2(1.06, 1.06), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(tap_prompt_box, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_all_tweens() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		_shake_tween = null

func _proceed_from_card_to_ready() -> void:
	if not _is_running:
		return
	_waiting_for_card_tap = false
	_stop_all_tweens()

	# Petit retour haptique au toucher
	Input.vibrate_handheld(30)

	# Transition fluide de sortie de la carte vers "PRÊT ?"
	banner_card.pivot_offset = banner_card.size * 0.5
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(banner_card, "scale", Vector2(1.10, 0.12), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_property(banner_card, "modulate:a", 0.0, 0.16)

	_active_tween.chain().tween_callback(func() -> void:
		banner_card.visible = false
		_show_callout_ready()
	)

func _show_callout_ready() -> void:
	if not _is_running or _has_triggered_bonbonk:
		return

	callout_container.visible = true
	ready_box.visible = true
	bonbonk_label.visible = false

	ready_box.pivot_offset = ready_box.size * 0.5
	ready_box.scale = Vector2(0.35, 0.35)
	ready_box.modulate.a = 1.0

	sparkle_left.pivot_offset = sparkle_left.size * 0.5
	sparkle_right.pivot_offset = sparkle_right.size * 0.5
	sparkle_left.rotation = 0.0
	sparkle_right.rotation = 0.0

	_stop_all_tweens()
	_active_tween = create_tween()

	# Pop percutant "PRÊT ?"
	_active_tween.set_parallel(true)
	_active_tween.tween_property(ready_box, "scale", Vector2(1.18, 1.18), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(sparkle_left, "rotation", TAU, 0.65).set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(sparkle_right, "rotation", -TAU, 0.65).set_trans(Tween.TRANS_SINE)

	# Pulsation respiratoire de suspense
	_active_tween.chain().tween_property(ready_box, "scale", Vector2(1.0, 1.0), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Enchaînement automatique vers BONBONK !
	_active_tween.chain().tween_callback(func() -> void:
		# Transition rapide
		var trans_tw: Tween = create_tween()
		trans_tw.set_parallel(true)
		trans_tw.tween_property(ready_box, "scale", Vector2(1.25, 0.1), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		trans_tw.tween_property(ready_box, "modulate:a", 0.0, 0.10)
		trans_tw.chain().tween_callback(func() -> void:
			ready_box.visible = false
			_show_callout_bonbonk()
		)
	)

func _show_callout_bonbonk() -> void:
	if not _is_running:
		return
	_has_triggered_bonbonk = true

	callout_container.visible = true
	ready_box.visible = false
	bonbonk_label.visible = true
	bonbonk_label.modulate.a = 1.0

	# Positionnement du pivot au centre pour un slam rotatif percutant
	bonbonk_label.pivot_offset = bonbonk_label.size * 0.5
	bonbonk_label.scale = Vector2(2.4, 2.4)
	bonbonk_label.rotation = -0.10 # -6 degrés

	# 1. Éclat de 70 confettis 3D et onde de choc néon dans l'espace UI
	var center_pt: Vector2 = get_viewport_rect().size * 0.5
	if fx_canvas != null:
		fx_canvas.trigger_burst(center_pt)

	# 2. Flash d'impact à l'écran
	flash_overlay.color = Color(1.0, 0.95, 0.98, 0.45)
	var flash_tw: Tween = create_tween()
	flash_tw.tween_property(flash_overlay, "color:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Secousse dynamique d'impact
	_trigger_screen_shake()

	# 4. Vibration haptique percutante
	Input.vibrate_handheld(65)

	# 5. Animation d'écrasement élastique (Slam) de "BONBONK !"
	_stop_all_tweens()
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(bonbonk_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(bonbonk_label, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(darkener, "color:a", 0.0, 0.32)

	# Maintien fier de "BONBONK !" pendant que la bille et les bumpers s'animent
	_active_tween.chain().tween_interval(0.55)

	# Déclenchement du gameplay au moment où BONBONK est pleinement affirmé
	_active_tween.chain().tween_callback(func() -> void:
		intro_finished.emit()
		if _on_finished_callback.is_valid():
			_on_finished_callback.call()
	)

	# Disparition en fondu et zoom avant dynamique vers la caméra
	_active_tween.chain().set_parallel(true)
	_active_tween.tween_property(bonbonk_label, "scale", Vector2(1.4, 1.4), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(bonbonk_label, "modulate:a", 0.0, 0.24)
	_active_tween.tween_property(self, "modulate:a", 0.0, 0.24)

	_active_tween.chain().tween_callback(func() -> void:
		_is_running = false
		visible = false
	)

func _trigger_screen_shake() -> void:
	if callout_container == null:
		return
	var base_pos: Vector2 = callout_container.position
	_shake_tween = create_tween()
	for i in range(5):
		var decay: float = 1.0 - (float(i) / 5.0)
		var ox: float = randf_range(-10.0, 10.0) * decay
		var oy: float = randf_range(-8.0, 8.0) * decay
		_shake_tween.tween_property(callout_container, "position", base_pos + Vector2(ox, oy), 0.035)
	_shake_tween.tween_property(callout_container, "position", base_pos, 0.03)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return

	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		# Ne réagir QUE si on est en attente du tap sur la carte de mission
		if not _waiting_for_card_tap:
			return

		# Protection anti-clic parasite provenant du menu précédent
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _intro_start_time
		if elapsed < MIN_TAP_DELAY:
			return

		# Consommer l'événement immédiatement et passer à PRÊT ?
		_waiting_for_card_tap = false
		get_viewport().set_input_as_handled()
		_proceed_from_card_to_ready()

func _fast_forward_to_bonbonk() -> void:
	_waiting_for_card_tap = false
	_stop_all_tweens()
	banner_card.visible = false
	_show_callout_bonbonk()
