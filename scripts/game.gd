extends Node2D

const PLAYER_SCENE_SCRIPT = preload("res://scripts/player.gd")
const TRAP_SCRIPT = preload("res://scripts/trap.gd")
const SAVE_PATH := "user://level_devil_progress.cfg"
const VIEW_SIZE := Vector2(960, 540)

const LEVELS := [
	{
		"name": "A FRIENDLY START",
		"hint": "THE FLOOR LOOKS PERFECTLY SAFE.",
		"platforms": [Rect2(0, 430, 370, 110), Rect2(430, 430, 530, 110)],
		"traps": [{"type": "spikes", "rect": Rect2(535, 390, 54, 80)}]
	},
	{
		"name": "TRUST ISSUES",
		"hint": "SOME FLOORS HAVE A SHORT MEMORY.",
		"platforms": [Rect2(0, 430, 300, 110), Rect2(360, 430, 250, 110), Rect2(670, 430, 290, 110)],
		"traps": [{"type": "collapse", "rect": Rect2(430, 400, 74, 60)}]
	},
	{
		"name": "LOOK UP",
		"hint": "THE CEILING IS PAYING ATTENTION.",
		"platforms": [Rect2(0, 430, 420, 110), Rect2(480, 430, 480, 110)],
		"traps": [{"type": "falling", "rect": Rect2(580, 330, 70, 100)}]
	},
	{
		"name": "POINTY BUSINESS",
		"hint": "THAT EMPTY SPACE ISN'T EMPTY.",
		"platforms": [Rect2(0, 430, 250, 110), Rect2(310, 430, 250, 110), Rect2(620, 430, 340, 110)],
		"traps": [{"type": "spikes", "rect": Rect2(385, 390, 64, 80)}, {"type": "collapse", "rect": Rect2(690, 400, 70, 60)}]
	},
	{
		"name": "THE LAST DOOR",
		"hint": "YOU REALLY THOUGHT IT WAS OVER?",
		"platforms": [Rect2(0, 430, 320, 110), Rect2(380, 430, 210, 110), Rect2(650, 430, 310, 110)],
		"traps": [{"type": "falling", "rect": Rect2(710, 320, 76, 110)}, {"type": "spikes", "rect": Rect2(500, 390, 58, 80)}]
	}
]

var player: DevilPlayer
var level_index := 0
var deaths := 0
var best_unlocked := 0
var started := false
var paused := false
var touch_left := false
var touch_right := false
var jump_just_pressed := false
var platforms: Array[StaticBody2D] = []
var traps: Array[DevilTrap] = []
var revealed_spikes: Array[Rect2] = []
var exit_area: Area2D
var door_open := false
var toast := ""
var toast_time := 0.0

func _ready() -> void:
	_load_progress()
	queue_redraw()

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast = ""
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not started or paused:
		return
	if player != null and player.global_position.x > 920.0:
		player.global_position.x = 920.0
	if player != null and player.global_position.x < 12.0:
		player.global_position.x = 12.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not started and event.keycode in [KEY_ENTER, KEY_SPACE]:
			_start_game()
		elif started and event.keycode == KEY_R:
			_restart_level()
		elif started and event.keycode == KEY_ESCAPE:
			paused = not paused
			get_tree().paused = paused
			queue_redraw()
	if event is InputEventScreenTouch:
		_handle_touch(event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_touch(event.position, true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position, event.pressed)

func _handle_touch(point: Vector2, pressed: bool) -> void:
	if not started:
		if pressed:
			_start_game()
		return
	if paused:
		if pressed:
			paused = false
			get_tree().paused = false
			queue_redraw()
		return
	touch_left = pressed and point.x < 145.0 and point.y > 390.0
	touch_right = pressed and point.x >= 145.0 and point.x < 270.0 and point.y > 390.0
	if pressed and point.x > 760.0 and point.y > 390.0:
		jump_just_pressed = true

func _start_game() -> void:
	started = true
	_build_level()
	queue_redraw()

func _build_level() -> void:
	_clear_level()
	paused = false
	get_tree().paused = false
	var definition: Dictionary = LEVELS[level_index]
	for platform_rect: Rect2 in definition["platforms"]:
		platforms.append(_make_platform(platform_rect))
	player = PLAYER_SCENE_SCRIPT.new() as DevilPlayer
	player.name = "Player"
	player.z_index = 2
	player.position = Vector2(72, 430)
	player.controls = self
	player.died.connect(_on_player_died)
	add_child(player)
	for trap_data: Dictionary in definition["traps"]:
		var trap_rect: Rect2 = trap_data["rect"]
		var trap := TRAP_SCRIPT.new() as DevilTrap
		trap.configure(str(trap_data["type"]), trap_rect.size, trap_rect.position + trap_rect.size * 0.5)
		trap.activated.connect(_on_trap_activated)
		add_child(trap)
		traps.append(trap)
	_build_exit()
	toast = "LEVEL %02d  /  %s" % [level_index + 1, definition["name"]]
	toast_time = 2.0
	queue_redraw()

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
	revealed_spikes.clear()
	door_open = false

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
	top_line.points = PackedVector2Array([Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5), Vector2(rect.size.x * 0.5, -rect.size.y * 0.5)])
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
			toast = "YOU WERE WARNED. (YOU WEREN'T.)"
			toast_time = 1.2
			player.die()
		"collapse":
			trap.disarm()
			var target := _nearest_platform(trap.position)
			if target != null:
				var tween := create_tween()
				tween.tween_property(target, "position:y", target.position.y + 90.0, 0.22)
				tween.tween_callback(target.queue_free)
			toast = "THE FLOOR HAS LEFT THE CHAT."
			toast_time = 1.2
		"falling":
			trap.disarm()
			var block := _make_platform(Rect2(trap.position.x - 35, -110, 70, 70))
			var tween := create_tween()
			tween.tween_property(block, "position:y", 445.0, 0.48)
			tween.tween_callback(func() -> void:
				if player != null and player.alive and absf(player.global_position.x - block.position.x) < 52.0:
					player.die()
			)
			toast = "LOOK UP!"
			toast_time = 1.0
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
	toast = "TRY AGAIN. THE DEVIL IS PATIENT."
	toast_time = 1.0
	_respawn()

