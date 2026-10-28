class_name CloudSyncService
extends Node

## Service de synchronisation Cloud offline-first & Multi-Plateforme (Supabase / Local).
## - Priorité absolue : Zéro perte de données (progression, monnaies et achats in-app).
## - Résolution de conflits non-destructive (Union conservative des cartes, niveaux et records).
## - Journal des transactions financières sécurisé (Purchases Ledger).
## - Mode hors-ligne transparent avec synchronisation automatique lors du retour réseau.

const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")
const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")
const SupabaseClientScript = preload("res://scripts/core/account/supabase_client.gd")

enum SyncStatus { IDLE, SYNCING, SUCCESS, ERROR, OFFLINE }

signal status_changed(new_status: SyncStatus, message: String)
signal sync_completed(merged_profile: PlayerProfileScript)

const CLOUD_STORAGE_DIR: String = "user://cloud_storage/"

var current_status: SyncStatus = SyncStatus.IDLE
var is_network_simulated_online: bool = true
var last_sync_timestamp: int = 0

# Client Supabase managé
var supabase_client: Node = null

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(CLOUD_STORAGE_DIR):
		DirAccess.make_dir_recursive_absolute(CLOUD_STORAGE_DIR)

	supabase_client = SupabaseClientScript.new()
	supabase_client.name = "SupabaseClient"
	add_child(supabase_client)

	supabase_client.auth_state_changed.connect(_on_supabase_auth_changed)

func _on_supabase_auth_changed(is_auth: bool, uid: String) -> void:
	if is_auth:
		print("CloudSyncService: Authentifié avec succès sur Supabase (UID: %s)" % uid)
	else:
		print("CloudSyncService: Déconnecté de Supabase")

func set_network_online(online: bool) -> void:
	is_network_simulated_online = online
	if not is_network_simulated_online:
		current_status = SyncStatus.OFFLINE
		status_changed.emit(current_status, "Mode hors-ligne")
	else:
		current_status = SyncStatus.IDLE
		status_changed.emit(current_status, "Connecté au Cloud")

func is_online() -> bool:
	return is_network_simulated_online

## Force une synchronisation immédiate avec le profil actif
func sync_now() -> void:
	if SaveManager != null and SaveManager.current_profile != null:
		sync_profile(SaveManager.current_profile)

## Lance une authentification anonyme (Guest) et met à jour le profil local
func authenticate_anonymously() -> void:
	if supabase_client != null and supabase_client.is_configured():
		var display_name: String = "Gourmand"
		if SaveManager != null and SaveManager.current_profile != null:
			display_name = SaveManager.current_profile.display_name
		var res: Dictionary = await supabase_client.sign_in_anonymously(display_name)
		if res.get("success", false) and SaveManager != null and SaveManager.current_profile != null:
			SaveManager.current_profile.cloud_user_id = supabase_client.user_id
			SaveManager.current_profile.account_type = "guest"
			SaveManager.request_save()
			sync_profile(SaveManager.current_profile)

## Déconnecte le compte cloud actif
func sign_out() -> void:
	if supabase_client != null:
		supabase_client.sign_out()
	current_status = SyncStatus.IDLE
	status_changed.emit(current_status, "Déconnecté")

## Lance la synchronisation offline-first
func sync_profile(local_profile: PlayerProfileScript) -> void:
	if not is_online():
		current_status = SyncStatus.OFFLINE
		status_changed.emit(current_status, "Hors-ligne : les modifications sont enregistrées en local")
		return

	if current_status == SyncStatus.SYNCING:
		return

	current_status = SyncStatus.SYNCING
	status_changed.emit(current_status, "Synchronisation Cloud en cours...")

	# Si Supabase est configuré et disponible, on effectue la synchronisation réelle
	if supabase_client != null and supabase_client.is_configured():
		await _sync_with_supabase(local_profile)
	else:
		# Fallback local sécurisé (développement, simulation réseau offline-first)
		await _sync_with_local_cloud_mock(local_profile)

## Synchronisation réelle avec le backend Supabase
func _sync_with_supabase(local_profile: PlayerProfileScript) -> void:
	# 1. Connexion Anonyme automatique si pas encore connecté
	if not supabase_client.is_logged_in():
		var auth_resp: Dictionary = await supabase_client.sign_in_anonymously(local_profile.display_name)
		if not auth_resp.get("success", false):
			current_status = SyncStatus.ERROR
			status_changed.emit(current_status, "Erreur d'authentification Cloud: %s" % auth_resp.get("error", ""))
			return

	local_profile.cloud_user_id = supabase_client.user_id

	# 2. Garantie FinTech / Achats in-app : Vidage du journal d'achats en attente
	if not local_profile.pending_purchases.is_empty():
		var remaining_purchases: Array = []
		for tx in local_profile.pending_purchases:
			if tx is Dictionary:
				var tx_resp: Dictionary = await supabase_client.record_purchase(tx)
				if not tx_resp.get("success", false):
					remaining_purchases.append(tx)
		local_profile.pending_purchases = remaining_purchases

	# 3. Récupération du profil distant depuis PostgreSQL (RLS sécurisé)
	var fetch_resp: Dictionary = await supabase_client.fetch_profile()
	if not fetch_resp.get("success", false):
		current_status = SyncStatus.ERROR
		status_changed.emit(current_status, "Erreur lors de la récupération Cloud: %s" % fetch_resp.get("error", ""))
		return

	var remote_data_row: Dictionary = fetch_resp.get("profile", {})
	var merged_profile: PlayerProfileScript = local_profile

	if not remote_data_row.is_empty():
		# Profil distant existant -> Fusion non-destructive
		var remote_profile: PlayerProfileScript = PlayerProfileScript.new()
		var profile_dict: Dictionary = remote_data_row.get("data", {})
		if profile_dict.is_empty():
			profile_dict = remote_data_row
		remote_profile.from_dict(profile_dict)
		if remote_data_row.has("is_admin"):
			remote_profile.is_admin = bool(remote_data_row.get("is_admin", false))

		merged_profile = _resolve_conflicts(local_profile, remote_profile)
		merged_profile.sync_revision = maxi(local_profile.sync_revision, remote_profile.sync_revision) + 1
	else:
		# Premier envoi vers le Cloud
		local_profile.sync_revision += 1
		merged_profile = local_profile

	# 4. Envoi du profil fusionné vers Supabase (Upsert)
	var upsert_payload: Dictionary = {
		"display_name": merged_profile.display_name,
		"gold": merged_profile.gold,
		"diamonds": merged_profile.diamonds,
		"campaign_unlocked_world": merged_profile.campaign_unlocked_world,
		"campaign_unlocked_level": merged_profile.campaign_unlocked_level,
		"survival_best_wave": merged_profile.survival_best_wave,
		"survival_best_score": merged_profile.survival_best_score,
		"sync_revision": merged_profile.sync_revision,
		"data": merged_profile.to_dict()
	}
	var upsert_resp: Dictionary = await supabase_client.upsert_profile(upsert_payload)
	if not upsert_resp.get("success", false):
		current_status = SyncStatus.ERROR
		status_changed.emit(current_status, "Erreur lors de la sauvegarde Cloud: %s" % upsert_resp.get("error", ""))
		return

	# Sauvegarde locale chiffrée de secours
	_save_local_cloud_backup(merged_profile)

	last_sync_timestamp = int(Time.get_unix_time_from_system())
	current_status = SyncStatus.SUCCESS
	status_changed.emit(current_status, "Synchronisation Cloud réussie")
	sync_completed.emit(merged_profile)

## Simulation offline-first locale chiffrée (tests et mode sans Supabase)
func _sync_with_local_cloud_mock(local_profile: PlayerProfileScript) -> void:
	await get_tree().create_timer(0.3).timeout

	var cloud_user_id: String = local_profile.cloud_user_id
	if cloud_user_id.is_empty():
		cloud_user_id = "user_" + local_profile.profile_id + "_" + OS.get_unique_id().substr(0, 8)
		local_profile.cloud_user_id = cloud_user_id

	var remote_path: String = CLOUD_STORAGE_DIR + cloud_user_id + ".cloud"
	var remote_data: Dictionary = SaveCipher.load_encrypted_json(remote_path)

	if remote_data.is_empty():
		local_profile.sync_revision += 1
		local_profile.pending_sync_actions.clear()
		SaveCipher.save_encrypted_json(remote_path, local_profile.to_dict())

		last_sync_timestamp = int(Time.get_unix_time_from_system())
		current_status = SyncStatus.SUCCESS
		status_changed.emit(current_status, "Sauvegarde Cloud initialisée avec succès")
		sync_completed.emit(local_profile)
		return

	var remote_profile: PlayerProfileScript = PlayerProfileScript.new()
	remote_profile.from_dict(remote_data)

	var merged: PlayerProfileScript = _resolve_conflicts(local_profile, remote_profile)
	merged.sync_revision = maxi(local_profile.sync_revision, remote_profile.sync_revision) + 1
	merged.pending_sync_actions.clear()

	SaveCipher.save_encrypted_json(remote_path, merged.to_dict())

	last_sync_timestamp = int(Time.get_unix_time_from_system())
	current_status = SyncStatus.SUCCESS
	status_changed.emit(current_status, "Synchronisation terminée avec succès")
	sync_completed.emit(merged)

func _save_local_cloud_backup(profile: PlayerProfileScript) -> void:
	if not profile.cloud_user_id.is_empty():
		var remote_path: String = CLOUD_STORAGE_DIR + profile.cloud_user_id + ".cloud"
		SaveCipher.save_encrypted_json(remote_path, profile.to_dict())

