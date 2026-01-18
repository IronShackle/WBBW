# Controllers/player_controller.gd
class_name PlayerController
extends Node

var mob: Node2D
var movement_state_machine: StateMachine
var action_state_machine: StateMachine
var charged_attack: ChargedAttack
var bounce_component: BounceComponent


func _ready() -> void:
	mob = get_parent()
	movement_state_machine = mob.get_node("MovementStateMachine")
	action_state_machine = mob.get_node("ActionStateMachine")
	charged_attack = mob.get_node("ChargedAttack")
	bounce_component = mob.get_node("BounceComponent")
	
	# Set up movement state machine
	movement_state_machine.mob = mob
	movement_state_machine.initialize()
	
	# Set up action state machine
	action_state_machine.mob = mob
	action_state_machine.initialize()


func _physics_process(delta: float) -> void:
	movement_state_machine.update(delta)
	action_state_machine.update(delta)
	_handle_input()


func _handle_input() -> void:
	if Input.is_action_just_pressed("attack"):
		action_state_machine.transition_to("Charging")
	
	if Input.is_action_just_released("attack"):
		if action_state_machine.current_state.name == "Charging":
			var success = charged_attack.release_charge()
			if success:
				var launch_vel = charged_attack.get_launch_velocity()
				bounce_component.velocity = launch_vel
			action_state_machine.transition_to("Idle")
