# Systems/Combat/hitbox.gd
class_name Hitbox
extends Area2D

## Simple collision detector for attacks

signal hit_detected(target: Node2D)

@export_group("Shape Properties")
@export var base_radius: float = 16.0
@export var base_size: Vector2 = Vector2(32, 32)

var size_multiplier: float = 1.0
var collision_shape: CollisionShape2D


func _ready() -> void:
	collision_shape = $CollisionShape2D
	_update_shape_size()
	
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	
	var target = area.get_parent()
	if target:
		hit_detected.emit(target)


func _get_collision_shape() -> CollisionShape2D:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D")
	return collision_shape


func set_circle_shape(radius: float = -1.0) -> void:
	if radius > 0:
		base_radius = radius
	
	var col_shape = _get_collision_shape()
	if col_shape == null:
		push_error("Hitbox is missing CollisionShape2D child!")
		return
	
	var shape = CircleShape2D.new()
	col_shape.shape = shape
	_update_shape_size()


func set_rectangle_shape(size: Vector2 = Vector2.ZERO) -> void:
	if size != Vector2.ZERO:
		base_size = size
	
	var col_shape = _get_collision_shape()
	if col_shape == null:
		push_error("Hitbox is missing CollisionShape2D child!")
		return
	
	var shape = RectangleShape2D.new()
	col_shape.shape = shape
	_update_shape_size()


func set_capsule_shape(radius: float = -1.0, height: float = -1.0) -> void:
	if radius > 0:
		base_radius = radius
	if height > 0:
		base_size.y = height
	
	var col_shape = _get_collision_shape()
	if col_shape == null:
		push_error("Hitbox is missing CollisionShape2D child!")
		return
	
	var shape = CapsuleShape2D.new()
	col_shape.shape = shape
	_update_shape_size()


func set_size_multiplier(multiplier: float) -> void:
	size_multiplier = multiplier
	_update_shape_size()


func add_size_multiplier(additional: float) -> void:
	size_multiplier += additional
	_update_shape_size()


func _update_shape_size() -> void:
	var col_shape = _get_collision_shape()
	if col_shape == null or col_shape.shape == null:
		return
	
	var shape = col_shape.shape
	
	if shape is CircleShape2D:
		shape.radius = base_radius * size_multiplier
	elif shape is RectangleShape2D:
		shape.size = base_size * size_multiplier
	elif shape is CapsuleShape2D:
		shape.radius = base_radius * size_multiplier
		shape.height = base_size.y * size_multiplier


func get_effective_radius() -> float:
	var col_shape = _get_collision_shape()
	if col_shape == null or col_shape.shape == null:
		return 0.0
	
	if col_shape.shape is CircleShape2D:
		return base_radius * size_multiplier
	return (base_size.x + base_size.y) / 4.0 * size_multiplier


func get_effective_size() -> Vector2:
	return base_size * size_multiplier