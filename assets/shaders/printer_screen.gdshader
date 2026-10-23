shader_type spatial;
// Petit écran de l'imprimante : éteint, prêt, impression (barre de progression), terminé.
render_mode unshaded;

uniform float power : hint_range(0.0, 1.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int mode = 0; // 0 prêt, 1 impression, 2 terminé
uniform vec3 ready_color : source_color = vec3(0.35, 0.75, 1.0);
uniform vec3 done_color : source_color = vec3(0.45, 1.0, 0.55);

void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(0.02, 0.025, 0.03);
	vec3 accent = mode == 2 ? done_color : ready_color;
	float border = step(0.06, uv.x) * step(uv.x, 0.94) * step(0.12, uv.y) * step(uv.y, 0.88);
	float frame = 1.0 - border;
	float bar_area = step(0.15, uv.x) * step(uv.x, 0.85) * step(0.55, uv.y) * step(uv.y, 0.7);
	float shown = mode == 0 ? 0.0 : (mode == 2 ? 1.0 : progress);
	float bar = bar_area * step(uv.x, 0.15 + 0.7 * shown);
	float outline = bar_area * (1.0 - step(0.16, uv.x) * step(uv.x, 0.84) * step(0.565, uv.y) * step(uv.y, 0.685));
	// Icône « prêt » : petit carré clignotant.
	float icon = mode == 0 ? step(0.44, uv.x) * step(uv.x, 0.56) * step(0.3, uv.y) * step(uv.y, 0.45)
			* (0.6 + 0.4 * sin(TIME * 3.0)) : 0.0;
	col += accent * (frame * 0.35 + bar + outline * 0.6 + icon);
	ALBEDO = mix(vec3(0.02, 0.025, 0.03), col, power);
}
