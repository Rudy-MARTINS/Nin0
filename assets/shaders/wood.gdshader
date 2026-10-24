shader_type spatial;
// Bois générique (meubles, établi, rebord) : veinage projeté selon la face dominante.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 color_light : source_color = vec3(0.58, 0.41, 0.26);
uniform vec3 color_dark : source_color = vec3(0.4, 0.26, 0.15);
uniform float grain_scale = 1.0;
uniform float wear : hint_range(0.0, 1.0) = 0.2;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = dominant_plane(world_pos, world_normal) * grain_scale;
	float warp = fbm(p * vec2(0.25, 1.5)) * 3.0;
	// Atténue le veinage fin au loin pour éviter le moiré.
	float detail = clamp(1.0 - length(fwidth(p)) * 4.0, 0.0, 1.0);
	float rings = mix(0.5, sin((p.y * 5.0 + warp) * 2.0) * 0.5 + 0.5, detail * 0.8 + 0.2);
	float fine = mix(0.5, value_noise(vec2(p.x * 0.4, p.y * 9.0)), detail);
	vec3 col = mix(color_light, color_dark, rings * 0.45 + fine * 0.3);
	float scuffs = smoothstep(0.55, 0.9, fbm(p * 0.6 + 13.0)) * wear;
	col = mix(col, col * 1.25 + 0.05, scuffs);
	ALBEDO = col;
	ROUGHNESS = 0.6 + fine * 0.2;
	SPECULAR = 0.35;
}
