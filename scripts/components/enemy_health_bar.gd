class_name EnemyHealthBar
extends Node2D

## Composant visuel dédié au rendu dynamique de la jauge de points de vie d'un ennemi.
## Affiche un arc de cercle élégant au-dessus du sprite lors des dégâts reçus.

var _enemy: CharacterBody2D = null
var _health_component: HealthComponent = null
var _sprite: Sprite2D = null
var _collision_shape: CollisionShape2D = null

var _hp_ratio: float = 1.0
var _hp_flash_timer: float = 0.0

func setup(
	p_enemy: CharacterBody2D,
	p_health_comp: HealthComponent,
	p_sprite: Sprite2D,
	p_collision_shape: CollisionShape2D
) -> void:
	_enemy = p_enemy
	_health_component = p_health_comp
	_sprite = p_sprite
	_collision_shape = p_collision_shape

	if _health_component != null:
		_health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(cur: int, max_h: int) -> void:
	if max_h > 0:
		_hp_ratio = clampf(float(cur) / float(max_h), 0.0, 1.0)
	else:
		_hp_ratio = 0.0
	_hp_flash_timer = 0.2
	queue_redraw()

func _process(delta: float) -> void:
	if _hp_flash_timer > 0.0:
		_hp_flash_timer = maxf(0.0, _hp_flash_timer - delta)
		if _hp_flash_timer == 0.0:
			queue_redraw()

func _draw() -> void:
	if _enemy == null or _health_component == null:
		return
	if _enemy.has_method(&"is_dying") and _enemy.is_dying():
		return
	if "is_boss" in _enemy and _enemy.is_boss:
		return
	# Affichage uniquement si l'ennemi n'est pas full HP
	if _health_component.current_health >= _health_component.max_health:
		return

	# 1. Calcul dynamique du sommet réel du sprite
	var top_y: float = -34.0
	var half_width: float = 28.0

	if _sprite != null and _sprite.texture != null:
		var tex_size: Vector2 = _sprite.texture.get_size()
		var s_y: float = absf(_sprite.scale.y)
		var s_x: float = absf(_sprite.scale.x)
		var visual_half_h: float = (tex_size.y * s_y) * 0.5
		var visual_half_w: float = (tex_size.x * s_x) * 0.5
		top_y = -visual_half_h
		half_width = clampf(visual_half_w * 0.75, 24.0, 42.0)
	elif _collision_shape != null and _collision_shape.shape != null:
		if _collision_shape.shape is CapsuleShape2D:
			var cap: CapsuleShape2D = _collision_shape.shape as CapsuleShape2D
			top_y = -(cap.height * 0.5)
			half_width = cap.radius + 6.0
		elif _collision_shape.shape is CircleShape2D:
			var circ: CircleShape2D = _collision_shape.shape as CircleShape2D
			top_y = -circ.radius
			half_width = circ.radius + 6.0

	# 2. Centre et courbure de l'arc au-dessus du sprite
	var clearance: float = 12.0
	var arc_radius: float = half_width + 4.0
	var center: Vector2 = Vector2(0.0, (top_y - clearance) + arc_radius)

	var half_span: float = PI * 0.32
	var start_angle: float = -PI * 0.5 - half_span
	var total_span: float = half_span * 2.0
	var end_angle_bg: float = start_angle + total_span
	var end_angle_fg: float = start_angle + total_span * _hp_ratio

	# 3. Contour d'ombre extérieure
	draw_arc(center, arc_radius, start_angle - 0.04, end_angle_bg + 0.04, 26, Color(0.04, 0.02, 0.01, 0.85), 7.0, true)

	# 4. Fond sombre de la piste
	draw_arc(center, arc_radius, start_angle, end_angle_bg, 24, Color(0.18, 0.12, 0.10, 0.90), 5.0, true)

	# 5. Remplissage coloré dynamique (Vert éclatant > Jaune-Orange > Rouge vif)
	var bar_color: Color
	if _hp_flash_timer > 0.0:
		bar_color = Color(1.0, 1.0, 1.0, 1.0)
	elif _hp_ratio > 0.5:
		bar_color = Color(0.30, 0.95, 0.35, 1.0).lerp(Color(1.0, 0.85, 0.18, 1.0), (1.0 - _hp_ratio) * 2.0)
	else:
		bar_color = Color(1.0, 0.85, 0.18, 1.0).lerp(Color(1.0, 0.22, 0.22, 1.0), (0.5 - _hp_ratio) * 2.0)

	if _hp_ratio > 0.01:
		draw_arc(center, arc_radius, start_angle, end_angle_fg, 24, bar_color, 4.0, true)
		var tip_pos: Vector2 = center + Vector2(cos(end_angle_fg), sin(end_angle_fg)) * arc_radius
		draw_circle(tip_pos, 2.2, Color(1.0, 1.0, 1.0, 0.95))
