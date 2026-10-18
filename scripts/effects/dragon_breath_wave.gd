class_name DragonBreathWave
extends Node2D

## Onde de souffle de dragon circulaire (Dragiburst).
## Naît au-dessus du bonbon et s'étend rapidement vers l'extérieur ("Frouuuuhh").
## Inflige des dégâts d'impact, repousse vers le haut/extérieur et applique le statut Burn.

@export var start_radius: float = 24.0
@export var max_radius: float = 260.0
@export var expansion_time: float = 0.38
@export var impact_damage: int = 2
@export var burn_duration: float = 3.5
@export var burn_damage_per_tick: int = 1
@export var burn_tick_interval: float = 0.5
@export var push_force: float = 450.0

var _current_radius: float = 24.0
var _elapsed_time: float = 0.0
var _alpha: float = 1.0
var _is_finished: bool = false
var _hit_enemies: Dictionary = {} # id -> true

# Couleurs du souffle draconique
const COLOR_CORE: Color = Color(1.0, 0.96, 0.55, 1.0)       # Cœur incandescent doré
const COLOR_FLAME_INNER: Color = Color(1.0, 0.35, 0.05, 1.0) # Flamme orangée vive
const COLOR_FLAME_OUTER: Color = Color(0.92, 0.08, 0.15, 1.0) # Rouge rubis dragon
const COLOR_SMOKE_EDGE: Color = Color(0.45, 0.05, 0.12, 0.0) # Braises / fumée pourpre

static var _pool: Array[DragonBreathWave] = []

static func spawn(
	bumper_node: Node2D,
	offset: Vector2 = Vector2(0.0, -18.0),
	radius: float = 260.0,
	dmg: int = 2,
	b_duration: float = 3.5,
	b_dmg_tick: int = 1
) -> Node2D:
	if bumper_node == null or not bumper_node.is_inside_tree():
		return null

	var wave: DragonBreathWave = null
	while not _pool.is_empty():
		var candidate: DragonBreathWave = _pool.pop_back()
		if is_instance_valid(candidate):
			wave = candidate
			break

	if wave == null:
		wave = DragonBreathWave.new()

	wave.max_radius = radius
	wave.impact_damage = dmg
	wave.burn_duration = b_duration
	wave.burn_damage_per_tick = b_dmg_tick

	if wave.get_parent() != bumper_node:
		if wave.get_parent() != null:
			wave.get_parent().remove_child(wave)
		bumper_node.add_child(wave)

	wave.position = offset
	wave._activate()
	return wave

func _ready() -> void:
	z_index = 25

func _activate() -> void:
	_current_radius = start_radius
	_elapsed_time = 0.0
	_alpha = 1.0
	_is_finished = false
	_hit_enemies.clear()
	visible = true
	set_process(true)
	queue_redraw()

func _recycle() -> void:
	_is_finished = true
	visible = false
	set_process(false)
	if not _pool.has(self):
		_pool.append(self)

func _process(delta: float) -> void:
	if _is_finished:
		return

	_elapsed_time += delta
	var progress: float = clampf(_elapsed_time / expansion_time, 0.0, 1.0)
	
	# Courbe ease-out dynamique : démarre vivement puis ralentit sur le bord extérieur
	var ease_t: float = 1.0 - pow(1.0 - progress, 2.5)
	_current_radius = lerpf(start_radius, max_radius, ease_t)

	# Fondu de fin dans le dernier tiers
	if progress > 0.65:
		_alpha = 1.0 - ((progress - 0.65) / 0.35)
	else:
		_alpha = 1.0

	_detect_and_burn_enemies()
	queue_redraw()

	if progress >= 1.0:
		_recycle()

func _detect_and_burn_enemies() -> void:
	var enemies: Array[Enemy] = Enemy.get_active_enemies()
	var inner_bound: float = maxf(0.0, _current_radius - 55.0)
	var outer_bound: float = _current_radius + 20.0

	for enemy in enemies:
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dying():
			var inst_id: int = enemy.get_instance_id()
			if _hit_enemies.has(inst_id):
				continue

			var dist: float = global_position.distance_to(enemy.global_position)
			if dist >= inner_bound and dist <= outer_bound:
				_hit_enemies[inst_id] = true
				_apply_dragon_hit(enemy)

