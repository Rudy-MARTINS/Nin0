class_name AntWorker
extends Node3D
## Fourmi ouvrière : inoffensive. Elle marche, transporte, fait des pauses, échange
## avec ses voisines et réagit ponctuellement à Nin0 (arrêt, tête inclinée, antennes).
## Pilotée par une AntColumn (le long d'un chemin) ou par une séquence scriptée.
## Analysable avec la vision focalisée (FocusTarget « Fourmi ouvrière »).

const SPECIES: SpeciesData = preload("res://assets/species/ant_worker.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")
const CARRY_COLORS := [Color(0.95, 0.9, 0.75), Color(0.45, 0.6, 0.3), Color(0.6, 0.5, 0.4)]

## Vitesse propre de cette fourmi (u/s).
var speed := 0.35
## Arrêt temporaire (pause, curiosité) : la fourmi ne progresse pas.
var paused := 0.0
var react_cooldown := 0.0
var carrying := false

var body: AntBody
var focus: FocusTarget
var _carry: MeshInstance3D
var _look_at: Variant = null


func _init() -> void:
	body = AntBody.new()
	body.caste = AntBody.Caste.WORKER
	body.body_length = randf_range(0.17, 0.2)
	body.body_color = Color(0.55, 0.3, 0.2).lerp(Color(0.42, 0.24, 0.16), randf())
	add_child(body)
	focus = FocusTarget.new()
	focus.id = &"ant_worker"
	focus.radius = 0.12
	focus.profile = PROFILE
	focus.species = SPECIES
	focus.thought_icons = [&"ant", &"eye"]
	focus.position = Vector3(0.0, 0.05, -0.05)
	add_child(focus)


func set_carrying(value: bool) -> void:
	carrying = value
	if value and _carry == null:
		_carry = MeshInstance3D.new()
		if randf() < 0.5:
			var box := BoxMesh.new()
			box.size = Vector3(0.05, 0.03, 0.04)
			_carry.mesh = box
		else:
			var sphere := SphereMesh.new()
			sphere.radius = 0.025
			sphere.height = 0.045
			_carry.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = CARRY_COLORS[randi() % CARRY_COLORS.size()]
		_carry.material_override = material
		_carry.position = Vector3(0.0, 0.05, -0.1)
		add_child(_carry)
	if _carry:
		_carry.visible = value


## Réagit à Nin0 tout proche : s'arrête, le regarde, incline la tête (pas d'attaque).
func react_to(point: Vector3, duration := 1.4) -> void:
	paused = maxf(paused, duration)
	react_cooldown = duration + randf_range(5.0, 9.0)
	_look_at = point
	body.excitement = 0.7
	body.head_tilt = randf_range(0.25, 0.4) * (1.0 if randf() < 0.5 else -1.0)
	if randf() < 0.7:
		Sfx.play(&"ant_chitter", -18.0, randf_range(0.9, 1.2))


## Avance d'un pas : renvoie la distance réellement parcourue.
func tick(delta: float) -> float:
	react_cooldown = maxf(react_cooldown - delta, 0.0)
	if paused > 0.0:
		paused -= delta
		body.motion_speed = 0.0
		if _look_at != null:
			var to: Vector3 = (_look_at as Vector3) - global_position
			to.y = 0.0
			if to.length() > 0.01:
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-6.0 * delta))
		if paused <= 0.0:
			_look_at = null
			body.excitement = 0.0
			body.head_tilt = 0.0
		return 0.0
	body.motion_speed = speed
	return speed * delta


func face_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length() > 0.0001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-10.0 * delta))
