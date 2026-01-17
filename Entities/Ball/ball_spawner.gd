# ball_spawner.gd
extends Node2D

## Spawns balls in a radius around this node

@export var ball_scene: PackedScene
@export var spawn_count: int = 5
@export var spawn_radius: float = 100.0


func _ready() -> void:
	# Defer spawning to avoid node setup conflicts
	call_deferred("_spawn_balls")


func _spawn_balls() -> void:
	if ball_scene == null:
		push_error("BallSpawner: No ball_scene assigned!")
		return
	
	for i in range(spawn_count):
		var ball = ball_scene.instantiate()
		
		# Random position within radius
		var angle = randf_range(0, TAU)
		var distance = randf_range(0, spawn_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		ball.global_position = global_position + offset
		
		get_tree().current_scene.add_child(ball)
	
	print("[BallSpawner] Spawned %d balls" % spawn_count)