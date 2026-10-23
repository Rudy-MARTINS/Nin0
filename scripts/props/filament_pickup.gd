@tool
class_name FilamentPickup
extends Area3D
## Fragment de filament : petit bout de fil enroulé, ramassé en passant dessus.
## Ressource simple (compteur), servant aux réparations et à la fabrication.
## Chaque fragment a un identifiant unique (sauvegarde : jamais ramassé deux fois).

signal collected(pickup: FilamentPickup)

@export var id: StringName
@export var amount := 1
@export var color := Color(0.93, 0.55, 0.2):
	set(value):
		color = value
		_build()

var _coil: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)
	refresh()


## Masque le fragment s'il a déjà été ramassé (chargement de sauvegarde).
func refresh() -> void:
	var taken := GameState.collected_pickups.has(id)
	visible = not taken
	set_deferred("monitoring", not taken)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _coil == null:
		return
	_time += delta
	_coil.rotation.y += delta * 0.8
	_coil.position.y = 0.06 + sin(_time * 2.2) * 0.012


func _on_body_entered(body: Node3D) -> void:
	if not body is NinoController or not visible:
		return
	if GameState.collect_fragment(id, amount):
		visible = false
		set_deferred("monitoring", false)
		Sfx.play(&"fragment", -6.0)
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
	# Spirale de fil (quelques tours irréguliers) et petit éclat lumineux.
	var points := PackedVector3Array()
	for i in 34:
		var t := float(i) / 33.0
		var a := t * TAU * 2.6
		var r := 0.11 + 0.025 * sin(t * 9.0)
		points.append(Vector3(cos(a) * r, t * 0.07 + sin(a * 1.5) * 0.012, sin(a) * r))
	points.append(points[points.size() - 1] + Vector3(0.16, -0.03, 0.08))
	var coil := Cable.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.6
	coil.material_override = material
	coil.radius = 0.02
	coil.points = points
	coil.position = Vector3(0.0, 0.06, 0.0)
	coil.set_meta("generated", true)
	add_child(coil)
	_coil = coil
