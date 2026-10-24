@tool
class_name CannonModel
extends Node3D
## Canon à projectiles plastiques (modèle procédural) : petit, artisanal, imprimé.
## Coque claire comme Nin0, éléments orange, mécanique lisible : réservoir de billes
## transparent, ressort de propulsion, culasse, embout. Pointé vers -Z.

const SHELL := Color(0.93, 0.89, 0.8)
const ACCENT := Color(0.93, 0.48, 0.14)
const METAL := Color(0.55, 0.56, 0.6)

@export var length := 0.15:
	set(value):
		length = value
		_queue_build()

var _barrel: Node3D
var _build_queued := false


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if _build_queued or not is_inside_tree():
		return
	_build_queued = true
	(func() -> void:
		_build_queued = false
		_build()).call_deferred()


## Petit recul du canon au tir.
func recoil() -> void:
	if _barrel == null:
		return
	var tween := create_tween()
	tween.tween_property(_barrel, "position:z", length * 0.18, 0.04)
	tween.tween_property(_barrel, "position:z", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_muzzle() -> Vector3:
	return to_global(Vector3(0.0, 0.0, -length * 0.62))


func _material(color: Color, rough := 0.45, metal := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.roughness = rough
	material.metallic = metal
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _cyl(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, along_z := true) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	if along_z:
		node.rotation.x = PI * 0.5
	parent.add_child(node)
	return node


func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var shell := _material(SHELL, 0.38)
	var accent := _material(ACCENT, 0.45)
	var metal := _material(METAL, 0.3, 0.8)
	var clear := _material(Color(0.8, 0.9, 1.0), 0.1, 0.0, 0.35)
	var bead := _material(Color(0.3, 0.55, 0.95), 0.3)
	var l := length
	# Support (collier orange) qui se fixe sur l'épaule de Nin0.
	_box(self, Vector3(l * 0.32, l * 0.16, l * 0.36), Vector3(0.0, -l * 0.17, l * 0.05), accent)
	_cyl(self, l * 0.06, l * 0.3, Vector3(0.0, -l * 0.08, l * 0.05), metal, false)
	_barrel = Node3D.new()
	add_child(_barrel)
	# Culasse et corps.
	_cyl(_barrel, l * 0.15, l * 0.42, Vector3(0.0, 0.0, l * 0.12), shell)
	_cyl(_barrel, l * 0.16, l * 0.05, Vector3(0.0, 0.0, l * 0.34), accent)
	# Ressort de propulsion visible (anneaux métalliques).
	for i in 4:
		_cyl(_barrel, l * 0.1, l * 0.02, Vector3(0.0, 0.0, l * (0.28 - i * 0.07)), metal)
	# Tube.
	_cyl(_barrel, l * 0.085, l * 0.55, Vector3(0.0, 0.0, -l * 0.3), shell)
	_cyl(_barrel, l * 0.11, l * 0.07, Vector3(0.0, 0.0, -l * 0.56), accent)
	_cyl(_barrel, l * 0.05, l * 0.08, Vector3(0.0, 0.0, -l * 0.6), _material(Color(0.1, 0.1, 0.1), 0.8))
	# Réservoir de billes, transparent, sur le dessus.
	_cyl(_barrel, l * 0.11, l * 0.2, Vector3(0.0, l * 0.2, l * 0.12), clear, false)
	_cyl(_barrel, l * 0.12, l * 0.03, Vector3(0.0, l * 0.31, l * 0.12), accent, false)
	var sphere := SphereMesh.new()
	sphere.radius = l * 0.04
	sphere.height = l * 0.08
	for i in 5:
		var b := MeshInstance3D.new()
		b.mesh = sphere
		b.material_override = bead
		b.position = Vector3(cos(i * 1.3) * l * 0.05, l * (0.14 + (i % 2) * 0.06), l * 0.12 + sin(i * 1.3) * l * 0.05)
		_barrel.add_child(b)
	# Petite manivelle de réarmement (lisible, artisanale).
	_box(_barrel, Vector3(l * 0.04, l * 0.16, l * 0.04), Vector3(l * 0.17, -l * 0.02, l * 0.22), accent)
	_cyl(_barrel, l * 0.03, l * 0.08, Vector3(l * 0.17, -l * 0.1, l * 0.22), metal, false)
