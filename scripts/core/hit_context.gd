class_name HitContext
extends RefCounted

## Données contextuelles d'un impact ou d'une attaque dans le jeu.
## Permet aux mots-clés, aux reliques roguelike et aux composants de modifier
## ou de réagir aux chocs (dégâts, type d'élément, source, parade, etc.).

enum DamageType {
	PHYSICAL,
	ELECTRIC,
	FIRE,
	ICE,
	PARRY,
	DOT
}

var attacker: Node = null
var target: Node = null
var base_damage: int = 1
var final_damage: int = 1
var impact_point: Vector2 = Vector2.ZERO
var impact_velocity: Vector2 = Vector2.ZERO
var damage_type: DamageType = DamageType.PHYSICAL
var is_parry: bool = false
var is_critical: bool = false
var extra_data: Dictionary = {}

static func create(
	p_attacker: Node,
	p_target: Node,
	p_damage: int,
	p_point: Vector2 = Vector2.ZERO,
	p_velocity: Vector2 = Vector2.ZERO,
	p_type: DamageType = DamageType.PHYSICAL,
	p_is_parry: bool = false
) -> HitContext:
	var ctx: HitContext = HitContext.new()
	ctx.attacker = p_attacker
	ctx.target = p_target
	ctx.base_damage = p_damage
	ctx.final_damage = p_damage
	ctx.impact_point = p_point
	ctx.impact_velocity = p_velocity
	ctx.damage_type = p_type
	ctx.is_parry = p_is_parry
	return ctx
