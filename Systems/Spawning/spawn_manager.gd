# Systems/Spawning/spawn_manager.gd
class_name SpawnManager
extends Node

## Manages ball and pickup spawning

signal ball_spawned(ball: BaseBall)
signal ball_count_changed(count: int, max_count: int)
signal pickup_spawned(pickup: BasePickup)
signal special_ball_spawned(ball: BaseBall)
signal balls_sacrificed(count: int)

# Spawnable configurations
@export var spawnable_balls: Array[BallConfig] = []
@export var spawnable_pickups: Array[PickupConfig] = []

# Pickup spawning settings
@export var pickup_spawning_enabled: bool = false

# References
var budding_spawner: BuddingSpawner
var active_balls: Array[BaseBall] = []
var active_pickups: Array[BasePickup] = []
var config_manager: GameConfigManager

# Pickup spawn timer
var pickup_check_timer: float = 0.0


func _ready() -> void:
	add_to_group("spawn_manager")
	_find_config_manager()
	_find_budding_spawner()


func _process(delta: float) -> void:
	if not pickup_spawning_enabled or not config_manager:
		return
	
	_clean_dead_pickups()
	
	# Handle pickup spawn checks
	pickup_check_timer += delta
	if pickup_check_timer >= config_manager.pickup_check_interval:
		pickup_check_timer = 0.0
		_try_spawn_pickup()


func _find_config_manager() -> void:
	config_manager = get_tree().get_first_node_in_group("game_config_manager")
	if not config_manager:
		push_warning("No GameConfigManager found in scene")


func _find_budding_spawner() -> void:
	await get_tree().process_frame
	
	var player_ball = get_tree().get_first_node_in_group("player")
	if player_ball:
		budding_spawner = player_ball.get_node("BuddingSpawner")
		if not budding_spawner:
			push_warning("Player ball has no BuddingSpawner component")
	else:
		push_warning("No player ball found in scene")


## Spawn a ball by ball config
func spawn_ball(ball_config: BallConfig) -> bool:
	# Check if this is a special ball (has essence cost)
	if ball_config.essence_cost > 0:
		return false
	
	# Regular ball spawning logic
	if not ball_config or not ball_config.ball_scene:
		push_warning("Invalid ball config or missing scene")
		return false
	
	if not config_manager:
		push_warning("No GameConfigManager available")
		return false
	
	_clean_dead_balls()
	
	# Check total ball limit
	if active_balls.size() >= config_manager.max_total_balls:
		print("[SpawnManager] At max total ball capacity (%d)" % config_manager.max_total_balls)
		return false
	
	# Check individual ball type limit
	var max_for_type = _get_max_count_for_type(ball_config.ball_type)
	if max_for_type > 0:
		var type_count = _count_balls_of_type(ball_config.ball_type)
		if type_count >= max_for_type:
			print("[SpawnManager] At max capacity for %s (%d)" % [ball_config.ball_type, max_for_type])
			return false
	
	if not budding_spawner:
		push_warning("Cannot spawn: missing BuddingSpawner")
		return false
	
	# Spawn through BuddingSpawner
	var new_ball = budding_spawner.spawn_ball_from_scene(ball_config.ball_scene)
	
	if new_ball and new_ball is BaseBall:
		active_balls.append(new_ball)
		ball_spawned.emit(new_ball)
		ball_count_changed.emit(active_balls.size(), config_manager.max_total_balls)
		print("[SpawnManager] Spawned %s (%d / %d total)" % 
			[ball_config.ball_type, active_balls.size(), config_manager.max_total_balls])
		return true
	
	return false


