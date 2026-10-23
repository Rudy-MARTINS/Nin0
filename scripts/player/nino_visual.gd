class_name NinoVisual
extends Node3D
## Apparence animée de NINO : roues, jambes (IK procédurale à deux segments),
## transformation, tête qui regarde, visage expressif et réactions.
## Aucune logique de gameplay ici : uniquement de l'affichage.

enum Emotion { NEUTRAL, CURIOUS, HAPPY, SURPRISED, HURT, FOCUSED }

const EMOTION_VALUES := {
	Emotion.NEUTRAL: {},
	Emotion.CURIOUS: {"curious": 1.0},
	Emotion.HAPPY: {"happy": 1.0},
	Emotion.SURPRISED: {"surprise": 1.0},
	Emotion.HURT: {"hurt": 1.0},
	Emotion.FOCUSED: {"focus": 1.0},
}
const FACE_PARAMS := ["happy", "surprise", "hurt", "focus", "curious"]

@export var wheel_radius := 0.065
@export var max_lean_degrees := 5.0
## Hauteur dont le corps s'élève en mode jambes.
@export var leg_lift := 0.2
@export var thigh_length := 0.19
@export var shin_length := 0.19
@export var foot_height := 0.026
@export var stride_length := 0.2
@export var blink_interval := Vector2(2.5, 5.5)

## Position globale que NINO regarde (null = regard libre).
var look_target: Variant = null

var _mode_blend := 0.0
var _legs_installed := false
var _walk_phase := 0.0
var _walk_amount := 0.0
var _on_floor := true
var _climbing := false
var _speed := 0.0

var _base_emotion := Emotion.NEUTRAL
var _mood := Emotion.NEUTRAL
var _mood_time := 0.0
var _face_values := {}
var _power := 1.0
var _blink_timer := 3.0
var _blink_time_left := 0.0
var _glance := Vector2.ZERO
var _glance_timer := 2.0
var _squash := 0.0
var _squash_velocity := 0.0
var _step_side := 1.0

@onready var _rig: Node3D = $Rig
@onready var _head: Node3D = $Rig/Head
@onready var _wheels: Array[Node] = $Rig/Wheels.get_children()
@onready var _wheel_rest: Array[Vector3] = []
@onready var _legs: Node3D = $Legs
@onready var _leg_left: Node3D = $Legs/LegLeft
@onready var _leg_right: Node3D = $Legs/LegRight
@onready var _mount_left: Node3D = $Rig/Modules/LegMountLeft
@onready var _mount_right: Node3D = $Rig/Modules/LegMountRight
@onready var _face_material: ShaderMaterial = ($Rig/Head/Face as MeshInstance3D).material_override


func _ready() -> void:
	for wheel in _wheels:
		_wheel_rest.append((wheel as Node3D).position)
	for param in FACE_PARAMS:
		_face_values[param] = 0.0
	_blink_timer = randf_range(blink_interval.x, blink_interval.y)
	set_legs_installed(false)
	_apply_mode_blend()


func _process(delta: float) -> void:
	_update_face(delta)
	_update_head(delta)
	_update_squash(delta)
	_update_legs(delta)


# --- API appelée par le contrôleur -------------------------------------------

## speed : vitesse horizontale signée (u/s) ; speed_ratio : vitesse / vitesse max.
func update_motion(speed: float, speed_ratio: float, on_floor: bool, climbing: bool, delta: float) -> void:
	_speed = speed
	_on_floor = on_floor
	_climbing = climbing
	var wheel_factor := 1.0 - _mode_blend
	for wheel in _wheels:
		(wheel as Node3D).rotation.x -= speed / wheel_radius * delta * wheel_factor
	var lean := -deg_to_rad(max_lean_degrees) * clampf(speed_ratio, -1.0, 1.0) * wheel_factor
	rotation.x = lerpf(rotation.x, lean, 1.0 - exp(-8.0 * delta))
	_base_emotion = Emotion.FOCUSED if climbing else Emotion.NEUTRAL


## 0 = roues, 1 = jambes. Utilisé pendant la transformation.
func set_mode_blend(value: float) -> void:
	_mode_blend = clampf(value, 0.0, 1.0)
	_apply_mode_blend()


func set_legs_installed(installed: bool) -> void:
	_legs_installed = installed
	_legs.visible = installed


func get_leg_mount_positions() -> Array[Vector3]:
	return [_mount_left.global_position, _mount_right.global_position]


## Émotion temporaire (retour automatique à l'expression de base).
func show_emotion(emotion: Emotion, duration := 1.2) -> void:
	_mood = emotion
	_mood_time = duration


## Allume / éteint l'écran (0..1).
func set_power(value: float) -> void:
	_power = value
	_face_material.set_shader_parameter("power", value)


func react_to_landing(impact_speed: float) -> void:
	_squash_velocity = -clampf(impact_speed * 0.12, 0.3, 2.2)
	if impact_speed > 15.0:
		show_emotion(Emotion.HURT, 1.4)
		Sfx.play(&"hurt", -6.0)
	elif impact_speed > 7.0:
		show_emotion(Emotion.SURPRISED, 0.9)
	if impact_speed > 3.0:
		Sfx.play(&"thud", linear_to_db(clampf(impact_speed / 15.0, 0.2, 1.0)))


func react_to_jump() -> void:
	_squash_velocity = 1.2


# --- Visage et tête ------------------------------------------------------------

