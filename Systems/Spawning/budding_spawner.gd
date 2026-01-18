# Systems/Spawning/budding_spawner.gd
class_name BuddingSpawner
extends Node

## Spawns balls from the player on demand

@export var spawn_velocity: float = 300.0  # Initial velocity of spawned ball
@export var spawn_offset: float = 80.0  # Distance from parent to spawn


## Spawn a ball from a given scene (returns the spawned ball or null)
func spawn_ball_from_scene(ball_scene: PackedScene) -> Node2D:
	if not ball_scene:
		push_warning("No ball scene provided to spawn")
		return null
	
	var parent = get_parent()
	
	# Try to find a valid spawn position
	var spawn_position: Vector2
	var spawn_direction: Vector2
	var valid_spawn = false
	var max_attempts = 8
	
	for attempt in range(max_attempts):
		var random_angle = randf() * TAU
		spawn_direction = Vector2(cos(random_angle), sin(random_angle))
		spawn_position = parent.global_position + (spawn_direction * spawn_offset)
		
		if _is_valid_spawn_position(parent.global_position, spawn_position):
			valid_spawn = true
			break
	
	if not valid_spawn:
		push_warning("[BuddingSpawner] Could not find valid spawn position after %d attempts" % max_attempts)
		return null
	
	# Spawn the ball
	var new_ball = ball_scene.instantiate()
	new_ball.global_position = spawn_position
	
	# Add to scene (deferred to avoid physics issues)
	get_tree().current_scene.call_deferred("add_child", new_ball)
	
	# Set initial velocity on spawned ball's BounceComponent
	var spawned_bounce = new_ball.get_node("BounceComponent")
	if spawned_bounce:
		spawned_bounce.call_deferred("apply_knockback", spawn_direction, spawn_velocity)
	
	print("[BuddingSpawner] Spawned ball at %s with velocity %s" % [spawn_position, spawn_direction * spawn_velocity])
	
	return new_ball


func _is_valid_spawn_position(from: Vector2, to: Vector2) -> bool:
	var space_state = get_parent().get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	return not result  # Valid if nothing was hit