## Spawn a special ball (requires sacrifice)
func spawn_special_ball(ball_config: BallConfig) -> bool:
	if not config_manager:
		push_warning("No GameConfigManager available")
		return false
	
	_clean_dead_balls()
	
	# Check if at max basic balls
	var basic_count = _count_balls_of_type("basic")
	var max_basic = config_manager.max_basic_balls
	
	if basic_count < max_basic:
		print("[SpawnManager] Need max basic balls to spawn special (%d / %d)" % [basic_count, max_basic])
		return false
	
	# Check essence cost
	if GameManager.essence < ball_config.essence_cost:
		print("[SpawnManager] Not enough essence (%d / %d)" % [GameManager.essence, ball_config.essence_cost])
		return false
	
	# Choose random convergence point in play area
	var convergence_point = _get_random_spawn_position()
	
	# Sacrifice all basic balls with visual effect
	var sacrificed_count = await _sacrifice_all_basic_balls(convergence_point)
	balls_sacrificed.emit(sacrificed_count)
	
	# Deduct essence
	GameManager.essence -= ball_config.essence_cost
	GameManager.essence_changed.emit(GameManager.essence)
	
	# Increase max basic balls and trigger UI animation
	var old_max = config_manager.max_basic_balls
	config_manager.base_max_basic_balls += config_manager.special_ball_max_increase
	var new_max = config_manager.max_basic_balls
	print("[SpawnManager] Increased max basic balls: %d -> %d" % [old_max, new_max])
	
	# Trigger sidebar animation (find sidebar and call directly)
	await get_tree().create_timer(0.7).timeout  # Wait a moment
	var sidebar = get_tree().get_first_node_in_group("sidebar")
	if sidebar and sidebar.has_method("animate_max_balls_increase"):
		sidebar.animate_max_balls_increase(old_max, new_max)
	
	# Spawn special ball at convergence point
	var new_ball = ball_config.ball_scene.instantiate()
	new_ball.global_position = convergence_point
	
	get_tree().current_scene.add_child(new_ball)
	
	if new_ball and new_ball is BaseBall:
		active_balls.append(new_ball)
		special_ball_spawned.emit(new_ball)
		ball_count_changed.emit(active_balls.size(), config_manager.max_total_balls)
		print("[SpawnManager] Spawned special %s at %s (sacrificed %d basic balls)" % 
			[ball_config.ball_type, convergence_point, sacrificed_count])
		return true
	
	return false


## Sacrifice all basic balls with visual effect
func _sacrifice_all_basic_balls(target_pos: Vector2) -> int:
	var basic_balls_to_sacrifice: Array[BaseBall] = []
	
	# Collect all basic balls
	for ball in active_balls:
		if ball.ball_type == "basic":
			basic_balls_to_sacrifice.append(ball)
	
	var sacrifice_count = basic_balls_to_sacrifice.size()
	
	# Animate each ball moving toward target
	for ball in basic_balls_to_sacrifice:
		_sacrifice_ball_with_effect(ball, target_pos)
		active_balls.erase(ball)
	
	# Wait for animations to complete
	if sacrifice_count > 0:
		await get_tree().create_timer(0.5).timeout
	
	print("[SpawnManager] Sacrificed %d basic balls" % sacrifice_count)
	return sacrifice_count


