# Systems/Buffs/speed_buff.gd
class_name SpeedBuff
extends BaseBuff

## Increases max velocity


func _init() -> void:
	buff_id = "speed_boost"
	display_name = "Speed Boost"
	description = "Increases max speed"
	can_stack = false


func apply_effect(entity: Node2D) -> void:
	var buff_component = entity.get_node_or_null("BuffComponent")
	if not buff_component:
		return
	
	# Read speed_multiplier from config parameters (default 1.5 for 50% faster)
	var multiplier = config.parameters.get("speed_multiplier", 1.5) if config else 1.5
	
	# Add multiplicative modifier to max_velocity
	buff_component.add_stat_modifier("max_velocity", 0.0, multiplier)
	
	print("[SpeedBuff] Applied - max_velocity multiplier: x%.2f" % multiplier)


func remove_effect(entity: Node2D) -> void:
	var buff_component = entity.get_node_or_null("BuffComponent")
	if not buff_component:
		return
	
	var multiplier = config.parameters.get("speed_multiplier", 1.5) if config else 1.5
	buff_component.remove_stat_modifier("max_velocity", 0.0, multiplier)
	
	print("[SpeedBuff] Removed - max_velocity modifier cleared")