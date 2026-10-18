class_name StatusVisualOverlay
extends Node2D

## Superposition visuelle pour les altérations d'état (Brûlure, Gel, Étourdissement électrique).
## Rendu vectoriel pur via _draw() : 0 allocation par frame, 60/120 FPS garanti sur mobile.
## Se désactive automatiquement (0 CPU, 0 Draw Call) quand aucun statut n'est actif.

# Références
var _target_enemy: CharacterBody2D = null
var _target_sprite: Sprite2D = null

# États actifs
var _is_burning: bool = false
var _is_frozen: bool = false
var _is_stunned: bool = false

# Dimensions de l'entité
var _half_w: float = 24.0
var _half_h: float = 28.0

# Animation timers
var _anim_time: float = 0.0
var _zap_timer: float = 0.0

# Buffers pré-alloués pour les braises (Burn) - 0 allocation en runtime
const EMBER_COUNT: int = 7
var _ember_pos_x: PackedFloat32Array = PackedFloat32Array()
var _ember_pos_y: PackedFloat32Array = PackedFloat32Array()
var _ember_speed: PackedFloat32Array = PackedFloat32Array()
var _ember_phase: PackedFloat32Array = PackedFloat32Array()
var _ember_life: PackedFloat32Array = PackedFloat32Array()
var _ember_max_life: PackedFloat32Array = PackedFloat32Array()
var _ember_size: PackedFloat32Array = PackedFloat32Array()

# Buffers pour les arcs électriques (Stun)
var _arc1_points: PackedVector2Array = PackedVector2Array()
var _arc2_points: PackedVector2Array = PackedVector2Array()
var _sparks: PackedVector2Array = PackedVector2Array()

# Buffers pour les facettes de glace (Freeze)
var _ice_polygons: Array[PackedVector2Array] = []
var _ice_lines: Array[PackedVector2Array] = []
var _ice_spikes: Array[PackedVector2Array] = []

# Éclats de bris de glace (Shatter FX)
var _is_shattering: bool = false
var _shatter_timer: float = 0.0
const SHARD_COUNT: int = 8
var _shard_pos: PackedVector2Array = PackedVector2Array()
var _shard_vel: PackedVector2Array = PackedVector2Array()
var _shard_rot: PackedFloat32Array = PackedFloat32Array()
var _shard_rot_speed: PackedFloat32Array = PackedFloat32Array()

func _init() -> void:
	z_index = 5
	z_as_relative = true
	visible = false
	set_process(false)
	_init_ember_buffers()
	_init_shatter_buffers()

func setup(enemy: CharacterBody2D, sprite_node: Sprite2D = null) -> void:
	_target_enemy = enemy
	_target_sprite = sprite_node
	_update_bounds()
	_build_ice_geometry()

func _update_bounds() -> void:
	if _target_sprite != null and _target_sprite.texture != null:
		var tex_sz: Vector2 = _target_sprite.texture.get_size()
		_half_w = clampf((tex_sz.x * absf(_target_sprite.scale.x)) * 0.5, 18.0, 50.0)
		_half_h = clampf((tex_sz.y * absf(_target_sprite.scale.y)) * 0.5, 20.0, 55.0)
	else:
		_half_w = 24.0
		_half_h = 28.0

func _init_ember_buffers() -> void:
	_ember_pos_x.resize(EMBER_COUNT)
	_ember_pos_y.resize(EMBER_COUNT)
	_ember_speed.resize(EMBER_COUNT)
	_ember_phase.resize(EMBER_COUNT)
	_ember_life.resize(EMBER_COUNT)
	_ember_max_life.resize(EMBER_COUNT)
	_ember_size.resize(EMBER_COUNT)

	for i in range(EMBER_COUNT):
		_reset_ember(i, true)

func _reset_ember(i: int, randomize_y: bool = false) -> void:
	var spread_x: float = _half_w * 0.85
	_ember_pos_x[i] = randf_range(-spread_x, spread_x)
	var bottom_y: float = _half_h * 0.85
	if randomize_y:
		_ember_pos_y[i] = randf_range(-_half_h * 0.5, bottom_y)
	else:
		_ember_pos_y[i] = bottom_y + randf_range(-3.0, 5.0)

	_ember_speed[i] = randf_range(60.0, 110.0)
	_ember_phase[i] = randf_range(0.0, TAU)
	var ml: float = randf_range(0.5, 0.9)
	_ember_max_life[i] = ml
	_ember_life[i] = ml if not randomize_y else randf_range(0.1, ml)
	_ember_size[i] = randf_range(2.0, 4.0)

