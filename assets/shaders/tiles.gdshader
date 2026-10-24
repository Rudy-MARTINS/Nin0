shader_type spatial;
// Carrelage en coordonnées monde : carreaux, joints, salissures et humidité par endroits.
uniform vec3 tile_color : source_color = vec3(0.82, 0.85, 0.84);
uniform vec3 grout_color : source_color = vec3(0.45, 0.45, 0.42);
uniform vec3 grime_color : source_color = vec3(0.42, 0.38, 0.28);
uniform float tile_size = 1.5;
uniform float grout = 0.05;
uniform int plane_axis = 1; // 0 : mur x, 1 : sol, 2 : mur z

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = plane_axis == 1 ? world_pos.xz : (plane_axis == 0 ? world_pos.zy : world_pos.xy);
	vec2 cell = p / tile_size;
	vec2 g = abs(fract(cell) - 0.5);
	float line = step(0.5 - grout / tile_size, max(g.x, g.y));
	float variation = hash(floor(cell)) * 0.06;
	float grime = smoothstep(0.55, 0.85, noise(p * 0.35)) * 0.5 + smoothstep(0.6, 0.9, noise(p * 2.1)) * 0.2;
	vec3 base = tile_color - variation;
	vec3 col = mix(base, grout_color, line);
	col = mix(col, grime_color, grime);
	ALBEDO = col;
	ROUGHNESS = mix(0.25, 0.9, max(line, grime));
	SPECULAR = 0.4;
}
