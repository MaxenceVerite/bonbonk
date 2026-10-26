class_name DevConsole
extends Control

## Console développeur activable via F1 pour comptes dev / sandbox.
## Permet d'exécuter des commandes de debug : wave, heal, boss, killall, gold, etc.

@onready var panel: PanelContainer = $CenterAnchor/ConsolePanel
@onready var log_output: RichTextLabel = $CenterAnchor/ConsolePanel/VBox/LogScroll/LogOutput
@onready var command_input: LineEdit = $CenterAnchor/ConsolePanel/VBox/HBoxInput/CommandInput
@onready var btn_close: Button = $CenterAnchor/ConsolePanel/VBox/HBoxInput/BtnClose
@onready var status_badge: Label = $CenterAnchor/ConsolePanel/VBox/HBoxHeader/StatusBadge

var command_history: Array[String] = []
var history_index: int = -1

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if btn_close != null:
		btn_close.pressed.connect(toggle_console)
	if command_input != null:
		command_input.text_submitted.connect(_on_command_submitted)

	print_log("[color=#45d65b]Flip Dev Console 1.0[/color] initialisée. Tapez [color=#ffe600]help[/color] pour voir la liste des commandes.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F1:
			toggle_console()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			toggle_console()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()

func toggle_console() -> void:
	# Vérification stricte du compte de dev
	if not SaveManager.is_dev_account():
		if visible:
			visible = false
		return

	visible = not visible
	if visible:
		command_input.grab_focus()
		history_index = command_history.size()
		if status_badge != null:
			status_badge.text = "[DEV: %s]" % SaveManager.active_profile_id.to_upper()
	else:
		command_input.release_focus()

func print_log(bbcode_text: String) -> void:
	if log_output != null:
		log_output.append_text(bbcode_text + "\n")

func _navigate_history(direction: int) -> void:
	if command_history.is_empty():
		return
	history_index = clamp(history_index + direction, 0, command_history.size())
	if history_index < command_history.size():
		command_input.text = command_history[history_index]
		command_input.caret_column = command_input.text.length()
	else:
		command_input.text = ""

func _on_command_submitted(text: String) -> void:
	var raw_cmd: String = text.strip_edges()
	command_input.text = ""
	if raw_cmd.is_empty():
		return

	command_history.append(raw_cmd)
	history_index = command_history.size()

	print_log("[color=#88c0d0]> %s[/color]" % raw_cmd)
	_execute_command(raw_cmd)

func _execute_command(input: String) -> void:
	var parts: PackedStringArray = input.split(" ", false)
	if parts.is_empty():
		return

	var cmd: String = parts[0].to_lower()
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	var main_node: Node = _find_main_node()

	match cmd:
		"help", "?":
			print_log("[color=#e5c07b]--- COMMANDES DISPONIBLES ---[/color]")
			print_log("[color=#98c379]wave <X>[/color] / [color=#98c379]manche <X>[/color] : saute immédiatement à la manche X (ex: wave 10)")
			print_log("[color=#98c379]boss[/color] : fait apparaître instantanément le boss Brocolino")
			print_log("[color=#98c379]killall[/color] / [color=#98c379]clear[/color] : élimine tous les ennemis présents")
			print_log("[color=#98c379]heal[/color] : soigne le joueur à 100% de ses PV")
			print_log("[color=#98c379]hp <val>[/color] : définit précisément les PV du joueur")
			print_log("[color=#98c379]god[/color] : active / désactive l'invulnérabilité du joueur")
			print_log("[color=#98c379]gold <nb>[/color] : ajoute ou retire de l'or")
			print_log("[color=#98c379]diamonds <nb>[/color] : ajoute ou retire des diamants")
			print_log("[color=#98c379]brocs[/color] : fait pousser 3 bumpers brocolis sur les slots")
			print_log("[color=#98c379]unlockall[/color] : débloque toutes les cartes au niveau max")
			print_log("[color=#98c379]cls[/color] : efface les logs de la console")

		"cls", "clearlog":
			if log_output != null:
				log_output.clear()

		"wave", "manche", "w":
			if args.is_empty():
				print_log("[color=#e06c75]Erreur: spécifiez le numéro de manche. Ex: wave 10[/color]")
				return
			var target_w: int = args[0].to_int()
			if target_w <= 0:
				print_log("[color=#e06c75]Erreur: la manche doit être >= 1[/color]")
				return
			if main_node != null and main_node.has_method(&"dev_jump_to_wave"):
				main_node.dev_jump_to_wave(target_w)
				print_log("[color=#61afef]Saut réussi à la manche %d ![/color]" % target_w)
			else:
				print_log("[color=#e06c75]Erreur: Main introuvable[/color]")

		"boss", "brocolino", "carambine":
			if main_node != null:
				var board: Board = main_node.get_node_or_null("Board") as Board
				var boss_scene: String = "res://scenes/enemies/boss_brocolino.tscn"
				var boss_lbl: String = "Brocolino"
				if cmd == "carambine" or (not args.is_empty() and args[0].to_lower() == "carambine"):
					boss_scene = "res://scenes/enemies/boss_carambine.tscn"
					boss_lbl = "Carambine"
				if board != null and board.is_game_running:
					board.spawn_enemy_by_path(boss_scene, 310.0)
					print_log("[color=#98c379]Boss %s invoqué sur le terrain ![/color]" % boss_lbl)
				else:
					main_node.dev_jump_to_wave(10)
					print_log("[color=#98c379]Lancement de la manche 10 (Boss) ![/color]")

		"killall", "kill":
			if main_node != null and main_node.has_method(&"dev_kill_all_enemies"):
				main_node.dev_kill_all_enemies()
				print_log("[color=#98c379]Tous les ennemis ont été éliminés.[/color]")

		"heal":
			if main_node != null and main_node.has_method(&"dev_heal_full"):
				main_node.dev_heal_full()
				print_log("[color=#98c379]Joueur soigné à 100%.[/color]")

		"hp":
			if args.is_empty():
				print_log("[color=#e06c75]Syntaxe: hp <valeur>[/color]")
				return
			var val: int = args[0].to_int()
			if main_node != null and main_node.has_method(&"dev_set_hp"):
				main_node.dev_set_hp(val)
				print_log("[color=#98c379]PV fixés à %d.[/color]" % val)

		"god":
			if main_node != null and main_node.has_method(&"dev_toggle_god_mode"):
				var active: bool = main_node.dev_toggle_god_mode()
				var msg: String = "ACTIVÉ" if active else "DÉSACTIVÉ"
				print_log("[color=#e5c07b]Mode God : %s[/color]" % msg)

		"gold":
			if args.is_empty():
				print_log("[color=#e06c75]Syntaxe: gold <montant>[/color]")
				return
			var delta: int = args[0].to_int()
			SaveManager.add_gold(delta)
			print_log("[color=#ffd700]Or ajusté de %+d (Total: %d)[/color]" % [delta, SaveManager.gold])

		"diamonds", "dia":
			if args.is_empty():
				print_log("[color=#e06c75]Syntaxe: diamonds <montant>[/color]")
				return
			var delta: int = args[0].to_int()
			SaveManager.add_diamonds(delta)
			print_log("[color=#00e5ff]Diamants ajustés de %+d (Total: %d)[/color]" % [delta, SaveManager.diamonds])

		"brocs", "broccoli":
			var board: Board = null
			if main_node != null:
				board = main_node.get_node_or_null("Board") as Board
			if board != null:
				var brocs = board.spawn_broccoli_bumpers(3)
				print_log("[color=#98c379]%d Bumpers Brocolis invoqués sur les slots ![/color]" % brocs.size())

		"unlockall":
			SaveManager.sandbox_unlock_all()
			print_log("[color=#98c379]Toutes les cartes débloquées (profil sandbox).[/color]")

		_:
			print_log("[color=#e06c75]Commande inconnue: '%s'. Tapez 'help' pour la liste.[/color]" % cmd)

func _find_main_node() -> Node:
	var cur: Node = get_tree().current_scene
	if cur != null and cur.has_method(&"dev_jump_to_wave"):
		return cur
	# Recherche parmi les enfants ou parents
	var p: Node = get_parent()
	while p != null:
		if p.has_method(&"dev_jump_to_wave"):
			return p
		p = p.get_parent()
	# Recherche dans la racine de la scène
	if get_tree().root != null:
		for child in get_tree().root.get_children():
			if child.has_method(&"dev_jump_to_wave"):
				return child
			var m = child.find_child("Main", true, false)
			if m != null and m.has_method(&"dev_jump_to_wave"):
				return m
	return cur
