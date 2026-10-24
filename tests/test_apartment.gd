extends Node
## Test de l'appartement (lot 4, verrous du lot 5) en mode développement, sans affichage.
##   godot --headless --fixed-fps 60 --path . res://tests/test_apartment.tscn
## Vérifie : placard intact, sept zones, dimensions, sols et plafonds, passages
## réellement franchissables sur roues, accès bloqués (salon fermé, cuisine au loquet,
## chambre), caméra, aucune sauvegarde.

const APARTMENT := preload("res://scenes/levels/apartment.tscn")
## Dimensions intérieures provisoires (unités ; 10 u = 1 m) : largeur x, profondeur z.
const EXPECTED := {
	1: Vector2(30.0, 27.0), 2: Vector2(29.4, 27.0), 3: Vector2(29.4, 34.4), 4: Vector2(29.4, 57.0),
	5: Vector2(20.0, 5.0), 6: Vector2(90.0, 44.4), 7: Vector2(29.4, 47.0),
}

var _failures := 0
var _dev: Node3D
var _nino: NinoController
var _camera: ThirdPersonCamera
var _personal_existed := false
var _personal := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_personal_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_existed else ""
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	_dev = APARTMENT.instantiate()
	add_child(_dev)
	_nino = _dev.nino
	_camera = _dev.camera
	await _wait(1.5)

	# 1. Mode développement : placard intact, session complète, aucune sauvegarde.
	var workshop: Node3D = _dev.workshop
	_check(GameState.dev_mode and _nino.controls_enabled and _nino.legs_available and _dev.workshop.focus_vision.unlocked,
			"mode développement actif : Nin0 complet et jouable")
	for path in ["Printer3D", "ClosetDoor", "PowerStrip", "Notebook", "Geometry/ChildDrawing", "Geometry/BenchTop", "Geometry/IroningBoard", "Pickups"]:
		_check(workshop.has_node(path), "placard intact : %s" % path)
	_check(not workshop.has_node("Sas") and not workshop.has_node("Geometry/SasBlocker"), "décor provisoire du sas remplacé par l'appartement")
	var demo := (load("res://scenes/levels/workshop.tscn") as PackedScene).get_state()
	var demo_nodes := []
	for i in demo.get_node_count():
		demo_nodes.append(String(demo.get_node_path(i)))
	_check(demo_nodes.has("./Sas") and demo_nodes.has("./Geometry/SasBlocker"), "la scène de la démo garde son sas et sa fin inchangés")
	var door: ClosetDoor = workshop.door
	_check(door.is_open and is_equal_approx(door.open_angle, 20.0), "porte du placard entrouverte (20°)")

	# 2. Sept zones, dimensions, sols et plafonds.
	_check(_dev._zones.size() == 7, "sept zones de référence")
	var space := _nino.get_world_3d().direct_space_state
	for number in EXPECTED:
		var zone: Area3D = _dev.get_zone(number)
		var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		var size := Vector2(box.size.x, box.size.z)
		_check(size.is_equal_approx(EXPECTED[number]), "zone %d (%s) : %.1f × %.1f m" % [number, zone.get_meta("title"), size.x / 10.0, size.y / 10.0])
		if number == 5:
			continue
		var c := zone.global_position + (Vector3(10.0, 0.0, 0.0) if number == 6 else Vector3.ZERO)  # à côté de la retombée du salon
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x, 3.0, c.z + 3.0), Vector3(c.x, -2.0, c.z + 3.0), 1))
		var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x, 3.0, c.z + 3.0), Vector3(c.x, 30.0, c.z + 3.0), 1))
		_check(not down.is_empty() and absf(down.position.y) < 0.05 and not up.is_empty() and absf(up.position.y - 23.9) < 0.2,
				"zone %d : sol à 0 et plafond à 2,39 m" % number)

	# 3. Passages réels, sur roues.
	_nino.force_mode(NinoController.Mode.WHEELS)
	_check(await _drive(Vector3(-12.5, 0.05, 1.45), 90.0, 2), "placard → sas par la porte entrouverte")
	_check(await _drive(Vector3(-38.0, 0.05, -7.5), 90.0, 3), "sas → salle de bain")
	_check(await _drive(Vector3(-41.0, 0.05, -7.5), -90.0, 2), "salle de bain → sas (retour)")
	_check(await _drive(Vector3(-19.5, 0.05, 1.35), -90.0, 1, 6.0), "sas → placard (retour vers l'imprimante)")
	# Lot 5 : le salon reste fermé pendant tout le chapitre (ouverture À DÉFINIR).
	_check(not await _drive(Vector3(-31.5, 0.05, 5.0), 180.0, 6, 3.0) and _dev.zone_at(_nino.global_position) == 2, "porte sas → salon fermée")
	_check(not await _drive(Vector3(-38.0, 0.05, 31.5), 90.0, 4, 3.0) and _dev.zone_at(_nino.global_position) == 6, "passage salon → cuisine fermé")
	_check(not await _drive(Vector3(-31.5, 0.05, 18.0), 0.0, 2, 3.0) and _dev.zone_at(_nino.global_position) == 6, "salon → sas fermé")
	# Lot 7 : une seule pièce, mais l'étape B est barrée par un encombrement physique
	# (bacs empilés, paravent, plante) tant que la suite n'est pas développée.
	_place(Vector3(-6.0, 0.05, 37.0), -90.0)
	var crossed := await _hold_until(6.0, func() -> bool: return _nino.global_position.x > 1.0)
	_check(not crossed and _dev.zone_at(_nino.global_position) == 6, "salon : étape B barrée par l'encombrement (même pièce, pas de mur invisible)")

	# 4. Accès bloqués.
	_check(not await _drive(Vector3(-40.0, 0.05, 8.0), 90.0, 4, 3.0) and _dev.zone_at(_nino.global_position) == 2, "porte sas → cuisine fermée (loquet)")
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.3)
	await _jump_toward(Vector3(-41.0, 0.05, 8.0), 90.0, 3.0)
	_check(_dev.zone_at(_nino.global_position) == 2, "même en sautant, la porte de la cuisine reste fermée")
	_nino.force_mode(NinoController.Mode.WHEELS)
	_check(not await _drive(Vector3(30.0, 0.05, 20.0), 0.0, 7, 3.0) and _dev.zone_at(_nino.global_position) == 6, "rideau de la chambre verrouillé")
	_check(_nino.global_position.z > 12.6, "Nin0 reste dans le salon devant le rideau (z = %.2f)" % _nino.global_position.z)
	_place(Vector3(-2.0, 0.05, 50.0), 180.0)
	await _hold_until(3.0, func() -> bool: return false)
	_check(_nino.global_position.z < 57.0, "porte-fenêtre fermée (jardin non jouable)")
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.3)
	var jumped := await _jump_toward(Vector3(30.0, 0.05, 15.0), 0.0, 3.0)
	_check(_nino.global_position.z > 12.6 and _dev.zone_at(_nino.global_position) != 7, "même en sautant, la chambre reste inaccessible")
	_nino.force_mode(NinoController.Mode.WHEELS)

	# 5. Mode développement : zones, caméra, outils.
	for number in [1, 2, 3, 4, 5, 6, 7]:
		_dev.go_to_zone(number)
		await _wait(0.8)
		var cam := _camera.get_camera().global_position
		var inside := space.intersect_point(_point_query(cam))
		_check(_dev.zone_at(_nino.global_position) == (6 if number == 5 else number) and inside.is_empty(),
				"aller à la zone %d : Nin0 placé, caméra hors des murs" % number)
	_key(KEY_3)
	await _wait(0.3)
	_check(_dev.zone_at(_nino.global_position) == 3, "touche 3 : salle de bain")
	_key(KEY_F2)
	_key(KEY_F3)
	await _wait(0.2)
	_check(_dev._map.visible and not _dev.blockout.get_node("Ceilings").visible, "carte (F2) et plafonds masqués (F3)")
	_key(KEY_F4)
	await _wait(0.3)
	_check(_dev._free and not _nino.controls_enabled, "caméra libre (F4), Nin0 immobilisé")
	_key(KEY_F4)
	_key(KEY_F2)
	_key(KEY_F3)
	await _wait(0.2)
	_check(not _dev._free and _nino.controls_enabled, "retour à Nin0")

	# 6. Sauvegardes : rien d'écrit en mode développement.
	GameState.save()
	GameState.collect_fragment(&"dev_test")
	_check(not FileAccess.file_exists(GameState.save_path), "aucune sauvegarde écrite en mode développement")
	GameState.dev_mode = false
	GameState.save_path = GameState.SAVE_PATH
	var now := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_existed and now == _personal, "la sauvegarde personnelle n'a pas été touchée")

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


