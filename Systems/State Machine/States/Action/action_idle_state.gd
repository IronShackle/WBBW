# Systems/state_machine/States/Action/action_idle_state.gd
class_name ActionIdleState
extends State

## Action state for waiting to attack

var player: CharacterBody2D


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func get_transition(context: Dictionary) -> String:
	# Check for charge attack input
	if context.get("charge_attack_pressed", false):
		return "Charging"
	
	return ""