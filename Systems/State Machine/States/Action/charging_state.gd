# Systems/state_machine/States/Action/charging_state.gd
class_name ChargingState
extends State

## Action state for charging attack

var player: CharacterBody2D
var charged_attack: ChargedAttack


func _init(p_state_machine, p_player: CharacterBody2D) -> void:
	super(p_state_machine)
	player = p_player


func enter() -> void:
	charged_attack = player.get_node_or_null("ChargedAttack")
	if not charged_attack:
		push_error("ChargingState: Player missing ChargedAttack component!")
		return
	
	charged_attack.start_charge()
	
	# Slow down movement while charging
	var movement = player.get_node("MovementComponent") as MovementComponent
	if movement:
		movement.set_movement_modifier(charged_attack.movement_speed_while_charging)


func update(delta: float, _context: Dictionary) -> void:
	if charged_attack:
		charged_attack.update(delta)


func exit() -> void:
	# Reset movement speed
	var movement = player.get_node("MovementComponent") as MovementComponent
	if movement:
		movement.reset_movement_modifier()


func get_transition(context: Dictionary) -> String:
	# Release attack when button released
	if context.get("charge_attack_released", false):
		if charged_attack:
			charged_attack.release_attack()
		return "Attacking"
	
	# Allow dash to cancel charging
	if context.get("dash_pressed", false):
		return "ActionIdle"
	
	return ""
