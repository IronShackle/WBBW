# Systems/Combat/Hitboxes/hitbox_instance.gd
class_name HitboxInstance
extends Area2D

signal activated()
signal deactivated()

var shape: Shape2D
var knockback_force: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var use_radial_knockback: bool = false
var damage: float = 0.0
var duration: float = 0.1
var hitbox_owner: Node2D = null


func _ready() -> void:
	add_to_group("hitbox")
	
	# Set collision layers
	collision_layer = 4  # Hitboxes on layer 3 (bit 2)
	collision_mask = 0   # Don't need to detect anything - balls will detect us
	
	# Create collision shape
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	
	# Emit activated signal
	activated.emit()
	
	# Auto-cleanup after duration
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		deactivated.emit()
		queue_free()