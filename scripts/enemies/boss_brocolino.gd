class_name BrocolinoBoss
extends BossEnemy

## Boss Brocolino : Colosse végétal défendant la forêt du haut.
## - 200 PV
## - Reste ancré en haut de l'écran à la frontière de la forêt.
## - Possède 3 patterns d'attaque selon la phase + 1 attaque périodique de spores :
##   * Phase 1 (100% -> 67%) : Tir unique parabolique rapide visant alternativement la porte gauche ou droite.
##   * Phase 2 (<= 67%) : Salve en duo (2 tirs brossés en courbe opposée) + Invulnérabilité (3 Bumpers Brocolis).
##   * Phase 3 (<= 33%) : Salve en rafale de 3 tirs courbes successifs (Gauche, Droite, Centre) + Invulnérabilité.
##   * Périodique (Spore Cascade) : Rafale de pluie végétale dispersée.
## - Supporte l'étourdissement (Stun) avec étoiles tournoyantes lors d'une parade parfaite !

const ParryableProjectileScene: PackedScene = preload("res://scenes/effects/parryable_projectile.tscn")

var _remaining_broccoli_bumpers: int = 0
var _phase_67_triggered: bool = false
var _phase_33_triggered: bool = false

var _projectile_timer: float = 2.4
@export var projectile_cooldown: float = 3.6

# Stun d'étourdissement
var _is_stunned: bool = false
var _stun_timer: float = 0.0
var _stun_visual_angle: float = 0.0
var _recent_proj_hits: Array[float] = []

# Pattern périodique spécial
var _special_cascade_timer: float = 9.0

# Positions précises des cibles (centre des portes en bois)
const TARGET_LEFT_GATE: Vector2 = Vector2(175.0, 1185.0)
const TARGET_RIGHT_GATE: Vector2 = Vector2(440.0, 1185.0)
const TARGET_CENTER_GAP: Vector2 = Vector2(308.0, 1185.0)

func _ready() -> void:
	boss_name = "Brocolino"
	boss_max_hp = 200
	target_anchor_y = 165.0
	super._ready()

	position.x = 310.0

## Enregistre les impacts de projectiles réfléchis (3+ en moins de 2s = stun 5s)
func register_reflected_projectile_hit() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_recent_proj_hits.append(now)

	# Nettoie les impacts vieux de plus de 2 secondes
	while _recent_proj_hits.size() > 0 and (now - _recent_proj_hits[0]) > 2.0:
		_recent_proj_hits.pop_front()

	if _recent_proj_hits.size() >= 3:
		_recent_proj_hits.clear()
		apply_boss_stun(5.0)

func apply_boss_stun(duration: float = 2.2) -> void:
	_is_stunned = true
	_stun_timer = duration
	_projectile_timer = maxf(_projectile_timer, duration + 1.2) # Décale les prochaines attaques
	queue_redraw()

	# Animation d'étourdissement : petit affaissement et lueur jaune
	var stun_tw: Tween = create_tween()
	stun_tw.tween_property(visual_container, "position:y", 14.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stun_tw.tween_property(visual_container, "modulate", Color(2.5, 2.5, 1.2, 1.0), 0.12)
	stun_tw.tween_property(visual_container, "modulate", Color.WHITE, 0.2)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _is_dying or _is_entering:
		return

	# Vérifie si le Boss est sous contrôle de foule (Stun ou Gel / Immobilisation)
	var is_cc: bool = _is_stunned or (status_component != null and status_component.is_immobilized())

	# Gestion de l'état étourdi (Stun)
	if _is_stunned:
		_stun_timer -= delta
		_stun_visual_angle += delta * 6.0
		# Tanguement oscillatoire pendant le stun
		if visual_container != null:
			visual_container.rotation = sin(_time_alive * 9.0) * 0.08
		queue_redraw()
		if _stun_timer <= 0.0:
			_is_stunned = false
			if visual_container != null:
				visual_container.rotation = 0.0
			queue_redraw()
			var recover_tw: Tween = create_tween()
			recover_tw.tween_property(visual_container, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)

	# Si le Boss est sous CC (Stun ou Gelée), ses délais d'attaque sont gelés et n'avancent pas !
	if is_cc:
		return

	# Attaque périodique classique selon la phase
	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = randf_range(projectile_cooldown - 0.3, projectile_cooldown + 0.4)
		_execute_phase_attack()

	# Pattern périodique spécial : Cascade de spores
	_special_cascade_timer -= delta
	if _special_cascade_timer <= 0.0:
		_special_cascade_timer = randf_range(11.0, 15.0)
		_execute_cascade_pattern()

func _execute_phase_attack() -> void:
	var hp_ratio: float = float(health_component.current_health) / float(health_component.max_health)

	if hp_ratio > 0.67:
		# PHASE 1 : Tir unique parabolique vif visant une des deux portes
		var use_right: bool = (randf() < 0.5)
		var target: Vector2 = TARGET_RIGHT_GATE if use_right else TARGET_LEFT_GATE
		var curve_curve: float = randf_range(80.0, 130.0) * (-1.0 if use_right else 1.0)
		_spawn_curved_spore(target, curve_curve, 0.85, 0, 1)

	elif hp_ratio > 0.33:
		# PHASE 2 : Duo de spores rapides (gauche puis droite en pince brossée)
		var tw: Tween = create_tween()
		tw.tween_callback(func() -> void: _spawn_curved_spore(TARGET_LEFT_GATE, -100.0, 0.82, 0, 2))
		tw.tween_interval(0.24)
		tw.tween_callback(func() -> void: _spawn_curved_spore(TARGET_RIGHT_GATE, 100.0, 0.82, 1, 2))

	else:
		# PHASE 3 : Rafale en trio (Série de 3 tirs très véloces : Gauche, Droite, Centre)
		var tw: Tween = create_tween()
		tw.tween_callback(func() -> void: _spawn_curved_spore(TARGET_LEFT_GATE, -120.0, 0.76, 0, 3))
		tw.tween_interval(0.20)
		tw.tween_callback(func() -> void: _spawn_curved_spore(TARGET_RIGHT_GATE, 120.0, 0.76, 1, 3))
		tw.tween_interval(0.20)
		tw.tween_callback(func() -> void: _spawn_curved_spore(TARGET_CENTER_GAP, (60.0 if randf() < 0.5 else -60.0), 0.72, 2, 3))

func _execute_cascade_pattern() -> void:
	# Rugissement léger
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "scale", Vector2(1.15, 1.15), 0.12)
	tw.tween_property(visual_container, "scale", Vector2.ONE, 0.15)

	# 2 tirs paraboliques croisés rapides
	tw.tween_callback(func() -> void:
		_spawn_curved_spore(TARGET_RIGHT_GATE, -140.0, 0.88, 0, 2)
		_spawn_curved_spore(TARGET_LEFT_GATE, 140.0, 0.88, 1, 2)
	)

