# Systems/Prestige/prestige_node.gd
class_name PrestigeNode
extends RefCounted

var id: String
var display_name: String
var description: String
var cost: int
var position: Vector2
var requires: Array[String]
var effect: Dictionary
var is_unlocked: bool = false


static func from_dict(data: Dictionary) -> PrestigeNode:
	var node = PrestigeNode.new()
	node.id = data.get("id", "")
	node.display_name = data.get("name", "")
	node.description = data.get("description", "")
	node.cost = data.get("cost", 0)
	
	var pos = data.get("position", {"x": 0, "y": 0})
	node.position = Vector2(pos.get("x", 0), pos.get("y", 0))
	
	# Manually convert untyped array to typed Array[String]
	var requires_data = data.get("requires", [])
	for req in requires_data:
		if req is String:
			node.requires.append(req)
	
	node.effect = data.get("effect", {})
	
	return node


func can_afford(currency_amount: int) -> bool:
	return currency_amount >= cost


func can_unlock(unlocked_nodes: Array[String]) -> bool:
	for req_id in requires:
		if req_id not in unlocked_nodes:
			return false
	return true


func apply_effect(scene_tree: SceneTree) -> void:
	match effect.get("type"):
		"modify_physics":
			_apply_physics_modification(scene_tree)
		"unlock_feature":
			_unlock_feature()
		_:
			push_warning("Unknown effect type: %s" % effect.get("type"))


func _apply_physics_modification(scene_tree: SceneTree) -> void:
	var physics_manager = scene_tree.get_first_node_in_group("physics_manager")
	if not physics_manager:
		push_warning("No PhysicsManager found")
		return
	
	var target = effect.get("target")
	var operation = effect.get("operation")
	var value = effect.get("value")
	
	var current_value = physics_manager.get(target)
	
	match operation:
		"multiply":
			physics_manager.set(target, current_value * value)
		"add":
			physics_manager.set(target, current_value + value)
		"set":
			physics_manager.set(target, value)
	
	print("[PrestigeNode] Applied %s: %s %s %s = %s" % 
		[display_name, target, operation, value, physics_manager.get(target)])


func _unlock_feature() -> void:
	# Stub for future feature unlocks
	pass
