# Systems/state_machine/States/Action/attacking_state.gd
class_name AttackingState
extends State

## Action state for active attack swing

var player: CharacterBody2D
var charged_attack: ChargedAttack
var attack_complete: bool = false


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func enter() -> void:
	attack_complete = false
	charged_attack = player.get_node_or_null("ChargedAttack")
	
	if charged_attack:
		# Lock movement during swing
		var movement = player.get_node("MovementComponent") as MovementComponent
		if movement:
			movement.set_movement_modifier(0.0)
		
		# Connect to attack completion
		if not charged_attack.attack_completed.is_connected(_on_attack_completed):
			charged_attack.attack_completed.connect(_on_attack_completed)


func exit() -> void:
	# Restore movement
	var movement = player.get_node("MovementComponent") as MovementComponent
	if movement:
		movement.reset_movement_modifier()
	
	# Disconnect signal
	if charged_attack and charged_attack.attack_completed.is_connected(_on_attack_completed):
		charged_attack.attack_completed.disconnect(_on_attack_completed)


func get_transition(_context: Dictionary) -> String:
	if attack_complete:
		return "ActionIdle"
	
	return ""


func _on_attack_completed() -> void:
	attack_complete = true