extends Node
## Test automatique du Lot 1 (déplacement roues + escalade), sans affichage.
## Lancement (depuis la racine du projet) :
##   godot --headless --fixed-fps 60 --path . res://tests/test_lot1_movement.tscn
## Code de sortie 0 = succès, 1 = échec.

const LEVEL := preload("res://scenes/levels/test_level.tscn")

var _failures := 0
var _nino: NinoController
var _camera: ThirdPersonCamera


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	_nino = level.get_node("Nino")
	_camera = level.get_node("ThirdPersonCamera")
	await _wait(0.5)

	# 0. Pas de saut en mode roues (GDD §3).
	var ground_y := _nino.global_position.y
	await _hold(["jump"], 0.4)
	_check(_nino.mode == NinoController.Mode.WHEELS and _nino.global_position.y <= ground_y + 0.01,
			"aucun saut possible en mode roues")

	# 1. Rouler vers l'avant.
	var start := _nino.global_position
	await _hold(["move_forward"], 1.0)
	_check(start.z - _nino.global_position.z > 1.5, "Nino roule vers l'avant (%.2f u)" % (start.z - _nino.global_position.z))
	_check(_nino.is_on_floor(), "Nino reste au sol")
	await _wait(1.0)
	_check(Vector3(_nino.velocity.x, 0, _nino.velocity.z).length() < 0.05, "Nino décélère jusqu'à l'arrêt")

	# 2. Rotation progressive : demander la droite ne tourne pas instantanément.
	_place(Vector3(0, 0.02, 6), 0.0)
	await _wait(0.2)
	Input.action_press("move_right")
	await _wait(1.0 / 60.0)
	var yaw_after_one_frame := absf(_nino.rotation.y)
	await _wait(0.5)
	Input.action_release("move_right")
	_check(yaw_after_one_frame < 0.3 and absf(absf(_nino.rotation.y) - PI / 2) < 0.1,
			"rotation progressive vers la droite")

	# 3. Surface NON escaladable (tasse) : pas d'escalade.
	_place(Vector3(-1.5, 0.02, -3.3), 0.0)
	var climbed_mug := await _hold_and_watch(["move_forward"], 2.0)
	_check(not climbed_mug and _nino.global_position.y < 0.1, "la tasse n'est pas escaladable")

	# 3b. Lot 7 : l'escalade libre est désactivée par défaut (le carton reste un obstacle).
	_check(not _nino.climbing_enabled, "escalade libre désactivée par défaut (lot 7)")
	_place(Vector3(4, 0.02, 0.2), 0.0)
	var climbed_disabled := await _hold_and_watch(["move_forward"], 1.6)
	_check(not climbed_disabled and _nino.global_position.y < 0.1, "sans escalade, le carton reste un obstacle")
	# Mécanique conservée (prototypes) : on la réactive pour vérifier le code existant.
	_nino.climbing_enabled = true

	# 4. Carton escaladable : accroche, montée, hissage sur le dessus.
	_place(Vector3(4, 0.02, 0.2), 0.0)
	var climbed_box := await _hold_and_watch(["move_forward"], 2.2)
	await _wait(0.5)
	_check(climbed_box, "Nino s'accroche au carton")
	_check(_nino.state == NinoController.State.FREE and absf(_nino.global_position.y - 1.6) < 0.03,
			"Nino se hisse sur le carton (y = %.2f)" % _nino.global_position.y)

	# 5. Lâcher la paroi en cours d'escalade.
	_place(Vector3(4, 0.02, 0.2), 0.0)
	await _hold(["move_forward"], 1.2)
	_check(_nino.state == NinoController.State.CLIMBING, "Nino est en escalade à mi-hauteur")
	Input.action_press("release_grip")
	await _wait(1.0 / 60.0)
	Input.action_release("release_grip")
	await _wait(1.5)
	_check(_nino.state == NinoController.State.FREE and _nino.global_position.y < 0.1, "Nino lâche la paroi et retombe")

	# 6. Descendre une paroi jusqu'au sol.
	_place(Vector3(4, 0.02, 0.2), 0.0)
	await _hold(["move_forward"], 1.0)
	await _hold(["move_back"], 2.0)
	_check(_nino.state == NinoController.State.FREE and _nino.global_position.y < 0.1, "Nino redescend au sol")

	# 6b. Angle sortant : en se décalant au-delà de l'arête, Nin0 passe sur la face voisine.
	_place(Vector3(4.8, 0.02, 0.2), 0.0)
	await _hold(["move_forward"], 1.2)
	await _hold(["move_right"], 2.2)
	_check(_nino.state == NinoController.State.CLIMBING and _nino.global_position.x > 5.55,
			"Nin0 contourne l'angle du carton (x = %.2f)" % _nino.global_position.x)
	Input.action_press("release_grip")
	await _wait(1.0 / 60.0)
	Input.action_release("release_grip")
	await _wait(1.0)

	# 6c. Descente : depuis le dessus du carton, rouler au-delà du bord accroche Nin0 à la paroi.
	_place(Vector3(4, 1.62, -2.0), PI)
	await _wait(0.3)
	var grabbed := false
	Input.action_press("move_forward")
	for i in 90:
		await get_tree().physics_frame
		if _nino.state == NinoController.State.CLIMBING:
			grabbed = true
			break
	Input.action_release("move_forward")
	_check(grabbed, "Nin0 s'accroche en quittant le bord du carton")
	await _hold(["move_back"], 2.5)
	_check(_nino.state == NinoController.State.FREE and _nino.global_position.y < 0.1, "Nin0 redescend la paroi jusqu'au sol")

	# 7. Escalade latérale limitée à la surface : impossible de dépasser le bord.
	_place(Vector3(5, 0.02, -8.5), 0.0)
	await _hold(["move_forward"], 2.0)
	await _hold(["move_right"], 3.0)
	_check(_nino.state == NinoController.State.CLIMBING and _nino.global_position.x < 6.1,
			"Nino reste sur le panneau de liège (x = %.2f)" % _nino.global_position.x)
	await _hold(["move_forward"], 2.5)
	await _wait(0.5)
	_check(absf(_nino.global_position.y - 3.1) < 0.1, "Nino atteint l'étagère (y = %.2f)" % _nino.global_position.y)

	# 8. Pente (planchette) jusqu'au dictionnaire, sans escalade.
	_place(Vector3(0, 0.02, -1), PI / 2)
	var climbed_ramp := await _hold_and_watch(["move_forward"], 1.9)
	_check(not climbed_ramp and _nino.global_position.y > 0.6, "Nino monte la pente (y = %.2f)" % _nino.global_position.y)

	# 9. Réapparition.
	_place(Vector3(0, -20, 0), 0.0)
	await _wait(0.1)
	_check(_nino.global_position.distance_to(Vector3(0, 0.02, 5)) < 0.2, "réapparition sous la limite de chute")

	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _place(position: Vector3, yaw: float) -> void:
	_nino.respawn()
	_nino.global_position = position
	_nino.rotation.y = yaw
	_camera.rotation.y = yaw
	_camera.global_position = position


func _wait(seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame


func _hold(actions: Array, seconds: float) -> void:
	await _hold_and_watch(actions, seconds)


## Maintient des actions ; renvoie true si Nino est passé en escalade pendant ce temps.
func _hold_and_watch(actions: Array, seconds: float) -> bool:
	var climbed := false
	for action in actions:
		Input.action_press(action)
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame
		climbed = climbed or _nino.state != NinoController.State.FREE
	for action in actions:
		Input.action_release(action)
	return climbed


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "ÉCHEC", label])
	if not condition:
		_failures += 1
