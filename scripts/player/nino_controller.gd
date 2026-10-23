class_name NinoController
extends CharacterBody3D
## Contrôleur provisoire de Nino (Lot 1) : mode roues + escalade basique.
##
## Nino NE SAUTE PAS (GDD §3). Le saut arrivera avec le module « deux jambes ».
## Échelle : 1 unité = 10 cm réels. L'origine du nœud est au niveau des roues.
##
## Escalade [hypothèse de prototype, à valider] :
## - Nino s'accroche automatiquement en roulant vers une surface placée sur la
##   couche physique 2 « escaladable », depuis le sol.
## - Sur la paroi : avant/arrière = monter/descendre, gauche/droite = latéral.
## - Nino reste limité à la surface escaladable (il ne peut pas en dépasser les bords).
## - En haut, il se hisse automatiquement si la place est libre.
## - En bas, reculer au contact du sol le remet en mode roues.
## - « Lâcher » (C) le décroche : il tombe.

signal state_changed(new_state: State)

enum State { WHEELS, CLIMBING, MOUNTING }

const WORLD_MASK := 1 << 0      # couche 1 « monde »
const CLIMBABLE_MASK := 1 << 1  # couche 2 « escaladable »

@export_group("Roues")
## Vitesse maximale au sol (unités/s ; 3 = 30 cm/s réels).
@export var max_speed := 3.0
@export var acceleration := 7.0
@export var deceleration := 9.0
## Vitesse de rotation maximale (radians/s).
@export var turn_speed := 7.0

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
## Contrôle horizontal en l'air (fraction de l'accélération au sol).
@export_range(0.0, 1.0) var air_control := 0.3
## En dessous de cette hauteur, Nino réapparaît.
@export var kill_height := -10.0

var state: State = State.WHEELS

var _wall_normal := Vector3.FORWARD
var _climb_velocity := Vector3.ZERO
var _attach_cooldown := 0.0
var _spawn_transform: Transform3D

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _visual: NinoVisual = $Visual


func _ready() -> void:
	_spawn_transform = global_transform


func _physics_process(delta: float) -> void:
	_attach_cooldown = maxf(_attach_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("respawn") or global_position.y < kill_height:
		respawn()
		return

	match state:
		State.WHEELS:
			_process_wheels(delta)
		State.CLIMBING:
			_process_climbing(delta)
		State.MOUNTING:
			pass # Le hissage est piloté par un Tween.

	_update_visual(delta)


func respawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_climb_velocity = Vector3.ZERO
	_set_state(State.WHEELS)


# --- Mode roues --------------------------------------------------------------

func _process_wheels(delta: float) -> void:
	var desired := _get_camera_relative_direction()
	var on_floor := is_on_floor()

	# Rotation progressive vers la direction demandée (rotation sur place possible).
	if desired.length_squared() > 0.0001:
		var target_yaw := atan2(-desired.x, -desired.z)
		var diff := wrapf(target_yaw - rotation.y, -PI, PI)
		rotation.y += clampf(diff, -turn_speed * delta, turn_speed * delta)

	# Les roues poussent dans l'axe du robot : il ralentit s'il doit faire demi-tour.
	var forward := -global_basis.z
	var alignment := clampf(forward.dot(desired.normalized()), 0.0, 1.0) if desired.length_squared() > 0.0001 else 0.0
	var target_velocity := forward * max_speed * desired.length() * alignment

	var rate := acceleration if desired.length_squared() > 0.0001 else deceleration
	if not on_floor:
		rate *= air_control
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if not on_floor:
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)

	move_and_slide()

	if on_floor and _attach_cooldown <= 0.0 and desired.length_squared() > 0.0001:
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


# --- Escalade ------------------------------------------------------------------

func _start_climbing(normal: Vector3) -> void:
	_wall_normal = normal
	_climb_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	_set_state(State.CLIMBING)


func _process_climbing(delta: float) -> void:
	if Input.is_action_just_pressed("release_grip"):
		_release_wall(true)
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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

	# Arrivé en bas : reculer au contact du sol repasse en mode roues.
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
	_set_state(State.WHEELS)


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
	_set_state(State.WHEELS)


func _is_space_free(feet_position: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _collision_shape.shape
	params.transform = Transform3D(global_basis, feet_position + _collision_shape.position)
	params.collision_mask = WORLD_MASK
	params.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


# --- Utilitaires ---------------------------------------------------------------

## Direction horizontale demandée, relative à la caméra active (longueur 0..1).
func _get_camera_relative_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	_visual.set_climbing(new_state != State.WHEELS)
	state_changed.emit(new_state)


func _update_visual(delta: float) -> void:
	var speed: float
	if state == State.CLIMBING:
		speed = _climb_velocity.length() * signf(_climb_velocity.y + 0.001)
	else:
		speed = velocity.dot(-global_basis.z)
	_visual.update_motion(speed, speed / max_speed, delta)
