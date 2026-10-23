class_name NinoController
extends CharacterBody3D
## Contrôleur de NINO : mode roues, mode jambes (après impression), escalade.
##
## Échelle : 1 unité = 10 cm réels. L'origine du nœud est au niveau du sol.
##
## - Mode roues : rapide, rotation progressive, AUCUN saut (GDD §3).
## - Mode jambes : plus lent, plus précis, saut. Disponible une fois les jambes installées.
## - Transformation : immobile, au sol, à l'arrêt ; courte animation (GDD : ~0,8 s).
##
## Escalade [hypothèse validée au Lot 1] :
## - Accroche automatique en roulant/marchant vers une surface de la couche
##   physique 2 « escaladable », depuis le sol.
## - Sur la paroi : avant/arrière = monter/descendre, gauche/droite = latéral.
## - Nino reste limité à la surface ; il se hisse en haut s'il y a de la place ;
##   reculer au contact du sol le libère ; « Lâcher » (C) le fait tomber.

signal state_changed(new_state: State)
signal mode_changed(new_mode: Mode)
## Émis quand un changement de mode est refusé (raison lisible par le joueur).
signal transform_refused(reason: String)
signal landed(impact_speed: float)
signal jumped

enum State { FREE, CLIMBING, MOUNTING, TRANSFORMING }
enum Mode { WHEELS, LEGS }

const WORLD_MASK := 1 << 0      # couche 1 « monde »
const CLIMBABLE_MASK := 1 << 1  # couche 2 « escaladable »

@export_group("Roues")
## Vitesse maximale au sol (unités/s ; 3 = 30 cm/s réels).
@export var max_speed := 3.0
@export var acceleration := 7.0
@export var deceleration := 9.0
## Vitesse de rotation maximale (radians/s).
@export var turn_speed := 7.0

@export_group("Jambes")
@export var legs_max_speed := 1.8
@export var legs_acceleration := 12.0
@export var legs_deceleration := 14.0
@export var legs_turn_speed := 12.0
## Hauteur de saut (unités ; 1 = 10 cm, deux fois la taille de NINO sur roues).
@export var jump_height := 1.0
@export_range(0.0, 1.0) var legs_air_control := 0.7
## Tolérance après avoir quitté un rebord, et mémorisation d'un appui anticipé.
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
## Durée de la transformation roues ↔ jambes (GDD : ~0,8 s, à tester).
@export var transform_duration := 0.8
## Vitesse horizontale au-delà de laquelle la transformation est refusée.
@export var transform_max_speed := 0.15
@export var wheels_capsule_height := 0.5
@export var legs_capsule_height := 0.7

@export_group("Escalade")
@export var climb_speed := 1.1
@export var climb_acceleration := 8.0
## Alignement minimal entre la direction demandée et la paroi pour s'accrocher (0..1).
@export var attach_min_alignment := 0.6
## Distance au-delà du rayon de collision pour détecter la paroi.
@export var wall_check_margin := 0.15
## Force qui plaque Nino contre la paroi.
@export var wall_stick_speed := 0.6
## Vitesse d'éjection quand Nino lâche la paroi.
@export var release_push := 0.8
## Délai avant de pouvoir se raccrocher.
@export var reattach_cooldown := 0.4
## Durée du hissage en haut d'une paroi.
@export var mount_duration := 0.4

@export_group("Chute")
## Gravité adaptée à l'échelle de jeu (la vraie gravité serait 98 u/s²).
@export var gravity := 25.0
@export var max_fall_speed := 20.0
## Contrôle horizontal en l'air en mode roues (fraction de l'accélération au sol).
@export_range(0.0, 1.0) var air_control := 0.3
## En dessous de cette hauteur, Nino réapparaît.
@export var kill_height := -10.0

var state: State = State.FREE
var mode: Mode = Mode.WHEELS
## Désactivé pendant l'introduction, les interfaces et les séquences.
var controls_enabled := true
## Vrai quand les jambes sont installées (le mode jambes devient accessible).
var legs_available := false:
	set(value):
		legs_available = value
		if is_node_ready():
			_visual.set_legs_installed(value)

var _wall_normal := Vector3.FORWARD
var _climb_velocity := Vector3.ZERO
var _attach_cooldown := 0.0
var _spawn_transform: Transform3D
var _coyote_timer := 0.0
var _jump_buffer := 0.0
var _mode_blend := 0.0

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _visual: NinoVisual = $Visual


