class_name LarvaDropper
extends Node3D
## Chute de larves depuis une galerie surélevée de la colonie (cause visible : amas sur
## la serviette, ouvrières qui transportent). Avant chaque chute : poussière qui tombe,
## bruissement et ombre au sol. La larve devient un obstacle temporaire qui gêne et
## ralentit Nin0 (jamais mortelle), puis repart. Nombre limité (aucune accumulation).

## Une larve est tombée tout près de Nin0.
signal landed_near(point: Vector3)

@export var interval := Vector2(3.5, 6.5)
@export var warning_time := 1.1
@export var max_active := 3
@export var larva_lifetime := 6.0
## Distance de Nin0 en dessous de laquelle les larves tombent.
@export var active_distance := 7.0
@export var drop_height := 4.0

var active: Array[Node3D] = []
var drops_started := 0
var _timer := 2.0
var _points: Array[Vector3] = []
var _nino: NinoController


func _ready() -> void:
	for child in $DropPoints.get_children():
		_points.append((child as Node3D).global_position)


func _physics_process(delta: float) -> void:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		return
	if GameState.hazards_suspended() or _points.is_empty() or _nino.global_position.distance_to(global_position) > active_distance:
		return
	_timer -= delta
	if _timer <= 0.0 and active.size() < max_active:
		_timer = randf_range(interval.x, interval.y)
		drop(_points[randi() % _points.size()])


## Déclenche une chute (annoncée) au point donné.
func drop(point: Vector3) -> void:
	drops_started += 1
	var warning := _make_warning(point)
	Sfx.play(&"larva_warn", -14.0)
	await get_tree().create_timer(warning_time).timeout
	if not is_inside_tree():
		return
	warning.queue_free()
	var larva := _make_larva()
	add_child(larva)
	larva.global_position = point + Vector3.UP * drop_height
	active.append(larva)
	var fall := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(larva, "global_position", point, 0.55)
	await fall.finished
	Sfx.play(&"larva_drop", -8.0, randf_range(0.9, 1.1))
	if _nino and _nino.global_position.distance_to(point) < 0.45 and not GameState.hazards_suspended():
		_nino.apply_slow(0.45, 1.2)
		landed_near.emit(point)
		var away := _nino.global_position - point
		away.y = 0.0
		_nino.velocity += (away.normalized() if away.length() > 0.01 else Vector3.FORWARD) * 1.5
	(larva.get_node("Shape") as CollisionShape3D).disabled = false
	await get_tree().create_timer(larva_lifetime).timeout
	if not is_instance_valid(larva):
		return
	var leave := create_tween()
	leave.tween_property(larva, "scale", Vector3.ONE * 0.1, 0.8)
	await leave.finished
	active.erase(larva)
	larva.queue_free()


func _make_warning(point: Vector3) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.global_position = point
	var dust := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.35, 0.25)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = material
	dust.mesh = quad
	dust.amount = 18
	dust.lifetime = 1.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.15
	dust.direction = Vector3.DOWN
	dust.gravity = Vector3(0.0, -4.0, 0.0)
	dust.position = Vector3.UP * drop_height
	root.add_child(dust)
	var shadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.22
	disc.bottom_radius = 0.22
	disc.height = 0.01
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0, 0, 0, 0.45)
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material = dark
	shadow.mesh = disc
	shadow.position = Vector3.UP * 0.015
	root.add_child(shadow)
	return root


func _make_larva() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.11
	capsule.height = 0.42
	shape.shape = capsule
	shape.rotation.x = PI * 0.5
	shape.position = Vector3(0.0, 0.1, 0.0)
	shape.disabled = true
	shape.name = "Shape"
	body.add_child(shape)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 0.93, 0.82)
	material.roughness = 0.4
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 5
	for k in 4:
		var segment := MeshInstance3D.new()
		segment.mesh = mesh
		segment.material_override = material
		var r := 0.11 - absf(k - 1.5) * 0.015
		segment.scale = Vector3(r, r * 0.9, r * 0.8) * 2.0
		segment.position = Vector3(0.0, 0.1, -0.15 + k * 0.1)
		body.add_child(segment)
	body.rotation.y = randf() * TAU
	return body
