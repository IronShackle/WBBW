# Systems/Player/player_controller.gd
extends CharacterBody2D

## Player controller with dual state machine architecture

@onready var movement_component: MovementComponent = $MovementComponent
@onready var movement_machine: StateMachine = $MovementMachine
@onready var action_machine: StateMachine = $ActionMachine
@onready var charged_attack: ChargedAttack = $ChargedAttack


func _ready() -> void:
	_setup_movement_machine()
	_setup_action_machine()


func _physics_process(delta: float) -> void:
	var movement_context = get_movement_context(delta)
	var action_context = get_action_context(delta)
	
	movement_machine.update(delta, movement_context)
	action_machine.update(delta, action_context)


func get_movement_context(_delta: float) -> Dictionary:
	return {
		"input_direction": Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"),
		"dash_pressed": Input.is_action_just_pressed("dash")
	}


func get_action_context(_delta: float) -> Dictionary:
	return {
		"charge_attack_pressed": Input.is_action_pressed("attack"),
		"charge_attack_released": Input.is_action_just_released("attack"),
		"dash_pressed": Input.is_action_just_pressed("dash")
	}


func _setup_movement_machine() -> void:
	var idle_state = IdleState.new(movement_machine, self)
	var run_state = RunState.new(movement_machine, self)
	var dash_state = DashState.new(movement_machine, self)
	
	movement_machine.add_state("Idle", idle_state)
	movement_machine.add_state("Run", run_state)
	movement_machine.add_state("Dash", dash_state)
	
	movement_machine.set_initial_state("Idle")
	movement_machine.start()


func _setup_action_machine() -> void:
	var action_idle = ActionIdleState.new(action_machine, self)
	var charging_state = ChargingState.new(action_machine, self)
	var attacking_state = AttackingState.new(action_machine, self)
	
	action_machine.add_state("ActionIdle", action_idle)
	action_machine.add_state("Charging", charging_state)
	action_machine.add_state("Attacking", attacking_state)
	
	action_machine.set_initial_state("ActionIdle")
	action_machine.start()


func get_movement_component() -> MovementComponent:
	return movement_component
