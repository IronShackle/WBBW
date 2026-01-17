# Systems/Player/ball_player_controller.gd
extends CharacterBody2D

## Draggable ball player - click, drag, release to launch

@onready var bounce_component: BounceComponent = $BounceComponent

@export var max_launch_force: float = 1000.0
@export var force_multiplier: float = 2.0
@export var max_drag_distance: float = 150.0
@export var launch_cooldown: float = 0.5  # Seconds between launches

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var cooldown_timer: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# Update cooldown timer
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	if Input.is_action_just_pressed("attack"):  # Left mouse button
		_start_drag()
	
	if Input.is_action_just_released("attack"):
		_release_launch()


func _start_drag() -> void:
	# Can't drag if on cooldown
	if cooldown_timer > 0.0:
		return
	
	is_dragging = true
	drag_start_position = get_global_mouse_position()


func _release_launch() -> void:
	if not is_dragging:
		return
	
	is_dragging = false
	
	var mouse_pos = get_global_mouse_position()
	var launch_vector = drag_start_position - mouse_pos  # Launch away from drag
	
	# Clamp to max drag distance
	if launch_vector.length() > max_drag_distance:
		launch_vector = launch_vector.normalized() * max_drag_distance
	
	# Calculate launch force based on drag distance
	var launch_force = launch_vector.length() * force_multiplier
	launch_force = min(launch_force, max_launch_force)
	
	# Apply knockback
	if bounce_component and launch_vector.length() > 1.0:
		bounce_component.apply_knockback(launch_vector.normalized(), launch_force)
		cooldown_timer = launch_cooldown  # Start cooldown
		print("[BallPlayer] Launched with force: %.1f (cooldown: %.1fs)" % [launch_force, launch_cooldown])


func _draw() -> void:
	# Don't show aim line if on cooldown
	if cooldown_timer > 0.0:
		# Draw cooldown indicator
		var cooldown_percent = cooldown_timer / launch_cooldown
		draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.0, 0.0, 0.3 * cooldown_percent))
		return
	
	if not is_dragging:
		return
	
	# Get current mouse position
	var mouse_pos = get_global_mouse_position()
	var drag_vector = drag_start_position - mouse_pos
	
	# Clamp for visualization
	if drag_vector.length() > max_drag_distance:
		drag_vector = drag_vector.normalized() * max_drag_distance
	
	# Convert to local space for drawing
	var local_drag_vector = to_local(global_position + drag_vector)
	
	# Draw from ball center to launch direction
	draw_line(Vector2.ZERO, local_drag_vector, Color.YELLOW, 3.0)
	
	# Draw power indicator (circle at end)
	var power_percent = drag_vector.length() / max_drag_distance
	draw_circle(local_drag_vector, 8.0, Color.YELLOW.lerp(Color.RED, power_percent))
	
	# Draw crosshair at mouse position (aim point)
	var mouse_local = to_local(mouse_pos)
	draw_circle(mouse_local, 4.0, Color.WHITE)


func _physics_process(_delta: float) -> void:
	# Redraw aim line each frame
	queue_redraw()