func _respawn() -> void:
	await get_tree().create_timer(0.48).timeout
	if player != null and is_instance_valid(player):
		player.revive(Vector2(72, 430))
		for trap in traps:
			if is_instance_valid(trap) and trap.trap_type != "spikes":
				trap.armed = true
				trap.monitoring = true
	queue_redraw()

func _on_exit_entered(body: Node2D) -> void:
	if body != player or door_open:
		return
	door_open = true
	best_unlocked = maxi(best_unlocked, mini(level_index + 1, LEVELS.size() - 1))
	_save_progress()
	if level_index < LEVELS.size() - 1:
		level_index += 1
		toast = "DOOR OPEN. NEXT ROOM..."
		toast_time = 0.8
		await get_tree().create_timer(0.85).timeout
		_build_level()
	else:
		started = false
		_clear_level()
		toast = "YOU ESCAPED. FOR NOW."
		toast_time = 3.0
	queue_redraw()

func _restart_level() -> void:
	_build_level()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_unlocked = clampi(int(config.get_value("progress", "unlocked", 0)), 0, LEVELS.size() - 1)

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked", best_unlocked)
	config.save(SAVE_PATH)

func _draw() -> void:
	_draw_backdrop()
	if not started:
		_draw_title_screen()
		return
	_draw_level_art()
	_draw_hud()
	_draw_touch_controls()
	if paused:
		draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0, 0, 0, 0.72))
		draw_string(ThemeDB.fallback_font, Vector2(0, 250), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 960, 38, Color("#f4f1e9"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 290), "TAP TO RESUME  /  ESC", HORIZONTAL_ALIGNMENT_CENTER, 960, 15, Color("#aaaeb7"))

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#11141a"))
	for i in range(24):
		var x := float((i * 173) % 960)
		var y := float((i * 97) % 400)
		draw_circle(Vector2(x, y), 1.2, Color(0.75, 0.78, 0.84, 0.18))
	draw_rect(Rect2(0, 0, 960, 6), Color("#e5a13a"))

func _draw_title_screen() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 170), "LEVEL", HORIZONTAL_ALIGNMENT_CENTER, 960, 34, Color("#e7e4dc"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 245), "DEVIL", HORIZONTAL_ALIGNMENT_CENTER, 960, 72, Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 292), "A VERY NORMAL PLATFORMER", HORIZONTAL_ALIGNMENT_CENTER, 960, 15, Color("#a7abb4"))
	draw_rect(Rect2(350, 345, 260, 58), Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(350, 382), "TAP TO PLAY", HORIZONTAL_ALIGNMENT_CENTER, 260, 20, Color("#17191f"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 470), "MOVE  A / D     JUMP  SPACE     RETRY  R", HORIZONTAL_ALIGNMENT_CENTER, 960, 14, Color("#858b96"))

func _draw_level_art() -> void:
	# Exit door and its deliberately reassuring glow.
	draw_rect(Rect2(866, 344, 48, 86), Color("#d7d2c6"))
	draw_rect(Rect2(872, 350, 36, 80), Color("#242832"))
	draw_circle(Vector2(899, 391), 3, Color("#e5a13a"))
	for spike_rect in revealed_spikes:
		for i in range(4):
			var sx := spike_rect.position.x + float(i) * 16.0
			draw_colored_polygon(PackedVector2Array([Vector2(sx, spike_rect.end.y), Vector2(sx + 8, spike_rect.position.y), Vector2(sx + 16, spike_rect.end.y)]), Color("#e65b52"))
	draw_rect(Rect2(0, 430, 960, 110), Color(0.03, 0.035, 0.045, 0.65))

func _draw_hud() -> void:
	var definition: Dictionary = LEVELS[level_index]
	draw_string(ThemeDB.fallback_font, Vector2(28, 42), "LEVEL  %02d" % (level_index + 1), HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#e5a13a"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 66), str(definition["name"]), HORIZONTAL_ALIGNMENT_LEFT, 400, 13, Color("#e7e4dc"))
	draw_string(ThemeDB.fallback_font, Vector2(930, 42), "DEATHS  %02d" % deaths, HORIZONTAL_ALIGNMENT_RIGHT, 180, 15, Color("#a7abb4"))
	draw_string(ThemeDB.fallback_font, Vector2(480, 42), str(definition["hint"]), HORIZONTAL_ALIGNMENT_CENTER, 500, 13, Color("#8c929e"))
	if toast_time > 0.0 and toast != "":
		draw_string(ThemeDB.fallback_font, Vector2(0, 115), toast, HORIZONTAL_ALIGNMENT_CENTER, 960, 15, Color("#f0c16c"))

func _draw_touch_controls() -> void:
	_draw_control(Vector2(72, 478), "‹", touch_left)
	_draw_control(Vector2(172, 478), "›", touch_right)
	_draw_control(Vector2(870, 478), "↑", false)

func _draw_control(center: Vector2, label: String, active: bool) -> void:
	draw_circle(center, 36, Color(0.07, 0.08, 0.10, 0.76))
	draw_arc(center, 34, 0.0, TAU, 48, Color("#e5a13a") if active else Color(0.72, 0.74, 0.78, 0.55), 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-13, 10), label, HORIZONTAL_ALIGNMENT_CENTER, 26, 28, Color("#f2f0e8"))
