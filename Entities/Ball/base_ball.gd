# Entities/Ball/base_ball.gd
class_name BaseBall
extends CharacterBody2D

## Base class for all ball types

@onready var bounce_component: BounceComponent = $BounceComponent
@onready var ball_detection: Area2D = $BallDetection
@onready var ball_hurtbox: BallHurtbox = $BallDetection

# Base physics stats - computed properties read these
@export_group("Physics Stats")
@export var base_max_velocity: float = 800.0
@export var base_friction_deceleration: float = 50.0
@export var base_wall_bounce_damping: float = 0.85
@export var base_ball_bounce_restitution: float = 0.9

# Visual properties
@export_group("Visual")
@export var ball_color: Color = Color.WHITE
@export var ball_radius: float = 10.0

# Durability system
@export_group("Durability")
@export var is_breakable: bool = true
@export var base_max_durability: int = 20

# Currency reward
@export_group("Currency")
@export var base_currency_value: int = 10

var current_durability: int = 0
var ball_type: String = "base"

# Component references
var buff_component: BuffComponent
var config_manager: GameConfigManager


func _ready() -> void:
	current_durability = max_durability
	_setup_ball()
	_apply_visual_properties()
	
	# Get component references
	buff_component = get_node_or_null("BuffComponent")
	
	await get_tree().process_frame
	config_manager = get_tree().get_first_node_in_group("game_config_manager")
	
	if not config_manager:
		push_warning("[BaseBall] No GameConfigManager found in scene")
	
	# Connect to bounce component signals
	if bounce_component:
		bounce_component.bounced.connect(_on_bounced)
		bounce_component.ball_hit.connect(_on_ball_collision)


# Computed properties with modifier layers applied
var max_velocity: float:
	get:
		var base = base_max_velocity
		
		if config_manager:
			base = config_manager.apply_stat_modifiers(base, "max_velocity")
		
		if buff_component:
			base = buff_component.apply_stat_modifiers(base, "max_velocity")
		
		return base

func _draw() -> void:
	draw_circle(Vector2.ZERO, ball_radius, ball_color)

var friction_deceleration: float:
	get:
		var base = base_friction_deceleration
		
		if config_manager:
			base = config_manager.apply_stat_modifiers(base, "friction_deceleration")
		
		if buff_component:
			base = buff_component.apply_stat_modifiers(base, "friction_deceleration")
		
		return base


var wall_bounce_damping: float:
	get:
		var base = base_wall_bounce_damping
		
		if config_manager:
			base = config_manager.apply_stat_modifiers(base, "wall_bounce_damping")
		
		if buff_component:
			base = buff_component.apply_stat_modifiers(base, "wall_bounce_damping")
		
		return base


var ball_bounce_restitution: float:
	get:
		var base = base_ball_bounce_restitution
		
		if config_manager:
			base = config_manager.apply_stat_modifiers(base, "ball_bounce_restitution")
		
		if buff_component:
			base = buff_component.apply_stat_modifiers(base, "ball_bounce_restitution")
		
		return base


var max_durability: int:
	get:
		var base = float(base_max_durability)
		
		if config_manager:
			base = config_manager.apply_stat_modifiers(base, "durability")
		
		if buff_component:
			base = buff_component.apply_stat_modifiers(base, "durability")
		
		return int(base)


## Virtual method - override in derived classes for custom setup
func _setup_ball() -> void:
	pass


## Virtual method - override for custom collision behavior
func _on_ball_collision(other_ball: BaseBall) -> void:
	_reduce_durability()


## Virtual method - override for custom wall bounce behavior
func _on_wall_bounce(wall: Node2D) -> void:
	pass


func _apply_visual_properties() -> void:
	queue_redraw()
	_update_collision_shapes()
	modulate = ball_color

func _update_collision_shapes() -> void:
	# Physics collision shape
	var physics_shape = get_node_or_null("CollisionShape2D")
	if physics_shape and physics_shape.shape is CircleShape2D:
		physics_shape.shape.radius = ball_radius
	
	# BallDetection collision shape
	var detection_shape = get_node_or_null("BallDetection/CollisionShape2D")
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = ball_radius

func _on_bounced(collision: KinematicCollision2D) -> void:
	_reduce_durability()


func _reduce_durability() -> void:
	if not is_breakable:
		return
	
	current_durability -= 1
	
	if current_durability <= 0:
		_explode()


func _explode() -> void:
	# Spawn explosion particles
	var particles = get_node_or_null("ExplosionParticles")
	if particles:
		# Reparent to scene so particles persist after ball is freed
		var explosion = particles.duplicate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		explosion.emitting = true
		explosion.finished.connect(explosion.queue_free)
	
	# Award currency before destroying
	GameManager.add_currency(base_currency_value)
	
	queue_free()