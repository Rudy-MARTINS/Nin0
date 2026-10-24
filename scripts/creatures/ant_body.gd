@tool
class_name AntBody
extends Node3D
## Corps de fourmi cartoon, construit en code (visible dans l'éditeur) : tête, yeux
## expressifs, antennes articulées, mandibules, thorax, pétiole, abdomen et six pattes.
## Animations procédurales : marche tripode, balancement des antennes, inclinaison de
## tête, cabrage (préparation d'attaque), tremblement (surprise / panique).
##
## Dimensions normalisées (longueur 1, tête vers -Z comme Nin0) ; `body_length` règle la
## taille réelle. Ouvrière ≈ 1,8 cm, soldat ≈ 2,6 cm, reine ≈ 5 cm (1 unité = 10 cm).

enum Caste { WORKER, SOLDIER, QUEEN }

@export var caste := Caste.WORKER:
	set(value):
		caste = value
		_queue_build()
@export var body_length := 0.18:
	set(value):
		body_length = value
		scale = Vector3.ONE * body_length
@export var body_color := Color(0.55, 0.3, 0.2):
	set(value):
		body_color = value
		_queue_build()

## Vitesse de déplacement actuelle (u/s), fournie par le comportement : anime la marche.
var motion_speed := 0.0
## Inclinaison de la tête (radians), curiosité.
var head_tilt := 0.0
## 0..1 : cabrage avant (préparation d'une attaque).
var rear := 0.0
## 0..1 : agitation (antennes rapides, tremblement).
var excitement := 0.0

var _head: Node3D
var _thorax: Node3D
var _abdomen: Node3D
var _antennas: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _mandibles: Array[Node3D] = []
var _phase := 0.0
var _time := 0.0
var _build_queued := false
var _sphere: SphereMesh
var _cylinder: CylinderMesh


func _ready() -> void:
	scale = Vector3.ONE * body_length
	_build()


func get_head() -> Node3D:
	return _head


func _queue_build() -> void:
	if _build_queued or not is_inside_tree():
		return
	_build_queued = true
	_build.call_deferred()


