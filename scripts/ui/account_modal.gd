class_name AccountModal
extends Control

## Modale Profil & Options Joueur (Style Supercell / Bonbonk ID).
## Confort mobile-first, gros boutons tactiles (50-60px), réglages interactifs et connexion sans mot de passe (OTP 6 chiffres).

signal edit_name_requested

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var modal_card: PanelContainer = $CenterAnchor/ModalCard
@onready var btn_close: Button = $CenterAnchor/ModalCard/VBoxMain/HeaderContainer/BtnClose

# Vues principales
@onready var profile_view: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/ProfileView
@onready var auth_view: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/AuthView

# Section Identité
@onready var label_player_name: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxName/LabelPlayerName
@onready var btn_edit_name: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxName/BtnEditName
@onready var label_player_id: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxDetails/LabelPlayerId
@onready var btn_copy_id: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxDetails/BtnCopyId
@onready var label_copy_toast: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxDetails/LabelCopyToast
@onready var label_sync_status: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/IdentityCard/HBox/InfoVBox/HBoxDetails/LabelSyncStatus

# Section Sauvegarde Cloud
@onready var logged_view: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SaveCard/VBox/LoggedView
@onready var label_user_email: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SaveCard/VBox/LoggedView/LabelUserEmail
@onready var btn_sign_out: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SaveCard/VBox/LoggedView/BtnSignOut

@onready var guest_view: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SaveCard/VBox/GuestView
@onready var btn_open_auth: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SaveCard/VBox/GuestView/BtnOpenAuth

# Section Paramètres Audio / Haptiques
@onready var btn_toggle_music: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleMusic
@onready var badge_music: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleMusic/VBox/Badge

@onready var btn_toggle_sfx: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleSfx
@onready var badge_sfx: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleSfx/VBox/Badge

@onready var btn_toggle_vibrate: Button = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleVibrate
@onready var badge_vibrate: Label = $CenterAnchor/ModalCard/VBoxMain/ProfileView/SettingsCard/VBox/HBoxToggles/BtnToggleVibrate/VBox/Badge

# Sous-vue Bonbonk ID (Supercell OTP sans mot de passe)
@onready var btn_back_from_auth: Button = $CenterAnchor/ModalCard/VBoxMain/AuthView/HBoxTop/BtnBackFromAuth
@onready var step_email: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepEmail
@onready var edit_email: LineEdit = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepEmail/EditEmail
@onready var btn_send_otp: Button = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepEmail/BtnSendOtp

@onready var step_code: VBoxContainer = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode
@onready var label_sent_email: Label = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode/LabelSentEmail
@onready var edit_otp_code: LineEdit = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode/EditOtpCode
@onready var btn_verify_otp: Button = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode/BtnVerifyOtp
@onready var btn_change_email: Button = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode/HBoxResend/BtnChangeEmail
@onready var btn_resend_otp: Button = $CenterAnchor/ModalCard/VBoxMain/AuthView/StepCode/HBoxResend/BtnResendOtp

@onready var label_auth_msg: Label = $CenterAnchor/ModalCard/VBoxMain/AuthView/LabelAuthMsg

var _current_full_id: String = ""
var _pending_email: String = ""

func _ready() -> void:
	btn_close.pressed.connect(close)
	dark_overlay.gui_input.connect(_on_overlay_input)

	# Édition du nom -> ouvre la popup dédiée
	btn_edit_name.pressed.connect(func() -> void:
		edit_name_requested.emit()
	)

	# Copie de l'ID
	btn_copy_id.pressed.connect(_on_copy_id_pressed)

	# Bascule vers la vue de sauvegarde Bonbonk ID
	btn_open_auth.pressed.connect(func() -> void:
		_switch_to_auth_view(true)
	)
	btn_back_from_auth.pressed.connect(func() -> void:
		_switch_to_auth_view(false)
	)

	# Flux OTP sans mot de passe
	btn_send_otp.pressed.connect(_on_send_otp_pressed)
	edit_email.text_submitted.connect(func(_t: String) -> void: _on_send_otp_pressed())

	btn_verify_otp.pressed.connect(_on_verify_otp_pressed)
	edit_otp_code.text_submitted.connect(func(_t: String) -> void: _on_verify_otp_pressed())
	edit_otp_code.text_changed.connect(_on_otp_code_changed)

	btn_change_email.pressed.connect(_on_change_email_pressed)
	btn_resend_otp.pressed.connect(_on_resend_otp_pressed)

	btn_sign_out.pressed.connect(_on_sign_out_pressed)

	# Boutons de réglages (toggles tactiles)
	btn_toggle_music.pressed.connect(_on_toggle_music)
	btn_toggle_sfx.pressed.connect(_on_toggle_sfx)
	btn_toggle_vibrate.pressed.connect(_on_toggle_vibrate)

	EventBus.cloud_sync_completed.connect(func(_ok: bool) -> void: _refresh_ui())
	EventBus.profile_loaded.connect(func(_pid: String) -> void: _refresh_ui())

