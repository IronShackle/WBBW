# Systems/Buffs/bounce_power_buff.gd
class_name BouncePowerBuff
extends BaseBuff

## Increases ball bounce restitution for more energetic collisions


func _init() -> void:
	buff_id = "bounce_power"
	display_name = "Bounce Power"
	description = "Increases bounce energy"
	can_stack = false


func apply_effect(entity: Node2D) -> void:
	var bounce_component = entity.get_node_or_null("BounceComponent")
	if not bounce_component:
		return
	
	var physics_manager = bounce_component.physics_manager
	if not physics_manager:
		return
	
	# Read bounce_multiplier from config parameters (default 1.5 for 50% more bouncy)
	var multiplier = config.parameters.get("bounce_multiplier", 1.5) if config else 1.5
	
	# Apply restitution increase
	var base_restitution = physics_manager.ball_bounce_restitution
	bounce_component.ball_bounce_restitution_override = base_restitution * multiplier
	
	print("[BouncePowerBuff] Applied - restitution: %.2f -> %.2f (x%.2f)" % 
		[base_restitution, bounce_component.ball_bounce_restitution_override, multiplier])


func remove_effect(entity: Node2D) -> void:
	var bounce_component = entity.get_node_or_null("BounceComponent")
	if bounce_component:
		bounce_component.ball_bounce_restitution_override = -1.0  # Reset to default
		print("[BouncePowerBuff] Removed - restitution restored to default")