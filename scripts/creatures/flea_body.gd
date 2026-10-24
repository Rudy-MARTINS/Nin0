@tool
class_name FleaBody
extends Node3D
## Corps de puce cartoon : corps ovale aplati sur les côtés, carapace brun-rouge
## luisante, petite tête, antennes courtes, deux grandes pattes arrière repliées en
## ressort (elles se compriment avant un saut), quatre petites pattes avant.
## Normalisé (longueur 1, tête vers -Z) ; `body_length` ≈ 0,2 u (agrandie pour la lisibilité).

@export var body_length := 0.2:
	set(value):
		body_length = value
		scale = Vector3.ONE * body_length

## 0..1 : compression des pattes arrière (préparation du saut).
var crouch := 0.0
## 0..1 : pattes tendues (en vol).
var stretch := 0.0
var motion_speed := 0.0

var _root: Node3D
var _hind: Array[Node3D] = []
var _front: Array[Node3D] = []
var _time := 0.0


func _ready() -> void:
	scale = Vector3.ONE * body_length
	_build()


func _material(color: Color, rough := 0.25, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.metallic = 0.15
	material.rim_enabled = true
	material.rim = 0.3
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.scale = radii * 2.0
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _build() -> void:
	for child in get_children():
		child.free()
	_hind.clear()
	_front.clear()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.4
	cylinder.height = 1.0
	cylinder.radial_segments = 5
	var shell := _material(Color(0.42, 0.16, 0.1))
	var dark := _material(Color(0.24, 0.09, 0.06), 0.4)
	var band := _material(Color(0.55, 0.24, 0.14), 0.2)
	var white := _material(Color(0.98, 0.97, 0.94), 0.3, true)
	var black := _material(Color(0.03, 0.03, 0.03), 0.2, true)
	_root = Node3D.new()
	add_child(_root)
	# Corps aplati latéralement, bombé, avec des bandes de segments.
	_part(_root, sphere, Vector3(0.0, 0.42, 0.08), Vector3(0.17, 0.3, 0.38), shell)
	for k in 3:
		_part(_root, sphere, Vector3(0.0, 0.5 + k * 0.03, -0.12 + k * 0.17), Vector3(0.175, 0.24, 0.05), band)
	# Tête et yeux (grands, cartoon), antennes courtes.
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.36, -0.32)
	_root.add_child(head)
	_part(head, sphere, Vector3.ZERO, Vector3(0.12, 0.13, 0.12), shell)
	for side in [-1.0, 1.0]:
		var eye := Vector3(side * 0.08, 0.04, -0.06)
		_part(head, sphere, eye, Vector3.ONE * 0.05, white)
		_part(head, sphere, eye + Vector3(side * 0.01, 0.0, -0.03), Vector3.ONE * 0.026, black)
		var antenna := _part(head, cylinder, Vector3(side * 0.06, 0.12, -0.08), Vector3(0.012, 0.08, 0.012), dark)
		antenna.rotation = Vector3(-0.5, 0.0, side * 0.4)
	# Pattes avant (quatre petites).
	for i in 2:
		for side in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.1, 0.3, -0.18 + i * 0.12)
			_root.add_child(leg)
			var seg := _part(leg, cylinder, Vector3(side * 0.05, -0.12, -0.02), Vector3(0.02, 0.14, 0.02), dark)
			seg.rotation.z = side * 0.35
			_front.append(leg)
	# Grandes pattes arrière : cuisse épaisse, tibia long, repliés en Z.
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(side * 0.14, 0.38, 0.22)
		_root.add_child(hip)
		var thigh := _part(hip, sphere, Vector3(side * 0.05, -0.05, 0.08), Vector3(0.07, 0.07, 0.17), dark)
		thigh.rotation.x = 0.6
		var knee := Node3D.new()
		knee.position = Vector3(side * 0.06, -0.12, 0.22)
		hip.add_child(knee)
		var shin := _part(knee, cylinder, Vector3(0.0, -0.12, -0.08), Vector3(0.025, 0.3, 0.025), dark)
		shin.rotation.x = -0.9
		hip.set_meta("side", side)
		_hind.append(hip)


func _process(delta: float) -> void:
	if _root == null:
		return
	_time += delta
	# Ressort : le corps s'abaisse, les cuisses se replient ; en vol, tout s'étire.
	_root.position.y = -crouch * 0.12 + sin(_time * 3.0) * 0.008
	_root.rotation.x = -crouch * 0.25 + stretch * 0.35
	for hip in _hind:
		hip.rotation.x = crouch * 0.7 - stretch * 0.9
	for i in _front.size():
		_front[i].rotation.x = sin(_time * 14.0 + i) * 0.2 * clampf(motion_speed, 0.0, 1.0) - stretch * 0.6
