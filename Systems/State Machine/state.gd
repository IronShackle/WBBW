# Systems/state_machine/state.gd
class_name State
extends RefCounted

## Base class for all state machine states

var state_machine: StateMachine


func _init(p_state_machine: StateMachine) -> void:
	state_machine = p_state_machine


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float, _context: Dictionary) -> void:
	pass


func get_transition(_context: Dictionary) -> String:
	return ""