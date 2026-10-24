@tool
class_name ResourcePickup
extends Area3D
## Ressource ordinaire ramassée en passant dessus : filament structurel (spirale orange,
## réparation et fabrication) ou plastique à munitions (billes bleues, canon).
## Les ressources ordinaires réapparaissent après `respawn_delay` secondes de jeu,
## loin du regard de Nin0 ; 0 = jamais. Chaque objet a un identifiant unique.

signal collected(pickup: ResourcePickup)

enum Kind { FILAMENT, PLASTIC }

@export var id: StringName
@export var kind := Kind.FILAMENT:
	set(value):
		kind = value
		_build()
@export var amount := 1
## Temps de jeu avant réapparition (s). 0 = objet unique.
@export var respawn_delay := 300.0
## Distance minimale de Nin0 pour réapparaître (pas sous son nez).
@export var respawn_distance := 8.0
@export var color := Color(0.93, 0.55, 0.2):
	set(value):
		color = value
		_build()

var _visual: Node3D
var _time := 0.0
var _check := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"resource_pickups")
	_time = randf() * TAU
	_check = randf() * 2.0
	body_entered.connect(_on_body_entered)
	refresh()


func resource_kind() -> StringName:
	return GameState.RESOURCE_PLASTIC if kind == Kind.PLASTIC else GameState.RESOURCE_FILAMENT


## Visible si la ressource est disponible (jamais prise ou réapparue).
func refresh() -> void:
	var available := GameState.is_pickup_available(id, respawn_delay)
	visible = available
	set_deferred("monitoring", available)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _visual == null:
		return
	if visible:
		_time += delta
		_visual.rotation.y += delta * 0.8
		_visual.position.y = 0.06 + sin(_time * 2.2) * 0.012
	elif respawn_delay > 0.0:
		_check -= delta
		if _check <= 0.0:
			_check = 2.0
			_try_respawn()


func _try_respawn() -> void:
	if not GameState.is_pickup_available(id, respawn_delay):
		return
	var nino := get_tree().get_first_node_in_group(&"nino") as Node3D
	if nino and nino.global_position.distance_to(global_position) < respawn_distance:
		return
	refresh()


func _on_body_entered(body: Node3D) -> void:
	if not body is NinoController or not visible:
		return
	if GameState.collect_resource(id, resource_kind(), amount, respawn_delay):
		visible = false
		set_deferred("monitoring", false)
		Sfx.play(&"fragment" if kind == Kind.FILAMENT else &"pickup", -6.0, 1.0 if kind == Kind.FILAMENT else 1.3)
		collected.emit(self)


func _build() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child.has_meta("generated"):
			child.free()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	shape.shape = sphere
	shape.position = Vector3(0.0, 0.2, 0.0)
	shape.set_meta("generated", true)
	add_child(shape)
	_visual = _build_filament() if kind == Kind.FILAMENT else _build_plastic()
	_visual.position = Vector3(0.0, 0.06, 0.0)
	_visual.set_meta("generated", true)
	add_child(_visual)


func _material(c: Color, glow: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = c
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = c
	material.emission_energy_multiplier = glow
	return material


## Spirale de fil (quelques tours irréguliers).
func _build_filament() -> Node3D:
	var points := PackedVector3Array()
	for i in 34:
		var t := float(i) / 33.0
		var a := t * TAU * 2.6
		var r := 0.11 + 0.025 * sin(t * 9.0)
		points.append(Vector3(cos(a) * r, t * 0.07 + sin(a * 1.5) * 0.012, sin(a) * r))
	points.append(points[points.size() - 1] + Vector3(0.16, -0.03, 0.08))
	var coil := Cable.new()
	coil.material_override = _material(color, 0.6)
	coil.radius = 0.02
	coil.points = points
	return coil


## Petit tas de billes de plastique bleues, rondes et brillantes.
func _build_plastic() -> Node3D:
	var root := Node3D.new()
	var material := _material(Color(0.25, 0.6, 0.95), 0.45)
	material.roughness = 0.15
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.radial_segments = 12
	mesh.rings = 6
	for i in 5:
		var bead := MeshInstance3D.new()
		bead.mesh = mesh
		bead.material_override = material
		var a := TAU * i / 4.0
		bead.position = Vector3(cos(a) * 0.07, 0.0, sin(a) * 0.07) if i < 4 else Vector3(0.0, 0.07, 0.0)
		root.add_child(bead)
	return root
