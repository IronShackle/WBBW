# Systems/Round/round_manager.gd
class_name RoundManager
extends Node

## Manages round timing, ball auto-spawning, and round flow

signal round_started()
signal round_ended(stats: Dictionary)
signal time_remaining_changed(seconds: float)

@export var base_round_duration: float = 30.0
@export var ball_spawn_interval: float = 2.0
@export var basic_ball_config: BallConfig

var round_active: bool = false
var current_round: int = 0
var time_remaining: float = 0.0
var spawn_timer: float = 0.0

# Track currency at round start for results
var currency_at_start: int = 0
var essence_at_start: int = 0

var spawn_manager: SpawnManager
var barrier_manager: BarrierManager


func _ready() -> void:
	add_to_group("round_manager")
	
	# Find managers
	await get_tree().process_frame
	spawn_manager = get_tree().get_first_node_in_group("spawn_manager")
	barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	
	if barrier_manager:
		barrier_manager.round_complete.connect(_on_round_complete)

	if not spawn_manager:
		push_warning("[RoundManager] No SpawnManager found")
	if not barrier_manager:
		push_warning("[RoundManager] No BarrierManager found")
	
	# Auto-start first round
	await get_tree().process_frame
	start_round()


func _process(delta: float) -> void:
	if not round_active:
		return
	
	# Auto-spawn balls
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_ball()
		spawn_timer = ball_spawn_interval


func start_round() -> void:
	if not spawn_manager or not barrier_manager:
		push_error("[RoundManager] Cannot start round - missing managers")
		return
	
	# Unpause if paused
	get_tree().paused = false
	
	current_round += 1
	round_active = true
	time_remaining = base_round_duration
	spawn_timer = ball_spawn_interval
	
	# Track starting currency for results
	currency_at_start = GameManager.currency
	essence_at_start = GameManager.essence
	
	# Clear all active balls
	_clear_all_balls()
	
	# Clear all active pickups
	spawn_manager.clear_all_pickups()

	# Reset player position
	_reset_player()
	
	# Reset barriers
	barrier_manager.reset_barriers()
	
	round_started.emit()


func _on_round_complete() -> void:
	end_round()

func end_round() -> void:
	round_active = false
	
	# Pause the game
	get_tree().paused = true
	
	# Calculate earnings
	var currency_earned = GameManager.currency - currency_at_start
	var essence_earned = GameManager.essence - essence_at_start
	
	var stats = {
		"currency_earned": currency_earned,
		"essence_earned": essence_earned,
		"total_currency": GameManager.currency,
		"total_essence": GameManager.essence,
	}
	
	round_ended.emit(stats)


func _spawn_ball() -> void:
	if not spawn_manager or not basic_ball_config:
		return
	
	spawn_manager.spawn_ball(basic_ball_config)


func _clear_all_balls() -> void:
	if not spawn_manager:
		return
	
	# Clear all active balls from spawn manager
	for ball in spawn_manager.active_balls.duplicate():
		if is_instance_valid(ball):
			ball.queue_free()
	
	spawn_manager.active_balls.clear()


func _reset_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2.ZERO
		# Also reset velocity if player has bounce component
		var bounce_component = player.get_node_or_null("BounceComponent")
		if bounce_component:
			bounce_component.knockback_velocity = Vector2.ZERO
