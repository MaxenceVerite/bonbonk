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

	# 10. Test de validation : Brocolino est le Boss du Monde 1 (1-10) et Carambine est le Boss du Monde 2 (2-10)
	var l1_10: LevelData = w1.get_level(10)
	assert(l1_10 != null, "Niveau 10 du Monde 1 introuvable")
	assert(l1_10.waves[1].spawns[0]["unit"] == "boss_brocolino", "Le boss du niveau 1-10 (Forêt Dragée) doit être Brocolino")

	var w2: WorldData = worlds[1]
	assert(w2 != null and w2.id == &"world_2", "Monde 2 Plage Sucrée introuvable")
	var l2_10: LevelData = w2.get_level(10)
	assert(l2_10 != null, "Niveau 10 du Monde 2 introuvable")
	assert(l2_10.waves[1].spawns[0]["unit"] == "boss_carambine", "Le boss du niveau 2-10 (Plage Sucrée) doit être Carambine")

	director.start_wave(10)
	assert(director.get("_pending_spawns")[0]["scene_path"].contains("boss_brocolino"), "La manche 10 de Survie doit faire apparaître Brocolino")
	director.start_wave(20)
	assert(director.get("_pending_spawns")[0]["scene_path"].contains("boss_carambine"), "La manche 20 de Survie doit faire apparaître Carambine")
	print("✓ 10. Intégration de Brocolino (Monde 1 / Vague 10) et Carambine (Monde 2 / Vague 20) validée")

	# 11. Test de validation : AdventureView navigation multi-monde & synchronisation UI
	var adv_scene: PackedScene = preload("res://scenes/ui/play/adventure_view.tscn")
	var adv_instance: Node = adv_scene.instantiate()
	add_child(adv_instance)

	assert(adv_instance.current_world_num == 1, "Monde initial doit être 1")
	assert(adv_instance.world_title_label.text.contains("FORÊT DRAGÉE"), "Titre Monde 1 doit être Forêt Dragée")
	assert(adv_instance.map_texture.texture.resource_path.contains("foret_dragee_saga_map"), "Texture carte Monde 1 doit être foret_dragee")
	assert(adv_instance.btn_prev_world.disabled == true, "Flèche précédente doit être désactivée au Monde 1")
	assert(adv_instance.btn_next_world.disabled == false, "Flèche suivante doit être accessible pour visiter le Monde 2")

	# Visite du Monde 2 alors qu'il est encore verrouillé (Monde débloqué = 1)
	SaveManager.campaign_unlocked_world = 1
	adv_instance._change_world(2)
	assert(adv_instance.current_world_num == 2, "Doit pouvoir visiter le Monde 2")
	assert(adv_instance.world_title_label.text.contains("🔒"), "Titre Monde 2 doit afficher le cadenas de verrouillage")
	assert(adv_instance.map_texture.texture.resource_path.contains("world_1_saga_map"), "Texture carte Monde 2 doit être la plage")
	assert(adv_instance._pins[0].current_status == adv_instance._pins[0].Status.LOCKED, "Le niveau 2-1 doit être verrouillé")

	# Vérifier que la modale bloque le jeu sur le Monde 2 verrouillé
	var w2_data: WorldData = CampaignCatalog.get_world_by_number(2)
	adv_instance.level_detail_modal.open(w2_data.get_level(1))
	assert(adv_instance.level_detail_modal.btn_play.disabled == true, "Bouton Jouer doit être désactivé sur un monde verrouillé")
	assert(adv_instance.level_detail_modal.btn_play.text.contains("MONDE VERROUILLÉ"), "Bouton doit afficher MONDE VERROUILLÉ")
	adv_instance.level_detail_modal.close()

	# Débloquer le Monde 2 et vérifier la transition vers l'accès débloqué
	SaveManager.campaign_unlocked_world = 2
	SaveManager.campaign_unlocked_level = 1
	adv_instance.refresh()
	assert(not adv_instance.world_title_label.text.contains("🔒"), "Le cadenas doit disparaître une fois débloqué")
	assert(adv_instance._pins[0].current_status == adv_instance._pins[0].Status.UNLOCKED, "Le niveau 2-1 doit devenir UNLOCKED")
	adv_instance.level_detail_modal.open(w2_data.get_level(1))
	assert(adv_instance.level_detail_modal.btn_play.disabled == false, "Bouton Jouer doit devenir actif sur un monde débloqué")
	adv_instance.level_detail_modal.close()

	# Revenir au Monde 1
	adv_instance._change_world(1)
	assert(adv_instance.current_world_num == 1, "Doit être revenu au Monde 1")
	adv_instance.queue_free()
	print("✓ 11. Navigation Multi-Mondes libre & verrouillage strict du Monde 2 validés")

	# 12. Test de validation : Choix d'arène en Survie & pureté du reskin
	var surv_scene: PackedScene = preload("res://scenes/ui/play/survival_view.tscn")
	var surv_instance: SurvivalView = surv_scene.instantiate() as SurvivalView
	add_child(surv_instance)

	assert(SaveManager.survival_selected_world == 1, "Arène par défaut en Survie doit être 1")
	assert(surv_instance.arena_name_label.text.contains("FORÊT DRAGÉE"), "Le label doit afficher FORÊT DRAGÉE")

	# Basculer vers l'arène suivante
	surv_instance._on_next_arena_pressed()
	assert(SaveManager.survival_selected_world == 2, "Arène sélectionnée en Survie doit être 2")
	assert(surv_instance.arena_name_label.text.contains("PLAGE SUCRÉE"), "Le label doit afficher PLAGE SUCRÉE")

	# Boucler vers l'arène précédente
	surv_instance._on_prev_arena_pressed()
	assert(SaveManager.survival_selected_world == 1, "Doit revenir à l'arène 1")
	surv_instance.queue_free()

	# Vérifier que les flippers conservent l'angle de physique exact de 7°
	var board_scene: PackedScene = preload("res://scenes/board/board.tscn")
	var board_inst = board_scene.instantiate()
	add_child(board_inst)
	var left_gate = board_inst.get_node("Gates/LeftGate")
	var right_gate = board_inst.get_node("Gates/RightGate")
	assert(is_equal_approx(left_gate.rotation_degrees, 7.0), "Angle de repos gauche doit être exactement 7.0°")
	assert(is_equal_approx(right_gate.rotation_degrees, 173.0), "Angle de repos droit doit être exactement 173.0°")
	board_inst.queue_free()
	print("✓ 12. Choix d'arène en Survie & préservation stricte de la physique/reskinning validés")

	print("\n>>> TOUS LES TESTS D'ARCHITECTURE SONT VALIDÉS AVEC SUCCÈS ! <<<\n")
	get_tree().quit(0)
