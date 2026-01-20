# Systems/Buffs/buff_component.gd
class_name BuffComponent
extends Node

## Manages active buffs on an entity

signal buff_added(buff: BaseBuff)
signal buff_removed(buff: BaseBuff)
signal buff_refreshed(buff: BaseBuff)

var active_buffs: Array[BaseBuff] = []
var entity: Node2D
var config_manager: GameConfigManager


func _ready() -> void:
	entity = get_parent()
	add_to_group("buff_component")
	
	# Find GameConfigManager
	await get_tree().process_frame
	config_manager = get_tree().get_first_node_in_group("game_config_manager")
	if not config_manager:
		push_warning("[BuffComponent] No GameConfigManager found in scene")


func _process(delta: float) -> void:
	# Update all active buffs
	for buff in active_buffs.duplicate():  # Duplicate to avoid modification during iteration
		buff.tick(delta)
		
		if buff.is_expired():
			remove_buff(buff)


func add_buff(buff: BaseBuff) -> void:
	# Check if buff type already exists
	var existing = get_buff_by_id(buff.buff_id)
	
	if existing:
		if buff.can_stack:
			existing.stack_count += 1
			existing.refresh_duration()
			buff_refreshed.emit(existing)
			print("[BuffComponent] Stacked %s (x%d)" % [buff.display_name, existing.stack_count])
		else:
			existing.refresh_duration()
			buff_refreshed.emit(existing)
			print("[BuffComponent] Refreshed %s" % buff.display_name)
		return
	
	# Add new buff
	buff.owner_entity = entity
	active_buffs.append(buff)
	buff.apply_effect(entity)
	buff_added.emit(buff)
	
	print("[BuffComponent] Added %s (duration: %.1fs)" % [buff.display_name, buff.duration])


func remove_buff(buff: BaseBuff) -> void:
	if buff not in active_buffs:
		return
	
	buff.remove_effect(entity)
	active_buffs.erase(buff)
	buff_removed.emit(buff)
	
	print("[BuffComponent] Removed %s" % buff.display_name)


func get_buff_by_id(buff_id: String) -> BaseBuff:
	for buff in active_buffs:
		if buff.buff_id == buff_id:
			return buff
	return null


func has_buff(buff_id: String) -> bool:
	return get_buff_by_id(buff_id) != null


func clear_all_buffs() -> void:
	for buff in active_buffs.duplicate():
		remove_buff(buff)


## Get buff duration from GameConfigManager
func get_buff_duration(buff_id: String) -> float:
	if not config_manager:
		return 10.0  # Fallback
	
	match buff_id:
		"speed_boost":
			return config_manager.speed_boost_duration
		"bounce_power":
			return config_manager.bounce_power_duration
		"size_boost":
			return config_manager.size_boost_duration
		_:
			push_warning("[BuffComponent] Unknown buff ID for duration lookup: %s" % buff_id)
			return 10.0