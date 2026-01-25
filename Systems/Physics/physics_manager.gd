# Systems/Physics/physics_manager.gd
class_name PhysicsManager
extends Node

## Central configuration for all physics systems

@export_group("Bounce Physics")
@export var friction_deceleration: float = 100.0
@export_range(0.0, 1.0) var wall_bounce_damping: float = 0.8
@export_range(0.0, 1.5) var ball_bounce_restitution: float = 1.1
@export var ball_collision_kickback: float = 0.2  # NEW - How much extra bounce on ball collisions
@export var max_velocity: float = 1000.0