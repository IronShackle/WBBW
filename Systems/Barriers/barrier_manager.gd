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

# Shader for damage visualization
var damage_shader: Shader

# Prestige rewards per tier (can be tuned in inspector)
@export var prestige_rewards: Array[int] = [10, 15, 20, 30, 50, 75, 100, 150, 200, 300]

# Bounce requirements per tier (can be tuned in inspector)
@export var bounce_requirements: Array[int] = [
	100, 
	200, 
	350, 
	500, 
	750, 
	1000, 
	1500, 
	2000, 
	3000, 
	5000
]

# Zoom settings per barrier tier
@export var barrier_zoom_levels: Array[float] = [
	1.0,   # Tier 0 - closest
	0.95,  # Tier 1
	0.9,   # Tier 2
	0.85,  # Tier 3
	0.8,   # Tier 4
	0.75,  # Tier 5
	0.7,   # Tier 6
	0.65,  # Tier 7
	0.6,   # Tier 8
	0.55   # Tier 9 - most zoomed out
]

# Essence drops per barrier
@export var essence_pickups_per_barrier: int = 5

# Essence pickup scene
@export var essence_pickup_scene: PackedScene

var barriers: Array[Node2D] = []
var current_barrier_tier: int = 0  # 0 = innermost
var barrier_bounces: int = 0


func _ready() -> void:
	add_to_group("barrier_manager")
	
	# Load damage shader
	damage_shader = load("res://Shaders/barrier_damage.gdshader")
	
	# Connect to GameManager
	GameManager.bounce_currency_changed.connect(_on_bounce_registered)
	
	# Create barriers
	_create_barriers()
	
	# Load saved state if available
	_load_barrier_state()
	
	# Set initial camera zoom for current tier
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and current_barrier_tier < barrier_zoom_levels.size():
		camera.set_initial_zoom(barrier_zoom_levels[current_barrier_tier])


func _create_barriers() -> void:
	# Use hardcoded scene center
	var center = Vector2.ZERO
	
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
		Vector2(barrier_thickness, size.y + barrier_thickness * 2)
	)
	left_wall.name = "LeftWall"
	layer.add_child(left_wall)
	
	# Right wall
	var right_wall = _create_wall(
		Vector2(center.x + half_size.x, center.y),
		Vector2(barrier_thickness, size.y + barrier_thickness * 2)
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
	
	# Visual (black polygon with shader)
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x/2, -size.y/2),  # Top-left
		Vector2(size.x/2, -size.y/2),   # Top-right
		Vector2(size.x/2, size.y/2),    # Bottom-right
		Vector2(-size.x/2, size.y/2)    # Bottom-left
	])
	visual.color = Color.BLACK
	
	# Apply damage shader
	if damage_shader:
		var material = ShaderMaterial.new()
		material.shader = damage_shader
		material.set_shader_parameter("damage_percent", 0.0)
		material.set_shader_parameter("wall_color", Color.BLACK)
		visual.material = material
	
	wall.add_child(visual)
	
	# Add to wall group
	wall.add_to_group("wall")
	
	return wall


func _on_bounce_registered(new_bounce_currency: int) -> void:
	# Increment barrier damage
	barrier_bounces += 1
	
	# Get current requirement
	var required = get_current_barrier_requirement()
	
	# Calculate damage percentage
	var damage_percent = float(barrier_bounces) / float(required)
	
	# Update shader on current barrier walls
	_update_barrier_damage_visual(damage_percent)
	
	barrier_damage_changed.emit(barrier_bounces, required)
	
	# Check if barrier should break
	if barrier_bounces >= required:
		_break_current_barrier()


func _update_barrier_damage_visual(damage_percent: float) -> void:
	if current_barrier_tier >= barriers.size():
		return
	
	print("[BarrierManager] Updating damage visual: %.2f" % damage_percent)
	
	var barrier = barriers[current_barrier_tier]
	if not is_instance_valid(barrier):
		return
	
	var walls = [
		barrier.get_node_or_null("TopWall"),
		barrier.get_node_or_null("BottomWall"),
		barrier.get_node_or_null("LeftWall"),
		barrier.get_node_or_null("RightWall")
	]
	
	for wall in walls:
		if wall:
			var visual = null
			for child in wall.get_children():
				if child is Polygon2D:
					visual = child
					break
			
			if visual and visual.material:
				visual.material.set_shader_parameter("damage_percent", damage_percent)
	
	# Trigger camera shake at damage thresholds
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		if damage_percent >= 0.95 and damage_percent < 0.96:  # Just crossed 90%
			camera.shake_screen(6.0)  # Heavy shake
		elif damage_percent >= 0.9 and damage_percent < 0.91:  # Just crossed 80%
			camera.shake_screen(4.0)  # Medium shake
		elif damage_percent >= 0.75 and damage_percent < 0.76:  # Just crossed 70%
			camera.shake_screen(2.0)   # Light shake


