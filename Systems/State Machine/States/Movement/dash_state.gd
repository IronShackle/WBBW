# Systems/state_machine/States/Movement/dash_state.gd
class_name DashState
extends State

## Movement state for quick dash

var player: CharacterBody2D
var dash_timer: float = 0.0
var dash_duration: float = 0.15  # Short duration for dash immunity/speed


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func enter() -> void:
	dash_timer = 0.0
	
	var movement = player.get_node("MovementComponent") as MovementComponent
	if not movement:
		return
	
	var input_dir = Vector2.ZERO
	if player.has_method("get_movement_context"):
		var context = player.get_movement_context(0.0)
		input_dir = context.get("input_direction", Vector2.ZERO)
	
	movement.start_dash(input_dir)


func update(delta: float, _context: Dictionary) -> void:
	dash_timer += delta


func get_transition(_context: Dictionary) -> String:
	if dash_timer >= dash_duration:
		return "Idle"
	
	return ""