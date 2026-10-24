shader_type spatial;
// Parquet usé : lames, veinage, joints et poussière (coordonnées monde, unités de 10 cm).
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 color_a : source_color = vec3(0.47, 0.32, 0.2);
uniform vec3 color_b : source_color = vec3(0.36, 0.23, 0.14);
uniform vec3 dust_color : source_color = vec3(0.62, 0.58, 0.52);
uniform float plank_width = 1.4;
uniform float plank_length = 9.0;
uniform float dust_amount : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float row = floor(p.y / plank_width);
	float offset = hash12(vec2(row, 3.7)) * plank_length;
	float column = floor((p.x + offset) / plank_length);
	float plank_id = hash12(vec2(row, column));
	vec2 local = vec2(fract((p.x + offset) / plank_length), fract(p.y / plank_width));

	// Veinage atténué au loin (anti-moiré).
	float detail = clamp(1.0 - length(fwidth(p)) * 3.0, 0.0, 1.0);
	float grain = value_noise(vec2(p.x * 0.5, p.y * 6.0 + plank_id * 40.0));
	grain = grain * 0.6 + 0.4 * (sin((p.y * 4.0 + value_noise(p * vec2(0.3, 2.0)) * 4.0) * 3.0) * 0.5 + 0.5);
	grain = mix(0.5, grain, detail);
	vec3 col = mix(color_a, color_b, clamp(plank_id * 0.7 + grain * 0.4, 0.0, 1.0));

	float seam = min(min(local.y, 1.0 - local.y) * plank_width, min(local.x, 1.0 - local.x) * plank_length);
	col *= mix(0.45, 1.0, smoothstep(0.0, 0.035, seam));

	float dust = smoothstep(0.45, 0.85, fbm(p * 0.35)) * dust_amount;
	col = mix(col, dust_color, dust);
	ALBEDO = col;
	ROUGHNESS = mix(0.55, 0.9, dust);
	SPECULAR = 0.3;
}
