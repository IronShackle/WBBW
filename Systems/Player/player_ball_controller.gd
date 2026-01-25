# Systems/Player/player_ball_controller.gd
extends BaseBall

## Draggable ball player - click, drag, release to launch

@onready var launch_trail: Line2D = get_node("/root/Game/PlayerLaunchTrail")

@export var max_launch_force: float = 1000.0
@export var force_multiplier: float = 2.0
@export var max_drag_distance: float = 150.0
@export var launch_cooldown: float = 0.5
@export var launched_grace_period: float = 0.2

@export_group("Trail Settings")
@export var trail_length: int = 20
@export var trail_color: Color = Color(1.0, 0.8, 0.0, 0.7)
@export var trail_width: float = 3.0

@export_group("Upgrades")
@export var max_velocity_multiplier: float = 1.0

enum State { IDLE, CHARGING, LAUNCHED, ROLLING }
var current_state = State.IDLE
var state_timer: float = 0.0

var drag_start_position: Vector2 = Vector2.ZERO
var has_bounced_since_launch: bool = false
var cooldown_timer: float = 0.0
var trail_fade_tween: Tween
var is_trail_fading: bool = false

func _ready() -> void:
	if bounce_component:
		bounce_component.bounced.connect(_on_bounced)
	
	is_breakable = false

	_setup_trail()


func _setup_trail() -> void:
	if not launch_trail:
		push_warning("LaunchTrail not found in scene!")
		return
	
	launch_trail.width = trail_width
	launch_trail.default_color = trail_color
	launch_trail.begin_cap_mode = Line2D.LINE_CAP_NONE
	launch_trail.end_cap_mode = Line2D.LINE_CAP_NONE
	
	# Add width curve for taper
	var width_curve = Curve.new()
	width_curve.add_point(Vector2(0, 0.1))  # Full width at newest point
	width_curve.add_point(Vector2(1, 1.0))  # Thin at oldest point
	launch_trail.width_curve = width_curve
	
	launch_trail.visible = false


func _process(delta: float) -> void:
	state_timer += delta
	
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	if Input.is_action_just_pressed("attack"):
		_try_start_charge()
	
	if Input.is_action_just_released("attack"):
		_try_release_launch()


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_handle_idle(delta)
		State.CHARGING:
			_handle_charging(delta)
		State.LAUNCHED:
			_handle_launched(delta)
		State.ROLLING:
			_handle_rolling(delta)
	
	_update_trail()
	queue_redraw()


func _handle_idle(delta: float) -> void:
	if bounce_component and bounce_component.is_moving():
		_transition_to(State.ROLLING)


func _handle_charging(delta: float) -> void:
	pass


func _handle_launched(delta: float) -> void:
	if has_bounced_since_launch and state_timer >= launched_grace_period:
		_transition_to(State.ROLLING)


func _handle_rolling(delta: float) -> void:
	if bounce_component and not bounce_component.is_moving():
		_transition_to(State.IDLE)


func _transition_to(new_state: int) -> void:
	match current_state:
		State.CHARGING:
			pass
		State.LAUNCHED:
			has_bounced_since_launch = false
	
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.IDLE:
			pass
		State.CHARGING:
			drag_start_position = get_global_mouse_position()
		State.LAUNCHED:
			has_bounced_since_launch = false
		State.ROLLING:
			pass


func _try_start_charge() -> void:
	if cooldown_timer > 0.0:
		return
	
	_transition_to(State.CHARGING)


func _try_release_launch() -> void:
	if current_state != State.CHARGING:
		return
	
	var mouse_pos = get_global_mouse_position()
	var launch_vector = drag_start_position - mouse_pos
	
	if launch_vector.length() > max_drag_distance:
		launch_vector = launch_vector.normalized() * max_drag_distance
	
	var launch_force = launch_vector.length() * force_multiplier
	launch_force = min(launch_force, max_launch_force)
	
	if bounce_component and launch_vector.length() > 1.0:
		bounce_component.apply_knockback(launch_vector.normalized(), launch_force)
		cooldown_timer = launch_cooldown
		_transition_to(State.LAUNCHED)
	else:
		_transition_to(State.IDLE if not bounce_component.is_moving() else State.ROLLING)


func _on_bounced(collision: KinematicCollision2D) -> void:
	if current_state == State.LAUNCHED:
		has_bounced_since_launch = true


# Update _update_trail:
func _update_trail() -> void:
	if not launch_trail:
		return
	
	if current_state == State.LAUNCHED:
		# Cancel any fade and reset
		if trail_fade_tween:
			trail_fade_tween.kill()
		is_trail_fading = false
		
		launch_trail.add_point(global_position)
		
		if launch_trail.get_point_count() > trail_length:
			launch_trail.remove_point(0)
		
		launch_trail.visible = true
		launch_trail.modulate.a = 1.0
	else:
		# Start fade if not already fading
		if launch_trail.visible and not is_trail_fading:
			is_trail_fading = true
			trail_fade_tween = create_tween()
			trail_fade_tween.tween_property(launch_trail, "modulate:a", 0.0, 0.3)
			trail_fade_tween.tween_callback(func():
				launch_trail.clear_points()
				launch_trail.visible = false
				is_trail_fading = false
			)
		
		# Keep adding points during fade for smooth continuation
		if is_trail_fading:
			launch_trail.add_point(global_position)
			if launch_trail.get_point_count() > trail_length:
				launch_trail.remove_point(0)


func _draw() -> void:
	if cooldown_timer > 0.0:
		var cooldown_percent = cooldown_timer / launch_cooldown
		draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.0, 0.0, 0.3 * cooldown_percent))
		return
	
	if current_state == State.CHARGING:
		var mouse_pos = get_global_mouse_position()
		var drag_vector = drag_start_position - mouse_pos
		
		if drag_vector.length() > max_drag_distance:
			drag_vector = drag_vector.normalized() * max_drag_distance
		
		var local_drag_vector = to_local(global_position + drag_vector)
		
		draw_line(Vector2.ZERO, local_drag_vector, Color.YELLOW, 3.0)
		
		var power_percent = drag_vector.length() / max_drag_distance
		draw_circle(local_drag_vector, 8.0, Color.YELLOW.lerp(Color.RED, power_percent))
		
		var mouse_local = to_local(mouse_pos)
		draw_circle(mouse_local, 4.0, Color.WHITE)
