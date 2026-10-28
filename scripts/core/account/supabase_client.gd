class_name SupabaseClient
extends Node

## Client REST natif Supabase pour Godot 4.
## Gère l'authentification anonyme (Guest), la session JWT chiffrée,
## la synchronisation du profil et le journal inviolable des transactions (IAP).

const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")

signal auth_state_changed(is_authenticated: bool, user_id: String)
signal sync_error(error_message: String)

const CONFIG_PATH: String = "res://config/supabase_config.json"
const SESSION_FILE_PATH: String = "user://supabase_session.enc"

var supabase_url: String = ""
var supabase_anon_key: String = ""
var custom_schema: String = "bonbonk"
var request_timeout: float = 8.0
var max_retries: int = 3
var is_enabled: bool = true

# État de la session active
var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var user_email: String = ""
var is_anonymous: bool = true

func _ready() -> void:
	load_config()
	load_cached_session()

## Charge la configuration depuis le fichier JSON externe
func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("SupabaseClient: Fichier de config introuvable: %s" % CONFIG_PATH)
		return
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	var json: JSON = JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var cfg: Dictionary = json.data as Dictionary
		var raw_url: String = str(cfg.get("supabase_url", "")).strip_edges().trim_suffix("/")
		if raw_url.ends_with("/rest/v1"):
			raw_url = raw_url.trim_suffix("/rest/v1").trim_suffix("/")
		supabase_url = raw_url
		supabase_anon_key = str(cfg.get("supabase_anon_key", "")).strip_edges()
		custom_schema = str(cfg.get("schema", "bonbonk")).strip_edges()
		request_timeout = float(cfg.get("request_timeout_seconds", 8.0))
		max_retries = int(cfg.get("max_retry_attempts", 3))
		is_enabled = bool(cfg.get("enable_cloud_sync", true))

## Vérifie si la configuration est prête et valide (non placeholder)
func is_configured() -> bool:
	return is_enabled and not supabase_url.is_empty() and not supabase_anon_key.is_empty() and not supabase_url.contains("your-project-id")

func is_logged_in() -> bool:
	return not access_token.is_empty() and not user_id.is_empty()

## Sauvegarde sécurisée de la session chiffrée en AES local
func save_session() -> void:
	var session_data: Dictionary = {
		"access_token": access_token,
		"refresh_token": refresh_token,
		"user_id": user_id,
		"user_email": user_email,
		"is_anonymous": is_anonymous,
		"saved_at": int(Time.get_unix_time_from_system())
	}
	SaveCipher.save_encrypted_json(SESSION_FILE_PATH, session_data)

## Chargement de la session chiffrée existante
func load_cached_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE_PATH):
		return
	var data: Dictionary = SaveCipher.load_encrypted_json(SESSION_FILE_PATH)
	if not data.is_empty():
		access_token = str(data.get("access_token", ""))
		refresh_token = str(data.get("refresh_token", ""))
		user_id = str(data.get("user_id", ""))
		user_email = str(data.get("user_email", ""))
		is_anonymous = bool(data.get("is_anonymous", true))
		if is_logged_in():
			auth_state_changed.emit(true, user_id)

func clear_session() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	user_email = ""
	is_anonymous = true
	if FileAccess.file_exists(SESSION_FILE_PATH):
		DirAccess.remove_absolute(SESSION_FILE_PATH)
	auth_state_changed.emit(false, "")

## Déconnexion propre de la session active (révocation serveur + nettoyage local)
func sign_out() -> void:
	if is_logged_in():
		# Notifier le serveur Supabase de la révocation du token de session
		_perform_request("/auth/v1/logout", HTTPClient.METHOD_POST, "", true)
	clear_session()

