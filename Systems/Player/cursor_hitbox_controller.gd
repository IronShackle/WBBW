# Systems/Player/cursor_hitbox_controller.gd
extends Node2D

## Player controller using charged mouse hitboxes - auto-charging version

signal charge_updated(charge_percent: float)
signal charge_released(charge_percent: float)

@export var max_charge_time: float = 2.0
@export var min_hitbox_radius: float = 30.0
@export var max_hitbox_radius: float = 120.0
@export var min_knockback_force: float = 300.0
@export var max_knockback_force: float = 1000.0
@export var hitbox_duration: float = 0.15

var charge_time: float = 0.0
var mouse_position: Vector2 = Vector2.ZERO

# Visual indicator
var charge_visual: Node2D


func _ready() -> void:
	# Create visual indicator
	charge_visual = Node2D.new()
	add_child(charge_visual)
	charge_visual.z_index = 100  # Render on top


func _process(delta: float) -> void:
	# Track mouse position
	mouse_position = get_global_mouse_position()
	
	# Always charge automatically
	if charge_time < max_charge_time:
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)
		
		var charge_percent = charge_time / max_charge_time
		charge_updated.emit(charge_percent)
	
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_release_charge()


func _draw() -> void:
	# Always draw charging circle at mouse position
	var charge_percent = charge_time / max_charge_time
	var current_radius = lerp(min_hitbox_radius, max_hitbox_radius, charge_percent)
	
	# Convert mouse position to local coordinates for drawing
	var local_mouse = to_local(mouse_position)
	
	# Draw outer circle (charge indicator)
	var circle_color = Color.ORANGE.lerp(Color.RED, charge_percent)
	circle_color.a = 0.3 + (charge_percent * 0.2)  # Fade in as it charges
	draw_circle(local_mouse, current_radius, circle_color)
	
	# Draw border
	draw_arc(local_mouse, current_radius, 0, TAU, 32, circle_color.lightened(0.3), 3.0)
	
	# Draw center dot
	draw_circle(local_mouse, 5.0, Color.WHITE)


func _release_charge() -> void:
	var charge_percent = charge_time / max_charge_time
	
	# Spawn hitbox at current charge level
	_spawn_hitbox(charge_percent)
	
	charge_released.emit(charge_percent)
	
	# Reset charge
	charge_time = 0.0
	queue_redraw()


func _spawn_hitbox(charge_percent: float) -> void:
	var hitbox = HitboxInstance.new()
	hitbox.global_position = mouse_position
	hitbox.hitbox_owner = self
	
	# Create circular shape scaled by charge
	var shape = CircleShape2D.new()
	var radius = lerp(min_hitbox_radius, max_hitbox_radius, charge_percent)
	shape.radius = radius
	
	# Configure hitbox
	hitbox.shape = shape
	hitbox.knockback_force = lerp(min_knockback_force, max_knockback_force, charge_percent)
	hitbox.use_radial_knockback = true
	hitbox.damage = 0
	hitbox.duration = hitbox_duration
	
	get_tree().current_scene.add_child(hitbox)

