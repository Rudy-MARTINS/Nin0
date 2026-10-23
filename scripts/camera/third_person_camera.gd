class_name ThirdPersonCamera
extends Node3D
## Caméra troisième personne : suivi lissé, rotation à la souris.
## Le SpringArm3D rapproche la caméra quand un obstacle s'interpose (anti-traversée).

@export var target: Node3D
## Hauteur du point visé au-dessus des pieds de la cible.
@export var target_height := 0.35
@export var follow_sharpness := 14.0
@export var mouse_sensitivity := 0.0025
@export var min_pitch_degrees := -65.0
@export var max_pitch_degrees := 30.0
@export var initial_pitch_degrees := -18.0

var _pitch := 0.0

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _spring_arm: SpringArm3D = $PitchPivot/SpringArm3D


func _ready() -> void:
	top_level = true
	_pitch = deg_to_rad(initial_pitch_degrees)
	_pitch_pivot.rotation.x = _pitch
	if target:
		global_position = _get_focus_point()
		rotation.y = target.global_rotation.y
		if target is CollisionObject3D:
			_spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotation.y -= motion.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity,
				deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
		_pitch_pivot.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Suivi en _physics_process : Nino se déplace au rythme de la physique.
func _physics_process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(_get_focus_point(), 1.0 - exp(-follow_sharpness * delta))


func _get_focus_point() -> Vector3:
	return target.global_position + Vector3.UP * target_height
