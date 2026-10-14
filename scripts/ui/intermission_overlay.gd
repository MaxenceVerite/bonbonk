class_name IntermissionOverlay
extends Control

## Écran de transition et de temps mort entre les manches.
## Affiche le bilan de la manche franchie et le bouton 'Manche Suivante'.

signal next_wave_pressed

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var info_label: Label = $CenterContainer/Panel/VBox/InfoLabel
@onready var btn_next: Button = $CenterContainer/Panel/VBox/BtnNextWave

func _ready() -> void:
	btn_next.pressed.connect(func() -> void: next_wave_pressed.emit())

func show_intermission(completed_wave: int, next_wave_num: int, next_budget: int) -> void:
	title_label.text = "🎉 MANCHE %d RÉUSSIE !" % completed_wave
	info_label.text = "Prochaine Manche : %d\nMenace à venir : %d pts" % [next_wave_num, next_budget]
	visible = true
	
	# Animation pop-in gourmande
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_intermission() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(func() -> void: visible = false)
