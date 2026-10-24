shader_type canvas_item;
// Parasites plein écran pendant la lecture d'un souvenir : voile sombre, lignes de
// balayage, bandes de neige numérique par saccades. `intensity` : 0..1.

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.45, 0.92, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float tick = floor(TIME * 12.0);
	float band = floor(UV.y * 40.0);
	float noisy_band = step(1.0 - 0.25 * intensity, hash(vec2(band, tick)));
	float snow = hash(floor(UV * vec2(320.0, 180.0)) + vec2(tick, tick * 0.37));
	float scan = 0.5 + 0.5 * sin(UV.y * 900.0 + TIME * 6.0);
	float vignette = smoothstep(0.25, 0.9, distance(UV, vec2(0.5)));
	vec3 col = vec3(0.01, 0.02, 0.025) + tint * (snow * noisy_band * 0.25 + scan * 0.03);
	float alpha = intensity * (0.95 + vignette * 0.2) + noisy_band * snow * 0.3 * intensity;
	COLOR = vec4(col, clamp(alpha, 0.0, 0.92));
}
