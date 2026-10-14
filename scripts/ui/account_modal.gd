class_name AccountModal
extends Control

## Modale de gestion de compte, synchronisation cloud et profil Sandbox.

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var btn_close: Button = $CenterAnchor/ModalCard/VBox/Header/BtnClose

# Profil & Nom
@onready var edit_player_name: LineEdit = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/ProfileSection/VBox/HBoxName/EditPlayerName
@onready var btn_save_name: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/ProfileSection/VBox/HBoxName/BtnSaveName
@onready var label_profile_id: Label = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/ProfileSection/VBox/LabelProfileId

# Synchronisation Cloud & Mode Réseau
@onready var label_sync_status: Label = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SyncSection/VBox/LabelSyncStatus
@onready var btn_sync_now: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SyncSection/VBox/BtnSyncNow
@onready var check_offline_mode: CheckButton = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SyncSection/VBox/CheckOfflineMode

# Sélecteur de profil
@onready var btn_profile_main: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/ProfilesSection/VBox/HBoxProfiles/BtnProfileMain
@onready var btn_profile_sandbox: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/ProfilesSection/VBox/HBoxProfiles/BtnProfileSandbox


# Section Outils Sandbox (Visible uniquement si Sandbox actif)
@onready var sandbox_card: PanelContainer = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SandboxSection
@onready var btn_sandbox_unlock_all: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SandboxSection/VBox/Grid/BtnUnlockAll
@onready var btn_sandbox_max_level: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SandboxSection/VBox/Grid/BtnMaxLevel
@onready var btn_sandbox_add_resources: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SandboxSection/VBox/Grid/BtnAddResources
@onready var btn_sandbox_reset: Button = $CenterAnchor/ModalCard/VBox/ContentScroll/SectionsVBox/SandboxSection/VBox/Grid/BtnResetSandbox

func _ready() -> void:
	btn_close.pressed.connect(close)
	dark_overlay.gui_input.connect(_on_overlay_input)

	btn_save_name.pressed.connect(_on_save_name_pressed)
	edit_player_name.text_submitted.connect(func(_t: String) -> void: _on_save_name_pressed())

	btn_sync_now.pressed.connect(_on_sync_now_pressed)
	check_offline_mode.toggled.connect(_on_offline_toggled)

	btn_profile_main.pressed.connect(func() -> void: _switch_to_profile("main"))
	btn_profile_sandbox.pressed.connect(func() -> void: _switch_to_profile("sandbox"))

	# Boutons Sandbox
	btn_sandbox_unlock_all.pressed.connect(_on_sandbox_unlock_all)
	btn_sandbox_max_level.pressed.connect(_on_sandbox_max_level)
	btn_sandbox_add_resources.pressed.connect(_on_sandbox_add_resources)
	btn_sandbox_reset.pressed.connect(_on_sandbox_reset)

	# Écoute des signaux EventBus
	EventBus.cloud_sync_status_changed.connect(_on_cloud_status_changed)
	EventBus.cloud_sync_completed.connect(func(_ok: bool) -> void: _refresh_ui())
	EventBus.profile_loaded.connect(func(_pid: String) -> void: _refresh_ui())

func open() -> void:
	visible = true
	_refresh_ui()

	# Animation pop-in
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	pivot_offset = size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.15)
	await tween.finished
	visible = false

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _refresh_ui() -> void:
	if SaveManager.current_profile == null:
		return

	var prof: RefCounted = SaveManager.current_profile
	edit_player_name.text = prof.display_name
	
	var is_sandbox: bool = SaveManager.is_sandbox_active()
	var type_str: String = "Profil Développeur" if is_sandbox else ("Compte Invité (Local)" if prof.cloud_user_id.is_empty() else "Compte Cloud Lié")
	label_profile_id.text = "Profil: %s • Type: %s" % [prof.profile_id.to_upper(), type_str]

	# Mise à jour de l'état du switch profil
	btn_profile_main.button_pressed = not is_sandbox
	btn_profile_sandbox.button_pressed = is_sandbox
	btn_profile_main.modulate = Color(1.0, 1.0, 1.0) if not is_sandbox else Color(0.7, 0.7, 0.7)
	btn_profile_sandbox.modulate = Color(1.0, 1.0, 1.0) if is_sandbox else Color(0.7, 0.7, 0.7)

	# Afficher ou masquer la section Sandbox
	sandbox_card.visible = is_sandbox

	# Statut réseau
	if SaveManager.cloud_sync != null:
		check_offline_mode.set_pressed_no_signal(not SaveManager.cloud_sync.is_online())
		if not SaveManager.cloud_sync.is_online():
			label_sync_status.text = "⚪ Mode Hors-ligne (Sauvegardes chiffrées en local)"
			btn_sync_now.disabled = true
		else:
			label_sync_status.text = "🟢 Connecté au Cloud (Synchronisation prête)"
			btn_sync_now.disabled = is_sandbox

func _on_save_name_pressed() -> void:
	var new_name: String = edit_player_name.text.strip_edges()
	if new_name.is_empty():
		return
	if SaveManager.current_profile != null:
		SaveManager.current_profile.display_name = new_name
		SaveManager.save_to_disk()
		_refresh_ui()

func _on_sync_now_pressed() -> void:
	if SaveManager.cloud_sync != null and SaveManager.cloud_sync.is_online():
		SaveManager.sync_cloud()

func _on_offline_toggled(is_offline_checked: bool) -> void:
	if SaveManager.cloud_sync != null:
		SaveManager.cloud_sync.set_network_online(not is_offline_checked)
		_refresh_ui()

func _switch_to_profile(profile_id: String) -> void:
	SaveManager.switch_profile(profile_id)
	_refresh_ui()

func _on_cloud_status_changed(status_str: String, message: String) -> void:
	match status_str:
		"SYNCING":
			label_sync_status.text = "⏳ " + message
			btn_sync_now.disabled = true
		"SUCCESS":
			label_sync_status.text = "🟢 " + message
			btn_sync_now.disabled = SaveManager.is_sandbox_active()
		"OFFLINE":
			label_sync_status.text = "⚪ " + message
			btn_sync_now.disabled = true
		"ERROR":
			label_sync_status.text = "🔴 " + message
			btn_sync_now.disabled = false

func _on_sandbox_unlock_all() -> void:
	SaveManager.sandbox_unlock_all()
	_refresh_ui()

func _on_sandbox_max_level() -> void:
	SaveManager.sandbox_set_all_max_level(5)
	_refresh_ui()

func _on_sandbox_add_resources() -> void:
	SaveManager.sandbox_add_resources(10000, 500)
	_refresh_ui()

func _on_sandbox_reset() -> void:
	SaveManager.sandbox_reset()
	_refresh_ui()
