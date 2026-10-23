@tool
class_name ProceduralMesh
extends MeshInstance3D
## Maillage simple généré par MeshFactory, visible dans l'éditeur.
## ROUNDED_BOX : boîte arrondie de taille `size`.
## CYLINDER : cylindre d'axe Y aux bords arrondis (x = diamètre, y = hauteur).

enum Kind { ROUNDED_BOX, CYLINDER }

@export var kind: Kind = Kind.ROUNDED_BOX:
	set(value):
		kind = value
		_rebuild()
@export var size := Vector3(0.1, 0.1, 0.1):
	set(value):
		size = value
		_rebuild()
@export var bevel := 0.02:
	set(value):
		bevel = value
		_rebuild()
@export_range(6, 64) var segments := 20:
	set(value):
		segments = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if kind == Kind.ROUNDED_BOX:
		mesh = MeshFactory.rounded_box(size, bevel)
	else:
		var radius := size.x * 0.5
		mesh = MeshFactory.lathe(MeshFactory.tire_profile(radius, size.y, minf(bevel, radius * 0.95)), segments)


# Le maillage est régénéré au chargement : inutile de l'enregistrer dans la scène.
func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE
