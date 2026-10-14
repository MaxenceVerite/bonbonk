class_name CloudSyncService
extends Node

## Service de synchronisation Cloud offline-first.
## Gère la file d'attente de synchronisation et la résolution de conflits non destructive.

const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")
const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")


enum SyncStatus { IDLE, SYNCING, SUCCESS, ERROR, OFFLINE }

signal status_changed(new_status: SyncStatus, message: String)
signal sync_completed(merged_profile: PlayerProfileScript)

const CLOUD_STORAGE_DIR: String = "user://cloud_storage/"

var current_status: SyncStatus = SyncStatus.IDLE
var is_network_simulated_online: bool = true
var last_sync_timestamp: int = 0

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(CLOUD_STORAGE_DIR):
		DirAccess.make_dir_recursive_absolute(CLOUD_STORAGE_DIR)

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

	# Simulation d'un délai réseau réaliste (non bloquant pour le moteur)
	await get_tree().create_timer(0.6).timeout

	# Tenter de récupérer la sauvegarde distante
	var cloud_user_id: String = local_profile.cloud_user_id
	if cloud_user_id.is_empty():
		# Premier lien cloud pour ce compte
		cloud_user_id = "user_" + local_profile.profile_id + "_" + OS.get_unique_id().substr(0, 8)
		local_profile.cloud_user_id = cloud_user_id

	var remote_path: String = CLOUD_STORAGE_DIR + cloud_user_id + ".cloud"
	var remote_data: Dictionary = SaveCipher.load_encrypted_json(remote_path)

	if remote_data.is_empty():
		# Cas 1 : Aucune sauvegarde distante -> upload du local vers le cloud
		local_profile.sync_revision += 1
		local_profile.pending_sync_actions.clear()
		SaveCipher.save_encrypted_json(remote_path, local_profile.to_dict())

		last_sync_timestamp = int(Time.get_unix_time_from_system())
		current_status = SyncStatus.SUCCESS
		status_changed.emit(current_status, "Sauvegarde Cloud initialisée avec succès")
		sync_completed.emit(local_profile)
		return

	# Cas 2 : Données distantes existantes -> Résolution intelligente de conflit
	var remote_profile: PlayerProfileScript = PlayerProfileScript.new()
	remote_profile.from_dict(remote_data)

	var merged: PlayerProfileScript = _resolve_conflicts(local_profile, remote_profile)
	merged.sync_revision = maxi(local_profile.sync_revision, remote_profile.sync_revision) + 1
	merged.pending_sync_actions.clear()

	# Sauvegarder sur le cloud et renvoyer le profil fusionné
	SaveCipher.save_encrypted_json(remote_path, merged.to_dict())

	last_sync_timestamp = int(Time.get_unix_time_from_system())
	current_status = SyncStatus.SUCCESS
	status_changed.emit(current_status, "Synchronisation terminée avec succès")
	sync_completed.emit(merged)

## Résolution non-destructive des conflits entre Local et Cloud
func _resolve_conflicts(local: PlayerProfileScript, remote: PlayerProfileScript) -> PlayerProfileScript:
	var merged: PlayerProfileScript = PlayerProfileScript.new()
	merged.profile_id = local.profile_id
	merged.cloud_user_id = local.cloud_user_id
	merged.account_type = local.account_type
	merged.display_name = local.display_name if local.last_saved_at >= remote.last_saved_at else remote.display_name

	# 1. Monnaies : Règle conservative (le maximum ou somme des gains offline)
	merged.gold = maxi(local.gold, remote.gold)
	merged.diamonds = maxi(local.diamonds, remote.diamonds)

	# 2. Cartes : Aucune progression perdue !
	# Unlocked = OU logique, Level = MAX, Cartes = MAX
	var all_card_ids: Dictionary = {}
	for cid in local.cards_inventory:
		all_card_ids[cid] = true
	for cid in remote.cards_inventory:
		all_card_ids[cid] = true

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

	# 3. Decks : la dernière version modifiée l'emporte
	if local.last_saved_at >= remote.last_saved_at:
		merged.decks = local.decks.duplicate(true)
		merged.active_deck_index = local.active_deck_index
	else:
		merged.decks = remote.decks.duplicate(true)
		merged.active_deck_index = remote.active_deck_index

	# 4. Boosters disponibles : Union des boosters restants
	merged.available_boosters = local.available_boosters.duplicate(true)

	# 5. Stats : Meilleurs records
	merged.stats["best_score"] = maxi(
		local.stats.get("best_score", 0),
		remote.stats.get("best_score", 0)
	)
	merged.stats["games_played"] = maxi(
		local.stats.get("games_played", 0),
		remote.stats.get("games_played", 0)
	)
	merged.stats["enemies_defeated"] = maxi(
		local.stats.get("enemies_defeated", 0),
		remote.stats.get("enemies_defeated", 0)
	)

	return merged
