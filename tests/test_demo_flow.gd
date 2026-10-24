extends Node
## Test de bout en bout de la première démo (lots 2 et 3), sans affichage.
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
var _thought_texts: Array[String] = []
var _personal_save_existed := false
var _personal_save := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_personal_save_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal_save = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_save_existed else ""
	# Sauvegarde dédiée : la sauvegarde personnelle du joueur n'est jamais touchée.
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	GameState.reset_progress()
	GameState.skip_title_once = true
	_load_level()
	await _wait(1.6)

	_check(Music.has_track(&"intro") and Music.current == &"intro" and not Music.play_once(&"intro"),
			"musique d'introduction lancée une seule fois au démarrage (bus Music)")
	# 1. Réveil interactif et pensées.
	_check(not _nino.controls_enabled and _level._waiting_wake_input, "Nin0 attend le réveil (commandes bloquées)")
	await _hold(["move_forward"], 0.1)
	await _wait(1.0)
	var frames := 60
	_check(Music.desired == &"hub" and not _nino.controls_enabled, "l'éveil commence : la musique du hub prend le relais en fondu pendant le réveil")
	var awake := false
	for i in 900:
		await get_tree().physics_frame
		frames += 1
		if GameState.woke_up and _nino.controls_enabled:
			awake = true
			break
	var boot_seconds := frames / 60.0
	_check(awake and boot_seconds > 6.0 and boot_seconds < 14.0, "réveil progressif (%.1f s), sans longueur excessive" % boot_seconds)
	_check(GameState.woke_up and _nino.controls_enabled, "Nin0 s'est réveillé et répond aux commandes")
	_check(Music.desired == &"hub" and Music.current != &"intro", "début du jeu : l'introduction s'arrête, la musique du hub prend le relais")
	_check(_saw_thought([&"ellipsis"]) and _saw_thought([&"question"]), "pensées du réveil : confusion puis interrogation")

	# 2. Mini-tutoriel : chaque action doit être réellement effectuée.
	_check(GameState.get_objective() == "Prendre ses repères", "objectif pendant le tutoriel")
	_check(_level._tutorial == _level.Tutorial.FORWARD, "tutoriel : avancer")
	await _hold(["move_right"], 0.8)
	_check(_level._tutorial == _level.Tutorial.FORWARD, "tutoriel : tourner ne valide pas « avancer »")
	await _hold(["move_forward"], 1.2)
	_check(_level._tutorial == _level.Tutorial.BACK, "tutoriel : reculer")
	await _hold(["move_back"], 1.6)
	_check(_level._tutorial == _level.Tutorial.TURN, "tutoriel : tourner")
	var tray: Node3D = _level.get_node("StartTray")
	var start_spot: Vector3 = (_level.get_node("Checkpoints/Start") as Node3D).global_position
	_check(is_zero_approx((tray.get_node("Ramp") as Node3D).rotation.z), "le bac de recharge est fermé pendant l'apprentissage")
	await _hold(["move_forward"], 2.0)
	_check(Vector2(_nino.global_position.x - start_spot.x, _nino.global_position.z - start_spot.z).length() < 1.4 and _nino.global_position.y > 7.9,
			"Nin0 ne peut pas quitter le bac avant la fin du tutoriel")
	await _hold(["move_left"], 0.8)
	await _hold(["move_right"], 0.8)
	_check(_level._tutorial == _level.Tutorial.CAMERA, "tutoriel : orienter la caméra")
	# Sans affichage, la souris ne peut pas être capturée : on reproduit l'effet
	# d'un mouvement de souris (rotation progressive de la caméra).
	for i in 20:
		_camera.rotation.y += 0.07
		await get_tree().physics_frame
	await _wait(0.2)
	_check(GameState.tutorial_done and GameState.get_objective() == "Explorer l'établi", "tutoriel terminé, objectif « Explorer l'établi »")
	await _wait(1.0)
	_check(absf((tray.get_node("Ramp") as Node3D).rotation.z - PI / 2.0) < 0.05, "la rampe du bac s'abaisse : Nin0 peut partir")

	# 3. Découvertes (facultatives).
	var interactor: Interactor = _nino.get_node("Interactor")
	_place(Vector3(-6.2, 8.05, -11.6), PI)
	await _wait(0.4)
	_check(interactor.focused != null and interactor.focused.name == "ExamineServo", "le servomoteur est détectable")
	await _tap("interact")
	await _wait(0.3)
	_check(GameState.has_discovery(&"spare_servo") and not _level.get_node("Geometry/SpareServo").visible, "le servomoteur est emporté (découverte)")
	_place(Vector3(-12.0, 8.05, -11.5), PI / 2)
	await _wait(0.6)
	_check(interactor.focused == null and not GameState.has_discovery(&"child_drawing") and GameState.memory_count() == 0,
			"le dessin n'est plus une découverte à examiner (souvenir par la vision uniquement)")
	_check(_saw_thought([&"eye", &"question"]), "Nin0 remarque le dessin sans rien obtenir")

	# 3b. Passages du sol et caméra dans les espaces bas.
	_place(Vector3(-6.0, 0.05, -6.5), -PI / 2)
	await _hold(["move_forward"], 3.6)
	_check(_nino.global_position.x > 2.5, "Nin0 traverse le tube en carton (x = %.2f)" % _nino.global_position.x)
	_place(Vector3(-2.7, 0.05, -6.6), -PI / 2)
	await _wait(0.4)
	_check(interactor.focused != null and interactor.focused.name == "ExaminePlan", "un plan roulé est caché dans le tube")
	await _tap("interact")
	await _wait(0.3)
	_check(GameState.has_discovery(&"plan_chassis") and not _level.get_node("Geometry/RolledPlan").visible, "le plan est emporté")
	# Fragment de filament sous la table.
	_place(Vector3(-7.6, 0.05, -12.6), PI / 2)
	await _hold(["move_forward"], 0.6)
	_check(GameState.fragments == 1 and GameState.collected_pickups.has(&"frag_under_bench"), "un fragment de filament est ramassé")
	_check(_level.hud.get_node("Fragments").visible and _level.hud.get_node("Fragments/Count").text == "1", "compteur de fragments affiché")
	_place(Vector3(-7.6, 0.05, -12.6), PI / 2)
	await _hold(["move_forward"], 0.6)
	_check(GameState.fragments == 1, "un fragment ne se ramasse qu'une fois")
	var pot: Node3D = _level.get_node("Geometry/PlantPot")
	_check(not (pot.global_position.x < -9.0 and pot.global_position.z > 0.0 and pot.global_position.z < 11.0), "le pot de fleur ne gêne plus la porte")
	_place(Vector3(4.5, 0.05, 2.6), PI)
	await _hold(["move_forward"], 1.6)
	_check(_nino.global_position.z > 5.0, "Nin0 passe sous le fauteuil (z = %.2f)" % _nino.global_position.z)
	await _wait(1.0)
	_check(_nino.get_node("Visual").visible, "Nin0 reste visible sous le fauteuil (caméra aplatie)")

	# 4. Imprimante hors tension → Nin0 comprend qu'il manque de l'énergie.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	_check(interactor.focused == _level.printer.interactable, "l'imprimante est détectée comme interactive")
	await _tap("interact")
	var panel: PrinterPanel = _level.printer_panel
	await _wait(0.5)
	_check(not panel.visible and _saw_thought([&"eye", &"question"]), "première rencontre : Nin0 observe la machine avant l'interface")
	var opened := await _wait_until(9.0, func() -> bool: return panel.visible)
	_check(opened and GameState.printer_seen, "Nin0 observe la machine, puis l'interface de l'imprimante s'ouvre")
	_check(panel.get_node("Center/Panel/Margin/VBox/LegsCard/Button").disabled, "impression impossible sans alimentation")
	await _tap("interact")
	_check(not panel.visible and _nino.controls_enabled, "l'interface se ferme (sans se rouvrir)")
	await _wait(0.5)
	_check(_saw_thought([&"printer", &"cross", &"energy"]), "pensée : l'imprimante n'a pas d'énergie")
	_check(not panel.get_node("Center/Panel/Margin/VBox/RepairCard").visible, "pas de réparation proposée avant la blessure")
	_check(GameState.get_objective() == "Rétablir l'alimentation de l'imprimante", "objectif : alimentation")

	# 5. Le câble mène à la multiprise.
	_place(Vector3(3.8, 8.05, -12.6), 0.0)
	await _wait(0.4)
	_check(_saw_thought([&"plug", &"down"]), "pensée : le câble descend (question, pas d'ordre)")
	_place(Vector3(-4.6, 0.05, -12.4), 0.0)
	await _wait(0.4)
	_check(_saw_thought([&"plug", &"exclamation"]), "pensée : la multiprise est trouvée")
	_check(interactor.focused == _level.power_strip.interactable, "la multiprise est détectée")
	await _tap("interact")
	await _wait(3.5)
	_check(GameState.power_on and _level.printer.is_powered(), "la multiprise alimente l'imprimante")
	_check(_saw_thought([&"plug", &"arrow", &"printer", &"energy"]), "pensée : Nin0 relie la multiprise à l'imprimante")
	_check(GameState.get_objective() == "Retourner à l'imprimante", "objectif : retourner à l'imprimante")

	# 6. Retour sur roues : planche à repasser → bobine poussée dans l'encoche → planche → table.
	_place(Vector3(13.5, 0.05, 7.4), 0.0)
	var on_p1 := await _hold_until(["move_forward"], 8.0, func() -> bool: return _nino.global_position.y > 5.4 and _nino.global_position.z < -5.3)
	_check(on_p1, "Nin0 monte la planche à repasser sur roues (y = %.2f)" % _nino.global_position.y)
	var slotted := await _hold_until(["move_forward"], 8.0, func() -> bool: return _level.spool_slot.is_filled())
	_check(slotted, "Nin0 pousse une bobine dans l'encoche")
	await _wait(0.6)
	var crossed := await _hold_until(["move_forward"], 6.0, func() -> bool: return _nino.global_position.z < -12.9)
	_check(crossed and _nino.global_position.y > 5.4, "Nin0 traverse la bobine jusqu'à la seconde pile (z = %.2f)" % _nino.global_position.z)
	var on_table := await _hold_until(["move_left"], 8.0, func() -> bool: return _nino.global_position.x < 2.6)
	_check(on_table and absf(_nino.global_position.y - 8.0) < 0.15, "Nin0 rejoint la table par la planche (x = %.2f, y = %.2f)" % [_nino.global_position.x, _nino.global_position.y])
	_check(_nino.mode == NinoController.Mode.WHEELS and _nino.state == NinoController.State.FREE, "parcours entièrement sur roues, sans escalade")

	# 7. Compréhension de l'imprimante puis impression.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	await _tap("interact")
	await _wait(5.0)
	_check(_saw_thought([&"printer", &"arrow", &"gear"]) and GameState.printer_understood, "pensée : l'imprimante fabrique des pièces")
	_check(panel.visible and not panel.get_node("Center/Panel/Margin/VBox/LegsCard/Button").disabled, "impression disponible")
	await _tap("interact")
	await _wait(0.3)
	_check(_level.printer.state in [Printer3D.State.HEATING, Printer3D.State.PRINTING], "l'impression démarre")
	await _wait(_level.printer.heat_duration + _level.printer.print_duration * 0.5)
	_check(GameState.get_objective().begins_with("Impression en cours") and GameState.get_objective().ends_with("%"), "objectif avec progression : %s" % GameState.get_objective())
	await _wait(_level.printer.print_duration * 0.5 + 2.5)
	_check(GameState.legs_printed and _level.printer.state == Printer3D.State.DONE, "les jambes sont imprimées")
	_check(GameState.get_objective() == "Rejoindre la plateforme d'impression", "objectif : rejoindre la plateforme")

	# 8. Le carnet renversé forme une rampe ; Nin0 monte sur le plateau.
	_place(Vector3(-0.6, 8.05, -8.3), 0.0)
	await _wait(0.4)
	_check(interactor.focused == _level.notebook.interactable, "le carnet peut être poussé")
	await _tap("interact")
	await _wait(1.2)
	_check(_level.notebook.is_toppled, "le carnet est renversé")
	var installing := await _hold_until(["move_forward"], 4.0, func() -> bool: return _nino.state == NinoController.State.SCRIPTED)
	_check(installing, "Nin0 monte la rampe et la machine le détecte sur le plateau")
	var installed := await _wait_until(16.0, func() -> bool: return GameState.legs_installed and _nino.controls_enabled)
	_check(installed and _nino.legs_available, "jambes installées sur le plateau, Nin0 à nouveau contrôlable")
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
	_check(_nino.global_position.distance_to(before) < 0.05, "Nin0 reste immobile pendant la transformation")
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
	_check(peak - ground > 0.8, "Nin0 saute en mode jambes (%.2f u)" % (peak - ground))
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
	_check(reached, "Nin0 atteint le rebord de la fenêtre (y = %.2f)" % _nino.global_position.y)
	_check(not _nino.controls_enabled and not _level.focus_vision.unlocked, "mise en scène : Nin0 remarque quelque chose au loin")
	var calibrated := await _wait_until(10.0, func() -> bool: return _level.focus_vision.unlocked and _nino.controls_enabled)
	_check(calibrated and _saw_thought([&"eye", &"question"]), "le système optique se calibre ; la vision focalisée est disponible")
	_check(GameState.get_objective() == "Observer la porte", "objectif : observer la porte")

	# 12. Vision focalisée : règles communes (portée, angle, obstacles), puis la poignée.
	var vision: FocusVision = _level.focus_vision
	var drawing: FocusTarget = _level.drawing_focus
	var handle_target: FocusTarget = _level.door.get_node("Hinge/LeverPivot/HandleFocus")
	var eye := _nino.global_position + Vector3.UP * 0.6
	_check(vision.evaluate(drawing, Vector3(-6.0, 10.6, -14.5)) == FocusVision.Status.TOO_FAR, "le dessin est trop loin depuis le milieu du rebord")
	_check(vision.evaluate(handle_target, eye) == FocusVision.Status.OK, "la poignée est observable depuis la fenêtre")
	_check(vision.evaluate(drawing, Vector3(-14.2, 8.6, -11.5)) == FocusVision.Status.BAD_ANGLE, "angle trop rasant sous le dessin")
	_check(vision.evaluate(drawing, Vector3(-11.0, 8.6, -11.5)) == FocusVision.Status.OK, "dessin observable à bonne distance")
	_check(vision.evaluate(drawing, Vector3(-17.0, 12.0, -11.5)) == FocusVision.Status.HIDDEN, "un mur masque la cible")
	_check(vision.evaluate(handle_target, Vector3(-6.0, 4.0, -11.5)) == FocusVision.Status.HIDDEN, "la poignée est cachée depuis sous la table")
	_check(vision.find_aimed(eye, (handle_target.global_position - eye).rotated(Vector3.UP, deg_to_rad(12.0)).normalized()).target == null,
			"viser à côté ne reconnaît rien")
	_aim_at(handle_target.global_position)
	Input.action_press("focus")
	await _wait(0.4)
	_check(vision.active and _nino.focus_lock, "vision focalisée active (Nin0 immobile)")
	await _wait(1.2)
	Input.action_release("focus")
	await _wait(0.5)
	_check(GameState.handle_identified and _level.door.interactable.enabled, "la poignée est identifiée")
	_check(_saw_thought([&"handle", &"exclamation"]), "pensée : Nin0 comprend qu'il peut l'atteindre")
	_check(GameState.get_objective() == "Atteindre la poignée de la porte", "objectif : atteindre la poignée")

	# 12b. Souvenir 1 : le dessin, observé de près, longtemps, sous un bon angle.
	_place(Vector3(-10.4, 8.05, -11.5), PI / 2)
	await _wait(2.0)
	_aim_at(drawing.global_position)
	Input.action_press("focus")
	await _wait(0.8)
	_check(GameState.memory_count() == 0, "une observation trop brève ne suffit pas")
	await _wait(1.4)
	Input.action_release("focus")
	_check(GameState.has_memory(&"memory_01") and GameState.memory_count() == 1, "souvenir 1 obtenu par la vision focalisée")
	_check(_level.memory_player.playing, "séquence du souvenir (signal, parasites, fragments)")
	var memory_done := await _wait_until(16.0, func() -> bool: return not _level.memory_player.playing and _nino.controls_enabled)
	_check(memory_done and _saw_thought([&"question"]) and _thought_texts.has("Ce dessin… il me parle ?"), "fin de la séquence : commentaire mystérieux, jeu repris")
	_aim_at(drawing.global_position)
	Input.action_press("focus")
	await _wait(2.4)
	Input.action_release("focus")
	await _wait(0.3)
	_check(GameState.memory_count() == 1 and not _level.memory_player.playing, "aucun doublon en observant à nouveau")
	_level.pause_menu.open()
	_check(_level.pause_menu.get_node("Center/Panel/Margin/VBox/Archives").visible
			and _level.pause_menu.get_node("Center/Panel/Margin/VBox/Archives/Label").text == "Archives fragmentées — 1/7", "archives consultables dans la pause")
	_level.pause_menu.close()
	_check(GameState.archive_state() == &"incomplete", "donnée de fin : archives incomplètes")

	# 13. Parcours final : boîtes, livres, étagère (sauts réels), puis la poignée.
	_place(Vector3(-13.8, 8.05, -11.4), PI)
	await _wait(0.3)
	var at_handle := await _jump_route(["move_forward"], 16, func() -> bool: return interactor.focused == _level.door.interactable)
	_check(at_handle and _nino.global_position.y > 9.7, "Nin0 franchit l'étagère jusqu'à la poignée (z = %.2f)" % _nino.global_position.z)
	await _wait(0.4)
	_check(_nino.mode == NinoController.Mode.LEGS, "Nin0 est en mode jambes sur l'étagère")
	await _tap("interact")
	var fell := await _wait_until(8.0, func() -> bool: return GameState.injured)
	_check(fell and _level.door.is_open, "la porte s'ouvre et Nin0 lâche prise")
	_check(_thought_texts.has("LEEEROOOY JENKINS !"), "bulle « LEEEROOOY JENKINS ! » avant le saut décisif")
	_check(_nino.global_position.y < 0.3, "Nin0 est réellement tombé au sol (y = %.2f)" % _nino.global_position.y)
	var eraser: Node3D = _level.get_node("Geometry/Eraser")
	_check(eraser.global_position.y < 0.5 and eraser.global_position.distance_to(_nino.global_position) < 1.6, "gag : la gomme délogée est tombée sur sa tête, puis au sol à côté")
	_check(is_equal_approx(GameState.integrity, 100.0 - _level.DOOR_FALL_DAMAGE) and is_equal_approx(GameState.shield, GameState.shield_max),
			"chute : intégrité %d / 100, bouclier intact (choc direct)" % roundi(GameState.integrity))
	_check(_level.hud.get_node("Status").visible, "la jauge d'intégrité apparaît")
	var recovered := await _wait_until(14.0, func() -> bool: return _nino.controls_enabled)
	var leaf: Node3D = _level.door.get_node("Hinge/Panel")
	_check(absf(rad_to_deg(leaf.global_basis.get_euler().y) - _level.door.open_angle) < 1.0 and _level.door.open_angle <= 25.0,
			"porte entrouverte (battant réellement tourné de %d°)" % roundi(rad_to_deg(leaf.global_basis.get_euler().y)))
	_check(recovered and _saw_thought([&"robot", &"damage"]) and _saw_thought([&"printer", &"wrench"]), "réaction de blessure, puis Nin0 pense à l'imprimante")
	_check(GameState.get_objective() == "Se faire réparer à l'imprimante" and not GameState.demo_completed, "objectif : réparation (pas encore la fin)")
	_check(_level.printer.interactable.enabled, "l'imprimante est de nouveau utilisable")

	# 13b. Bouclier et petites chutes.
	var integrity_before := GameState.integrity
	_level.integrity.take_damage(12.0)
	_check(is_equal_approx(GameState.integrity, integrity_before) and GameState.shield < GameState.shield_max, "le bouclier absorbe un petit choc")
	await _wait(_level.integrity.shield_recharge_delay + 3.5)
	_check(is_equal_approx(GameState.shield, GameState.shield_max), "le bouclier se recharge après un moment sans dégâts")
	_nino.emit_signal("landed", 10.0)
	_check(is_equal_approx(GameState.integrity, integrity_before) and is_equal_approx(GameState.shield, GameState.shield_max), "une petite chute ne coûte rien")

	# 13c. Retour à l'imprimante avec les jambes : règle en pente, carton, pile de livres, table.
	_check(not _nino.climbing_enabled, "escalade libre désactivée (lot 7)")
	_place(Vector3(-9.5, 0.05, 8.2), 0.0)
	var on_box := await _hold_until(["move_forward"], 8.0, func() -> bool: return _nino.global_position.y > 3.9 and _nino.global_position.z < -0.95 and _nino.state == NinoController.State.FREE)
	_check(on_box, "Nin0 monte la règle posée en pente jusqu'au carton (y = %.2f)" % _nino.global_position.y)
	var on_bench := await _jump_route(["move_forward"], 14, func() -> bool: return _nino.global_position.y > 7.9 and _nino.global_position.z < -8.1)
	_check(on_bench, "Nin0 rejoint la table par la pile de livres (y = %.2f, z = %.2f)" % [_nino.global_position.y, _nino.global_position.z])
	_check(GameState.fragments >= _level.REPAIR_COST and GameState.collected_pickups.has(&"frag_chair_box") and GameState.collected_pickups.has(&"frag_chair_seat") and GameState.collected_pickups.has(&"frag_chair_books"), "les 3 fragments du chemin sont ramassés, assez pour réparer (%d)" % GameState.fragments)

	# 13d. Réparation.
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	await _tap("interact")
	await _wait(0.3)
	_check(panel.visible and panel.get_node("Center/Panel/Margin/VBox/RepairCard").visible
			and not panel.get_node("Center/Panel/Margin/VBox/RepairCard/Button").disabled, "réparation proposée (coût en fragments)")
	_check(panel.get_node("Center/Panel/Margin/VBox/UpgradeCard").visible
			and panel.get_node("Center/Panel/Margin/VBox/UpgradeCard/Button").disabled, "renfort visible mais réparation d'abord")
	var fragments_before := GameState.fragments
	await _tap("interact")
	await _wait(1.0)
	_check(_level.printer.state == Printer3D.State.SERVICING and _nino.state == NinoController.State.SCRIPTED, "Nin0 est installé sur le plateau")
	var repaired := await _wait_until(16.0, func() -> bool: return GameState.repaired and _nino.controls_enabled)
	_check(repaired and is_equal_approx(GameState.integrity, GameState.integrity_max), "réparation terminée, intégrité restaurée")
	_check(GameState.fragments == fragments_before - _level.REPAIR_COST and GameState.repairs_done == 1, "fragments dépensés")
	_check(_nino.legs_available, "les jambes sont conservées")
	_check(GameState.get_objective() == "Franchir la porte", "objectif : franchir la porte")

	# 13e. Renfort de châssis I (facultatif) : fragments cachés, puis fabrication.
	for spot in [Vector3(-5.5, 10.1, -14.65), Vector3(-14.3, 9.9, -0.2), Vector3(10.7, 2.7, 7.1), Vector3(14.3, 5.6, -14.3)]:
		_place(spot, 0.0)
		await _wait(0.3)
	_place(Vector3(-1, 8.05, -8.9), 0.0)
	await _wait(0.4)
	await _tap("interact")
	await _wait(0.3)
	_check(not panel.get_node("Center/Panel/Margin/VBox/UpgradeCard/Button").disabled, "renfort fabricable (%d fragments)" % GameState.fragments)
	await _tap("interact")
	var upgraded := await _wait_until(14.0, func() -> bool: return GameState.has_upgrade(&"chassis_reinforcement_1") and _nino.controls_enabled)
	_check(upgraded and is_equal_approx(GameState.integrity_max, 125.0), "Renfort de châssis I : intégrité max. 125")

	# 13f. Fin : la porte ouverte, face au sas.
	_place(Vector3(-12.0, 0.05, 5.5), PI / 2)
	var ended := await _hold_until(["move_forward"], 6.0, func() -> bool: return _level.end_screen.visible)
	_check(ended and GameState.demo_completed, "Nin0 rejoint la porte ouverte : fin de la démo")
	var end_title: Label = _level.end_screen.get_node("Content/VBox/Title")
	var end_line: Label = _level.end_screen.get_node("Content/VBox/Line")
	_check(end_title.text == "Nin0" and end_line.text == "Fin de la première démo", "texte de conclusion")

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
	_check(_nino.legs_available and _nino.controls_enabled and GameState.power_on, "reprise : jambes installées, Nin0 jouable")
	_check(_level.hud.get_node("Objective").visible and _level.hud.get_node("Status").visible and _level.hud.get_node("Fragments").visible,
			"reprise : interface de jeu affichée (objectif, intégrité, fragments)")
	_check(_level.spool_slot.is_filled() and _level.notebook.is_toppled, "reprise : bobine et carnet en place")
	_check(GameState.has_discovery(&"spare_servo") and GameState.has_discovery(&"plan_chassis"), "reprise : découvertes conservées")
	_check(_level.door.is_open and GameState.repaired and _level.focus_vision.unlocked, "reprise : porte ouverte, réparé, vision disponible")
	_check(GameState.has_memory(&"memory_01") and _level.drawing_focus.is_identified, "reprise : souvenir conservé")
	_check(GameState.has_upgrade(&"chassis_reinforcement_1") and is_equal_approx(GameState.integrity_max, 125.0), "reprise : renfort conservé")
	_check(GameState.collected_pickups.size() == 8 and not _level.get_node("Pickups/Fragment_sill").visible, "reprise : fragments ramassés absents (%d, %s)" % [GameState.collected_pickups.size(), str(GameState.collected_pickups)])
	_check(not _level.get_node("Geometry/RolledPlan").visible and not _level.get_node("Geometry/SpareServo").visible, "reprise : objets emportés absents")

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
	_check(GameState.memory_count() == 0 and GameState.fragments == 0 and GameState.upgrades.is_empty()
			and is_equal_approx(GameState.integrity, 100.0) and not GameState.integrity_known, "nouvelle partie : intégrité, fragments, souvenirs remis à zéro")

	# 16. Ancienne sauvegarde (lot 2) : lisible, sans souvenir attribué pour le dessin examiné.
	var old := ConfigFile.new()
	old.set_value("progress", "legs_installed", true)
	old.set_value("progress", "discoveries", ["leg_sketch", "child_drawing"])
	old.save(GameState.save_path)
	GameState.load_save()
	_check(GameState.legs_installed and GameState.has_discovery(&"child_drawing"), "ancienne sauvegarde chargée")
	_check(GameState.memory_count() == 0 and is_equal_approx(GameState.integrity, 100.0) and GameState.fragments == 0
			and not GameState.door_opened, "ancienne sauvegarde : aucun souvenir automatique, valeurs par défaut")

	# 16b. Sauvegarde du lot 3 écrite par Godot 4.3 (avant migration), relue sous 4.7.
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/save_lot3_godot43.cfg"), ProjectSettings.globalize_path(GameState.save_path))
	GameState.load_save()
	_check(GameState.legs_installed and GameState.door_opened and GameState.injured and not GameState.repaired
			and GameState.has_memory(&"memory_01") and GameState.fragments == 2 and GameState.collected_pickups.has(&"frag_shelf")
			and is_equal_approx(GameState.integrity, 55.0) and GameState.has_discovery(&"plan_chassis"),
			"sauvegarde du lot 3 écrite sous Godot 4.3 relue intégralement")

	# 17. Dégradation des souvenirs selon la progression (données fictives, ordre libre).
	var archive := MemoryArchive.new()
	archive.total = 7
	_check(archive.corruption(1) > archive.corruption(4) and archive.corruption(4) > archive.corruption(7), "la dégradation diminue avec les fragments retrouvés")
	var sample := "Une phrase fictive de test pour mesurer les parasites du signal"
	var altered_few := 0
	var altered_many := 0
	for seed_value in 20:
		altered_few += MemoryArchive.altered_count(sample, MemoryArchive.degrade(sample, archive.corruption(1), seed_value))
		altered_many += MemoryArchive.altered_count(sample, MemoryArchive.degrade(sample, archive.corruption(7), seed_value))
	_check(altered_few > altered_many * 2, "texte plus lisible avec 7 fragments (%d contre %d altérations)" % [altered_many, altered_few])
	_check(MemoryArchive.degrade(sample, 0.5, 3) == MemoryArchive.degrade(sample, 0.5, 3), "dégradation reproductible")
	GameState.reset_progress()
	for id in [&"m_a", &"m_b", &"m_c", &"m_d", &"m_e", &"m_f", &"m_g"]:
		GameState.add_memory(id)
	GameState.add_memory(&"m_c")
	_check(GameState.memory_count() == 7 and GameState.archive_state() == &"complete", "7/7 distinguable (aucune fin développée)")
	GameState.reset_progress()
	GameState.erase_save()
	GameState.save_path = GameState.SAVE_PATH
	var personal_now := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_save_existed and personal_now == _personal_save,
			"la sauvegarde personnelle n'a pas été touchée")

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _load_level() -> void:
	_level = LEVEL.instantiate()
	add_child(_level)
	_nino = _level.get_node("Nino")
	_camera = _level.get_node("ThirdPersonCamera")
	_level.thoughts.thought_requested.connect(func(icons: Array, text: String) -> void:
		_thoughts.append(icons)
		_thought_texts.append(text))


func _saw_thought(icons: Array) -> bool:
	return _thoughts.has(icons)


func _place(position: Vector3, yaw: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = yaw
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = yaw
	_camera.snap_to_target()


## Oriente la caméra (vue focalisée) vers un point, depuis la tête de Nin0.
func _aim_at(point: Vector3) -> void:
	var head := _nino.global_position + Vector3.UP * (_nino.get_focus_height() + 0.12)
	var to_point: Vector3 = point - head
	_camera.rotation.y = atan2(-to_point.x, -to_point.z)
	_camera.pitch = atan2(to_point.y, Vector2(to_point.x, to_point.z).length())


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
