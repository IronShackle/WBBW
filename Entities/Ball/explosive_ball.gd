# Entities/Ball/explosive_ball.gd
class_name ExplosiveBall
extends BaseBall

## Ball that charges on collisions and explodes with knockback

@export var collisions_to_explode: int = 5
@export var explosion_radius: float = 100.0
@export var explosion_force: float = 500.0
@export var charge_color_start: Color = Color.ORANGE
@export var charge_color_full: Color = Color.RED
@export var show_explosion_radius: bool = true

var current_charge: int = 0
var is_exploding: bool = false


func _ready() -> void:
	
	super._ready()
	
	# Connect to bounce component's ball collision signal
	if bounce_component:
		bounce_component.ball_hit.connect(_on_ball_collision)


func _draw() -> void:
	if show_explosion_radius:
		var color = Color(1.0, 0.5, 0.0, 0.3)
		
		if current_charge > 0:
			var charge_percent = float(current_charge) / float(collisions_to_explode)
			color.a = 0.3 + (charge_percent * 0.4)
		
		draw_arc(Vector2.ZERO, explosion_radius, 0, TAU, 32, color, 2.0)
		
		if current_charge >= collisions_to_explode:
			var fill_color = Color(1.0, 0.0, 0.0, 0.2)
			draw_circle(Vector2.ZERO, explosion_radius, fill_color)


func _on_ball_collision(other_ball: Node2D) -> void:
	if is_exploding:
		return
	
	current_charge += 1
	print("[ExplosiveBall] Charge: %d / %d" % [current_charge, collisions_to_explode])
	
	_update_charge_visual()
	
	if current_charge >= collisions_to_explode:
		_trigger_explosion()


func _update_charge_visual() -> void:
	var charge_percent = float(current_charge) / float(collisions_to_explode)
	modulate = charge_color_start.lerp(charge_color_full, charge_percent)
	queue_redraw()


func _trigger_explosion() -> void:
	if is_exploding:
		return
	
	is_exploding = true
	print("[ExplosiveBall] EXPLODING!")
	
	queue_redraw()
	
	# Spawn explosion hitbox - BallHurtbox will detect it and apply knockback
	_spawn_explosion_hitbox()
	
	modulate = Color.WHITE
	
	# Reset after explosion
	await get_tree().create_timer(0.5).timeout
	current_charge = 0
	is_exploding = false
	modulate = charge_color_start
	queue_redraw()


func _spawn_explosion_hitbox() -> void:
	var hitbox = HitboxInstance.new()
	hitbox.position = Vector2.ZERO
	hitbox.hitbox_owner = self  # Don't hit ourselves
	
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	
	hitbox.shape = shape
	hitbox.knockback_force = explosion_force
	hitbox.use_radial_knockback = true
	hitbox.damage = 0
	hitbox.duration = 0.1
	
	add_child(hitbox)
	
	print("[ExplosiveBall] Spawned explosion hitbox (radius: %s, force: %s)" % 
		[explosion_radius, explosion_force])
