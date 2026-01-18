# Entities/Ball/base_ball.gd
class_name BaseBall
extends CharacterBody2D

## Base class for all ball types

@onready var bounce_component: BounceComponent = $BounceComponent
@onready var ball_detection: Area2D = $BallDetection
@onready var ball_hurtbox: BallHurtbox = $BallDetection  # Same node, different script

# Ball properties that derived classes can override
@export var ball_color: Color = Color.WHITE
@export var ball_radius: float = 10.0

# Ball type identifier (set by derived classes)
var ball_type: String = "base"


func _ready() -> void:
	_setup_ball()
	_apply_visual_properties()


## Virtual method - override in derived classes for custom setup
func _setup_ball() -> void:
	pass


## Virtual method - override for custom collision behavior
func _on_ball_collision(other_ball: BaseBall) -> void:
	pass


## Virtual method - override for custom wall bounce behavior
func _on_wall_bounce(wall: Node2D) -> void:
	pass


func _apply_visual_properties() -> void:
	# Apply color to sprite/modulate
	modulate = ball_color