func open() -> void:
	visible = true
	_switch_to_auth_view(false)
	label_copy_toast.visible = false
	_refresh_ui()

	# Animation pop-in dynamique
	modulate.a = 0.0
	modal_card.scale = Vector2(0.9, 0.9)
	modal_card.pivot_offset = modal_card.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(modal_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_card, "scale", Vector2(0.9, 0.9), 0.15)
	await tween.finished
	visible = false

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_copy_id_pressed() -> void:
	if _current_full_id.is_empty():
		return
	DisplayServer.clipboard_set(_current_full_id)
	label_copy_toast.visible = true
	label_copy_toast.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(label_copy_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: label_copy_toast.visible = false)

func _switch_to_auth_view(is_auth: bool) -> void:
	profile_view.visible = not is_auth
	auth_view.visible = is_auth
	label_auth_msg.text = ""
	if is_auth:
		_switch_to_step(true)

func _switch_to_step(is_email_step: bool) -> void:
	step_email.visible = is_email_step
	step_code.visible = not is_email_step
	label_auth_msg.text = ""
	if is_email_step:
		edit_email.grab_focus()
	else:
		edit_otp_code.text = ""
		edit_otp_code.grab_focus()

func _refresh_ui() -> void:
	if SaveManager.current_profile == null:
		return

	var prof: RefCounted = SaveManager.current_profile

	# 1. Identité Joueur
	label_player_name.text = prof.display_name
	var uid: String = prof.cloud_user_id
	_current_full_id = uid if not uid.is_empty() else prof.profile_id
	if uid.is_empty():
		label_player_id.text = "#%s" % prof.profile_id.substr(0, 6).to_upper()
	else:
		label_player_id.text = "#%s" % uid.substr(0, 6).to_upper()

	if SaveManager.cloud_sync != null and SaveManager.cloud_sync.is_online():
		label_sync_status.text = "🟢 En ligne"
		label_sync_status.modulate = Color(0.2, 0.85, 0.3)
	else:
		label_sync_status.text = "⚪ Hors-ligne"
		label_sync_status.modulate = Color(0.65, 0.65, 0.65)

	# 2. Sauvegarde Cloud
	var is_logged: bool = false
	var user_email: String = ""
	if SaveManager.cloud_sync != null and SaveManager.cloud_sync.supabase_client != null:
		var sb = SaveManager.cloud_sync.supabase_client
		is_logged = sb.is_logged_in() and not sb.is_anonymous
		user_email = sb.user_email if not sb.user_email.is_empty() else ("UID: #" + sb.user_id.substr(0, 6).to_upper())

	if is_logged:
		logged_view.visible = true
		guest_view.visible = false
		label_user_email.text = "Compte lié : %s" % user_email
	else:
		logged_view.visible = false
		guest_view.visible = true

	# 3. Réglages Audio & Vibrations
	_refresh_settings_buttons()

func _refresh_settings_buttons() -> void:
	var music_on: bool = SaveManager.get_setting("music", true)
	var sfx_on: bool = SaveManager.get_setting("sfx", true)
	var vib_on: bool = SaveManager.get_setting("vibrate", true)

	_update_toggle_badge(badge_music, music_on)
	_update_toggle_badge(badge_sfx, sfx_on)
	_update_toggle_badge(badge_vibrate, vib_on)

func _update_toggle_badge(badge: Label, is_on: bool) -> void:
	if is_on:
		badge.text = "ACTIVÉ"
		badge.modulate = Color(0.18, 0.75, 0.25, 1.0)
	else:
		badge.text = "DÉSACTIVÉ"
		badge.modulate = Color(0.65, 0.50, 0.45, 1.0)

func _animate_toggle_tap(btn: Button) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_toggle_music() -> void:
	var current: bool = SaveManager.get_setting("music", true)
	SaveManager.set_setting("music", not current)
	_animate_toggle_tap(btn_toggle_music)
	_refresh_settings_buttons()

func _on_toggle_sfx() -> void:
	var current: bool = SaveManager.get_setting("sfx", true)
	SaveManager.set_setting("sfx", not current)
	_animate_toggle_tap(btn_toggle_sfx)
	_refresh_settings_buttons()

