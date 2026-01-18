# Systems/state_machine/state_machine.gd
extends Node
class_name StateMachine

## Generic state machine for managing entity behavior states

signal state_changed(old_state: String, new_state: String)

var states: Dictionary = {}
var current_state: State = null
var current_state_name: String = ""
var transition_rules: Dictionary = {}


func add_state(state_name: String, state: State) -> void:
	states[state_name] = state


func set_transition_rule(from_state: String, to_state: String, allowed: bool = true) -> void:
	if not transition_rules.has(from_state):
		transition_rules[from_state] = {}
	transition_rules[from_state][to_state] = allowed


func can_transition(from_state: String, to_state: String) -> bool:
	if not transition_rules.has(from_state):
		return true
	
	if transition_rules[from_state].has(to_state):
		return transition_rules[from_state][to_state]
	
	return true


func set_initial_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("State '%s' not found" % state_name)
		return
	
	current_state = states[state_name]
	current_state_name = state_name


func start() -> void:
	if current_state:
		current_state.enter()


func update(delta: float, context: Dictionary = {}) -> void:
	if current_state == null:
		return
	
	current_state.update(delta, context)
	
	var next_state_name = current_state.get_transition(context)
	if next_state_name != "" and next_state_name != current_state_name:
		transition_to(next_state_name)


func transition_to(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_error("Cannot transition to unknown state '%s'" % new_state_name)
		return
	
	if not can_transition(current_state_name, new_state_name):
		return
	
	var old_state_name = current_state_name
	if current_state:
		current_state.exit()
	
	current_state_name = new_state_name
	current_state = states[new_state_name]
	current_state.enter()
	
	state_changed.emit(old_state_name, new_state_name)
