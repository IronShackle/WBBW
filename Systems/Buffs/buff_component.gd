# Systems/Buffs/buff_component.gd
class_name BuffComponent
extends Node

## Manages active buffs on an entity and applies stat modifiers

signal buff_added(buff: BaseBuff)
signal buff_removed(buff: BaseBuff)
signal buff_refreshed(buff: BaseBuff)

var active_buffs: Array[BaseBuff] = []
var entity: Node2D
var config_manager: GameConfigManager

# Temporary stat modifiers from active buffs
var active_modifiers: Dictionary = {
	"max_velocity": {"add": 0.0, "multiply": 1.0},
	"friction_deceleration": {"add": 0.0, "multiply": 1.0},
	"wall_bounce_damping": {"add": 0.0, "multiply": 1.0},
	"ball_bounce_restitution": {"add": 0.0, "multiply": 1.0},
	"durability": {"add": 0.0, "multiply": 1.0},
}


func _ready() -> void:
	entity = get_parent()
	add_to_group("buff_component")
	
	await get_tree().process_frame
	config_manager = get_tree().get_first_node_in_group("game_config_manager")
	if not config_manager:
		push_warning("[BuffComponent] No GameConfigManager found in scene")


func _process(delta: float) -> void:
	for buff in active_buffs.duplicate():
		buff.tick(delta)
		
		if buff.is_expired():
			remove_buff(buff)


func add_buff(buff: BaseBuff) -> void:
	var existing = get_buff_by_id(buff.buff_id)
	
	if existing:
		if buff.can_stack:
			existing.stack_count += 1
			existing.refresh_duration()
			buff_refreshed.emit(existing)
		else:
			existing.refresh_duration()
			buff_refreshed.emit(existing)
		return
	
	buff.owner_entity = entity
	active_buffs.append(buff)
	buff.apply_effect(entity)
	buff_added.emit(buff)


func remove_buff(buff: BaseBuff) -> void:
	if buff not in active_buffs:
		return
	
	buff.remove_effect(entity)
	active_buffs.erase(buff)
	buff_removed.emit(buff)


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


func get_buff_duration(buff_id: String) -> float:
	if not config_manager:
		return 10.0
	
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


func apply_stat_modifiers(base_value: float, stat_name: String) -> float:
	var modifiers = active_modifiers.get(stat_name, {"add": 0.0, "multiply": 1.0})
	return (base_value + modifiers["add"]) * modifiers["multiply"]


func add_stat_modifier(stat_name: String, flat_add: float = 0.0, multiply: float = 1.0) -> void:
	if not active_modifiers.has(stat_name):
		active_modifiers[stat_name] = {"add": 0.0, "multiply": 1.0}
	
	active_modifiers[stat_name]["add"] += flat_add
	active_modifiers[stat_name]["multiply"] *= multiply


func remove_stat_modifier(stat_name: String, flat_add: float = 0.0, multiply: float = 1.0) -> void:
	if not active_modifiers.has(stat_name):
		return
	
	active_modifiers[stat_name]["add"] -= flat_add
	if multiply != 1.0:
		active_modifiers[stat_name]["multiply"] /= multiply


func clear_all_modifiers() -> void:
	for stat in active_modifiers.keys():
		active_modifiers[stat] = {"add": 0.0, "multiply": 1.0}