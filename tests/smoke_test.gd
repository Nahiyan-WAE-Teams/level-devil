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
	game.call("_start_game")

	if game.get_node_or_null("Player") == null:
		push_error("Starting the game did not create a player")
		quit(1)
		return
	if game.get("platforms").size() != 2:
		push_error("The first room should create two platforms")
		quit(1)
		return
	if game.get("traps").size() != 1:
		push_error("The first room should create one hidden spike trap")
		quit(1)
		return

	game.call("_restart_level")
	if game.get_node_or_null("Player") == null or game.get("deaths") != 0:
		push_error("Restart did not restore the player cleanly")
		quit(1)
		return

	print("LEVEL DEVIL smoke test passed")
	quit(0)
