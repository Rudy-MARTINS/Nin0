shader_type spatial;
// Visage numérique de Nin0 : yeux dessinés par fonctions de distance (SDF).
// Les expressions se mélangent par interpolation des formes ; pilotées par nino_visual.gd.
render_mode unshaded, cull_back;

uniform vec3 eye_color : source_color = vec3(0.45, 0.92, 1.0);
uniform vec3 screen_color : source_color = vec3(0.025, 0.035, 0.045);
uniform float aspect = 1.9;
uniform float power : hint_range(0.0, 1.0) = 1.0;
uniform float open : hint_range(0.0, 1.0) = 1.0;
uniform float happy : hint_range(0.0, 1.0) = 0.0;
uniform float surprise : hint_range(0.0, 1.0) = 0.0;
uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform float focus : hint_range(0.0, 1.0) = 0.0;
uniform float curious : hint_range(0.0, 1.0) = 0.0;
// Étourdissement (yeux en spirale) et parasites d'écran (dommages, souvenirs).
uniform float dizzy : hint_range(0.0, 1.0) = 0.0;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform vec2 look = vec2(0.0);

float sd_round_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// side : -1 = œil gauche (à l'écran), +1 = œil droit.
float eye(vec2 p, float side) {
	// Curiosité : un œil plus grand, l'autre plus petit et relevé.
	float scale = 1.0 + curious * 0.22 * -side;
	p.y -= curious * 0.03 * side;
	p /= scale;
	vec2 blink = vec2(p.x, p.y / max(open, 0.06));

	float neutral = sd_round_box(blink, vec2(0.085, 0.15), 0.08);
	float focused = sd_round_box(blink, vec2(0.12, 0.05), 0.05);
	float surprised = length(blink) - 0.19;
	// Arc « ∩ » (yeux plissés de contentement).
	vec2 hp = p - vec2(0.0, -0.05);
	float arc = hp.y > 0.0 ? abs(length(hp) - 0.12) : length(vec2(abs(hp.x) - 0.12, hp.y));
	float happy_eye = arc - 0.035;
	// Chevrons « > < » (choc).
	float dir = -side;
	vec2 tip = vec2(0.08 * dir, 0.0);
	float hurt_eye = min(sd_segment(p, vec2(-0.08 * dir, 0.12), tip), sd_segment(p, vec2(-0.08 * dir, -0.12), tip)) - 0.035;

	// Spirale (étourdi) : distance approchée au bras de la spirale.
	float r = length(p);
	float turns = r / 0.05 - atan(p.y, p.x) / 6.2831 * side + TIME * 1.6 * side;
	float dizzy_eye = max(abs(fract(turns) - 0.5) * 0.05 - 0.011, r - 0.17);

	float d = mix(neutral, focused, focus);
	d = mix(d, surprised, surprise);
	d = mix(d, happy_eye, happy);
	d = mix(d, hurt_eye, hurt);
	d = mix(d, dizzy_eye, dizzy);
	return d * scale;
}

void fragment() {
	vec2 uv = UV;
	// Parasites : bandes horizontales décalées, par saccades.
	float band = floor(uv.y * 18.0);
	float tick = floor(TIME * 14.0);
	float shift = step(0.78, hash(vec2(band, tick))) * (hash(vec2(tick, band)) - 0.5) * 0.35 * glitch;
	uv.x += shift;
	vec2 p = (uv - 0.5) * vec2(aspect, -1.0) / 1.2;
	vec2 offset = look * vec2(0.12, 0.07) * (1.0 - hurt);
	float d = min(eye(p - vec2(-0.34, 0.02) - offset, -1.0), eye(p - vec2(0.34, 0.02) - offset, 1.0));

	float aa = fwidth(d) * 1.2;
	float fill = smoothstep(aa, -aa, d);
	float glow = exp(-max(d, 0.0) * 22.0) * 0.35;
	float scan = 0.92 + 0.08 * sin(UV.y * 140.0);
	// Reflet discret de l'écran.
	float sheen = smoothstep(0.35, 0.0, abs(UV.x + UV.y * 0.6 - 0.45)) * 0.04;

	float flicker = 1.0 - glitch * 0.6 * step(0.7, hash(vec2(tick, 3.0)));
	vec3 col = screen_color + vec3(sheen);
	col += eye_color * (fill * 1.15 + glow) * scan * power * flicker;
	// Neige numérique et léger décalage de teinte.
	float snow = hash(floor(UV * vec2(90.0, 48.0)) + vec2(tick * 1.7, tick));
	col += vec3(snow) * 0.22 * glitch * power;
	col.r += abs(shift) * 0.8 * power;
	ALBEDO = col;
}
