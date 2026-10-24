shader_type spatial;
// Mur en plâtre vieilli : marbrures douces, taches d'humidité près du sol.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.78, 0.74, 0.66);
uniform vec3 stain_color : source_color = vec3(0.6, 0.55, 0.45);
uniform float stain_height = 6.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = dominant_plane(world_pos, world_normal);
	float mottling = fbm(p * 0.15) * 0.5 + fbm(p * 1.2) * 0.15;
	vec3 col = base_color * (0.9 + mottling * 0.25);
	float stain = smoothstep(stain_height, 0.0, world_pos.y + fbm(p * 0.3) * 4.0 - 1.0);
	col = mix(col, stain_color, stain * 0.45);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
