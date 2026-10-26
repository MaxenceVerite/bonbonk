extends Node

## Test de validation unitaire et fonctionnelle pour le Boss Carambine

const CarambineScene: PackedScene = preload("res://scenes/enemies/boss_carambine.tscn")
const StarProjectileScene: PackedScene = preload("res://scenes/effects/carambine_star_projectile.tscn")
const LaserBeamScript = preload("res://scripts/effects/carambine_laser_beam.gd")
const BoardScene: PackedScene = preload("res://scenes/board/board.tscn")
const CarambineScript = preload("res://scripts/enemies/boss_carambine.gd")
const StarProjectileScript = preload("res://scripts/effects/carambine_star_projectile.gd")

func _ready() -> void:
	print("\n=== TEST DE VALIDATION DU BOSS CARAMBINE ===")

	# 1. Validation de la scène et des paramètres
	var carambine: BossEnemy = CarambineScene.instantiate() as BossEnemy
	assert(carambine != null, "Impossible d'instancier Boss Carambine")
	assert(carambine.boss_name == "Carambine", "Le nom du boss doit être Carambine")
	assert(carambine.boss_max_hp == 140, "Les PV max doivent être de 140")
	print("✓ 1. Instanciation et stats de Carambine validées (140 HP)")

	# 2. Validation des couches de collision (Non-collision avec les bumpers)
	# Layer 4 (Enemies) = 8
	assert(carambine.collision_layer == 8, "Collision layer doit être 8 (Enemies)")
	# Mask 7 = Ball (1) + Flippers (2) + Walls (4). DOIT EXCLURE Bumpers (16)
	assert((carambine.collision_mask & 16) == 0, "Carambine ne doit PAS entrer en collision avec le Layer 5 (Bumpers) !")
	print("✓ 2. Couches physiques validées : traverse les bumpers sans collision (mask & 16 == 0)")

	# 3. Test du projectile étoile parable
	var star_proj: ParryableProjectile = StarProjectileScene.instantiate() as ParryableProjectile
	assert(star_proj != null, "Impossible d'instancier CarambineStarProjectile")
	assert(star_proj.flight_duration <= 0.95, "Le projectile doit avoir une trajectoire rapide et lisible")
	star_proj.setup_curved(Vector2(360, 200), Vector2(175, 1185), 0.0, carambine, 0.88)
	assert(star_proj.target_boss == carambine, "La cible de retour doit être Carambine")
	star_proj.queue_free()
	print("✓ 3. Projectile étoile star-shooting rapide et lisible validé (flight_duration <= 0.95s)")

	# 4. Test d'interruption en Phase C par une bille
	add_child(carambine)
	carambine.call(&"_start_phase", 2) # Phase.PHASE_C_BUMPER_SQUAT = 2
	assert(carambine.get(&"current_phase") == 2, "Carambine doit être en Phase C")

	# Simulation de l'état squatting actif
	carambine.set(&"_phase_c_squatting", true)
	var dummy_ball: RigidBody2D = RigidBody2D.new()
	var hit_ctx: HitContext = HitContext.create(dummy_ball, carambine, 1, carambine.global_position, Vector2(0, -600))
	var initial_hp: int = carambine.health_component.current_health
	carambine.take_hit_with_context(hit_ctx)

	assert(carambine.get(&"_phase_c_interrupted") == true, "La Phase C doit être interrompue suite au choc de la bille")
	assert(carambine.health_component.current_health == initial_hp - 25, "L'interruption doit infliger 25 points de dégâts")
	print("✓ 4. Interruption de la Phase C par balle de flipper validée (subit 25 dégâts et projection)")

	# 5. Test du masquage temporaire des bumpers sur le plateau
	var board: Board = BoardScene.instantiate() as Board
	add_child(board)
	board.hide_all_bumpers_temporarily(true)
	# Vérifie que les slots de bumpers sont bien masqués
	for slot in board.get_bumper_slots():
		if slot is BumperSlot:
			assert(slot.get(&"_is_hidden_temporarily") == true, "Le slot doit être marqué comme masqué temporairement")

	board.hide_all_bumpers_temporarily(false)
	for slot in board.get_bumper_slots():
		if slot is BumperSlot:
			assert(slot.get(&"_is_hidden_temporarily") == false, "Le slot doit être restauré")
	print("✓ 5. Masquage et réapparition dynamique des bumpers du plateau validés")

	# Nettoyage
	dummy_ball.queue_free()
	carambine.queue_free()
	board.queue_free()

	print("\n>>> TOUS LES TESTS DU BOSS CARAMBINE SONT VALIDÉS AVEC SUCCÈS ! <<<")
	get_tree().quit()
