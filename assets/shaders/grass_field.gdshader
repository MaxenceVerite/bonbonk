shader_type canvas_item;

// Shader procédural pour terrain de jeu stylisé :
// - Bandes de tonte d'herbe alternées
// - Gradient de vignettage / ombre ambiante sur les bordures
// - Micro-bruit de texture de pelouse / terre
// - Légère ondulation de lumière de vent très subtile

uniform vec4 grass_color_1 : source_color = vec4(0.48, 0.70, 0.16, 1.0);
uniform vec4 grass_color_2 : source_color = vec4(0.43, 0.64, 0.13, 1.0);
uniform vec4 shadow_border_color : source_color = vec4(0.08, 0.12, 0.04, 0.45);
uniform float stripe_count = 14.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    
    // 1. Bandes de tonte horizontales
    float stripe = sin(uv.y * stripe_count * 3.14159);
    float stripe_mask = smoothstep(-0.2, 0.2, stripe);
    vec4 base_color = mix(grass_color_1, grass_color_2, stripe_mask);
    
    // 2. Grain de pelouse procédural (herbe / terre)
    float grain = noise(uv * vec2(160.0, 320.0));
    base_color.rgb += (grain - 0.5) * 0.07;
    
    // 3. Ombre de bordure / Ambient Occlusion intérieure
    float border_x = min(uv.x, 1.0 - uv.x) * 12.0;
    float border_y = min(uv.y, 1.0 - uv.y) * 16.0;
    float edge_dist = min(border_x, border_y);
    float vignette = clamp(edge_dist, 0.0, 1.0);
    
    // 4. Lueur de vent subtile se déplaçant doucement
    float wind = sin(uv.y * 5.0 + uv.x * 3.0 + TIME * 0.8) * 0.025;
    base_color.rgb += wind;
    
    // Mix final avec l'ombre ambiante
    vec3 final_rgb = mix(shadow_border_color.rgb, base_color.rgb, vignette);
    COLOR = vec4(final_rgb, 1.0);
}