func _on_toggle_vibrate() -> void:
	var current: bool = SaveManager.get_setting("vibrate", true)
	var new_val: bool = not current
	SaveManager.set_setting("vibrate", new_val)
	_animate_toggle_tap(btn_toggle_vibrate)
	if new_val:
		SaveManager.vibrate(35)
	_refresh_settings_buttons()

# =============================================================================
# FLUX BONBONK ID (SUPERCELL OTP SANS MOT DE PASSE)
# =============================================================================

func _on_send_otp_pressed() -> void:
	var email: String = edit_email.text.strip_edges()
	print("AccountModal: Envoi OTP demandé pour email: '", email, "'")
	if not email.contains("@") or not email.contains("."):
		_set_auth_msg("Merci d'entrer une adresse email valide.", false)
		return

	_set_auth_msg("Envoi du code en cours...", true)
	btn_send_otp.disabled = true

	if SaveManager.cloud_sync == null or SaveManager.cloud_sync.supabase_client == null:
		push_error("AccountModal: cloud_sync ou supabase_client est null !")
		_set_auth_msg("Service cloud indisponible pour le moment.", false)
		btn_send_otp.disabled = false
		return

	var res: Dictionary = await SaveManager.cloud_sync.supabase_client.send_email_otp(email)
	btn_send_otp.disabled = false
	print("AccountModal: Retour send_email_otp -> ", res)

	if res.get("success", false):
		_pending_email = email
		label_sent_email.text = email
		_switch_to_step(false)
		_set_auth_msg("Code envoyé ! Vérifie ta boîte mail (et tes spams).", true)
	else:
		var err_str: String = res.get("error", "Impossible d'envoyer le code.")
		if err_str.contains("rate limit"):
			err_str = "Limite d'envoi atteinte sur le serveur. Réessaie dans quelques minutes."
		elif err_str.contains("invalid"):
			err_str = "Adresse email invalide ou domaine non reconnu."
		_set_auth_msg("Erreur : %s" % err_str, false)

func _on_verify_otp_pressed() -> void:
	var code: String = edit_otp_code.text.strip_edges()
	print("AccountModal: Validation OTP demandée avec code: '", code, "'")
	if code.length() < 6 or code.length() > 8:
		_set_auth_msg("Le code doit comporter entre 6 et 8 chiffres.", false)
		return

	_set_auth_msg("Validation du code en cours...", true)
	btn_verify_otp.disabled = true

	if SaveManager.cloud_sync == null or SaveManager.cloud_sync.supabase_client == null:
		_set_auth_msg("Service cloud indisponible.", false)
		btn_verify_otp.disabled = false
		return

	var res: Dictionary = await SaveManager.cloud_sync.supabase_client.verify_email_otp(_pending_email, code)
	btn_verify_otp.disabled = false

	if res.get("success", false):
		_set_auth_msg("Compte lié avec succès ! Synchronisation...", true)
		await get_tree().create_timer(0.6).timeout
		_switch_to_auth_view(false)
		SaveManager.cloud_sync.sync_now()
		_refresh_ui()
	else:
		_set_auth_msg("Code incorrect ou expiré. Réessaie.", false)

func _on_otp_code_changed(new_text: String) -> void:
	var stripped: String = new_text.strip_edges()
	# Auto-validation dès que le code atteint 8 chiffres (longueur maximale du champ)
	if stripped.length() == 8:
		_on_verify_otp_pressed()

func _on_change_email_pressed() -> void:
	_switch_to_step(true)

func _on_resend_otp_pressed() -> void:
	if _pending_email.is_empty():
		_switch_to_step(true)
		return
	_set_auth_msg("Renvoi du code en cours...", true)
	btn_resend_otp.disabled = true
	var res: Dictionary = await SaveManager.cloud_sync.supabase_client.send_email_otp(_pending_email)
	btn_resend_otp.disabled = false
	if res.get("success", false):
		_set_auth_msg("Un nouveau code a été envoyé !", true)
	else:
		_set_auth_msg("Erreur lors du renvoi du code.", false)

func _on_sign_out_pressed() -> void:
	if SaveManager.cloud_sync != null:
		SaveManager.cloud_sync.sign_out()
		SaveManager.cloud_sync.authenticate_anonymously()
		_refresh_ui()

func _set_auth_msg(msg: String, is_info: bool) -> void:
	label_auth_msg.text = msg
	if is_info:
		label_auth_msg.modulate = Color(0.2, 0.75, 0.3)
	else:
		label_auth_msg.modulate = Color(0.85, 0.2, 0.2)
