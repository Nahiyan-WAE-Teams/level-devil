extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	assert(packed_scene != null, "Main scene must load")

	var game: Node = packed_scene.instantiate()
	root.add_child(game)
	await process_frame

	game.call("_start_game")
	await process_frame

	assert(game.get_node_or_null("Player") != null, "Starting the game must create a player")
	assert(game.get("platforms").size() == 2, "The first room must build its two platforms")
	assert(game.get("traps").size() == 1, "The first room must build its hidden spike trap")

	game.call("_restart_level")
	await process_frame
	assert(game.get_node_or_null("Player") != null, "Restarting must restore the player")
	assert(game.get("deaths") == 0, "A manual restart must not count as a death")

	print("LEVEL DEVIL smoke test passed")
	quit(0)
