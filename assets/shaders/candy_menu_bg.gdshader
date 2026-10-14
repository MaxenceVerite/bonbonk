shader_type canvas_item;

// Candy swirl & striped background shader
uniform vec4 bg_color_base : source_color = vec4(0.98, 0.93, 0.85, 1.0);     // Biscuit cream
uniform vec4 bg_color_secondary : source_color = vec4(0.96, 0.82, 0.88, 1.0);// Pastel strawberry pink
uniform vec4 bg_color_accent : source_color = vec4(0.85, 0.94, 0.96, 1.0);   // Soft pastel cyan
uniform float stripe_scale : hint_range(5.0, 50.0) = 18.0;
uniform float scroll_speed : hint_range(-1.0, 1.0) = 0.05;

void fragment() {
	vec2 uv = UV;
	
	// Diagonal candy stripes
	float diag = uv.x * 0.8 + uv.y * 1.2 + TIME * scroll_speed;
	float stripe_val = sin(diag * stripe_scale);
	
	// Soft vignette / radial gradient from center
	vec2 center_dist = uv - vec2(0.5, 0.45);
	float dist = length(center_dist);
	
	// Base color blend
	vec4 col = mix(bg_color_base, bg_color_secondary, smoothstep(-0.2, 0.8, stripe_val));
	
	// Center soft glow / edge shadow
	col = mix(col, bg_color_accent, smoothstep(0.7, 0.0, dist) * 0.35);
	col.rgb -= dist * 0.15; // subtle edge shade
	
	COLOR = col;
}
