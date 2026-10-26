class_name CarambineLaserBeam
extends Node2D

## Faisceau laser destructeur tiré par la Boss Carambine en Phase C si elle n'est pas interrompue.
## Traverse verticalement toute l'arène jusqu'aux portes en bas et inflige de lourds dégâts au joueur.

const JuiceSplatScript = preload("res://scripts/effects/juice_splat.gd")

@export var damage_to_player: int = 25
@export var beam_duration: float = 0.85
@export var target_gate_y: float = 1220.0

var _time_alive: float = 0.0
var _beam_width: float = 75.0
var _has_dealt_damage: bool = false
var start_pos: Vector2 = Vector2.ZERO

static func spawn(parent: Node, origin_pos: Vector2, damage: int = 25) -> Node2D:
	var beam: Node2D = new()
	beam.set(&"start_pos", origin_pos)
	beam.global_position = origin_pos
	beam.set(&"damage_to_player", damage)
	parent.add_child(beam)
	return beam

func _ready() -> void:
	z_index = 25
	_trigger_impact_effects()

func _trigger_impact_effects() -> void:
	if _has_dealt_damage:
		return
	_has_dealt_damage = true

	# Dégât lourd direct sur la défense du joueur
	EventBus.enemy_escaped.emit(damage_to_player)

	# Puissant retour haptique
	Input.vibrate_handheld(90)

	# Éclaboussures d'énergie aux portes
	var impact_pt: Vector2 = Vector2(start_pos.x, target_gate_y)
	JuiceSplatScript.spawn(
		get_parent(),
		impact_pt,
		Color(1.0, 0.9, 0.2, 1.0),
		Color(1.0, 0.25, 0.65, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		28
	)

func _process(delta: float) -> void:
	_time_alive += delta
	queue_redraw()

	if _time_alive >= beam_duration:
		queue_free()

func _draw() -> void:
	var progress: float = clampf(_time_alive / beam_duration, 0.0, 1.0)
	var fade: float = 1.0 - ease(progress, 2.5)

	var length: float = maxf(100.0, target_gate_y - start_pos.y)
	var jitter: float = sin(_time_alive * 60.0) * 3.0
	var w: float = _beam_width * fade + jitter

	var p_top: Vector2 = Vector2.ZERO
	var p_bottom: Vector2 = Vector2(0.0, length)

	# 1. Halo extérieur rose / magenta
	draw_line(p_top, p_bottom, Color(1.0, 0.2, 0.65, 0.45 * fade), w * 1.8)

	# 2. Faisceau principal doré éclatant
	draw_line(p_top, p_bottom, Color(1.0, 0.88, 0.2, 0.9 * fade), w)

	# 3. Cœur blanc aveuglant
	draw_line(p_top, p_bottom, Color(1.0, 1.0, 1.0, 1.0 * fade), w * 0.45)

	# Étoile d'énergie à l'origine du tir
	var pts_star: PackedVector2Array = PackedVector2Array()
	var r_outer: float = (w * 1.2) * (0.8 + 0.2 * sin(_time_alive * 40.0))
	var r_inner: float = r_outer * 0.4
	for i in range(10):
		var r: float = r_outer if (i % 2 == 0) else r_inner
		var a: float = float(i) * (PI / 5.0) + _time_alive * 8.0
		pts_star.append(p_top + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts_star, Color(1.0, 1.0, 1.0, fade))
