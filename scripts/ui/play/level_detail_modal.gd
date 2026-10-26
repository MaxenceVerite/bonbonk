class_name LevelDetailModal
extends Control

## Modale de détail d'un niveau de la carte Saga.
## Affiche les objectifs d'étoiles (haute lisibilité), les récompenses, la description et le bouton "JOUER".

signal play_level_requested(level_data: LevelData)
signal closed

const LevelData = preload("res://scripts/data/level_data.gd")

var current_level_data: LevelData = null

@onready var backdrop: Button = $Backdrop
@onready var panel_container: PanelContainer = $CenterContainer/PanelCard
@onready var title_label: Label = $CenterContainer/PanelCard/VBox/TitleBanner/TitleLabel
@onready var desc_label: Label = $CenterContainer/PanelCard/VBox/DescLabel
@onready var star_1_label: Label = $CenterContainer/PanelCard/VBox/StarsCard/VBox/StarsHBox/Goal1/Label
@onready var star_2_label: Label = $CenterContainer/PanelCard/VBox/StarsCard/VBox/StarsHBox/Goal2/Label
@onready var star_3_label: Label = $CenterContainer/PanelCard/VBox/StarsCard/VBox/StarsHBox/Goal3/Label
@onready var best_score_label: Label = $CenterContainer/PanelCard/VBox/StarsCard/VBox/BestScoreLabel
@onready var reward_gold_label: Label = $CenterContainer/PanelCard/VBox/RewardsCard/HBoxRewards/GoldReward/Label
@onready var reward_diamonds_label: Label = $CenterContainer/PanelCard/VBox/RewardsCard/HBoxRewards/DiamondReward/Label
@onready var reward_booster_box: Control = $CenterContainer/PanelCard/VBox/RewardsCard/HBoxRewards/BoosterReward
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

	# Récupère l'état sauvegardé du niveau
	var lvl_id_str: String = String(level_data.id)
	var lvl_info: Dictionary = SaveManager.campaign_levels_data.get(lvl_id_str, {})
	var stars: int = int(lvl_info.get("stars", 0))
	var best_score: int = int(lvl_info.get("best_score", 0))

	var is_boss: bool = (level_data.level_number == 10)
	var boss_prefix: String = "👑 " if is_boss else ""
	if title_label != null:
		title_label.text = "%sNIVEAU %d : %s" % [boss_prefix, level_data.level_number, level_data.display_title.to_upper()]
	if desc_label != null:
		desc_label.text = level_data.description

	# Étoiles & seuils
	var th: Array = level_data.star_thresholds
	var th1: int = th[0] if th.size() > 0 else 400
	var th2: int = th[1] if th.size() > 1 else 900
	var th3: int = th[2] if th.size() > 2 else 1500

	# Haute lisibilité : si l'étoile est obtenue, texte doré étincelant. Sinon, blanc/argent net bien contrasté !
	if star_1_label != null:
		if stars >= 1:
			star_1_label.text = "⭐ %d pts" % th1
			star_1_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		else:
			star_1_label.text = "☆ %d pts" % th1
			star_1_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))

	if star_2_label != null:
		if stars >= 2:
			star_2_label.text = "⭐⭐ %d pts" % th2
			star_2_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		else:
			star_2_label.text = "☆☆ %d pts" % th2
			star_2_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))

	if star_3_label != null:
		if stars >= 3:
			star_3_label.text = "⭐⭐⭐ %d pts" % th3
			star_3_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		else:
			star_3_label.text = "☆☆☆ %d pts" % th3
			star_3_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))

	if best_score_label != null:
		if best_score > 0:
			best_score_label.text = "🏆 MEILLEUR SCORE : %d PTS" % best_score
			best_score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		else:
			best_score_label.text = "AUCUN SCORE ENREGISTRÉ"
			best_score_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 0.95))

	# Récompenses
	if reward_gold_label != null:
		reward_gold_label.text = "+%d" % level_data.first_clear_gold
	if reward_diamonds_label != null:
		reward_diamonds_label.text = "+%d" % level_data.first_clear_diamonds
	if reward_booster_box != null:
		reward_booster_box.visible = (level_data.first_clear_booster_id != &"")

	# Statut de déblocage multi-monde
	var world_num: int = int(String(level_data.world_id).trim_prefix("world_"))
	var is_world_unlocked: bool = (world_num <= SaveManager.campaign_unlocked_world)
	var is_unlocked: bool = false

	if world_num < SaveManager.campaign_unlocked_world:
		is_unlocked = true
	elif world_num == SaveManager.campaign_unlocked_world:
		is_unlocked = (level_data.level_number <= SaveManager.campaign_unlocked_level)
	else:
		is_unlocked = false

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
	panel_container.scale = Vector2(0.9, 0.9)
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_property(panel_container, "scale", Vector2(0.92, 0.92), 0.14)
	await tw.finished
	visible = false
	closed.emit()

func _on_btn_play_pressed() -> void:
	if current_level_data == null:
		return
	var world_num: int = int(String(current_level_data.world_id).trim_prefix("world_"))
	var is_unlocked: bool = false
	if world_num < SaveManager.campaign_unlocked_world:
		is_unlocked = true
	elif world_num == SaveManager.campaign_unlocked_world:
		is_unlocked = (current_level_data.level_number <= SaveManager.campaign_unlocked_level)

	if is_unlocked:
		visible = false
		play_level_requested.emit(current_level_data)
