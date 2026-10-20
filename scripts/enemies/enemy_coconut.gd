class_name EnemyCoconut
extends Enemy

## Ennemi Noix de Coco blindé :
## - Ne subit de dégâts QUE par impact direct de bille (Ball).
## - Ne perd qu'un seul PV par coup, quelle que soit la puissance de la bille.
## - À 1 PV restant, passe visuellement sur le sprite 'fendu' avec projection d'éclats.

const PATH_COCONUT_NORMAL_PNG = "res://sprites/coconut_enemy_sprite.png"
const PATH_COCONUT_NORMAL_JPG = "res://sprites/coconut_enemy_sprite.jpg"
const PATH_COCONUT_LOW_PNG = "res://sprites/coconut_low_enemy_sprite_.png"
const PATH_COCONUT_LOW_JPG = "res://sprites/coconut_low_enemy_sprite_.jpg"

var _is_cracked: bool = false

func _ready() -> void:
	super._ready()
	_apply_coconut_texture(false)
	if health_component != null:
		health_component.health_changed.connect(_on_coconut_health_changed)


func _apply_coconut_texture(is_low: bool) -> void:
	if sprite == null:
		return
	var path_png: String = PATH_COCONUT_LOW_PNG if is_low else PATH_COCONUT_NORMAL_PNG
	var path_jpg: String = PATH_COCONUT_LOW_JPG if is_low else PATH_COCONUT_NORMAL_JPG
	var tex: Texture2D = CandyTextureHelper.load_texture(path_png)
	if tex == null:
		tex = CandyTextureHelper.load_texture(path_jpg)
	if tex != null:
		sprite.texture = tex

func _on_coconut_health_changed(cur: int, _max_h: int) -> void:
	if cur <= 1 and not _is_cracked and not _is_dying:
		_crack_shell()

func _crack_shell() -> void:
	_is_cracked = true
	_apply_coconut_texture(true)

	# Juice de fissuration : secousse brutale, flash et projection d'éclats de coque
	if visual_container != null:
		var tw: Tween = create_tween()
		visual_container.scale = Vector2(1.35, 0.7)
		tw.tween_property(visual_container, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Éclats de bois et de coque
	if enemy_data != null and get_parent() != null:
		JuiceSplatScript.spawn(
			get_parent(),
			global_position,
			Color(0.42, 0.26, 0.14, 1.0), # Écorce brune
			Color(0.96, 0.94, 0.88, 1.0), # Lait blanc
			Color(0.72, 0.52, 0.35, 1.0), # Fibres
			12
		)

## Blindage absolu : Immunité totale à tout ce qui n'est pas une bille directe
func take_hit_with_context(hit_ctx: HitContext) -> void:
	if _is_dying or _is_expelled or hit_ctx == null:
		return

	# Si la source n'est pas une balle (ex: bumper explosion, choc entre ennemis, etc.)
	if not (hit_ctx.attacker is Ball):
		_play_armor_deflect_juice(hit_ctx)
		return

	# La balle ne peut retirer qu'un seul PV à la coque blindée par impact
	hit_ctx.final_damage = 1

	super.take_hit_with_context(hit_ctx)

## Effet visuel quand un coup non-balle ricoche sans faire de dégât
func _play_armor_deflect_juice(hit_ctx: HitContext) -> void:
	if visual_container == null:
		return
	var deflect_dir: Vector2 = Vector2.UP
	if hit_ctx.impact_velocity.length() > 10.0:
		deflect_dir = hit_ctx.impact_velocity.normalized()

	var tw: Tween = create_tween().set_parallel(true)
	visual_container.modulate = Color(1.8, 1.8, 1.8, 1.0) # Flash gris métallique
	tw.tween_property(visual_container, "modulate", Color.WHITE, 0.12)
	visual_container.position = deflect_dir * 4.0
	tw.tween_property(visual_container, "position", Vector2.ZERO, 0.12)

# La coque de noix de coco est immunisée aux effets de statut de dégâts continus
func apply_burn(_duration: float = 3.0, _damage_per_tick: int = 1, _tick_interval: float = 0.5) -> void:
	pass
