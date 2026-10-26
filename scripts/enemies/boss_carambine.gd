class_name CarambineBoss
extends BossEnemy

## Boss Carambine : Étoile fruitée stylée (lunettes étoilées et bandana).
## - Petite taille (légèrement plus grande qu'un ennemi normal).
## - N'entre pas en collision avec les bumpers (traverse librement).
## - Déplacement fluide avec balancement organique (wobble) et inclinaison dynamique.
## - 3 Phases cycliques non liées à ses PV, alternées sans répétition directe :
##   * Phase A : Petits dashs rythmés (2s pause, dash fluide) + Tir d'étoiles filantes parables ultra-visibles.
##   * Phase B : Danse au centre + Invocation échelonnée de sbires (noix de coco, grenade, ananas sur 6s).
##   * Phase C : Squat d'emplacement de bumper (tous les bumpers disparaissent) + Charge 10s en rotation
##     -> Si heurtée par la bille : interrompue, gros dégâts et projection !
##     -> Si ininterrompue : Laser massif vers les portes (lourds dégâts au joueur).
##     -> Les bumpers réapparaissent à la fin.

const StarProjectileScene: PackedScene = preload("res://scenes/effects/carambine_star_projectile.tscn")
const LaserBeamScript = preload("res://scripts/effects/carambine_laser_beam.gd")
const HitstopManagerScript = preload("res://scripts/core/hitstop_manager.gd")

enum Phase {
	PHASE_A_DASH,
	PHASE_B_SUMMON,
	PHASE_C_BUMPER_SQUAT
}

var current_phase: Phase = Phase.PHASE_A_DASH
var _last_phase: Phase = Phase.PHASE_A_DASH
var _phase_progression_index: int = 0

# Cibles de visée des portes
const TARGET_LEFT_GATE: Vector2 = Vector2(175.0, 1185.0)
const TARGET_RIGHT_GATE: Vector2 = Vector2(440.0, 1185.0)
const NEUTRAL_REST_POS: Vector2 = Vector2(360.0, 220.0)

# Paramètres généraux
var _wobble_t: float = 0.0
var _is_performing_action: bool = false
var _phase_timer: float = 0.0

# --- PHASE A : DASHS ET TIRS ÉTOILES ---
var _dash_count: int = 0
var _max_dashes_in_phase: int = 3
var _dash_wait_timer: float = 1.8
var _is_dashing: bool = false
var _current_active_tween: Tween = null

# --- PHASE B : DANSE ET INVOCATION ---
var _dance_timer: float = 0.0
var _summon_step: int = 0
var _summon_timestamps: Array[float] = [1.0, 3.0, 4.8]
var _summon_scenes: Array[String] = [
	"res://scenes/enemies/enemy_coconut.tscn",
	"res://scenes/enemies/enemy_tomato.tscn",
	"res://scenes/enemies/enemy_pomegranate.tscn"
]

# --- PHASE C : SQUAT DE BUMPER & CHARGE LASER ---
const PHASE_C_CHARGE_MAX_TIME: float = 7.0
var _phase_c_charge_timer: float = 0.0
var _phase_c_target_bumper_pos: Vector2 = Vector2.ZERO
var _phase_c_spin_angle: float = 0.0
var _phase_c_interrupted: bool = false
var _phase_c_squatting: bool = false

# Référence au plateau
var _board_ref: Board = null

