class_name PomegranateBurstWave
extends Node2D

## Onde de déflagration de grenade (Burst de pépins).
## Similaire au souffle Dragiburst, mais avec une projection de grains rubis translucides.
## Inflige des dégâts aux ennemis dans le rayon et les repousse avec force.

@export var start_radius: float = 20.0
@export var max_radius: float = 230.0
@export var expansion_time: float = 0.35
@export var impact_damage: int = 2
@export var push_force: float = 500.0

var _current_radius: float = 20.0
var _elapsed_time: float = 0.0
var _alpha: float = 1.0
var _is_finished: bool = false
var _hit_enemies: Dictionary = {} # id -> true

# Structure de grains de grenade projetés
class PomegranateSeed:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var size: float = 4.0
	var color: Color = Color.WHITE

var _seeds: Array[PomegranateSeed] = []

# Palette rubis / grenade
const COLOR_CORE: Color = Color(1.0, 0.85, 0.90, 1.0)       # Cœur brillant étincelant
const COLOR_RUBY_INNER: Color = Color(0.95, 0.12, 0.28, 1.0) # Rouge rubis vif
const COLOR_POME_OUTER: Color = Color(0.68, 0.04, 0.18, 0.85) # Pourpre profond grenade
const COLOR_SEED: Color = Color(0.92, 0.18, 0.32, 0.95)      # Grains translucides

static var _pool: Array = []

static func spawn(
	parent_node: Node2D,
	spawn_pos: Vector2,
	radius: float = 230.0,
	dmg: int = 2,
	force: float = 500.0
) -> Node2D:
	if parent_node == null or not parent_node.is_inside_tree():
		return null

	var wave: Node2D = null
	while not _pool.is_empty():
		var candidate: Variant = _pool.pop_back()
		if is_instance_valid(candidate) and candidate is Node2D:
			wave = candidate
			break

	if wave == null:
		var wave_script: GDScript = load("res://scripts/effects/pomegranate_burst_wave.gd") as GDScript
		wave = wave_script.new() as Node2D

	wave.set("max_radius", radius)
	wave.set("impact_damage", dmg)
	wave.set("push_force", force)
	wave.global_position = spawn_pos

	if wave.get_parent() != parent_node:
		if wave.get_parent() != null:
			wave.get_parent().remove_child(wave)
		parent_node.add_child(wave)

	wave._reset()
	return wave

func _ready() -> void:
	z_index = 18
	set_process(false)

func _reset() -> void:
	_elapsed_time = 0.0
	_current_radius = start_radius
	_alpha = 1.0
	_is_finished = false
	_hit_enemies.clear()
	_seeds.clear()

	# Génération de 16 à 22 grains de grenade projetés en éventail
	var seed_count: int = randi_range(16, 22)
	for i in range(seed_count):
		var seed_obj: PomegranateSeed = PomegranateSeed.new()
		var angle: float = randf_range(0.0, TAU)
		var speed: float = randf_range(280.0, 560.0)
		seed_obj.pos = Vector2.ZERO
		seed_obj.vel = Vector2(cos(angle), sin(angle)) * speed
		seed_obj.size = randf_range(3.5, 6.0)
		var c_tint: Color = COLOR_SEED.lerp(COLOR_CORE, randf_range(0.0, 0.4))
		seed_obj.color = c_tint
		_seeds.append(seed_obj)

	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if _is_finished:
		return

	_elapsed_time += delta
	var progress: float = clampf(_elapsed_time / expansion_time, 0.0, 1.0)

	# Courbe d'expansion explosive (Ease Out Back / Quartic)
	var ease_prog: float = 1.0 - pow(1.0 - progress, 3.5)
	_current_radius = lerpf(start_radius, max_radius, ease_prog)
	_alpha = 1.0 - pow(progress, 2.0)

	# Mise à jour des grains de grenade
	for s in _seeds:
		s.pos += s.vel * delta
		s.vel *= 0.88 # Forte décélération organique

	_detect_and_damage_enemies()
	queue_redraw()

	if progress >= 1.0:
		_finish()

func _detect_and_damage_enemies() -> void:
	var enemies: Array[Enemy] = Enemy.get_in_radius(global_position, _current_radius + 15.0)
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dying():
			continue

		var enemy_id: int = enemy.get_instance_id()
		if _hit_enemies.has(enemy_id):
			continue

		_hit_enemies[enemy_id] = true

		var to_enemy: Vector2 = enemy.global_position - global_position
		var push_dir: Vector2 = to_enemy.normalized() if to_enemy.length() > 5.0 else Vector2.UP

		# Knockback violent vers l'extérieur
		enemy.apply_knockback(push_dir * push_force, push_dir.angle())

		# Dégâts de souffle
		var ctx: HitContext = HitContext.create(self, enemy, impact_damage, enemy.global_position, push_dir * push_force, HitContext.DamageType.EXPLOSION)
		enemy.take_hit_with_context(ctx)

func _draw() -> void:
	if _is_finished or _alpha <= 0.0:
		return

	# 1. Cœur d'éclair rubis
	var core_col: Color = COLOR_CORE
	core_col.a = _alpha * 0.9
	draw_circle(Vector2.ZERO, _current_radius * 0.28, core_col)

	# 2. Anneau intermédiaire rouge grenade
	var inner_col: Color = COLOR_RUBY_INNER
	inner_col.a = _alpha * 0.75
	draw_arc(Vector2.ZERO, _current_radius * 0.65, 0.0, TAU, 32, inner_col, 8.0 * _alpha)

	# 3. Onde de choc externe
	var outer_col: Color = COLOR_POME_OUTER
	outer_col.a = _alpha * 0.85
	draw_arc(Vector2.ZERO, _current_radius, 0.0, TAU, 48, outer_col, 5.0 * _alpha)

	# 4. Dessin des grains de grenade (pépins rubis)
	for s in _seeds:
		var s_col: Color = s.color
		s_col.a = _alpha
		# Dessin en losange / grain
		draw_circle(s.pos, s.size * _alpha, s_col)
		# Petit point blanc au centre du pépin pour l'éclat translucide
		var white_dot: Color = Color.WHITE
		white_dot.a = _alpha * 0.7
		draw_circle(s.pos, s.size * 0.4 * _alpha, white_dot)

func _finish() -> void:
	_is_finished = true
	set_process(false)
	visible = false
	if get_parent() != null:
		get_parent().remove_child(self)
	if not _pool.has(self):
		_pool.append(self)
