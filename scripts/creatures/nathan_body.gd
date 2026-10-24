@tool
class_name NathanBody
extends Node3D
## Nathan (lot 7) : figurine articulée originale, deux fois plus grande que Nin0.
## Tête ronde peinte (grands yeux, sourcils, petit sourire), casquette d'explorateur,
## écharpe rouge, gilet orange à poches, pantalon bleu, chaussures marron. Articulations
## apparentes (rotules sombres aux épaules, coudes, hanches, genoux) : il bouge par petits
## à-coups, comme un jouet. Hauteur ≈ 1,3 u, face vers -Z.

## 0..1 : allure de marche (balancement des bras et des jambes).
var gait := 0.0
## 0..1 : assis (jambes à l'horizontale).
var sit := 0.0
## 0..1 : allongé sur le dos, inerte (avant d'être scanné).
var dormant := 0.0
## Bras droit levé pour montrer une direction (0..1) ; direction en coordonnées locales.
var point := 0.0
## Peur : bras devant le visage, tremblement.
var scared := 0.0
## Joie : petits sauts, bras levés.
var cheer := 0.0

var _root: Node3D
var _head: Node3D
var _eyes: Array[MeshInstance3D] = []
var _arms: Array[Node3D] = []
var _forearms: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _shins: Array[Node3D] = []
var _time := 0.0
var _blink := 0.0


func _ready() -> void:
	_build()


func _material(color: Color, rough := 0.45) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.rim_enabled = true
	material.rim = 0.25
	return material


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.scale = size
	parent.add_child(node)
	return node


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	parent.add_child(node)
	return node


func _build() -> void:
	for child in get_children():
		child.free()
	_eyes.clear()
	_arms.clear()
	_forearms.clear()
	_legs.clear()
	_shins.clear()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var box := BoxMesh.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	capsule.radial_segments = 10
	capsule.rings = 3
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	cylinder.radial_segments = 14
	var skin := _material(Color(0.96, 0.82, 0.66), 0.5)
	var vest := _material(Color(0.93, 0.52, 0.18))
	var shirt := _material(Color(0.95, 0.93, 0.86))
	var pants := _material(Color(0.24, 0.4, 0.68))
	var shoes := _material(Color(0.42, 0.27, 0.16))
	var scarf := _material(Color(0.82, 0.18, 0.16))
	var cap := _material(Color(0.72, 0.64, 0.42))
	var joint := _material(Color(0.3, 0.27, 0.25), 0.3)
	var ink := _material(Color(0.1, 0.08, 0.08), 0.2)
	var white := _material(Color(1, 1, 1), 0.2)
	_root = _pivot(self, Vector3.ZERO)
	# Bassin et torse (gilet sans manches sur chemise).
	var hips := _pivot(_root, Vector3(0.0, 0.58, 0.0))
	_part(hips, box, Vector3(0.0, 0.0, 0.0), Vector3(0.34, 0.14, 0.2), pants)
	var torso := _pivot(hips, Vector3(0.0, 0.07, 0.0))
	_part(torso, box, Vector3(0.0, 0.2, 0.0), Vector3(0.36, 0.36, 0.21), shirt)
	_part(torso, box, Vector3(0.0, 0.19, -0.005), Vector3(0.38, 0.34, 0.22), vest)
	_part(torso, box, Vector3(0.0, 0.19, -0.115), Vector3(0.06, 0.34, 0.01), shirt)
	for side in [-1.0, 1.0]:
		_part(torso, box, Vector3(side * 0.11, 0.12, -0.12), Vector3(0.1, 0.08, 0.02), _material(Color(0.8, 0.42, 0.12)))
	# Écharpe et cou.
	_part(torso, cylinder, Vector3(0.0, 0.42, 0.0), Vector3(0.26, 0.07, 0.24), scarf)
	var tail := _part(torso, box, Vector3(0.09, 0.32, -0.12), Vector3(0.07, 0.18, 0.02), scarf)
	tail.rotation.z = 0.25
	# Tête : peinte, grands yeux, sourcils, sourire ; casquette à visière.
	_head = _pivot(torso, Vector3(0.0, 0.48, 0.0))
	_part(_head, sphere, Vector3(0.0, 0.15, 0.0), Vector3(0.3, 0.3, 0.28), skin)
	for side in [-1.0, 1.0]:
		var eye := _part(_head, sphere, Vector3(side * 0.065, 0.17, -0.128), Vector3(0.06, 0.075, 0.03), ink)
		_eyes.append(eye)
		_part(_head, sphere, Vector3(side * 0.06, 0.19, -0.142), Vector3(0.02, 0.02, 0.01), white)
		var brow := _part(_head, box, Vector3(side * 0.065, 0.235, -0.13), Vector3(0.06, 0.012, 0.01), ink)
		brow.rotation.z = side * -0.12
		_part(_head, sphere, Vector3(side * 0.15, 0.15, 0.0), Vector3(0.04, 0.06, 0.04), skin)
	var smile := _part(_head, box, Vector3(0.0, 0.09, -0.135), Vector3(0.07, 0.012, 0.01), ink)
	smile.rotation.x = 0.2
	_part(_head, sphere, Vector3(0.0, 0.25, 0.0), Vector3(0.31, 0.16, 0.29), cap)
	_part(_head, box, Vector3(0.0, 0.27, -0.15), Vector3(0.2, 0.015, 0.1), cap)
	_part(_head, cylinder, Vector3(0.0, 0.29, 0.0), Vector3(0.32, 0.02, 0.3), _material(Color(0.5, 0.36, 0.2)))
	# Bras : rotule d'épaule, bras, rotule de coude, avant-bras, main.
	for side in [-1.0, 1.0]:
		var shoulder := _pivot(torso, Vector3(side * 0.21, 0.33, 0.0))
		_part(shoulder, sphere, Vector3.ZERO, Vector3.ONE * 0.075, joint)
		_part(shoulder, capsule, Vector3(side * 0.01, -0.09, 0.0), Vector3(0.065, 0.065, 0.065), shirt)
		var elbow := _pivot(shoulder, Vector3(side * 0.01, -0.18, 0.0))
		_part(elbow, sphere, Vector3.ZERO, Vector3.ONE * 0.06, joint)
		_part(elbow, capsule, Vector3(0.0, -0.08, 0.0), Vector3(0.055, 0.06, 0.055), skin)
		_part(elbow, sphere, Vector3(0.0, -0.17, 0.0), Vector3(0.07, 0.07, 0.06), skin)
		_arms.append(shoulder)
		_forearms.append(elbow)
	# Jambes : rotule de hanche, cuisse, genou, tibia, chaussure.
	for side in [-1.0, 1.0]:
		var hip := _pivot(hips, Vector3(side * 0.09, -0.05, 0.0))
		_part(hip, sphere, Vector3.ZERO, Vector3.ONE * 0.08, joint)
		_part(hip, capsule, Vector3(0.0, -0.12, 0.0), Vector3(0.08, 0.075, 0.08), pants)
		var knee := _pivot(hip, Vector3(0.0, -0.25, 0.0))
		_part(knee, sphere, Vector3.ZERO, Vector3.ONE * 0.07, joint)
		_part(knee, capsule, Vector3(0.0, -0.11, 0.0), Vector3(0.07, 0.07, 0.07), pants)
		_part(knee, box, Vector3(0.0, -0.24, -0.03), Vector3(0.1, 0.06, 0.16), shoes)
		_legs.append(hip)
		_shins.append(knee)


