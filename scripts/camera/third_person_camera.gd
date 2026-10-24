class_name ThirdPersonCamera
extends Node3D
## Caméra troisième personne : suivi lissé, rotation à la souris.
## Le SpringArm3D rapproche la caméra quand un obstacle s'interpose (anti-traversée).
##
## Espaces étroits :
## - sous un meuble bas, la caméra s'aplatit (pitch proche de l'horizontale) pour
##   rester derrière Nin0 au lieu de se coller à lui ;
## - Nin0 n'est masqué qu'en dernier recours, si la caméra est quasiment en lui.

@export var target: Node3D
## Hauteur du point visé au-dessus des pieds de la cible (si la cible ne la fournit pas).
@export var target_height := 0.35
@export var follow_sharpness := 14.0
@export var mouse_sensitivity := 0.0025
@export var min_pitch_degrees := -65.0
@export var max_pitch_degrees := 30.0
## En vision focalisée (vue subjective), Nin0 peut lever les yeux plus haut (viser un
## mécanisme en hauteur) : aucune caméra ne risque alors de traverser le sol.
@export var first_person_max_pitch_degrees := 62.0
@export var initial_pitch_degrees := -18.0
## Distance de la caméra derrière la cible.
@export var arm_length := 1.8:
	set(value):
		arm_length = value
		if is_node_ready() and not _first_person:
			_spring_arm.spring_length = value
## En dessous de cette distance, la cible est masquée (évite de voir l'intérieur du modèle).
@export var hide_target_distance := 0.16
## Hauteur libre au-dessus de Nin0 en dessous de laquelle la caméra s'aplatit.
@export var low_ceiling_height := 1.6

## Rotation à la souris autorisée (désactivée pendant les séquences).
var input_enabled := true
var pitch := 0.0:
	set(value):
		var top := first_person_max_pitch_degrees if _first_person else max_pitch_degrees
		pitch = clampf(value, deg_to_rad(min_pitch_degrees), deg_to_rad(top))

var _first_person := false
var _low_ceiling := 0.0  # 0 = dégagé, 1 = plafond bas

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var _camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	pitch = deg_to_rad(initial_pitch_degrees)
	_pitch_pivot.rotation.x = pitch
	_spring_arm.spring_length = arm_length
	if target:
		global_position = _get_focus_point()
		rotation.y = target.global_rotation.y
		if target is CollisionObject3D:
			_spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())
	capture_mouse()


func get_camera() -> Camera3D:
	return _camera


func capture_mouse() -> void:
	if not GameState.modal_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Vue « à travers les yeux » de Nin0 (vision focalisée).
func set_first_person(value: bool) -> void:
	_first_person = value
	pitch = pitch  # ré-applique la limite (en quittant la vue subjective)
	var tween := create_tween()
	tween.tween_property(_spring_arm, "spring_length", 0.0 if value else arm_length, 0.2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and input_enabled:
		var motion := event as InputEventMouseMotion
		var sensitivity := mouse_sensitivity * (0.4 if _first_person else 1.0)
		rotation.y -= motion.relative.x * sensitivity
		pitch -= motion.relative.y * sensitivity
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		capture_mouse()


# Suivi en _physics_process : Nino se déplace au rythme de la physique.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(_get_focus_point(), 1.0 - exp(-follow_sharpness * delta))
	# Plafond bas (dessous d'un meuble) : la caméra s'aplatit progressivement.
	var low := 0.0
	if not _first_person:
		var space := target.get_world_3d().direct_space_state
		var origin := target.global_position + Vector3.UP * 0.3
		var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.UP * low_ceiling_height, 1)
		if target is CollisionObject3D:
			query.exclude = [(target as CollisionObject3D).get_rid()]
		if not space.intersect_ray(query).is_empty():
			low = 1.0
	_low_ceiling = lerpf(_low_ceiling, low, 1.0 - exp(-6.0 * delta))
	var effective_pitch := lerpf(pitch, deg_to_rad(-3.0), _low_ceiling) if not _first_person else pitch
	_pitch_pivot.rotation.x = effective_pitch


func _process(_delta: float) -> void:
	if target:
		var visual := target.get_node_or_null("Visual") as Node3D
		if visual:
			visual.visible = _spring_arm.get_hit_length() > hide_target_distance and not _first_person


## Recentre immédiatement la caméra sur la cible (après une réapparition).
func snap_to_target() -> void:
	if target:
		global_position = _get_focus_point()
		_pitch_pivot.rotation.x = pitch


func _get_focus_point() -> Vector3:
	var height := target_height
	if target.has_method("get_focus_height"):
		height = target.get_focus_height()
	if _first_person:
		height += 0.12
	elif _low_ceiling > 0.01:
		height = lerpf(height, 0.28, _low_ceiling)
	return target.global_position + Vector3.UP * height
