extends Node

func _ready() -> void:
	print("--- TEST & RÉPARATION DE PROGRESSION ---")

	# 1. Assainissement du profil actif
	SaveManager.sanitize_campaign_progression()

	print("Profil assaini:")
	print("  campaign_unlocked_world = ", SaveManager.campaign_unlocked_world)
	print("  campaign_unlocked_level = ", SaveManager.campaign_unlocked_level)

	assert(SaveManager.campaign_unlocked_world == 1, "Le monde débloqué doit être 1 tant que le niveau 10 n'est pas battu")
	assert(SaveManager.campaign_unlocked_level == 2, "Le niveau débloqué doit être 2 puisque seul le niveau 1 est battu")

	# 2. Vérification des pins dans AdventureView
	var adv_scene: PackedScene = preload("res://scenes/ui/play/adventure_view.tscn")
	var adv: AdventureView = adv_scene.instantiate() as AdventureView
	add_child(adv)
	adv.current_world_num = 1
	adv.refresh()

	assert(adv._pins[0].current_status == adv._pins[0].Status.CLEARED, "Niveau 1 doit être CLEARED")
	assert(adv._pins[1].current_status == adv._pins[1].Status.UNLOCKED, "Niveau 2 doit être UNLOCKED (seul niveau actif)")
	for i in range(2, 10):
		assert(adv._pins[i].current_status == adv._pins[i].Status.LOCKED, "Niveau %d doit être LOCKED" % (i + 1))

	print("✓ Statuts des niveaux : Niveau 1 CLEARED, Niveau 2 UNLOCKED, Niveaux 3-10 STRICTEMENT VERROUILLÉS !")

	# 3. Capture du screenshot
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw

	var tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/adventure_progression_fixed.png"
			img.save_png(path)
			print("✓ Screenshot sauvegardé dans : ", path)

	adv.queue_free()
	print("ALL PROGRESSION REPAIR TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
