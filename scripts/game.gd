extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const TRAP_SCRIPT = preload("res://scripts/trap.gd")
const CATALOG = preload("res://scripts/level_catalog.gd")
const SAVE_PATH := "user://level_devil_progress.cfg"
const VIEW_SIZE := Vector2(960, 540)

var screen := "title"
var selected_world := 0
var selected_level := 0
var highest_completed := -1
var deaths := 0
var paused := false
var touch_left := false
var touch_right := false
var jump_just_pressed := false
var player: DevilPlayer
var platforms: Array[StaticBody2D] = []
var traps: Array[DevilTrap] = []
var revealed_spikes: Array[Rect2] = []
var exit_area: Area2D
var door_open := false
var fake_door_visible := true
var toast := ""
var toast_time := 0.0
var completion_text := ""
var screen_time := 0.0
var shake_time := 0.0
var shake_strength := 0.0
var particles: Array[Dictionary] = []

func _ready() -> void:
	_load_progress()
	queue_redraw()

func _process(delta: float) -> void:
	screen_time += delta
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast = ""
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle["position"] = particle["position"] + particle["velocity"] * delta
		particle["velocity"] = particle["velocity"] + Vector2(0, 280) * delta
		particle["life"] = float(particle["life"]) - delta
		particles[index] = particle
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if screen != "playing" or paused or player == null:
		return
	player.global_position.x = clampf(player.global_position.x, 12.0, 948.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			if screen == "title":
				_open_world_select()
			elif screen == "world_select":
				_open_level_select()
			elif screen == "level_select":
				_start_game()
			elif screen == "complete":
				_continue_after_level()
		elif event.keycode == KEY_ESCAPE:
			if screen == "playing":
				paused = true
				screen = "paused"
			elif screen == "paused":
				paused = false
				screen = "playing"
		elif event.keycode == KEY_R and screen == "playing":
			_restart_level()
		queue_redraw()

	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_pointer(event.position, true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)

func _handle_pointer(point: Vector2, pressed: bool) -> void:
	if screen == "title":
		if pressed and Rect2(330, 340, 300, 64).has_point(point):
			_open_world_select()
		return
	if screen == "world_select":
		if not pressed:
			return
		if Rect2(28, 24, 120, 46).has_point(point):
			screen = "title"
		elif Rect2(110, 175, 350, 220).has_point(point):
			selected_world = 0
			_open_level_select()
		elif Rect2(500, 175, 350, 220).has_point(point) and CATALOG.is_level_unlocked(1, 0, highest_completed):
			selected_world = 1
			_open_level_select()
		queue_redraw()
		return
	if screen == "level_select":
		if not pressed:
			return
		if Rect2(28, 24, 120, 46).has_point(point):
			screen = "world_select"
			queue_redraw()
			return
		for index in range(CATALOG.level_count(selected_world)):
			var rect := _level_card_rect(index)
			if rect.has_point(point) and CATALOG.is_level_unlocked(selected_world, index, highest_completed):
				selected_level = index
				_start_game()
				return
		return
	if screen == "complete":
		if pressed and Rect2(330, 355, 300, 58).has_point(point):
			_continue_after_level()
		elif pressed and Rect2(330, 425, 300, 46).has_point(point):
			screen = "level_select"
			queue_redraw()
		return
	if screen == "paused":
		if pressed:
			if Rect2(330, 250, 300, 54).has_point(point):
				paused = false
				screen = "playing"
			elif Rect2(330, 318, 300, 54).has_point(point):
				_restart_level()
			elif Rect2(330, 386, 300, 54).has_point(point):
				paused = false
				screen = "level_select"
				_clear_level()
			queue_redraw()
		return
	if screen != "playing":
		return

	if pressed and Rect2(884, 16, 58, 58).has_point(point):
		paused = true
		screen = "paused"
		queue_redraw()
		return
	touch_left = pressed and point.y > 390.0 and point.x < 130.0
	touch_right = pressed and point.y > 390.0 and point.x >= 130.0 and point.x < 250.0
	if pressed and point.y > 390.0 and point.x > 760.0:
		jump_just_pressed = true

func _open_world_select() -> void:
	screen = "world_select"
	queue_redraw()

func _open_level_select() -> void:
	if not CATALOG.is_level_unlocked(selected_world, 0, highest_completed):
		selected_world = 0
	screen = "level_select"
	queue_redraw()

func _start_game() -> void:
	if not CATALOG.is_level_unlocked(selected_world, selected_level, highest_completed):
		return
	screen = "playing"
	paused = false
	_build_level()
	queue_redraw()

func _build_level() -> void:
	_clear_level()
	var definition := CATALOG.get_level(selected_world, selected_level)
	if definition.is_empty():
		screen = "level_select"
		return

	for platform_rect: Rect2 in definition.get("platforms", []):
		platforms.append(_make_platform(platform_rect))

	for moving_data: Dictionary in definition.get("moving_platforms", []):
		var moving_rect: Rect2 = moving_data["rect"]
		var moving_body := _make_platform(moving_rect)
		platforms.append(moving_body)
		var distance := float(moving_data.get("distance", 80.0))
		var speed := maxf(0.4, float(moving_data.get("speed", 1.0)))
		var base_x := moving_body.position.x
		var tween := create_tween().set_loops()
		tween.tween_property(moving_body, "position:x", base_x + distance, 1.0 / speed)
		tween.tween_property(moving_body, "position:x", base_x - distance, 2.0 / speed)
		tween.tween_property(moving_body, "position:x", base_x, 1.0 / speed)

	player = PLAYER_SCRIPT.new() as DevilPlayer
	player.name = "Player"
	player.z_index = 2
	player.position = Vector2(72, 430)
	player.controls = self
	player.died.connect(_on_player_died)
	add_child(player)

	for trap_data: Dictionary in definition.get("traps", []):
		var trap_rect: Rect2 = trap_data["rect"]
		var trap := TRAP_SCRIPT.new() as DevilTrap
		trap.configure(
			str(trap_data["type"]),
			trap_rect.size,
			trap_rect.position + trap_rect.size * 0.5,
			float(trap_data.get("distance", 0.0)),
			float(trap_data.get("speed", 1.0))
		)
		trap.activated.connect(_on_trap_activated)
		add_child(trap)
		traps.append(trap)

	_build_exit()
	var world_data := CATALOG.get_world(selected_world)
	toast = "%s  /  LEVEL %02d" % [world_data["name"], selected_level + 1]
	toast_time = 2.0

func _clear_level() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	for platform in platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	platforms.clear()
	for trap in traps:
		if is_instance_valid(trap):
			trap.queue_free()
	traps.clear()
	if is_instance_valid(exit_area):
		exit_area.queue_free()
	exit_area = null
	revealed_spikes.clear()
	door_open = false
	fake_door_visible = true

func _make_platform(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	body.z_index = -1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	visual.color = Color("#292d35")
	body.add_child(visual)

	var top_line := Line2D.new()
	top_line.points = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5)
	])
	top_line.width = 4.0
	top_line.default_color = Color("#e5a13a")
	body.add_child(top_line)
	add_child(body)
	return body

