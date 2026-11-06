extends Area2D
class_name DevilTrap

signal activated(trap: DevilTrap)

var trap_type := "spikes"
var armed := true
var linked_platform: StaticBody2D
var base_position := Vector2.ZERO
var motion_distance := 0.0
var motion_speed := 1.0
var elapsed := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	queue_redraw()

func configure(kind: String, size: Vector2, position_in_level: Vector2, travel_distance: float = 0.0, travel_speed: float = 1.0) -> void:
	trap_type = kind
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
	if trap_type == "saw" and armed:
		elapsed += delta
		position.x = base_position.x + sin(elapsed * motion_speed) * motion_distance

func _on_body_entered(body: Node2D) -> void:
	if not armed or not body is DevilPlayer:
		return
	activated.emit(self)

func disarm() -> void:
	armed = false
	monitoring = false
	queue_redraw()

func _draw() -> void:
	if trap_type == "saw":
		draw_circle(Vector2.ZERO, 19.0, Color("#d95d55"))
		for index in range(8):
			var angle := TAU * float(index) / 8.0
			var inner := Vector2(cos(angle), sin(angle)) * 14.0
			var outer := Vector2(cos(angle), sin(angle)) * 25.0
			draw_line(inner, outer, Color("#f2e7dc"), 4.0)
		draw_circle(Vector2.ZERO, 5.0, Color("#272a31"))
