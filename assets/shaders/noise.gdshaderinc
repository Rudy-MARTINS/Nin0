// Bruits procéduraux simples partagés par les shaders du décor.

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

// Coordonnées 2D d'un point du monde selon la face dominante (projection triplanaire simple).
vec2 dominant_plane(vec3 world_pos, vec3 world_normal) {
	vec3 n = abs(world_normal);
	if (n.y >= n.x && n.y >= n.z) {
		return world_pos.xz;
	} else if (n.x >= n.z) {
		return world_pos.zy;
	}
	return world_pos.xy;
}
