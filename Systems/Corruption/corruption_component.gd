# Systems/Corruption/corruption_component.gd
class_name CorruptionComponent
extends Node

## Component for balls that can be corrupted

signal corruption_broken(ball: BaseBall)

@export var hits_to_break: int = 5

var is_corrupted: bool = false
var corruption_hits: int = 0
var parent_ball: BaseBall


func _ready() -> void:
	parent_ball = get_parent() as BaseBall
	if not parent_ball:
		push_error("[CorruptionComponent] Must be child of BaseBall!")
		return


func corrupt() -> void:
	is_corrupted = true
	corruption_hits = 0
	
	# Visual feedback (placeholder)
	parent_ball.modulate = Color(1.0, 0.3, 0.3)


func register_player_hit() -> void:
	if not is_corrupted:
		return
	
	corruption_hits += 1
	print("[CorruptionComponent] Hit %d/%d" % [corruption_hits, hits_to_break])
	
	if corruption_hits >= hits_to_break:
		_break_corruption()


func _on_hit_by_player(hitbox: HitboxInstance) -> void:
	register_player_hit()


func _break_corruption() -> void:
	print("[CorruptionComponent] Breaking corruption!")
	corruption_broken.emit(parent_ball)
	parent_ball.queue_free()
