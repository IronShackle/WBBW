# Systems/Buffs/base_buff.gd
class_name BaseBuff
extends RefCounted

## Base class for all buff types

var buff_id: String = "base_buff"
var display_name: String = "Base Buff"
var description: String = ""
var duration: float = 10.0
var max_duration: float = 10.0
var can_stack: bool = false
var stack_count: int = 1
var owner_entity: Node2D = null

# Store the config that created this buff
var config: BuffConfig


func initialize_from_config(buff_config: BuffConfig, base_duration: float) -> void:
	config = buff_config
	buff_id = buff_config.buff_id
	display_name = buff_config.display_name
	description = buff_config.description
	duration = base_duration
	max_duration = base_duration


func tick(delta: float) -> void:
	duration -= delta


func is_expired() -> bool:
	return duration <= 0.0


func refresh_duration() -> void:
	duration = max_duration


## Override in derived classes
func apply_effect(entity: Node2D) -> void:
	pass


## Override in derived classes
func remove_effect(entity: Node2D) -> void:
	pass