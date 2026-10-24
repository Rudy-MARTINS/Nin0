@tool
class_name WaspBody
extends Node3D
## Corps de guêpe cartoon : tête aux grands yeux, mandibules, thorax, taille de guêpe,
## abdomen rayé jaune et noir terminé par un dard, quatre ailes translucides qui
## battent vite, six pattes pendantes. Normalisé (longueur 1, tête vers -Z).
## `anger` teinte l'abdomen en rouge orangé et accélère les ailes (colère, préparation).

@export var body_length := 0.35:
	set(value):
		body_length = value
		scale = Vector3.ONE * body_length

## 0..1 : colère (teinte, ailes plus rapides).
var anger := 0.0
## 0..1 : abdomen relevé vers l'avant (préparation d'un dard ou d'une pique).
var aim := 0.0
## Ailes repliées (au sol, KO).
var wings_folded := false

var _root: Node3D
var _abdomen: Node3D
var _wings: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _stripe_material: StandardMaterial3D
var _time := 0.0


func _ready() -> void:
	scale = Vector3.ONE * body_length
	_build()


func _material(color: Color, rough := 0.35, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
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
	_wings.clear()
	_legs.clear()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 7
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.35
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 8
	var yellow := _material(Color(0.98, 0.78, 0.12))
	var black := _material(Color(0.07, 0.06, 0.05), 0.3)
	_stripe_material = _material(Color(0.98, 0.78, 0.12))
	var eye_mat := _material(Color(0.05, 0.05, 0.06), 0.1)
	var shine := _material(Color(1, 1, 1), 0.2, true)
	var wing := _material(Color(0.85, 0.92, 1.0, 0.35), 0.05)
	wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wing.cull_mode = BaseMaterial3D.CULL_DISABLED
	_root = Node3D.new()
	add_child(_root)
	# Tête : grands yeux noirs brillants, face jaune, antennes coudées, mandibules.
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.02, -0.36)
	_root.add_child(head)
	_part(head, sphere, Vector3.ZERO, Vector3(0.13, 0.13, 0.11), yellow)
	for side in [-1.0, 1.0]:
		_part(head, sphere, Vector3(side * 0.085, 0.03, -0.03), Vector3(0.06, 0.09, 0.06), eye_mat)
		_part(head, sphere, Vector3(side * 0.095, 0.07, -0.08), Vector3.ONE * 0.018, shine)
		var antenna := _part(head, cylinder, Vector3(side * 0.05, 0.16, -0.06), Vector3(0.012, 0.1, 0.012), black)
		antenna.rotation = Vector3(-0.6, 0.0, side * 0.3)
		var jaw := _part(head, sphere, Vector3(side * 0.04, -0.1, -0.07), Vector3(0.03, 0.025, 0.04), black)
		jaw.rotation.y = side * 0.4
	# Thorax noir et jaune.
	_part(_root, sphere, Vector3(0.0, 0.03, -0.17), Vector3(0.13, 0.12, 0.15), black)
	_part(_root, sphere, Vector3(0.0, 0.11, -0.2), Vector3(0.08, 0.03, 0.06), yellow)
	# Taille fine puis abdomen rayé, dard.
	_abdomen = Node3D.new()
	_abdomen.position = Vector3(0.0, 0.0, -0.03)
	_root.add_child(_abdomen)
	_part(_abdomen, sphere, Vector3(0.0, 0.0, 0.03), Vector3(0.035, 0.035, 0.04), black)
	for k in 4:
		var z := 0.12 + k * 0.09
		var radius := 0.14 - absf(k - 1.2) * 0.022
		_part(_abdomen, sphere, Vector3(0.0, -0.02 * k, z), Vector3(radius, radius * 0.92, 0.06), _stripe_material if k % 2 == 0 else black)
	var sting := _part(_abdomen, cone, Vector3(0.0, -0.1, 0.5), Vector3(0.02, 0.07, 0.02), black)
	sting.rotation.x = -PI * 0.5 - 0.3
	# Ailes (deux paires).
	for side in [-1.0, 1.0]:
		for k in 2:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.06, 0.12, -0.2 + k * 0.08)
			_root.add_child(pivot)
			var blade := _part(pivot, sphere, Vector3(side * 0.18, 0.0, 0.08), Vector3(0.17 - k * 0.04, 0.005, 0.06), wing)
			blade.rotation.y = side * 0.4
			pivot.set_meta("side", side)
			_wings.append(pivot)
	# Pattes pendantes.
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.07, -0.06, -0.24 + i * 0.07)
			_root.add_child(leg)
			var seg := _part(leg, cylinder, Vector3(side * 0.03, -0.1, 0.02), Vector3(0.012, 0.12, 0.012), black)
			seg.rotation.z = side * 0.3
			_legs.append(leg)


func _process(delta: float) -> void:
	if _root == null:
		return
	_time += delta
	var beat := 0.0 if wings_folded else sin(_time * (70.0 + anger * 40.0)) * 0.6
	for wing in _wings:
		var side := float(wing.get_meta("side"))
		wing.rotation.z = side * (beat if not wings_folded else -0.2)
		wing.rotation.y = side * (0.0 if not wings_folded else 0.9)
	_abdomen.rotation.x = aim * 0.9 + sin(_time * 3.0) * 0.05
	_root.position.y = (0.0 if wings_folded else sin(_time * 6.0) * 0.03)
	for i in _legs.size():
		_legs[i].rotation.x = sin(_time * 4.0 + i) * 0.15
	_stripe_material.albedo_color = Color(0.98, 0.78, 0.12).lerp(Color(1.0, 0.35, 0.12), anger)
