class_name ThirdPersonCamera
extends Node3D
## Caméra troisième personne : suivi lissé, rotation à la souris.
## Le SpringArm3D rapproche la caméra quand un obstacle s'interpose (anti-traversée).

@export var target: Node3D
## Hauteur du point visé au-dessus des pieds de la cible (si la cible ne la fournit pas).
@export var target_height := 0.35
@export var follow_sharpness := 14.0
@export var mouse_sensitivity := 0.0025
@export var min_pitch_degrees := -65.0
@export var max_pitch_degrees := 30.0
@export var initial_pitch_degrees := -18.0
## Distance de la caméra derrière la cible.
@export var arm_length := 1.8:
	set(value):
		arm_length = value
		if is_node_ready():
			_spring_arm.spring_length = value

## Rotation à la souris autorisée (désactivée pendant les séquences).
var input_enabled := true
var pitch := 0.0:
	set(value):
		pitch = clampf(value, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
		if is_node_ready():
			_pitch_pivot.rotation.x = pitch

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _spring_arm: SpringArm3D = $PitchPivot/SpringArm3D


func _ready() -> void:
	top_level = true
	pitch = deg_to_rad(initial_pitch_degrees)
	_spring_arm.spring_length = arm_length
	if target:
		global_position = _get_focus_point()
		rotation.y = target.global_rotation.y
		if target is CollisionObject3D:
			_spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())
	capture_mouse()


func capture_mouse() -> void:
	if not GameState.modal_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and input_enabled:
		var motion := event as InputEventMouseMotion
		rotation.y -= motion.relative.x * mouse_sensitivity
		pitch -= motion.relative.y * mouse_sensitivity
	elif event is InputEventMouseButton and event.pressed:
		capture_mouse()


# Suivi en _physics_process : Nino se déplace au rythme de la physique.
func _physics_process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(_get_focus_point(), 1.0 - exp(-follow_sharpness * delta))


## Recentre immédiatement la caméra sur la cible (après une réapparition).
func snap_to_target() -> void:
	if target:
		global_position = _get_focus_point()


func _get_focus_point() -> Vector3:
	var height := target_height
	if target.has_method("get_focus_height"):
		height = target.get_focus_height()
	return target.global_position + Vector3.UP * height
