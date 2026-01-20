# Systems/Config/game_config_manager.gd
class_name GameConfigManager
extends Node

## Central configuration for all gameplay systems with prestige modifier support

# Ball spawning limits
@export_group("Ball Limits")
@export var base_max_basic_balls: int = 20
@export var base_max_explosive_balls: int = 10
@export var base_max_total_balls: int = 30
@export var special_ball_max_increase: int = 5

# Pickup settings
@export_group("Pickups")
@export var base_pickup_lifetime: float = 30.0
@export var base_pickup_check_interval: float = 5.0  
@export var base_pickup_spawn_chance: float = 0.3 # Chance to spawn a pickup each interval
@export var base_max_active_pickups: int = 10

# Buff durations
@export_group("Buff Durations")
@export var base_speed_boost_duration: float = 15.0
@export var base_bounce_power_duration: float = 10.0
@export var base_size_boost_duration: float = 12.0

# Computed properties with prestige modifiers applied
var max_basic_balls: int:
	get:
		return int(base_max_basic_balls * PrestigeManager.get_config_modifier("max_basic_balls"))

var max_explosive_balls: int:
	get:
		return int(base_max_explosive_balls * PrestigeManager.get_config_modifier("max_explosive_balls"))

var max_total_balls: int:
	get:
		return int(base_max_total_balls * PrestigeManager.get_config_modifier("max_total_balls"))

var pickup_lifetime: float:
	get:
		return base_pickup_lifetime * PrestigeManager.get_config_modifier("pickup_lifetime")

var pickup_check_interval: float:
	get:
		return base_pickup_check_interval * PrestigeManager.get_config_modifier("pickup_check_interval")

var pickup_spawn_chance: float:
	get:
		return base_pickup_spawn_chance * PrestigeManager.get_config_modifier("pickup_spawn_chance")

var max_active_pickups: int:
	get:
		return int(base_max_active_pickups * PrestigeManager.get_config_modifier("max_active_pickups"))

var speed_boost_duration: float:
	get:
		return base_speed_boost_duration * PrestigeManager.get_config_modifier("speed_boost_duration")

var bounce_power_duration: float:
	get:
		return base_bounce_power_duration * PrestigeManager.get_config_modifier("bounce_power_duration")

var size_boost_duration: float:
	get:
		return base_size_boost_duration * PrestigeManager.get_config_modifier("size_boost_duration")


func _ready() -> void:
	add_to_group("game_config_manager")
	print("[GameConfigManager] Initialized with prestige modifiers applied")