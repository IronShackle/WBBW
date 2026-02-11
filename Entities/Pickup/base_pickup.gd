# Entities/Pickup/base_pickup.gd
class_name BasePickup
extends Area2D

## Base pickup that player can collect

signal pickup_collected(pickup: BasePickup)

@export var visual_color: Color = Color.YELLOW

var pickup_lifetime: float = 30.0  # Set by spawn manager
var time_alive: float = 0.0


func _ready() -> void:
	add_to_group("pickup")
	collision_layer = 0
	collision_mask = 2  # Detect player (layer 2)
	
	z_index = -1
	
	area_entered.connect(_on_area_entered)  
	_setup_visuals()


func _on_area_entered(area: Area2D) -> void: 
	if area.is_in_group("player"):
		_collect(area)


func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= pickup_lifetime:
		_despawn()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)


func _collect(collector: Node2D) -> void:
	pickup_collected.emit(self)
	_apply_effect(collector)
	queue_free()


## Override in derived classes to implement pickup effect
func _apply_effect(collector: Node2D) -> void:
	pass


func _despawn() -> void:
	print("[BasePickup] Despawned after %.1fs" % pickup_lifetime)
	queue_free()


func _setup_visuals() -> void:
	# Simple circle visual
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), 
		Vector2(8, 8), Vector2(-8, 8)
	])
	visual.color = visual_color
	add_child(visual)