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
	var buff_component = entity.get_node_or_null("BuffComponent")
	if not buff_component:
		return
	
	# Read bounce_multiplier from config parameters (default 1.5 for 50% more bouncy)
	var multiplier = config.parameters.get("bounce_multiplier", 1.5) if config else 1.5
	
	# Add multiplicative modifier to ball_bounce_restitution
	buff_component.add_stat_modifier("ball_bounce_restitution", 0.0, multiplier)
	
	print("[BouncePowerBuff] Applied - ball_bounce_restitution multiplier: x%.2f" % multiplier)


func remove_effect(entity: Node2D) -> void:
	var buff_component = entity.get_node_or_null("BuffComponent")
	if not buff_component:
		return
	
	var multiplier = config.parameters.get("bounce_multiplier", 1.5) if config else 1.5
	buff_component.remove_stat_modifier("ball_bounce_restitution", 0.0, multiplier)
	
	print("[BouncePowerBuff] Removed - ball_bounce_restitution modifier cleared")