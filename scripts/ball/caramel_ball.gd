class_name CaramelBall
extends Ball

## Bille de caramel fondant possédant le mot-clé "Collant" (KeywordSticky).
## - Dès qu'elle percute un ennemi, s'accroche et le ralentit de 65%.
## - Se détruit automatiquement à la mort de l'ennemi.

@export var slow_multiplier: float = 0.35

func _ready() -> void:
	if not has_keyword(&"sticky"):
		var sticky_kw: KeywordSticky = KeywordSticky.new()
		sticky_kw.slow_multiplier = slow_multiplier
		native_keywords.append(sticky_kw)
	super._ready()

	# Teinte caramel ambré / miel
	if visual_ball != null:
		visual_ball.color = Color(0.92, 0.55, 0.18, 1.0)
	if core_glow != null:
		core_glow.color = Color(1.0, 0.82, 0.35, 1.0)
	if trail != null:
		trail.default_color = Color(0.95, 0.65, 0.25, 0.55)
