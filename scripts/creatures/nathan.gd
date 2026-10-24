class_name Nathan
extends CharacterBody3D
## Nathan (lot 7) : figurine articulée, compagnon de Nin0 (inspiration : Abe's Oddysee).
## Inerte tant que Nin0 ne l'a pas observé (souvenir n° 4), puis il suit Nin0 et obéit à
## quatre ordres : Suis-moi, Attends, Va là-bas, Interagis (bascule, interrupteurs…).
## Il ne peut ni mourir ni être perdu : s'il reste coincé ou trop loin, il réapparaît
## près de Nin0, hors du champ de la caméra. Effrayé, il fuit vers un abri puis revient.
## Il ne grimpe pas : il franchit de petites marches (0,5 u) seulement.

signal order_changed(order: StringName)
signal interaction_started(target: Node3D)
signal interaction_done(target: Node3D)
signal scared_by(source: Node3D)
signal recovered

enum State { DORMANT, SCRIPTED, FOLLOW, WAIT, GOTO, INTERACT, HOLD, SCARED }

const SPEED := 2.3
const GRAVITY := 25.0
const FOLLOW_DISTANCE := 1.6

var state := State.DORMANT
var body: NathanBody
var focus: FocusTarget
## Abri où il se réfugie quand il a peur (fourni par la zone).
var safe_spot := Vector3.ZERO
var _nino: NinoController
var _target := Vector3.ZERO
var _interact_target: Node3D
var _stuck_time := 0.0
var _last_progress := Vector3.ZERO
var _scared_timer := 0.0
var _resume_state := State.FOLLOW
var _step_sound := 0.0
var _emote: Label3D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	floor_snap_length = 0.3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.25
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.63, 0.0)
	add_child(shape)
	body = NathanBody.new()
	body.dormant = 1.0
	add_child(body)
	focus = FocusTarget.new()
	focus.id = &"nathan"
	focus.radius = 0.6
	focus.position = Vector3(0.0, 0.3, 0.0)
	focus.thought_icons = [&"eye", &"question"]
	add_child(focus)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 72
	_emote.pixel_size = 0.005
	_emote.outline_size = 14
	_emote.modulate = Color(1.0, 0.82, 0.45)
	_emote.position = Vector3(0.0, 1.55, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	add_to_group(&"nathan")


func is_awake() -> bool:
	return state != State.DORMANT


func is_holding() -> bool:
	return state == State.HOLD


## Réveil (fin de la mise en scène du souvenir n° 4).
func wake(immediate := false) -> void:
	focus.enabled = false
	if immediate:
		body.dormant = 0.0
	else:
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(body, "dormant", 0.0, 0.6)
	state = State.SCRIPTED


func set_emote(text: String) -> void:
	_emote.text = text


# --- Ordres ------------------------------------------------------------------------------------

func follow() -> void:
	_release_hold()
	state = State.FOLLOW
	order_changed.emit(&"follow")


func wait_here() -> void:
	_release_hold()
	state = State.WAIT
	order_changed.emit(&"wait")


func go_to(point: Vector3) -> void:
	_release_hold()
	_target = point
	state = State.GOTO
	_stuck_time = 0.0
	order_changed.emit(&"goto")


## « Interagis » : rejoint l'objet le plus proche du point visé (ou de lui) et l'utilise.
func interact_with(target: Node3D) -> bool:
	if target == null:
		set_emote("?")
		Sfx.play(&"toy_voice", -8.0, 0.8)
		get_tree().create_timer(1.2).timeout.connect(func() -> void: set_emote(""))
		return false
	_release_hold()
	_interact_target = target
	_target = target.companion_point()
	state = State.INTERACT
	_stuck_time = 0.0
	order_changed.emit(&"interact")
	return true


## Objet utilisable le plus proche d'un point (groupe « companion_targets »).
func nearest_target(point: Vector3, radius := 7.0) -> Node3D:
	var best: Node3D
	var best_d := radius
	for node in get_tree().get_nodes_in_group(&"companion_targets"):
		var target := node as Node3D
		var d: float = (target.companion_point() as Vector3).distance_to(point)
		if d < best_d:
			best_d = d
			best = target
	return best


## Effrayé (une créature l'a atteint) : il lâche tout, fuit vers l'abri, puis revient.
func scare(source: Node3D) -> void:
	if state in [State.DORMANT, State.SCRIPTED, State.SCARED]:
		return
	_resume_state = State.INTERACT if state in [State.HOLD, State.INTERACT] and _interact_target else state
	_release_hold()
	state = State.SCARED
	_scared_timer = 3.0
	_target = safe_spot
	set_emote("!")
	Sfx.play(&"toy_voice", -4.0, 1.6)
	scared_by.emit(source)


## Réapparition près de Nin0 (coincé ou perdu), hors du champ de la caméra : derrière la
## caméra ou sur un côté, sur un sol libre, jamais dans un mur.
func recover_near(nino: NinoController) -> void:
	var cam := get_viewport().get_camera_3d()
	var back := cam.global_basis.z if cam else nino.global_basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3.BACK
	var side := back.cross(Vector3.UP)
	var base := nino.global_position
	var arm := Vector2(cam.global_position.x - base.x, cam.global_position.z - base.z).length() if cam else 2.0
	var candidates := [base + back * (arm + 1.2), base + side * 3.2, base - side * 3.2, base + back * (arm + 0.6) + side * 1.5,
			base + back * (arm + 0.6) - side * 1.5, base + back * 1.4]
	var space := get_world_3d().direct_space_state
	var chosen: Vector3 = candidates[-1]
	for candidate in candidates:
		var spot := candidate as Vector3
		var clear := space.intersect_ray(PhysicsRayQueryParameters3D.create(base + Vector3.UP * 0.5, spot + Vector3.UP * 0.5, 1, [get_rid(), nino.get_rid()]))
		if not clear.is_empty():
			continue
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 0.8, spot + Vector3.DOWN * 1.5, 1, [get_rid()]))
		if ground.is_empty() or absf((ground.position as Vector3).y - base.y) > 0.9:
			continue
		if cam and cam.is_position_in_frustum(spot + Vector3.UP * 0.6):
			continue
		chosen = (ground.position as Vector3)
		break
	global_position = chosen
	velocity = Vector3.ZERO
	_stuck_time = 0.0
	recovered.emit()


