class_name EnemyGrape
extends Enemy

## Petit ennemi Raisin :
## - Très rapide et léger (expulsé en cloche lors du coup fatal direct d'une bille).
## - 1 seul PV, sautillements vifs.
## - Libéré par la Grappe Mère (Bunch of Grapes) lors des chocs ou de sa mort.

const PATH_GRAPE = "res://sprites/grape_enemy_sprite.png"

func _ready() -> void:
	super._ready()
	_apply_texture()

func _apply_texture() -> void:
	if sprite == null:
		return
	var tex: Texture2D = CandyTextureHelper.load_texture(PATH_GRAPE)
	if tex != null:
		sprite.texture = tex

## Propulsion initiale lors de son détachement de la grappe
func launch_from_bunch(initial_impulse: Vector2) -> void:
	_knockback_velocity = initial_impulse
	_trigger_impact_squash(initial_impulse.angle())
