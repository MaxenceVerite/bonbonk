class_name LeaderboardView
extends Control

## Vue interactive du Classement Mondial (Top 50 Survie) connectée à Supabase.
## Affiche les médailles (Top 3), les records de vagues & scores, ainsi que le rang du joueur.

signal play_survival_requested
signal open_account_requested

@onready var btn_refresh: Button = $VBox/HeaderCard/HeaderHBox/BtnRefresh
@onready var scroll_container: ScrollContainer = $VBox/ContentArea/ScrollContainer
@onready var rows_vbox: VBoxContainer = $VBox/ContentArea/ScrollContainer/RowsVBox

# Vues d'état
@onready var loading_box: VBoxContainer = $VBox/ContentArea/LoadingBox
@onready var offline_box: VBoxContainer = $VBox/ContentArea/OfflineBox
@onready var btn_connect: Button = $VBox/ContentArea/OfflineBox/BtnConnect
@onready var empty_box: VBoxContainer = $VBox/ContentArea/EmptyBox
@onready var btn_play_empty: Button = $VBox/ContentArea/EmptyBox/BtnPlayEmpty

# Bandeau fixe "Mon Rang" en bas
@onready var my_rank_banner: PanelContainer = $VBox/MyRankBanner
@onready var label_my_rank: Label = $VBox/MyRankBanner/HBox/LabelRank
@onready var label_my_name: Label = $VBox/MyRankBanner/HBox/LabelName
@onready var label_my_record: Label = $VBox/MyRankBanner/HBox/LabelRecord

var _is_fetching: bool = false
var _cached_leaderboard: Array = []

func _ready() -> void:
	if btn_refresh != null:
		btn_refresh.pressed.connect(fetch_leaderboard)
	if btn_connect != null:
		btn_connect.pressed.connect(func() -> void: open_account_requested.emit())
	if btn_play_empty != null:
		btn_play_empty.pressed.connect(func() -> void: play_survival_requested.emit())

	EventBus.cloud_sync_completed.connect(func(_ok: bool) -> void:
		if visible:
			fetch_leaderboard()
	)

func refresh() -> void:
	_update_my_rank_display()
	if _cached_leaderboard.is_empty():
		fetch_leaderboard()
	else:
		_render_leaderboard(_cached_leaderboard)

func fetch_leaderboard() -> void:
	if _is_fetching:
		return

	_is_fetching = true
	_show_state("loading")
	if btn_refresh != null:
		btn_refresh.disabled = true

	# Vérification connexion
	if SaveManager.cloud_sync == null or not SaveManager.cloud_sync.is_online():
		_is_fetching = false
		if btn_refresh != null:
			btn_refresh.disabled = false
		_show_state("offline")
		_update_my_rank_display()
		return

	var sb = SaveManager.cloud_sync.supabase_client
	if sb == null or not sb.is_configured():
		_is_fetching = false
		if btn_refresh != null:
			btn_refresh.disabled = false
		_show_state("offline")
		_update_my_rank_display()
		return

	var resp: Dictionary = await sb.fetch_leaderboard(50)
	_is_fetching = false
	if btn_refresh != null:
		btn_refresh.disabled = false

	if resp.get("success", false):
		var list = resp.get("data", [])
		if list is Array:
			_cached_leaderboard = list
			if list.is_empty():
				_show_state("empty")
			else:
				_show_state("ready")
				_render_leaderboard(list)
		else:
			_show_state("empty")
	else:
		if not _cached_leaderboard.is_empty():
			_show_state("ready")
			_render_leaderboard(_cached_leaderboard)
		else:
			_show_state("offline")

	_update_my_rank_display()

func _render_leaderboard(entries: Array) -> void:
	if rows_vbox == null:
		return

	for c in rows_vbox.get_children():
		c.queue_free()

	var my_uid: String = ""
	if SaveManager.current_profile != null:
		my_uid = SaveManager.current_profile.cloud_user_id

	var rank: int = 1
	var found_my_rank: int = -1

	for entry in entries:
		if entry is Dictionary:
			var u_id: String = str(entry.get("user_id", ""))
			var d_name: String = str(entry.get("display_name", "Gourmand"))
			var wave: int = int(entry.get("survival_best_wave", 0))
			var score: int = int(entry.get("survival_best_score", 0))

			var is_me: bool = (not my_uid.is_empty() and u_id == my_uid)
			if is_me and found_my_rank == -1:
				found_my_rank = rank

			var row: PanelContainer = _create_row_node(rank, d_name, wave, score, is_me)
			rows_vbox.add_child(row)
			rank += 1

	if found_my_rank != -1:
		label_my_rank.text = "#%d" % found_my_rank
	elif SaveManager.current_profile != null and SaveManager.current_profile.survival_best_score > 0:
		label_my_rank.text = "50+"
	else:
		label_my_rank.text = "—"

