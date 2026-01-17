# Systems/Combat/Hitboxes/shape_preset.gd
class_name ShapePreset
extends RefCounted

## Shape types for hitbox collision generation

enum ShapeType { CIRCLE, ARC, TRIANGLE }


## Generate collision shape and add to parent node
static func apply_shape(
	parent: Node2D,
	shape_type: ShapeType,
	radius: float,
	angle: float,
	size: Vector2,
	offset: Vector2 = Vector2.ZERO
) -> void:
	match shape_type:
		ShapeType.CIRCLE:
			_apply_circle(parent, radius, offset)
		ShapeType.ARC:
			_apply_arc(parent, radius, angle, offset)
		ShapeType.TRIANGLE:
			_apply_triangle(parent, size, offset)


static func _apply_circle(parent: Node2D, radius: float, offset: Vector2) -> void:
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	collision.position = offset
	parent.add_child(collision)


static func _apply_arc(parent: Node2D, radius: float, angle: float, offset: Vector2) -> void:
	var collision = CollisionPolygon2D.new()
	var points = PackedVector2Array()
	
	# Center point
	points.append(offset)
	
	# Arc edge points
	var half_angle = deg_to_rad(angle / 2.0)
	var segments = maxi(3, ceili(angle / 10.0))
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var current_angle = -half_angle + (t * deg_to_rad(angle))
		var point = offset + Vector2(cos(current_angle), sin(current_angle)) * radius
		points.append(point)
	
	collision.polygon = points
	parent.add_child(collision)


static func _apply_triangle(parent: Node2D, size: Vector2, offset: Vector2) -> void:
	var collision = CollisionPolygon2D.new()
	var points = PackedVector2Array()
	
	# Triangle: base at origin, tip pointing forward (+X)
	# size.x = length (how far forward), size.y = width (base)
	points.append(offset + Vector2(0, -size.y / 2.0))  # Base bottom
	points.append(offset + Vector2(size.x, 0))          # Tip
	points.append(offset + Vector2(0, size.y / 2.0))   # Base top
	
	collision.polygon = points
	parent.add_child(collision)