class_name FocusVision
extends Node
## Vision focalisée de NINO : maintenir la touche (clic droit ou Maj) pour regarder
## « à travers ses yeux » avec un fort grossissement. Viser une cible (FocusTarget)
## quelques instants l'identifie.
##
## Version simple et extensible : pas de scanner, pas d'inventaire d'informations.

signal focus_changed(active: bool)
signal target_identified(target: FocusTarget)

## La capacité doit être débloquée (la démo la présente au rebord de la fenêtre).
@export var unlocked := false
@export var player: NinoController
@export var camera: ThirdPersonCamera
@export var overlay: FocusOverlay
@export var zoom_fov := 28.0
## Temps de visée nécessaire pour identifier une cible.
@export var lock_time := 0.7
## Tolérance de visée minimale (degrés).
@export var min_aim_degrees := 2.5

var active := false
var lock_progress := 0.0

var _locked: FocusTarget
var _normal_fov := 70.0


func _ready() -> void:
	_normal_fov = camera.get_camera().fov


func _physics_process(delta: float) -> void:
	var wants := unlocked and Input.is_action_pressed("focus") and player.can_focus()
	if wants != active:
		_set_active(wants)
	if not active:
		return
	var aimed := _find_aimed_target()
	if aimed != _locked:
		_locked = aimed
		lock_progress = 0.0
	if _locked and not _locked.is_identified:
		lock_progress = minf(lock_progress + delta / lock_time, 1.0)
		if lock_progress >= 1.0:
			_locked.mark_identified()
			Sfx.play(&"focus_lock", -4.0)
			target_identified.emit(_locked)
	overlay.update_targets(_visible_markers(), _locked, lock_progress)


func _set_active(value: bool) -> void:
	active = value
	lock_progress = 0.0
	_locked = null
	player.focus_lock = value
	camera.set_first_person(value)
	var cam := camera.get_camera()
	var tween := create_tween()
	tween.tween_property(cam, "fov", zoom_fov if value else _normal_fov, 0.25).set_trans(Tween.TRANS_SINE)
	overlay.set_active(value)
	player.get_visual().show_emotion(NinoVisual.Emotion.FOCUSED, 0.6 if value else 0.0)
	Sfx.play(&"focus_in" if value else &"focus_out", -10.0)
	focus_changed.emit(value)


## Cible la plus proche du centre de la vue, dans la tolérance de visée.
func _find_aimed_target() -> FocusTarget:
	var cam := camera.get_camera()
	var origin := cam.global_position
	var forward := -cam.global_basis.z
	var best: FocusTarget = null
	var best_angle := INF
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		if not target.enabled or not target.is_visible_in_tree():
			continue
		var to_target := target.global_position - origin
		var distance := to_target.length()
		var angle := rad_to_deg(forward.angle_to(to_target))
		var tolerance := maxf(rad_to_deg(atan(target.radius / maxf(distance, 0.01))), min_aim_degrees)
		if angle < tolerance and angle < best_angle:
			best_angle = angle
			best = target
	return best


func _visible_markers() -> Array:
	var cam := camera.get_camera()
	var markers := []
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		if target.enabled and target.show_marker and not target.is_identified and not cam.is_position_behind(target.global_position):
			markers.append(cam.unproject_position(target.global_position))
	return markers
