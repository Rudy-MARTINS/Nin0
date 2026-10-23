shader_type canvas_item;
// Masque « jumelles » de la vision focalisée : deux lentilles, bords assombris.

uniform vec2 view_size = vec2(1280.0, 720.0);
uniform vec3 tint : source_color = vec3(0.45, 0.92, 1.0);

void fragment() {
	vec2 p = UV * view_size;
	vec2 center = view_size * 0.5;
	float radius = view_size.y * 0.42;
	float d = min(distance(p, center - vec2(radius * 0.55, 0.0)), distance(p, center + vec2(radius * 0.55, 0.0))) - radius;
	float dark = smoothstep(-6.0, 40.0, d) * 0.9;
	float rim = smoothstep(3.0, 0.0, abs(d)) * 0.35;
	// Léger quadrillage de visée à l'intérieur des lentilles.
	float grid = (1.0 - step(0.0, d)) * 0.04 * step(0.985, max(fract(p.x / 64.0), fract(p.y / 64.0)));
	COLOR = vec4(mix(vec3(0.0, 0.02, 0.03), tint, rim + grid), max(dark, rim + grid));
}
