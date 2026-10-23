shader_type spatial;
// Tapis tissé à motifs simples, un peu délavé.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 color_base : source_color = vec3(0.45, 0.22, 0.17);
uniform vec3 color_band : source_color = vec3(0.78, 0.66, 0.45);
uniform vec3 color_accent : source_color = vec3(0.22, 0.3, 0.38);
uniform vec2 size = vec2(12.0, 9.0);

void fragment() {
	vec2 p = UV * size;
	vec2 edge = min(p, size - p);
	float border = min(edge.x, edge.y);
	vec3 col = color_base;
	col = mix(col, color_band, step(0.5, border) * step(border, 0.9));
	col = mix(col, color_accent, step(1.3, border) * step(border, 1.6));
	// Losanges centraux.
	vec2 c = abs(p - size * 0.5);
	float diamond = c.x / (size.x * 0.3) + c.y / (size.y * 0.3);
	col = mix(col, color_band, step(diamond, 0.55) * step(0.42, diamond));
	col = mix(col, color_accent, step(diamond, 0.25));
	float weave = sin(p.x * 60.0) * sin(p.y * 60.0) * 0.04;
	col *= 0.88 + weave + fbm(p * 0.6) * 0.18;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
