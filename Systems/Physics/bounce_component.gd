# Systems/Physics/bounce_component.gd
extends Node
class_name BounceComponent

## Handles velocity-based knockback and wall bouncing with per-ball physics overrides

signal bounced(collision: KinematicCollision2D)
signal wall_hit(wall: Node)
signal barrier_hit(barrier: Node)
signal ball_hit(other_ball: Node2D)

var body: CharacterBody2D
var detection_area: Area2D
var knockback_velocity: Vector2 = Vector2.ZERO
var bounce_count: int = 0
var physics_manager: PhysicsManager

# Physics overrides (-1 = use PhysicsManager default)
var friction_override: float = -1.0
var wall_bounce_damping_override: float = -1.0
var ball_bounce_restitution_override: float = -1.0
var ball_collision_kickback_override: float = -1.0
var max_bounce_speed_override: float = -1.0

# Debounce tracking
var last_bounce_time: float = 0.0
var bounce_cooldown: float = 0.1

# Ball collision tracking
var collided_balls: Dictionary = {}
var ball_collision_cooldown: float = 0.2
var pending_ball_collisions: Array[Node2D] = []


func _ready() -> void:
	body = get_parent() as CharacterBody2D
	if not body:
		push_error("BounceComponent must be child of CharacterBody2D")
	
	physics_manager = get_tree().get_first_node_in_group("physics_manager")
	if not physics_manager:
		push_warning("BounceComponent: No PhysicsManager found in scene")
	
	_setup_detection_area()


func _setup_detection_area() -> void:
	detection_area = body.get_node_or_null("BallDetection")
	
	if not detection_area:
		detection_area = Area2D.new()
		detection_area.name = "BallDetection"
		body.add_child(detection_area)
		
		for child in body.get_children():
			if child is CollisionShape2D:
				var area_shape = CollisionShape2D.new()
				area_shape.shape = child.shape
				area_shape.position = child.position
				detection_area.add_child(area_shape)
				break
		
		detection_area.collision_layer = 0
		detection_area.collision_mask = 1
	
	if not detection_area.body_entered.is_connected(_on_ball_body_entered):
		detection_area.body_entered.connect(_on_ball_body_entered)


func _on_ball_body_entered(other_body: Node2D) -> void:
	if other_body == body:
		return
	
	if not other_body.has_node("BounceComponent"):
		return
	
	var ball_id = other_body.get_instance_id()
	
	if collided_balls.has(ball_id):
		return

	if other_body not in pending_ball_collisions:
		pending_ball_collisions.append(other_body)


func _physics_process(delta: float) -> void:
	if not physics_manager:
		return
	
	# Update cooldown timers
	if last_bounce_time > 0.0:
		last_bounce_time -= delta
	
	var expired_ids = []
	for ball_id in collided_balls.keys():
		collided_balls[ball_id] -= delta
		if collided_balls[ball_id] <= 0.0:
			expired_ids.append(ball_id)
	
	for ball_id in expired_ids:
		collided_balls.erase(ball_id)
	
	# 1. FIRST: Resolve queued ball collisions BEFORE moving
	for other_ball in pending_ball_collisions:
		_handle_ball_collision(other_ball)
	pending_ball_collisions.clear()
	
	# Stop if below minimum velocity
	if knockback_velocity.length() < physics_manager.min_bounce_velocity:
		knockback_velocity = Vector2.ZERO
		return
	
	# 2. THEN: Set velocity and move
	body.velocity = knockback_velocity
	body.move_and_slide()
	
	# 3. Handle wall/barrier collisions from move result
	if body.get_slide_collision_count() > 0 and last_bounce_time <= 0.0:
		var collision = body.get_slide_collision(0)
		var collider = collision.get_collider()
		
		if collider.is_in_group("wall"):
			_handle_wall_bounce(collision)
			wall_hit.emit(collider)
		elif collider.is_in_group("barrier"):
			_handle_barrier_hit(collision)
			barrier_hit.emit(collider)
	
	# 4. Apply friction
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		get_friction_deceleration() * delta
	)


func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force
	
	var max_speed = get_max_bounce_speed()
	if knockback_velocity.length() > max_speed:
		knockback_velocity = knockback_velocity.normalized() * max_speed
	
	bounce_count = 0
	last_bounce_time = 0.0
	collided_balls.clear()


func _handle_ball_collision(other_body: Node2D) -> void:
	var other_bounce_component = other_body.get_node("BounceComponent") as BounceComponent
	
	if not other_bounce_component:
		return
	
	var collision_normal = (other_body.global_position - body.global_position).normalized()
	
	var v1 = knockback_velocity
	var v2 = other_bounce_component.knockback_velocity
	
	var v1_normal = v1.dot(collision_normal)
	var v2_normal = v2.dot(collision_normal)
	
	var relative_velocity_normal = v1_normal - v2_normal
	
	if relative_velocity_normal <= 0:
		return
	
	var restitution = get_ball_bounce_restitution()
	
	# Calculate new velocities with standard exchange
	var v1_normal_new = v2_normal * restitution
	var v2_normal_new = v1_normal * restitution
	
	# Add collision kickback for bouncy feel
	var collision_energy = abs(relative_velocity_normal) * get_ball_collision_kickback()
	v1_normal_new -= collision_energy
	v2_normal_new += collision_energy
	
	# Apply velocity changes
	var v1_change = (v1_normal_new - v1_normal) * collision_normal
	var v2_change = (v2_normal_new - v2_normal) * collision_normal
	
	knockback_velocity += v1_change
	other_bounce_component.knockback_velocity += v2_change
	
	var our_id = body.get_instance_id()
	var their_id = other_body.get_instance_id()
	
	collided_balls[their_id] = ball_collision_cooldown
	other_bounce_component.collided_balls[our_id] = ball_collision_cooldown

	var particles = get_parent().get_node_or_null("CollisionParticles")
	if particles:
		particles.restart()
	
	ball_hit.emit(other_body)


func _handle_wall_bounce(collision: KinematicCollision2D) -> void:
	if not physics_manager:
		return
	
	var normal = collision.get_normal()
	
	knockback_velocity = knockback_velocity.bounce(normal) * get_wall_bounce_damping()
	
	last_bounce_time = bounce_cooldown
	
	bounce_count += 1
	bounced.emit(collision)

	GameManager.register_bounce()


func _handle_barrier_hit(collision: KinematicCollision2D) -> void:
	_handle_wall_bounce(collision)


func get_velocity() -> Vector2:
	return knockback_velocity


func is_moving() -> bool:
	if not physics_manager:
		return knockback_velocity.length() > 50.0
	return knockback_velocity.length() > physics_manager.min_bounce_velocity


## Physics override getters
func get_friction_deceleration() -> float:
	if friction_override >= 0.0:
		return friction_override
	return physics_manager.friction_deceleration if physics_manager else 100.0


func get_wall_bounce_damping() -> float:
	if wall_bounce_damping_override >= 0.0:
		return wall_bounce_damping_override
	return physics_manager.wall_bounce_damping if physics_manager else 0.8


func get_ball_bounce_restitution() -> float:
	if ball_bounce_restitution_override >= 0.0:
		return ball_bounce_restitution_override
	return physics_manager.ball_bounce_restitution if physics_manager else 1.1


func get_ball_collision_kickback() -> float:
	if ball_collision_kickback_override >= 0.0:
		return ball_collision_kickback_override
	return physics_manager.ball_collision_kickback if physics_manager else 0.2


func get_max_bounce_speed() -> float:
	if max_bounce_speed_override >= 0.0:
		return max_bounce_speed_override
	return physics_manager.max_bounce_speed if physics_manager else 1000.0