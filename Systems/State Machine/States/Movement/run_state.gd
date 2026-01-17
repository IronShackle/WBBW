# Systems/state_machine/States/Movement/run_state.gd
class_name RunState
extends State

## Movement state for active movement

var player: CharacterBody2D


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func update(delta: float, context: Dictionary) -> void:
	var input_dir = context.get("input_direction", Vector2.ZERO)
	var movement = player.get_node("MovementComponent") as MovementComponent
	
	if not movement:
		return
	
	if input_dir.length() > 0.1:
		movement.move_in_direction(input_dir, delta)
	else:
		movement.apply_friction(delta)


func get_transition(context: Dictionary) -> String:
	var input_dir = context.get("input_direction", Vector2.ZERO)
	
	if context.get("dash_pressed", false):
		return "Dash"
	
	if input_dir.length() < 0.1:
		return "Idle"
	
	return ""