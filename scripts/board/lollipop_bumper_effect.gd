class_name LollipopBumperEffect
extends BumperEffect

## Stratégie d'effet du Bumper Légendaire Sucette (Twistypop).
## Quand le bumper est tapé par la bille, il projette une salve d'éclats magiques
## de couleurs aléatoires qui traquent les ennemis sur le terrain.
## Le nombre d'éclats évolue selon le niveau : 2 au niveau 1 jusqu'à 10 au niveau 5.

const CandyShardScript = preload("res://scripts/effects/candy_shard_projectile.gd")

@export var shard_damage: int = 1
@export var base_shards: int = 2
@export var shards_per_level: int = 2

# Palette arc-en-ciel néon & gourmande pour les éclats
const RAINBOW_SHARD_COLORS: Array[Color] = [
	Color(1.0, 0.15, 0.25, 1.0), # Fraise acidulée
	Color(1.0, 0.52, 0.05, 1.0), # Orangeade
	Color(1.0, 0.92, 0.05, 1.0), # Citron étincelant
	Color(0.20, 0.92, 0.35, 1.0), # Pomme verte
	Color(0.05, 0.82, 0.98, 1.0), # Curaçao / Cyan
	Color(0.22, 0.48, 1.0, 1.0), # Myrtille royale
	Color(0.72, 0.18, 0.95, 1.0), # Violet mûre
	Color(1.0, 0.28, 0.72, 1.0), # Framboise rose
]

func execute(bumper: Node2D) -> void:
	if bumper == null or not bumper.is_inside_tree():
		return

	# 1. Détermination du niveau effectif de la carte
	var lvl: int = 1
	if bumper is CandyBumper:
		lvl = (bumper as CandyBumper).current_level
	if lvl <= 0:
		var st: Dictionary = SaveManager.get_card_state(&"twistypop")
		lvl = st.get("level", 1)

	# Formule stricte : 2 au niveau 1, 10 au niveau 5
	var shard_count: int = base_shards + (clampi(lvl, 1, 5) - 1) * shards_per_level

	# 2. Recensement des ennemis vivants
	var alive_enemies: Array[Enemy] = []
	for e in Enemy.get_active_enemies():
		if e != null and is_instance_valid(e) and not e.is_dying():
			alive_enemies.append(e)

	# 3. Projection des éclats multicolores
	var parent_node: Node = bumper.get_parent()
	if parent_node == null:
		parent_node = bumper

	for i in range(shard_count):
		# Cible ennemie aléatoire parmi les survivants
		var target: Node2D = alive_enemies.pick_random() if not alive_enemies.is_empty() else null
		
		# Répartition radiale harmonieuse avec léger bruit
		var angle_step: float = TAU / float(maxi(1, shard_count))
		var burst_angle: float = float(i) * angle_step + randf_range(-0.18, 0.18)
		var shard_color: Color = RAINBOW_SHARD_COLORS.pick_random()

		CandyShardScript.spawn(
			parent_node,
			bumper.global_position,
			target,
			shard_color,
			shard_damage,
			burst_angle
		)

	# 4. Feedback visuel et haptique
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(25)
