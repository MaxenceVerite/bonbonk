class_name PlayerProfile
extends RefCounted

## Données de profil et de progression du joueur (sérialisable et synchronisable).

const CURRENT_SCHEMA_VERSION: int = 1

var profile_id: String = "main"
var display_name: String = "Gourmand"
var account_type: String = "guest" # "guest", "cloud", "sandbox"
var cloud_user_id: String = ""

var created_at: int = 0
var last_saved_at: int = 0
var schema_version: int = CURRENT_SCHEMA_VERSION
var sync_revision: int = 0

var gold: int = 250
var diamonds: int = 30

# Dictionnaire { card_id: { "unlocked": bool, "level": int, "cards": int } }
var cards_inventory: Dictionary = {}

# Decks : Array de 3 Arrays de 6 StringName
var decks: Array = []
var active_deck_index: int = 0

# Mode de jeu actif ("campaign" ou "survival") et Deck dédié au mode Survie
var active_game_mode: String = "campaign"
var survival_deck: Array = []

# Progression du Mode Campagne (Saga)
var campaign_unlocked_world: int = 1
var campaign_unlocked_level: int = 1
var campaign_levels_data: Dictionary = {} # level_id (String) -> { "stars": int, "best_score": int, "cleared": bool }

# Records du Mode Survie (Roguelike)
var survival_best_wave: int = 0
var survival_best_score: int = 0

# Boosters en attente d'ouverture (dictionnaires de données pour sérialisation)
var available_boosters: Array = []

# Actions en attente de synchro cloud (deltas d'économie, etc.)
var pending_sync_actions: Array = []

# Statistiques globales de jeu
var stats: Dictionary = {
	"best_score": 0,
	"games_played": 0,
	"enemies_defeated": 0,
}

func _init() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	created_at = now
	last_saved_at = now

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"profile_id": profile_id,
		"display_name": display_name,
		"account_type": account_type,
		"cloud_user_id": cloud_user_id,
		"created_at": created_at,
		"last_saved_at": int(Time.get_unix_time_from_system()),
		"sync_revision": sync_revision,
		"gold": gold,
		"diamonds": diamonds,
		"cards_inventory": cards_inventory.duplicate(true),
		"decks": decks.duplicate(true),
		"active_deck_index": active_deck_index,
		"active_game_mode": active_game_mode,
		"survival_deck": survival_deck.duplicate(true),
		"campaign_unlocked_world": campaign_unlocked_world,
		"campaign_unlocked_level": campaign_unlocked_level,
		"campaign_levels_data": campaign_levels_data.duplicate(true),
		"survival_best_wave": survival_best_wave,
		"survival_best_score": survival_best_score,
		"available_boosters": available_boosters.duplicate(true),
		"pending_sync_actions": pending_sync_actions.duplicate(true),
		"stats": stats.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	schema_version = data.get("schema_version", CURRENT_SCHEMA_VERSION)
	profile_id = data.get("profile_id", "main")
	display_name = data.get("display_name", "Gourmand")
	account_type = data.get("account_type", "guest")
	cloud_user_id = data.get("cloud_user_id", "")
	created_at = data.get("created_at", int(Time.get_unix_time_from_system()))
	last_saved_at = data.get("last_saved_at", int(Time.get_unix_time_from_system()))
	sync_revision = data.get("sync_revision", 0)
	gold = data.get("gold", 250)
	diamonds = data.get("diamonds", 30)

	var raw_inv: Dictionary = data.get("cards_inventory", {})
	cards_inventory.clear()
	for k in raw_inv:
		var c_id: StringName = StringName(k)
		cards_inventory[c_id] = raw_inv[k].duplicate(true)

	var raw_decks: Array = data.get("decks", [])
	decks.clear()
	for d in raw_decks:
		var slot_deck: Array = []
		for card_id in d:
			slot_deck.append(StringName(card_id))
		decks.append(slot_deck)

	active_deck_index = data.get("active_deck_index", 0)
	active_game_mode = data.get("active_game_mode", "campaign")

	var raw_survival_deck: Array = data.get("survival_deck", [])
	survival_deck.clear()
	for card_id in raw_survival_deck:
		survival_deck.append(StringName(card_id))

	campaign_unlocked_world = data.get("campaign_unlocked_world", 1)
	campaign_unlocked_level = data.get("campaign_unlocked_level", 1)
	campaign_levels_data = data.get("campaign_levels_data", {}).duplicate(true)
	survival_best_wave = data.get("survival_best_wave", 0)
	survival_best_score = data.get("survival_best_score", 0)

	available_boosters = data.get("available_boosters", []).duplicate(true)
	pending_sync_actions = data.get("pending_sync_actions", []).duplicate(true)
	stats = data.get("stats", { "best_score": 0, "games_played": 0, "enemies_defeated": 0 }).duplicate(true)

	# Auto-migration de schéma si nécessaire
	_apply_migrations()

