shader_type canvas_item;

// Rivière de Chocolat Chaud & Sirop Onctueux (Mobile-First)
// - Écoulement sirupeux lourd, plis de caramel visqueux
// - 1 seul Draw Call, zéro allocation mémoire, 60/120 FPS

uniform vec4 choco_dark : source_color = vec4(0.20, 0.07, 0.03, 1.0);     // Chocolat noir fondant
uniform vec4 choco_milk : source_color = vec4(0.36, 0.15, 0.06, 1.0);     // Chocolat au lait chaud
uniform vec4 choco_creamy : source_color = vec4(0.68, 0.38, 0.18, 1.0);   // Nappage caramel / crème
uniform vec4 shore_shadow : source_color = vec4(0.10, 0.03, 0.01, 0.88);  // Ombre de berge profonde

uniform float flow_speed : hint_range(0.05, 1.5) = 0.20;
uniform bool is_left_river = true; // true = rive droite contre l'arène

void fragment() {
    vec2 uv = UV;
    float t = TIME * flow_speed;
    
    // 1. Écoulement sirupeux et visqueux :
    // Plis lourds et lents avec tension de surface
    float slow_drift = t * 1.2;
    float fold1 = sin(uv.y * 5.0 + slow_drift + sin(uv.x * 3.5 + t * 0.7) * 1.3);
    float fold2 = cos(uv.y * 9.5 - slow_drift * 1.3 + uv.x * 4.0 + fold1 * 0.7);
    float syrup_flow = fold1 * 0.65 + fold2 * 0.35; // Plis de sirop étiré
    
    // 2. Teinte de base : chocolat chaud onctueux
    vec3 col = mix(choco_dark.rgb, choco_milk.rgb, syrup_flow * 0.45 + 0.55);
    
    // 3. Rubans de crème / caramel liquide épais
    float ribbons = smoothstep(0.28, 0.58, syrup_flow);
    col = mix(col, choco_creamy.rgb, ribbons * 0.50);
    
    // 4. Ombres de berges (canal encaissé deux fois plus large)
    // Berge contre l'arène (rempart haut)
    float dist_to_arena = is_left_river ? (1.0 - uv.x) : uv.x;
    float arena_shadow = smoothstep(0.0, 0.22, dist_to_arena);
    col = mix(shore_shadow.rgb, col, arena_shadow);
    
    // Berge extérieure contre le fond
    float dist_to_outer = is_left_river ? uv.x : (1.0 - uv.x);
    float outer_shadow = smoothstep(0.0, 0.16, dist_to_outer);
    col = mix(shore_shadow.rgb * 1.15, col, outer_shadow);
    
    // 5. Brillance spéculaire sirupeuse (luisance liquide)
    float gloss = pow(max(0.0, fold1 * 0.5 + fold2 * 0.5), 3.5) * smoothstep(0.12, 0.88, uv.x);
    col += choco_creamy.rgb * gloss * 0.32;

    COLOR = vec4(col, 1.0);
}
