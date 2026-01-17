# Systems/Combat/charged_attack.gd
extends Node
class_name ChargedAttack

## Charge-hold-release attack that spawns arc hitbox

signal attack_completed()
signal charge_updated(charge_level: float)

@export_group("Charge Properties")
@export var charge_rate: float = 1.0
@export var min_knockback: float = 200.0
@export var max_knockback: float = 800.0

@export_group("Hitbox Properties")
@export var hitbox_radius: float = 60.0
@export var hitbox_angle: float = 120.0
@export var hitbox_lifetime: float = 0.15

@export_group("Movement")
@export var movement_speed_while_charging: float = 0.3

var player: Node2D
var charge_level: float = 0.0
var is_charging: bool = false
var is_attacking: bool = false
var bounce_manager: BounceManager


func _ready() -> void:
	player = get_parent()
	
	# Find bounce manager
	bounce_manager = get_tree().get_first_node_in_group("bounce_manager")
	if not bounce_manager:
		push_warning("ChargedAttack: No BounceManager found in scene")


## Start charging the attack
func start_charge() -> void:
	if is_attacking:
		return
	
	is_charging = true
	charge_level = 0.0
	charge_updated.emit(charge_level)


## Update charge level while button held
func update_charge(delta: float) -> void:
	if not is_charging:
		return
	
	charge_level = min(charge_level + charge_rate * delta, 1.0)
	charge_updated.emit(charge_level)


## Release and execute the attack
func release_attack() -> void:
	if not is_charging:
		return
	
	is_charging = false
	is_attacking = true
	
	_execute_attack()
	
	# Short delay before allowing next charge
	await get_tree().create_timer(0.1).timeout
	is_attacking = false
	attack_completed.emit()


func _execute_attack() -> void:
	var attack_direction = _get_attack_direction()
	_spawn_hitbox(attack_direction)


func _get_attack_direction() -> Vector2:
	var mouse_pos = player.get_global_mouse_position()
	var to_mouse = (mouse_pos - player.global_position).normalized()
	
	if to_mouse.length() < 0.1:
		return Vector2.RIGHT
	
	return _snap_direction_to_45(to_mouse)


func _snap_direction_to_45(direction: Vector2) -> Vector2:
	if direction.length() < 0.1:
		return Vector2.RIGHT
	
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	var snapped_degrees = round(degrees / 45.0) * 45.0
	
	return Vector2.from_angle(deg_to_rad(snapped_degrees))


func _spawn_hitbox(attack_direction: Vector2) -> void:
	var hitbox = HitboxInstance.new()
	player.get_tree().current_scene.add_child(hitbox)
	
	hitbox.global_position = player.global_position
	hitbox.rotation = attack_direction.angle()
	
	hitbox.initialize(
		hitbox_lifetime,
		ShapePreset.ShapeType.ARC,
		hitbox_radius,
		hitbox_angle,
		Vector2.ZERO
	)
	
	hitbox.hit_landed.connect(_on_hitbox_hit)


func _on_hitbox_hit(target: Node2D) -> void:
	if target == player:
		return  # Don't hit self
	
	if not bounce_manager:
		push_warning("ChargedAttack: Cannot apply knockback, no BounceManager")
		return
	
	var knockback_dir = (target.global_position - player.global_position).normalized()
	var scaled_knockback = lerpf(min_knockback, max_knockback, charge_level)
	
	# Apply knockback through BounceComponent
	var bounce_component = target.get_node_or_null("BounceComponent")
	if bounce_component:
		bounce_component.apply_knockback(knockback_dir, scaled_knockback)
		print("[ChargedAttack] Hit %s with %.1f%% charge (knockback: %.1f)" % [target.name, charge_level * 100, scaled_knockback])


## Check if currently charging
func get_is_charging() -> bool:
	return is_charging


## Check if currently attacking
func get_is_attacking() -> bool:
	return is_attacking


## Get current charge level (0.0 - 1.0)
func get_charge_level() -> float:
	return charge_level