func _init_shatter_buffers() -> void:
	_shard_pos.resize(SHARD_COUNT)
	_shard_vel.resize(SHARD_COUNT)
	_shard_rot.resize(SHARD_COUNT)
	_shard_rot_speed.resize(SHARD_COUNT)

func _build_ice_geometry() -> void:
	_ice_polygons.clear()
	_ice_lines.clear()
	_ice_spikes.clear()

	var w: float = _half_w * 1.15
	var h: float = _half_h * 1.15

	# Points caractéristiques de la coquille cristalline (enveloppe facettée)
	var p_top: Vector2 = Vector2(randf_range(-3.0, 3.0), -h - 4.0)
	var p_tr: Vector2 = Vector2(w * 0.9, -h * 0.6)
	var p_br: Vector2 = Vector2(w * 0.95, h * 0.65)
	var p_bot: Vector2 = Vector2(randf_range(-4.0, 4.0), h + 4.0)
	var p_bl: Vector2 = Vector2(-w * 0.95, h * 0.65)
	var p_tl: Vector2 = Vector2(-w * 0.9, -h * 0.6)
	var p_center: Vector2 = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))

	# Facettes triangulaires translucides
	_ice_polygons.append(PackedVector2Array([p_top, p_tr, p_center]))
	_ice_polygons.append(PackedVector2Array([p_tr, p_br, p_center]))
	_ice_polygons.append(PackedVector2Array([p_br, p_bot, p_center]))
	_ice_polygons.append(PackedVector2Array([p_bot, p_bl, p_center]))
	_ice_polygons.append(PackedVector2Array([p_bl, p_tl, p_center]))
	_ice_polygons.append(PackedVector2Array([p_tl, p_top, p_center]))

	# Arêtes internes contrastées pour effet bijou / réfraction
	_ice_lines.append(PackedVector2Array([p_top, p_center]))
	_ice_lines.append(PackedVector2Array([p_tr, p_center]))
	_ice_lines.append(PackedVector2Array([p_br, p_center]))
	_ice_lines.append(PackedVector2Array([p_bot, p_center]))
	_ice_lines.append(PackedVector2Array([p_bl, p_center]))
	_ice_lines.append(PackedVector2Array([p_tl, p_center]))

	# Pointes de glace externes (Spikes) acérées
	_ice_spikes.append(PackedVector2Array([
		Vector2(-w * 0.8, -h * 0.3),
		Vector2(-w * 1.45, -h * 0.4),
		Vector2(-w * 0.7, -h * 0.55)
	]))
	_ice_spikes.append(PackedVector2Array([
		Vector2(w * 0.8, -h * 0.2),
		Vector2(w * 1.5, -h * 0.3),
		Vector2(w * 0.75, -h * 0.45)
	]))
	_ice_spikes.append(PackedVector2Array([
		Vector2(-w * 0.2, -h - 2.0),
		Vector2(0.0, -h - 14.0),
		Vector2(w * 0.25, -h - 2.0)
	]))

func sync_status(burning: bool, frozen: bool, stunned: bool) -> void:
	var was_frozen: bool = _is_frozen
	_is_burning = burning
	_is_frozen = frozen
	_is_stunned = stunned

	# Si le gel vient de se terminer ou d'être brisé, déclenche l'éclat de glace
	if was_frozen and not frozen:
		trigger_ice_shatter()

	var needs_process: bool = _is_burning or _is_frozen or _is_stunned or _is_shattering
	visible = needs_process
	set_process(needs_process)
	if needs_process:
		queue_redraw()

func trigger_ice_shatter() -> void:
	_is_shattering = true
	_shatter_timer = 0.28
	for i in range(SHARD_COUNT):
		var ang: float = randf_range(0.0, TAU)
		var spd: float = randf_range(160.0, 320.0)
		_shard_pos[i] = Vector2(cos(ang), sin(ang)) * randf_range(4.0, 18.0)
		_shard_vel[i] = Vector2(cos(ang), sin(ang)) * spd
		_shard_rot[i] = randf_range(0.0, TAU)
		_shard_rot_speed[i] = randf_range(-14.0, 14.0)

	visible = true
	set_process(true)
	queue_redraw()

