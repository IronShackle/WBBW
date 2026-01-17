# Entities/Ball/ball.gd
extends CharacterBody2D
class_name Ball

## Simple ball entity that bounces around when hit

@onready var bounce_component: BounceComponent = $BounceComponent
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	# Connect to hurtbox hit detection
	if hurtbox:
		hurtbox.hit_by_hitbox.connect(_on_hit_by_hitbox)


func _on_hit_by_hitbox(_hitbox: Hitbox) -> void:
	# Knockback is applied by ChargedAttack via BounceManager
	# This is just for feedback/effects if needed
	print("[Ball] Hit detected!")