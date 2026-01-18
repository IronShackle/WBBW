# Systems/Combat/ball_hurtbox.gd
class_name BallHurtbox
extends Area2D

## Hurtbox for balls that applies knockback via BounceComponent

signal hit_received(hitbox: HitboxInstance)

var bounce_component: BounceComponent


func _ready() -> void:
	add_to_group("ball_hurtbox")
	
	# Find BounceComponent on parent
	bounce_component = get_parent().get_node_or_null("BounceComponent")
	
	if not bounce_component:
		push_warning("[BallHurtbox] Parent has no BounceComponent!")
	
	# Connect to hitbox areas
	area_entered.connect(_on_hitbox_entered)


func _on_hitbox_entered(area: Area2D) -> void:
	# Check if it's a hitbox
	if area.is_in_group("hitbox") and area is HitboxInstance:
		var hitbox = area as HitboxInstance
		
		# Don't hit ourselves
		if hitbox.hitbox_owner == get_parent():
			return
		
		take_hit(hitbox)


func take_hit(hitbox: HitboxInstance) -> void:
	if not bounce_component:
		return
	
	# Calculate knockback direction
	var kb_direction = hitbox.knockback_direction
	
	if hitbox.use_radial_knockback:
		# Direction from hitbox center to this ball
		kb_direction = (global_position - hitbox.global_position).normalized()
	
	# Apply knockback via BounceComponent
	bounce_component.apply_knockback(kb_direction, hitbox.knockback_force)
	
	hit_received.emit(hitbox)
	
	print("[BallHurtbox] Received hit from %s (force: %s, direction: %s)" % 
		[hitbox.hitbox_owner.name if hitbox.hitbox_owner else "unknown", hitbox.knockback_force, kb_direction])