func _build_exit() -> void:
	exit_area = Area2D.new()
	exit_area.position = Vector2(890, 390)
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(42, 78)
	shape.shape = rectangle
	exit_area.add_child(shape)
	exit_area.body_entered.connect(_on_exit_entered)
	add_child(exit_area)

func _on_trap_activated(trap: DevilTrap) -> void:
	if player == null or not player.alive:
		return

	match trap.trap_type:
		"spikes":
			trap.disarm()
			revealed_spikes.append(Rect2(trap.position - Vector2(32, 12), Vector2(64, 24)))
			toast = "SURPRISE. THE FLOOR HAD TEETH."
			toast_time = 1.1
			player.die()
		"collapse":
			trap.disarm()
			var target := _nearest_platform(trap.position)
			if target != null:
				var tween := create_tween()
				tween.tween_property(target, "position:y", target.position.y + 100.0, 0.25)
				tween.tween_callback(target.queue_free)
				platforms.erase(target)
			toast = "THE FLOOR HAS LEFT THE CHAT."
			toast_time = 1.1
		"falling":
			trap.disarm()
			var block := _make_platform(Rect2(trap.position.x - 35.0, -110.0, 70.0, 70.0))
			var tween := create_tween()
			tween.tween_property(block, "position:y", 445.0, 0.48)
			tween.tween_callback(func() -> void:
				if player != null and player.alive and absf(player.global_position.x - block.position.x) < 52.0:
					player.die()
			)
			toast = "LOOK UP!"
			toast_time = 0.9
		"reverse":
			trap.disarm()
			player.apply_trap_effect("reverse", 3.5)
			toast = "LEFT IS RIGHT. GOOD LUCK."
			toast_time = 1.2
		"gravity":
			trap.disarm()
			player.apply_trap_effect("gravity", 2.4)
			toast = "GRAVITY HAS BEEN DISMISSED."
			toast_time = 1.2
		"saw":
			toast = "SHARP. VERY SHARP."
			toast_time = 0.8
			player.die()
		"fake_exit":
			trap.disarm()
			fake_door_visible = false
			if exit_area != null:
				exit_area.monitoring = false
			toast = "THAT WASN'T THE EXIT."
			toast_time = 1.0
			player.die()
	queue_redraw()

