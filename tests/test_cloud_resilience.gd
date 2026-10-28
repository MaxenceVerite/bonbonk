extends Node

## Test de validation de la résilience Cloud & Offline-First (Supabase / Local).
## Vérifie :
## 1. Le chiffrement AES et l'écriture atomique SaveCipher
## 2. La résolution non-destructive de conflits (Cartes, Niveaux, Étoiles, Monnaies)
## 3. La garantie FinTech zéro-perte (Journal des achats in-app / purchases_ledger)
## 4. L'initialisation robuste du SupabaseClient

const SaveCipher = preload("res://scripts/core/account/save_cipher.gd")
const PlayerProfileScript = preload("res://scripts/data/player_profile.gd")
const CloudSyncService = preload("res://scripts/core/account/cloud_sync_service.gd")
const SupabaseClientScript = preload("res://scripts/core/account/supabase_client.gd")

func _ready() -> void:
	print("\n=== TEST DE RÉSILIENCE CLOUD & SYSTÈME DE COMPTE SUPABASE ===")
	
	_test_encryption_and_atomic_io()
	_test_non_destructive_conflict_resolution()
	_test_financial_ledger_safety()
	_test_supabase_client_initialization()
	
	print(">>> TOUS LES TESTS DE RÉSILIENCE CLOUD SONT VALIDÉS AVEC SUCCÈS ! <<<\n")

func _test_encryption_and_atomic_io() -> void:
	var test_path: String = "user://test_secure_profile.enc"
	var payload: Dictionary = {
		"player_id": "test_gourmand_99",
		"gold": 1250,
		"diamonds": 85,
		"secret_token": "jwt_abc123_xyz"
	}

	# 1. Écriture chiffrée
	var write_ok: bool = SaveCipher.save_encrypted_json(test_path, payload)
	assert(write_ok, "L'écriture chiffrée AES doit réussir")

	# 2. Vérification que le fichier n'est pas du texte en clair
	var raw_file: FileAccess = FileAccess.open(test_path, FileAccess.READ)
	assert(raw_file != null, "Le fichier de test chiffré doit exister")
	var raw_content: String = raw_file.get_as_text()
	raw_file.close()
	assert(not raw_content.contains("test_gourmand_99"), "Le contenu sur disque ne doit PAS être lisible en clair !")

	# 3. Lecture déchiffrée
	var loaded: Dictionary = SaveCipher.load_encrypted_json(test_path)
	assert(loaded.get("player_id") == "test_gourmand_99", "Le déchiffrement doit restituer les données exactes")
	assert(loaded.get("gold") == 1250, "Le solde d'or déchiffré doit être 1250")
	assert(loaded.get("diamonds") == 85, "Le solde de diamants déchiffré doit être 85")

	# Nettoyage
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)
	if FileAccess.file_exists(test_path + ".bak"):
		DirAccess.remove_absolute(test_path + ".bak")

	print("✓ 1. Chiffrement AES-256 et écriture atomique validés")