func _spawn_curved_spore(target_dest: Vector2, curve_x: float, duration: float, idx: int, tot: int) -> void:
	if ParryableProjectileScene == null or _is_dying:
		return

	var spore: ParryableProjectile = ParryableProjectileScene.instantiate() as ParryableProjectile
	if spore == null:
		return

	var spawn_pos: Vector2 = global_position + Vector2(randf_range(-25, 25), 50.0)
	spore.setup_curved(spawn_pos, target_dest, curve_x, self, duration, idx, tot)

	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(spore)
	else:
		get_tree().current_scene.add_child(spore)

	# Micro-recul du boss au lancer
	var recoil_tw: Tween = create_tween()
	recoil_tw.tween_property(visual_container, "position:y", -8.0, 0.06)
	recoil_tw.tween_property(visual_container, "position:y", 0.0, 0.10)

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

	_play_summon_roar()

	var spawned: Array[BroccoliBumper] = board.spawn_broccoli_bumpers(3, _on_broccoli_bumper_broken)
	if not spawned.is_empty():
		_remaining_broccoli_bumpers += spawned.size()
		set_invulnerable(true)

func _on_broccoli_bumper_broken(_bumper: BroccoliBumper) -> void:
	_remaining_broccoli_bumpers = maxi(0, _remaining_broccoli_bumpers - 1)

	if _remaining_broccoli_bumpers == 0:
		set_invulnerable(false)
		_play_vulnerability_reaction()

func _play_summon_roar() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "scale", Vector2(1.3, 1.3), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "scale", Vector2.ONE, 0.22)

	JuiceSplatScript.spawn(
		get_parent(),
		global_position + Vector2(0, 40),
		Color(0.2, 0.95, 0.25, 1.0),
		Color(0.4, 1.0, 0.5, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		18
	)

func _play_vulnerability_reaction() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(visual_container, "modulate", Color(3.0, 2.5, 1.0, 1.0), 0.1)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.25)

	# Étourdissement automatique quand le bouclier saute
	apply_boss_stun(2.0)
	Input.vibrate_handheld(40)

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

func _draw() -> void:
	super._draw()

	# Dessin des étoiles de Stun tourbillonnantes au-dessus de Brocolino
	if _is_stunned:
		var center_head: Vector2 = Vector2(0.0, -100.0)
		var star_radius: float = 38.0
		for i in range(3):
			var a: float = _stun_visual_angle + float(i) * (TAU / 3.0)
			var star_pos: Vector2 = center_head + Vector2(cos(a) * star_radius, sin(a) * (star_radius * 0.4))
			# Petite étoile dorée
			draw_circle(star_pos, 5.0, Color(1.0, 0.92, 0.2, 0.95))
			draw_circle(star_pos, 2.5, Color.WHITE)
			draw_line(star_pos - Vector2(7, 0), star_pos + Vector2(7, 0), Color(1.0, 0.9, 0.3, 0.8), 2.0)
			draw_line(star_pos - Vector2(0, 7), star_pos + Vector2(0, 7), Color(1.0, 0.9, 0.3, 0.8), 2.0)
