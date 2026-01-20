shader_type canvas_item;

uniform float damage_percent : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wall_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// Use screen coordinates instead of UV
	vec2 pos = FRAGCOORD.xy;
	
	// Generate noise from screen position
	float noise = fract(sin(dot(pos * 0.005, vec2(12.9898, 78.233))) * 43758.5453);
	
	// Determine crack intensity based on damage thresholds
	float crack_intensity = 0.0;
	if (damage_percent >= 0.95) {
		crack_intensity = 0.25;
	} else if (damage_percent >= 0.90) {
		crack_intensity = 0.15;
	} else if (damage_percent >= 0.75) {
		crack_intensity = 0.02;
	}
	
	// Show white pixels based on noise threshold
	if (noise < crack_intensity) {
		COLOR = vec4(1.0, 1.0, 1.0, 1.0); // White cracks
	} else {
		COLOR = wall_color; // Black wall
	}
}