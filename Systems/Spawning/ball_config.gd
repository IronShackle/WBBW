# Systems/Spawning/ball_config.gd
class_name BallConfig
extends Resource

## Configuration for a spawnable ball type

@export var ball_type: String = "basic"  # Identifier (must match GameConfigManager properties)
@export var display_name: String = "Basic Ball"
@export var ball_scene: PackedScene  # The ball scene to spawn
@export var cost: int = 10  # Bounce currency cost (for basic balls)
@export var essence_cost: int = 0  # Essence cost (for special balls - 0 means not a special ball)
@export var description: String = "A standard ball"
@export var icon: Texture2D  # Optional icon for UI