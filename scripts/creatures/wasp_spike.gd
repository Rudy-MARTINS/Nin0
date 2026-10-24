class_name WaspSpike
extends Node3D
## Pique lancée par la grosse guêpe : trajectoire lisible (légère courbe), traînée,
## se plante dans le décor ou touche Nin0 (dégâts modérés), puis disparaît.

@export var damage := 10.0
var velocity := Vector3.ZERO
var gravity := 3.0
var _life := 4.0
var _stuck := false
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.035
	cone.height = 0.3
	cone.radial_segments = 6
	_mesh.mesh = cone
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.1, 0.08)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.15)
	material.emission_energy_multiplier = 0.8
	_mesh.material_override = material
	_mesh.rotation.x = -PI * 0.5
	add_child(_mesh)


func launch(from: Vector3, target: Vector3, speed := 9.0) -> void:
	global_position = from
	var to := target - from
	var time := to.length() / speed
	velocity = to / maxf(time, 0.05)
	velocity.y += 0.5 * gravity * time


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _stuck:
		return
	if GameState.hazards_suspended():
		queue_free()
		return
	velocity.y -= gravity * delta
	var next := global_position + velocity * delta
	var nino := get_tree().get_first_node_in_group(&"nino") as NinoController
	if nino and next.distance_to(nino.global_position + Vector3.UP * 0.3) < 0.35:
		var integrity := get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
		if integrity:
			integrity.hit(damage, &"physical", global_position)
		queue_free()
		return
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, next, 1))
	if not hit.is_empty():
		global_position = hit.position
		_stuck = true
		_life = 1.5
		Sfx.play(&"impact_small", -16.0, 0.8)
		return
	if velocity.length() > 0.01:
		look_at(global_position + velocity)
	global_position = next