func _ready() -> void:
	_spawn_transform = global_transform
	# Copie locale de la forme : sa hauteur change avec le mode.
	_collision_shape.shape = _collision_shape.shape.duplicate()
	_set_capsule_height(wheels_capsule_height)
	_visual.set_legs_installed(legs_available)


func _physics_process(delta: float) -> void:
	_attach_cooldown = maxf(_attach_cooldown - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	if global_position.y < kill_height or (controls_enabled and Input.is_action_just_pressed("respawn")):
		respawn()
		return

	if controls_enabled:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = jump_buffer_time
		if Input.is_action_just_pressed("switch_mode"):
			request_mode_switch()

	match state:
		State.FREE:
			_process_free(delta)
		State.CLIMBING:
			_process_climbing(delta)
		State.TRANSFORMING:
			_process_transforming(delta)
		State.MOUNTING:
			pass # Le hissage est piloté par un Tween.

	_update_visual(delta)
	_update_audio()


# --- API -----------------------------------------------------------------------------

## Point de réapparition (touche R ou chute hors du niveau).
func set_checkpoint(checkpoint: Transform3D) -> void:
	_spawn_transform = checkpoint


func respawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_climb_velocity = Vector3.ZERO
	_set_state(State.FREE)


## Vrai si NINO peut interagir avec un objet (au sol, libre, contrôlable).
func can_interact() -> bool:
	return controls_enabled and state == State.FREE and is_on_floor()


func get_visual() -> NinoVisual:
	return _visual


## Hauteur du point suivi par la caméra (plus haute en mode jambes).
func get_focus_height() -> float:
	return 0.32 + _mode_blend * (legs_capsule_height - wheels_capsule_height)


## Demande un changement de mode ; émet `transform_refused` si impossible.
func request_mode_switch() -> void:
	if not legs_available:
		return
	var reason := _get_transform_refusal()
	if reason != "":
		transform_refused.emit(reason)
		return
	var target := Mode.LEGS if mode == Mode.WHEELS else Mode.WHEELS
	if target == Mode.LEGS and not _capsule_fits(legs_capsule_height):
		transform_refused.emit("Pas assez de place pour se redresser")
		return
	_start_transform(target)


## Place NINO directement dans un mode (chargement de sauvegarde, tests).
func force_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_blend = 1.0 if new_mode == Mode.LEGS else 0.0
	_set_capsule_height(legs_capsule_height if new_mode == Mode.LEGS else wheels_capsule_height)
	_visual.set_mode_blend(_mode_blend)
	mode_changed.emit(mode)


# --- Déplacement libre (roues ou jambes) --------------------------------------------------

func _process_free(delta: float) -> void:
	var desired := _get_camera_relative_direction()
	var has_input := desired.length_squared() > 0.0001
	var on_floor := is_on_floor()
	var legs := mode == Mode.LEGS

	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	var top_speed := legs_max_speed if legs else max_speed
	var rotation_speed := legs_turn_speed if legs else turn_speed

	# Rotation progressive vers la direction demandée (rotation sur place possible).
	if has_input:
		var target_yaw := atan2(-desired.x, -desired.z)
		var diff := wrapf(target_yaw - rotation.y, -PI, PI)
		rotation.y += clampf(diff, -rotation_speed * delta, rotation_speed * delta)

	var target_velocity := Vector3.ZERO
	if has_input:
		if legs:
			# Les jambes permettent de se déplacer directement dans la direction voulue.
			target_velocity = desired * top_speed
		else:
			# Les roues poussent dans l'axe du robot : il ralentit s'il doit faire demi-tour.
			var forward := -global_basis.z
			var alignment := clampf(forward.dot(desired.normalized()), 0.0, 1.0)
			target_velocity = forward * top_speed * desired.length() * alignment

	var rate: float
	if legs:
		rate = legs_acceleration if has_input else legs_deceleration
		if not on_floor:
			rate *= legs_air_control
	else:
		rate = acceleration if has_input else deceleration
		if not on_floor:
			rate *= air_control
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Saut : uniquement en mode jambes.
	if legs and _jump_buffer > 0.0 and _coyote_timer > 0.0:
		velocity.y = sqrt(2.0 * gravity * jump_height)
		_jump_buffer = 0.0
		_coyote_timer = 0.0
		on_floor = false
		jumped.emit()
		_visual.react_to_jump()
		Sfx.play(&"jump", -10.0, randf_range(0.95, 1.05))

	if not on_floor:
		var g := gravity
		# Relâcher le saut tôt donne un saut plus court (meilleur contrôle).
		if velocity.y > 0.0 and not (controls_enabled and Input.is_action_pressed("jump")):
			g *= 2.2
		velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)

	var fall_speed := -velocity.y
	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > 0.5:
		landed.emit(fall_speed)
		_visual.react_to_landing(fall_speed)

	if is_on_floor() and _attach_cooldown <= 0.0 and has_input:
		_try_attach_from_collisions(desired.normalized())


