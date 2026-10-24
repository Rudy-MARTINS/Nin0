class_name AntSoldier
extends CharacterBody3D
## Fourmi soldat : garde une galerie. Patrouille, détecte Nin0 (vue, distance, même
## niveau), le poursuit à la vitesse du mode jambes, prépare puis porte une morsure
## esquivable, récupère, perd sa trace et revient patrouiller.
## Touchée par les billes du canon : recule, puis fuit quand elle n'en peut plus ; elle
## revient plus tard (ennemi ordinaire). Ne bloque jamais physiquement Nin0.

signal alerted(soldier: AntSoldier)
signal lost_track(soldier: AntSoldier)

enum State { PATROL, ALERT, CHASE, WINDUP, ATTACK, RECOVER, SEARCH, RETURN, STAGGER, FLEE, AWAY }

const SPECIES: SpeciesData = preload("res://assets/species/ant_soldier.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

## Points de patrouille (coordonnées globales), parcourus en boucle.
@export var patrol_points: PackedVector3Array = []
@export var patrol_speed := 0.7
## Vitesse de poursuite ≈ Nin0 en mode jambes (1,8 u/s).
@export var chase_speed := 1.75
@export var detect_range := 4.0
@export var detect_angle := 75.0
@export var attack_range := 0.6
@export var bite_damage := 14.0
@export var windup_time := 0.55
@export var recover_time := 0.9
@export var lose_time := 2.2
@export var max_health := 3
@export var respawn_time := 45.0
@export var gravity := 25.0

var state := State.PATROL
var health := 3
var body: AntBody

var _target_index := 0
var _timer := 0.0
var _unseen := 0.0
var _stuck := 0.0
var _last_position := Vector3.ZERO
var _nino: NinoController
var _integrity: NinoIntegrity
var _emote: Label3D
var _home: Vector3
var _hit_done := false
var _calm := 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	floor_snap_length = 0.1
	health = max_health
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.09
	capsule.height = 0.26
	shape.shape = capsule
	shape.rotation.x = PI * 0.5
	shape.position = Vector3(0.0, 0.09, 0.0)
	add_child(shape)
	body = AntBody.new()
	body.caste = AntBody.Caste.SOLDIER
	body.body_length = 0.26
	body.body_color = Color(0.36, 0.15, 0.11)
	add_child(body)
	var focus := FocusTarget.new()
	focus.id = &"ant_soldier"
	focus.radius = 0.16
	focus.profile = PROFILE
	focus.species = SPECIES
	focus.thought_icons = [&"ant_soldier", &"exclamation"]
	focus.position = Vector3(0.0, 0.08, -0.08)
	add_child(focus)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 64
	_emote.pixel_size = 0.004
	_emote.outline_size = 12
	_emote.modulate = Color(1.0, 0.45, 0.3)
	_emote.position = Vector3(0.0, 0.32, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	_home = global_position
	if patrol_points.is_empty():
		patrol_points = PackedVector3Array([global_position])
	_last_position = global_position


func is_engaged() -> bool:
	return state in [State.ALERT, State.CHASE, State.WINDUP, State.ATTACK, State.RECOVER]


## Remet le soldat à son poste (réinitialisation de zone, réapparition).
## Ignore Nin0 un instant (retour au point sûr après une mise en veille).
func calm(seconds: float) -> void:
	_calm = seconds


func reset_to_post() -> void:
	health = max_health
	global_position = patrol_points[0] if not patrol_points.is_empty() else _home
	velocity = Vector3.ZERO
	visible = true
	collision_layer = 16
	_set_state(State.PATROL)


func _physics_process(delta: float) -> void:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
		if _nino == null:
			return
	_timer -= delta
	_calm = maxf(_calm - delta, 0.0)
	var desired := Vector3.ZERO
	var speed := 0.0
	match state:
		State.PATROL:
			if _can_see_nino():
				_alert()
			else:
				desired = _toward(patrol_points[_target_index])
				speed = patrol_speed
				if _flat_distance(patrol_points[_target_index]) < 0.15:
					_target_index = (_target_index + 1) % patrol_points.size()
		State.ALERT:
			_face(_nino.global_position, delta)
			if _timer <= 0.0:
				_set_state(State.CHASE)
		State.CHASE:
			if _can_see_nino(true):
				_unseen = 0.0
			else:
				_unseen += delta
			if _unseen > lose_time or _flat_distance(_nino.global_position) > detect_range * 2.0:
				_set_state(State.SEARCH)
			elif _flat_distance(_nino.global_position) < attack_range and _same_level():
				_set_state(State.WINDUP)
			else:
				desired = _toward(_nino.global_position)
				speed = chase_speed
		State.WINDUP:
			_face(_nino.global_position, delta)
			body.rear = minf(body.rear + delta / windup_time, 1.0)
			if _timer <= 0.0:
				_set_state(State.ATTACK)
		State.ATTACK:
			# Bond court vers l'avant ; la morsure ne touche qu'une fois.
			desired = -global_basis.z
			speed = 2.4
			body.rear = maxf(body.rear - delta * 6.0, 0.0)
			if not _hit_done and _flat_distance(_nino.global_position) < attack_range + 0.1 and _same_level() \
					and (-global_basis.z).dot((_nino.global_position - global_position).normalized()) > 0.2:
				_hit_done = true
				Sfx.play(&"bite", -6.0)
				if _integrity:
					_integrity.hit(bite_damage, &"physical", global_position)
			if _timer <= 0.0:
				_set_state(State.RECOVER)
		State.RECOVER:
			if _timer <= 0.0:
				_set_state(State.CHASE if _can_see_nino(true) else State.SEARCH)
		State.SEARCH:
			body.head_tilt = sin(_timer * 4.0) * 0.4
			rotation.y += delta * 1.5
			if _can_see_nino():
				_alert()
			elif _timer <= 0.0:
				body.head_tilt = 0.0
				_target_index = _nearest_point()
				_set_state(State.RETURN)
		State.RETURN:
			if _can_see_nino():
				_alert()
			else:
				desired = _toward(patrol_points[_target_index])
				speed = patrol_speed * 1.3
				if _flat_distance(patrol_points[_target_index]) < 0.2:
					_set_state(State.PATROL)
		State.STAGGER:
			body.excitement = 1.0
			if _timer <= 0.0:
				body.excitement = 0.0
				_set_state(State.FLEE if health <= 0 else State.CHASE)
		State.FLEE:
			desired = (global_position - _nino.global_position) * Vector3(1, 0, 1)
			speed = chase_speed * 1.1
			if _timer <= 0.0:
				visible = false
				collision_layer = 0
				_set_state(State.AWAY)
		State.AWAY:
			if _timer <= 0.0 and _flat_distance(_nino.global_position) > 6.0:
				reset_to_post()
	_move(desired, speed, delta)


func _move(desired: Vector3, speed: float, delta: float) -> void:
	if state == State.AWAY:
		return
	var horizontal := Vector3.ZERO
	if desired.length() > 0.001:
		desired.y = 0.0
		desired = desired.normalized()
		horizontal = desired * speed
		if state != State.ATTACK:
			rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), 1.0 - exp(-10.0 * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	body.motion_speed = Vector3(velocity.x, 0.0, velocity.z).length()
	# Coincé contre un obstacle : abandonne et reprend sa patrouille.
	if speed > 0.1 and state in [State.PATROL, State.RETURN, State.CHASE]:
		if global_position.distance_to(_last_position) < speed * delta * 0.2:
			_stuck += delta
		else:
			_stuck = 0.0
		if _stuck > 1.5:
			_stuck = 0.0
			if state == State.CHASE:
				_set_state(State.SEARCH)
			else:
				_target_index = (_target_index + 1) % patrol_points.size()
	_last_position = global_position


func _set_state(next: State) -> void:
	state = next
	match next:
		State.ALERT:
			_timer = 0.45
			_emote.text = "!"
			Sfx.play(&"soldier_alert", -8.0, randf_range(0.95, 1.1))
			alerted.emit(self)
		State.CHASE:
			_emote.text = ""
			_unseen = 0.0
		State.WINDUP:
			_timer = windup_time
			_emote.text = "!"
			Sfx.play(&"windup", -12.0)
		State.ATTACK:
			_timer = 0.18
			_hit_done = false
		State.RECOVER:
			_timer = recover_time
			_emote.text = ""
			body.rear = 0.0
		State.SEARCH:
			_timer = 1.6
			_emote.text = "?"
			lost_track.emit(self)
		State.RETURN, State.PATROL:
			_emote.text = ""
			body.rear = 0.0
		State.STAGGER:
			_timer = 0.5
			_emote.text = "!"
		State.FLEE:
			_timer = 2.0
			_emote.text = ""
		State.AWAY:
			_timer = respawn_time


func _alert() -> void:
	_set_state(State.ALERT)


## Bille du canon : recul, puis fuite quand le soldat n'en peut plus.
func on_projectile_hit(projectile: Node3D) -> void:
	if state in [State.FLEE, State.AWAY]:
		return
	health -= 1
	var push := global_position - projectile.global_position
	push.y = 0.0
	velocity += push.normalized() * 1.5
	Sfx.play(&"impact_small", -6.0)
	_set_state(State.STAGGER)


func _can_see_nino(chasing := false) -> bool:
	if _nino == null or not _nino.visible or _calm > 0.0:
		return false
	var to := _nino.global_position - global_position
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() > (detect_range * (1.6 if chasing else 1.0)):
		return false
	if not _same_level(1.0):
		return false
	if not chasing and flat.length() > 1.0 and rad_to_deg((-global_basis.z).angle_to(flat)) > detect_angle:
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.12, _nino.global_position + Vector3.UP * 0.25, 1, [get_rid(), _nino.get_rid()])
	return space.intersect_ray(query).is_empty()


func _same_level(tolerance := 0.45) -> bool:
	return absf(_nino.global_position.y - global_position.y) < tolerance


func _toward(point: Vector3) -> Vector3:
	var to := point - global_position
	to.y = 0.0
	return to


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _face(point: Vector3, delta: float) -> void:
	var to := _toward(point)
	if to.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-12.0 * delta))


func _nearest_point() -> int:
	var best := 0
	var best_d := INF
	for i in patrol_points.size():
		var d := _flat_distance(patrol_points[i])
		if d < best_d:
			best_d = d
			best = i
	return best
