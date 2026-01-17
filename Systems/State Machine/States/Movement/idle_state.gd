# Systems/state_machine/States/Movement/idle_state.gd
class_name IdleState
extends State

## Movement state for standing still

var player: CharacterBody2D


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func update(_delta: float, _context: Dictionary) -> void:
	var movement = player.get_node("MovementComponent") as MovementComponent
	if movement:
		movement.apply_friction(_delta)


func get_transition(context: Dictionary) -> String:
	var input_dir = context.get("input_direction", Vector2.ZERO)
	
	if context.get("dash_pressed", false):
		return "Dash"
	
	if input_dir.length() > 0.1:
		return "Run"
	
	return ""