func _process(delta: float) -> void:
	if _root == null:
		return
	_time += delta
	# Clignement des yeux de temps en temps (sauf inerte).
	_blink -= delta
	if _blink <= 0.0:
		_blink = randf_range(2.5, 5.0)
	var closed := dormant > 0.5 or _blink < 0.12
	for eye in _eyes:
		eye.scale.y = 0.01 if closed else 0.075
	# Marche raide de jouet : balancement par à-coups (sinus « quantifié »).
	var swing := sin(_time * 8.0) * gait
	swing = round(swing * 4.0) / 4.0 * 0.6
	var jitter := sin(_time * 40.0) * 0.06 * scared
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var leg_angle := (swing * side) * (1.0 - sit) - sit * 1.5
		_legs[i].rotation.x = leg_angle
		_shins[i].rotation.x = maxf(-swing * side, 0.0) * 0.6 * (1.0 - sit) + sit * 1.5
		var arm := -swing * side * 0.8
		arm = lerpf(arm, -2.2, cheer) + jitter
		arm = lerpf(arm, -1.4, scared)
		_arms[i].rotation.x = arm
		_arms[i].rotation.z = side * (0.12 + cheer * 0.4 + scared * 0.3)
		_forearms[i].rotation.x = lerpf(-0.3, -1.6, scared)
	# Bras droit qui montre (le long de -Z local, levé).
	if point > 0.0:
		_arms[1].rotation.x = lerpf(_arms[1].rotation.x, -1.6, point)
		_arms[1].rotation.z = lerpf(_arms[1].rotation.z, 0.2, point)
		_forearms[1].rotation.x = lerpf(_forearms[1].rotation.x, 0.0, point)
	_head.rotation.z = sin(_time * 1.3) * 0.05 * (1.0 - dormant) + jitter
	_root.position.y = (absf(sin(_time * 8.0)) * 0.03 * gait + absf(sin(_time * 10.0)) * 0.12 * cheer) * (1.0 - sit) - sit * 0.33
	# Inerte : allongé sur le dos.
	_root.rotation.x = dormant * (PI * 0.5)
	_root.position.z = dormant * 0.0
	if dormant > 0.0:
		_root.position.y = lerpf(_root.position.y, 0.12, dormant)
