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

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 42.0
	shape.shape = capsule
	shape.position = Vector2(0, -21)
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return

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

	if direction != 0.0:
		facing = int(sign(direction))
		velocity.x = direction * RUN_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * 8.0 * delta)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += GRAVITY * delta

	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		jump_buffer = JUMP_BUFFER
	elif controls != null and controls.jump_just_pressed:
		jump_buffer = JUMP_BUFFER
		controls.jump_just_pressed = false
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)

	if jump_buffer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote_timer = 0.0

	move_and_slide()
	if global_position.y > 700.0:
		die()

func die() -> void:
	if not alive:
		return
	alive = false
	died.emit()

func revive(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	alive = true
	queue_redraw()

func _draw() -> void:
	# Original, deliberately simple hero silhouette.
	draw_rect(Rect2(-11, -38, 22, 30), Color("#f2f0e8"))
	draw_rect(Rect2(-10, -8, 9, 8), Color("#e3a33a"))
	draw_rect(Rect2(2, -8, 9, 8), Color("#e3a33a"))
	draw_rect(Rect2(facing * 2, -29, 4, 4), Color("#17191f"))
	draw_rect(Rect2(-12, -40, 24, 3), Color("#ffffff"))
