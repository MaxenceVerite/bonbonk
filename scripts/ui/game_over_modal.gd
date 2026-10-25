class_name GameOverModal
extends Control

## Modal de fin de partie :
## Affiche un résumé complet (Score, Manches survécues, Or gagné, Nouveau record)
## Boutons : "Rejouer" et "Menu Principal".

signal replay_pressed
signal return_to_menu_pressed

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var record_badge: PanelContainer = $CenterContainer/Panel/VBox/RecordBadge
@onready var record_label: Label = $CenterContainer/Panel/VBox/RecordBadge/RecordLabel

@onready var waves_title_label: Label = $CenterContainer/Panel/VBox/StatsGrid/WavesBox/VBox/Lbl
@onready var best_title_label: Label = $CenterContainer/Panel/VBox/StatsGrid/BestBox/VBox/Lbl
@onready var score_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/ScoreVal
@onready var waves_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/WavesVal
@onready var gold_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/GoldVal
@onready var best_val_label: Label = $CenterContainer/Panel/VBox/StatsGrid/BestVal

@onready var btn_replay: Button = $CenterContainer/Panel/VBox/BtnRow/BtnReplay
@onready var btn_menu: Button = $CenterContainer/Panel/VBox/BtnRow/BtnMenu

func _ready() -> void:
	if btn_replay != null:
		btn_replay.pressed.connect(func() -> void: replay_pressed.emit())
	if btn_menu != null:
		btn_menu.pressed.connect(func() -> void: return_to_menu_pressed.emit())

func show_game_over(data: Dictionary) -> void:
	var mode: String = data.get("mode", "survival")
	var is_campaign: bool = (mode == "campaign")
	var final_score: int = data.get("final_score", 0)
	var waves_cleared: int = data.get("waves_cleared", 0)
	var gold_earned: int = data.get("gold_earned", 0)
	var is_new_record: bool = data.get("is_new_record", false)
	var best_score: int = data.get("best_score", final_score)

	if is_campaign:
		title_label.text = "💔 DÉFAITE 💔"
		if waves_title_label != null:
			waves_title_label.text = "VAGUE ATTEINTE"
		waves_val_label.text = str(data.get("subwave_text", "1 / 1"))
		if best_title_label != null:
			best_title_label.text = "RECORD NIVEAU"
		if btn_replay != null:
			btn_replay.text = "🔄 RÉESSAYER LE NIVEAU"
	else:
		title_label.text = "💥 FIN DE PARTIE 💥"
		if waves_title_label != null:
			waves_title_label.text = "MANCHES"
		waves_val_label.text = "%d" % waves_cleared
		if best_title_label != null:
			best_title_label.text = "MEILLEUR"
		if btn_replay != null:
			btn_replay.text = "🔄 REJOUER LA SURVIE"

	score_val_label.text = "%d" % final_score
	gold_val_label.text = "+%d 🪙" % gold_earned
	best_val_label.text = "%d" % best_score

	if record_badge != null:
		record_badge.visible = is_new_record

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
