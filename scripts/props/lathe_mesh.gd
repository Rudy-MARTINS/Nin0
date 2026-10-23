@tool
class_name LatheMesh
extends MeshInstance3D
## Surface de révolution (axe Y) définie par un profil (rayon, hauteur). Ex. : tube en carton.

@export var profile := PackedVector2Array([Vector2(0.5, -0.5), Vector2(0.5, 0.5)]):
	set(value):
		profile = value
		_rebuild()
@export_range(6, 64) var segments := 24:
	set(value):
		segments = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if profile.size() >= 2:
		mesh = MeshFactory.lathe(profile, segments)


# Le maillage est régénéré au chargement : inutile de l'enregistrer dans la scène.
func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE
