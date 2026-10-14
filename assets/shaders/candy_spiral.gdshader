shader_type canvas_item;

// Spirale tournoyante rouge & blanc style sucette géante de fête foraine / candy lollipop
uniform vec4 color_red : source_color = vec4(0.85, 0.18, 0.28, 0.45);
uniform vec4 color_white : source_color = vec4(1.0, 0.95, 0.90, 0.40);
uniform float rotation_speed : hint_range(-5.0, 5.0) = 0.8;
uniform float spiral_arms : hint_range(4.0, 24.0) = 12.0;
uniform float twist_strength : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Spirale arquée
    float spiral = angle + dist * twist_strength - (TIME * rotation_speed);
    float pattern = sin(spiral * (spiral_arms * 0.5));
    
    // Découpage adouci
    float mix_val = smoothstep(-0.2, 0.2, pattern);
    
    vec4 col = mix(color_red, color_white, mix_val);
    
    // Dégradé radial doux : centre doux, bord estompé
    float vignette = smoothstep(0.5, 0.08, dist);
    col.a *= vignette;
    
    COLOR = col;
}
