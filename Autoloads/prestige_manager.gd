# Autoloads/prestige_manager.gd
extends Node

## Manages all prestige trees and prestige currency

signal prestige_points_changed(new_amount: int)
signal node_unlocked(tree_id: String, node_id: String)

var trees: Dictionary = {}  # tree_id -> PrestigeTree
var prestige_points: int = 0


func _ready() -> void:
	load_all_trees()


func load_all_trees() -> void:
	var tree_dir = "res://Data/prestige_trees/"
	var dir = DirAccess.open(tree_dir)
	
	if not dir:
		push_error("Failed to open prestige trees directory: %s" % tree_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var prestige_tree = PrestigeTree.load_from_file(tree_dir + file_name)
			if prestige_tree:
				trees[prestige_tree.tree_id] = prestige_tree
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("[PrestigeManager] Loaded %d prestige trees" % trees.size())


func get_prestige_tree(tree_id: String) -> PrestigeTree:
	return trees.get(tree_id)


func get_all_tree_ids() -> Array:
	return trees.keys()


func try_unlock_node(tree_id: String, node_id: String) -> bool:
	var prestige_tree = get_prestige_tree(tree_id)
	if not prestige_tree:
		push_warning("Tree not found: %s" % tree_id)
		return false
	
	var node = prestige_tree.get_node(node_id)
	if not node:
		push_warning("Node not found: %s in tree %s" % [node_id, tree_id])
		return false
	
	if not prestige_tree.can_unlock_node(node_id, prestige_points):
		print("[PrestigeManager] Cannot unlock %s (Points: %d, Cost: %d)" % 
			[node.display_name, prestige_points, node.cost])
		return false
	
	prestige_points -= node.cost
	prestige_tree.unlock_node(node_id, get_tree())  # get_tree() here is Node's method
	
	prestige_points_changed.emit(prestige_points)
	node_unlocked.emit(tree_id, node_id)
	
	print("[PrestigeManager] Unlocked '%s' (%d points remaining)" % [node.display_name, prestige_points])
	return true


func add_prestige_points(amount: int) -> void:
	prestige_points += amount
	prestige_points_changed.emit(prestige_points)
	print("[PrestigeManager] Added %d prestige points (total: %d)" % [amount, prestige_points])


func set_prestige_points(amount: int) -> void:
	prestige_points = amount
	prestige_points_changed.emit(prestige_points)
