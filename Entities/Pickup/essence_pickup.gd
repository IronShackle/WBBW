# Entities/Pickup/essence_pickup.gd
class_name EssencePickup
extends BasePickup

## Pickup that grants essence when collected - gentle meandering motion

var essence_value: int = 1  # Set by spawner

# Meandering motion
var time: float = 0.0
var speed: float = 15.0  # Overall drift speed
var frequency_x: float = 0.3  # How often it changes horizontal direction
var frequency_y: float = 0.5  # How often it changes vertical direction
var amplitude_x: float = 1.0  # Horizontal movement strength
var amplitude_y: float = 1.0  # Vertical movement strength

# Random offsets for variety
var offset_x: float = 0.0
var offset_y: float = 0.0

# Soft bounds
var play_area_center: Vector2 = Vector2.ZERO
var play_area_radius: float = 200.0


func _ready() -> void:
	add_to_group("pickup")
	collision_layer = 0
	collision_mask = 2  # Detect player
	z_index = -1  # Below balls
	
	body_entered.connect(_on_body_entered)
	
	# Customize visual
	visual_color = Color(0.7, 0.5, 1.0)  # Purple for essence
	_setup_visuals()
	
	# Randomize movement parameters for variety
	frequency_x = randf_range(0.2, 0.5)
	frequency_y = randf_range(0.3, 0.6)
	amplitude_x = randf_range(0.8, 1.2)
	amplitude_y = randf_range(0.8, 1.2)
	offset_x = randf_range(0, TAU)
	offset_y = randf_range(0, TAU)
	speed = randf_range(12.0, 18.0)
	
	# Play area will be set by spawner, but use fallback if not
	if play_area_radius == 200.0:  # Default value, not set by spawner
		_setup_play_area()
	
	# NO DESPAWN
	pickup_lifetime = INF


func _setup_visuals() -> void:
	# Small circle for essence
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	# Small diamond shape
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(0, -8),   # Top
		Vector2(8, 0),    # Right
		Vector2(0, 8),    # Bottom
		Vector2(-8, 0)    # Left
	])
	visual.color = visual_color
	add_child(visual)


func _setup_play_area() -> void:
	# Fallback if spawner didn't set play area
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager:
		var play_area_size = barrier_manager.get_current_play_area_size()
		play_area_center = Vector2.ZERO
		play_area_radius = min(play_area_size.x, play_area_size.y) / 2.0 - 80.0
	else:
		play_area_radius = 200.0


## Set the play area for this essence (called by spawner)
func set_play_area(center: Vector2, radius: float) -> void:
	play_area_center = center
	play_area_radius = radius


func _process(delta: float) -> void:
	time += delta
	
	# Gentle wandering using sine waves at different frequencies
	var velocity = Vector2(
		sin(time * frequency_x + offset_x) * amplitude_x,
		cos(time * frequency_y + offset_y) * amplitude_y
	).normalized() * speed
	
	# ADD: Gentle attraction toward player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var to_player = (player.global_position - global_position)
		var distance = to_player.length()
		
		# Only attract if within a certain range (not too aggressive from far away)
		if distance < 800.0:  # Attraction range
			var attraction_strength = 25.0  # How strong the pull is
			var attraction = to_player.normalized() * attraction_strength
			velocity += attraction
	
	var new_pos = global_position + velocity * delta
	
	# Soft boundary - gently push back toward center if getting too far
	var distance_from_center = new_pos.distance_to(play_area_center)
	if distance_from_center > play_area_radius:
		var push_direction = (play_area_center - new_pos).normalized()
		var push_strength = (distance_from_center - play_area_radius) * 0.5
		new_pos += push_direction * push_strength
	
	global_position = new_pos


func _apply_effect(collector: Node2D) -> void:
	GameManager.add_essence(essence_value)
	print("[EssencePickup] Granted %d essence to %s" % [essence_value, collector.name])