func _nearest_platform(at: Vector2) -> StaticBody2D:
	var closest: StaticBody2D
	var distance := INF
	for platform in platforms:
		if not is_instance_valid(platform):
			continue
		var current := platform.global_position.distance_to(at)
		if current < distance:
			distance = current
			closest = platform
	return closest

func _on_player_died() -> void:
	deaths += 1
	shake_time = 0.28
	shake_strength = 8.0
	_spawn_burst(player.global_position, Color("#e65b52"), 18)
	toast = "TRY AGAIN. THE DEVIL IS PATIENT."
	toast_time = 1.0
	_respawn()

func _respawn() -> void:
	await get_tree().create_timer(0.48).timeout
	if screen != "playing":
		return
	var discovered_spikes := revealed_spikes.duplicate()
	_build_level()
	revealed_spikes = discovered_spikes
	if is_instance_valid(exit_area):
		exit_area.monitoring = true
	fake_door_visible = true
	queue_redraw()

func _spawn_burst(at: Vector2, tint: Color, amount: int = 14) -> void:
	for index in range(amount):
		var angle := TAU * float(index) / float(amount) + randf_range(-0.2, 0.2)
		var speed := randf_range(55.0, 210.0)
		particles.append({"position": at, "velocity": Vector2(cos(angle), sin(angle)) * speed, "life": randf_range(0.28, 0.68), "max_life": 0.68, "size": randf_range(2.0, 5.0), "color": tint})

func _on_exit_entered(body: Node2D) -> void:
	if body != player or door_open or screen != "playing":
		return
	door_open = true
	_spawn_burst(Vector2(890, 390), Color("#e5a13a"), 28)
	var global_index := CATALOG.global_level_index(selected_world, selected_level)
	highest_completed = maxi(highest_completed, global_index)
	_save_progress()
	completion_text = "WORLD CLEARED" if selected_level == CATALOG.level_count(selected_world) - 1 else "LEVEL CLEARED"
	screen = "complete"
	queue_redraw()

func _continue_after_level() -> void:
	if selected_level < CATALOG.level_count(selected_world) - 1:
		selected_level += 1
		_start_game()
	elif selected_world < CATALOG.world_count() - 1 and CATALOG.is_level_unlocked(selected_world + 1, 0, highest_completed):
		selected_world += 1
		selected_level = 0
		screen = "level_select"
		queue_redraw()
	else:
		screen = "level_select"
		queue_redraw()

