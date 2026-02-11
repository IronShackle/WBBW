# Autoloads/upgrade_manager.gd
extends Node

## Manages all upgrade trees and node unlocking

signal node_unlocked(tree_id: String, node_id: String)

var trees: Dictionary = {}  # tree_id -> PrestigeTree (keeping class name for now)

# Config modifiers applied by upgrades
var config_modifiers: Dictionary = {
	"max_basic_balls": 1.0,
	"max_explosive_balls": 1.0,
	"max_total_balls": 1.0,
	"pickup_lifetime": 1.0,
	"pickup_spawn_interval": 1.0,
	"max_active_pickups": 1.0,
	"speed_boost_duration": 1.0,
	"bounce_power_duration": 1.0,
	"size_boost_duration": 1.0,
}


func _ready() -> void:
	load_all_trees()


func load_all_trees() -> void:
	var tree_dir = "res://Data/prestige_trees/"
	var dir = DirAccess.open(tree_dir)
	
	if not dir:
		push_error("Failed to open upgrade trees directory: %s" % tree_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var upgrade_tree = PrestigeTree.load_from_file(tree_dir + file_name)
			if upgrade_tree:
				trees[upgrade_tree.tree_id] = upgrade_tree
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


func get_upgrade_tree(tree_id: String) -> PrestigeTree:
	return trees.get(tree_id)


func get_all_tree_ids() -> Array:
	return trees.keys()


func try_unlock_node(tree_id: String, node_id: String) -> bool:
	var upgrade_tree = get_upgrade_tree(tree_id)
	if not upgrade_tree:
		push_warning("Tree not found: %s" % tree_id)
		return false
	
	var node = upgrade_tree.get_node(node_id)
	if not node:
		push_warning("Node not found: %s in tree %s" % [node_id, tree_id])
		return false
	
	# Check if node can be unlocked (prerequisites met)
	if not upgrade_tree.can_unlock_node(node_id, 0):  # Pass 0 since we're not using currency param
		return false
	
	# Check if player can afford the node based on its cost structure
	# Node effect should define which currency it costs
	var cost_currency = node.effect.get("cost_currency", "currency")  # default to main currency
	var cost_amount = node.cost
	
	var can_afford = false
	match cost_currency:
		"currency":
			can_afford = GameManager.currency >= cost_amount
		"essence":
			can_afford = GameManager.essence >= cost_amount
		"corruption_points":
			can_afford = GameManager.corruption_points >= cost_amount
	
	if not can_afford:
		return false
	
	# Deduct the cost
	match cost_currency:
		"currency":
			GameManager.spend_currency(cost_amount)
		"essence":
			GameManager.spend_essence(cost_amount)
		"corruption_points":
			GameManager.spend_corruption_points(cost_amount)
	
	# Unlock the node
	upgrade_tree.unlock_node(node_id, get_tree())
	node_unlocked.emit(tree_id, node_id)
	
	return true


## Get config modifier value (1.0 = no modifier)
func get_config_modifier(config_key: String) -> float:
	return config_modifiers.get(config_key, 1.0)


## Set config modifier (called by upgrade node effects)
func set_config_modifier(config_key: String, value: float) -> void:
	config_modifiers[config_key] = value


## Multiply existing config modifier (for stacking upgrades)
func multiply_config_modifier(config_key: String, multiplier: float) -> void:
	var current = config_modifiers.get(config_key, 1.0)
	config_modifiers[config_key] = current * multiplier