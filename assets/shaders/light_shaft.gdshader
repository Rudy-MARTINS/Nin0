shader_type spatial;
// Faisceau de lumière factice (fenêtre) : additif, s'estompe aux extrémités.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 color : source_color = vec3(1.0, 0.85, 0.6);
uniform float intensity = 0.12;

void fragment() {
	float along = UV.y;
	float fade = smoothstep(0.0, 0.25, along) * smoothstep(1.0, 0.5, along);
	float side = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	float flicker = 0.85 + value_noise(vec2(UV.x * 6.0 + TIME * 0.2, along * 3.0)) * 0.3;
	// Atténuation aux angles rasants pour éviter les arêtes visibles.
	float facing = abs(dot(NORMAL, VIEW));
	ALBEDO = color * intensity * fade * side * flicker * facing;
}
