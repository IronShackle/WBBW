# Systems/Corruption/corruption_controller.gd
class_name CorruptionController
extends Node

## Controls when corruption is available and handles corruption logic

signal corruption_available()
signal ball_corrupted(ball: BaseBall)
signal corruption_consumed()

@export var base_corruption_chance: float = 0.05
@export var chance_increase_per_collision: float = 0.02

var corruption_active: bool = false
var current_corruption_chance: float = 0.0


func _ready() -> void:
	add_to_group("corruption_controller")
	
	# Listen for barrier breaks to trigger corruption
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager:
		barrier_manager.barrier_broken.connect(_on_barrier_broken)


func trigger_corruption() -> void:
	corruption_active = true
	current_corruption_chance = base_corruption_chance
	corruption_available.emit()


func try_corrupt_ball(ball: Node2D) -> bool:
	if not corruption_active:
		return false
	
	# Check if ball has corruption component
	var corruption_comp = ball.get_node_or_null("CorruptionComponent")
	if not corruption_comp:
		return false
	
	# Roll for corruption
	if randf() < current_corruption_chance:
		# Corruption succeeded
		corruption_comp.corrupt()
		corruption_comp.corruption_broken.connect(_on_corruption_broken)
		
		corruption_active = false
		ball_corrupted.emit(ball)
		
		return true
	else:
		# Failed - increase chance for next collision
		current_corruption_chance += chance_increase_per_collision
		current_corruption_chance = min(current_corruption_chance, 1.0)
		
		return false


func _on_barrier_broken(tier: int) -> void:
	# For now, trigger on any barrier break
	# Later you can add tier requirements
	trigger_corruption()


func _on_corruption_broken(ball: Node2D) -> void:
	print("[CorruptionController] Corruption broken!")
	corruption_consumed.emit()