class_name EnemyPomegranate
extends Enemy

## Ennemi Grenade Kamikaze :
## - En dessous d'un seuil de PV (1 PV restant), entre en état Kamikaze :
##   accélération massive (+80%), clignotement rouge d'alarme et compte à rebours de 3 secondes.
## - Explose :
##   1. À sa mort (tuée par le joueur).
##   2. À l'expiration du timer de 3 secondes.
##   3. En se jetant sur la porte (inflige alors de très gros dégâts au joueur : 4 PV).
## - L'explosion projette une onde de choc avec une nuée de grains rubis translucides.

const PomegranateBurstScript = preload("res://scripts/effects/pomegranate_burst_wave.gd")
const PATH_POME_PNG = "res://sprites/pomegrenate_enemy_sprite.png"
const PATH_POME_JPG = "res://sprites/pomegrenate_enemy_sprite.jpg"

var _is_kamikaze: bool = false
var _kamikaze_timer: float = 3.0
var _has_exploded: bool = false
var _pulse_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_apply_texture()
	if health_component != null:
		health_component.health_changed.connect(_on_pome_health_changed)


func _apply_texture() -> void:
	if sprite == null:
		return
	var tex: Texture2D = CandyTextureHelper.load_texture(PATH_POME_PNG)
	if tex == null:
		tex = CandyTextureHelper.load_texture(PATH_POME_JPG)
	if tex != null:
		sprite.texture = tex

func _on_pome_health_changed(cur: int, _max_h: int) -> void:
	if cur <= 1 and not _is_kamikaze and not _is_dying:
		_enter_kamikaze_state()

func _enter_kamikaze_state() -> void:
	_is_kamikaze = true
	_kamikaze_timer = 3.0
	_current_move_speed = enemy_data.move_speed * 1.8 if enemy_data != null else 130.0

	# Juice d'alerte : secousse violente, grossissement et son visuel
	if visual_container != null:
		var tw: Tween = create_tween()
		visual_container.scale = Vector2(1.3, 1.3)
		tw.tween_property(visual_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _is_dying or _is_expelled or _has_exploded:
		return

	if _is_kamikaze:
		_kamikaze_timer -= delta
		_pulse_timer += delta

		# Clignotement alarmant rouge écarlate dont la fréquence augmente
		var pulse_freq: float = lerpf(8.0, 18.0, 1.0 - (_kamikaze_timer / 3.0))
		var flash: float = (sin(_pulse_timer * pulse_freq) + 1.0) * 0.5
		if visual_container != null:
			visual_container.modulate = Color(1.0, 1.0, 1.0).lerp(Color(2.5, 0.2, 0.4), flash)
			# Légère pulsation de taille façon bombe prête à exploser
			var pulse_scale: float = 1.0 + (flash * 0.12)
			visual_container.scale = Vector2(pulse_scale, pulse_scale)

		# Déclenchement de l'explosion spontanée au bout des 3 secondes
		if _kamikaze_timer <= 0.0:
			trigger_explosion(false)

## Déclenche l'explosion de grenade
func trigger_explosion(is_hitting_gate: bool = false) -> void:
	if _has_exploded:
		return
	_has_exploded = true

	# 1. Émission de l'onde de choc et des grains de grenade
	if get_parent() != null:
		PomegranateBurstScript.spawn(
			get_parent(),
			global_position,
			220.0, # Rayon
			2,     # Dégâts aux ennemis alentours
			550.0  # Force de projection
		)

	# 2. Éclaboussure de jus rouge rubis et pépins
	if enemy_data != null and get_parent() != null:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			enemy_data.juice_primary_color,
			enemy_data.juice_secondary_color,
			enemy_data.juice_accent_color,
			28
		)

	# 3. Si l'explosion a lieu sur la porte, gros dégâts infligés au joueur
	if is_hitting_gate:
		var heavy_gate_dmg: int = 4
		EventBus.enemy_escaped.emit(heavy_gate_dmg)
		despawn()
	else:
		# Si non provoqué par la porte, on déclenche le flux complet de mort (score, events, suppression)
		super._on_died()

## Quand la grenade heurte la porte ou franchit la zone basse
func _explode_at_gate(_normal: Vector2) -> void:
	if _has_exploded or _is_dying:
		return
	trigger_explosion(true)

## À sa mort achevée par le joueur (balle ou autre)
func _on_died() -> void:
	trigger_explosion(false)
