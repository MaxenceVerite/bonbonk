shader_type canvas_item;

// Shader pour le plateau de jeu "Chemin Gourmand & Collines Bonbon" :
// - Sentier central de caramel / nougatine doré et sinueux (exactement comme sur l'écran d'accueil)
// - Collines bordières vertes acidulées et rose bonbon / guimauve
// - Effet de lueur douce et vignette gourmande sur les rebords

uniform vec4 path_color_base : source_color = vec4(0.91, 0.69, 0.38, 1.0);     // Caramel doux
uniform vec4 path_color_shade : source_color = vec4(0.82, 0.58, 0.28, 1.0);    // Caramel ombré
uniform vec4 grass_color_candy : source_color = vec4(0.48, 0.74, 0.20, 1.0);   // Vert bonbon
uniform vec4 hill_candy_pink : source_color = vec4(0.96, 0.64, 0.76, 1.0);     // Collines guimauve rose
uniform vec4 shadow_border_color : source_color = vec4(0.20, 0.10, 0.05, 0.45);

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
    
    // 1. Calcul du sentier sinueux central menant au château
    // Le chemin serpente avec deux douces ondulations en S
    float path_center_x = 0.5 + sin(uv.y * 5.0) * 0.16 + sin(uv.y * 2.2) * 0.08;
    // Le chemin s'élargit légèrement vers le bas de l'écran
    float path_width = mix(0.24, 0.36, uv.y);
    float dist_to_path = abs(uv.x - path_center_x);
    
    // Masque du sentier (0 = herbe/colline, 1 = plein sentier caramel)
    float path_mask = 1.0 - smoothstep(path_width * 0.82, path_width * 1.05, dist_to_path);
    
    // Bordure foncée du chemin de caramel
    float path_edge = smoothstep(path_width * 0.78, path_width * 0.95, dist_to_path) * path_mask;
    
    // Couleur du sentier (avec grain sablé doré)
    float sand_grain = noise(uv * vec2(120.0, 240.0)) * 0.06;
    vec3 path_col = mix(path_color_base.rgb, path_color_shade.rgb, uv.y * 0.5 + sand_grain);
    path_col = mix(path_col, path_color_shade.rgb * 0.85, path_edge); // bordure plus cuite
    
    // 2. Collines environnantes (alternance vert acidulé et vagues de rose guimauve)
    float hill_wave = sin(uv.y * 8.0 + uv.x * 4.0) * 0.5 + 0.5;
    float hill_grain = noise(uv * vec2(80.0, 160.0)) * 0.05;
    vec3 grass_col = mix(grass_color_candy.rgb, grass_color_candy.rgb * 0.9, sin(uv.y * 18.0) * 0.5 + 0.5);
    
    // Touches de collines roses bonbon sur les côtés
    float pink_spots = smoothstep(0.68, 0.95, hill_wave);
    vec3 land_col = mix(grass_col + hill_grain, hill_candy_pink.rgb + hill_grain, pink_spots * 0.65);
    
    // 3. Fusion Sentier Caramel & Terres Bonbon
    vec3 base_color = mix(land_col, path_col, path_mask);
    
    // 4. Ombre ambiante / biseau sur les rebords extérieurs
    float border_x = min(uv.x, 1.0 - uv.x) * 16.0;
    float border_y = min(uv.y, 1.0 - uv.y) * 20.0;
    float vignette = clamp(min(border_x, border_y), 0.0, 1.0);
    
    vec3 final_rgb = mix(shadow_border_color.rgb, base_color, vignette);
    COLOR = vec4(final_rgb, 1.0);
}
