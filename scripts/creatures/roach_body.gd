@tool
class_name RoachBody
extends Node3D
## Corps de cafard des bois cartoon : corps plat et ovale, bouclier du pronotum, élytres
## brillants, longues antennes souples, cerques, six pattes épineuses, petits yeux
## expressifs. Animations : marche rapide en trépied, antennes qui fouettent, tête qui
## se lève (alerte), corps qui tremble (peur), cabrage défensif.
##
## Normalisé (longueur 1, tête vers -Z) ; `body_length` ≈ 0,2 à 0,3 u (2 à 3 cm).

@export var body_length := 0.26:
	set(value):
		body_length = value
		scale = Vector3.ONE * body_length
@export var body_color := Color(0.42, 0.24, 0.12):
	set(value):
		body_color = value
		_queue_build()

var motion_speed := 0.0
## 0..1 : cabrage défensif.
var rear := 0.0
## 0..1 : peur / agitation.
var excitement := 0.0
var head_tilt := 0.0

var _root: Node3D
var _antennas: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _phase := 0.0
var _time := 0.0
var _build_queued := false


func _ready() -> void:
	scale = Vector3.ONE * body_length
	_build()


func _queue_build() -> void:
	if _build_queued or not is_inside_tree():
		return
	_build_queued = true
	_build.call_deferred()


func _material(color: Color, rough := 0.3, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.metallic = 0.1
	material.rim_enabled = true
	material.rim = 0.25
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
	_build_queued = false
	for child in get_children():
		if child.has_meta("roach_part"):
			child.free()
	_antennas.clear()
	_legs.clear()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 7
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.4
	cylinder.height = 1.0
	cylinder.radial_segments = 5
	var body := _material(body_color)
	var shell := _material(body_color.lightened(0.12), 0.18)
	var dark := _material(body_color.darkened(0.45))
	var edge := _material(Color(0.78, 0.6, 0.38), 0.3)
	var white := _material(Color(0.98, 0.97, 0.94), 0.3, true)
	var black := _material(Color(0.03, 0.03, 0.03), 0.2, true)
	_root = Node3D.new()
	_root.set_meta("roach_part", true)
	add_child(_root)
	# Corps plat : abdomen, élytres (deux coques), pronotum (bouclier) bordé de clair.
	_part(_root, sphere, Vector3(0.0, 0.12, 0.12), Vector3(0.2, 0.07, 0.36), body)
	for side in [-1.0, 1.0]:
		var wing := _part(_root, sphere, Vector3(side * 0.07, 0.17, 0.12), Vector3(0.13, 0.05, 0.33), shell)
		wing.rotation.y = side * 0.08
	_part(_root, sphere, Vector3(0.0, 0.16, -0.22), Vector3(0.21, 0.055, 0.13), edge)
	_part(_root, sphere, Vector3(0.0, 0.175, -0.22), Vector3(0.18, 0.05, 0.11), shell)
	# Tête sous le pronotum, petits yeux expressifs.
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.11, -0.36)
	_root.add_child(head)
	_part(head, sphere, Vector3.ZERO, Vector3(0.09, 0.07, 0.07), dark)
	for side in [-1.0, 1.0]:
		var eye := Vector3(side * 0.06, 0.03, -0.04)
		_part(head, sphere, eye, Vector3.ONE * 0.035, white)
		_part(head, sphere, eye + Vector3(0.0, 0.0, -0.025), Vector3.ONE * 0.018, black)
	# Longues antennes souples (trois segments).
	for side in [-1.0, 1.0]:
		var base := Node3D.new()
		base.position = Vector3(side * 0.04, 0.05, -0.06)
		head.add_child(base)
		base.rotation.y = side * 0.35
		var node := base
		for k in 3:
			var seg := _part(node, cylinder, Vector3(0.0, 0.0, -0.17), Vector3(0.008, 0.17, 0.008), dark)
			seg.rotation.x = PI * 0.5
			var next := Node3D.new()
			next.position = Vector3(0.0, 0.0, -0.34)
			node.add_child(next)
			_antennas.append(node)
			node = next
	# Cerques.
	for side in [-1.0, 1.0]:
		var cercus := _part(_root, cylinder, Vector3(side * 0.06, 0.12, 0.5), Vector3(0.012, 0.08, 0.012), dark)
		cercus.rotation.x = PI * 0.5 + 0.2
		cercus.rotation.z = side * 0.3
	# Six pattes épineuses, étalées.
	var hips := [-0.2, -0.02, 0.16]
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.12, 0.1, hips[i])
			_root.add_child(leg)
			leg.rotation.y = -side * (0.7 - i * 0.7)
			var femur := _part(leg, cylinder, Vector3(side * 0.12, 0.04, 0.0), Vector3(0.022, 0.15, 0.022), dark)
			femur.rotation.z = -side * 1.2
			var tibia := _part(leg, cylinder, Vector3(side * 0.28, -0.04, 0.0), Vector3(0.016, 0.2, 0.016), dark)
			tibia.rotation.z = side * 0.75
			for k in 2:
				var spine := _part(leg, cylinder, Vector3(side * (0.24 + k * 0.06), 0.0 - k * 0.03, 0.0), Vector3(0.005, 0.03, 0.005), dark)
				spine.rotation.z = side * 0.2
			leg.set_meta("group", (i + (0 if side < 0.0 else 1)) % 2)
			leg.set_meta("base_yaw", leg.rotation.y)
			_legs.append(leg)


func _process(delta: float) -> void:
	if _root == null:
		return
	_time += delta
	_phase += absf(motion_speed) / maxf(body_length, 0.01) * 3.0 * delta
	var walking := clampf(absf(motion_speed) / maxf(body_length, 0.01) * 0.3, 0.0, 1.0)
	for leg in _legs:
		var group := float(leg.get_meta("group"))
		var swing := sin(_phase + group * PI)
		leg.rotation.y = float(leg.get_meta("base_yaw")) + swing * 0.4 * walking
		leg.rotation.x = maxf(0.0, cos(_phase + group * PI)) * -0.3 * walking
	_root.position.y = sin(_time * 45.0) * 0.006 * excitement
	_root.rotation.x = -rear * 0.4
	_root.rotation.z = lerpf(_root.rotation.z, head_tilt, 1.0 - exp(-8.0 * delta))
	var whip := 4.0 + excitement * 16.0
	for i in _antennas.size():
		_antennas[i].rotation.y = sin(_time * whip + i * 0.9) * (0.15 + excitement * 0.2)
		_antennas[i].rotation.x = sin(_time * whip * 0.7 + i) * 0.1