func reset() -> void:
	_is_burning = false
	_is_frozen = false
	_is_stunned = false
	_is_shattering = false
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	_anim_time += delta

	if _is_burning:
		_process_burn(delta)

	if _is_stunned:
		_process_stun(delta)

	if _is_shattering:
		_shatter_timer -= delta
		for i in range(SHARD_COUNT):
			_shard_pos[i] += _shard_vel[i] * delta
			_shard_rot[i] += _shard_rot_speed[i] * delta
		if _shatter_timer <= 0.0:
			_is_shattering = false
			if not _is_burning and not _is_frozen and not _is_stunned:
				visible = false
				set_process(false)

	queue_redraw()

func _process_burn(delta: float) -> void:
	for i in range(EMBER_COUNT):
		_ember_life[i] -= delta
		if _ember_life[i] <= 0.0:
			_reset_ember(i, false)
			continue

		_ember_pos_y[i] -= _ember_speed[i] * delta
		var sway: float = sin(_anim_time * 7.0 + _ember_phase[i]) * 18.0
		_ember_pos_x[i] += sway * delta

		# Disparition si trop haut
		if _ember_pos_y[i] < -_half_h - 16.0:
			_reset_ember(i, false)

func _process_stun(delta: float) -> void:
	_zap_timer -= delta
	if _zap_timer <= 0.0:
		_zap_timer = 0.05 # 20 Hz flicker pour dynamisme électrique intense
		_generate_zap_arcs()

func _generate_zap_arcs() -> void:
	_arc1_points.clear()
	_arc2_points.clear()
	_sparks.clear()

	# Arc 1 : traverse en diagonale
	var p_start: Vector2 = Vector2(-_half_w * randf_range(0.7, 1.0), -_half_h * randf_range(0.5, 0.9))
	var p_end: Vector2 = Vector2(_half_w * randf_range(0.6, 0.95), _half_h * randf_range(0.5, 0.9))
	_arc1_points.append(p_start)
	var steps: int = 4
	for s in range(1, steps):
		var t: float = float(s) / float(steps)
		var pt: Vector2 = p_start.lerp(p_end, t) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		_arc1_points.append(pt)
	_arc1_points.append(p_end)

	# Arc 2 : transversal court
	var p2_start: Vector2 = Vector2(_half_w * randf_range(0.4, 0.9), -_half_h * randf_range(0.2, 0.6))
	var p2_end: Vector2 = Vector2(-_half_w * randf_range(0.4, 0.8), _half_h * randf_range(0.1, 0.5))
	_arc2_points.append(p2_start)
	for s in range(1, 3):
		var t2: float = float(s) / 3.0
		var pt2: Vector2 = p2_start.lerp(p2_end, t2) + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		_arc2_points.append(pt2)
	_arc2_points.append(p2_end)

	# 3 étincelles périphériques
	for k in range(3):
		var ang: float = randf_range(0.0, TAU)
		var dist: float = randf_range(_half_w * 0.8, _half_w * 1.3)
		_sparks.append(Vector2(cos(ang) * dist, sin(ang) * dist * 1.1))

func _draw() -> void:
	if _is_burning:
		_draw_burn()

	if _is_frozen:
		_draw_freeze()

	if _is_stunned:
		_draw_stun()

	if _is_shattering:
		_draw_shatter()

func _draw_burn() -> void:
	# 1. Halo incandescant à la base
	var bottom_center: Vector2 = Vector2(0.0, _half_h * 0.75)
	var pulse: float = 0.8 + 0.2 * sin(_anim_time * 10.0)
	draw_circle(bottom_center, _half_w * 0.9 * pulse, Color(1.0, 0.35, 0.05, 0.22))
	draw_circle(bottom_center, _half_w * 0.55 * pulse, Color(1.0, 0.75, 0.15, 0.35))

	# 2. Braises montantes
	for i in range(EMBER_COUNT):
		var life_ratio: float = clampf(_ember_life[i] / _ember_max_life[i], 0.0, 1.0)
		var alpha: float = sin(life_ratio * PI) # Fondu apparition puis disparition douce
		var pos: Vector2 = Vector2(_ember_pos_x[i], _ember_pos_y[i])
		var sz: float = _ember_size[i] * (0.5 + 0.5 * life_ratio)

		# Cœur jaune brûlant + contour orange vif
		var color_outer: Color = Color(1.0, 0.32, 0.05, alpha * 0.9)
		var color_inner: Color = Color(1.0, 0.95, 0.5, alpha)

		draw_circle(pos, sz, color_outer)
		draw_circle(pos, sz * 0.5, color_inner)