func _update_face(delta: float) -> void:
	if _mood_time > 0.0:
		_mood_time -= delta
	var emotion := _mood if _mood_time > 0.0 else _base_emotion
	if emotion == Emotion.NEUTRAL and look_target != null:
		emotion = Emotion.CURIOUS
	var targets: Dictionary = EMOTION_VALUES[emotion]
	for param in FACE_PARAMS:
		var value: float = lerpf(_face_values[param], targets.get(param, 0.0), 1.0 - exp(-14.0 * delta))
		_face_values[param] = value
		_face_material.set_shader_parameter(param, value)

	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_time_left = 0.13
		_blink_timer = randf_range(blink_interval.x, blink_interval.y)
	_blink_time_left = maxf(_blink_time_left - delta, 0.0)
	_face_material.set_shader_parameter("open", 0.08 if _blink_time_left > 0.0 else 1.0)


func _update_head(delta: float) -> void:
	var target_yaw := 0.0
	var target_pitch := 0.0
	if look_target != null:
		var local := _rig.global_transform.affine_inverse() * (look_target as Vector3) - _head.position
		target_yaw = clampf(atan2(-local.x, -local.z), -0.7, 0.7)
		target_pitch = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.4, 0.35)
	elif absf(_speed) < 0.1 and not _climbing:
		# Regards occasionnels quand NINO est immobile.
		_glance_timer -= delta
		if _glance_timer <= 0.0:
			_glance = Vector2(randf_range(-0.5, 0.5), randf_range(-0.1, 0.25)) if randf() < 0.7 else Vector2.ZERO
			_glance_timer = randf_range(1.5, 4.0)
		target_yaw = _glance.x
		target_pitch = _glance.y
	else:
		_glance = Vector2.ZERO
	var weight := 1.0 - exp(-6.0 * delta)
	_head.rotation.y = lerpf(_head.rotation.y, target_yaw, weight)
	_head.rotation.x = lerpf(_head.rotation.x, target_pitch, weight)
	var look := Vector2(-_head.rotation.y / 0.7, _head.rotation.x / 0.4) * 0.6
	_face_material.set_shader_parameter("look", look)


func _update_squash(delta: float) -> void:
	# Petit ressort amorti sur l'échelle verticale (atterrissage, saut).
	_squash_velocity += (-_squash * 180.0 - _squash_velocity * 14.0) * delta
	_squash += _squash_velocity * delta
	_squash = clampf(_squash, -0.25, 0.2)
	_rig.scale = Vector3(1.0 - _squash * 0.5, 1.0 + _squash, 1.0 - _squash * 0.5)


# --- Roues, jambes et transformation -----------------------------------------------

func _apply_mode_blend() -> void:
	var t := _mode_blend
	var eased := t * t * (3.0 - 2.0 * t)
	_rig.position.y = eased * leg_lift
	# Les roues se replient légèrement sous le châssis.
	for i in _wheels.size():
		var wheel := _wheels[i] as Node3D
		var rest: Vector3 = _wheel_rest[i]
		wheel.position = Vector3(rest.x * (1.0 - 0.18 * eased), rest.y + 0.03 * eased, rest.z * (1.0 - 0.15 * eased))
		wheel.scale = Vector3.ONE * (1.0 - 0.3 * eased)


func _update_legs(delta: float) -> void:
	if not _legs_installed:
		return
	var moving := _on_floor and not _climbing and absf(_speed) > 0.05 and _mode_blend > 0.99
	_walk_amount = move_toward(_walk_amount, 1.0 if moving else 0.0, delta * 6.0)
	if moving:
		var previous := _walk_phase
		_walk_phase += absf(_speed) / stride_length * PI * delta
		if int(previous / PI) != int(_walk_phase / PI):
			Sfx.play(&"step", -18.0, randf_range(0.9, 1.15))
	_place_leg(_leg_left, _mount_left, 0.0)
	_place_leg(_leg_right, _mount_right, PI)
	# Léger rebond du corps pendant la marche.
	if _mode_blend > 0.99:
		_rig.position.y = leg_lift + absf(sin(_walk_phase)) * 0.012 * _walk_amount


func _place_leg(leg: Node3D, mount: Node3D, phase_offset: float) -> void:
	var hip := to_local(mount.global_position)
	leg.position = hip
	var reach := thigh_length + shin_length
	# Position du pied relative à la hanche (z négatif = vers l'avant).
	var folded := Vector2(0.03, 0.07)  # (avant, bas) : jambe repliée contre le flanc
	var standing := Vector2(0.0, hip.y - foot_height)
	var target := folded.lerp(standing, clampf(_mode_blend * 1.15 - 0.1, 0.0, 1.0))
	if _mode_blend > 0.99:
		if not _on_floor and not _climbing:
			target = Vector2(0.04, reach * 0.8)
		else:
			var phase := _walk_phase + phase_offset
			target.x += sin(phase) * stride_length * 0.5 * _walk_amount
			target.y -= maxf(0.0, cos(phase)) * 0.05 * _walk_amount
	_solve_leg(leg, target.x, target.y)


## IK analytique : hanche et genou dans le plan sagittal du robot.
func _solve_leg(leg: Node3D, forward: float, down: float) -> void:
	var knee := leg.get_node("Knee") as Node3D
	var ankle := knee.get_node("Ankle") as Node3D
	var distance := clampf(Vector2(forward, down).length(), 0.02, thigh_length + shin_length - 0.001)
	var base := atan2(forward, down)
	var hip_bend := acos(clampf((thigh_length * thigh_length + distance * distance - shin_length * shin_length)
			/ (2.0 * thigh_length * distance), -1.0, 1.0))
	var knee_inner := acos(clampf((thigh_length * thigh_length + shin_length * shin_length - distance * distance)
			/ (2.0 * thigh_length * shin_length), -1.0, 1.0))
	leg.rotation.x = base + hip_bend
	knee.rotation.x = -(PI - knee_inner)
	ankle.rotation.x = -(leg.rotation.x + knee.rotation.x)
