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
	available_boosters = data.get("available_boosters", []).duplicate(true)
	pending_sync_actions = data.get("pending_sync_actions", []).duplicate(true)
	stats = data.get("stats", { "best_score": 0, "games_played": 0, "enemies_defeated": 0 }).duplicate(true)

	# Auto-migration de schéma si nécessaire
	_apply_migrations()

func _apply_migrations() -> void:
	# S'assurer que les cartes obligatoires existent
	var required_defaults: Dictionary = {
		&"standard":   { "unlocked": true,  "level": 1, "cards": 3 },
		&"fizz":       { "unlocked": true,  "level": 1, "cards": 1 },
		&"caramel":    { "unlocked": true,  "level": 1, "cards": 2 },
		&"cherry":     { "unlocked": false, "level": 1, "cards": 0 },
		&"mentox":     { "unlocked": true,  "level": 1, "cards": 2 },
		&"jawbreaker": { "unlocked": false, "level": 1, "cards": 0 },
		&"dragibump":  { "unlocked": true,  "level": 1, "cards": 2 },
	}
	for cid in required_defaults:
		if not cards_inventory.has(cid):
			cards_inventory[cid] = required_defaults[cid].duplicate(true)

	# S'assurer de 3 decks valides
	while decks.size() < 3:
		decks.append([&"standard", &"fizz", &"caramel", &"standard", &"fizz", &"dragibump"])
	for i in range(decks.size()):
		var d: Array = decks[i]
		while d.size() < 6:
			d.append(&"standard")
		if d.size() > 6:
			d.resize(6)

static func create_default(p_id: String, is_sandbox: bool = false) -> RefCounted:
	var profile: RefCounted = (load("res://scripts/data/player_profile.gd") as GDScript).new()
	profile.profile_id = p_id

	if is_sandbox:
		profile.display_name = "Dev Sandbox 🧪"
		profile.account_type = "sandbox"
		profile.gold = 99999
		profile.diamonds = 5000
		profile.cards_inventory = {
			&"standard":   { "unlocked": true, "level": 5, "cards": 50 },
			&"fizz":       { "unlocked": true, "level": 5, "cards": 50 },
			&"caramel":    { "unlocked": true, "level": 5, "cards": 50 },
			&"cherry":     { "unlocked": true, "level": 5, "cards": 50 },
			&"mentox":     { "unlocked": true, "level": 5, "cards": 50 },
			&"jawbreaker": { "unlocked": true, "level": 5, "cards": 50 },
			&"dragibump":  { "unlocked": true, "level": 5, "cards": 50 },
		}
		profile.decks = [
			[&"jawbreaker", &"mentox", &"fizz", &"caramel", &"dragibump", &"standard"],
			[&"jawbreaker", &"jawbreaker", &"mentox", &"fizz", &"dragibump", &"dragibump"],
			[&"standard", &"fizz", &"caramel", &"dragibump", &"mentox", &"jawbreaker"]
		]
	else:
		profile.display_name = "Gourmand"
		profile.account_type = "guest"
		profile.gold = 250
		profile.diamonds = 30
		profile.cards_inventory = {
			&"standard":   { "unlocked": true,  "level": 1, "cards": 3 },
			&"fizz":       { "unlocked": true,  "level": 1, "cards": 1 },
			&"caramel":    { "unlocked": true,  "level": 1, "cards": 2 },
			&"cherry":     { "unlocked": false, "level": 1, "cards": 0 },
			&"mentox":     { "unlocked": true,  "level": 1, "cards": 2 },
			&"jawbreaker": { "unlocked": false, "level": 1, "cards": 0 },
			&"dragibump":  { "unlocked": true,  "level": 1, "cards": 2 },
		}
		profile.decks = [
			[&"standard", &"fizz", &"caramel", &"standard", &"fizz", &"dragibump"],
			[&"standard", &"caramel", &"caramel", &"dragibump", &"standard", &"standard"],
			[&"fizz", &"fizz", &"caramel", &"dragibump", &"standard", &"caramel"]
		]

	# Boosters de bienvenue
	profile.available_boosters = [
		{
			"id": "classic_solo",
			"display_name": "🍬 Sachet Classique",
			"booster_type": BoosterData.BoosterType.CLASSIC_SOLO,
			"min_gold": 40,
			"max_gold": 80
		},
		{
			"id": "pop_solo",
			"display_name": "⭐ Sachet Pop Acidulé",
			"booster_type": BoosterData.BoosterType.POP_SOLO,
			"min_gold": 120,
			"max_gold": 220
		}
	]

	return profile
