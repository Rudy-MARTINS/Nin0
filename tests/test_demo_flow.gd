extends Node
## Test de bout en bout de la première démo (lot 2), sans affichage.
## Lancement (depuis la racine du projet) :
##   godot --headless --fixed-fps 60 --path . res://tests/test_demo_flow.tscn
## Code de sortie 0 = succès, 1 = échec.
##
## Les entrées sont simulées comme des appuis réels. Les trajets entre deux étapes
## sont raccourcis par téléportation ; les passages physiques (bobine poussée,
## rampes, carnet, sauts jusqu'à la fenêtre, parcours de l'étagère) sont joués.

const LEVEL := preload("res://scenes/levels/workshop.tscn")

var _failures := 0
var _level: Node3D
var _nino: NinoController
var _camera: ThirdPersonCamera
var _thoughts: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.erase_save()
	GameState.reset_progress()
	GameState.skip_title_once = true
	_load_level()
	await _wait(1.6)

	# 1. Réveil interactif et pensées.
	_check(not _nino.controls_enabled and _level._waiting_wake_input, "NINO attend le réveil (commandes bloquées)")
	await _hold(["move_forward"], 0.1)
	await _wait(6.5)
	_check(GameState.woke_up and _nino.controls_enabled, "NINO s'est réveillé et répond aux commandes")
	_check(_saw_thought([&"ellipsis"]) and _saw_thought([&"question"]), "pensées du réveil : confusion puis interrogation")

	# 2. Mini-tutoriel : chaque action doit être réellement effectuée.
	_check(GameState.get_objective() == "Prendre ses repères", "objectif pendant le tutoriel")
	_check(_level._tutorial == _level.Tutorial.FORWARD, "tutoriel : avancer")
	await _hold(["move_right"], 0.8)
	_check(_level._tutorial == _level.Tutorial.FORWARD, "tutoriel : tourner ne valide pas « avancer »")
	await _hold(["move_forward"], 1.2)
	_check(_level._tutorial == _level.Tutorial.BACK, "tutoriel : reculer")
	await _hold(["move_back"], 1.6)
	_check(_level._tutorial == _level.Tutorial.CAMERA, "tutoriel : orienter la caméra")
	# Sans affichage, la souris ne peut pas être capturée : on reproduit l'effet
	# d'un mouvement de souris (rotation progressive de la caméra).
	for i in 20:
		_camera.rotation.y += 0.07
		await get_tree().physics_frame
	await _wait(0.2)
	_check(GameState.tutorial_done and GameState.get_objective() == "Explorer l'établi", "tutoriel terminé, objectif « Explorer l'établi »")

	# 3. Découvertes (facultatives).
	var interactor: Interactor = _nino.get_node("Interactor")
	_place(Vector3(-6.2, 8.05, -11.6), PI)
	await _wait(0.4)
	_check(interactor.focused != null and interactor.focused.name == "ExamineServo", "le servomoteur est détectable")
	await _tap("interact")
	await _wait(0.3)
	_check(GameState.has_discovery(&"spare_servo") and not _level.get_node("Geometry/SpareServo").visible, "le servomoteur est emporté (découverte)")
	_place(Vector3(-13.6, 8.05, -11.5), PI / 2)
	await _wait(0.4)
	await _tap("interact")
	await _wait(0.3)
	_check(GameState.has_discovery(&"child_drawing") and GameState.discoveries.size() == 2, "le dessin est examiné")

	# 4. Imprimante hors tension → NINO comprend qu'il manque de l'énergie.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	_check(interactor.focused == _level.printer.interactable, "l'imprimante est détectée comme interactive")
	await _tap("interact")
	var panel: PrinterPanel = _level.printer_panel
	_check(panel.visible and GameState.printer_seen, "l'interface de l'imprimante s'ouvre")
	_check(panel.get_node("Center/Panel/Margin/VBox/Buttons/PrintButton").disabled, "impression impossible sans alimentation")
	await _tap("interact")
	_check(not panel.visible and _nino.controls_enabled, "l'interface se ferme (sans se rouvrir)")
	await _wait(0.5)
	_check(_saw_thought([&"printer", &"cross", &"energy"]), "pensée : l'imprimante n'a pas d'énergie")
	_check(GameState.get_objective() == "Rétablir l'alimentation de l'imprimante", "objectif : alimentation")

	# 5. Le câble mène à la multiprise.
	_place(Vector3(3.8, 8.05, -12.6), 0.0)
	await _wait(0.4)
	_check(_saw_thought([&"plug", &"down"]), "pensée : le câble descend")
	_place(Vector3(-4.6, 0.05, -12.4), 0.0)
	await _wait(0.4)
	_check(_saw_thought([&"plug", &"exclamation"]), "pensée : la multiprise est trouvée")
	_check(interactor.focused == _level.power_strip.interactable, "la multiprise est détectée")
	await _tap("interact")
	await _wait(3.5)
	_check(GameState.power_on and _level.printer.is_powered(), "la multiprise alimente l'imprimante")
	_check(_saw_thought([&"plug", &"arrow", &"printer", &"energy"]), "pensée : NINO relie la multiprise à l'imprimante")
	_check(GameState.get_objective() == "Retourner à l'imprimante", "objectif : retourner à l'imprimante")

	# 6. Retour sur roues : planche à repasser → bobine poussée dans l'encoche → planche → table.
	_place(Vector3(13.5, 0.05, 7.4), 0.0)
	var on_p1 := await _hold_until(["move_forward"], 8.0, func() -> bool: return _nino.global_position.y > 5.4 and _nino.global_position.z < -5.3)
	_check(on_p1, "NINO monte la planche à repasser sur roues (y = %.2f)" % _nino.global_position.y)
	var slotted := await _hold_until(["move_forward"], 8.0, func() -> bool: return _level.spool_slot.is_filled())
	_check(slotted, "NINO pousse une bobine dans l'encoche")
	await _wait(0.6)
	var crossed := await _hold_until(["move_forward"], 6.0, func() -> bool: return _nino.global_position.z < -12.9)
	_check(crossed and _nino.global_position.y > 5.4, "NINO traverse la bobine jusqu'à la seconde pile (z = %.2f)" % _nino.global_position.z)
	var on_table := await _hold_until(["move_left"], 8.0, func() -> bool: return _nino.global_position.x < 2.6)
	_check(on_table and absf(_nino.global_position.y - 8.0) < 0.15, "NINO rejoint la table par la planche (x = %.2f, y = %.2f)" % [_nino.global_position.x, _nino.global_position.y])
	_check(_nino.mode == NinoController.Mode.WHEELS and _nino.state == NinoController.State.FREE, "parcours entièrement sur roues, sans escalade")

	# 7. Compréhension de l'imprimante puis impression.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	await _tap("interact")
	await _wait(5.0)
	_check(_saw_thought([&"printer", &"arrow", &"gear"]) and GameState.printer_understood, "pensée : l'imprimante fabrique des pièces")
	_check(panel.visible and not panel.get_node("Center/Panel/Margin/VBox/Buttons/PrintButton").disabled, "impression disponible")
	await _tap("interact")
	await _wait(0.3)
	_check(_level.printer.state in [Printer3D.State.HEATING, Printer3D.State.PRINTING], "l'impression démarre")
	await _wait(_level.printer.heat_duration + _level.printer.print_duration * 0.5)
	_check(GameState.get_objective().begins_with("Impression en cours") and GameState.get_objective().ends_with("%"), "objectif avec progression : %s" % GameState.get_objective())
	await _wait(_level.printer.print_duration * 0.5 + 2.5)
	_check(GameState.legs_printed and _level.printer.state == Printer3D.State.DONE, "les jambes sont imprimées")
	_check(GameState.get_objective() == "Rejoindre la plateforme d'impression", "objectif : rejoindre la plateforme")

	# 8. Le carnet renversé forme une rampe ; NINO monte sur le plateau.
	_place(Vector3(-0.6, 8.05, -8.3), 0.0)
	await _wait(0.4)
	_check(interactor.focused == _level.notebook.interactable, "le carnet peut être poussé")
	await _tap("interact")
	await _wait(1.2)
	_check(_level.notebook.is_toppled, "le carnet est renversé")
	var installing := await _hold_until(["move_forward"], 4.0, func() -> bool: return _nino.state == NinoController.State.SCRIPTED)
	_check(installing, "NINO monte la rampe et la machine le détecte sur le plateau")
	var installed := await _wait_until(16.0, func() -> bool: return GameState.legs_installed and _nino.controls_enabled)
	_check(installed and _nino.legs_available, "jambes installées sur le plateau, NINO à nouveau contrôlable")
	_check(GameState.has_save(), "la progression (jambes) est sauvegardée")

	# 9. Transformation : refusée en mouvement, acceptée à l'arrêt, sans téléportation.
	_place(Vector3(-6, 8.05, -10.5), PI / 2)
	Input.action_press("move_forward")
	await _wait(0.6)
	await _tap("switch_mode")
	Input.action_release("move_forward")
	_check(_nino.mode == NinoController.Mode.WHEELS and _nino.state != NinoController.State.TRANSFORMING, "transformation refusée en mouvement")
	await _wait(1.2)
	var before := _nino.global_position
	await _tap("switch_mode")
	_check(_nino.state == NinoController.State.TRANSFORMING, "transformation lancée à l'arrêt")
	await _wait(0.4)
	_check(_nino.global_position.distance_to(before) < 0.05, "NINO reste immobile pendant la transformation")
	await _wait(0.8)
	_check(_nino.mode == NinoController.Mode.LEGS and GameState.legs_deployed_once, "mode jambes actif")
	_check(_saw_thought([&"legs", &"exclamation"]), "réaction de surprise aux premiers pas")
	await _wait(1.5)

	# 10. Saut, refus en l'air, vitesse.
	var ground := _nino.global_position.y
	var peak := ground
	Input.action_press("jump")
	for i in 30:
		await get_tree().physics_frame
		peak = maxf(peak, _nino.global_position.y)
		if i == 10:
			await _tap("switch_mode")
	Input.action_release("jump")
	_check(peak - ground > 0.8, "NINO saute en mode jambes (%.2f u)" % (peak - ground))
	_check(_nino.mode == NinoController.Mode.LEGS, "transformation refusée en l'air")
	await _wait(1.0)
	var legs_start := _nino.global_position
	await _hold(["move_forward"], 1.0)
	var legs_speed := legs_start.distance_to(_nino.global_position)
	_check(legs_speed > 0.8 and legs_speed < 2.2, "le mode jambes est plus lent (%.2f u/s)" % legs_speed)

	# 11. Montée jusqu'au rebord de la fenêtre (sauts réels).
	_place(Vector3(-11.4, 8.05, -9.6), 0.0)
	await _wait(0.3)
	var reached := await _jump_route(["move_forward"], 10, func() -> bool: return GameState.reached_window)
	_check(reached, "NINO atteint le rebord de la fenêtre (y = %.2f)" % _nino.global_position.y)
	await _wait(2.5)
	_check(_saw_thought([&"door", &"question"]) and _level.focus_vision.unlocked, "NINO remarque la porte ; la vision focalisée est disponible")
	_check(GameState.get_objective() == "Observer la porte", "objectif : observer la porte")

	# 12. Vision focalisée : viser la poignée l'identifie.
	var handle: Vector3 = _level.door.get_grip_position()
	var head := _nino.global_position + Vector3.UP * (_nino.get_focus_height() + 0.12)
	var to_handle: Vector3 = handle - head
	_camera.rotation.y = atan2(-to_handle.x, -to_handle.z)
	_camera.pitch = atan2(to_handle.y, Vector2(to_handle.x, to_handle.z).length())
	Input.action_press("focus")
	await _wait(0.4)
	_check(_level.focus_vision.active and _nino.focus_lock, "vision focalisée active (NINO immobile)")
	await _wait(1.2)
	Input.action_release("focus")
	await _wait(0.5)
	_check(GameState.handle_identified and _level.door.interactable.enabled, "la poignée est identifiée")
	_check(_saw_thought([&"handle", &"exclamation"]), "pensée : NINO comprend qu'il peut l'atteindre")
	_check(GameState.get_objective() == "Atteindre la poignée de la porte", "objectif : atteindre la poignée")

	# 13. Parcours final : boîtes, livres, étagère (sauts réels), puis la poignée.
	_place(Vector3(-13.8, 8.05, -11.4), PI)
	await _wait(0.3)
	var at_handle := await _jump_route(["move_forward"], 16, func() -> bool: return interactor.focused == _level.door.interactable)
	_check(at_handle and _nino.global_position.y > 9.7, "NINO franchit l'étagère jusqu'à la poignée (z = %.2f)" % _nino.global_position.z)
	await _wait(0.4)
	await _tap("interact")
	var opened := await _wait_until(10.0, func() -> bool: return _level.door.is_open and _level.end_screen.visible)
	_check(opened and GameState.demo_completed, "la porte s'ouvre et la démo se conclut")
	var end_line: Label = _level.end_screen.get_node("Content/VBox/Line")
	_check(end_line.text == "Fin de la première démo", "texte de conclusion")

	# 14. Écran titre : « Continuer » reprend avec les jambes et le chemin en place.
	_level.queue_free()
	await get_tree().process_frame
	GameState.reset_progress()
	_check(GameState.has_save(), "une sauvegarde existe au retour à l'écran titre")
	_load_level()
	await _wait(0.5)
	var title: TitleScreen = _level.title_screen
	_check(title.visible and title.get_node("Panel/Margin/VBox/Buttons/ContinueButton").visible, "écran titre avec « Continuer »")
	title.get_node("Panel/Margin/VBox/Buttons/ContinueButton").emit_signal("pressed")
	await _wait(1.5)
	_check(_nino.legs_available and _nino.controls_enabled and GameState.power_on, "reprise : jambes installées, NINO jouable")
	_check(_level.spool_slot.is_filled() and _level.notebook.is_toppled, "reprise : bobine et carnet en place")
	_check(GameState.discoveries.size() == 2, "reprise : découvertes conservées")

	# 15. « Nouvelle partie » efface tout ; bobines récupérables.
	_level.queue_free()
	await get_tree().process_frame
	_load_level()
	await _wait(0.5)
	_level.title_screen.get_node("Panel/Margin/VBox/Buttons/StartButton").emit_signal("pressed")
	await _wait(1.5)
	_check(not GameState.has_save() and not _nino.legs_available and not GameState.woke_up and GameState.discoveries.is_empty(), "nouvelle partie : progression effacée")
	_check(not _level.spool_slot.is_filled() and not _level.notebook.is_toppled, "nouvelle partie : énigmes réinitialisées")
	var spool: PushableSpool = _level.spools[0]
	var spool_start := spool.global_position
	spool.global_position = Vector3(9.0, 1.0, -6.6)
	await _wait(2.0)
	_check(spool.global_position.distance_to(spool_start) < 0.2, "une bobine tombée revient à sa place")
	spool.global_position = spool_start + Vector3(0.0, 0.0, -0.6)
	_nino.respawn()
	await _wait(0.2)
	_check(spool.global_position.distance_to(spool_start) < 0.2, "revenir au point sûr (R) replace les bobines")
	GameState.erase_save()

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _load_level() -> void:
	_level = LEVEL.instantiate()
	add_child(_level)
	_nino = _level.get_node("Nino")
	_camera = _level.get_node("ThirdPersonCamera")
	_level.thoughts.thought_requested.connect(func(icons: Array, _text: String) -> void: _thoughts.append(icons))


