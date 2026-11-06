extends CharacterBody2D
class_name DevilPlayer

signal died

const RUN_SPEED := 285.0
const JUMP_VELOCITY := -545.0
const GRAVITY := 1500.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

var controls: Node
var jump_buffer := 0.0
var coyote_timer := 0.0
var facing := 1
var alive := true
var reverse_time := 0.0
var gravity_flip_time := 0.0
var gravity_direction := 1.0
var run_phase := 0.0
var body_bob := 0.0
var squash := Vector2.ONE
var blink_timer := 2.5
var blink_closed := false
var death_time := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 42.0
	shape.shape = capsule
	shape.position = Vector2(0, -21)
	add_child(shape)

func _process(delta: float) -> void:
	if not alive:
		death_time += delta
		var fade := clampf(death_time / 0.48, 0.0, 1.0)
		rotation = lerpf(0.0, TAU * 0.72, fade)
		modulate.a = 1.0 - fade
		queue_redraw()
		return
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink_closed = not blink_closed
		blink_timer = 0.10 if blink_closed else randf_range(2.0, 4.5)
	if alive and absf(velocity.x) > 12.0 and is_on_floor():
		run_phase += delta * 13.0
		body_bob = sin(run_phase * 2.0) * 1.8
	else:
		body_bob = move_toward(body_bob, 0.0, delta * 12.0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	reverse_time = maxf(0.0, reverse_time - delta)
	gravity_flip_time = maxf(0.0, gravity_flip_time - delta)
	gravity_direction = -1.0 if gravity_flip_time > 0.0 else 1.0
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	if controls != null:
		if controls.touch_left:
			direction -= 1.0
		if controls.touch_right:
			direction += 1.0
	if reverse_time > 0.0:
		direction *= -1.0
	if direction != 0.0:
		facing = int(sign(direction))
		velocity.x = direction * RUN_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * 8.0 * delta)
	if gravity_direction > 0.0 and is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += GRAVITY * gravity_direction * delta
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		jump_buffer = JUMP_BUFFER
	elif controls != null and controls.jump_just_pressed:
		jump_buffer = JUMP_BUFFER
		controls.jump_just_pressed = false
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if jump_buffer > 0.0 and coyote_timer > 0.0 and gravity_direction > 0.0:
		velocity.y = JUMP_VELOCITY
		if controls != null and controls.has_method("play_game_sfx"):
			controls.call("play_game_sfx", "jump")
		jump_buffer = 0.0
		coyote_timer = 0.0
		squash = Vector2(0.78, 1.25)
	move_and_slide()
	if is_on_floor() and absf(velocity.y) < 20.0:
		squash = squash.lerp(Vector2.ONE, delta * 12.0)
	else:
		squash = squash.lerp(Vector2(1.08, 0.92), delta * 5.0)
	if global_position.y > 700.0 or global_position.y < -180.0:
		die()

func apply_trap_effect(effect: String, duration: float) -> void:
	match effect:
		"reverse":
			reverse_time = maxf(reverse_time, duration)
		"gravity":
			gravity_flip_time = maxf(gravity_flip_time, duration)

func die() -> void:
	if not alive:
		return
	alive = false
	death_time = 0.0
	rotation = 0.0
	modulate = Color.WHITE
	died.emit()

func revive(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	alive = true
	death_time = 0.0
	rotation = 0.0
	modulate = Color.WHITE
	reverse_time = 0.0
	gravity_flip_time = 0.0
	gravity_direction = 1.0
	squash = Vector2(0.7, 1.3)
	queue_redraw()

func _draw() -> void:
	var body_color := Color("#eee9df")
	if reverse_time > 0.0:
		body_color = Color("#e5a13a")
	elif gravity_flip_time > 0.0:
		body_color = Color("#8cc7dc")
	draw_set_transform(Vector2(0, body_bob), 0.0, Vector2(squash.x, squash.y))
	var moving := absf(velocity.x) > 12.0 and is_on_floor()
	var stride := sin(run_phase) * 5.0 if moving else 0.0
	var arm_swing := sin(run_phase + PI) * 4.0 if moving else 0.0
	var airborne := not is_on_floor()
	var arm_raise := -7.0 if airborne and velocity.y < 0.0 else (3.0 if airborne else 0.0)
	draw_circle(Vector2(0, 1), 11.0, Color(0, 0, 0, 0.18))
	draw_line(Vector2(-7, -25), Vector2(-12 - arm_swing, -15 + arm_raise), Color("#d8b99b"), 5.0)
	draw_line(Vector2(7, -25), Vector2(12 + arm_swing, -15 + arm_raise), Color("#d8b99b"), 5.0)
	draw_rect(Rect2(-9 - stride * 0.35, -13, 7, 12), Color("#c58b42"))
	draw_rect(Rect2(2 + stride * 0.35, -13, 7, 12), Color("#c58b42"))
	draw_rect(Rect2(-12 - stride, -4, 11, 5), Color("#222630"))
	draw_rect(Rect2(2 + stride, -4, 11, 5), Color("#222630"))
	draw_rect(Rect2(-12, -35, 24, 24), body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -29), Vector2(12, -31), Vector2(9, -10), Vector2(-9, -10)]), body_color)
	draw_rect(Rect2(-12, -38, 24, 4), Color("#343943"))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -35), Vector2(8, -35), Vector2(13, -30), Vector2(-7, -29)]), Color("#d95d55"))
	draw_line(Vector2(8, -31), Vector2(17, -26 + sin(run_phase * 0.7) * 2.0), Color("#d95d55"), 3.0)
	draw_circle(Vector2(0, -43), 10.5, Color("#e8c5a3"))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -45), Vector2(-8, -54), Vector2(2, -56), Vector2(10, -50), Vector2(9, -43), Vector2(4, -48), Vector2(-3, -47)]), Color("#292832"))
	draw_circle(Vector2(-6, -37), 2.2, Color("#e8c5a3"))
	if not blink_closed:
		draw_circle(Vector2(facing * 4.0, -43), 1.5, Color("#17191f"))
	else:
		draw_line(Vector2(2, -43), Vector2(6, -43), Color("#17191f"), 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
