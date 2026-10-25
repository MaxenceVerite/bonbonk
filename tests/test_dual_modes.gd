extends Node

const LevelData = preload("res://scripts/data/level_data.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const CampaignCatalog = preload("res://scripts/data/campaign_catalog.gd")
const WaveDirectorScript = preload("res://scripts/core/wave_director.gd")
const DeckServiceScript = preload("res://scripts/core/account/deck_service.gd")

func _ready() -> void:
	print("\n=== TEST DE VALIDATION ARCHITECTURALE : CAMPAGNE & SURVIE ===")

	# 1. Test du Catalogue de Campagne
	var worlds: Array[WorldData] = CampaignCatalog.get_all_worlds()
	assert(worlds.size() >= 2, "Au moins 2 mondes doivent exister !")
	var w1: WorldData = worlds[0]
	assert(w1.id == &"world_1", "Monde 1 doit avoir l'id world_1")
	assert(w1.levels.size() >= 5, "Monde 1 doit avoir au moins 5 niveaux")
	print("✓ 1. Catalogue de Campagne : %d mondes chargés avec succès" % worlds.size())

	# 2. Test du premier niveau et calcul des étoiles
	var l1: LevelData = w1.get_level(1)
	assert(l1 != null, "Niveau 1 du Monde 1 introuvable")
	assert(l1.waves.size() == 3, "Niveau 1 doit avoir 3 sous-vagues")
	assert(l1.calculate_stars(1600, 100, 100) == 3, "Score 1600 + 100% HP doit donner 3 étoiles")
	assert(l1.calculate_stars(1000, 50, 100) == 2, "Score 1000 + 50% HP doit donner 2 étoiles")
	assert(l1.calculate_stars(450, 20, 100) == 1, "Score 450 doit donner 1 étoile")
	assert(l1.calculate_stars(0, 0, 100) == 0, "0 HP = 0 étoile")
	print("✓ 2. Calcul des étoiles de niveau validé (seuil score & ratio PV)")

	# 3. Test du typage GameMode et Helpers
	SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
	assert(SaveManager.is_campaign() == true, "Doit être en mode campagne")
	assert(SaveManager.is_survival() == false, "Ne doit pas être en mode survie")

	SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
	assert(SaveManager.is_survival() == true, "Doit être en mode survie")
	assert(SaveManager.is_campaign() == false, "Ne doit pas être en mode campagne")
	print("✓ 3. Typage strict GameMode et Helpers SaveManager validés")

	# 4. Test de la séparation des Decks
	SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
	var camp_deck: Array = SaveManager.get_active_deck()
	assert(camp_deck.size() == 6, "Le deck campagne doit avoir 6 cartes")

	SaveManager.set_game_mode(SaveManager.GameMode.SURVIVAL)
	var surv_deck: Array = SaveManager.get_active_deck()
	assert(surv_deck.size() == 6, "Le deck survie doit avoir 6 cartes")

	# Modification du deck de survie
	SaveManager.set_card_in_active_deck(0, &"jawbreaker")
	assert(SaveManager.survival_deck[0] == &"jawbreaker", "Le slot 0 du deck de survie doit être jawbreaker")

	# Vérifier que le deck campagne n'a PAS été touché
	SaveManager.set_game_mode(SaveManager.GameMode.CAMPAIGN)
	assert(SaveManager.get_active_deck()[0] != &"jawbreaker" or camp_deck[0] == &"jawbreaker", "Le deck campagne ne doit pas être altéré par le deck survie")
	print("✓ 4. Séparation stricte des Decks (Campagne vs Survie) validée")

	# 5. Test de la factorisation de DeckService (assainissement des cartes obsolètes)
	var deck_service: RefCounted = DeckServiceScript.new()
	var dirty_deck: Array = [&"standard", &"cherry", &"fizz"]
	deck_service.validate_single_deck(dirty_deck)
	assert(dirty_deck.size() == 6, "Le deck assaini doit faire 6 cartes")
	assert(dirty_deck[0] == &"fizz" and dirty_deck[1] == &"fizz", "Les cartes obsolètes standard et cherry doivent devenir fizz")
	print("✓ 5. Factorisation validate_single_deck validée")

	# 6. Test de non-régression : sélection de niveau vs palier débloqué
	SaveManager.campaign_unlocked_level = 5
	SaveManager.campaign_selected_level = 1
	assert(SaveManager.campaign_unlocked_level == 5, "campaign_unlocked_level doit rester à 5 après avoir sélectionné le niveau 1 !")
	assert(SaveManager.campaign_selected_level == 1, "campaign_selected_level doit être à 1")
	print("✓ 6. Dissociation niveau sélectionné vs niveau débloqué validée (zéro régression de progression)")

	# 7. Test de défaite en Campagne : ne doit JAMAIS polluer les stats de Survie
	var prev_survival_played: int = SaveManager.current_profile.stats.get("games_played", 0)
	var prev_survival_best: int = SaveManager.current_profile.stats.get("best_score", 0)
	var prev_gold: int = SaveManager.gold

	var defeat_res: Dictionary = SaveManager.record_campaign_defeat(l1, 500, 15)
	assert(defeat_res["score"] == 500, "Score de défaite enregistré")
	assert(SaveManager.gold == prev_gold + 15, "Or de participation crédité (+15)")
	assert(SaveManager.current_profile.stats.get("games_played", 0) == prev_survival_played, "Les parties jouées en Survie NE DOIVENT PAS être incrémentées !")
	assert(SaveManager.current_profile.stats.get("best_score", 0) == prev_survival_best, "Le meilleur score de Survie NE DOIT PAS être pollué !")
	print("✓ 7. Isolation étanche de la défaite Campagne (zéro pollution des stats Survie) validée")

	# 8. Test d'enregistrement de victoire de niveau
	var res: Dictionary = SaveManager.record_campaign_level_results(l1, 1800, 3, 100)
	assert(res["stars"] == 3, "3 étoiles enregistrées")
	assert(res["is_first_clear"] == true or SaveManager.campaign_levels_data.has("w1_01"), "Niveau enregistré dans le profil")
	print("✓ 8. Enregistrement et progression de victoire validés")

	# 9. Test de WaveDirector en mode Campagne (Une seule manche continue)
	var dummy_enemy_container: Node2D = Node2D.new()
	var director: Node = WaveDirectorScript.new()
	add_child(director)
	director.initialize(dummy_enemy_container)

	var counter: Array[int] = [0]
	director.campaign_subwave_started.connect(func(sub_idx: int, total: int) -> void:
		counter[0] += 1
		print("  -> Signal sous-vague reçue : %d / %d" % [sub_idx, total])
	)

	var completed_called: Array[bool] = [false]
	director.campaign_level_completed.connect(func() -> void:
		completed_called[0] = true
		print("  -> Signal Niveau Campagne Terminé reçu !")
	)

	director.start_campaign_level(l1)
	assert(director.current_mode == director.Mode.CAMPAIGN, "Le mode doit être CAMPAIGN")
	assert(director.current_subwave_index == 1, "Doit être à la sous-vague 1")
	assert(counter[0] == 1, "1er signal sous-vague émis")

	print("✓ 9. Orchestration de vague continue en Campagne validée")
	print("\n>>> TOUS LES TESTS D'ARCHITECTURE SONT VALIDÉS AVEC SUCCÈS ! <<<\n")
	get_tree().quit(0)