func _apply_migrations() -> void:
	# 1. Remplacement absolu de dragibump par dragiburst
	if cards_inventory.has(&"dragibump"):
		var old_data: Dictionary = cards_inventory[&"dragibump"]
		if not cards_inventory.has(&"dragiburst"):
			cards_inventory[&"dragiburst"] = old_data.duplicate(true)
		else:
			var burst_data: Dictionary = cards_inventory[&"dragiburst"]
			burst_data["level"] = maxi(burst_data.get("level", 1), old_data.get("level", 1))
			burst_data["cards"] = maxi(burst_data.get("cards", 0), old_data.get("cards", 0))
			burst_data["unlocked"] = burst_data.get("unlocked", false) or old_data.get("unlocked", false)
		cards_inventory.erase(&"dragibump")

	# 2. Nettoyage des cartes obsolètes supprimées (standard, cherry, mint)
	cards_inventory.erase(&"standard")
	cards_inventory.erase(&"cherry")
	cards_inventory.erase(&"mint")

	# Remplacer toute occurrence d'anciennes cartes dans les decks
	for d in decks:
		for i in range(d.size()):
			if d[i] == &"dragibump":
				d[i] = &"dragiburst"
			elif d[i] == &"mint":
				d[i] = &"mentox"
			elif d[i] == &"standard" or d[i] == &"cherry":
				d[i] = &"fizz"

	# 3. S'assurer que les cartes obligatoires du catalogue existent
	var required_defaults: Dictionary = {
		&"fizz":          { "unlocked": true,  "level": 1, "cards": 3 },
		&"caramel":       { "unlocked": true,  "level": 1, "cards": 2 },
		&"mentox":        { "unlocked": true,  "level": 1, "cards": 2 },
		&"jawbreaker":    { "unlocked": false, "level": 1, "cards": 0 },
		&"dragiburst":    { "unlocked": true,  "level": 1, "cards": 2 },
		&"twistypop":     { "unlocked": true,  "level": 1, "cards": 2 },
		&"flying_saucer": { "unlocked": false, "level": 1, "cards": 0 },
	}
	for cid in required_defaults:
		if not cards_inventory.has(cid):
			cards_inventory[cid] = required_defaults[cid].duplicate(true)

	# S'assurer de 3 decks valides
	while decks.size() < 3:
		decks.append([&"fizz", &"caramel", &"mentox", &"fizz", &"twistypop", &"dragiburst"])
	for i in range(decks.size()):
		var d: Array = decks[i]
		while d.size() < 6:
			d.append(&"fizz")
		if d.size() > 6:
			d.resize(6)

	# 4. S'assurer d'un deck de Survie valide
	for i in range(survival_deck.size()):
		if survival_deck[i] == &"dragibump":
			survival_deck[i] = &"dragiburst"
		elif survival_deck[i] == &"mint":
			survival_deck[i] = &"mentox"
		elif survival_deck[i] == &"standard" or survival_deck[i] == &"cherry":
			survival_deck[i] = &"fizz"
	while survival_deck.size() < 6:
		if not decks.is_empty() and decks[0].size() > survival_deck.size():
			survival_deck.append(decks[0][survival_deck.size()])
		else:
			survival_deck.append(&"fizz")
	if survival_deck.size() > 6:
		survival_deck.resize(6)

static func create_default(p_id: String, is_sandbox: bool = false) -> RefCounted:
	var profile: RefCounted = (load("res://scripts/data/player_profile.gd") as GDScript).new()
	profile.profile_id = p_id

	if is_sandbox:
		profile.display_name = "Dev Sandbox 🧪"
		profile.account_type = "sandbox"
		profile.gold = 99999
		profile.diamonds = 5000
		profile.cards_inventory = {
			&"fizz":          { "unlocked": true, "level": 5, "cards": 50 },
			&"caramel":       { "unlocked": true, "level": 5, "cards": 50 },
			&"mentox":        { "unlocked": true, "level": 5, "cards": 50 },
			&"jawbreaker":    { "unlocked": true, "level": 5, "cards": 50 },
			&"dragiburst":    { "unlocked": true, "level": 5, "cards": 50 },
			&"twistypop":     { "unlocked": true, "level": 5, "cards": 50 },
			&"flying_saucer": { "unlocked": true, "level": 5, "cards": 50 },
		}
		profile.decks = [
			[&"jawbreaker", &"mentox", &"fizz", &"twistypop", &"dragiburst", &"flying_saucer"],
			[&"jawbreaker", &"caramel", &"mentox", &"fizz", &"dragiburst", &"twistypop"],
			[&"flying_saucer", &"fizz", &"caramel", &"dragiburst", &"mentox", &"twistypop"]
		]
		profile.survival_deck = [&"jawbreaker", &"mentox", &"fizz", &"twistypop", &"dragiburst", &"flying_saucer"]
	else:
		profile.display_name = "Gourmand"
		profile.account_type = "guest"
		profile.gold = 250
		profile.diamonds = 30
		profile.cards_inventory = {
			&"fizz":          { "unlocked": true,  "level": 1, "cards": 3 },
			&"caramel":       { "unlocked": true,  "level": 1, "cards": 2 },
			&"mentox":        { "unlocked": true,  "level": 1, "cards": 2 },
			&"jawbreaker":    { "unlocked": false, "level": 1, "cards": 0 },
			&"dragiburst":    { "unlocked": true,  "level": 1, "cards": 2 },
			&"twistypop":     { "unlocked": true,  "level": 1, "cards": 2 },
			&"flying_saucer": { "unlocked": false, "level": 1, "cards": 0 },
		}
		profile.decks = [
			[&"fizz", &"caramel", &"twistypop", &"mentox", &"fizz", &"dragiburst"],
			[&"fizz", &"caramel", &"twistypop", &"dragiburst", &"mentox", &"caramel"],
			[&"fizz", &"fizz", &"caramel", &"dragiburst", &"twistypop", &"mentox"]
		]
		profile.survival_deck = [&"fizz", &"caramel", &"twistypop", &"mentox", &"fizz", &"dragiburst"]

	# Boosters de bienvenue
	profile.available_boosters = [
		{
			"id": "silver_pop",
			"display_name": "🥈 Sachet Silver Pop",
			"booster_type": BoosterData.BoosterType.SILVER_POP,
			"min_gold": 50,
			"max_gold": 100
		},
		{
			"id": "golden_crush",
			"display_name": "🥇 Sachet Golden Crush",
			"booster_type": BoosterData.BoosterType.GOLDEN_CRUSH,
			"min_gold": 180,
			"max_gold": 350
		},
		{
			"id": "mystery_mix",
			"display_name": "🔮 Sachet Mystery Mix",
			"booster_type": BoosterData.BoosterType.MYSTERY_MIX,
			"min_gold": 100,
			"max_gold": 500
		},
		{
			"id": "diamond_dust",
			"display_name": "💎 Sachet Diamond Dust",
			"booster_type": BoosterData.BoosterType.DIAMOND_DUST,
			"min_gold": 600,
			"max_gold": 1200,
			"min_diamonds": 5,
			"max_diamonds": 10
		}
	]

	return profile
