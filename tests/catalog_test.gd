extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(LevelCatalog.world_count() == 2, "The game must expose two worlds")
	assert(LevelCatalog.level_count(0) == 10, "World one must contain ten levels")
	assert(LevelCatalog.level_count(1) == 10, "World two must contain ten levels")
	assert(LevelCatalog.level_count(2) == 0, "Unknown worlds must have no levels")
	assert(LevelCatalog.is_level_unlocked(0, 0, 0), "The first level must always be unlocked")
	assert(not LevelCatalog.is_level_unlocked(0, 1, -1), "Later levels must remain locked until the first level is cleared")
	assert(LevelCatalog.is_level_unlocked(0, 1, 0), "Clearing the first level must unlock the next level")
	assert(LevelCatalog.is_level_unlocked(1, 0, 9), "A completed first world must unlock the next world")
	assert(not LevelCatalog.is_level_unlocked(1, 0, 8), "An incomplete first world must not unlock the next world")
	assert(LevelCatalog.global_level_index(1, 9) == 19, "The final level must be level twenty")
	for world_index in range(LevelCatalog.world_count()):
		for level_index in range(LevelCatalog.level_count(world_index)):
			var level: Dictionary = LevelCatalog.get_level(world_index, level_index)
			assert(not str(level.get("name", "")).is_empty(), "Every level needs a name")
			assert(not (level.get("platforms", []) as Array).is_empty(), "Every level needs at least one platform")
			for trap: Dictionary in level.get("traps", []):
				assert(trap.has("type") and trap.has("rect"), "Every trap needs a type and rectangle")
	print("LEVEL DEVIL catalog tests passed")
	quit(0)
