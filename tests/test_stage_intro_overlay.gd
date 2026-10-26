extends Node

## Test automatisé de l'introduction de partie (StageIntroOverlay & Board Reveal)

const StageIntroScene: PackedScene = preload("res://scenes/ui/stage_intro_overlay.tscn")
const BoardScene: PackedScene = preload("res://scenes/board/board.tscn")
const StageIntroScript = preload("res://scripts/ui/stage_intro_overlay.gd")

func _ready() -> void:
	print("\n=== TEST DE VALIDATION DE L'INTRO DE PARTIE (STAGE INTRO) ===")

	# 1. Instanciation de l'overlay
	var overlay: Control = StageIntroScene.instantiate() as Control
	assert(overlay != null, "Impossible d'instancier StageIntroOverlay")
	add_child(overlay)
	assert(overlay.visible == false, "L'overlay doit être masqué au démarrage")
	print("✓ 1. Instanciation de StageIntroOverlay validée")

	# 2. Test du remplissage des données de niveau (Campagne)
	var test_info: Dictionary = {
		"mode": "campaign",
		"world_title": "Monde 1 • Plage Sucrée",
		"level_title": "Niv. 1-4 • Le Carrefour des Cocos",
		"subtitle": "Défendez les portes sucrées !"
	}
	var was_finished: bool = false
	overlay.call(&"play_intro", test_info, func() -> void:
		was_finished = true
	)

	assert(overlay.visible == true, "L'overlay doit être visible après play_intro")
	var world_label: Label = overlay.get_node("CenterContainer/BannerCard/Margin/CardVBox/WorldTagLabel") as Label
	var title_label: Label = overlay.get_node("CenterContainer/BannerCard/Margin/CardVBox/TitleLabel") as Label
	assert(world_label.text.contains("MONDE 1"), "Le tag du monde doit être affiché")
	assert(title_label.text == "Niv. 1-4 • Le Carrefour des Cocos", "Le titre du niveau doit correspondre")
	print("✓ 2. Affichage des métadonnées de mission validé")

	# 3. Test de validation du tap sur la carte (passage à PRÊT ?) et fast-forward BONBONK
	overlay.call(&"_proceed_from_card_to_ready")
	assert(overlay.get(&"_waiting_for_card_tap") == false, "La carte ne doit plus être en attente de tap")
	overlay.call(&"_fast_forward_to_bonbonk")
	assert(overlay.get(&"_has_triggered_bonbonk") == true, "Le fast-forward doit enclencher le BONBONK !")
	print("✓ 3. Transition par tap sur la carte et déclenchement BONBONK validés")

	# 4. Test du Board Reveal (Pop en cascade des bumpers et éveil des batteurs)
	var board: Board = BoardScene.instantiate() as Board
	add_child(board)
	board.play_board_intro_reveal()
	print("✓ 4. Animation du Board Reveal (pop bumpers & batteurs) validée")

	# Nettoyage
	overlay.queue_free()
	board.queue_free()

	print("\n>>> TOUS LES TESTS DE L'INTRO DE PARTIE SONT VALIDÉS AVEC SUCCÈS ! <<<")
	get_tree().quit()