func _create_row_node(rank_num: int, player_name: String, wave: int, score: int, is_me: bool) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 64)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8

	# Couleurs selon le podium ou si c'est moi
	if is_me:
		sb.bg_color = Color(0.18, 0.45, 0.25, 0.95) # Surlignage vert joueur
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 5
		sb.border_color = Color(0.40, 0.90, 0.50, 1.0)
	elif rank_num == 1:
		sb.bg_color = Color(0.96, 0.78, 0.22, 0.95) # Or
		sb.border_width_bottom = 4
		sb.border_color = Color(0.72, 0.48, 0.08, 1.0)
	elif rank_num == 2:
		sb.bg_color = Color(0.85, 0.88, 0.92, 0.95) # Argent
		sb.border_width_bottom = 4
		sb.border_color = Color(0.55, 0.60, 0.68, 1.0)
	elif rank_num == 3:
		sb.bg_color = Color(0.88, 0.65, 0.45, 0.95) # Bronze
		sb.border_width_bottom = 4
		sb.border_color = Color(0.58, 0.35, 0.20, 1.0)
	else:
		# Ligne normale alternée
		if rank_num % 2 == 0:
			sb.bg_color = Color(0.96, 0.92, 0.86, 0.95)
		else:
			sb.bg_color = Color(0.92, 0.88, 0.82, 0.95)
		sb.border_width_bottom = 3
		sb.border_color = Color(0.75, 0.68, 0.60, 1.0)

	row.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Rang
	var lbl_rank: Label = Label.new()
	lbl_rank.custom_minimum_size = Vector2(48, 0)
	lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rank.add_theme_font_size_override("font_size", 22)

	if rank_num == 1:
		lbl_rank.text = "🥇 1"
		lbl_rank.add_theme_color_override("font_color", Color(0.35, 0.18, 0.02, 1))
	elif rank_num == 2:
		lbl_rank.text = "🥈 2"
		lbl_rank.add_theme_color_override("font_color", Color(0.25, 0.28, 0.35, 1))
	elif rank_num == 3:
		lbl_rank.text = "🥉 3"
		lbl_rank.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08, 1))
	else:
		lbl_rank.text = "#%d" % rank_num
		lbl_rank.add_theme_color_override("font_color", Color(0.40, 0.28, 0.18, 0.9) if not is_me else Color.WHITE)
	hbox.add_child(lbl_rank)

	# Pseudo Joueur
	var lbl_name: Label = Label.new()
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_name.text = player_name + ("  (Moi)" if is_me else "")
	lbl_name.add_theme_font_size_override("font_size", 20)
	lbl_name.add_theme_color_override("font_color", Color.WHITE if is_me else Color(0.28, 0.14, 0.06, 1))
	hbox.add_child(lbl_name)

	# Record Vague
	var lbl_wave: Label = Label.new()
	lbl_wave.text = "🌊 Vague %d" % wave
	lbl_wave.add_theme_font_size_override("font_size", 16)
	lbl_wave.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0) if is_me else Color(0.30, 0.25, 0.20, 0.85))
	hbox.add_child(lbl_wave)

	# Record Score
	var lbl_score: Label = Label.new()
	lbl_score.custom_minimum_size = Vector2(100, 0)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_score.text = "%s pts" % _format_number(score)
	lbl_score.add_theme_font_size_override("font_size", 18)
	lbl_score.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30) if is_me else Color(0.55, 0.25, 0.05, 1))
	hbox.add_child(lbl_score)

	return row

func _update_my_rank_display() -> void:
	if SaveManager.current_profile == null:
		return

	var prof = SaveManager.current_profile
	label_my_name.text = prof.display_name
	var wave: int = prof.survival_best_wave
	var score: int = prof.survival_best_score

	if score > 0 or wave > 0:
		label_my_record.text = "🌊 Vague %d  •  %s pts" % [wave, _format_number(score)]
	else:
		label_my_record.text = "Aucune partie de Survie jouée"
		label_my_rank.text = "—"

func _show_state(st: String) -> void:
	if loading_box != null: loading_box.visible = (st == "loading")
	if offline_box != null: offline_box.visible = (st == "offline")
	if empty_box != null: empty_box.visible = (st == "empty")
	if scroll_container != null: scroll_container.visible = (st == "ready")

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
