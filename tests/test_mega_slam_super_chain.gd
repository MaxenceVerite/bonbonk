extends Node

func _ready() -> void:
	print("--- TEST MEGA SLAM & SUPER CHAIN (CLUTCH SAVE) ---")

	var board_scene: PackedScene = preload("res://scenes/board/board.tscn")
	var board: Board = board_scene.instantiate() as Board
	add_child(board)
	board.start_game()

	for f in range(6):
		await get_tree().process_frame

	assert(board.mega_slam_controller != null, "MegaSlamController doit être instancié dans Board")
	assert(board.mega_slam_controller.is_ready() == true, "MegaSlamController doit être prêt au départ")

	# 1. Vérification du déclenchement du Mega Slam au clavier (Spacebar ou deux touches simultanées)
	print("Test de la commande clavier PC (Action mega_slam / Espace / Flèches simultanées)...")
	Input.action_press(&"mega_slam")
	await get_tree().process_frame
	Input.action_release(&"mega_slam")
	await get_tree().process_frame

	assert(board.mega_slam_controller.is_ready() == false, "MegaSlamController doit s'être déclenché via l'action mega_slam !")

	await get_tree().create_timer(0.08).timeout
	for f in range(4):
		await get_tree().process_frame

	# Vérification de l'allongement des deux batteurs (+42%)
	assert(board.left_gate.scale.x >= 1.35, "Le batteur gauche doit s'allonger pour combler le trou central")
	assert(board.right_gate.scale.x >= 1.35, "Le batteur droit doit s'allonger pour combler le trou central")
	assert(board.left_gate.is_in_mega_slam() == true, "LeftGate doit être en état mega_slam")
	assert(board.right_gate.is_in_mega_slam() == true, "RightGate doit être en état mega_slam")
	print("✓ Extension des flippers validée : scale.x = %.2f (Trou central comblé !)" % board.left_gate.scale.x)

	# Capture 1 : Allongement des batteurs et jauge en décharge
	var tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path1: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/mega_slam_extended_flippers.png"
			img.save_png(path1)
			print("✓ Screenshot 1 (Flippers allongés & Jauge) sauvegardé : ", path1)

	# 2. Test du Super Chain : Transperce les ennemis vers le haut
	print("Création de 3 ennemis en colonne ascendante...")
	var tomato_scene: PackedScene = preload("res://scenes/enemies/enemy_tomato.tscn")
	var enemy1: Enemy = tomato_scene.instantiate() as Enemy
	enemy1.position = Vector2(308.0, 950.0)
	board.enemy_container.add_child(enemy1)

	var enemy2: Enemy = tomato_scene.instantiate() as Enemy
	enemy2.position = Vector2(330.0, 680.0)
	board.enemy_container.add_child(enemy2)

	var enemy3: Enemy = tomato_scene.instantiate() as Enemy
	enemy3.position = Vector2(285.0, 420.0)
	board.enemy_container.add_child(enemy3)

	for f in range(4):
		await get_tree().process_frame

	# Création d'une bille propulsée par le Mega Slam
	var ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
	var ball: Ball = ball_scene.instantiate() as Ball
	ball.position = Vector2(308.0, 1160.0) # Dans le creux central
	board.ball_container.add_child(ball)

	for f in range(2):
		await get_tree().process_frame

	# Activation du Super Chain sur la bille
	ball.enter_super_chain()
	assert(ball.is_super_chain == true, "La bille doit être en mode Super Chain")
	assert(ball.linear_velocity.y < -1500.0, "La bille doit être propulsée à très grande vitesse vers le haut")
	print("✓ Super Chain activé sur la bille : vitesse = %.1f px/s" % ball.linear_velocity.length())

	# Attente de la traversée du premier et deuxième ennemi
	await get_tree().create_timer(0.25).timeout
	for f in range(6):
		await get_tree().process_frame

	# Capture 2 : Bille ardente transperçant les ennemis
	tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path2: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/ball_super_chain_piercing.png"
			img.save_png(path2)
			print("✓ Screenshot 2 (Super Chain en ascension transperçante) sauvegardé : ", path2)

	# Attente que la bille atteigne le sommet du plateau (y <= 95)
	var wait_timeout: float = 0.0
	while ball.is_super_chain and wait_timeout < 1.5:
		await get_tree().process_frame
		wait_timeout += get_process_delta_time()

	await get_tree().create_timer(0.12).timeout
	for f in range(4):
		await get_tree().process_frame

	assert(ball.is_super_chain == false, "La bille doit avoir quitté le Super Chain en franchissant le sommet")
	assert(ball.gravity_scale == 1.0, "La gravité normale doit être rétablie")
	print("✓ Sortie au sommet réussie : la gravité a repris le contrôle et la bille retombe naturellement !")

	# Capture 3 : Bille au sommet retombant naturellement
	tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path3: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/super_chain_apex_exit.png"
			img.save_png(path3)
			print("✓ Screenshot 3 (Sortie au sommet & retombée) sauvegardé : ", path3)

	print("=== TOUS LES TESTS MEGA SLAM & SUPER CHAIN ONT RÉUSSI AVEC SUCCÈS ===")
	get_tree().quit(0)
