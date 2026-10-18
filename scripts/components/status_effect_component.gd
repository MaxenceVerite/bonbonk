class_name StatusEffectComponent
extends Node

## Composant gérant les altérations d'état modulaires sur une entité (Strategy Pattern).
## Gère le cycle de vie, les timers, l'immobilisation et les modulations sans couplage.

signal status_changed(is_immobilized: bool)

var _target_node: CharacterBody2D = null
var _visual_container: Node2D = null
var _active_effects: Dictionary = {} # StringName -> StatusEffect

func setup(target: CharacterBody2D, visual: Node2D) -> void:
	_target_node = target
	_visual_container = visual

func apply_effect(effect: StatusEffect) -> void:
	if effect == null:
		return

	var was_immobile: bool = is_immobilized()

	if _active_effects.has(effect.id):
		var existing: StatusEffect = _active_effects[effect.id]
		existing.refresh_duration(effect.duration)
	else:
		_active_effects[effect.id] = effect
		effect.on_applied(_target_node, _visual_container)
		EventBus.status_applied.emit(_target_node, effect.id)

	var now_immobile: bool = is_immobilized()
	if was_immobile != now_immobile:
		status_changed.emit(now_immobile)

func remove_effect(effect_id: StringName) -> void:
	if not _active_effects.has(effect_id):
		return
	var was_immobile: bool = is_immobilized()
	var effect: StatusEffect = _active_effects[effect_id]
	_active_effects.erase(effect_id)
	effect.on_removed(_target_node, _visual_container)

	var now_immobile: bool = is_immobilized()
	if was_immobile != now_immobile:
		status_changed.emit(now_immobile)

func has_effect(effect_id: StringName) -> bool:
	return _active_effects.has(effect_id)

func get_effect(effect_id: StringName) -> StatusEffect:
	return _active_effects.get(effect_id, null)

func is_immobilized() -> bool:
	for eff in _active_effects.values():
		if eff.is_immobilizing():
			return true
	return false

func is_stunned() -> bool:
	return has_effect(&"stun")

func is_frozen() -> bool:
	return has_effect(&"freeze")

func is_burning() -> bool:
	return has_effect(&"burn")

func get_speed_multiplier() -> float:
	var mult: float = 1.0
	for eff in _active_effects.values():
		mult = minf(mult, eff.get_speed_multiplier())
	return mult

# --- Méthodes de confort pour rétrocompatibilité totale ---

func apply_burn(duration: float = 3.0, damage_per_tick: int = 1, tick_interval: float = 0.5) -> void:
	var burn: BurnStatusEffect = BurnStatusEffect.new(duration, damage_per_tick, tick_interval)
	apply_effect(burn)

func apply_electric_zap(duration: float = 2.0) -> void:
	var stun: StunStatusEffect = StunStatusEffect.new(duration)
	apply_effect(stun)

func apply_freeze(duration: float = 2.0) -> void:
	var freeze_eff: FreezeStatusEffect = FreezeStatusEffect.new(duration)
	apply_effect(freeze_eff)

func attach_caramel_ball(caramel_ball: Node2D, speed_multiplier: float = 0.35) -> void:
	var sticky: StickyStatusEffect = StickyStatusEffect.new(caramel_ball, speed_multiplier)
	apply_effect(sticky)

func detach_caramel_ball() -> void:
	remove_effect(&"sticky")

func cleanup_on_death() -> void:
	for eff in _active_effects.values():
		if eff is StickyStatusEffect:
			eff.cleanup_on_death()
	_active_effects.clear()

func update_status(delta: float) -> void:
	if _active_effects.is_empty():
		return

	var was_immobile: bool = is_immobilized()
	var expired_keys: Array[StringName] = []

	for effect_id in _active_effects.keys():
		var effect: StatusEffect = _active_effects[effect_id]
		effect.on_tick(_target_node, _visual_container, delta)
		if effect.is_expired:
			expired_keys.append(effect_id)

	for key in expired_keys:
		var effect: StatusEffect = _active_effects[key]
		_active_effects.erase(key)
		effect.on_removed(_target_node, _visual_container)

	var now_immobile: bool = is_immobilized()
	if was_immobile != now_immobile:
		status_changed.emit(now_immobile)
