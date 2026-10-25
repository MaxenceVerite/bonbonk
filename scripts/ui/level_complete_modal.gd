class_name LevelCompleteModal
extends Control

## Modale de fin de niveau (Campagne) :
## Affiche les étoiles obtenues (1 à 3), le score, et les récompenses débloquées.
## Boutons : "Niveau Suivant", "Rejouer", "Menu".

signal next_level_pressed
signal replay_pressed
signal return_to_menu_pressed

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/VBox/SubtitleLabel
@onready var stars_label: Label = $CenterContainer/Panel/VBox/StarsContainer/StarsLabel
@onready var score_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/ScoreVal
@onready var rewards_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/RewardsVal
@onready var btn_next: Button = $CenterContainer/Panel/VBox/BtnRow/BtnNext
@onready var btn_replay: Button = $CenterContainer/Panel/VBox/BtnRow/BtnReplay
@onready var btn_menu: Button = $CenterContainer/Panel/VBox/BtnRow/BtnMenu

func _ready() -> void:
	if btn_next != null:
		btn_next.pressed.connect(func() -> void:
			hide_modal()
			next_level_pressed.emit()
		)
	if btn_replay != null:
		btn_replay.pressed.connect(func() -> void:
			hide_modal()
			replay_pressed.emit()
		)
	if btn_menu != null:
		btn_menu.pressed.connect(func() -> void:
			hide_modal()
			return_to_menu_pressed.emit()
		)

func show_level_complete(data: Dictionary) -> void:
	var stars: int = clampi(int(data.get("stars", 1)), 1, 3)
	var score: int = int(data.get("score", 0))
	var gold: int = int(data.get("gold_earned", 0))
	var diamonds: int = int(data.get("diamonds_earned", 0))
	var lvl_title: String = str(data.get("level_title", "Niveau Terminé"))

	subtitle_label.text = lvl_title
	score_val_label.text = "%d" % score

	var stars_text: String = ""
	match stars:
		1: stars_text = "⭐ ☆ ☆"
		2: stars_text = "⭐ ⭐ ☆"
		3: stars_text = "⭐ ⭐ ⭐"
		_: stars_text = "⭐ ☆ ☆"
	stars_label.text = stars_text

	var rewards_parts: Array[String] = []
	if gold > 0:
		rewards_parts.append("+%d 🪙" % gold)
	if diamonds > 0:
		rewards_parts.append("+%d 💎" % diamonds)
	if data.get("is_first_clear", false) and data.get("booster_awarded", false):
		rewards_parts.append("🎁 Sachet Débloqué !")
	rewards_val_label.text = " ".join(rewards_parts) if not rewards_parts.is_empty() else "+50 🪙"

	visible = true

	# Animation pop-in gourmande
	pivot_offset = size * 0.5
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)

func hide_modal() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(func() -> void: visible = false)