func _try_attach_from_collisions(desired: Vector3) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as CollisionObject3D
		if collider == null or (collider.collision_layer & CLIMBABLE_MASK) == 0:
			continue
		var normal := collision.get_normal()
		if absf(normal.y) > 0.35:
			continue # Sol, plafond ou pente : pas une paroi.
		if desired.dot(-normal) < attach_min_alignment:
			continue
		_start_climbing(normal)
		return


# --- Transformation -------------------------------------------------------------------

func _get_transform_refusal() -> String:
	if state == State.TRANSFORMING:
		return "Transformation déjà en cours"
	if state != State.FREE:
		return "Impossible pendant l'escalade"
	if not is_on_floor():
		return "Impossible en l'air"
	if Vector3(velocity.x, 0.0, velocity.z).length() > transform_max_speed:
		return "Arrêtez-vous pour changer de mode"
	return ""


func _start_transform(target: Mode) -> void:
	_set_state(State.TRANSFORMING)
	velocity = Vector3.ZERO
	if target == Mode.LEGS:
		_set_capsule_height(legs_capsule_height)
	Sfx.play(&"servo", -6.0, 1.0 if target == Mode.LEGS else 0.85)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(_apply_mode_blend, _mode_blend, 1.0 if target == Mode.LEGS else 0.0, transform_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_transform.bind(target))


func _apply_mode_blend(value: float) -> void:
	_mode_blend = value
	_visual.set_mode_blend(value)


func _finish_transform(target: Mode) -> void:
	mode = target
	if target == Mode.WHEELS:
		_set_capsule_height(wheels_capsule_height)
	_set_state(State.FREE)
	mode_changed.emit(mode)


func _process_transforming(delta: float) -> void:
	# NINO reste immobile ; seule la gravité s'applique.
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
	move_and_slide()


func _set_capsule_height(height: float) -> void:
	var capsule := _collision_shape.shape as CapsuleShape3D
	capsule.height = height
	_collision_shape.position.y = height * 0.5


func _capsule_fits(height: float) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = _get_radius() - 0.01
	capsule.height = height - 0.03
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.transform = Transform3D(global_basis, global_position + Vector3.UP * (height * 0.5 + 0.02))
	params.collision_mask = WORLD_MASK
	params.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


# --- Escalade ------------------------------------------------------------------

func _start_climbing(normal: Vector3) -> void:
	_wall_normal = normal
	_climb_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	_set_state(State.CLIMBING)


func _process_climbing(delta: float) -> void:
	if controls_enabled and Input.is_action_just_pressed("release_grip"):
		_release_wall(true)
		return

	var input := _get_input_vector()
	var wall_up := (Vector3.UP - _wall_normal * Vector3.UP.dot(_wall_normal)).normalized()
	var wall_right := (-_wall_normal).cross(wall_up).normalized()
	var target := (wall_right * input.x + wall_up * -input.y) * climb_speed
	_climb_velocity = _climb_velocity.move_toward(target, climb_acceleration * delta)

	# Nino fait face à la paroi.
	var face_yaw := atan2(_wall_normal.x, _wall_normal.z)
	rotation.y = lerp_angle(rotation.y, face_yaw, 1.0 - exp(-12.0 * delta))

	var previous_position := global_position
	velocity = _climb_velocity - _wall_normal * wall_stick_speed
	move_and_slide()

	# Arrivé en bas : reculer au contact du sol libère Nino.
	if input.y > 0.3 and is_on_floor():
		_release_wall(false)
		velocity = _wall_normal * release_push
		return

	var hit := _cast_wall_ray()
	if not hit.is_empty():
		_wall_normal = hit.normal
		return

	# Plus de surface escaladable devant Nino.
	if _climb_velocity.y > 0.05 and _try_mount():
		return
	# Sinon on reste sur la surface : on annule le dernier déplacement.
	global_position = previous_position
	_climb_velocity = Vector3.ZERO


