# Systems/Round/round_manager.gd
class_name RoundManager
extends Node

## Manages round timing, stats tracking, and round flow

signal round_started()
signal round_ended(stats: Dictionary)
signal time_remaining_changed(seconds: float)

@export var base_round_duration: float = 30.0

var round_active: bool = false
var current_round: int = 0
var time_remaining: float = 0.0

var round_stats: Dictionary = {
	"total_bounces": 0,
	"barriers_broken": 0,
	"currency_earned": 0
}

var barrier_manager: BarrierManager


func _ready() -> void:
	add_to_group("round_manager")
	
	# Find BarrierManager
	barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager:
		barrier_manager.barrier_broken.connect(_on_barrier_broken)


func _process(delta: float) -> void:
	if not round_active:
		return
	
	time_remaining -= delta
	time_remaining_changed.emit(time_remaining)
	
	if time_remaining <= 0.0:
		end_round()


func start_round() -> void:
	current_round += 1
	round_active = true
	time_remaining = base_round_duration
	
	# Reset stats
	round_stats = {
		"total_bounces": 0,
		"barriers_broken": 0,
		"currency_earned": 0
	}
	
	# Reset barriers
	if barrier_manager:
		barrier_manager.reset_barriers()
	
	# Connect to all active balls
	_connect_to_active_balls()
	
	round_started.emit()
	print("[RoundManager] Round %d started (Duration: %.1fs)" % [current_round, base_round_duration])


func end_round() -> void:
	round_active = false
	
	# Award currency based on bounces
	round_stats["currency_earned"] = round_stats["total_bounces"]
	GameManager.bounce_currency += round_stats["currency_earned"]
	GameManager.bounce_currency_changed.emit(GameManager.bounce_currency)
	
	round_ended.emit(round_stats)
	print("[RoundManager] Round %d ended - Bounces: %d, Barriers: %d, Currency: %d" % 
		[current_round, round_stats["total_bounces"], round_stats["barriers_broken"], round_stats["currency_earned"]])


func add_time(seconds: float) -> void:
	time_remaining += seconds
	time_remaining_changed.emit(time_remaining)


func _connect_to_active_balls() -> void:
	var balls = get_tree().get_nodes_in_group("ball")
	for ball in balls:
		var bounce_component = ball.get_node_or_null("BounceComponent")
		if bounce_component and not bounce_component.bounced.is_connected(_on_ball_bounced):
			bounce_component.bounced.connect(_on_ball_bounced)


func _on_ball_bounced(collision: KinematicCollision2D) -> void:
	round_stats["total_bounces"] += 1


func _on_barrier_broken(tier: int) -> void:
	round_stats["barriers_broken"] += 1