@tool
class_name SpiderBody
extends Node3D
## Corps d'araignée cartoon, construit en code : céphalothorax, gros abdomen rayé,
## deux grands yeux expressifs et quatre petits, chélicères, pédipalpes, huit pattes
## articulées en arc. Animations procédurales : marche en alternance, attente
## frémissante, pattes avant levées (préparation d'attaque), agitation.
##
## Dimensions normalisées (longueur du corps 1, avant vers -Z comme Nin0) ;
## `body_length` règle la taille réelle (araignée domestique ≈ 2 à 3 cm de corps).

@export var body_length := 0.25:
	set(value):
		body_length = value
		scale = Vector3.ONE * body_length
@export var body_color := Color(0.22, 0.17, 0.14):
	set(value):
		body_color = value
		_queue_build()
@export var pattern_color := Color(0.62, 0.48, 0.32):
	set(value):
		pattern_color = value
		_queue_build()

## Vitesse de déplacement actuelle (u/s), fournie par le comportement.
var motion_speed := 0.0
## 0..1 : pattes avant levées (préparation d'attaque).
var rear := 0.0
## 0..1 : agitation (frémissement, pattes nerveuses).
var excitement := 0.0
## Regard : inclinaison du corps (curiosité, guet).
var head_tilt := 0.0

var _root: Node3D
var _abdomen: Node3D
var _legs: Array[Node3D] = []
var _fangs: Array[Node3D] = []
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


func _material(color: Color, rough := 0.5, unshaded := false) -> StandardMaterial3D:
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
	_build_queued = false
	for child in get_children():
		if child.has_meta("spider_part"):
			child.free()
	_legs.clear()
	_fangs.clear()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 7
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.42
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var body := _material(body_color)
	var dark := _material(body_color.darkened(0.4))
	var pattern := _material(pattern_color)
	var white := _material(Color(0.98, 0.97, 0.94), 0.3, true)
	var black := _material(Color(0.03, 0.03, 0.03), 0.2, true)

	_root = Node3D.new()
	_root.set_meta("spider_part", true)
	add_child(_root)
	# Céphalothorax.
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.3, -0.18)
	_root.add_child(head)
	_part(head, sphere, Vector3.ZERO, Vector3(0.19, 0.14, 0.22), body)
	# Yeux : deux grands (cartoon) et quatre petits au-dessus.
	for side in [-1.0, 1.0]:
		var eye := Vector3(side * 0.085, 0.07, -0.18)
		_part(head, sphere, eye, Vector3.ONE * 0.07, white)
		_part(head, sphere, eye + Vector3(side * 0.008, -0.005, -0.05), Vector3.ONE * 0.038, black)
		for k in 2:
			_part(head, sphere, Vector3(side * (0.04 + k * 0.07), 0.14, -0.12), Vector3.ONE * 0.022, black)
	# Chélicères (crocs) et pédipalpes.
	for side in [-1.0, 1.0]:
		var fang := Node3D.new()
		fang.position = Vector3(side * 0.05, -0.06, -0.2)
		head.add_child(fang)
		_part(fang, sphere, Vector3(0.0, -0.03, -0.02), Vector3(0.035, 0.05, 0.035), dark)
		_fangs.append(fang)
		var palp := _part(head, cylinder, Vector3(side * 0.11, -0.02, -0.22), Vector3(0.018, 0.07, 0.018), body)
		palp.rotation.x = -1.1
	# Abdomen rond, motif en chevrons.
	_abdomen = Node3D.new()
	_abdomen.position = Vector3(0.0, 0.36, 0.24)
	_root.add_child(_abdomen)
	_part(_abdomen, sphere, Vector3.ZERO, Vector3(0.27, 0.23, 0.32), body)
	for k in 3:
		var chevron := _part(_abdomen, sphere, Vector3(0.0, 0.19 - k * 0.015, -0.12 + k * 0.12), Vector3(0.11 - k * 0.02, 0.035, 0.045), pattern)
		chevron.rotation.x = 0.25
	# Huit pattes : coxa, fémur en arc haut, tibia vers le sol.
	var hips := [-0.28, -0.2, -0.12, -0.04]
	for i in 4:
		for side in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.12, 0.3, hips[i])
			_root.add_child(leg)
			leg.rotation.y = -side * (0.9 - i * 0.55)
			var femur := _part(leg, cylinder, Vector3(side * 0.2, 0.14, 0.0), Vector3(0.028, 0.26, 0.028), dark)
			femur.rotation.z = -side * 0.95
			_part(leg, sphere, Vector3(side * 0.4, 0.27, 0.0), Vector3.ONE * 0.034, dark)
			var tibia := _part(leg, cylinder, Vector3(side * 0.53, 0.0, 0.0), Vector3(0.022, 0.32, 0.022), dark)
			tibia.rotation.z = side * 0.42
			_part(leg, sphere, Vector3(side * 0.64, -0.28, 0.0), Vector3.ONE * 0.022, body)
			leg.set_meta("side", side)
			leg.set_meta("index", i)
			leg.set_meta("group", (i + (0 if side < 0.0 else 1)) % 2)
			leg.set_meta("base_yaw", leg.rotation.y)
			_legs.append(leg)


func _process(delta: float) -> void:
	if _root == null:
		return
	_time += delta
	_phase += absf(motion_speed) / maxf(body_length, 0.01) * 2.2 * delta
	var walking := clampf(absf(motion_speed) / maxf(body_length, 0.01) * 0.4, 0.0, 1.0)
	for leg in _legs:
		var group := float(leg.get_meta("group"))
		var index := int(leg.get_meta("index"))
		var swing := sin(_phase + group * PI)
		var lift := 0.0
		# Pattes avant levées pendant la préparation d'une attaque.
		if index == 0:
			lift = rear * 0.9
		leg.rotation.y = float(leg.get_meta("base_yaw")) + swing * 0.3 * walking + sin(_time * 30.0 + index) * 0.03 * excitement
		leg.rotation.x = maxf(0.0, cos(_phase + group * PI)) * -0.3 * walking - lift
	_root.position.y = absf(sin(_phase * 2.0)) * 0.015 * walking + sin(_time * 2.0) * 0.006
	_root.rotation.x = -rear * 0.3
	_root.rotation.z = lerpf(_root.rotation.z, head_tilt, 1.0 - exp(-6.0 * delta))
	_abdomen.rotation.x = sin(_time * 1.3) * 0.05
	var bite := 0.2 + rear * 0.6 + excitement * 0.2 * sin(_time * 22.0)
	for i in _fangs.size():
		_fangs[i].rotation.x = bite