func _release_hold() -> void:
	if state == State.HOLD and _interact_target and _interact_target.has_method("set_held"):
		_interact_target.set_held(false)
	body.sit = 0.0


# --- Déplacements ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state in [State.DORMANT, State.SCRIPTED, State.HOLD]:
		body.gait = move_toward(body.gait, 0.0, delta * 4.0)
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		if _nino == null:
			return
	var goal := global_position
	var speed := SPEED
	match state:
		State.FOLLOW:
			var to := _nino.global_position - global_position
			to.y = 0.0
			if to.length() > FOLLOW_DISTANCE:
				goal = _nino.global_position - to.normalized() * FOLLOW_DISTANCE
			# Nin0 en hauteur (inaccessible) : il l'attend au pied.
			if _nino.global_position.y - global_position.y > 0.8 and to.length() < 3.0:
				goal = global_position
			# Très loin (téléportation, chute…) : il le rejoint.
			if global_position.distance_to(_nino.global_position) > 26.0:
				recover_near(_nino)
		State.WAIT:
			goal = global_position
		State.GOTO, State.INTERACT:
			goal = _target
			if _flat(goal - global_position).length() < 0.35:
				if state == State.INTERACT:
					_begin_interaction()
					return
				state = State.WAIT
		State.SCARED:
			goal = safe_spot
			speed = SPEED * 1.5
			_scared_timer -= delta
			# Calmé à l'abri (ou, s'il n'arrive pas à l'atteindre, après quelques secondes).
			if _scared_timer <= 0.0 and (_flat(safe_spot - global_position).length() < 0.6 or _scared_timer < -4.0):
				set_emote("")
				body.scared = 0.0
				if _resume_state == State.INTERACT and _interact_target:
					interact_with(_interact_target)
				else:
					state = _resume_state if _resume_state != State.SCARED else State.FOLLOW
	body.scared = move_toward(body.scared, 1.0 if state == State.SCARED else 0.0, delta * 3.0)
	var move := _flat(goal - global_position)
	var horizontal := Vector3.ZERO
	if move.length() > 0.12:
		horizontal = move.normalized() * minf(speed, move.length() * 4.0)
		rotation.y = lerp_angle(rotation.y, atan2(-move.x, -move.z), 1.0 - exp(-10.0 * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	# Petites marches : un saut court quand un obstacle bas bloque.
	if is_on_floor() and horizontal.length() > 0.5 and is_on_wall() and _low_step_ahead(horizontal):
		velocity.y = 4.2
	move_and_slide()
	body.gait = move_toward(body.gait, clampf(_flat(velocity).length() / SPEED, 0.0, 1.0), delta * 6.0)
	if body.gait > 0.3:
		_step_sound -= delta
		if _step_sound <= 0.0:
			_step_sound = 0.26
			if _nino and global_position.distance_to(_nino.global_position) < 10.0:
				Sfx.play(&"toy_step", -16.0, randf_range(0.9, 1.15))
	_check_stuck(delta, move.length())


func _check_stuck(delta: float, remaining: float) -> void:
	if remaining < 0.6 or state in [State.WAIT, State.SCARED]:
		_stuck_time = 0.0
		_last_progress = global_position
		return
	if global_position.distance_to(_last_progress) > 0.4:
		_last_progress = global_position
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if _stuck_time > 3.5:
		# Coincé : il réapparaît près de Nin0 (ou de sa destination s'il en a une).
		if state == State.FOLLOW:
			recover_near(_nino)
		else:
			global_position = _target + Vector3(0.0, 0.1, 0.0)
			velocity = Vector3.ZERO
			_stuck_time = 0.0
			recovered.emit()


func _low_step_ahead(direction: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 0.75 + direction.normalized() * 0.1
	var query := PhysicsRayQueryParameters3D.create(from, from + direction.normalized() * 0.5, 1, [get_rid()])
	return space.intersect_ray(query).is_empty()


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


# --- Interactions -----------------------------------------------------------------------------

func _begin_interaction() -> void:
	var target := _interact_target
	if target == null:
		state = State.WAIT
		return
	state = State.SCRIPTED
	interaction_started.emit(target)
	if target is Seesaw:
		await _climb_seesaw(target as Seesaw)
	elif target.has_method("companion_use"):
		await target.companion_use(self)
		state = State.WAIT
	interaction_done.emit(target)


## Bascule : il monte sur la règle depuis l'extrémité basse, dépasse le point d'appui,
## la règle bascule, il glisse jusqu'au bout et s'assoit pour la tenir.
func _climb_seesaw(seesaw: Seesaw) -> void:
	Sfx.play(&"toy_voice", -8.0, 1.2)
	body.gait = 1.0
	var path := [seesaw.surface_point(4.6), seesaw.surface_point(1.6), seesaw.surface_point(-0.4)]
	look_at_flat(seesaw.surface_point(-5.0))
	for point in path:
		var tween := create_tween()
		tween.tween_property(self, "global_position", point, global_position.distance_to(point) / 1.6)
		await tween.finished
	seesaw.set_held(true)
	var slide := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slide.tween_method(func(k: float) -> void: global_position = seesaw.surface_point(lerpf(-0.4, -5.0, k)), 0.0, 1.0, 0.7)
	await slide.finished
	body.gait = 0.0
	global_position = seesaw.hold_spot.global_position
	look_at_flat(seesaw.surface_point(5.0))
	body.sit = 1.0
	state = State.HOLD
	Sfx.play(&"toy_voice", -6.0, 1.4)


func look_at_flat(point: Vector3) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = atan2(-to.x, -to.z)
