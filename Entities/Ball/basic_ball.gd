# Entities/Balls/basic_ball.gd
class_name BasicBall
extends BaseBall

## Standard ball spawned by the player

func _ready() -> void:
	
	super._ready()
	add_to_group("basic_ball")
