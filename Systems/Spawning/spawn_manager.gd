# Systems/Spawning/spawn_manager.gd
class_name SpawnManager
extends Node

## Manages ball spawning, types, and limits

signal ball_spawned(ball: BaseBall)
signal ball_count_changed(count: int, max_count: int)

# Spawnable ball configurations
@export var spawnable_balls: Array[BallConfig] = []
@export var max_total_balls: int = 20  # Total ball limit across all types

# References
var budding_spawner: BuddingSpawner
var active_balls: Array[BaseBall] = []


func _ready() -> void:
	add_to_group("spawn_manager")
	_find_budding_spawner()


func _find_budding_spawner() -> void:
	await get_tree().process_frame
	
	var player_ball = get_tree().get_first_node_in_group("player")
	if player_ball:
		budding_spawner = player_ball.get_node("BuddingSpawner")
		if not budding_spawner:
			push_warning("Player ball has no BuddingSpawner component")
	else:
		push_warning("No player ball found in scene")


## Spawn a ball by ball type ID
func spawn_ball(ball_config: BallConfig) -> bool:
	if not ball_config or not ball_config.ball_scene:
		push_warning("Invalid ball config or missing scene")
		return false
	
	_clean_dead_balls()
	
	# Check total ball limit
	if active_balls.size() >= max_total_balls:
		print("[SpawnManager] At max total ball capacity (%d)" % max_total_balls)
		return false
	
	# Check individual ball type limit (if set)
	if ball_config.max_count > 0:
		var type_count = _count_balls_of_type(ball_config.ball_type)
		if type_count >= ball_config.max_count:
			print("[SpawnManager] At max capacity for %s (%d)" % [ball_config.ball_type, ball_config.max_count])
			return false
	
	if not budding_spawner:
		push_warning("Cannot spawn: missing BuddingSpawner")
		return false
	
	# Spawn through BuddingSpawner
	var new_ball = budding_spawner.spawn_ball_from_scene(ball_config.ball_scene)
	
	if new_ball and new_ball is BaseBall:
		active_balls.append(new_ball)
		ball_spawned.emit(new_ball)
		ball_count_changed.emit(active_balls.size(), max_total_balls)
		print("[SpawnManager] Spawned %s (%d / %d total)" % [ball_config.ball_type, active_balls.size(), max_total_balls])
		return true
	
	return false


## Check if can spawn (not at max)
func can_spawn() -> bool:
	_clean_dead_balls()
	return active_balls.size() < max_total_balls and budding_spawner != null


## Check if can spawn specific ball type
func can_spawn_ball_type(ball_config: BallConfig) -> bool:
	if not can_spawn():
		return false
	
	if ball_config.max_count > 0:
		var type_count = _count_balls_of_type(ball_config.ball_type)
		return type_count < ball_config.max_count
	
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
	
