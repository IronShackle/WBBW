# Systems/Movement/movement_component.gd
extends Node
class_name MovementComponent

## Handles snappy impulse-based movement with directional snap

@export_group("Movement Settings")
@export var max_speed: float = 200.0
@export var acceleration_rate: float = 1500.0
@export var deceleration_rate: float = 8.0
@export var snap_threshold: float = 90.0
@export var snap_impulse: float = 150.0

@export_group("Dash Settings")
@export var dash_distance: float = 120.0
@export var dash_speed: float = 800.0

var character_body: CharacterBody2D

# State tracking
var move_intent: Vector2 = Vector2.ZERO
var current_velocity: Vector2 = Vector2.ZERO
var external_impulse: Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2.ZERO
var last_valid_direction: Vector2 = Vector2.RIGHT
var movement_modifier: float = 1.0


func _ready() -> void:
	if get_parent() is CharacterBody2D:
		character_body = get_parent()
	else:
		push_error("MovementComponent must be child of CharacterBody2D")


func _physics_process(delta: float) -> void:
	if move_intent.length() > 0.1:
		_process_movement_input(delta)
	else:
		_apply_deceleration(delta)
	
	# Apply movement modifier
	var modified_velocity = current_velocity * movement_modifier
	
	# Clamp movement velocity to max speed
	if modified_velocity.length() > max_speed:
		modified_velocity = modified_velocity.normalized() * max_speed
	
	# Combine movement velocity with external impulses
	character_body.velocity = modified_velocity + external_impulse
	character_body.move_and_slide()
	
	# Decay external impulse
	if external_impulse.length() > 0.1:
		external_impulse = external_impulse.move_toward(Vector2.ZERO, external_impulse.length() * deceleration_rate * delta)
	else:
		external_impulse = Vector2.ZERO
	
	# Clear intent for next frame
	move_intent = Vector2.ZERO


func _process_movement_input(delta: float) -> void:
	var input_dir = move_intent.normalized()
	
	# Check for directional snap (input reversal)
	if _check_directional_snap(input_dir):
		current_velocity = input_dir * snap_impulse
	else:
		# Fluid movement toward input direction
		var target_velocity = input_dir * max_speed
		current_velocity = current_velocity.move_toward(target_velocity, acceleration_rate * delta)
	
	last_input_direction = input_dir
	last_valid_direction = input_dir


func _check_directional_snap(new_direction: Vector2) -> bool:
	if last_input_direction.length() < 0.1:
		return false
	
	var angle_diff = rad_to_deg(last_input_direction.angle_to(new_direction))
	return abs(angle_diff) > snap_threshold


func _apply_deceleration(delta: float) -> void:
	var decel_amount = current_velocity.length() * deceleration_rate * delta
	current_velocity = current_velocity.move_toward(Vector2.ZERO, decel_amount)
	last_input_direction = Vector2.ZERO


## Set movement intent for this frame
func set_move_intent(direction: Vector2) -> void:
	move_intent = direction


## Apply movement in a direction (wrapper for compatibility)
func move_in_direction(direction: Vector2, _delta: float) -> void:
	set_move_intent(direction)


## Apply friction (compatibility)
func apply_friction(_delta: float) -> void:
	pass


## Apply external impulse (knockback, dash, etc)
func apply_impulse(impulse: Vector2) -> void:
	external_impulse += impulse


## Start a dash
func start_dash(direction: Vector2) -> void:
	var dash_dir = direction.normalized() if direction.length() > 0.1 else last_valid_direction
	if dash_dir.length() < 0.1:
		dash_dir = Vector2.RIGHT
	
	apply_impulse(dash_dir * dash_speed)


## Stop all movement
func stop() -> void:
	current_velocity = Vector2.ZERO
	external_impulse = Vector2.ZERO
	move_intent = Vector2.ZERO


## Get last movement direction
func get_last_direction() -> Vector2:
	return last_valid_direction


## Set movement speed multiplier
func set_movement_modifier(modifier: float) -> void:
	movement_modifier = modifier


## Reset movement modifier
func reset_movement_modifier() -> void:
	movement_modifier = 1.0