func _apply_dragon_hit(enemy_node: Node) -> void:
	var to_enemy: Vector2 = (enemy_node.global_position - global_position).normalized()
	if to_enemy == Vector2.ZERO:
		to_enemy = Vector2.UP

	# Répulsion vers l'extérieur et biaisée vers le HAUT pour repousser loin de la danger zone
	var knockback_dir: Vector2 = (to_enemy + Vector2.UP * 0.7).normalized()
	var impulse: Vector2 = knockback_dir * push_force

	# 1. Dégâts d'impact directs
	if enemy_node.has_method(&"take_hit"):
		enemy_node.take_hit(impact_damage, self, impulse)

	# 2. Knockback
	if enemy_node.has_method(&"apply_knockback"):
		enemy_node.apply_knockback(impulse, knockback_dir.angle())

	# 3. Application du statut Burn DoT périodique
	if enemy_node.has_method(&"apply_burn"):
		enemy_node.apply_burn(burn_duration, burn_damage_per_tick, burn_tick_interval)

func _draw() -> void:
	if _current_radius <= 2.0 or _alpha <= 0.0:
		return

	var center: Vector2 = Vector2.ZERO
	var ring_thickness: float = clampf(_current_radius * 0.28, 14.0, 48.0)

	# 1. Halo lumineux diffus arrière (glow rougeoyant)
	var glow_col: Color = Color(COLOR_FLAME_INNER.r, COLOR_FLAME_INNER.g, COLOR_FLAME_INNER.b, _alpha * 0.22)
	draw_circle(center, _current_radius + ring_thickness * 0.5, glow_col)

	# 2. Anneau externe (feu rubis)
	var outer_col: Color = Color(COLOR_FLAME_OUTER.r, COLOR_FLAME_OUTER.g, COLOR_FLAME_OUTER.b, _alpha * 0.75)
	draw_arc(center, _current_radius, 0.0, TAU, 48, outer_col, ring_thickness, true)

	# 3. Anneau médian vif (feu orangé intense)
	var mid_col: Color = Color(COLOR_FLAME_INNER.r, COLOR_FLAME_INNER.g, COLOR_FLAME_INNER.b, _alpha * 0.90)
	draw_arc(center, _current_radius - ring_thickness * 0.2, 0.0, TAU, 40, mid_col, ring_thickness * 0.55, true)

	# 4. Front d'onde ardent incandescent (cœur doré / blanc chaud)
	var core_col: Color = Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, _alpha * 0.95)
	draw_arc(center, _current_radius + 2.0, 0.0, TAU, 36, core_col, 5.0, true)

	# 5. Flammes dentelées le long de la vague (langues de feu procédurales)
	var num_flames: int = 16
	for i in range(num_flames):
		var angle: float = (TAU / float(num_flames)) * float(i) + (_elapsed_time * 4.0)
		var flame_height: float = (12.0 + 8.0 * sin(float(i) * 2.3 + _elapsed_time * 16.0)) * _alpha
		var p_base: Vector2 = center + Vector2(cos(angle), sin(angle)) * _current_radius
		var p_tip: Vector2 = center + Vector2(cos(angle), sin(angle)) * (_current_radius + flame_height)
		var p_left: Vector2 = p_base + Vector2(-sin(angle), cos(angle)) * 6.0
		var p_right: Vector2 = p_base + Vector2(sin(angle), -cos(angle)) * 6.0
		
		var flame_points: PackedVector2Array = PackedVector2Array([p_left, p_tip, p_right])
		var flame_colors: PackedColorArray = PackedColorArray([
			Color(COLOR_FLAME_INNER.r, COLOR_FLAME_INNER.g, COLOR_FLAME_INNER.b, _alpha * 0.8),
			Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, _alpha * 0.9),
			Color(COLOR_FLAME_OUTER.r, COLOR_FLAME_OUTER.g, COLOR_FLAME_OUTER.b, _alpha * 0.6)
		])
		draw_polygon(flame_points, flame_colors)
