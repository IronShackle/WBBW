# Systems/Buffs/buff_config.gd
class_name BuffConfig
extends Resource

@export var buff_id: String = "speed_boost"
@export var display_name: String = "Speed Boost"
@export var description: String = "Reduces friction"
@export_file("*.gd") var buff_script_path: String = ""  # Path to buff script
@export var icon: Texture2D
@export var visual_color: Color = Color.CYAN
@export var parameters: Dictionary = {}