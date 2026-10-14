class_name Fizzball
extends Ball

## Balle acidulée / électrique "Fizzball".
## Équipée du mot-clé KeywordElectric ("Électrique") qui propage des éclairs en chaîne.

@export var max_chain_targets: int = 2
@export var chain_radius: float = 380.0

func _ready() -> void:
	if not has_keyword(&"electric"):
		var electric_kw: KeywordElectric = KeywordElectric.new()
		electric_kw.max_chain_targets = max_chain_targets
		electric_kw.chain_radius = chain_radius
		native_keywords.append(electric_kw)
	super._ready()

	# Teinte acidulée / vert électrique
	if visual_ball != null:
		visual_ball.color = Color(0.2, 0.95, 0.75, 1.0)
	if core_glow != null:
		core_glow.color = Color(0.9, 1.0, 0.3, 1.0)
	if trail != null:
		trail.default_color = Color(0.3, 1.0, 0.8, 0.6)
