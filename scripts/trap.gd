extends Area2D
class_name DevilTrap

signal activated(trap: DevilTrap)

var trap_type := "spikes"
var armed := true
var base_position := Vector2.ZERO
var motion_distance := 0.0
var motion_speed := 1.0
var elapsed := 0.0
var pulse := 0.0
var configured_size := Vector2(48, 48)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func configure(kind: String, size: Vector2, position_in_level: Vector2, travel_distance: float = 0.0, travel_speed: float = 1.0) -> void:
	trap_type = kind
	configured_size = size
	position = position_in_level
	base_position = position_in_level
	motion_distance = travel_distance
	motion_speed = travel_speed
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	add_child(shape)

func _process(delta: float) -> void:
	elapsed += delta
	pulse = (sin(elapsed * 4.0) + 1.0) * 0.5
	if trap_type == "saw" and armed:
		position.x = base_position.x + sin(elapsed * motion_speed) * motion_distance
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not armed or not body is DevilPlayer:
		return
	activated.emit(self)

func disarm() -> void:
	armed = false
	monitoring = false
	queue_redraw()

func _draw() -> void:
	var half := configured_size * 0.5
	match trap_type:
		"saw":
			draw_circle(Vector2.ZERO, 22.0 + pulse * 1.5, Color("#171a20"))
			for index in range(10):
				var angle := TAU * float(index) / 10.0 + elapsed * 2.0
				var inner := Vector2(cos(angle), sin(angle)) * 13.0
				var outer := Vector2(cos(angle), sin(angle)) * 27.0
				draw_colored_polygon(PackedVector2Array([inner.rotated(-0.10), outer, inner.rotated(0.10)]), Color("#d95d55"))
			draw_circle(Vector2.ZERO, 7.0, Color("#b8bdc6"))
			draw_circle(Vector2.ZERO, 3.0, Color("#333842"))
		"reverse":
			draw_rect(Rect2(-half.x, -half.y, configured_size.x, configured_size.y), Color(0.78, 0.36, 0.25, 0.10 + pulse * 0.06))
			draw_rect(Rect2(-half.x, -half.y, configured_size.x, configured_size.y), Color("#d95d55"), false, 2.0)
			for x in [-half.x + 15.0, 0.0, half.x - 15.0]:
				draw_line(Vector2(x - 5, 0), Vector2(x + 5, 0), Color("#f2d8cf"), 2.0)
				draw_line(Vector2(x + 5, 0), Vector2(x + 1, -4), Color("#f2d8cf"), 2.0)
		"gravity":
			draw_circle(Vector2.ZERO, minf(half.x, half.y) * (0.48 + pulse * 0.04), Color(0.30, 0.64, 0.78, 0.12))
			draw_arc(Vector2.ZERO, minf(half.x, half.y) * 0.45, elapsed, elapsed + PI * 1.55, 40, Color("#8cc7dc"), 2.5)
			draw_line(Vector2(-9, 0), Vector2(9, 0), Color("#d9f0f7"), 2.0)
		"fake_exit":
			draw_rect(Rect2(-half.x, -half.y, configured_size.x, configured_size.y), Color("#d9d4c9"))
			draw_rect(Rect2(-half.x + 6, -half.y + 6, configured_size.x - 12, configured_size.y - 6), Color("#272b33"))
			draw_circle(Vector2(half.x - 12, 4), 2.5, Color("#e5a13a"))
		"collapse":
			draw_rect(Rect2(-half.x, -half.y, configured_size.x, configured_size.y), Color(0.78, 0.48, 0.24, 0.08 + pulse * 0.05))
			draw_line(Vector2(-half.x + 4, -half.y), Vector2(-half.x + 13, half.y), Color("#d99a4b"), 2.0)
			draw_line(Vector2(half.x - 9, -half.y), Vector2(half.x - 2, half.y), Color("#d99a4b"), 2.0)
		"falling":
			draw_rect(Rect2(-half.x, -half.y, configured_size.x, configured_size.y), Color("#d95d55"), false, 2.0)
			draw_line(Vector2(-half.x, -half.y), Vector2(half.x, half.y), Color("#d95d55"), 2.0)
			draw_line(Vector2(half.x, -half.y), Vector2(-half.x, half.y), Color("#d95d55"), 2.0)
