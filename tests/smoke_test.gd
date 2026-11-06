extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	if packed_scene == null:
		push_error("Main scene failed to load")
		quit(1)
		return

	var game: Node = packed_scene.instantiate()
	root.add_child(game)
	if game.get("screen") != "title":
		push_error("The game must open on its title screen")
		quit(1)
		return

	game.call("_open_world_select")
	if game.get("screen") != "world_select":
		push_error("World selection must open from the title screen")
		quit(1)
		return

	game.set("selected_world", 1)
	game.call("_open_level_select")
	if game.get("selected_world") != 0:
		push_error("Locked worlds must not open before world one is cleared")
		quit(1)
		return

	game.call("_start_game")
	if game.get_node_or_null("Player") == null:
		push_error("Starting the game must create a player")
		quit(1)
		return
	if game.get("platforms").size() != 2:
		push_error("The first room must create two platforms")
		quit(1)
		return
	if game.get("traps").size() != 1:
		push_error("The first room must create one hidden spike trap")
		quit(1)
		return

	game.call("_restart_level")
	if game.get_node_or_null("Player") == null or game.get("deaths") != 0:
		push_error("Restart must restore the player without counting a death")
		quit(1)
		return

	var player: DevilPlayer = game.get("player")
	player.apply_trap_effect("reverse", 2.0)
	if player.reverse_time < 1.9:
		push_error("Reverse-control effect did not activate")
		quit(1)
		return
	player.apply_trap_effect("gravity", 2.0)
	if player.gravity_flip_time < 1.9:
		push_error("Gravity effect did not activate")
		quit(1)
		return

	game.call("_handle_pointer", Vector2(72, 474), true, 1)
	game.call("_handle_pointer", Vector2(174, 474), true, 2)
	if not game.get("touch_left") or not game.get("touch_right"):
		push_error("Two simultaneous fingers must control both movement directions")
		quit(1)
		return
	game.call("_handle_pointer", Vector2(72, 474), false, 1)
	if game.get("touch_left") or not game.get("touch_right"):
		push_error("Releasing one finger must not cancel another finger's control")
		quit(1)
		return
	game.call("_handle_pointer", Vector2(858, 474), true, 3)
	if not game.get("jump_just_pressed"):
		push_error("The jump touch zone must register a press")
		quit(1)
		return
	game.call("_handle_pointer", Vector2(858, 474), false, 3)
	game.call("_handle_pointer", Vector2(174, 474), false, 2)

	var pause_event := InputEventKey.new()
	pause_event.keycode = KEY_ESCAPE
	pause_event.pressed = true
	game.call("_input", pause_event)
	if game.get("screen") != "paused":
		push_error("Escape must open the pause screen")
		quit(1)
		return
	game.call("_input", pause_event)
	if game.get("screen") != "playing":
		push_error("Escape must resume from the pause screen")
		quit(1)
		return

	print("LEVEL DEVIL gameplay smoke test passed")
	quit(0)
