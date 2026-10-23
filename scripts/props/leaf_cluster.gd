@tool
class_name LeafCluster
extends MeshInstance3D
## Végétation stylisée générée (plante en pot, touffes d'herbe, lierre, feuilles mortes).
## Toutes les feuilles sont fusionnées en un seul maillage. Décor uniquement (sans collision).

@export var count := 12:
	set(value):
		count = value
		_rebuild()
## Hauteur occupée par les feuilles.
@export var height := 1.0:
	set(value):
		height = value
		_rebuild()
## Rayon (ou demi-largeur) de la zone couverte.
@export var spread := 0.5:
	set(value):
		spread = value
		_rebuild()
@export var leaf_length := 1.0:
	set(value):
		leaf_length = value
		_rebuild()
@export var leaf_width := 0.4:
	set(value):
		leaf_width = value
		_rebuild()
## Brins dressés (herbe).
@export var upright := false:
	set(value):
		upright = value
		_rebuild()
## Feuilles plaquées contre un mur orienté vers +X (lierre).
@export var flat_wall := false:
	set(value):
		flat_wall = value
		_rebuild()
## Feuilles posées au sol (feuilles mortes).
@export var lying := false:
	set(value):
		lying = value
		_rebuild()
@export var material: Material:
	set(value):
		material = value
		material_override = value
@export var random_seed := 1:
	set(value):
		random_seed = value
		_rebuild()


func _ready() -> void:
	material_override = material
	_rebuild()


func _rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var t := (float(i) + 0.5) / maxf(count, 1)
		var size := rng.randf_range(0.75, 1.15)
		var leaf := MeshFactory.leaf(leaf_length * size, leaf_width * size)
		var xform: Transform3D
		if lying:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * spread
			xform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(cos(a) * r, 0.0, sin(a) * r))
		elif upright:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * spread
			var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, -PI * 0.5 + rng.randf_range(-0.35, 0.35))
			xform = Transform3D(basis, Vector3(cos(a) * r, 0.0, sin(a) * r))
		elif flat_wall:
			var basis := Basis(Vector3.RIGHT, rng.randf() * TAU) * Basis(Vector3.BACK, -PI * 0.5)
			xform = Transform3D(basis, Vector3(rng.randf_range(0.0, 0.05), t * height, rng.randf_range(-spread, spread)))
		else:
			# Plante en pot : feuilles en spirale sur de fines tiges.
			var a := i * 2.39996
			var base := Vector3(cos(a), 0.0, sin(a)) * spread * 0.15 * t + Vector3.UP * (0.15 + 0.85 * t) * height
			var pitch := lerpf(0.9, 0.15, t) + rng.randf_range(-0.2, 0.2)
			var basis := Basis(Vector3.UP, atan2(cos(a), sin(a))) * Basis(Vector3.RIGHT, -pitch)
			xform = Transform3D(basis, base)
			var stem := MeshFactory.tube(PackedVector3Array([Vector3.ZERO, base * Vector3(0.5, 0.6, 0.5), base]), 0.035 * height / 3.0 + 0.01, 4)
			tool.append_from(stem, 0, Transform3D.IDENTITY)
		tool.append_from(leaf, 0, xform)
	mesh = tool.commit()


# Le maillage est régénéré au chargement : inutile de l'enregistrer dans la scène.
func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE
