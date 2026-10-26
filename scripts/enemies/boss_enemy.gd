class_name BossEnemy
extends Enemy

## Classe de base extensible pour tous les Boss du jeu (ex: Brocolino).
## Gère l'entrée en scène depuis la canopée, l'ancrage en haut de l'écran,
## l'état d'invulnérabilité avec bouclier visuel et la synchronisation avec l'EventBus.

@export var boss_name: String = "Brocolino"
@export var boss_max_hp: int = 200
@export var target_anchor_y: float = 160.0
@export var anchors_to_top: bool = true

var is_invulnerable: bool = false
var _invuln_pulse_t: float = 0.0
var _is_entering: bool = true
var _shield_flash_timer: float = 0.0

func _ready() -> void:
	is_boss = true
	super._ready()

	# Configuration des points de vie
	if health_component != null:
		health_component.set_max_health(boss_max_hp)

	# Notifie le HUD pour afficher la barre épique
	EventBus.boss_spawned.emit(boss_name, boss_max_hp)

	# Position initiale au-dessus de l'écran dans les arbres
	position.y = -140.0
	_is_entering = true

	# Descente cinématographique majestueuse jusqu'au bord de la forêt
	var entry_tw: Tween = create_tween()
	entry_tw.tween_property(self, "position:y", target_anchor_y, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entry_tw.tween_callback(func() -> void:
		_is_entering = false
	)

func _on_health_changed(cur: int, max_h: int) -> void:
	# Synchronisation immédiate avec la barre de vie du Boss
	EventBus.boss_health_changed.emit(cur, max_h)

func take_hit_with_context(hit_ctx: HitContext) -> void:
	if _is_dying or _is_expelled or hit_ctx == null:
		return

	# Si le Boss est invulnérable (ex: tant qu'il reste des bumpers brocolis)
	if is_invulnerable:
		_deflect_hit(hit_ctx)
		return

	# Dégât normal
	super.take_hit_with_context(hit_ctx)

## Les Boss sont des colosses inébranlables : ils absorbent le knockback et ne basculent jamais
func apply_knockback(_impulse: Vector2, _hit_angle: float) -> void:
	if visual_container != null:
		visual_container.rotation = 0.0
func _deflect_hit(hit_ctx: HitContext) -> void:
	_shield_flash_timer = 0.2
	queue_redraw()

	# Rebond physique sec de la bille sur le bouclier
	if hit_ctx.attacker is RigidBody2D:
		var ball: RigidBody2D = hit_ctx.attacker as RigidBody2D
		var push_dir: Vector2 = (ball.global_position - global_position).normalized()
		if push_dir.y < 0.2:
			push_dir = Vector2(push_dir.x, 0.6).normalized()
		if ball.has_method(&"apply_bumper_bounce"):
			ball.apply_bumper_bounce(push_dir, 720.0)
		else:
			ball.linear_velocity = push_dir * 720.0

	# Secousse & Flash du sprite
	var tw: Tween = create_tween()
	visual_container.modulate = Color(1.8, 2.5, 2.8, 1.0)
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.12)

	Input.vibrate_handheld(20)

func set_invulnerable(invuln: bool) -> void:
	if is_invulnerable != invuln:
		is_invulnerable = invuln
		EventBus.boss_invulnerability_changed.emit(is_invulnerable)
		queue_redraw()

		# Flash / pulsation d'activation du bouclier
		var tw: Tween = create_tween()
		if is_invulnerable:
			visual_container.modulate = Color(1.5, 2.2, 1.5, 1.0)
			tw.tween_property(visual_container, "modulate", Color.WHITE, 0.25)
		else:
			# Bouclier brisé : éclat lumineux
			visual_container.modulate = Color(2.5, 2.5, 1.5, 1.0)
			tw.tween_property(visual_container, "modulate", Color.WHITE, 0.2)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	_time_since_last_damage += delta

	# Mise à jour des altérations d'état (Stun, Freeze, Burn...) pour les Boss
	if status_component != null:
		status_component.update_status(delta)

	if _shield_flash_timer > 0.0:
		_shield_flash_timer = maxf(0.0, _shield_flash_timer - delta)
		queue_redraw()

	if is_invulnerable:
		_invuln_pulse_t += delta * 5.0
		queue_redraw()

	# Les Boss stationnaires restent ancrés en haut sans avancer vers le bas une fois arrivés
	if anchors_to_top and not _is_entering:
		position.y = target_anchor_y + sin(_time_alive * 2.0) * 4.0 # Respiration flottante subtile

func _on_died() -> void:
	if _is_dying or _is_expelled:
		return
	_is_dying = true
	active_enemies.erase(self)
	collision_shape.set_deferred(&"disabled", true)

	EventBus.boss_defeated.emit(boss_name)
	EventBus.score_changed.emit(2500, 2500)

	# Mort cinématique : tremblements, éclairs de jus et explosion triomphale
	_play_boss_death_cinematic()

func _play_boss_death_cinematic() -> void:
	var tw: Tween = create_tween()
	# Tremblements intenses
	for i in range(8):
		var offset_x: float = randf_range(-14.0, 14.0)
		var offset_y: float = randf_range(-8.0, 8.0)
		tw.tween_property(visual_container, "position", Vector2(offset_x, offset_y), 0.05)
	
	tw.tween_callback(func() -> void:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			Color(0.28, 0.85, 0.18, 1.0),
			Color(0.85, 0.95, 0.35, 1.0),
			Color(1.0, 1.0, 1.0, 1.0),
			32
		)
		Input.vibrate_handheld(70)
	)

	tw.set_parallel(true)
	tw.tween_property(visual_container, "scale", Vector2(1.6, 0.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_container, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(despawn)

func _draw() -> void:
	# Pas de barre de vie en arc (remplacée par la grande jauge épique du haut)
	# Dessin du bouclier d'invulnérabilité si actif
	if is_invulnerable:
		var c: Vector2 = Vector2.ZERO
		var pulse: float = 0.9 + 0.1 * sin(_invuln_pulse_t)
		var shield_radius: float = 135.0 * pulse
		var base_col: Color = Color(0.25, 0.85, 0.35, 0.35)
		var outline_col: Color = Color(0.4, 1.0, 0.5, 0.85)
		if _shield_flash_timer > 0.0:
			base_col = Color(1.0, 1.0, 1.0, 0.6)
			outline_col = Color(1.0, 1.0, 1.0, 1.0)

		# Bulle de protection verdoyante
		draw_circle(c, shield_radius, base_col)
		draw_arc(c, shield_radius, 0.0, TAU, 36, outline_col, 4.0, true)
		# Deuxième anneau intérieur fin
		draw_arc(c, shield_radius * 0.75, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.35), 2.0, true)
