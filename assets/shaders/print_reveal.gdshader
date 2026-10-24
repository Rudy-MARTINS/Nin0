shader_type spatial;
// Pièce en cours d'impression : la partie au-dessus de la couche actuelle est invisible ;
// une fine bande lumineuse marque la couche en train d'être déposée.

uniform vec3 albedo : source_color = vec3(0.93, 0.89, 0.8);
uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float cut_height = 100.0;
uniform float layer_lines = 180.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (world_pos.y > cut_height) {
		discard;
	}
	float band = smoothstep(0.03, 0.0, cut_height - world_pos.y);
	float layers = 0.94 + 0.06 * sin(world_pos.y * layer_lines);
	ALBEDO = albedo * layers;
	EMISSION = glow_color * band * 2.5;
	ROUGHNESS = 0.45;
}
