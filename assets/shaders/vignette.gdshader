shader_type canvas_item;
// Vignettage doux et légèrement chaud (glow-up du lot 7) : assombrit les bords de l'image
// sans toucher au centre, pour resserrer le regard sur Nin0. Coût négligeable.

uniform float strength : hint_range(0.0, 1.0) = 0.32;
uniform vec4 tint : source_color = vec4(0.06, 0.04, 0.05, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.25;
	float d = length(uv);
	float v = smoothstep(0.42, 0.95, d) * strength;
	COLOR = vec4(tint.rgb, v);
}
