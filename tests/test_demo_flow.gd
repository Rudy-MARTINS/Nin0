extends Node
## Test de bout en bout de la première démo, sans affichage.
## Lancement (depuis la racine du projet) :
##   godot --headless --fixed-fps 60 --path . res://tests/test_demo_flow.tscn
## Code de sortie 0 = succès, 1 = échec.
##
## Les entrées sont simulées comme des appuis de touches réels. Quelques trajets
## sont raccourcis par téléportation ; l'escalade des cartons et la montée vers la
## fenêtre sont, elles, jouées réellement.

const LEVEL := preload("res://scenes/levels/workshop.tscn")

var _failures := 0
var _level: Node3D
var _nino: NinoController
var _camera: ThirdPersonCamera


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.erase_save()
	GameState.reset_progress()
	GameState.skip_title_once = true
	_level = LEVEL.instantiate()
	add_child(_level)
	_nino = _level.get_node("Nino")
	_camera = _level.get_node("ThirdPersonCamera")
	await _wait(1.6)

	# 1. Réveil interactif.
	_check(not _nino.controls_enabled and _level._waiting_wake_input, "NINO attend le réveil (commandes bloquées)")
	await _hold(["move_forward"], 0.1)
	await _wait(6.5)
	_check(GameState.woke_up and _nino.controls_enabled, "NINO s'est réveillé et répond aux commandes")
	_check(GameState.get_objective() == "Explorer l'établi", "objectif initial : %s" % GameState.get_objective())
	var start := _nino.global_position
	await _hold(["move_forward"], 1.0)
	_check(start.distance_to(_nino.global_position) > 1.0, "NINO roule sur l'établi")

	# Passages du sol : le tube en carton et le dessous du fauteuil.
	_place(Vector3(-6.0, 0.05, -6.5), -PI / 2)
	await _hold(["move_forward"], 3.6)
	_check(_nino.global_position.x > 2.5, "NINO traverse le tube en carton (x = %.2f)" % _nino.global_position.x)
	_place(Vector3(-5.0, 0.05, 5.5), PI / 2)
	await _hold(["move_forward"], 2.5)
	_check(_nino.global_position.x < -10.0, "NINO passe sous le fauteuil (x = %.2f)" % _nino.global_position.x)

	# Les marches vers la fenêtre sont trop hautes pour les roues.
	_place(Vector3(-10.2, 8.05, -9.8), PI / 2)
	await _hold(["move_forward"], 2.0)
	_check(_nino.global_position.y < 8.3, "les marches vers la fenêtre sont infranchissables sur roues")

	# 2. Imprimante hors tension.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	var interactor: Interactor = _nino.get_node("Interactor")
	_check(interactor.focused == _level.printer.interactable, "l'imprimante est détectée comme interactive")
	await _tap("interact")
	var panel: PrinterPanel = _level.printer_panel
	_check(panel.visible and GameState.printer_seen, "l'interface de l'imprimante s'ouvre")
	_check(panel.get_node("Center/Panel/Margin/VBox/Buttons/PrintButton").disabled, "impression impossible sans alimentation")
	_check(not _nino.controls_enabled, "NINO est immobilisé pendant l'interface")
	await _tap("interact")
	_check(not panel.visible and _nino.controls_enabled, "l'interface se ferme")
	_check(GameState.get_objective() == "Rétablir l'alimentation de l'imprimante", "objectif : alimentation")

	# 3. Multiprise sous l'établi.
	_place(Vector3(-4.6, 0.05, -12.4), 0.0)
	await _wait(0.4)
	_check(interactor.focused == _level.power_strip.interactable, "la multiprise est détectée")
	await _tap("interact")
	await _wait(0.6)
	_check(GameState.power_on and _level.printer.is_powered(), "la multiprise alimente l'imprimante")

	# 4. Remontée réelle par les cartons (escalade x2 puis l'établi).
	_place(Vector3(5.5, 0.05, -7.3), 0.0)
	var climbed := await _hold_until(["move_forward"], 16.0, func() -> bool: return _nino.global_position.y > 7.9 and _nino.state == NinoController.State.FREE)
	_check(climbed, "NINO escalade les deux cartons (y = %.2f)" % _nino.global_position.y)
	await _hold(["move_left"], 1.6)
	_check(_nino.global_position.x < 3.0 and absf(_nino.global_position.y - 8.0) < 0.1, "NINO rejoint l'établi (x = %.2f, y = %.2f)" % [_nino.global_position.x, _nino.global_position.y])

	# 5. Impression.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	await _tap("interact")
	_check(panel.visible and not panel.get_node("Center/Panel/Margin/VBox/Buttons/PrintButton").disabled, "impression disponible")
	await _tap("interact")
	await _wait(0.3)
	_check(_level.printer.state in [Printer3D.State.HEATING, Printer3D.State.PRINTING], "l'impression démarre")
	await _wait(_level.printer.heat_duration + _level.printer.print_duration * 0.5)
	_check(_level.printer.state == Printer3D.State.PRINTING, "impression en cours (progression visible)")
	await _wait(_level.printer.print_duration * 0.5 + 2.5)
	_check(GameState.legs_printed and _level.printer.state == Printer3D.State.DONE, "les jambes sont imprimées")

	# 6. Installation.
	await _wait(0.3)
	_check(interactor.focused == _level.printer.interactable and _level.printer.interactable.prompt == "Récupérer les jambes", "action « Récupérer les jambes »")
	await _tap("interact")
	await _wait(6.0)
	_check(GameState.legs_installed and _nino.legs_available and _nino.controls_enabled, "jambes installées, NINO à nouveau contrôlable")
	_check(GameState.has_save(), "la progression (jambes) est sauvegardée")

	# 7. Transformation : refusée en mouvement, acceptée à l'arrêt.
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
	_check(_nino.global_position.distance_to(before) < 0.05, "pas de téléportation à la transformation")

	# 8. Saut et refus de transformation en l'air.
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
	_check(_nino.mode == NinoController.Mode.LEGS and _nino.state == NinoController.State.FREE, "transformation refusée en l'air")
	await _wait(1.0)
	var legs_start := _nino.global_position
	await _hold(["move_forward"], 1.0)
	var legs_speed := legs_start.distance_to(_nino.global_position)
	_check(legs_speed > 0.8 and legs_speed < 2.2, "le mode jambes est plus lent (%.2f u/s)" % legs_speed)

	# 9. Retour aux roues puis à nouveau jambes (aller-retour).
	await _wait(1.0)
	await _tap("switch_mode")
	await _wait(1.3)
	_check(_nino.mode == NinoController.Mode.WHEELS, "retour au mode roues")
	await _tap("switch_mode")
	await _wait(1.3)

	# 10. Montée réelle jusqu'au rebord de la fenêtre (sauts successifs).
	_check(_nino.mode == NinoController.Mode.LEGS, "mode jambes avant la montée")
	_place(Vector3(-10.2, 8.05, -9.8), PI / 2)
	await _wait(0.3)
	Input.action_press("move_forward")
	for i in 8:
		await _hold(["jump"], 0.3)
		await _wait(0.5)
		if GameState.demo_completed:
			break
	Input.action_release("move_forward")
	_check(GameState.demo_completed, "NINO atteint le rebord de la fenêtre (y = %.2f)" % _nino.global_position.y)
	await _wait(9.0)
	_check(_level.end_screen.visible, "l'écran de fin s'affiche")
	var end_line: Label = _level.end_screen.get_node("Content/VBox/Line")
	_check(end_line.text == "Fin de la première démo", "texte de conclusion")

	# 11. Écran titre : « Continuer » reprend avec les jambes installées.
	_level.queue_free()
	await get_tree().process_frame
	GameState.reset_progress()
	_check(GameState.has_save(), "une sauvegarde existe au retour à l'écran titre")
	_level = LEVEL.instantiate()
	add_child(_level)
	_nino = _level.get_node("Nino")
	await _wait(0.5)
	var title: TitleScreen = _level.title_screen
	_check(title.visible and title.get_node("Panel/Margin/VBox/Buttons/ContinueButton").visible, "écran titre avec « Continuer »")
	title.get_node("Panel/Margin/VBox/Buttons/ContinueButton").emit_signal("pressed")
	await _wait(1.5)
	_check(_nino.legs_available and _nino.controls_enabled and GameState.power_on, "reprise : jambes installées, NINO jouable")
	_check(GameState.get_objective() == "Déployer les jambes", "reprise : objectif « Déployer les jambes »")

	# 12. « Nouvelle partie » efface la progression.
	_level.queue_free()
	await get_tree().process_frame
	_level = LEVEL.instantiate()
	add_child(_level)
	_nino = _level.get_node("Nino")
	await _wait(0.5)
	_level.title_screen.get_node("Panel/Margin/VBox/Buttons/StartButton").emit_signal("pressed")
	await _wait(1.5)
	_check(not GameState.has_save() and not _nino.legs_available and not GameState.woke_up, "nouvelle partie : progression effacée")
	GameState.erase_save()

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _place(position: Vector3, yaw: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = yaw
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = yaw
	_camera.snap_to_target()


func _wait(seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame


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
	var success := false
	for i in ceili(timeout * 60.0):
		await get_tree().physics_frame
		if condition.call():
			success = true
			break
	for action in actions:
		Input.action_release(action)
	return success


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "ÉCHEC", label])
	if not condition:
		_failures += 1
