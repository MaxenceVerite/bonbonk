class_name BrocolinoBoss
extends BossEnemy

## Boss Brocolino : Colosse végétal défendant la forêt du haut.
## - 200 PV
## - Reste ancré en haut de l'écran à la frontière de la forêt.
## - Tous les 33% de PV perdus (à 134 PV et 67 PV), invoque 3 Bumpers Brocolis sur le plateau
##   et devient totalement INVULNÉRABLE tant qu'au moins 1 bumper subsiste.
## - Tire périodiquement des spores parables vers les batteurs que le joueur peut renvoyer pour lui infliger des dégâts.

const ParryableProjectileScene: PackedScene = preload("res://scenes/effects/parryable_projectile.tscn")

var _remaining_broccoli_bumpers: int = 0
var _phase_67_triggered: bool = false
var _phase_33_triggered: bool = false

var _projectile_timer: float = 2.5 # Premier tir après 2.5s
@export var projectile_cooldown: float = 3.8

func _ready() -> void:
	boss_name = "Brocolino"
	boss_max_hp = 200
	target_anchor_y = 165.0
	super._ready()

	# Brocolino commence au centre horizontal de l'arène
	position.x = 310.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _is_dying or _is_entering:
		return

	# Cadence de tir des projectiles parables
	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = randf_range(projectile_cooldown - 0.4, projectile_cooldown + 0.6)
		_fire_parryable_spore()

func _on_health_changed(cur: int, max_h: int) -> void:
	super._on_health_changed(cur, max_h)

	if _is_dying:
		return

	# Seuil 1 : <= 67% des PV (134 PV)
	if not _phase_67_triggered and cur <= int(max_h * 0.67):
		_phase_67_triggered = true
		_trigger_broccoli_summon_phase()

	# Seuil 2 : <= 33% des PV (67 PV)
	elif not _phase_33_triggered and cur <= int(max_h * 0.33):
		_phase_33_triggered = true
		_trigger_broccoli_summon_phase()

func _trigger_broccoli_summon_phase() -> void:
	var board: Board = _find_board()
	if board == null:
		return

	# Animation d'incantation dramatique du Boss
	_play_summon_roar()

	# Apparition de 3 bumpers brocolis
	var spawned: Array[BroccoliBumper] = board.spawn_broccoli_bumpers(3, _on_broccoli_bumper_broken)
	if not spawned.is_empty():
		_remaining_broccoli_bumpers += spawned.size()
		set_invulnerable(true)

func _on_broccoli_bumper_broken(_bumper: BroccoliBumper) -> void:
	_remaining_broccoli_bumpers = maxi(0, _remaining_broccoli_bumpers - 1)

	# Si tous les bumpers brocolis ont été éliminés, le Boss redevient vulnérable
	if _remaining_broccoli_bumpers == 0:
		set_invulnerable(false)
		# Étourdissement / vulnérabilité du boss
		_play_vulnerability_reaction()

func _play_summon_roar() -> void:
	# Rugissement visuel : gonflement et onde verte
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "scale", Vector2(1.3, 1.3), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "scale", Vector2.ONE, 0.22)

	# Éclat vert de nature
	JuiceSplatScript.spawn(
		get_parent(),
		global_position + Vector2(0, 40),
		Color(0.2, 0.95, 0.25, 1.0),
		Color(0.4, 1.0, 0.5, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		16
	)

func _play_vulnerability_reaction() -> void:
	# Le bouclier se brise : flash doré et tremblement
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "modulate", Color(3.0, 2.5, 1.0, 1.0), 0.1)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.25)

	Input.vibrate_handheld(35)

func _fire_parryable_spore() -> void:
	if ParryableProjectileScene == null:
		return

	var spore: ParryableProjectile = ParryableProjectileScene.instantiate() as ParryableProjectile
	if spore == null:
		return

	# Origine : bouche / base de Brocolino
	var spawn_pos: Vector2 = global_position + Vector2(randf_range(-30, 30), 45.0)

	# Cible : alterne aléatoirement entre le batteur gauche, le batteur droit et le centre
	var target_choice: int = randi() % 3
	var target_x: float = 140.0 if target_choice == 0 else (476.0 if target_choice == 1 else 308.0)
	var target_pos: Vector2 = Vector2(target_x, 1180.0)

	spore.setup(spawn_pos, target_pos, self)

	# Ajout à l'arène (au parent ou au Board)
	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(spore)
	else:
		get_tree().current_scene.add_child(spore)

	# Petit recul du boss au tir
	var recoil_tw: Tween = create_tween()
	recoil_tw.tween_property(visual_container, "position:y", -10.0, 0.08)
	recoil_tw.tween_property(visual_container, "position:y", 0.0, 0.12)

func _find_board() -> Board:
	var cur: Node = get_parent()
	while cur != null:
		if cur is Board:
			return cur as Board
		cur = cur.get_parent()
	return get_tree().get_first_node_in_group(&"board") as Board

func _on_died() -> void:
	var board: Board = _find_board()
	if board != null:
		board.restore_temporary_bumper_overrides()
	super._on_died()