func _ready() -> void:
	boss_name = "Carambine"
	boss_max_hp = 140
	target_anchor_y = 220.0
	anchors_to_top = false

	super._ready()
	if health_component != null:
		health_component.set_max_health(boss_max_hp)

	position = Vector2(360.0, -120.0)

	_find_board_reference()

	# Descente initiale gracieuse vers son ancre
	var entry_tw: Tween = create_tween()
	entry_tw.tween_property(self, "position", NEUTRAL_REST_POS, 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entry_tw.tween_callback(func() -> void:
		_start_phase(Phase.PHASE_A_DASH)
	)

func _find_board_reference() -> void:
	var cur: Node = get_parent()
	while cur != null:
		if cur is Board:
			_board_ref = cur as Board
			break
		cur = cur.get_parent()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _is_dying or _is_entering:
		return

	_wobble_t += delta

	# Tanguement organique et flottement subtil hors dash
	if current_phase != Phase.PHASE_C_BUMPER_SQUAT and not _is_dashing:
		if visual_container != null:
			visual_container.rotation = sin(_wobble_t * 4.5) * 0.12
			visual_container.position.y = sin(_wobble_t * 3.5) * 5.0

	# Exécution de la phase active
	match current_phase:
		Phase.PHASE_A_DASH:
			_update_phase_a_dash(delta)
		Phase.PHASE_B_SUMMON:
			_update_phase_b_summon(delta)
		Phase.PHASE_C_BUMPER_SQUAT:
			_update_phase_c_bumper_squat(delta)

# ==============================================================================
# GESTION DES CYCLES DE PHASES (NON LIÉES AUX HP, ALTERNANCE SANS RÉPÉTITION)
# ==============================================================================

func _pick_next_phase() -> Phase:
	_phase_progression_index += 1
	if _phase_progression_index == 1:
		return Phase.PHASE_B_SUMMON
	elif _phase_progression_index == 2:
		return Phase.PHASE_C_BUMPER_SQUAT

	# Ensuite : tirage aléatoire dynamique parmi les 2 autres phases
	var choices: Array[Phase] = []
	for p in [Phase.PHASE_A_DASH, Phase.PHASE_B_SUMMON, Phase.PHASE_C_BUMPER_SQUAT]:
		if p != current_phase:
			choices.append(p)
	choices.shuffle()
	return choices[0] if not choices.is_empty() else Phase.PHASE_A_DASH

func _kill_active_tween() -> void:
	if _current_active_tween != null and _current_active_tween.is_valid():
		_current_active_tween.kill()
		_current_active_tween = null

func _start_phase(new_phase: Phase) -> void:
	_kill_active_tween()
	_last_phase = current_phase
	current_phase = new_phase
	_phase_timer = 0.0

	match current_phase:
		Phase.PHASE_A_DASH:
			_dash_count = 0
			_dash_wait_timer = 1.6
			_is_dashing = false

		Phase.PHASE_B_SUMMON:
			_dance_timer = 0.0
			_summon_step = 0
			_move_to_pos_smooth(NEUTRAL_REST_POS, 0.75)

		Phase.PHASE_C_BUMPER_SQUAT:
			_phase_c_charge_timer = 0.0
			_phase_c_spin_angle = 0.0
			_phase_c_interrupted = false
			_phase_c_squatting = false
			_prepare_phase_c_bumper_squat()

# ==============================================================================
# PHASE A : DASHS RYTHMÉS & TIRS ÉTOILES PARABLES
# ==============================================================================

func _update_phase_a_dash(delta: float) -> void:
	if _is_dashing:
		return

	_dash_wait_timer -= delta
	if _dash_wait_timer <= 0.0:
		_execute_dash_and_shoot()

func _execute_dash_and_shoot() -> void:
	_is_dashing = true
	_dash_count += 1
	_kill_active_tween()

	# Choix d'une position cible bien aérée dans les 2/3 hauts de l'arène
	var target_x: float = randf_range(140.0, 580.0)
	var target_y: float = randf_range(160.0, 680.0)
	var target_pos: Vector2 = Vector2(target_x, target_y)

	var dir: Vector2 = (target_pos - position).normalized()
	# Inclinaison stylée dans le sens de la course sans jamais retourner le visage
	var bank_angle: float = clampf(dir.x * 0.22, -0.22, 0.22)

	_current_active_tween = create_tween()

	# 1. Légère anticipation (squash de préparation au bond)
	_current_active_tween.tween_property(visual_container, "scale", Vector2(1.15, 0.85), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Dash fluide et rapide vers la position cible
	_current_active_tween.set_parallel(true)
	_current_active_tween.tween_property(self, "position", target_pos, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_current_active_tween.tween_property(visual_container, "rotation", bank_angle, 0.20)
	_current_active_tween.tween_property(visual_container, "scale", Vector2(0.9, 1.15), 0.20)

	# 3. Réception douce (overshoot élastique)
	_current_active_tween.chain().set_parallel(true)
	_current_active_tween.tween_property(visual_container, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_current_active_tween.tween_property(visual_container, "rotation", 0.0, 0.16)

	_current_active_tween.chain().tween_callback(func() -> void:
		_is_dashing = false
		if visual_container != null:
			visual_container.rotation = 0.0
			visual_container.scale = Vector2.ONE

		# Telegraphe visuel avant tir : éclat scintillant
		_charge_and_shoot_star()
	)

func _charge_and_shoot_star() -> void:
	# Flash d'anticipation avant de lancer le projectile
	var prep_tw: Tween = create_tween()
	prep_tw.tween_property(visual_container, "modulate", Color(2.8, 2.5, 1.2, 1.0), 0.12)
	prep_tw.tween_property(visual_container, "scale", Vector2(1.2, 1.2), 0.12)
	prep_tw.chain().tween_property(visual_container, "modulate", Color.WHITE, 0.10)
	prep_tw.tween_property(visual_container, "scale", Vector2.ONE, 0.10)

	prep_tw.chain().tween_callback(func() -> void:
		_shoot_star_projectile()

		if _dash_count >= _max_dashes_in_phase:
			# Fin de la phase A : transition vers une autre phase
			var wait_tw: Tween = create_tween()
			wait_tw.tween_interval(1.2)
			wait_tw.tween_callback(func() -> void:
				_start_phase(_pick_next_phase())
			)
		else:
			# Prochain dash dans 2 secondes
			_dash_wait_timer = 2.0
	)

func _shoot_star_projectile() -> void:
	var proj: ParryableProjectile = StarProjectileScene.instantiate() as ParryableProjectile
	if proj == null:
		return

	# Cible alternativement la porte gauche ou droite
	var target_gate: Vector2 = TARGET_LEFT_GATE if randf() < 0.5 else TARGET_RIGHT_GATE
	var curve_offset: float = randf_range(-90.0, 90.0)

	var board_parent: Node = get_parent()
	if board_parent != null:
		board_parent.add_child(proj)
		proj.setup_curved(global_position, target_gate, curve_offset, self, 0.88)

# ==============================================================================
# PHASE B : DANSE AU CENTRE & INVOCATION ÉCHELONNÉE
# ==============================================================================

func _update_phase_b_summon(delta: float) -> void:
	_dance_timer += delta

	# Dandinement joyeux et rebond vertical fluide
	position.y = NEUTRAL_REST_POS.y + sin(_dance_timer * 7.5) * 10.0
	if visual_container != null:
		visual_container.rotation = sin(_dance_timer * 6.5) * 0.18

	# Invocations échelonnées sur les 6 secondes
	if _summon_step < _summon_timestamps.size():
		if _dance_timer >= _summon_timestamps[_summon_step]:
			_spawn_summon_minion(_summon_scenes[_summon_step])
			_summon_step += 1

	# Fin de la danse
	if _dance_timer >= 6.2:
		if visual_container != null:
			visual_container.rotation = 0.0
		_start_phase(_pick_next_phase())

func _spawn_summon_minion(scene_path: String) -> void:
	if _board_ref != null and is_instance_valid(_board_ref):
		var spawn_x: float = randf_range(130.0, 590.0)
		_board_ref.spawn_enemy_by_path(scene_path, spawn_x)

	# Pulsation dorée d'invocation
	var tw: Tween = create_tween()
	visual_container.modulate = Color(2.4, 2.0, 2.6, 1.0)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.22)

# ==============================================================================
# PHASE C : SQUAT D'UN BUMPER, DISPARITION DES BUMPERS & CHARGE LASER 10S
# ==============================================================================

func _prepare_phase_c_bumper_squat() -> void:
	# 1. Sélection d'un emplacement de bumper
	var target_slot_pos: Vector2 = _get_target_bumper_slot_position()
	_phase_c_target_bumper_pos = target_slot_pos

	# 2. Déplacement rapide et propre vers le slot
	_kill_active_tween()
	_current_active_tween = create_tween()
	_current_active_tween.tween_property(self, "position", target_slot_pos, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_current_active_tween.tween_callback(func() -> void:
		_phase_c_squatting = true

		# 3. Tous les bumpers disparaissent temporairement
		if _board_ref != null and is_instance_valid(_board_ref):
			_board_ref.hide_all_bumpers_temporarily(true)
	)

func _get_target_bumper_slot_position() -> Vector2:
	if _board_ref != null and is_instance_valid(_board_ref):
		var active_slots: Array = _board_ref.get_occupied_or_active_bumper_slots()
		if not active_slots.is_empty():
			var chosen_slot: BumperSlot = active_slots.pick_random() as BumperSlot
			if chosen_slot != null:
				return chosen_slot.position
		var all_slots: Array = _board_ref.get_bumper_slots()
		if not all_slots.is_empty():
			var chosen: Node2D = all_slots.pick_random() as Node2D
			if chosen != null:
				return chosen.position

	return Vector2(360.0, 480.0)

func _update_phase_c_bumper_squat(delta: float) -> void:
	if not _phase_c_squatting or _phase_c_interrupted:
		return

	_phase_c_charge_timer += delta
	var charge_ratio: float = clampf(_phase_c_charge_timer / PHASE_C_CHARGE_MAX_TIME, 0.0, 1.0)

	# Rotation de charge de plus en plus rapide
	_phase_c_spin_angle += delta * (4.0 + charge_ratio * 28.0)
	if visual_container != null:
		visual_container.rotation = _phase_c_spin_angle

	queue_redraw()

	if _phase_c_charge_timer >= PHASE_C_CHARGE_MAX_TIME:
		_fire_phase_c_laser()

func _fire_phase_c_laser() -> void:
	_phase_c_squatting = false

	# Tir du gros laser dévastateur (25 dégâts au joueur)
	LaserBeamScript.spawn(get_parent(), global_position, 25)

	# Restauration des bumpers
	if _board_ref != null and is_instance_valid(_board_ref):
		_board_ref.hide_all_bumpers_temporarily(false)

	queue_redraw()

	var recover_tw: Tween = create_tween()
	recover_tw.tween_interval(0.8)
	recover_tw.tween_callback(func() -> void:
		_return_to_neutral_and_continue()
	)

func _interrupt_phase_c_by_ball(hit_ctx: HitContext) -> void:
	if _phase_c_interrupted:
		return
	_phase_c_interrupted = true
	_phase_c_squatting = false
	_kill_active_tween()

	# Énorme récompense : 25 points de dégâts sur Carambine
	var interrupt_dmg: int = 25
	if health_component != null:
		health_component.take_damage(interrupt_dmg)
	EventBus.enemy_damaged.emit(self, hit_ctx)
	EventBus.score_changed.emit(750, 750)

	# Micro-gel temporel percutant (Hitstop 60ms)
	HitstopManagerScript.trigger(0.06, 0.04)

	# Restauration immédiate des bumpers
	if _board_ref != null and is_instance_valid(_board_ref):
		_board_ref.hide_all_bumpers_temporarily(false)

	Input.vibrate_handheld(75)
	queue_redraw()

	# Recul spectaculaire vers le haut
	var push_up_y: float = maxf(140.0, position.y - 180.0)
	var recoil_tw: Tween = create_tween().set_parallel(true)
	recoil_tw.tween_property(self, "position:y", push_up_y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recoil_tw.tween_property(visual_container, "rotation", 0.0, 0.25)
	recoil_tw.tween_property(visual_container, "modulate", Color(3.0, 1.5, 1.5, 1.0), 0.12)
	recoil_tw.chain().tween_property(visual_container, "modulate", Color.WHITE, 0.2)

	recoil_tw.chain().tween_callback(func() -> void:
		_return_to_neutral_and_continue()
	)

func _return_to_neutral_and_continue() -> void:
	if visual_container != null:
		visual_container.rotation = 0.0
		visual_container.scale = Vector2.ONE
	queue_redraw()

	_move_to_pos_smooth(NEUTRAL_REST_POS, 0.55, func() -> void:
		var pause_tw: Tween = create_tween()
		pause_tw.tween_interval(0.5)
		pause_tw.tween_callback(func() -> void:
			_start_phase(_pick_next_phase())
		)
	)

# ==============================================================================
# GESTION DES COUPS REÇUS (INTERCEPTION EN PHASE C)
# ==============================================================================

func take_hit_with_context(hit_ctx: HitContext) -> void:
	if _is_dying or _is_expelled or hit_ctx == null:
		return

	if current_phase == Phase.PHASE_C_BUMPER_SQUAT and _phase_c_squatting and not _phase_c_interrupted:
		if hit_ctx.attacker is Ball or hit_ctx.attacker is RigidBody2D:
			_interrupt_phase_c_by_ball(hit_ctx)
			return

	super.take_hit_with_context(hit_ctx)

func _move_to_pos_smooth(target_p: Vector2, duration: float = 0.5, on_complete: Callable = Callable()) -> void:
	_kill_active_tween()
	_current_active_tween = create_tween()
	_current_active_tween.tween_property(self, "position", target_p, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if on_complete.is_valid():
		_current_active_tween.tween_callback(on_complete)

# ==============================================================================
# DESSIN VECTORIEL DES EFFETS D'ÉNERGIE (PHASE C)
# ==============================================================================

func _draw() -> void:
	if current_phase == Phase.PHASE_C_BUMPER_SQUAT and _phase_c_squatting and not _phase_c_interrupted:
		var c: Vector2 = Vector2.ZERO
		var charge_ratio: float = clampf(_phase_c_charge_timer / PHASE_C_CHARGE_MAX_TIME, 0.0, 1.0)
		var aura_radius: float = 48.0 + charge_ratio * 42.0
		var pulse: float = 0.88 + 0.12 * sin(_wobble_t * (10.0 + charge_ratio * 30.0))

		# 1. Aura radiale dorée / magenta
		var aura_col: Color = Color(1.0, 0.85, 0.2, 0.28 + charge_ratio * 0.45)
		draw_circle(c, aura_radius * pulse, aura_col)
		draw_arc(c, aura_radius * pulse, 0.0, TAU, 32, Color(1.0, 0.25, 0.7, 0.75 + charge_ratio * 0.25), 3.5, true)

		# 2. Anneau intérieur de puissance
		var inner_r: float = aura_radius * 0.65 * pulse
		draw_arc(c, inner_r, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.85), 2.5, true)

		# 3. Ligne laser guide vers le bas
		var line_w: float = 2.5 + charge_ratio * 12.0
		var line_alpha: float = 0.25 + charge_ratio * 0.75
		var bottom_y: float = 1200.0 - global_position.y
		draw_line(c, Vector2(0.0, bottom_y), Color(1.0, 0.18, 0.35, line_alpha), line_w)
		draw_line(c, Vector2(0.0, bottom_y), Color(1.0, 0.95, 0.4, line_alpha * 0.85), line_w * 0.5)

func _on_died() -> void:
	if _board_ref != null and is_instance_valid(_board_ref):
		_board_ref.hide_all_bumpers_temporarily(false)
	super._on_died()
