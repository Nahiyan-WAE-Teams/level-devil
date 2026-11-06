extends Area2D
class_name DevilTrap

signal activated(trap: DevilTrap)

var trap_type := "spikes"
var armed := true
var linked_platform: StaticBody2D
var linked_block: StaticBody2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func configure(kind: String, size: Vector2, position_in_level: Vector2) -> void:
	trap_type = kind
	position = position_in_level
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	add_child(shape)

func _on_body_entered(body: Node2D) -> void:
	if not armed or not body is DevilPlayer:
		return
	activated.emit(self)

func disarm() -> void:
	armed = false
	monitoring = false
