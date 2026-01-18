# Systems/Barriers/barrier_manager.gd
class_name BarrierManager
extends Node

## Manages barrier layers and progression

signal barrier_broken(tier: int, prestige_awarded: int)
signal barrier_damage_changed(current: int, required: int)

# Barrier configuration
@export var starting_barriers: int = 10
@export var barrier_thickness: float = 100.0
@export var barrier_spacing: float = 0.0  # No spacing between layers
@export var initial_play_area_size: Vector2 = Vector2(800, 600)

# Prestige rewards per tier (can be tuned in inspector)
@export var prestige_rewards: Array[int] = [10, 15, 20, 30, 50, 75, 100, 150, 200, 300]

# Bounce requirements per tier (can be tuned in inspector)
@export var bounce_requirements: Array[int] = [100, 200, 350, 500, 750, 1000, 1500, 2000, 3000, 5000]

var barriers: Array[Node2D] = []
var current_barrier_tier: int = 0  # 0 = innermost
var barrier_bounces: int = 0


func _ready() -> void:
	add_to_group("barrier_manager")
	
	# Connect to GameManager
	GameManager.bounce_currency_changed.connect(_on_bounce_registered)
	
	# Create barriers
	_create_barriers()
	
	# Load saved state if available
	_load_barrier_state()


func _create_barriers() -> void:
	# Use hardcoded scene center
	var center = Vector2.ZERO  # Or whatever your scene center is
	
	for i in range(starting_barriers):
		var barrier = _create_barrier_layer(i, center)
		barriers.append(barrier)
		add_child(barrier)


func _create_barrier_layer(tier: int, center: Vector2) -> Node2D:
	var layer = Node2D.new()
	layer.name = "BarrierLayer_%d" % tier
	
	# Calculate size for this tier
	var expansion = tier * (barrier_thickness + barrier_spacing)
	var size = initial_play_area_size + Vector2(expansion * 2, expansion * 2)
	
	# Create 4 walls forming a rectangle
	var half_size = size / 2
	
	# Top wall
	var top_wall = _create_wall(
		Vector2(center.x, center.y - half_size.y),
		Vector2(size.x, barrier_thickness)
	)
	top_wall.name = "TopWall"
	layer.add_child(top_wall)
	
	# Bottom wall
	var bottom_wall = _create_wall(
		Vector2(center.x, center.y + half_size.y),
		Vector2(size.x, barrier_thickness)
	)
	bottom_wall.name = "BottomWall"
	layer.add_child(bottom_wall)
	
	# Left wall
	var left_wall = _create_wall(
		Vector2(center.x - half_size.x, center.y),
		Vector2(barrier_thickness, size.y + barrier_thickness * 2)  # Extend to cover corners
	)
	left_wall.name = "LeftWall"
	layer.add_child(left_wall)
	
	# Right wall
	var right_wall = _create_wall(
		Vector2(center.x + half_size.x, center.y),
		Vector2(barrier_thickness, size.y + barrier_thickness * 2)  # Extend to cover corners
	)
	right_wall.name = "RightWall"
	layer.add_child(right_wall)
	
	return layer

func _create_wall(pos: Vector2, size: Vector2) -> StaticBody2D:
	var wall = StaticBody2D.new()
	wall.position = pos
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	
	# Visual (black rectangle)
	var visual = ColorRect.new()
	visual.color = Color.BLACK
	visual.size = size
	visual.position = -size / 2  # Center it
	wall.add_child(visual)
	
	# Add to wall group
	wall.add_to_group("wall")
	
	return wall


func _on_bounce_registered(new_bounce_currency: int) -> void:
	# Increment barrier damage
	barrier_bounces += 1
	
	# Get current requirement
	var required = get_current_barrier_requirement()
	
	barrier_damage_changed.emit(barrier_bounces, required)
	
	# Check if barrier should break
	if barrier_bounces >= required:
		_break_current_barrier()


func _break_current_barrier() -> void:
	if current_barrier_tier >= barriers.size():
		print("[BarrierManager] All barriers broken!")
		return
	
	# Get prestige reward
	var prestige = get_barrier_prestige_reward(current_barrier_tier)
	
	# Award prestige points
	GameManager.add_prestige_points(prestige)
	
	print("[BarrierManager] Barrier %d broken! Awarded %d prestige points" % 
		[current_barrier_tier, prestige])
	
	# Remove the barrier
	var barrier = barriers[current_barrier_tier]
	barrier.queue_free()
	
	# Move to next tier
	current_barrier_tier += 1
	barrier_bounces = 0
	
	# Emit signal
	barrier_broken.emit(current_barrier_tier - 1, prestige)
	
	# Update UI
	if current_barrier_tier < barriers.size():
		var next_required = get_current_barrier_requirement()
		barrier_damage_changed.emit(0, next_required)
	
	# Save state
	_save_barrier_state()


func get_current_barrier_requirement() -> int:
	if current_barrier_tier >= bounce_requirements.size():
		return 999999  # Fallback for tiers beyond config
	return bounce_requirements[current_barrier_tier]


func get_barrier_prestige_reward(tier: int) -> int:
	if tier >= prestige_rewards.size():
		return 100  # Fallback
	return prestige_rewards[tier]


func _save_barrier_state() -> void:
	# Called by GameManager during save
	pass


func _load_barrier_state() -> void:
	# Called on ready to restore state
	pass


func reset_barriers() -> void:
	# Called on prestige
	for barrier in barriers:
		if is_instance_valid(barrier):
			barrier.queue_free()
	
	barriers.clear()
	current_barrier_tier = 0
	barrier_bounces = 0
	
	_create_barriers()
