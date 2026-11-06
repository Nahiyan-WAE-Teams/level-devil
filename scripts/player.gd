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
var sprite: AnimatedSprite2D

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
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(0, -25.6)
	sprite.scale = Vector2(0.8, 0.8)
	sprite.sprite_frames = _create_sprite_frames()
	sprite.play("idle")
	add_child(sprite)

func _process(delta: float) -> void:
	if not alive:
		death_time += delta
		var fade := clampf(death_time / 0.48, 0.0, 1.0)
		rotation = lerpf(0.0, TAU * 0.72, fade)
		var fade_tint := sprite.modulate
		fade_tint.a = 1.0 - fade
		sprite.modulate = fade_tint
		return
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink_closed = not blink_closed
		blink_timer = 0.10 if blink_closed else randf_range(2.0, 4.5)
	if absf(velocity.x) > 12.0 and is_on_floor():
		run_phase += delta * 13.0
		body_bob = sin(run_phase * 2.0) * 1.8
	else:
		body_bob = move_toward(body_bob, 0.0, delta * 12.0)
	var next_animation := "idle"
	if not is_on_floor():
		next_animation = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 12.0:
		next_animation = "run"
	if sprite.animation != next_animation:
		sprite.play(next_animation)
	sprite.flip_h = facing < 0
	if reverse_time > 0.0:
		sprite.modulate = Color("#e5a13a")
	elif gravity_flip_time > 0.0:
		sprite.modulate = Color("#8cc7dc")
	else:
		sprite.modulate = Color.WHITE

func _create_sprite_frames() -> SpriteFrames:
	var texture := load("res://assets/player_sheet.svg") as Texture2D
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_animation(frames, texture, "idle", 0, 4, 5.0, true)
	_add_animation(frames, texture, "run", 1, 6, 12.0, true)
	_add_animation(frames, texture, "jump", 2, 4, 10.0, false)
	_add_animation(frames, texture, "fall", 2, 2, 5.0, true, 2)
	_add_animation(frames, texture, "death", 3, 6, 12.5, false)
	return frames

func _add_animation(frames: SpriteFrames, texture: Texture2D, animation_name: String, row: int, count: int, speed: float, looping: bool, start_frame: int = 0) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, looping)
	for frame_index in range(start_frame, start_frame + count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * 64, row * 64, 64, 64)
		frames.add_frame(animation_name, atlas)

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
	sprite.modulate = Color.WHITE
	sprite.play("death")
	died.emit()

func revive(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	alive = true
	death_time = 0.0
	rotation = 0.0
	sprite.modulate = Color.WHITE
	sprite.play("idle")
	reverse_time = 0.0
	gravity_flip_time = 0.0
	gravity_direction = 1.0
	squash = Vector2(0.7, 1.3)
	queue_redraw()