func _release_wall(push_away: bool) -> void:
	_attach_cooldown = reattach_cooldown
	velocity = _wall_normal * release_push if push_away else Vector3.ZERO
	_climb_velocity = Vector3.ZERO
	_set_state(State.FREE)


func _cast_wall_ray() -> Dictionary:
	var origin := _get_center()
	var reach := _get_radius() + wall_check_margin
	var query := PhysicsRayQueryParameters3D.create(origin, origin - _wall_normal * reach, CLIMBABLE_MASK, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)


## Tente de hisser Nino sur le dessus de la paroi. Renvoie true si le hissage démarre.
func _try_mount() -> bool:
	var space := get_world_3d().direct_space_state
	var height := _get_height()
	var forward := Vector3(-_wall_normal.x, 0.0, -_wall_normal.z).normalized()
	var probe := global_position + Vector3.UP * (height + 0.15) + forward * (_get_radius() * 2.0 + 0.05)
	var query := PhysicsRayQueryParameters3D.create(probe, probe + Vector3.DOWN * (height + 0.4), WORLD_MASK, [get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.7 or hit.position.y < global_position.y:
		return false

	var top: Vector3 = hit.position + Vector3.UP * 0.02
	var lift := Vector3(global_position.x, top.y, global_position.z)
	if not _is_space_free(lift) or not _is_space_free(top):
		return false

	_set_state(State.MOUNTING)
	velocity = Vector3.ZERO
	_climb_velocity = Vector3.ZERO
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", lift, mount_duration * 0.55)
	tween.tween_property(self, "global_position", top, mount_duration * 0.45)
	tween.tween_callback(_on_mount_finished)
	return true


func _on_mount_finished() -> void:
	_attach_cooldown = reattach_cooldown
	_set_state(State.FREE)


func _is_space_free(feet_position: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _collision_shape.shape
	params.transform = Transform3D(global_basis, feet_position + _collision_shape.position)
	params.collision_mask = WORLD_MASK
	params.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


# --- Utilitaires ---------------------------------------------------------------

func _get_input_vector() -> Vector2:
	if not controls_enabled:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


## Direction horizontale demandée, relative à la caméra active (longueur 0..1).
func _get_camera_relative_direction() -> Vector3:
	var input := _get_input_vector()
	if input.length_squared() < 0.0001:
		return Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	var yaw_basis := Basis.IDENTITY
	if camera:
		yaw_basis = Basis(Vector3.UP, camera.global_rotation.y)
	var direction := yaw_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	return direction.limit_length(1.0)


func _get_center() -> Vector3:
	return global_position + Vector3.UP * _collision_shape.position.y


func _get_radius() -> float:
	return (_collision_shape.shape as CapsuleShape3D).radius


func _get_height() -> float:
	return (_collision_shape.shape as CapsuleShape3D).height


func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(new_state)


func _update_visual(delta: float) -> void:
	var speed: float
	var ratio: float
	if state == State.CLIMBING:
		speed = _climb_velocity.length() * signf(_climb_velocity.y + 0.001)
		ratio = 0.0
	else:
		speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
		ratio = speed / max_speed
	_visual.update_motion(speed, ratio, is_on_floor(), state == State.CLIMBING, delta)


func _update_audio() -> void:
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if state == State.CLIMBING:
		speed = _climb_velocity.length() * 1.5
	var rolling := mode == Mode.WHEELS and state != State.TRANSFORMING and (is_on_floor() or state == State.CLIMBING)
	if rolling and speed > 0.08:
		var ratio := clampf(speed / max_speed, 0.0, 1.0)
		Sfx.set_loop(&"wheels", &"wheels", linear_to_db(0.15 + ratio * 0.5), 0.8 + ratio * 0.5)
	else:
		Sfx.stop_loop(&"wheels")
