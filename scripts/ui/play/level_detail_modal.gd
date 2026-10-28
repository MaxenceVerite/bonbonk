class_name LevelDetailModal
extends Control

## Modale de détail d'un niveau de la carte Saga.
## Affiche 3 grosses étoiles de jeu mobile 3D, le meilleur score et le bouton JOUER.

signal play_level_requested(level_data: LevelData)
signal closed

const LevelData = preload("res://scripts/data/level_data.gd")
const TEX_STAR_GOLD: Texture2D = preload("res://assets/ui/star_gold_3d.png")
const TEX_STAR_EMPTY: Texture2D = preload("res://assets/ui/star_empty_3d.png")

var current_level_data: LevelData = null

@onready var backdrop: Button = $Backdrop
@onready var panel_container: PanelContainer = $CenterContainer/PanelCard
@onready var title_label: Label = $CenterContainer/PanelCard/VBox/TitleBanner/TitleLabel


# Les 3 Grosses Étoiles Mobiles 3D
@onready var star_1_icon: TextureRect = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn1/StarIcon1
@onready var star_1_score: Label = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn1/ScoreLabel1

@onready var star_2_icon: TextureRect = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn2/StarIcon2
@onready var star_2_score: Label = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn2/ScoreLabel2

@onready var star_3_icon: TextureRect = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn3/StarIcon3
@onready var star_3_score: Label = $CenterContainer/PanelCard/VBox/StarsStage/StarsHBox/StarColumn3/ScoreLabel3

@onready var best_score_label: Label = $CenterContainer/PanelCard/VBox/BestScoreBanner/BestScoreLabel

@onready var btn_play: Button = $CenterContainer/PanelCard/VBox/BtnPlay
@onready var btn_close: Button = $CenterContainer/PanelCard/BtnClose

func _ready() -> void:
	visible = false
	if backdrop != null:
		backdrop.pressed.connect(close)
	if btn_close != null:
		btn_close.pressed.connect(close)
	if btn_play != null:
		btn_play.pressed.connect(_on_btn_play_pressed)

func open(level_data: LevelData) -> void:
	current_level_data = level_data
	if level_data == null:
		return

	var world_num: int = level_data.get_world_number()
	var lvl_info: Dictionary = SaveManager.get_campaign_level_info(world_num, level_data.level_number)
	var stars: int = int(lvl_info.get("stars", 0))
	var best_score: int = int(lvl_info.get("best_score", 0))

	var is_boss: bool = (level_data.level_number == 10)
	var boss_prefix: String = "👑 " if is_boss else ""
	if title_label != null:
		title_label.text = "%sNiveau %d : %s" % [boss_prefix, level_data.level_number, level_data.display_title]


	# Seuils d'étoiles
	var th: Array = level_data.star_thresholds
	var th1: int = th[0] if th.size() > 0 else 400
	var th2: int = th[1] if th.size() > 1 else 900
	var th3: int = th[2] if th.size() > 2 else 1500

	_setup_big_star(star_1_icon, star_1_score, th1, stars >= 1)
	_setup_big_star(star_2_icon, star_2_score, th2, stars >= 2)
	_setup_big_star(star_3_icon, star_3_score, th3, stars >= 3)

	# Meilleur score
	if best_score_label != null:
		if best_score > 0:
			best_score_label.text = "🏆 RECORD PERSONNEL : %s PTS" % _format_number(best_score)
			best_score_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
		else:
			best_score_label.text = "AUCUN RECORD • VISE LES 3 ÉTOILES !"
			best_score_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.72, 0.95))

	# Statut de déblocage multi-monde
	var is_world_unlocked: bool = SaveManager.is_campaign_world_unlocked(world_num)
	var is_unlocked: bool = SaveManager.is_campaign_level_unlocked(world_num, level_data.level_number)

	if btn_play != null:
		btn_play.disabled = not is_unlocked
		if is_unlocked:
			btn_play.text = "▶  JOUER"
		elif not is_world_unlocked:
			btn_play.text = "🔒 MONDE VERROUILLÉ"
		else:
			btn_play.text = "🔒 NIVEAU VERROUILLÉ"

	visible = true
	modulate.a = 0.0
	panel_container.scale = Vector2(0.88, 0.88)
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel_container, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_property(panel_container, "scale", Vector2(0.92, 0.92), 0.14)
	await tw.finished
	visible = false
	closed.emit()

func _setup_big_star(icon: TextureRect, score_lbl: Label, threshold_pts: int, is_achieved: bool) -> void:
	if score_lbl != null:
		score_lbl.text = "%s pts" % _format_number(threshold_pts)
		if is_achieved:
			score_lbl.add_theme_color_override("font_color", Color(0.72, 0.45, 0.05, 1.0))
		else:
			score_lbl.add_theme_color_override("font_color", Color(0.48, 0.38, 0.30, 0.85))

	if icon != null:
		icon.texture = TEX_STAR_GOLD if is_achieved else TEX_STAR_EMPTY
		icon.modulate = Color.WHITE

func _format_number(num: int) -> String:
	var s: String = str(num)
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = " " + res
	return res

func _on_btn_play_pressed() -> void:
	if current_level_data == null:
		return
	var world_num: int = current_level_data.get_world_number()
	var is_unlocked: bool = SaveManager.is_campaign_level_unlocked(world_num, current_level_data.level_number)

	if is_unlocked:
		visible = false
		play_level_requested.emit(current_level_data)