func _restart_level() -> void:
	screen = "playing"
	paused = false
	_build_level()
	queue_redraw()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_completed = int(config.get_value("progress", "highest_completed", -1))

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_completed", highest_completed)
	config.save(SAVE_PATH)

func _level_card_rect(index: int) -> Rect2:
	var column := index % 2
	var row := int(index / 2)
	return Rect2(190 + column * 310, 135 + row * 112, 270, 88)

func _draw() -> void:
	if screen == "playing" or screen == "paused":
		var shake := Vector2.ZERO
		if shake_time > 0.0:
			shake = Vector2(sin(screen_time * 91.0), cos(screen_time * 73.0)) * shake_strength * (shake_time / 0.28)
		draw_set_transform(shake, 0.0, Vector2.ONE)
	_draw_backdrop()
	match screen:
		"title":
			_draw_title_screen()
		"world_select":
			_draw_world_select()
		"level_select":
			_draw_level_select()
		"playing":
			_draw_level_art()
			_draw_hud()
			_draw_touch_controls()
		"paused":
			_draw_level_art()
			_draw_hud()
			_draw_pause_screen()
		"complete":
			_draw_completion_screen()
	_draw_particles()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_backdrop() -> void:
	var base := Color("#11141a")
	if selected_world == 1:
		base = Color("#151317")
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), base)
	for index in range(9):
		var x := float(index) * 124.0 - 30.0
		var sway := sin(screen_time * 0.22 + float(index)) * 5.0
		draw_colored_polygon(PackedVector2Array([Vector2(x + sway, 70), Vector2(x + 76 + sway, 70), Vector2(x + 76 + sway, 430), Vector2(x + sway, 430)]), Color(0.20, 0.23, 0.28, 0.10))
		draw_line(Vector2(x + 8 + sway, 82), Vector2(x + 8 + sway, 418), Color(0.55, 0.58, 0.64, 0.07), 1.0)
	for i in range(34):
		var x := float((i * 173) % 960)
		var y := float((i * 97) % 520)
		draw_circle(Vector2(x, y), 1.1, Color(0.75, 0.78, 0.84, 0.15))
	for index in range(16):
		var x := float(index) * 64.0
		draw_line(Vector2(x, 500), Vector2(x - 45, 540), Color(0.42, 0.46, 0.52, 0.10), 1.0)
	draw_rect(Rect2(0, 0, 960, 5), Color("#e5a13a"))
	draw_rect(Rect2(0, 535, 960, 5), Color("#272d36"))
	draw_rect(Rect2(0, 0, 960, 82), Color(0.02, 0.025, 0.035, 0.34))

func _draw_particles() -> void:
	for particle in particles:
		var life_ratio := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var tint: Color = particle["color"]
		tint.a = life_ratio
		draw_circle(particle["position"], float(particle["size"]) * life_ratio, tint)

func _draw_title_screen() -> void:
	draw_rect(Rect2(180, 105, 600, 310), Color(0.07, 0.08, 0.10, 0.64))
	draw_rect(Rect2(180, 105, 600, 310), Color(0.82, 0.56, 0.24, 0.34), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(0, 165), "A GAME OF BAD DECISIONS", HORIZONTAL_ALIGNMENT_CENTER, 960, 13, Color("#9299a4"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 225), "LEVEL", HORIZONTAL_ALIGNMENT_CENTER, 960, 42, Color("#e7e4dc"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 296), "DEVIL", HORIZONTAL_ALIGNMENT_CENTER, 960, 78, Color("#e5a13a"))
	draw_rect(Rect2(390, 315, 180, 2), Color("#e5a13a"))
	_draw_button(Rect2(330, 350, 300, 62), "START GAME", true)
	draw_string(ThemeDB.fallback_font, Vector2(0, 478), "10 ROOMS  /  2 WORLDS  /  ABSOLUTELY NO TRUST", HORIZONTAL_ALIGNMENT_CENTER, 960, 13, Color("#858b96"))