## Rafraîchit automatiquement le token JWT expiré
func refresh_session() -> Dictionary:
	if not is_configured() or refresh_token.is_empty():
		return { "success": false, "error": "Pas de refresh token" }
	print("SupabaseClient: Tentative de rafraîchissement du token JWT...")
	var body: String = JSON.stringify({
		"refresh_token": refresh_token
	})
	var resp: Dictionary = await _perform_request("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST, body, false)
	if resp.get("success", false):
		print("SupabaseClient: Token JWT rafraîchi avec succès !")
		_handle_auth_success(resp.get("data", {}), is_anonymous)
		return { "success": true, "user_id": user_id }
	else:
		push_warning("SupabaseClient: Échec du rafraîchissement JWT -> Nettoyage session")
		clear_session()
		return resp

# =============================================================================
# AUTHENTIFICATION MOBILE (SEAMLESS GUEST & ACCOUNT LINKING)
# =============================================================================

## Connexion invité transparente (utilise ou crée un compte anonyme Supabase)
func sign_in_anonymously(display_name: String = "Gourmand") -> Dictionary:
	if not is_configured():
		return { "success": false, "error": "Supabase non configuré" }

	if is_logged_in():
		return { "success": true, "user_id": user_id, "resumed": true }

	# Format officiel Supabase Auth Anonymous (zéro email, zéro mot de passe, instantané)
	var anon_body: String = JSON.stringify({
		"data": { "display_name": display_name, "is_guest": true }
	})
	var anon_resp: Dictionary = await _perform_request("/auth/v1/signup", HTTPClient.METHOD_POST, anon_body, false)
	if anon_resp.get("success", false):
		_handle_auth_success(anon_resp.get("data", {}), true)
		return { "success": true, "user_id": user_id, "action": "signup" }

	# Diagnostic clair si le toggle "Anonymous Sign-ins" n'est pas encore activé dans Supabase
	var err: String = anon_resp.get("error", "Échec d'inscription anonyme")
	if err.contains("Anonymous sign-ins are disabled"):
		push_warning("SupabaseClient: Activez 'Anonymous Sign-ins' dans votre dashboard Supabase -> Authentication -> Providers.")
	return { "success": false, "error": err }

## Connexion avec Email et Mot de passe (pour compte Joueur ou Admin)
func sign_in_with_password(email: String, password: String) -> Dictionary:
	if not is_configured():
		return { "success": false, "error": "Supabase non configuré" }
	var body: String = JSON.stringify({
		"email": email,
		"password": password
	})
	var resp: Dictionary = await _perform_request("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST, body, false)
	if resp.get("success", false):
		_handle_auth_success(resp.get("data", {}), false)
		return { "success": true, "user_id": user_id }
	return resp

## Inscription avec Email et Mot de passe
func sign_up_with_password(email: String, password: String, display_name: String = "Gourmand") -> Dictionary:
	if not is_configured():
		return { "success": false, "error": "Supabase non configuré" }
	var body: String = JSON.stringify({
		"email": email,
		"password": password,
		"data": { "display_name": display_name, "is_guest": false }
	})
	var resp: Dictionary = await _perform_request("/auth/v1/signup", HTTPClient.METHOD_POST, body, false)
	if resp.get("success", false):
		_handle_auth_success(resp.get("data", {}), false)
		return { "success": true, "user_id": user_id }
	return resp

## Envoi d'un Code OTP par Email (Style Supercell ID sans mot de passe)
func send_email_otp(email: String) -> Dictionary:
	print("SupabaseClient: Envoi demande OTP pour : '", email, "'")
	if not is_configured():
		push_error("SupabaseClient: Supabase non configuré !")
		return { "success": false, "error": "Supabase non configuré" }
	var body: String = JSON.stringify({
		"email": email,
		"create_user": true
	})
	var resp: Dictionary = await _perform_request("/auth/v1/otp", HTTPClient.METHOD_POST, body, false)
	print("SupabaseClient: Résultat envoi OTP -> ", resp)
	return resp

## Vérification du code OTP saisi par le joueur
func verify_email_otp(email: String, token_code: String) -> Dictionary:
	print("SupabaseClient: Vérification code OTP pour : '", email, "' (code: '", token_code, "')")
	if not is_configured():
		push_error("SupabaseClient: Supabase non configuré !")
		return { "success": false, "error": "Supabase non configuré" }
	var body: String = JSON.stringify({
		"email": email,
		"token": token_code,
		"type": "email"
	})
	var resp: Dictionary = await _perform_request("/auth/v1/verify", HTTPClient.METHOD_POST, body, false)
	print("SupabaseClient: Résultat vérification OTP -> ", resp)
	if resp.get("success", false):
		_handle_auth_success(resp.get("data", {}), false)
		return { "success": true, "user_id": user_id }
	return resp

func _handle_auth_success(data: Dictionary, anonymous: bool) -> void:
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	var user_data: Dictionary = data.get("user", {})
	user_id = str(user_data.get("id", ""))
	user_email = str(user_data.get("email", ""))
	is_anonymous = anonymous
	save_session()
	auth_state_changed.emit(true, user_id)

# =============================================================================
# SYNCHRONISATION DU PROFIL (CLOUD SAVE)
# =============================================================================

## Récupère le profil distant depuis la table player_profiles
func fetch_profile() -> Dictionary:
	if not is_configured() or not is_logged_in():
		return { "success": false, "error": "Non authentifié" }

	var endpoint: String = "/rest/v1/player_profiles?id=eq.%s&select=*" % user_id
	var resp: Dictionary = await _perform_request(endpoint, HTTPClient.METHOD_GET, "", true)
	if resp.get("success", false):
		var arr = resp.get("data", [])
		if arr is Array and arr.size() > 0:
			return { "success": true, "profile": arr[0] }
		else:
			return { "success": true, "profile": {} }
	return resp

## Téléverse le profil vers Supabase (avec fusion / upsert sécurisé par RLS)
func upsert_profile(profile_dict: Dictionary) -> Dictionary:
	if not is_configured() or not is_logged_in():
		return { "success": false, "error": "Non authentifié" }

	var payload: Dictionary = {
		"id": user_id,
		"display_name": str(profile_dict.get("display_name", "Gourmand")),
		"gold": int(profile_dict.get("gold", 0)),
		"diamonds": int(profile_dict.get("diamonds", 0)),
		"campaign_unlocked_world": int(profile_dict.get("campaign_unlocked_world", 1)),
		"campaign_unlocked_level": int(profile_dict.get("campaign_unlocked_level", 1)),
		"survival_best_wave": int(profile_dict.get("survival_best_wave", 0)),
		"survival_best_score": int(profile_dict.get("survival_best_score", 0)),
		"data": profile_dict.get("data", {}),
		"sync_revision": int(profile_dict.get("sync_revision", 1)),
		"updated_at": Time.get_datetime_string_from_system(true, true)
	}

	var custom_headers: Array[String] = [
		"Prefer: resolution=merge-duplicates,return=representation"
	]
	var body: String = JSON.stringify(payload)
	return await _perform_request("/rest/v1/player_profiles?on_conflict=id", HTTPClient.METHOD_POST, body, true, custom_headers)

# =============================================================================
# JOURNAL FINANCIER INVIOLABLE (PURCHASES LEDGER)
# =============================================================================

## Enregistre de manière idempotente et garantie un achat in-app
func record_purchase(tx: Dictionary) -> Dictionary:
	if not is_configured() or not is_logged_in():
		return { "success": false, "error": "Non authentifié" }

	var payload: Dictionary = {
		"tx_id": str(tx.get("tx_id", "")),
		"user_id": user_id,
		"product_id": str(tx.get("product_id", "")),
		"amount_paid": float(tx.get("amount_paid", 0.0)),
		"currency": str(tx.get("currency", "EUR")),
		"granted_diamonds": int(tx.get("granted_diamonds", 0)),
		"granted_gold": int(tx.get("granted_gold", 0)),
		"granted_items": tx.get("granted_items", {}),
		"platform": str(tx.get("platform", "sandbox")),
		"receipt_data": str(tx.get("receipt_data", "")),
		"status": "completed"
	}

	var custom_headers: Array[String] = [
		"Prefer: resolution=ignore-duplicates"
	]
	var body: String = JSON.stringify(payload)
	return await _perform_request("/rest/v1/purchases_ledger?on_conflict=tx_id", HTTPClient.METHOD_POST, body, true, custom_headers)

# =============================================================================
# CLASSEMENTS PUBLICS (LEADERBOARD)
# =============================================================================

## Récupère le classement mondial du mode Survie
func fetch_leaderboard(limit: int = 50) -> Dictionary:
	if not is_configured():
		return { "success": false, "error": "Supabase non configuré" }

	# 1. Tentative directe via la vue publique
	var endpoint: String = "/rest/v1/leaderboard_survival?limit=%d" % limit
	var resp: Dictionary = await _perform_request(endpoint, HTTPClient.METHOD_GET, "", true)
	if resp.get("success", false):
		return resp

	# 2. Fallback via la fonction RPC Security Definer
	var rpc_body: String = JSON.stringify({ "limit_count": limit })
	return await _perform_request("/rest/v1/rpc/get_survival_leaderboard", HTTPClient.METHOD_POST, rpc_body, true)

# =============================================================================
# MOTEUR HTTP INTERNE ROBUSTE
# =============================================================================

func _perform_request(path: String, method: HTTPClient.Method, body: String, use_auth: bool, extra_headers: Array[String] = []) -> Dictionary:
	if supabase_url.is_empty():
		return { "success": false, "error": "URL Supabase non définie" }

	var http: HTTPRequest = HTTPRequest.new()
	http.timeout = request_timeout
	if is_inside_tree():
		add_child(http)
	elif Engine.get_main_loop() is SceneTree and (Engine.get_main_loop() as SceneTree).root != null:
		(Engine.get_main_loop() as SceneTree).root.add_child(http)
	else:
		add_child(http)

	var headers: Array[String] = [
		"Content-Type: application/json",
		"apikey: %s" % supabase_anon_key
	]
	if use_auth and not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)
	if not custom_schema.is_empty() and custom_schema != "public" and path.begins_with("/rest/v1"):
		headers.append("Accept-Profile: %s" % custom_schema)
		headers.append("Content-Profile: %s" % custom_schema)
	for eh in extra_headers:
		headers.append(eh)

	var full_url: String = supabase_url + path
	var err: Error = http.request(full_url, headers, method, body)
	if err != OK:
		push_error("SupabaseClient: Erreur HTTP request (code: %d)" % err)
		http.queue_free()
		return { "success": false, "error": "Impossible d'initier la requête HTTP (code: %d)" % err }

	var result: Array = await http.request_completed
	http.queue_free()

	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]
	var text_body: String = response_body.get_string_from_utf8()

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text_body)
	var parsed_data = json.data if parse_err == OK else {}

	if response_code >= 200 and response_code < 300:
		print("SupabaseClient: HTTP %d OK pour %s" % [response_code, path])
		return { "success": true, "status": response_code, "data": parsed_data }
	else:
		if response_code == 401 and text_body.contains("JWT expired") and not refresh_token.is_empty() and not path.contains("grant_type=refresh_token"):
			push_warning("SupabaseClient: JWT expiré, rafraîchissement automatique...")
			var ref: Dictionary = await refresh_session()
			if ref.get("success", false):
				return await _perform_request(path, method, body, use_auth, extra_headers)

		var err_msg: String = "Erreur HTTP %d" % response_code
		if parsed_data is Dictionary and parsed_data.has("message"):
			err_msg = str(parsed_data["message"])
		elif parsed_data is Dictionary and parsed_data.has("msg"):
			err_msg = str(parsed_data["msg"])
		push_warning("SupabaseClient: HTTP %d sur %s -> %s" % [response_code, path, text_body])
		return { "success": false, "status": response_code, "error": err_msg, "data": parsed_data }