## Résolution non-destructive des conflits entre Local et Cloud
## RÈGLE ABSOLUE : ZÉRO PERTE DE PROGRESSION OU DE MONNAIE
func _resolve_conflicts(local: PlayerProfileScript, remote: PlayerProfileScript) -> PlayerProfileScript:
	var merged: PlayerProfileScript = PlayerProfileScript.new()
	merged.profile_id = local.profile_id
	merged.cloud_user_id = local.cloud_user_id if not local.cloud_user_id.is_empty() else remote.cloud_user_id
	merged.account_type = "cloud" if (local.account_type == "cloud" or remote.account_type == "cloud") else "guest"
	# Règle d'arbitrage pour le pseudo et les decks :
	# Si local est un compte vierge (0 parties jouées) et que le cloud a déjà progressé, le cloud gagne impérativement.
	var prefer_local: bool = false
	var local_games: int = int(local.stats.get("games_played", 0))
	var remote_games: int = int(remote.stats.get("games_played", 0))

	if local_games == 0 and remote_games > 0:
		prefer_local = false
	elif local.sync_revision > remote.sync_revision:
		prefer_local = true
	elif remote.sync_revision > local.sync_revision:
		prefer_local = false
	else:
		prefer_local = local.last_saved_at >= remote.last_saved_at

	merged.display_name = local.display_name if prefer_local else remote.display_name
	merged.has_chosen_name = local.has_chosen_name or remote.has_chosen_name or (merged.display_name != "Gourmand" and not merged.display_name.begins_with("Gourmand_"))

	# 1. Monnaies : Règle conservative absolue (le maximum atteint)
	merged.gold = maxi(local.gold, remote.gold)
	merged.diamonds = maxi(local.diamonds, remote.diamonds)

	# 2. Étoiles et records par niveau de Campagne (Union non-destructive)
	var all_lvl_ids: Dictionary = {}
	for lid in local.campaign_levels_data: all_lvl_ids[lid] = true
	for lid in remote.campaign_levels_data: all_lvl_ids[lid] = true

	for lid in all_lvl_ids:
		var loc_l: Dictionary = local.campaign_levels_data.get(lid, {})
		var rem_l: Dictionary = remote.campaign_levels_data.get(lid, {})
		merged.campaign_levels_data[lid] = {
			"stars": maxi(loc_l.get("stars", 0), rem_l.get("stars", 0)),
			"best_score": maxi(loc_l.get("best_score", 0), rem_l.get("best_score", 0)),
			"cleared": bool(loc_l.get("cleared", false) or rem_l.get("cleared", false))
		}

	# 3. Recalcul de cohérence stricte de progression (Monde & Niveau débloqué)
	var max_w: int = 1
	while true:
		var b_short: String = "w%d_10" % max_w
		var b_long: String = "world_%d_10" % max_w
		var b_data: Dictionary = merged.campaign_levels_data.get(b_short, merged.campaign_levels_data.get(b_long, {}))
		if bool(b_data.get("cleared", false)) or int(b_data.get("stars", 0)) > 0:
			max_w += 1
		else:
			break
	merged.campaign_unlocked_world = max_w

	var max_lvl: int = 1
	for l in range(1, 11):
		var l_short: String = "w%d_%02d" % [max_w, l]
		var l_long: String = "world_%d_%02d" % [max_w, l]
		var l_data: Dictionary = merged.campaign_levels_data.get(l_short, merged.campaign_levels_data.get(l_long, {}))
		if bool(l_data.get("cleared", false)) or int(l_data.get("stars", 0)) > 0:
			max_lvl = mini(10, l + 1)
		else:
			break
	merged.campaign_unlocked_level = max_lvl

	# 4. Records du Mode Survie
	merged.survival_best_wave = maxi(local.survival_best_wave, remote.survival_best_wave)
	merged.survival_best_score = maxi(local.survival_best_score, remote.survival_best_score)
	merged.survival_selected_world = local.survival_selected_world if prefer_local else remote.survival_selected_world

	# 5. Cartes : Aucune progression perdue ! (Déblocage = OU logique, Level = MAX, Cartes = MAX)
	var all_card_ids: Dictionary = {}
	for cid in local.cards_inventory: all_card_ids[cid] = true
	for cid in remote.cards_inventory: all_card_ids[cid] = true

	for cid in all_card_ids:
		var loc_c: Dictionary = local.cards_inventory.get(cid, {})
		var rem_c: Dictionary = remote.cards_inventory.get(cid, {})

		var is_unlocked: bool = loc_c.get("unlocked", false) or rem_c.get("unlocked", false)
		var lvl: int = maxi(loc_c.get("level", 1), rem_c.get("level", 1))
		var card_count: int = maxi(loc_c.get("cards", 0), rem_c.get("cards", 0))

		merged.cards_inventory[cid] = {
			"unlocked": is_unlocked,
			"level": lvl,
			"cards": card_count
		}

	# 6. Decks : la version la plus pertinente l'emporte
	if prefer_local:
		merged.decks = local.decks.duplicate(true)
		merged.active_deck_index = local.active_deck_index
		merged.survival_deck = local.survival_deck.duplicate(true)
	else:
		merged.decks = remote.decks.duplicate(true)
		merged.active_deck_index = remote.active_deck_index
		merged.survival_deck = remote.survival_deck.duplicate(true)

	# 7. Boosters disponibles : Union des boosters restants
	merged.available_boosters = local.available_boosters.duplicate(true)
	for b in remote.available_boosters:
		if not merged.available_boosters.has(b):
			merged.available_boosters.append(b)

	# 8. Journal des achats en attente : Union dédupliquée par tx_id
	var tx_map: Dictionary = {}
	for tx in local.pending_purchases:
		if tx is Dictionary and tx.has("tx_id"):
			tx_map[str(tx["tx_id"])] = tx
	for tx in remote.pending_purchases:
		if tx is Dictionary and tx.has("tx_id"):
			tx_map[str(tx["tx_id"])] = tx
	merged.pending_purchases = tx_map.values()

	# 9. Statistiques globales : Meilleurs records
	merged.stats["best_score"] = maxi(local.stats.get("best_score", 0), remote.stats.get("best_score", 0))
	merged.stats["games_played"] = maxi(local.stats.get("games_played", 0), remote.stats.get("games_played", 0))
	merged.stats["enemies_defeated"] = maxi(local.stats.get("enemies_defeated", 0), remote.stats.get("enemies_defeated", 0))

	# 10. Privilèges Admin / Dev
	merged.is_admin = bool(local.is_admin or remote.is_admin)

	return merged
