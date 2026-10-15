class_name CardCatalog
extends RefCounted

## Répertoire centralisé et définitions des cartes de bonbons (Balles & Bumpers).
## Isole la configuration des cartes pour alléger SaveManager.

static func get_default_definitions() -> Dictionary:
	var defs: Dictionary = {}

	# Fizzball
	var fizz_card: CandyCardData = CandyCardData.new()
	fizz_card.id = &"fizz"
	fizz_card.display_name = "Fizzball"
	fizz_card.subtitle = "Acidulée & Électrique"
	fizz_card.description = "Diffuse des décharges acidulées qui frappent plusieurs ennemis proches."
	fizz_card.rarity = CandyCardData.Rarity.RARE
	fizz_card.base_damage = 1
	fizz_card.damage_per_level = 0.25
	fizz_card.base_magnetism = 340.0
	fizz_card.magnetism_per_level = 25.0
	fizz_card.base_bounce = 1.05
	fizz_card.bounce_per_level = 0.04
	fizz_card.keyword_stats = [
		{ "id": &"chain_targets", "name": "Cibles foudroyées", "icon": "⚡", "base": 2.0, "step": 0.4, "format": "int", "unit": " cibles" },
		{ "id": &"stun_duration", "name": "Durée étourdissement", "icon": "💫", "base": 1.0, "step": 0.15, "format": "duration" }
	]
	fizz_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/fizzball_ball_sprite.png")
	defs[&"fizz"] = fizz_card

	# Bille Caramel (Collante & Gluante)
	var caramel_card: CandyCardData = CandyCardData.new()
	caramel_card.id = &"caramel"
	caramel_card.display_name = "Bille Caramel"
	caramel_card.subtitle = "Collante & Ralentissante"
	caramel_card.description = "Englue les bonbons adverses à chaque contact pour ralentir leur descente."
	caramel_card.rarity = CandyCardData.Rarity.RARE
	caramel_card.base_damage = 1
	caramel_card.damage_per_level = 0.2
	caramel_card.base_magnetism = 420.0
	caramel_card.magnetism_per_level = 40.0
	caramel_card.base_bounce = 0.90
	caramel_card.bounce_per_level = 0.02
	caramel_card.keyword_stats = [
		{ "id": &"slow_power", "name": "Ralentissement", "icon": "🍯", "base": 0.65, "step": 0.04, "format": "percent" }
	]
	caramel_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/sticky_caramel_ball_sprite.png")
	defs[&"caramel"] = caramel_card

	# Mentox Givrée (Inspiration bonbon Menthise)
	var mentox_card: CandyCardData = CandyCardData.new()
	mentox_card.id = &"mentox"
	mentox_card.display_name = "Mentox Givrée"
	mentox_card.subtitle = "Frisson Glacé & Fraîcheur"
	mentox_card.description = "Immobilise complètement les ennemis percutés sous un bloc de givre pendant quelques secondes."
	mentox_card.rarity = CandyCardData.Rarity.COMMON
	mentox_card.base_damage = 1
	mentox_card.damage_per_level = 0.25
	mentox_card.base_magnetism = 360.0
	mentox_card.magnetism_per_level = 30.0
	mentox_card.base_bounce = 1.00
	mentox_card.bounce_per_level = 0.03
	mentox_card.keyword_stats = [
		{ "id": &"freeze_duration", "name": "Durée de gel", "icon": "❄️", "base": 1.8, "step": 0.25, "format": "duration" }
	]
	mentox_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/mentox_givre_ball_sprite.png")
	defs[&"mentox"] = mentox_card

	# Casse-bonbon (Inspiration Jawbreaker / Joybreaker)
	var jaw_card: CandyCardData = CandyCardData.new()
	jaw_card.id = &"jawbreaker"
	jaw_card.display_name = "Casse-bonbon"
	jaw_card.subtitle = "Éclatement Multicolore"
	jaw_card.description = "Bille lourde et dense. Au moindre impact, elle éclate et projette des sous-bonbons de ton deck !"
	jaw_card.rarity = CandyCardData.Rarity.LEGENDARY
	jaw_card.base_damage = 2
	jaw_card.damage_per_level = 0.5
	jaw_card.base_magnetism = 280.0
	jaw_card.magnetism_per_level = 20.0
	jaw_card.base_bounce = 0.85
	jaw_card.bounce_per_level = 0.02
	jaw_card.keyword_stats = [
		{ "id": &"split_count", "name": "Sous-bonbons projetés", "icon": "🍬", "base": 2.0, "step": 0.35, "format": "int", "unit": " bonbons" }
	]
	jaw_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/joybreaker_ball_sprite.png")
	defs[&"jawbreaker"] = jaw_card

	# Dragiburst (Bumper Dragon Flamboyant)
	var dragi_card: CandyCardData = CandyCardData.new()
	dragi_card.id = &"dragiburst"
	dragi_card.display_name = "Dragiburst"
	dragi_card.subtitle = "Bumper Draconique"
	dragi_card.description = "Souffle de dragon circulaire ! Inflige de lourds dégâts d'impact et brûle les ennemis proches."
	dragi_card.rarity = CandyCardData.Rarity.RARE
	dragi_card.card_type = CandyCardData.CardType.BUMPER
	dragi_card.base_damage = 2
	dragi_card.damage_per_level = 0.5
	dragi_card.base_magnetism = 0.0
	dragi_card.magnetism_per_level = 0.0
	dragi_card.base_bounce = 1.35
	dragi_card.bounce_per_level = 0.05
	dragi_card.keyword_stats = [
		{ "id": &"burst_radius", "name": "Rayon du souffle", "icon": "🔥", "base": 240.0, "step": 20.0, "format": "int", "unit": "px" },
		{ "id": &"burn_duration", "name": "Durée brûlure", "icon": "⏳", "base": 3.0, "step": 0.4, "format": "float", "unit": "s" }
	]
	dragi_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/dragiburst_bumper_sprite.png")
	defs[&"dragiburst"] = dragi_card

	# Twistypop (Bumper Sucette Tournoyante)
	var twisty_card: CandyCardData = CandyCardData.new()
	twisty_card.id = &"twistypop"
	twisty_card.display_name = "Twistypop"
	twisty_card.subtitle = "Sucette Tournoyante"
	twisty_card.description = "Sucette arc-en-ciel légendaire ! Au contact de la bille, projette une salve d'éclats magiques traquant les ennemis."
	twisty_card.rarity = CandyCardData.Rarity.LEGENDARY
	twisty_card.card_type = CandyCardData.CardType.BUMPER
	twisty_card.base_damage = 1
	twisty_card.damage_per_level = 0.0
	twisty_card.base_magnetism = 0.0
	twisty_card.magnetism_per_level = 0.0
	twisty_card.base_bounce = 1.45
	twisty_card.bounce_per_level = 0.05
	twisty_card.keyword_stats = [
		{ "id": &"shard_count", "name": "Éclats traqueurs", "icon": "✨", "base": 2.0, "step": 2.0, "format": "int", "unit": "" }
	]
	twisty_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/lolipop_burster_sprite.png")
	defs[&"twistypop"] = twisty_card

	# Soucoupe Piquante (Bumper Anti-Gravité / Flying Saucer)
	var saucer_card: CandyCardData = CandyCardData.new()
	saucer_card.id = &"flying_saucer"
	saucer_card.display_name = "Soucoupe Piquante"
	saucer_card.subtitle = "Bumper Anti-Gravité"
	saucer_card.description = "Soucoupe en bonbon acide ! Propulse violemment la bille vers le haut et électrocute les ennemis proches."
	saucer_card.rarity = CandyCardData.Rarity.EPIC
	saucer_card.card_type = CandyCardData.CardType.BUMPER
	saucer_card.base_damage = 2
	saucer_card.damage_per_level = 0.4
	saucer_card.base_magnetism = 0.0
	saucer_card.magnetism_per_level = 0.0
	saucer_card.base_bounce = 1.40
	saucer_card.bounce_per_level = 0.04
	saucer_card.keyword_stats = [
		{ "id": &"zap_range", "name": "Rayon électrique", "icon": "⚡", "base": 200.0, "step": 20.0, "format": "int", "unit": "px" }
	]
	saucer_card.icon_texture = CandyTextureHelper.load_texture("res://assets/ui/cards/flying_saucer_bumper_sprite.png")
	defs[&"flying_saucer"] = saucer_card

	return defs

