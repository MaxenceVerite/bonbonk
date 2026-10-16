class_name DiveTelegraphVisual
extends Node2D

## Indicateur visuel vectoriel mobile-first (zéro texture, 60/120 FPS) :
## Affiche un anneau de ciblage qui rétrécit vers un cercle cible lorsque l'ennemi arme sa charge suicide.
## Dès que l'anneau atteint le centre (fenêtre de contre active), il clignote en vert/doré néon avec un point d'exclamation.

var is_active: bool = false
var progress: float = 0.0 # 0.0 (début alerte) -> 1.0 (moment de frappe parfait)
var can_be_parried: bool = true

# Rayon cible et rayon max de départ
const TARGET_RADIUS: float = 26.0
const START_RADIUS: float = 64.0

func setup(p_can_be_parried: bool) -> void:
	can_be_parried = p_can_be_parried
	is_active = false
	progress = 0.0
	queue_redraw()

func start_windup(p_can_be_parried: bool) -> void:
	can_be_parried = p_can_be_parried
	is_active = true
	progress = 0.0
	visible = true
	queue_redraw()

func set_progress(p: float) -> void:
	progress = clampf(p, 0.0, 1.0)
	queue_redraw()

func stop_telegraph() -> void:
	is_active = false
	progress = 0.0
	visible = false
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return

	# 1. Cercle cible (cible au sol / autour de l'ennemi)
	var target_color: Color
	if not can_be_parried:
		# Pourpre / Noir dangereux inarrêtable (ex: Pastèque)
		target_color = Color(0.85, 0.15, 0.25, 0.75)
	elif progress >= 0.85:
		# Fenêtre de contre active : VERT / DORÉ FLASH !
		target_color = Color(0.2, 1.0, 0.45, 0.95)
	else:
		# Préparation : Orange / Rouge d'alerte
		target_color = Color(1.0, 0.45, 0.15, 0.65)

	# Anneau cible fixe avec contour net
	draw_arc(Vector2.ZERO, TARGET_RADIUS, 0, TAU, 32, target_color, 2.5, true)

	# 2. Anneau d'anticipation qui rétrécit avec progress
	var current_radius: float = lerpf(START_RADIUS, TARGET_RADIUS, progress)
	var ring_color: Color
	if not can_be_parried:
		ring_color = Color(0.9, 0.1, 0.1, 0.85)
	elif progress >= 0.85:
		ring_color = Color(1.0, 1.0, 0.5, 1.0)
	else:
		ring_color = Color(1.0, 0.75, 0.2, 0.8)

	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, ring_color, 3.0, true)

	# 3. Marque centrale d'avertissement quand la fenêtre est idéale (❗ ou disque doré)
	if can_be_parried and progress >= 0.85:
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.95, 0.4, 0.9))
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
	elif not can_be_parried:
		# Petite croix ou symbole de danger inébranlable
		draw_line(Vector2(-6, -6), Vector2(6, 6), Color(0.9, 0.1, 0.1, 0.9), 2.5)
		draw_line(Vector2(-6, 6), Vector2(6, -6), Color(0.9, 0.1, 0.1, 0.9), 2.5)
