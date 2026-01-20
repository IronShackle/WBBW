# Entities/Pickup/buff_pickup.gd
class_name BuffPickup
extends BasePickup

## Pickup that grants a buff when collected

var buff_config: BuffConfig  # Set by spawn manager when instantiated


func _apply_effect(collector: Node2D) -> void:
	if not buff_config:
		push_warning("[BuffPickup] No buff_config set!")
		return
	
	var buff_component = collector.get_node_or_null("BuffComponent")
	if not buff_component:
		push_warning("[BuffPickup] Collector has no BuffComponent!")
		return
	
	# Create buff from config
	var buff = _create_buff_from_config(buff_config, buff_component)
	if buff:
		buff_component.add_buff(buff)
		print("[BuffPickup] Granted %s to %s" % [buff.display_name, collector.name])


func _create_buff_from_config(config: BuffConfig, buff_component: BuffComponent) -> BaseBuff:
	if config.buff_script_path.is_empty():
		push_warning("[BuffPickup] No buff_script_path set in config")
		return null
	
	# Load the script
	var buff_script = load(config.buff_script_path)
	if not buff_script:
		push_warning("[BuffPickup] Failed to load buff script: %s" % config.buff_script_path)
		return null
	
	# Instantiate the buff
	var buff = buff_script.new()
	if not buff is BaseBuff:
		push_warning("[BuffPickup] Script is not a BaseBuff: %s" % config.buff_script_path)
		return null
	
	# Get duration from GameConfigManager
	var duration = buff_component.get_buff_duration(config.buff_id)
	
	# Initialize buff with config and duration
	buff.initialize_from_config(config, duration)
	
	return buff