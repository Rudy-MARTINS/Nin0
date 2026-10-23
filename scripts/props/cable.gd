@tool
class_name Cable
extends MeshInstance3D
## Câble décoratif (sans collision) passant par des points de contrôle lissés.

@export var points := PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 0)]):
	set(value):
		points = value
		_rebuild()
@export var radius := 0.04:
	set(value):
		radius = value
		_rebuild()
## Nombre de subdivisions entre deux points de contrôle.
@export_range(1, 16) var smoothness := 6:
	set(value):
		smoothness = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if points.size() < 2:
		return
	var smooth := PackedVector3Array()
	var count := points.size()
	for i in count - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, count - 1)]
		for s in smoothness:
			var t := float(s) / smoothness
			smooth.append(p1.cubic_interpolate(p2, p0, p3, t))
	smooth.append(points[count - 1])
	mesh = MeshFactory.tube(smooth, radius, 8)


# Le maillage est régénéré au chargement : inutile de l'enregistrer dans la scène.
func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE
