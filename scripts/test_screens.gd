extends SceneTree

func _init():
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	print("--- DIAGNOSTIC ECRANS ---")
	print("current_screen_state = ", main.current_screen_state)
	print("title_screen.visible = ", main.title_screen.visible)
	print("title_screen.modulate.a = ", main.title_screen.modulate.a)
	print("title_screen.size = ", main.title_screen.size)
	print("main_menu.visible = ", main.main_menu.visible)
	print("hud.visible = ", main.hud.visible)
	print("touch_controls.visible = ", main.touch_controls.visible)
	print("board.is_game_running = ", main.board.is_game_running)
	print("-------------------------")
	quit()
