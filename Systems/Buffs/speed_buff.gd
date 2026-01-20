# Systems/Buffs/speed_buff.gd
class_name SpeedBuff
extends BaseBuff

## Increases max bounce speed to make the ball go faster


func _init() -> void:
	buff_id = "speed_boost"
	display_name = "Speed Boost"
	description = "Increases max speed"
	can_stack = false


func apply_effect(entity: Node2D) -> void:
	var bounce_component = entity.get_node_or_null("BounceComponent")
	if not bounce_component:
		return
	
	var physics_manager = bounce_component.physics_manager
	if not physics_manager:
		return
	
	# Read speed_multiplier from config parameters (default 1.5 for 50% faster)
	var multiplier = config.parameters.get("speed_multiplier", 1.5) if config else 1.5
	
	# Apply max speed increase
	var base_max_speed = physics_manager.max_bounce_speed
	bounce_component.max_bounce_speed_override = base_max_speed * multiplier
	
	print("[SpeedBuff] Applied - max speed: %.1f -> %.1f (x%.2f)" % 
		[base_max_speed, bounce_component.max_bounce_speed_override, multiplier])


func remove_effect(entity: Node2D) -> void:
	var bounce_component = entity.get_node_or_null("BounceComponent")
	if bounce_component:
		bounce_component.max_bounce_speed_override = -1.0  # Reset to default
		print("[SpeedBuff] Removed - max speed restored to default")