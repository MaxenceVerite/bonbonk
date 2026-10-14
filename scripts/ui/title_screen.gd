class_name TitleScreen
extends Control

## Écran d'accueil avec illustration plein écran et texte clignotant "Appuyer pour jouer".

signal screen_tapped

@onready var prompt_panel: Control = $VBoxContainer/PromptPanel
@onready var logo: TextureRect = $Logo

var _time: float = 0.0
var _logo_base_y: float = 0.0
var _logo_intro_done: bool = false

func _ready() -> void:
	if logo != null:
		_logo_base_y = logo.position.y
		# Pop d'entrée élastique
		logo.scale = Vector2(0.4, 0.4)
		logo.modulate.a = 0.0
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(logo, "modulate:a", 1.0, 0.3)
		tw.chain().tween_callback(func() -> void: _logo_intro_done = true)

func _process(delta: float) -> void:
	_time += delta
	# Pulsation douce du badge d'invite
	if prompt_panel != null:
		prompt_panel.modulate.a = 0.6 + 0.4 * (0.5 + 0.5 * sin(_time * 4.0))
	# Flottement + respiration légère du logo
	if logo != null and _logo_intro_done:
		logo.position.y = _logo_base_y + sin(_time * 1.8) * 8.0
		var s: float = 1.0 + 0.02 * sin(_time * 2.4)
		logo.scale = Vector2(s, s)
		logo.rotation = sin(_time * 1.2) * 0.015

var _is_tapped: bool = false

func _gui_input(event: InputEvent) -> void:
	if _is_tapped:
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_on_tap()

func _unhandled_input(event: InputEvent) -> void:
	if _is_tapped:
		return
	# N'accepte que la barre d'espace ou Entrée explicite au clavier
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_tap()

func _on_tap() -> void:
	if _is_tapped:
		return
	_is_tapped = true
	screen_tapped.emit()
	# Transition animée
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
	)