## Place Nin0, roule tout droit et renvoie vrai s'il atteint la zone voulue.
func _drive(from: Vector3, yaw_degrees: float, zone: int, timeout := 6.0) -> bool:
	_place(from, yaw_degrees)
	await _wait(0.2)
	return await _hold_until(timeout, func() -> bool: return _dev.zone_at(_nino.global_position) == zone)


func _jump_toward(from: Vector3, yaw_degrees: float, seconds: float) -> bool:
	_place(from, yaw_degrees)
	Input.action_press("move_forward")
	for i in int(seconds / 0.5):
		Input.action_press("jump")
		await _wait(0.3)
		Input.action_release("jump")
		await _wait(0.2)
	Input.action_release("move_forward")
	return true


func _place(position: Vector3, yaw_degrees: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = deg_to_rad(yaw_degrees)
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = deg_to_rad(yaw_degrees)
	_camera.snap_to_target()


func _point_query(point: Vector3) -> PhysicsPointQueryParameters3D:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	return query


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame


func _hold_until(timeout: float, condition: Callable) -> bool:
	Input.action_press("move_forward")
	var success := false
	for i in ceili(timeout * 60.0):
		await get_tree().physics_frame
		if condition.call():
			success = true
			break
	Input.action_release("move_forward")
	return success


func _wait(seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "ÉCHEC", label])
	if not condition:
		_failures += 1
