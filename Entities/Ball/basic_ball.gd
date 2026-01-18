# Entities/Ball/basic_ball.gd
class_name BasicBall
extends BaseBall

## Standard ball with no special effects


func _ready() -> void:
	ball_type = "basic"
	ball_color = Color.WHITE
	ball_radius = 10.0
	
	super._ready()  # Call parent _ready


func _setup_ball() -> void:
	# Basic ball has no special setup
	pass