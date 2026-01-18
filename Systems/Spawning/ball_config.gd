# Systems/Spawning/ball_config.gd
class_name BallConfig
extends Resource

## Configuration for a spawnable ball type

@export var ball_type: String = "basic"  # Identifier
@export var display_name: String = "Basic Ball"
@export var ball_scene: PackedScene  # The ball scene to spawn
@export var cost: int = 10  # Bounce currency cost
@export var max_count: int = 0  # 0 = unlimited, >0 = max of this type
@export var description: String = "A standard ball"
@export var icon: Texture2D  # Optional icon for UI