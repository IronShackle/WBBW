extends Camera2D

# Shake parameters
var shake_intensity: float = 0.0
var shake_decay: float = 15.0

# Zoom parameters
var target_zoom: Vector2 = Vector2.ONE
var zoom_speed: float = 2.0

func _ready():
	add_to_group("camera")

func _process(delta: float):
	# Handle shake decay
	if shake_intensity > 0:
		shake_intensity = max(shake_intensity - shake_decay * delta, 0.0)
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = Vector2.ZERO
	
	# Always lerp toward target zoom
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)

## Set initial zoom (no lerp, immediate snap)
func set_initial_zoom(zoom_value: float):
	var z = Vector2(zoom_value, zoom_value)
	zoom = z
	target_zoom = z

## Set target zoom (smooth transition)
func set_target_zoom(zoom_value: float):
	target_zoom = Vector2(zoom_value, zoom_value)

## Shake the screen
func shake_screen(intensity: float):
	shake_intensity = intensity