func _break_current_barrier() -> void:
	if current_barrier_tier >= barriers.size():
		print("[BarrierManager] All barriers broken!")
		return
	
	# Get barrier reference and validate
	var barrier = barriers[current_barrier_tier]
	if not is_instance_valid(barrier):
		print("[BarrierManager] Barrier already processed")
		return
	
	# GUARD: Prevent double-breaking by immediately incrementing tier
	var breaking_tier = current_barrier_tier
	current_barrier_tier += 1
	barrier_bounces = 0
	
	# Get prestige reward
	var prestige = get_barrier_prestige_reward(breaking_tier)
	
	# Award prestige points
	GameManager.add_prestige_points(prestige)
	
	print("[BarrierManager] Barrier %d broken! Awarded %d prestige points and %d essence pickups" % 
		[breaking_tier, prestige, essence_pickups_per_barrier])
	
	# Get wall references
	var walls = [
		barrier.get_node_or_null("TopWall"),
		barrier.get_node_or_null("BottomWall"),
		barrier.get_node_or_null("LeftWall"),
		barrier.get_node_or_null("RightWall")
	]
	
	# Flash effect on all walls - tween the modulate instead of color
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.shake_screen(10.0)
	
# Set zoom for new tier
	if current_barrier_tier < barrier_zoom_levels.size():
		if camera:
			camera.set_target_zoom(barrier_zoom_levels[current_barrier_tier])

	# Wait for flash to start before spawning essence
	await get_tree().create_timer(0.2).timeout
	
	# Spawn essence using wall references
	_spawn_essence_from_walls(walls)
	
	# Wait for fade to finish
	await get_tree().create_timer(0.2).timeout
	
	# Free the barrier container
	if is_instance_valid(barrier):
		barrier.queue_free()
	
	# Emit signal
	barrier_broken.emit(breaking_tier, prestige)
	
	# Update UI
	if current_barrier_tier < barriers.size():
		var next_required = get_current_barrier_requirement()
		barrier_damage_changed.emit(0, next_required)
	
	# Save state
	_save_barrier_state()


func _spawn_essence_from_walls(walls: Array) -> void:
	if not essence_pickup_scene:
		push_warning("[BarrierManager] No essence_pickup_scene assigned!")
		return
	
	var wall_names = ["top", "bottom", "left", "right"]
	
	# Calculate play area for essence (next barrier inward)
	var inner_expansion = current_barrier_tier * (barrier_thickness + barrier_spacing)
	var inner_size = initial_play_area_size + Vector2(inner_expansion * 2, inner_expansion * 2)
	var essence_play_radius = min(inner_size.x, inner_size.y) / 2.0 - 15.0
	
	# Spawn essence: 1 in each wall, then remaining randomly
	for i in range(essence_pickups_per_barrier):
		var wall_index: int
		
		if i < 4:
			wall_index = i
		else:
			wall_index = randi() % walls.size()
		
		var wall = walls[wall_index]
		if not wall:
			continue
		
		var wall_name = wall_names[wall_index]
		
		# Get wall's collision shape
		var collision: CollisionShape2D = null
		for child in wall.get_children():
			if child is CollisionShape2D:
				collision = child
				break
		
		if not collision:
			continue
		
		var shape = collision.shape as RectangleShape2D
		if not shape:
			continue
		
		# Random position within this wall's bounds
		var local_pos = Vector2(
			randf_range(-shape.size.x / 2.0, shape.size.x / 2.0),
			randf_range(-shape.size.y / 2.0, shape.size.y / 2.0)
		)
		
		# Create essence
		var essence = essence_pickup_scene.instantiate()
		essence.global_position = wall.global_position + local_pos
		
		# Set essence properties
		if essence is EssencePickup:
			essence.essence_value = 1
			essence.set_play_area(Vector2.ZERO, essence_play_radius)
		
		get_tree().current_scene.add_child(essence)
		
		print("[BarrierManager] Spawned essence in %s wall at %s" % [wall_name, essence.global_position])


func get_current_barrier_requirement() -> int:
	if current_barrier_tier >= bounce_requirements.size():
		return 999999  # Fallback for tiers beyond config
	return bounce_requirements[current_barrier_tier]


func get_barrier_prestige_reward(tier: int) -> int:
	if tier >= prestige_rewards.size():
		return 100  # Fallback
	return prestige_rewards[tier]


## Get the current play area size (size of innermost unbroken barrier)
func get_current_play_area_size() -> Vector2:
	# Calculate the size based on current barrier tier
	var expansion = current_barrier_tier * (barrier_thickness + barrier_spacing)
	return initial_play_area_size + Vector2(expansion * 2, expansion * 2)


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
