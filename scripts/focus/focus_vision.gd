class_name FocusVision
extends Node
## Vision focalisée de Nin0 : maintenir la touche (clic droit ou Maj) pour regarder
## « à travers ses yeux » avec un fort grossissement. Viser une cible (FocusTarget)
## assez longtemps l'identifie, si elle est réellement observable :
## - à portée (ObservationProfile.max_distance) ;
## - dans la tolérance de visée (taille apparente + marge minimale) ;
## - sous un angle valable par rapport à sa face (max_view_angle) ;
## - sans obstacle entre les yeux de Nin0 et elle (rayon contre le décor).
## Une seule règle pour toutes les observations futures.

signal focus_changed(active: bool)
signal target_identified(target: FocusTarget)

enum Status { OK, TOO_FAR, BAD_ANGLE, HIDDEN }

## La capacité doit être débloquée (la démo la présente au rebord de la fenêtre).
@export var unlocked := false
@export var player: NinoController
@export var camera: ThirdPersonCamera
@export var overlay: FocusOverlay
@export var zoom_fov := 28.0
## Profil utilisé par les cibles qui n'en définissent pas.
@export var default_profile: ObservationProfile
## Couches qui masquent la vue (monde).
@export_flags_3d_physics var occlusion_mask := 1

var active := false
var lock_progress := 0.0
## Cible visée mais non observable (trop loin, mauvais angle) : retour visuel.
var aimed_status := Status.OK

var _locked: FocusTarget
var _normal_fov := 70.0


func _ready() -> void:
	_normal_fov = camera.get_camera().fov
	if default_profile == null:
		default_profile = ObservationProfile.new()


func _physics_process(delta: float) -> void:
	var wants := unlocked and Input.is_action_pressed("focus") and player.can_focus()
	if wants != active:
		_set_active(wants)
	if not active:
		return
	var cam := camera.get_camera()
	var result := find_aimed(cam.global_position, -cam.global_basis.z)
	var aimed: FocusTarget = result.target
	aimed_status = result.status
	if aimed_status != Status.OK:
		aimed = null
	if aimed != _locked:
		_locked = aimed
		lock_progress = 0.0
	if _locked and not _locked.is_identified:
		lock_progress = minf(lock_progress + delta / get_profile(_locked).lock_time, 1.0)
		if lock_progress >= 1.0:
			_locked.mark_identified()
			Sfx.play(&"focus_lock", -4.0)
			target_identified.emit(_locked)
	overlay.update_targets(_visible_markers(), _locked, lock_progress, aimed_status)


func get_profile(target: FocusTarget) -> ObservationProfile:
	return target.profile if target.profile else default_profile


## Cible la plus proche du centre de la vue, et son état d'observation.
## Une cible cachée par le décor est ignorée (elle n'est pas vue du tout).
func find_aimed(origin: Vector3, forward: Vector3) -> Dictionary:
	var best: FocusTarget = null
	var best_status := Status.OK
	var best_angle := INF
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		if not target.enabled or not target.is_visible_in_tree():
			continue
		# Une espèce déjà analysée n'est plus « à identifier ».
		if target.species and GameState.has_species(target.species.id):
			continue
		var profile := get_profile(target)
		var to_target := target.global_position - origin
		var distance := to_target.length()
		var angle := rad_to_deg(forward.angle_to(to_target))
		var tolerance := maxf(rad_to_deg(atan(target.radius * profile.aim_scale / maxf(distance, 0.01))), profile.min_aim_degrees)
		if angle >= tolerance or angle >= best_angle:
			continue
		var status := evaluate(target, origin)
		if status == Status.HIDDEN:
			continue
		best = target
		best_angle = angle
		best_status = status
	return {"target": best, "status": best_status}


## État d'observation d'une cible depuis un point de vue (sans tenir compte de la visée).
func evaluate(target: FocusTarget, origin: Vector3) -> Status:
	var profile := get_profile(target)
	var to_target := target.global_position - origin
	var distance := to_target.length()
	if profile.require_line_of_sight and not has_line_of_sight(target, origin):
		return Status.HIDDEN
	if distance > profile.max_distance:
		return Status.TOO_FAR
	var facing := target.get_facing()
	if facing != Vector3.ZERO and rad_to_deg(facing.angle_to(-to_target)) > profile.max_view_angle:
		return Status.BAD_ANGLE
	return Status.OK


## Vrai si aucun élément du décor ne s'interpose entre le point de vue et la cible.
func has_line_of_sight(target: FocusTarget, origin: Vector3) -> bool:
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, target.global_position, occlusion_mask, [player.get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	# Le rayon peut toucher le support de la cible (mur, porte) juste à côté d'elle.
	return (hit.position as Vector3).distance_to(target.global_position) <= 0.3


func _set_active(value: bool) -> void:
	active = value
	lock_progress = 0.0
	_locked = null
	aimed_status = Status.OK
	player.focus_lock = value
	camera.set_first_person(value)
	var cam := camera.get_camera()
	var tween := create_tween()
	tween.tween_property(cam, "fov", zoom_fov if value else _normal_fov, 0.25).set_trans(Tween.TRANS_SINE)
	overlay.set_active(value)
	player.get_visual().show_emotion(NinoVisual.Emotion.FOCUSED, 0.6 if value else 0.0)
	Sfx.play(&"focus_in" if value else &"focus_out", -10.0)
	focus_changed.emit(value)


func _visible_markers() -> Array:
	var cam := camera.get_camera()
	var markers := []
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		if target.enabled and target.show_marker and not target.is_identified and not cam.is_position_behind(target.global_position) \
				and evaluate(target, cam.global_position) != Status.HIDDEN:
			markers.append(cam.unproject_position(target.global_position))
	return markers