func _material(color: Color, rough := 0.45, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.rim_enabled = true
	material.rim = 0.35
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.scale = radii * 2.0
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if caste == Caste.QUEEN else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _build() -> void:
	_build_queued = false
	for child in get_children():
		if child.has_meta("ant_part"):
			child.free()
	_antennas.clear()
	_legs.clear()
	_mandibles.clear()
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 14
	_sphere.rings = 7
	_cylinder = CylinderMesh.new()
	_cylinder.top_radius = 0.5
	_cylinder.bottom_radius = 0.5
	_cylinder.height = 1.0
	_cylinder.radial_segments = 6
	var body := _material(body_color)
	var dark := _material(body_color.darkened(0.35))
	var white := _material(Color(0.98, 0.97, 0.94), 0.3, true)
	var black := _material(Color(0.05, 0.04, 0.04), 0.2, true)
	var soldier := caste == Caste.SOLDIER
	var queen := caste == Caste.QUEEN

	var root := Node3D.new()
	root.name = "Body"
	root.set_meta("ant_part", true)
	add_child(root)

	_thorax = Node3D.new()
	_thorax.position = Vector3(0.0, 0.2, -0.1)
	root.add_child(_thorax)
	_part(_thorax, _sphere, Vector3.ZERO, Vector3(0.08, 0.08, 0.14) * (1.25 if soldier else 1.0), body)
	_part(root, _sphere, Vector3(0.0, 0.18, 0.04), Vector3(0.045, 0.045, 0.05), dark)

	_abdomen = Node3D.new()
	_abdomen.position = Vector3(0.0, 0.22, 0.22 if not queen else 0.3)
	root.add_child(_abdomen)
	var abdomen_radii := Vector3(0.15, 0.13, 0.2)
	if soldier:
		abdomen_radii = Vector3(0.16, 0.14, 0.19)
	if queen:
		abdomen_radii = Vector3(0.27, 0.22, 0.38)
	_part(_abdomen, _sphere, Vector3.ZERO, abdomen_radii, body)
	# Rayures claires sur l'abdomen (lisibilité, surtout la reine).
	for k in (3 if queen else 2):
		var band_color := Color(0.95, 0.68, 0.3) if queen else body_color.lightened(0.18)
		var band := _part(_abdomen, _sphere, Vector3(0.0, 0.005, -abdomen_radii.z * 0.35 + k * abdomen_radii.z * 0.35), Vector3(abdomen_radii.x * 1.01, abdomen_radii.y * 1.01, 0.02), _material(band_color))
		band.name = "Band%d" % k
	if queen:
		# Cicatrices d'ailes (une reine a perdu ses ailes) : petites lamelles translucides.
		var wing := _material(Color(0.9, 0.92, 0.95, 0.5), 0.2)
		wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for side in [-1.0, 1.0]:
			_part(_thorax, _sphere, Vector3(side * 0.07, 0.08, 0.05), Vector3(0.05, 0.01, 0.09), wing)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 0.24, -0.33)
	root.add_child(_head)
	var head_r := 0.14
	if soldier:
		head_r = 0.18
	if queen:
		head_r = 0.13
	_part(_head, _sphere, Vector3(0.0, 0.0, -0.04), Vector3(head_r * (1.25 if soldier else 1.0), head_r * 0.92, head_r), body)
	# Yeux cartoon : grands, blancs, pupilles noires (expressifs).
	for side in [-1.0, 1.0]:
		var eye_pos := Vector3(side * head_r * 0.58, head_r * 0.3, -head_r * 0.78)
		var eye_r := head_r * (0.42 if not soldier else 0.32)
		_part(_head, _sphere, eye_pos, Vector3.ONE * eye_r, white)
		_part(_head, _sphere, eye_pos + Vector3(side * eye_r * 0.12, eye_r * 0.05, -eye_r * 0.7), Vector3.ONE * eye_r * 0.5, black)
		if soldier:
			# Sourcils froncés : regard décidé.
			var brow := _part(_head, _sphere, eye_pos + Vector3(0.0, eye_r * 1.05, -eye_r * 0.2), Vector3(eye_r * 1.1, eye_r * 0.22, eye_r * 0.5), dark)
			brow.rotation.z = side * 0.45
		if queen:
			# Cils : expression marquée de la reine.
			var lash := _part(_head, _sphere, eye_pos + Vector3(side * eye_r * 0.6, eye_r * 0.9, -eye_r * 0.3), Vector3(eye_r * 0.5, eye_r * 0.12, eye_r * 0.3), black)
			lash.rotation.z = -side * 0.6
	# Antennes coudées : scape + flagelle.
	for side in [-1.0, 1.0]:
		var base := Node3D.new()
		base.position = Vector3(side * head_r * 0.35, head_r * 0.7, -head_r * 0.75)
		_head.add_child(base)
		var scape := _part(base, _cylinder, Vector3(0.0, 0.09, -0.02), Vector3(0.012, 0.09, 0.012), dark)
		scape.rotation.x = -0.3
		var elbow := Node3D.new()
		elbow.position = Vector3(0.0, 0.17, -0.06)
		base.add_child(elbow)
		var flagellum := _part(elbow, _cylinder, Vector3(0.0, 0.0, -0.12), Vector3(0.01, 0.12, 0.01), dark)
		flagellum.rotation.x = PI * 0.5 - 0.35
		_part(elbow, _sphere, Vector3(0.0, -0.04, -0.23), Vector3.ONE * 0.022, dark)
		base.rotation.z = side * 0.35
		_antennas.append(base)
		_antennas.append(elbow)
	# Mandibules.
	var mandible_len := 0.07
	if soldier:
		mandible_len = 0.16
	if queen:
		mandible_len = 0.08
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * head_r * 0.35, -head_r * 0.45, -head_r * 0.85)
		_head.add_child(pivot)
		var jaw := _part(pivot, _sphere, Vector3(-side * mandible_len * 0.25, 0.0, -mandible_len * 0.5), Vector3(0.025, 0.02, mandible_len * 0.5), _material(Color(0.9, 0.55, 0.2) if soldier else body_color.darkened(0.5)))
		jaw.rotation.y = side * 0.4
		_mandibles.append(pivot)
	# Six pattes : pivot à la hanche, cuisse vers l'extérieur, tibia vers le sol.
	var hips := [-0.18, -0.1, -0.02]
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = _thorax.position + Vector3(side * 0.06, -0.03, hips[i] + 0.1)
			root.add_child(leg)
			var spread := (i - 1) * 0.45
			leg.rotation.y = -side * spread
			# Cuisse vers le haut et l'extérieur, genou, tibia vers le sol en s'écartant.
			var femur := _part(leg, _cylinder, Vector3(side * 0.095, 0.055, 0.0), Vector3(0.026, 0.11, 0.026), dark)
			femur.rotation.z = -side * 1.05
			_part(leg, _sphere, Vector3(side * 0.19, 0.105, 0.0), Vector3.ONE * 0.03, dark)
			var tibia := _part(leg, _cylinder, Vector3(side * 0.255, -0.03, 0.0), Vector3(0.02, 0.15, 0.02), dark)
			tibia.rotation.z = side * 0.45
			_part(leg, _sphere, Vector3(side * 0.32, -0.165, 0.0), Vector3(0.03, 0.02, 0.035), dark)
			leg.set_meta("side", side)
			leg.set_meta("group", (i + (0 if side < 0.0 else 1)) % 2)
			leg.set_meta("base_yaw", leg.rotation.y)
			_legs.append(leg)


func _process(delta: float) -> void:
	if _head == null:
		return
	_time += delta
	var stride := 0.35
	_phase += absf(motion_speed) / maxf(body_length, 0.01) / stride * delta * TAU * 0.5
	var walking := clampf(absf(motion_speed) / maxf(body_length, 0.01) * 0.5, 0.0, 1.0)
	for leg in _legs:
		var group := float(leg.get_meta("group"))
		var swing := sin(_phase + group * PI)
		leg.rotation.y = float(leg.get_meta("base_yaw")) + swing * 0.35 * walking
		leg.rotation.x = maxf(0.0, cos(_phase + group * PI)) * -0.35 * walking
	var shake := sin(_time * 40.0) * 0.02 * excitement
	_thorax.position.y = 0.2 + absf(sin(_phase)) * 0.012 * walking
	_head.rotation.z = lerpf(_head.rotation.z, head_tilt + shake, 1.0 - exp(-8.0 * delta))
	_head.rotation.x = lerpf(_head.rotation.x, -rear * 0.5, 1.0 - exp(-10.0 * delta))
	rotation.x = -rear * 0.35
	_abdomen.rotation.x = sin(_time * 1.6) * 0.04 + rear * 0.25
	var antenna_speed := 3.0 + excitement * 14.0
	for i in _antennas.size():
		var node := _antennas[i]
		if i % 2 == 0:
			node.rotation.x = sin(_time * antenna_speed + i) * (0.18 + excitement * 0.3)
		else:
			node.rotation.x = sin(_time * antenna_speed * 1.3 + i * 0.7) * (0.25 + excitement * 0.35)
	var jaw := 0.15 + rear * 0.6 + excitement * 0.2 * sin(_time * 20.0)
	for i in _mandibles.size():
		_mandibles[i].rotation.y = (-1.0 if i == 0 else 1.0) * jaw
