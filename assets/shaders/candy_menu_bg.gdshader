shader_type canvas_item;

// Confectionery Bicolor Diamond & Warm Vignette Background
uniform vec4 diamond_color_a : source_color = vec4(0.86, 0.63, 0.36, 1.0);   // Warm golden honey waffle
uniform vec4 diamond_color_b : source_color = vec4(0.74, 0.47, 0.21, 1.0);   // Toasted caramel hazelnut
uniform vec4 seam_color : source_color = vec4(0.42, 0.22, 0.08, 0.5);        // Baked seam line
uniform vec4 vignette_color : source_color = vec4(0.18, 0.08, 0.03, 1.0);    // Dark chocolate perimeter
uniform float cell_size : hint_range(32.0, 120.0) = 68.0;                    // Larger, uncluttered diamonds
uniform float scroll_speed : hint_range(-0.5, 0.5) = 0.01;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec2 uv = UV;
	vec2 pixel_pos = uv * vec2(720.0, 1280.0);
	
	// Gentle ambient drift
	pixel_pos.y += TIME * scroll_speed * 60.0;
	
	// Rotate 45 degrees for classic diagonal diamonds
	float rad = 0.785398;
	mat2 rot = mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
	vec2 w_uv = (rot * pixel_pos) / cell_size;
	
	// Checkered alternating diamond index
	ivec2 cell_idx = ivec2(floor(w_uv));
	bool is_alt = ((cell_idx.x + cell_idx.y) % 2) != 0;
	
	// Local cell coordinates [-0.5, 0.5]
	vec2 f_uv = fract(w_uv) - 0.5;
	float d = max(abs(f_uv.x), abs(f_uv.y));
	
	// Bicolor alternating base
	vec4 base = is_alt ? diamond_color_a : diamond_color_b;
	
	// 3D subtle lighting normal from top-left
	float light = (-(f_uv.x + f_uv.y)) * 0.18;
	base.rgb += light;
	
	// Crisp clean baked seam between diamonds
	float seam = smoothstep(0.45, 0.495, d);
	vec4 col = mix(base, seam_color, seam * seam_color.a);
	
	// Deep warm chocolate radial vignette for readability & depth
	vec2 center_dist = uv - vec2(0.5, 0.45);
	float dist = length(center_dist * vec2(1.0, 0.82));
	float vig = smoothstep(0.26, 0.95, dist) * vignette_intensity;
	col = mix(col, vignette_color, vig);
	
	COLOR = col;
}