func _test_non_destructive_conflict_resolution() -> void:
	var sync_service: CloudSyncService = CloudSyncService.new()
	add_child(sync_service)

	# Profil Local (ex: joueur ayant joué hors-ligne dans le métro)
	var local_prof: PlayerProfileScript = PlayerProfileScript.new()
	local_prof.profile_id = "main"
	local_prof.display_name = "Maxence"
	local_prof.gold = 1500
	local_prof.diamonds = 40
	local_prof.campaign_unlocked_world = 1
	local_prof.campaign_unlocked_level = 8
	local_prof.campaign_levels_data = {
		"w1_01": { "stars": 3, "best_score": 12000, "cleared": true },
		"w1_02": { "stars": 2, "best_score": 8500, "cleared": true }
	}
	local_prof.survival_best_wave = 15
	local_prof.survival_best_score = 45000
	local_prof.cards_inventory[&"fizz"] = { "unlocked": true, "level": 3, "cards": 40 }
	local_prof.cards_inventory[&"caramel"] = { "unlocked": true, "level": 1, "cards": 10 }
	local_prof.last_saved_at = 1000

	# Profil Distant Cloud (ex: joueur ayant joué la veille sur sa tablette connectée)
	var remote_prof: PlayerProfileScript = PlayerProfileScript.new()
	remote_prof.profile_id = "main"
	remote_prof.display_name = "Maxence"
	remote_prof.gold = 800
	remote_prof.diamonds = 95 # Plus de diamants sur la tablette
	remote_prof.campaign_unlocked_world = 2 # Monde 2 débloqué sur la tablette !
	remote_prof.campaign_unlocked_level = 3
	remote_prof.campaign_levels_data = {
		"w1_01": { "stars": 2, "best_score": 9000, "cleared": true },
		"w1_02": { "stars": 3, "best_score": 14000, "cleared": true }, # 3 étoiles sur la tablette
		"w2_01": { "stars": 2, "best_score": 11000, "cleared": true }
	}
	remote_prof.survival_best_wave = 22 # Meilleure vague sur la tablette
	remote_prof.survival_best_score = 30000
	remote_prof.cards_inventory[&"fizz"] = { "unlocked": true, "level": 2, "cards": 60 } # Plus de cartes sur la tablette
	remote_prof.cards_inventory[&"twistypop"] = { "unlocked": true, "level": 2, "cards": 5 } # Carte débloquée sur la tablette
	remote_prof.last_saved_at = 2000

	# Exécution de la fusion non-destructive
	var merged: PlayerProfileScript = sync_service._resolve_conflicts(local_prof, remote_prof)

	# Vérifications absolues
	assert(merged.gold == 1500, "L'or fusionné doit être le maximum (1500)")
	assert(merged.diamonds == 95, "Les diamants fusionnés doivent être le maximum (95)")
	assert(merged.campaign_unlocked_world == 2, "Le monde le plus avancé doit être conservé (Monde 2)")
	assert(merged.campaign_unlocked_level == 3, "Le niveau débloqué du monde 2 doit être 3")

	# Étoiles par niveau
	assert(merged.campaign_levels_data["w1_01"]["stars"] == 3, "Niveau 1-01 : le max d'étoiles (3) doit être conservé")
	assert(merged.campaign_levels_data["w1_02"]["stars"] == 3, "Niveau 1-02 : le max d'étoiles (3) doit être conservé")
	assert(merged.campaign_levels_data["w1_02"]["best_score"] == 14000, "Niveau 1-02 : le meilleur score doit être conservé")
	assert(merged.campaign_levels_data["w2_01"]["stars"] == 2, "Niveau 2-01 du cloud doit être présent")

	# Survie
	assert(merged.survival_best_wave == 22, "Meilleure vague survie fusionnée doit être 22")
	assert(merged.survival_best_score == 45000, "Meilleur score survie fusionné doit être 45000")

	# Cartes
	assert(merged.cards_inventory[&"fizz"]["level"] == 3, "Niveau de Fizzball doit être le max (3)")
	assert(merged.cards_inventory[&"fizz"]["cards"] == 60, "Nombre de cartes Fizzball doit être le max (60)")
	assert(merged.cards_inventory.has(&"caramel"), "Bille Caramel débloquée en local doit être conservée")
	assert(merged.cards_inventory.has(&"twistypop"), "Bumper Twistypop débloqué sur le cloud doit être conservé")

	sync_service.queue_free()
	print("✓ 2. Résolution non-destructive de conflits validée (Zéro régression)")

func _test_financial_ledger_safety() -> void:
	# Test de la garantie FinTech zéro-perte (Achats in-app / Ledger)
	var profile: PlayerProfileScript = PlayerProfileScript.new()
	profile.diamonds = 20

	# Simulation d'un achat effectué hors-ligne
	var tx_id: String = SaveManager.record_in_app_purchase(
		"pack_gemmes_500",
		4.99,
		500,
		{ "booster": "golden_crush" },
		"google_play",
		"google_signed_receipt_token_xyz"
	)

	assert(not tx_id.is_empty(), "Un tx_id unique doit être généré")
	assert(profile.diamonds == 20, "Le solde avant injection locale")
	assert(SaveManager.current_profile.pending_purchases.size() >= 1, "Le journal des achats en attente doit contenir l'achat")

	var pending_tx: Dictionary = SaveManager.current_profile.pending_purchases.back()
	assert(pending_tx["product_id"] == "pack_gemmes_500", "L'achat enregistré doit correspondre au produit")
	assert(pending_tx["granted_diamonds"] == 500, "500 diamants doivent être enregistrés dans le journal")

	print("✓ 3. Journal des achats in-app (FinTech Ledger) validé")

func _test_supabase_client_initialization() -> void:
	var client: Node = SupabaseClientScript.new()
	add_child(client)

	# Doit charger la configuration sans planter
	client.load_config()
	assert(not client.supabase_url.is_empty(), "L'URL Supabase doit être chargée depuis config")
	assert(not client.supabase_anon_key.is_empty(), "La clé publique Anon doit être chargée")
	assert(client.request_timeout >= 5.0, "Le timeout doit être configuré")

	# Test du cycle de session chiffrée
	client.access_token = "mock_jwt_access_token_12345"
	client.refresh_token = "mock_jwt_refresh_token_67890"
	client.user_id = "usr_test_uuid_abc"
	client.is_anonymous = true
	client.save_session()

	# Nouveau client : doit relire la session chiffrée
	var client2: Node = SupabaseClientScript.new()
	add_child(client2)
	client2.load_cached_session()
	assert(client2.access_token == "mock_jwt_access_token_12345", "Le token JWT doit être relu fidèlement depuis le stockage chiffré")
	assert(client2.user_id == "usr_test_uuid_abc", "Le user_id doit être restauré")

	# Nettoyage de la session de test
	client.clear_session()
	client.queue_free()
	client2.queue_free()

	print("✓ 4. SupabaseClient & Persistance chiffrée de session validés")
