# Systems/Player/cursor_pickup_area.gd
extends Area2D

## Invisible area that follows cursor to collect pickups

@export var pickup_radius: float = 20.0


func _ready() -> void:
	add_to_group("player")
	
	collision_layer = 2  # Player layer
	collision_mask = 0   # We don't need to detect, pickups detect us
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = pickup_radius
	collision_shape.shape = shape
	add_child(collision_shape)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()