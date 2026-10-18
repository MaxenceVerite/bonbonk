class_name Relic
extends Resource

## Ressource de base pour toutes les reliques, améliorations ou modificateurs Roguelike.
## Utilise le pattern Observer/Strategy pour réagir aux événements universels du jeu
## sans jamais devoir modifier les scripts de physique, d'ennemis ou de bille.

@export var id: StringName = &"base_relic"
@export var display_name: String = "Relique"
@export_multiline var description: String = ""
@export var icon_texture: Texture2D

## Déclenché quand la relique est acquise pendant la run
func on_acquired() -> void:
	pass

## Déclenché quand la relique est retirée
func on_removed() -> void:
	pass

## Déclenché au début d'une manche
func on_wave_started(_wave_number: int) -> void:
	pass

## Déclenché quand une manche est pacifiée
func on_wave_cleared(_wave_number: int) -> void:
	pass

## Déclenché dès qu'une bille heurte un ennemi
func on_ball_hit_enemy(_context: HitContext) -> void:
	pass

## Déclenché dès qu'une bille heurte un bumper
func on_ball_hit_bumper(_ball: RigidBody2D, _bumper: Node2D) -> void:
	pass

## Déclenché quand un batteur réussit un Super-Contre (Parry) sur un ennemi
func on_flipper_parried(_flipper: Node2D, _enemy: Node2D, _context: HitContext) -> void:
	pass

## Déclenché chaque fois qu'un ennemi subit des dégâts
func on_enemy_damaged(_enemy: Node2D, _context: HitContext) -> void:
	pass

## Déclenché quand un ennemi est éliminé (avec le contexte complet de ce qui l'a achevé)
func on_enemy_killed(_enemy: Node2D, _context: HitContext) -> void:
	pass

## Déclenché quand un ennemi reçoit une altération d'état
func on_status_applied(_target: Node2D, _status_id: StringName) -> void:
	pass