## Palette de couleurs standardisée des bonbons (partagée entre Gameplay et UI)
static func get_candy_palette(b_type: StringName) -> Dictionary:
	match b_type:
		&"twistypop":
			return {
				"color": Color(0.95, 0.25, 0.65, 1.0),
				"core": Color(1.0, 0.92, 0.20, 1.0),
				"ring": Color(0.12, 0.78, 0.95, 0.9)
			}
		&"dragiburst":
			return {
				"color": Color(0.95, 0.15, 0.18, 1.0),
				"core": Color(1.0, 0.88, 0.35, 1.0),
				"ring": Color(0.65, 0.08, 0.12, 0.9)
			}
		&"flying_saucer":
			return {
				"color": Color(0.85, 0.45, 0.95, 1.0),
				"core": Color(1.0, 0.92, 0.35, 1.0),
				"ring": Color(0.45, 0.15, 0.75, 0.9)
			}
		&"fizz":
			return {
				"color": Color(0.20, 0.96, 0.76, 1.0),
				"core": Color(0.88, 1.0, 0.38, 1.0),
				"ring": Color(0.10, 0.52, 0.42, 0.9)
			}
		&"caramel":
			return {
				"color": Color(0.92, 0.55, 0.18, 1.0),
				"core": Color(1.0, 0.82, 0.35, 1.0),
				"ring": Color(0.65, 0.32, 0.08, 0.9)
			}
		&"mentox":
			return {
				"color": Color(0.92, 0.98, 1.0, 1.0),
				"core": Color(0.55, 0.88, 0.98, 1.0),
				"ring": Color(0.35, 0.75, 0.92, 0.9)
			}
		&"jawbreaker":
			return {
				"color": Color(0.96, 0.96, 0.98, 1.0),
				"core": Color(1.0, 0.82, 0.25, 1.0),
				"ring": Color(0.85, 0.2, 0.45, 0.9)
			}
		_:
			return {
				"color": Color(0.20, 0.96, 0.76, 1.0),
				"core": Color(0.88, 1.0, 0.38, 1.0),
				"ring": Color(0.10, 0.52, 0.42, 0.9)
			}

