extends Node

func _ready() -> void:
	print("--- TEST NAVIGATION CIRCULAIRE & BORDERS ---")

	# Test 1 : AdventureView Circular Navigation
	var adv_scene: PackedScene = preload("res://scenes/ui/play/adventure_view.tscn")
	var adv: AdventureView = adv_scene.instantiate() as AdventureView
	add_child(adv)

	# Initialisation Monde 1
	adv.current_world_num = 1
	adv.refresh()
	assert(adv.current_world_num == 1, "Doit être au Monde 1")
	assert(adv.btn_prev_world.disabled == false, "btn_prev_world doit rester actif pour navigation circulaire")
	assert(adv.btn_next_world.disabled == false, "btn_next_world doit rester actif pour navigation circulaire")

	# Monde 1 -> Clic Précédent (◀) -> doit boucler vers Monde 2
	adv._navigate_world(-1)
	assert(adv.current_world_num == 2, "1 - 1 avec wrap circulaire doit donner Monde 2")

	# Monde 2 -> Clic Suivant (▶) -> doit boucler vers Monde 1
	adv._navigate_world(1)
	assert(adv.current_world_num == 1, "2 + 1 avec wrap circulaire doit donner Monde 1")

	# Test spam / clics rapides consécutifs (ne doit pas bloquer)
	for i in range(10):
		adv._navigate_world(1)
	# Après 10 incréments circulaires sur 2 mondes, 1 + 10 = 11, posmod(11-1, 2) + 1 = 1
	assert(adv.current_world_num == 1, "Après 10 clics suivants, doit être revenu au Monde 1 sans blocage")

	print("✓ 1. Navigation circulaire Aventure validée sans perte d'inputs")

	# Test 2 : SurvivalView Circular Navigation
	var surv_scene: PackedScene = preload("res://scenes/ui/play/survival_view.tscn")
	var surv: SurvivalView = surv_scene.instantiate() as SurvivalView
	add_child(surv)

	SaveManager.survival_selected_world = 1
	surv.refresh()
	assert(SaveManager.survival_selected_world == 1, "Arène initiale doit être 1")

	# Arène 1 -> Précédente -> Arène 2
	surv._on_prev_arena_pressed()
	assert(SaveManager.survival_selected_world == 2, "1 - 1 avec wrap circulaire doit donner Arène 2")

	# Arène 2 -> Suivante -> Arène 1
	surv._on_next_arena_pressed()
	assert(SaveManager.survival_selected_world == 1, "2 + 1 avec wrap circulaire doit donner Arène 1")

	# Test spam clics rapides en survie
	for i in range(10):
		surv._on_next_arena_pressed()
	assert(SaveManager.survival_selected_world == 1, "Après 10 clics suivants, doit être revenu à l'Arène 1")

	print("✓ 2. Navigation circulaire Survie validée sans blocage")

	# Prise de screenshot du mode Aventure avec les nouvelles bordures
	adv.visible = true
	surv.visible = false
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw

	var tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var artifact_path: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/adventure_bordered_banner.png"
			img.save_png(artifact_path)
			print("✓ Screenshot sauvegardé dans : ", artifact_path)

	adv.queue_free()
	surv.queue_free()
	print("ALL TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
