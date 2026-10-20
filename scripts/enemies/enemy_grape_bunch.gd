class_name EnemyGrapeBunch
extends Enemy

## Ennemi Grappe de Raisin (Swarm Carrier) :
## - Ennemi lourd et résistant (5 PV).
## - À chaque coup direct de bille : la secousse détache 1 petit raisin qui est éjecté sur le plateau.
## - À sa mort finale : éclate en libérant 3 petits raisins en étoile tout autour d'elle.

const GRAPE_SCENE: PackedScene = preload("res://scenes/enemies/enemy_grape.tscn")
const EnemyGrapeScript = preload("res://scripts/enemies/enemy_grape.gd")
const PATH_GRAPE_BUNCH = "res://sprites/bunch_of_grapes_enemy_sprite.png"

func _ready() -> void:
	super._ready()
	_apply_texture()

func _apply_texture() -> void:
	if sprite == null:
		return
	var tex: Texture2D = CandyTextureHelper.load_texture(PATH_GRAPE_BUNCH)
	if tex != null:
		sprite.texture = tex

func take_hit_with_context(hit_ctx: HitContext) -> void:
	if _is_dying or _is_expelled or hit_ctx == null:
		return

	var is_ball: bool = (hit_ctx.attacker is Ball)
	super.take_hit_with_context(hit_ctx)

	# Si la grappe survit au coup et que c'était une bille : elle détache 1 raisin sous la secousse !
	if is_ball and not _is_dying and health_component.current_health > 0:
		_spawn_single_grape(hit_ctx.impact_velocity)

## Détache un raisin lors d'un choc de bille
func _spawn_single_grape(impact_vel: Vector2) -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var grape: Enemy = GRAPE_SCENE.instantiate() as Enemy
	if grape == null:
		return

	# Position légèrement décalée sur le flanc
	var side_offset: float = -38.0 if randf() < 0.5 else 38.0
	grape.global_position = global_position + Vector2(side_offset, randf_range(-15.0, 15.0))
	parent_node.add_child(grape)

	# Impulsion physique d'éjection en cloche latérale
	var launch_dir: Vector2 = Vector2(signf(side_offset), -0.65).normalized()
	if impact_vel.length() > 50.0:
		# Réaction tangentielle à l'impact
		launch_dir = (launch_dir + Vector2(-impact_vel.y, impact_vel.x).normalized() * 0.4).normalized()
	var launch_impulse: Vector2 = launch_dir * randf_range(280.0, 420.0)
	grape.launch_from_bunch(launch_impulse)

	# Juice sur la grappe mère : secousse de détachement
	if visual_container != null:
		var tw: Tween = create_tween()
		visual_container.scale = Vector2(1.22, 0.82)
		tw.tween_property(visual_container, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## À sa mort, libère 3 raisins en étoile
func _on_died() -> void:
	_spawn_death_grapes()
	super._on_died()

func _spawn_death_grapes() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	# 3 angles d'éjection en éventail vers le haut et les côtés
	var angles: Array[float] = [-2.3, -1.57, -0.84]
	for a in angles:
		var grape: Enemy = GRAPE_SCENE.instantiate() as Enemy
		if grape == null:
			continue

		var offset: Vector2 = Vector2(cos(a), sin(a)) * 34.0
		grape.global_position = global_position + offset
		parent_node.add_child(grape)

		var impulse: Vector2 = Vector2(cos(a), sin(a)) * randf_range(320.0, 480.0)
		grape.launch_from_bunch(impulse)
