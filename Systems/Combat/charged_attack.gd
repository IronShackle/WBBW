# Components/charged_attack.gd
class_name ChargedAttack
extends Node2D

## Component that handles charging and launching attacks with hitbox

signal charge_started()
signal charge_updated(charge_percent: float)
signal charge_released(direction: Vector2, charge_percent: float)
signal charge_cancelled()

@export var max_charge_time: float = 2.0
@export var min_charge_time: float = 0.2
@export var max_launch_speed: float = 1000.0
@export var min_launch_speed: float = 200.0
@export var attack_radius: float = 80.0
@export var knockback_force: float = 600.0
@export var movement_speed_while_charging: float = 100.0
@export var can_move_while_charging: bool = true

var is_charging: bool = false
var charge_time: float = 0.0
var charge_start_pos: Vector2
var charge_direction: Vector2
var body: CharacterBody2D


func _ready() -> void:
	add_to_group("charged_attack")
	body = get_parent()


func _draw() -> void:
	if not is_charging:
		return
	
	# Draw charge indicator
	var charge_percent = clampf(charge_time / max_charge_time, 0.0, 1.0)
	var max_arrow_length = 150.0
	var arrow_length = charge_percent * max_arrow_length
	
	if charge_direction.length() > 0:
		var end_pos = charge_direction.normalized() * arrow_length
		
		# Draw arrow line
		draw_line(Vector2.ZERO, end_pos, Color.ORANGE, 3.0)
		
		# Draw arrowhead
		var arrow_size = 15.0
		var perpendicular = charge_direction.normalized().rotated(PI / 2) * arrow_size
		var arrow_back = end_pos - charge_direction.normalized() * arrow_size
		
		draw_line(end_pos, arrow_back + perpendicular, Color.ORANGE, 3.0)
		draw_line(end_pos, arrow_back - perpendicular, Color.ORANGE, 3.0)
	
	# Draw attack radius
	var color = Color(1.0, 0.5, 0.0, 0.3 + (charge_percent * 0.3))
	draw_arc(Vector2.ZERO, attack_radius, 0, TAU, 32, color, 2.0)


func update(delta: float) -> void:
	if is_charging:
		charge_time += delta
		var mouse_pos = body.get_global_mouse_position()
		charge_direction = charge_start_pos - mouse_pos
		var charge_percent = clampf(charge_time / max_charge_time, 0.0, 1.0)
		charge_updated.emit(charge_percent)
		queue_redraw()


func start_charge(start_position: Vector2 = Vector2.ZERO) -> void:
	is_charging = true
	charge_time = 0.0
	charge_start_pos = start_position if start_position != Vector2.ZERO else body.global_position
	charge_direction = Vector2.ZERO
	charge_started.emit()
	queue_redraw()


func release_charge() -> bool:
	if not is_charging:
		return false
	
	var was_valid_charge = charge_time >= min_charge_time
	
	if was_valid_charge and charge_direction.length() > 0:
		var charge_percent = clampf(charge_time / max_charge_time, 0.0, 1.0)
		var normalized_direction = charge_direction.normalized()
		
		# Spawn hitbox attack
		_spawn_attack_hitbox()
		
		charge_released.emit(normalized_direction, charge_percent)
	
	is_charging = false
	charge_time = 0.0
	charge_direction = Vector2.ZERO
	queue_redraw()
	
	return was_valid_charge


func cancel_charge() -> void:
	if not is_charging:
		return
	
	is_charging = false
	charge_time = 0.0
	charge_direction = Vector2.ZERO
	queue_redraw()
	charge_cancelled.emit()


func _spawn_attack_hitbox() -> void:
	var hitbox = HitboxInstance.new()
	hitbox.position = Vector2.ZERO
	hitbox.hitbox_owner = body
	
	# Create circular attack shape
	var shape = CircleShape2D.new()
	shape.radius = attack_radius
	
	# Configure hitbox
	hitbox.shape = shape
	hitbox.knockback_force = knockback_force
	hitbox.use_radial_knockback = true
	hitbox.damage = 0
	hitbox.duration = 0.1
	
	add_child(hitbox)
	
	print("[ChargedAttack] Spawned attack hitbox (radius: %s, force: %s)" % 
		[attack_radius, knockback_force])


func get_launch_velocity() -> Vector2:
	if charge_direction.length() == 0:
		return Vector2.ZERO
	
	var charge_percent = clampf(charge_time / max_charge_time, 0.0, 1.0)
	var speed = lerpf(min_launch_speed, max_launch_speed, charge_percent)
	return charge_direction.normalized() * speed


func get_charge_percent() -> float:
	return clampf(charge_time / max_charge_time, 0.0, 1.0)
