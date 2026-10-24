class_name MaterialLibrary
extends RefCounted
## Bibliothèque de matériaux de Nin0 (lot 7, glow-up). Une seule famille artistique :
## couleurs franches et douces (style cartoon), mais surfaces enrichies par des textures
## procédurales originales (tools/art/gen_textures.py) : fil du bois, fibres du carton,
## trame des tissus, métal brossé, plastique mat ou brillant, enduit, émail…
##
## `dress(root)` parcourt une scène et enrichit chaque StandardMaterial3D généré
## (identifiant « Mat_<nom> ») selon sa famille, en conservant sa couleur : détail en
## niveaux de gris (albédo), relief (normal map), rugosité variable, projection
## triplanaire (aucune UV à refaire, densité de texture constante quelle que soit la
## taille de l'objet). Les matériaux déjà texturés, transparents, émissifs ou spéciaux
## (vitres, ciel, feuillage, décalcomanies) ne sont pas touchés. Chaque matériau n'est
## enrichi qu'une fois (métadonnée « nino_dressed »).

const DIR := "res://assets/textures/materials/"

## famille → [taille d'une tuile (u), force du relief, rugosité min, rugosité max, métal, éclaircissement]
## (1 u = 10 cm : une tuile de bois couvre 30 cm, la trame de tissu 6 cm…)
const FAMILIES := {
	&"wood": [3.0, 0.9, 0.55, 0.85, 0.0, 1.12],
	&"cardboard": [2.2, 0.8, 0.8, 1.0, 0.0, 1.1],
	&"paper": [1.6, 0.4, 0.85, 1.0, 0.0, 1.06],
	&"fabric": [0.8, 1.0, 0.9, 1.0, 0.0, 1.14],
	&"metal": [1.2, 0.35, 0.3, 0.6, 0.85, 1.08],
	&"plastic": [1.4, 0.35, 0.35, 0.65, 0.0, 1.06],
	&"plaster": [6.0, 0.5, 0.82, 1.0, 0.0, 1.08],
	&"ceramic": [2.4, 0.25, 0.12, 0.4, 0.0, 1.04],
	&"floor": [4.0, 0.6, 0.55, 0.85, 0.0, 1.1],
}

## Mots-clés des identifiants de matériaux → famille (le premier qui correspond gagne).
const KEYWORDS := [
	[&"skip", ["glass", "sky", "foliage", "leaf", "blocker", "dust", "stain", "mold", "shadow", "silk", "water", "puddle",
		"sludge", "mirror", "screen", "led", "lamp", "sunpatch", "husk", "scorch", "crack", "child_drawing", "blueprint",
		"photo", "printer_card", "shaft", "garden", "facade_win", "cocoon", "jar", "spool_clear", "pack_film", "tea",
		"soil", "crumb", "sprout", "potato", "peel", "larva", "drain_hole", "ink", "match", "filament"]],
	[&"metal", ["steel", "metal", "chrome", "brass", "handle", "grate", "hob", "tin", "knob", "socket", "cable", "wire"]],
	[&"cardboard", ["cardboard", "card", "cereal", "crate_lid", "cork", "tape", "basket", "wicker"]],
	[&"paper", ["paper", "pages", "notebook", "note_", "mag_", "elastic"]],
	[&"fabric", ["fabric", "plush", "slipper", "ironing_cover", "mat_green", "towel", "tee_", "denim", "rag", "cotton",
		"sofa", "cushion", "throw", "rug", "curtain", "scarf", "sock", "umbrella", "shoe", "doormat", "mat"]],
	[&"ceramic", ["ceramic", "enamel", "mug", "plate", "tile", "soap", "counter", "terracotta", "pot"]],
	[&"wood", ["wood", "plank", "door", "trunk", "plinth", "shelf"]],
	[&"plastic", ["plastic", "toy", "servo", "bucket", "bin", "console", "pad", "cap", "sponge", "crate", "box_case",
		"magnet", "bottle", "lessive", "chair", "black", "grey", "white", "rubber", "sole", "pipe", "pencil", "dock",
		"accent", "ruler", "spool", "frame", "cabinet", "vanity", "worktop"]],
	[&"floor", ["floor"]],
	[&"plaster", ["paint", "wall", "plaster", "facade", "ceiling", "mass", "sas", "dirt", "pebble"]],
]

static var _textures := {}


## Enrichit tous les matériaux générés sous `root`. Renvoie le nombre de matériaux traités.
static func dress(root: Node) -> int:
	var count := 0
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if geometry.material_override:
			count += _dress_material(geometry.material_override)
		var mesh_instance := geometry as MeshInstance3D
		if mesh_instance and mesh_instance.mesh:
			for i in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_surface_override_material(i)
				if material == null:
					material = mesh_instance.mesh.surface_get_material(i)
				if material:
					count += _dress_material(material)
	return count


## Famille d'un identifiant de matériau (« Mat_wood_dark » → wood ; &"" si aucune).
static func family_of(material_id: String) -> StringName:
	var key := material_id.to_lower().trim_prefix("mat_")
	for entry in KEYWORDS:
		for word in entry[1]:
			if key.contains(word):
				return entry[0]
	return &""


static func _dress_material(material: Material) -> int:
	var standard := material as StandardMaterial3D
	if standard == null or standard.has_meta(&"nino_dressed"):
		return 0
	standard.set_meta(&"nino_dressed", true)
	var path := standard.resource_path
	var id := path.get_slice("::", 1) if path.contains("::") else standard.resource_name
	var family := family_of(id)
	if family == &"" or family == &"skip" or not FAMILIES.has(family):
		return 0
	if standard.albedo_texture or standard.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			or standard.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or standard.emission_enabled:
		return 0
	apply_family(standard, family)
	return 1


## Applique une famille à un matériau (aussi utilisable pour les matériaux créés en code).
static func apply_family(standard: StandardMaterial3D, family: StringName) -> void:
	var spec: Array = FAMILIES[family]
	var tile: float = spec[0]
	var color := standard.albedo_color
	var lift: float = spec[5]
	standard.albedo_color = Color(minf(color.r * lift, 1.0), minf(color.g * lift, 1.0), minf(color.b * lift, 1.0), color.a)
	standard.albedo_texture = _texture(family, "albedo")
	standard.normal_enabled = true
	standard.normal_texture = _texture(family, "normal")
	standard.normal_scale = spec[1]
	standard.roughness_texture = _texture(family, "rough")
	standard.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	standard.roughness = clampf(lerpf(spec[2], spec[3], standard.roughness), 0.05, 1.0)
	if spec[4] > 0.0:
		standard.metallic = maxf(standard.metallic, spec[4])
		standard.metallic_specular = 0.6
	standard.uv1_triplanar = true
	standard.uv1_triplanar_sharpness = 4.0
	standard.uv1_scale = Vector3.ONE / tile
	standard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	standard.set_meta(&"nino_family", family)


static func _texture(family: StringName, kind: String) -> Texture2D:
	var key := "%s_%s" % [family, kind]
	if not _textures.has(key):
		_textures[key] = load(DIR + key + ".png")
	return _textures[key]
