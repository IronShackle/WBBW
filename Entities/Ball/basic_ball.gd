# Entities/Balls/basic_ball.gd
class_name BasicBall
extends BaseBall

## Standard ball spawned by the player

func _ready() -> void:
	# Set ball-specific stats
	base_max_velocity = 600.0
	base_friction_deceleration = 40.0
	base_wall_bounce_damping = 0.9
	base_ball_bounce_restitution = 0.85
	base_max_durability = 10
	
	super._ready()
	add_to_group("basic_ball")