func _saw_thought(icons: Array) -> bool:
	return _thoughts.has(icons)


func _place(position: Vector3, yaw: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = yaw
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = yaw
	_camera.snap_to_target()


func _wait(seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame


func _wait_until(timeout: float, condition: Callable) -> bool:
	for i in ceili(timeout * 60.0):
		await get_tree().physics_frame
		if condition.call():
			return true
	return false


## Appui bref, transmis comme un vrai événement (interfaces et actions).
func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().physics_frame


func _hold(actions: Array, seconds: float) -> void:
	for action in actions:
		Input.action_press(action)
	await _wait(seconds)
	for action in actions:
		Input.action_release(action)


func _hold_until(actions: Array, timeout: float, condition: Callable) -> bool:
	for action in actions:
		Input.action_press(action)
	var success := await _wait_until(timeout, condition)
	for action in actions:
		Input.action_release(action)
	return success


## Avance en sautant régulièrement (saut maintenu 0,3 s), jusqu'à la condition.
func _jump_route(actions: Array, jumps: int, condition: Callable) -> bool:
	for action in actions:
		Input.action_press(action)
	var success := false
	for i in jumps:
		Input.action_press("jump")
		if await _wait_until(0.3, condition):
			success = true
		Input.action_release("jump")
		if success or await _wait_until(0.45, condition):
			success = true
			break
	for action in actions:
		Input.action_release(action)
	Input.action_release("jump")
	return success


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "ÉCHEC", label])
	if not condition:
		_failures += 1
