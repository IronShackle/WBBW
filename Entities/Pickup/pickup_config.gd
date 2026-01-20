# Systems/Pickup/pickup_config.gd
class_name PickupConfig
extends Resource

## Configuration for a pickup type

@export var pickup_id: String = "speed_pickup"
@export var display_name: String = "Speed Boost"
@export var description: String = "Increases your max speed"
@export var pickup_scene: PackedScene  # The pickup scene to spawn
@export var buff_config: BuffConfig  # Which buff this pickup grants
@export var spawn_weight: int = 10  # Relative spawn chance (higher = more common)
@export var icon: Texture2D
@export var visual_color: Color = Color.CYAN