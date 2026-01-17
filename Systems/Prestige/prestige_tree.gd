# Systems/Prestige/prestige_tree.gd
class_name PrestigeTree
extends RefCounted

var tree_id: String
var tree_name: String
var nodes: Dictionary = {}  # id -> PrestigeNode


static func load_from_file(filepath: String) -> PrestigeTree:
	if not FileAccess.file_exists(filepath):
		push_error("Prestige tree file not found: %s" % filepath)
		return null
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse prestige tree: %s" % filepath)
		return null
	
	var data = json.data
	
	var tree = PrestigeTree.new()
	tree.tree_id = data.get("tree_id", "")
	tree.tree_name = data.get("tree_name", "")
	
	for node_data in data.get("nodes", []):
		var node = PrestigeNode.from_dict(node_data)
		tree.nodes[node.id] = node
	
	print("[PrestigeTree] Loaded tree '%s' with %d nodes" % [tree.tree_name, tree.nodes.size()])
	
	return tree


func get_node(node_id: String) -> PrestigeNode:
	return nodes.get(node_id)


func get_all_nodes() -> Array[PrestigeNode]:
	var all_nodes: Array[PrestigeNode] = []
	for node in nodes.values():
		all_nodes.append(node)
	return all_nodes


func get_unlocked_node_ids() -> Array[String]:
	var unlocked: Array[String] = []
	for node_id in nodes:
		if nodes[node_id].is_unlocked:
			unlocked.append(node_id)
	return unlocked


func can_unlock_node(node_id: String, currency_amount: int) -> bool:
	var node = get_node(node_id)
	if not node or node.is_unlocked:
		return false
	
	return node.can_afford(currency_amount) and node.can_unlock(get_unlocked_node_ids())


func unlock_node(node_id: String, scene_tree: SceneTree) -> bool:
	var node = get_node(node_id)
	if not node:
		return false
	
	node.is_unlocked = true
	node.apply_effect(scene_tree)
	return true