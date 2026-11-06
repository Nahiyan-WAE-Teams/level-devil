extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(LevelCatalog.world_count() == 2, "The game must expose two worlds")
	assert(LevelCatalog.level_count(0) == 5, "World one must contain five levels")
	assert(LevelCatalog.level_count(1) == 5, "World two must contain five levels")
	assert(LevelCatalog.level_count(2) == 0, "Unknown worlds must have no levels")
	assert(LevelCatalog.is_level_unlocked(0, 0, 0), "The first level must always be unlocked")
	assert(not LevelCatalog.is_level_unlocked(0, 1, 0), "Later levels must remain locked until progress")
	assert(LevelCatalog.is_level_unlocked(0, 1, 1), "Progress must unlock the next level")
	assert(LevelCatalog.is_level_unlocked(1, 0, 4), "A completed first world must unlock the next world")
	assert(not LevelCatalog.is_level_unlocked(1, 0, 3), "An incomplete first world must not unlock the next world")
	print("LEVEL DEVIL catalog tests passed")
	quit(0)
