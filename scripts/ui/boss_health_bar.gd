class_name BossHealthBar
extends Control

## Widget de barre de vie épique pour les Boss en haut de l'écran.
## Affiche l'icône de tête de mort [💀], le nom du boss et la jauge de vie rouge incandescente.
## S'active et se met à jour automatiquement via EventBus.

@onready var container: HBoxContainer = $CenterContainer/HBox
@onready var boss_name_label: Label = $CenterContainer/HBox/VBox/BossNameLabel
@onready var hp_bar: ProgressBar = $CenterContainer/HBox/VBox/HPBar
@onready var hp_text_label: Label = $CenterContainer/HBox/VBox/HPBar/HPTextLabel
@onready var skull_icon: Label = $CenterContainer/HBox/SkullLabel
@onready var shield_overlay: Panel = $CenterContainer/HBox/VBox/HPBar/GoldenShieldOverlay

var _current_max_hp: int = 200
var _target_hp: float = 200.0
var _anim_tween: Tween = null
var _shield_tween: Tween = null

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_invulnerability_changed.connect(_on_boss_invulnerability_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_spawned(boss_name: String, max_hp: int) -> void:
	_current_max_hp = max_hp
	_target_hp = float(max_hp)
	boss_name_label.text = boss_name.to_upper()
	hp_bar.max_value = float(max_hp)
	hp_bar.value = float(max_hp)
	hp_text_label.text = "%d / %d" % [max_hp, max_hp]

	visible = true
	position.y = -60.0
	modulate.a = 0.0

	# Animation d'entrée dramatique
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(self, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Battement du crâne
	var skull_tw: Tween = skull_icon.create_tween()
	skull_tw.tween_property(skull_icon, "scale", Vector2(1.35, 1.35), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	skull_tw.tween_property(skull_icon, "scale", Vector2.ONE, 0.2)

func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	if not visible:
		visible = true
		modulate.a = 1.0

	_current_max_hp = max_hp
	_target_hp = float(current_hp)
	hp_bar.max_value = float(max_hp)
	hp_text_label.text = "%d / %d" % [current_hp, max_hp]

	# Animation fluide de la jauge rouge
	var bar_tw: Tween = create_tween()
	bar_tw.tween_property(hp_bar, "value", _target_hp, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Secousse légère de la tête de mort sur dégât
	var sk_tw: Tween = skull_icon.create_tween()
	sk_tw.tween_property(skull_icon, "position:x", skull_icon.position.x + 3.0, 0.04)
	sk_tw.tween_property(skull_icon, "position:x", skull_icon.position.x - 3.0, 0.04)
	sk_tw.tween_property(skull_icon, "position:x", skull_icon.position.x, 0.04)

func _on_boss_invulnerability_changed(is_invulnerable: bool) -> void:
	if shield_overlay == null:
		return

	if _shield_tween != null and _shield_tween.is_valid():
		_shield_tween.kill()

	if is_invulnerable:
		shield_overlay.visible = true
		shield_overlay.modulate.a = 0.0
		shield_overlay.scale = Vector2(1.05, 1.25)
		shield_overlay.pivot_offset = shield_overlay.size * 0.5

		_shield_tween = create_tween()
		_shield_tween.set_parallel(true)
		_shield_tween.tween_property(shield_overlay, "modulate:a", 1.0, 0.25)
		_shield_tween.tween_property(shield_overlay, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# Pulsation continue dorée
		_shield_tween.chain().tween_property(shield_overlay, "modulate:a", 0.75, 0.6).set_trans(Tween.TRANS_SINE)
		_shield_tween.tween_property(shield_overlay, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		_shield_tween.set_loops()
	else:
		if shield_overlay.visible:
			# Explosion / bris de la coque dorée
			_shield_tween = create_tween()
			_shield_tween.set_parallel(true)
			_shield_tween.tween_property(shield_overlay, "scale", Vector2(1.15, 1.4), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_shield_tween.tween_property(shield_overlay, "modulate:a", 0.0, 0.22)
			_shield_tween.chain().tween_callback(func() -> void:
				shield_overlay.visible = false
				shield_overlay.scale = Vector2.ONE
			)

func _on_boss_defeated(_boss_name: String) -> void:
	if shield_overlay != null:
		shield_overlay.visible = false
	# Animation triomphale de disparition
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(self, "position:y", -70.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_anim_tween.chain().tween_callback(func() -> void: visible = false)