func _draw_world_select() -> void:
	_draw_back_button()
	draw_string(ThemeDB.fallback_font, Vector2(0, 100), "CHOOSE YOUR WORLD", HORIZONTAL_ALIGNMENT_CENTER, 960, 28, Color("#f2f0e8"))
	for index in range(CATALOG.world_count()):
		var world: Dictionary = CATALOG.get_world(index)
		var rect := Rect2(110 + index * 390, 175, 350, 220)
		var unlocked := CATALOG.is_level_unlocked(index, 0, highest_completed)
		var accent: Color = world["accent"] if unlocked else Color("#555b65")
		draw_rect(rect, Color("#20252d"))
		draw_rect(rect, accent, false, 2.0)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6)), accent)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 72), "WORLD  %02d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 300, 14, accent)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 116), str(world["name"]), HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color("#f2f0e8") if unlocked else Color("#8a8f98"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 150), str(world["subtitle"]), HORIZONTAL_ALIGNMENT_LEFT, 300, 13, Color("#a7abb4"))
		var status := "5 LEVELS  /  AVAILABLE" if unlocked else "LOCKED  /  CLEAR WORLD 01"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 190), status, HORIZONTAL_ALIGNMENT_LEFT, 310, 12, accent)
	draw_string(ThemeDB.fallback_font, Vector2(0, 465), "COMPLETE LEVELS TO UNLOCK THE NEXT WORLD", HORIZONTAL_ALIGNMENT_CENTER, 960, 13, Color("#858b96"))

func _draw_level_select() -> void:
	_draw_back_button()
	var world: Dictionary = CATALOG.get_world(selected_world)
	draw_string(ThemeDB.fallback_font, Vector2(0, 88), str(world["name"]), HORIZONTAL_ALIGNMENT_CENTER, 960, 26, Color("#f2f0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 112), str(world["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 960, 12, Color("#8f96a2"))
	for index in range(CATALOG.level_count(selected_world)):
		var rect := _level_card_rect(index)
		var unlocked := CATALOG.is_level_unlocked(selected_world, index, highest_completed)
		var completed := CATALOG.global_level_index(selected_world, index) <= highest_completed
		var accent := Color("#e5a13a") if unlocked else Color("#4b515b")
		draw_rect(rect, Color("#20252d") if unlocked else Color("#191d24"))
		draw_rect(rect, accent, false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 31), "%02d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 38, 22, accent)
		var level: Dictionary = CATALOG.get_level(selected_world, index)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(68, 34), str(level["name"]), HORIZONTAL_ALIGNMENT_LEFT, 190, 15, Color("#f2f0e8") if unlocked else Color("#777e89"))
		var state := "CLEARED" if completed else ("TAP TO PLAY" if unlocked else "LOCKED")
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(68, 62), state, HORIZONTAL_ALIGNMENT_LEFT, 180, 11, accent)

func _draw_back_button() -> void:
	_draw_button(Rect2(28, 24, 120, 46), "BACK", false, false)

func _draw_button(rect: Rect2, label: String, selected: bool = false, disabled: bool = false) -> void:
	var fill := Color("#e5a13a") if selected or not disabled else Color("#303640")
	var border := Color("#e5a13a") if not disabled else Color("#555b65")
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17, Color("#17191f") if not disabled else Color("#858b96"))