func _draw_freeze() -> void:
	# 1. Facettes translucides de glace
	var facet_colors: Array[Color] = [
		Color(0.55, 0.85, 1.0, 0.42),
		Color(0.68, 0.92, 1.0, 0.35),
		Color(0.50, 0.80, 0.98, 0.45),
		Color(0.60, 0.88, 1.0, 0.38),
		Color(0.52, 0.82, 0.99, 0.44),
		Color(0.70, 0.94, 1.0, 0.36)
	]

	for i in range(_ice_polygons.size()):
		var poly: PackedVector2Array = _ice_polygons[i]
		var col: Color = facet_colors[i % facet_colors.size()]
		draw_colored_polygon(poly, col)

	# 2. Spikes de givre
	for spike in _ice_spikes:
		draw_colored_polygon(spike, Color(0.75, 0.94, 1.0, 0.65))
		draw_polyline(spike, Color(0.95, 0.98, 1.0, 0.9), 1.6, true)

	# 3. Arêtes tranchantes blanches réfringentes
	for line in _ice_lines:
		draw_polyline(line, Color(0.85, 0.96, 1.0, 0.75), 1.4, true)

	# 4. Éclat spéculaire diagonal (balayage lumineux)
	var sweep_period: float = 1.3
	var sweep_t: float = fmod(_anim_time, sweep_period) / sweep_period
	if sweep_t < 0.45:
		var gleam_ratio: float = sweep_t / 0.45
		var gleam_x: float = lerpf(-_half_w * 1.2, _half_w * 1.2, gleam_ratio)
		var gleam_p1: Vector2 = Vector2(gleam_x - 10.0, -_half_h)
		var gleam_p2: Vector2 = Vector2(gleam_x + 10.0, _half_h)
		draw_line(gleam_p1, gleam_p2, Color(1.0, 1.0, 1.0, 0.55 * sin(gleam_ratio * PI)), 2.5)

func _draw_stun() -> void:
	# 1. Arc principal 1 (Halo néon cyan + cœur blanc chaud)
	if _arc1_points.size() > 1:
		draw_polyline(_arc1_points, Color(0.2, 0.85, 1.0, 0.95), 3.4, true)
		draw_polyline(_arc1_points, Color(1.0, 1.0, 1.0, 1.0), 1.4, true)

	# 2. Arc secondaire 2
	if _arc2_points.size() > 1:
		draw_polyline(_arc2_points, Color(0.3, 0.95, 1.0, 0.85), 2.6, true)
		draw_polyline(_arc2_points, Color(1.0, 1.0, 1.0, 0.95), 1.1, true)

	# 3. Étincelles électriques
	for spk in _sparks:
		draw_circle(spk, 2.2, Color(0.4, 0.95, 1.0, 0.9))
		draw_circle(spk, 1.1, Color(1.0, 1.0, 1.0, 1.0))

func _draw_shatter() -> void:
	var progress: float = clampf(1.0 - (_shatter_timer / 0.28), 0.0, 1.0)
	var alpha: float = (1.0 - progress) * 0.9
	var col_fill: Color = Color(0.7, 0.92, 1.0, alpha * 0.6)
	var col_edge: Color = Color(1.0, 1.0, 1.0, alpha)

	for i in range(SHARD_COUNT):
		var p: Vector2 = _shard_pos[i]
		var r: float = _shard_rot[i]
		var sz: float = 5.0 * (1.0 - progress * 0.3)
		var v1: Vector2 = p + Vector2(cos(r), sin(r)) * sz
		var v2: Vector2 = p + Vector2(cos(r + 2.1), sin(r + 2.1)) * (sz * 0.7)
		var v3: Vector2 = p + Vector2(cos(r + 4.2), sin(r + 4.2)) * sz
		var poly: PackedVector2Array = PackedVector2Array([v1, v2, v3])
		draw_colored_polygon(poly, col_fill)
		draw_polyline(poly, col_edge, 1.2, true)
