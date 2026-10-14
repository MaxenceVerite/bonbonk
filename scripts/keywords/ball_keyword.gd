class_name BallKeyword
extends Resource

## Classe de base pour tous les mots-clés de billes.
## Un mot-clé encapsule un effet de jeu découplé :
## - Collant (s'accroche et ralentit)
## - Électrique (propage des arcs et paralyse)
## - Piquant (inflige des dégâts perforants)
## - Explosif (déflagration de zone)

@export var id: StringName = &"base_keyword"
@export var display_name: String = "Mot-Clé"
@export var description: String = ""
@export var icon_texture: Texture2D

## Déclenché quand la bille touche un ennemi
func on_hit_enemy(ball: Ball, enemy: Enemy) -> void:
	pass

## Déclenché quand la bille touche un mur / obstacle
func on_hit_wall(ball: Ball, normal: Vector2) -> void:
	pass

## Déclenché quand la bille touche un bumper
func on_hit_bumper(ball: Ball, bumper: CandyBumper) -> void:
	pass

## Déclenché quand l'ennemi auquel la bille est attachée meurt
func on_attached_enemy_died(ball: Ball, enemy: Enemy) -> void:
	pass

## Déclenché à chaque frame physique si le mot-clé a un effet continu
func on_physics_tick(ball: Ball, delta: float) -> void:
	pass