func _draw_level_art() -> void:
	if fake_door_visible:
		draw_rect(Rect2(866, 344, 48, 86), Color("#d7d2c6"))
		draw_rect(Rect2(872, 350, 36, 80), Color("#242832"))
		draw_circle(Vector2(899, 391), 3, Color("#e5a13a"))
	for spike_rect in revealed_spikes:
		for index in range(4):
			var sx := spike_rect.position.x + float(index) * 16.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx, spike_rect.end.y),
				Vector2(sx + 8, spike_rect.position.y),
				Vector2(sx + 16, spike_rect.end.y)
			]), Color("#e65b52"))
	draw_rect(Rect2(0, 430, 960, 110), Color(0.03, 0.035, 0.045, 0.65))

func _draw_hud() -> void:
	var definition: Dictionary = CATALOG.get_level(selected_world, selected_level)
	draw_rect(Rect2(16, 14, 928, 62), Color(0.055, 0.065, 0.08, 0.88))
	draw_rect(Rect2(16, 14, 928, 62), Color(0.65, 0.68, 0.74, 0.18), false, 1.0)
	draw_rect(Rect2(16, 14, 4, 62), Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(32, 38), "WORLD %02d  /  LEVEL %02d" % [selected_world + 1, selected_level + 1], HORIZONTAL_ALIGNMENT_LEFT, 300, 14, Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(32, 59), str(definition.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, 360, 12, Color("#e7e4dc"))
	draw_string(ThemeDB.fallback_font, Vector2(480, 45), str(definition.get("hint", "")), HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color("#a0a6b0"))
	draw_string(ThemeDB.fallback_font, Vector2(850, 38), "DEATHS %02d" % deaths, HORIZONTAL_ALIGNMENT_RIGHT, 90, 12, Color("#a7abb4"))
	if toast_time > 0.0 and toast != "":
		draw_rect(Rect2(210, 91, 540, 34), Color(0.07, 0.08, 0.10, 0.90))
		draw_rect(Rect2(210, 91, 3, 34), Color("#e5a13a"))
		draw_string(ThemeDB.fallback_font, Vector2(220, 113), toast, HORIZONTAL_ALIGNMENT_CENTER, 520, 13, Color("#f0c16c"))

func _draw_touch_controls() -> void:
	draw_rect(Rect2(18, 426, 220, 96), Color(0.04, 0.05, 0.07, 0.40))
	draw_rect(Rect2(722, 426, 220, 96), Color(0.04, 0.05, 0.07, 0.40))
	_draw_control(Vector2(72, 474), "‹", touch_left)
	_draw_control(Vector2(174, 474), "›", touch_right)
	_draw_control(Vector2(858, 474), "↑", false)
	_draw_button(Rect2(884, 16, 58, 58), "Ⅱ", false, false)

func _draw_control(center: Vector2, label: String, active: bool) -> void:
	draw_circle(center + Vector2(0, 3), 38, Color(0, 0, 0, 0.30))
	draw_circle(center, 35, Color(0.09, 0.10, 0.13, 0.90))
	draw_arc(center, 33, 0.0, TAU, 48, Color("#e5a13a") if active else Color(0.72, 0.74, 0.78, 0.55), 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-13, 10), label, HORIZONTAL_ALIGNMENT_CENTER, 26, 28, Color("#f2f0e8"))

func _draw_pause_screen() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0, 0, 0, 0.78))
	draw_string(ThemeDB.fallback_font, Vector2(0, 190), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 960, 36, Color("#f2f0e8"))
	_draw_button(Rect2(330, 250, 300, 54), "RESUME", true)
	_draw_button(Rect2(330, 318, 300, 54), "RESTART")
	_draw_button(Rect2(330, 386, 300, 54), "LEVEL SELECT")

func _draw_completion_screen() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#11141a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 195), completion_text, HORIZONTAL_ALIGNMENT_CENTER, 960, 34, Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 238), "DEATHS: %02d" % deaths, HORIZONTAL_ALIGNMENT_CENTER, 960, 15, Color("#a7abb4"))
	_draw_button(Rect2(330, 355, 300, 58), "CONTINUE", true)
	_draw_button(Rect2(330, 425, 300, 46), "LEVEL SELECT")