## Visual effect for sacrificing a single ball
func _sacrifice_ball_with_effect(ball: BaseBall, target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ball, "global_position", target_pos, 0.5)
	tween.tween_property(ball, "scale", Vector2.ZERO, 0.5)
	tween.tween_property(ball, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.finished.connect(ball.queue_free)


## Try to spawn a pickup based on chance
func _try_spawn_pickup() -> void:
	# Check if already at max
	if active_pickups.size() >= config_manager.max_active_pickups:
		return
	
	# Roll for spawn chance
	var roll = randf()
	if roll < config_manager.pickup_spawn_chance:
		_spawn_random_pickup()
		print("[SpawnManager] Pickup spawn roll succeeded! (%.2f < %.2f)" % 
			[roll, config_manager.pickup_spawn_chance])


## Spawn a random pickup based on spawn weights
func _spawn_random_pickup() -> void:
	if spawnable_pickups.is_empty():
		return
	
	# Weighted random selection
	var total_weight = 0
	for config in spawnable_pickups:
		total_weight += config.spawn_weight
	
	if total_weight <= 0:
		return
	
	var roll = randi_range(0, total_weight - 1)
	var current_weight = 0
	
	for config in spawnable_pickups:
		current_weight += config.spawn_weight
		if roll < current_weight:
			_spawn_pickup(config)
			break


## Spawn a specific pickup
func _spawn_pickup(config: PickupConfig) -> void:
	if not config.pickup_scene:
		push_warning("[SpawnManager] PickupConfig missing pickup_scene")
		return
	
	var pickup = config.pickup_scene.instantiate()
	
	# Set pickup properties
	if pickup is BasePickup:
		pickup.visual_color = config.visual_color
		pickup.pickup_lifetime = config_manager.pickup_lifetime if config_manager else 30.0
	
	# Set buff config for BuffPickup
	if pickup is BuffPickup and config.buff_config:
		pickup.buff_config = config.buff_config
	
	# Random spawn position
	var spawn_pos = _get_random_spawn_position()
	pickup.global_position = spawn_pos
	
	# Add to scene
	get_tree().current_scene.add_child(pickup)
	active_pickups.append(pickup)
	pickup_spawned.emit(pickup)
	
	print("[SpawnManager] Spawned %s at %s" % [config.display_name, spawn_pos])


func _get_random_spawn_position() -> Vector2:
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if not barrier_manager:
		# Fallback if no barrier manager
		push_warning("[SpawnManager] No BarrierManager found, using default spawn area")
		return Vector2(randf_range(-200, 200), randf_range(-200, 200))
	
	# Get the size of the current play area (innermost unbroken barrier)
	var play_area_size = barrier_manager.get_current_play_area_size()
	var half_size = play_area_size / 2.0
	
	# Spawn within the play area with some padding to avoid spawning in walls
	var padding = 50.0
	return Vector2(
		randf_range(-half_size.x + padding, half_size.x - padding),
		randf_range(-half_size.y + padding, half_size.y - padding)
	)


## Get max count for a specific ball type from GameConfigManager
func _get_max_count_for_type(ball_type: String) -> int:
	if not config_manager:
		return 0
	
	match ball_type:
		"basic":
			return config_manager.max_basic_balls
		"explosive":
			return config_manager.max_explosive_balls
		_:
			return 0  # No limit for unknown types


## Check if can spawn (not at max)
func can_spawn() -> bool:
	if not config_manager:
		return false
	
	_clean_dead_balls()
	return active_balls.size() < config_manager.max_total_balls and budding_spawner != null


## Check if can spawn specific ball type
func can_spawn_ball_type(ball_config: BallConfig) -> bool:
	# Special balls have different requirements
	if ball_config.essence_cost > 0:
		return can_spawn_special_ball(ball_config)
	
	if not can_spawn():
		return false
	
	var max_for_type = _get_max_count_for_type(ball_config.ball_type)
	if max_for_type > 0:
		var type_count = _count_balls_of_type(ball_config.ball_type)
		return type_count < max_for_type
	
	return true


## Check if can spawn a special ball
func can_spawn_special_ball(ball_config: BallConfig) -> bool:
	if not config_manager:
		return false
	
	_clean_dead_balls()
	
	# Must be at max basic balls
	var basic_count = _count_balls_of_type("basic")
	if basic_count < config_manager.max_basic_balls:
		return false
	
	# Must have enough essence
	if GameManager.essence < ball_config.essence_cost:
		return false
	
	return true


## Get current total ball count
func get_total_ball_count() -> int:
	_clean_dead_balls()
	return active_balls.size()


## Count balls of a specific type
func _count_balls_of_type(type: String) -> int:
	_clean_dead_balls()
	var count = 0
	for ball in active_balls:
		if ball.ball_type == type:
			count += 1
	return count


func _clean_dead_balls() -> void:
	active_balls = active_balls.filter(func(ball): return is_instance_valid(ball))


func _clean_dead_pickups() -> void:
	active_pickups = active_pickups.filter(func(p): return is_instance_valid(p))


## Enable pickup spawning
func enable_pickup_spawning() -> void:
	pickup_spawning_enabled = true
	print("[SpawnManager] Pickup spawning enabled")


## Disable pickup spawning
func disable_pickup_spawning() -> void:
	pickup_spawning_enabled = false
	print("[SpawnManager] Pickup spawning disabled")
