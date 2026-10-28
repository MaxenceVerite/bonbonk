class_name MegaSlamGauge
extends Control

## Jauge visuelle arcade pour le Mega Slam :
## - Positionnée entre/sous les deux batteurs
## - Affiche le pourcentage de recharge et le décompte en secondes
## - S'illumine en or/cyan et pulse avec fierté quand elle est PRÊTE
## - Rebondit et flash lors de l'activation

@onready var panel_bg: PanelContainer = $PanelBG
@onready var fill_bar: ColorRect = $PanelBG/FillClip/FillBar
@onready var fill_clip: Control = $PanelBG/FillClip
@onready var label_title: Label = $PanelBG/VBox/LabelTitle
@onready var label_hint: Label = $PanelBG/VBox/LabelHint

var _pulse_tween: Tween = null
var _is_currently_ready: bool = false
var _bar_max_width: float = 176.0

func _ready() -> void:
	EventBus.mega_slam_cooldown_updated.connect(_on_cooldown_updated)
	EventBus.mega_slam_activated.connect(_on_mega_slam_activated)
	_bar_max_width = size.x - 4.0 if size.x > 10.0 else 176.0
	_set_ready_state(true)

func _on_cooldown_updated(current: float, max_duration: float, is_ready: bool) -> void:
	if is_ready:
		if not _is_currently_ready:
			_set_ready_state(true)
		if fill_bar != null:
			fill_bar.size.x = _bar_max_width
	else:
		if _is_currently_ready:
			_set_ready_state(false)
		var progress: float = 1.0 - clampf(current / max_duration, 0.0, 1.0)
		if fill_bar != null:
			fill_bar.size.x = _bar_max_width * progress
		if label_title != null:
			label_title.text = "⏳ %0.1fs" % current

func _set_ready_state(ready: bool) -> void:
	_is_currently_ready = ready

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if ready:
		if label_title != null:
			label_title.text = "⚡ MEGA SLAM ⚡"
			label_title.modulate = Color(2.4, 2.0, 0.5, 1.0)
		if label_hint != null:
			label_hint.text = "2 POUCES ENSEMBLE"
			label_hint.modulate = Color(1.0, 0.95, 0.7, 0.9)
		if fill_bar != null:
			fill_bar.color = Color(1.0, 0.85, 0.25, 0.9)
			fill_bar.size.x = _bar_max_width

		# Animation de pulsation vivante
		pivot_offset = size * 0.5
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		scale = Vector2.ONE
		if label_hint != null:
			label_hint.text = "RECHARGE..."
			label_hint.modulate = Color(0.7, 0.85, 1.0, 0.6)
		if fill_bar != null:
			fill_bar.color = Color(0.25, 0.65, 1.0, 0.75)

func _on_mega_slam_activated() -> void:
	# Flash & rebond de décharge
	pivot_offset = size * 0.5
	var pop_tw: Tween = create_tween()
	pop_tw.tween_property(self, "scale", Vector2(1.22, 1.22), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
	_set_ready_state(false)
