extends Node
## Test du chapitre 2 « Le territoire des fourmis » (lot 5), sans affichage :
##   godot --headless --fixed-fps 60 --path . res://tests/test_chapter2.tscn
## Joue dans la scène de développement (aucune sauvegarde personnelle touchée) :
## sas (rencontre, analyse, Armure I, colonne, portes), salle de bain (labyrinthes,
## ticket, soldats, larves, escabeau), reine (acide, morsure, enlisement, échec,
## vidange), canon (fabrication, tir, munitions), loquet de la cuisine, fin du chapitre,
## ressources, inventaire, sauvegardes.
## Les actions de visée fines (verrouillage de la vision, tir sur le crochet) sont
## déclenchées directement ; la vérification d'observabilité utilise la vraie règle.

const APARTMENT := preload("res://scenes/levels/apartment.tscn")

var _failures := 0
var _dev: Node3D
var _game: GameWorld
var _nino: NinoController
var _camera: ThirdPersonCamera
var _director: Node3D
var _personal_existed := false
var _personal := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	# Hasard initialisé : la reine et les créatures se comportent de façon reproductible.
	seed(5)
	_personal_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_existed else ""
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	_dev = APARTMENT.instantiate()
	add_child(_dev)
	_game = _dev.game
	_nino = _dev.nino
	_camera = _dev.camera
	_director = _dev.workshop
	await _wait(1.5)
	for flag in [&"injured", &"repaired", &"demo_completed"]:
		GameState.set(flag, true)
	_game._update_hub_blocker()

	await _test_sas()
	await _test_armor()
	await _test_inventory()
	await _test_bathroom()
	await _test_soldiers()
	await _test_larvae()
	await _test_stool()
	await _test_boss()
	await _test_cannon()
	await _test_kitchen()
	await _test_resources()
	await _test_saves()

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- Sas ------------------------------------------------------------------------------

func _test_sas() -> void:
	var sas := _game.sas
	_check(not GameState.chapter2_completed and not GameState.kitchen_unlocked and not sas.kitchen_door.is_unlocked, "début : cuisine fermée")
	# Musique : « Petit Refuge » au placard et dans le sas, sans redémarrage.
	_check(Music.desired == &"hub" and Music.current != &"intro", "début de partie : introduction arrêtée, musique du hub demandée")
	_check([&"hub", &"labyrinth", &"boss", &"kitchen"].all(func(id: StringName) -> bool: return Music.has_track(id)), "musiques du pack présentes (hub, labyrinthe, reine, cuisine)")
	_check(not Music.has_track(&"living_room"), "musique du salon non intégrée au jeu (réservée)")
	_check(Music.current == &"hub" and Music.is_playing(), "« Petit Refuge » réellement jouée")
	var changes := Music.changes.size()
	_place(Vector3(-10.0, 0.05, 1.4), 90.0)
	await _wait(0.6)
	_place(Vector3(-20.0, 0.05, 1.4), 90.0)
	await _wait(0.6)
	_place(Vector3(-10.0, 0.05, 1.4), 90.0)
	await _wait(0.6)
	_check(Music.desired == &"hub" and Music.changes.size() == changes, "placard ↔ sas : même morceau, jamais relancé")
	_check(Music.audible_count() <= 1, "une seule musique audible")
	# Première rencontre, en entrant depuis le placard.
	GameState.worker_met = false
	var before := GameState.integrity + GameState.shield
	_nino.force_mode(NinoController.Mode.WHEELS)
	_place(Vector3(-14.6, 0.05, 1.6), 90.0)
	var thoughts_seen: Array = []
	var record := func(icons: Array, _text: String) -> void: thoughts_seen.append(icons)
	_director.thoughts.thought_requested.connect(record)
	var started := await _hold_until(4.0, func() -> bool: return _game._encounter_running)
	_check(started and not _nino.controls_enabled, "rencontre : l'ouvrière arrive, contrôle retiré")
	var t0 := Time.get_ticks_msec()
	var done := await _wait_until(12.0, func() -> bool: return GameState.worker_met and _nino.controls_enabled)
	var seconds := (Time.get_ticks_msec() - t0) / 1000.0
	_check(done and seconds < 9.5, "rencontre courte (approche prudente comprise), contrôle rendu (%.1f s)" % seconds)
	_check(thoughts_seen.any(func(i: Array) -> bool: return i.has(&"binoculars")), "pensée « jumelles » après le calibrage des yeux")
	_director.thoughts.thought_requested.disconnect(record)
	_check(is_equal_approx(GameState.integrity + GameState.shield, before), "l'ouvrière n'attaque pas")
	var ant: AntWorker = _game.encounter_worker
	_check(ant != null and ant.focus.show_marker and ant.get_node("ScanRing").visible, "cible visuelle sur l'ouvrière, qui attend")
	await _wait(2.5)
	_check(not GameState.has_species(&"ant_worker") and is_instance_valid(ant) and ant.global_position.distance_to(sas.encounter_point("Stop")) < 0.8,
			"aucun scan automatique : l'ouvrière attend l'action du joueur")
	# Analyse (encyclopédie) : la règle d'observation accepte l'ouvrière visée.
	var eye := _nino.global_position + Vector3.UP * 0.4
	var aimed: Dictionary = _director.focus_vision.find_aimed(eye, (ant.focus.global_position - eye).normalized())
	_check(aimed.target == ant.focus and aimed.status == FocusVision.Status.OK, "l'ouvrière est observable (vision focalisée)")
	var jingles := Sfx.jingle_counts.duplicate()
	_director.focus_vision.target_identified.emit(ant.focus)
	await _wait(0.5)
	_check(GameState.has_species(&"ant_worker") and _game.species_card.showing, "fiche « ESPÈCE IDENTIFIÉE » : fourmi ouvrière")
	_check(int(Sfx.jingle_counts.get(&"jingle_scan", 0)) == int(jingles.get(&"jingle_scan", 0)) + 1, "jingle de scan joué")
	var opened := await _wait_until(10.0, func() -> bool: return _game.blueprint._open)
	_check(opened and get_tree().paused, "réflexion de Nin0 → plan présenté (jeu figé)")
	_check(int(Sfx.jingle_counts.get(&"jingle_plan", 0)) == int(jingles.get(&"jingle_plan", 0)) + 1, "jingle de nouveau plan joué")
	await _wait(2.6)
	_game.blueprint.close()
	await _wait(0.3)
	_check(GameState.has_discovery(&"plan_armor_1") and not get_tree().paused, "plan Armure I débloqué")
	var left := await _wait_until(16.0, func() -> bool: return sas.get_node_or_null("FirstWorker") == null)
	_check(left, "après l'analyse, l'ouvrière repart (pas de doublon)")
	# Colonne.
	var column := sas.column
	_check(column.get_worker_count() >= 6, "colonne d'ouvrières (%d)" % column.get_worker_count())
	var p0 := column.workers[0].global_position
	_place(Vector3(-40.0, 0.05, 0.0), 0.0)
	await _wait(1.5)
	_check(column.workers[0].global_position.distance_to(p0) > 0.05 or column.workers[1].paused > 0.0, "la colonne avance (vers la salle de bain)")
	var endpoint := (column.get_node("Path") as Path3D).curve.get_point_position((column.get_node("Path") as Path3D).curve.point_count - 1)
	_check(_game.zone_at(column.to_global(endpoint)) == 3, "la colonne mène au nid de la salle de bain")
	jingles = Sfx.jingle_counts.duplicate()
	_director.focus_vision.target_identified.emit(column.workers[3].focus)
	await _wait(0.3)
	_check(GameState.species.count(&"ant_worker") == 1 and not _game.blueprint._open and Sfx.jingle_counts == jingles, "pas de seconde analyse, de doublon ni de second jingle")
	_check(column.workers[4].focus.is_identified, "les autres ouvrières sont reconnues")
	# Portes : salon fermé (examinable), cuisine fermée.
	sas.salon_inspect.interacted.emit(_nino)
	await _wait(0.3)
	_check(_game._shown.has(&"salon_door"), "porte du salon examinable (Nin0 comprend)")
	_check(_director.reactions.history.has(&"strange"), "réaction contextuelle : hésitation devant la porte fermée")
	# Objets du sas : la boule de papier froissé a une vraie collision.
	_check(_solid_at((_game.sas.get_node("Decor/PaperBall/Facet0") as Node3D).global_position), "boule de papier froissé : apparence de papier et collision")
	_check(not await _drive(Vector3(-31.5, 0.05, 5.0), 180.0, 6, 3.0), "porte du salon fermée")
	_check(not await _drive(Vector3(-40.0, 0.05, 8.0), 90.0, 4, 3.0), "porte de la cuisine fermée avant le canon")


# --- Armure I -------------------------------------------------------------------------

func _test_armor() -> void:
	_teleport_marker(_director.get_node("Checkpoints/Printer"))
	GameState.fragments = 5
	_director._on_upgrade_requested(&"armor_1")
	var installs := int(Sfx.jingle_counts.get(&"jingle_install", 0))
	var made := await _wait_until(16.0, func() -> bool: return GameState.has_upgrade(&"armor_1") and _nino.controls_enabled)
	_check(int(Sfx.jingle_counts.get(&"jingle_install", 0)) == installs + 1, "jingle d'amélioration installée (une fois)")
	await _wait(1.5)
	_check(_director.reactions.history.has(&"upgrade"), "petite voix « Yeeeaah ! » après l'installation")
	var bed: Node3D = _director.printer.get_node("Bed")
	var bed_body: Node3D = bed.get_node("BedBody")
	_check(bed_body.global_position.distance_to(bed.global_position) < 0.01, "plateau : la collision suit réellement le plateau")
	await _wait(0.5)
	var bed_top := bed.global_position.y + 0.12
	var on_bed := _nino.is_on_floor() and absf(_nino.global_position.y - bed_top) < 0.08
	var off_bed := _nino.is_on_floor() and _nino.global_position.y > bed_top - 0.5
	_check(on_bed or off_bed, "Nin0 repose sur le plateau sans flotter ni le traverser (y %.2f, plateau %.2f)" % [_nino.global_position.y, bed_top])
	_check(made and GameState.fragments == 2, "Armure I fabriquée à l'imprimante (3 fragments)")
	_check(GameState.is_equipped(&"armor_1") and is_equal_approx(GameState.physical_damage_reduction(), 0.25), "Armure I équipée : -25 % de dégâts physiques")
	_check(_nino.get_visual()._armor != null and _nino.get_visual()._armor.visible, "Armure I visible sur Nin0")
	var before := GameState.integrity
	_director.integrity.take_damage(20.0, true, &"physical")
	_check(is_equal_approx(before - GameState.integrity, 15.0), "dégâts physiques réduits (20 → %.1f)" % (before - GameState.integrity))
	before = GameState.integrity
	_director.integrity.take_damage(20.0, true, &"acid")
	_check(is_equal_approx(before - GameState.integrity, 20.0), "l'acide n'est pas réduit (pas d'invincibilité)")
	GameState.restore_integrity(GameState.integrity_max)


# --- Inventaire -------------------------------------------------------------------------

func _test_inventory() -> void:
	var inventory := _game.inventory
	inventory.open(1)
	await _wait(0.2)
	_check(inventory.is_open and get_tree().paused, "inventaire ouvert (jeu en pause)")
	var texts := _texts(inventory)
	_check(texts.has("Armure I  ·  Module") and texts.has("Jambes mécaniques  ·  Majeure"), "équipement : jambes et Armure I listées")
	_check(texts.has("Filament structurel") and texts.has("%d" % GameState.fragments), "ressources : quantité réelle de filament")
	_check(texts.has("Fourmi ouvrière"), "bestiaire : fourmi ouvrière")
	_check(texts.has("Souvenirs retrouvés : %d / 7" % GameState.memory_count()), "archives : compteur n/7")
	var toggle := _find_button(inventory, "Retirer")
	toggle.pressed.emit()
	await _wait(0.1)
	_check(not GameState.is_equipped(&"armor_1"), "module retiré hors combat, sans imprimante")
	_find_button(inventory, "Équiper").pressed.emit()
	await _wait(0.1)
	_check(GameState.is_equipped(&"armor_1"), "module ré-équipé")
	GameState.in_combat = true
	inventory.refresh()
	var locked := _find_button(inventory, "Retirer")
	_check(locked.disabled, "bouton d'échange grisé en combat")
	_check(not GameState.unequip_module(&"armor_1") and GameState.is_equipped(&"armor_1"), "échange impossible en combat")
	GameState.in_combat = false
	inventory.close()
	await _wait(0.1)
	_check(not inventory.is_open and not get_tree().paused, "inventaire fermé")


# --- Salle de bain : labyrinthes, souvenir n° 2 -------------------------------------------

func _test_bathroom() -> void:
	var bath := _game.bath
	# Musique des labyrinthes dans la salle de bain, retour au hub dans le sas.
	_teleport_marker(bath.get_node("Markers/BathEntry"))
	await _wait(0.6)
	_check(Music.desired == &"labyrinth", "salle de bain : musique des labyrinthes")
	_place(Vector3(-40.0, 0.05, 0.0), 90.0)
	await _wait(0.6)
	_check(Music.desired == &"hub", "retour au sas : musique du hub")
	_teleport_marker(bath.get_node("Markers/BathEntry"))
	await _wait(0.6)
	# Soldats : plus nombreux, sur les deux chemins, trajets praticables.
	var soldiers := bath.get_soldiers()
	var left_count := soldiers.filter(func(s: AntSoldier) -> bool: return s.patrol_points[0].z > -13.0).size()
	_check(soldiers.size() >= 10 and left_count >= 3, "soldats : %d au total, %d sur le chemin du ticket" % [soldiers.size(), left_count])
	_check(soldiers.all(func(s: AntSoldier) -> bool: return s.patrol_points.size() >= 2 and s.patrol_points[0].distance_to(s.patrol_points[1]) > 0.5), "soldats en patrouille (aucun garde immobile)")
	_check(soldiers.all(func(s: AntSoldier) -> bool: return _path_clear(s.patrol_points)), "trajets de patrouille praticables (aucun obstacle)")
	var ticket_pos := bath.ticket_focus.global_position
	_check(soldiers.all(func(s: AntSoldier) -> bool: return s.patrol_points[0].distance_to(ticket_pos) > 3.0 and s.patrol_points[1].distance_to(ticket_pos) > 3.0), "aucun soldat posté devant le ticket")
	var safe := [bath.marker("BathEntry").origin, bath.marker("StoolBase").origin, bath.marker("StoolTop").origin]
	_check(soldiers.all(func(s: AntSoldier) -> bool: return safe.all(func(p: Vector3) -> bool: return s.patrol_points[0].distance_to(p) > 3.0)), "points sûrs hors des postes des soldats")
	# Extension : alcôve du linge (détour), refuge en hauteur, sortie basse en roues.
	_check(_reachable(bath.marker("MazeRightEntry").origin, Vector3(-59.8, 0.0, -21.5), 0.5, 0.95), "alcôve du linge accessible depuis le couloir de la marche")
	_check(_reachable(Vector3(-59.8, 0.0, -21.5), Vector3(-64.8, 0.0, -25.9), 0.07, 0.5), "sortie basse vers l'escabeau praticable en roues")
	_check(_solid_at(Vector3(-64.8, 0.66, -24.75)) and not _solid_at(Vector3(-64.8, 0.3, -24.75)), "passage sous la serviette : 0,6 u (roues oui, jambes non)")
	var watcher: AntSoldier = bath.get_node("Soldiers/SoldierPebbles")
	var old_pos := watcher.global_position
	watcher.global_position = Vector3(-62.0, 0.02, -22.2)
	_place(Vector3(-63.4, 1.55, -23.2), 0.0)
	await _wait(0.4)
	_check(_nino.global_position.y > 1.4 and not watcher._can_see_nino(true), "refuge en hauteur : les soldats ne voient pas Nin0 là-haut")
	watcher.global_position = old_pos
	watcher.reset_to_post()
	_check(_solid_at(Vector3(-56.9, 0.4, -24.1)), "second caillou des galeries : collision ajoutée")
	var plastic: ResourcePickup = bath.get_node("MazeRight/Alcove/PlasticAlcove")
	_check(plastic._visual.find_children("*", "Cable", true, false).size() >= 3, "plastique à munitions : tortillons de filament extrudé")
	_teleport_marker(bath.get_node("Markers/BathEntry"))
	await _wait(0.3)
	# Linge : les galeries sont faites de vêtements pliés et de serviettes.
	_check(bath.get_node("MazeRight").find_children("Wall*S*L*", "", false, false).size() >= 20 and bath.has_node("MazeRight/Heap0B0"), "galeries en linge plié, serviettes et tas de linge")
	_check(_reachable(bath.marker("MazeLeftEntry").origin, bath.marker("TicketView").origin, 0.07, 0.5),
			"labyrinthe gauche : le recoin du ticket est accessible sur roues")
	_check(_reachable(bath.marker("TicketView").origin, bath.marker("BathEntry").origin, 0.07, 0.5), "labyrinthe gauche : retour possible")
	_check(_reachable(bath.marker("MazeRightEntry").origin, bath.marker("StoolBase").origin, 0.5, 0.95),
			"labyrinthe droit : les galeries mènent à l'escabeau (jambes)")
	var gravel := bath.get_node("MazeRight/Gravel") as TerrainZone
	_nino.force_mode(NinoController.Mode.WHEELS)
	_place(Vector3(-47.6, 0.05, -18.3), 0.0)
	await _wait(0.5)
	var wheels_slow := gravel.is_nino_inside() and _nino.get_speed_factor() < 0.5
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(1.2)
	_check(wheels_slow and is_equal_approx(_nino.get_speed_factor(), 1.0), "gravier : ralentit les roues, pas les jambes")
	_place(bath.marker("BathEntry").origin, 90.0)
	await _wait(0.5)
	# Ticket : vraiment observable avec la vision focalisée, pas par interaction.
	var ticket := bath.ticket_focus
	_teleport_marker(bath.get_node("Markers/TicketView"))
	await _wait(0.4)
	var eye := _nino.global_position + Vector3.UP * 0.42
	var aimed: Dictionary = _director.focus_vision.find_aimed(eye, (ticket.global_position - eye).normalized())
	_check(aimed.target == ticket and aimed.status == FocusVision.Status.OK, "ticket observable depuis le recoin (distance, angle, vue dégagée)")
	var far: Dictionary = _director.focus_vision.find_aimed(bath.marker("MazeLeftEntry").origin + Vector3.UP * 0.4, (ticket.global_position - bath.marker("MazeLeftEntry").origin).normalized())
	_check(far.target != ticket or far.status != FocusVision.Status.OK, "ticket invisible depuis l'entrée (il faut chercher)")
	_check(ticket.get_parent().find_children("*", "Interactable", true, false).is_empty(), "aucune interaction ordinaire sur le ticket")
	var count := GameState.memory_count()
	# Un soldat poursuit Nin0 jusqu'au ticket : la séquence du souvenir le neutralise.
	var chaser: AntSoldier = bath.get_node("Soldiers/SoldierLeftUpper")
	chaser.global_position = _nino.global_position + Vector3(0.45, 0.0, 0.0)
	chaser.velocity = Vector3.ZERO
	chaser._set_state(AntSoldier.State.CHASE)
	await _wait(0.2)
	var hp_before := GameState.integrity + GameState.shield
	_director.focus_vision.target_identified.emit(ticket)
	await _wait(0.4)
	_check(GameState.hazards_suspended() and not _nino.controls_enabled, "souvenir : dangers suspendus (séquence non interactive)")
	var chaser_pos := chaser.global_position
	await _wait(2.5)
	_check(GameState.integrity + GameState.shield >= hp_before - 0.01 and chaser.global_position.distance_to(chaser_pos) < 0.05,
			"aucun dégât ni déplacement ennemi pendant le souvenir")
	await _wait(0.5)
	var back := await _wait_until(20.0, func() -> bool: return _nino.controls_enabled)
	_check(back and GameState.has_memory(&"memory_02") and GameState.memory_count() == count + 1, "souvenir n° 2 mémorisé (ticket)")
	_check(not GameState.hazards_suspended() and _director.integrity.is_protected(), "reprise : dangers rétablis, courte protection contre un coup immédiat")
	await _wait(1.6)
	_check(chaser.state != AntSoldier.State.WINDUP or GameState.integrity + GameState.shield >= hp_before - 15.0, "le soldat reprend son activité")
	_teleport_marker(bath.get_node("Markers/BathEntry"))
	await _wait(0.5)
	_check(GameState.memory_reads.has(&"memory_02") and (GameState.memory_reads[&"memory_02"] as Array).size() == 1, "commentaire de Nin0 conservé dans les archives")
	_director._acquire_memory(ticket.memory)
	await _wait(0.3)
	_check(GameState.memory_count() == count + 1 and _nino.controls_enabled, "pas de doublon du souvenir")
	var memory := ticket.memory
	var all := " ".join(memory.lines) + memory.comment + memory.title
	_check(all.contains("NIN0") and not all.to_lower().contains("papa") and not all.to_lower().contains("enfant"), "le ticket ne révèle que le nom de Nin0")


# --- Soldats ----------------------------------------------------------------------------

func _test_soldiers() -> void:
	var bath := _game.bath
	var soldier: AntSoldier = bath.get_node("Soldiers/SoldierCorridor")
	soldier.reset_to_post()
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.8)
	var spot := soldier.global_position + Vector3(0.85, 0.0, -0.1)
	_place(Vector3(spot.x, 0.05, spot.z), 90.0)
	var alerted := await _wait_until(3.0, func() -> bool: return soldier.state in [AntSoldier.State.ALERT, AntSoldier.State.CHASE, AntSoldier.State.WINDUP])
	_check(alerted, "soldat : détecte Nin0 (alerte)")
	_check(GameState.in_combat or soldier.is_engaged(), "combat signalé (modules verrouillés)")
	var before := GameState.integrity + GameState.shield
	var windup := await _wait_until(4.0, func() -> bool: return soldier.state == AntSoldier.State.WINDUP)
	_check(windup, "soldat : prépare sa morsure (télégraphiée)")
	var bitten := await _wait_until(3.0, func() -> bool: return GameState.integrity + GameState.shield < before)
	_check(bitten and _director.integrity.is_protected(), "morsure : dégâts, puis courte invulnérabilité")
	await _wait(1.2)
	# Esquive : s'écarter pendant la préparation.
	await _wait_until(5.0, func() -> bool: return soldier.state == AntSoldier.State.WINDUP)
	before = GameState.integrity + GameState.shield
	var away := soldier.global_position + (soldier.global_position - _nino.global_position).normalized() * -1.6
	_place(Vector3(away.x, 0.05, away.z), 90.0)
	await _wait(0.9)
	_check(is_equal_approx(GameState.integrity + GameState.shield, before), "morsure esquivée en s'écartant")
	# Perte de trace : Nin0 s'éloigne hors de vue, le soldat cherche puis revient.
	_teleport_marker(bath.get_node("Markers/BathEntry"))
	var lost := await _wait_until(8.0, func() -> bool: return soldier.state in [AntSoldier.State.SEARCH, AntSoldier.State.RETURN, AntSoldier.State.PATROL])
	var home := await _wait_until(12.0, func() -> bool: return soldier.state == AntSoldier.State.PATROL)
	_check(lost and home, "soldat : perd la trace et retourne patrouiller")
	_check(not GameState.in_combat or not bath.any_soldier_engaged(), "fin du combat")
	# Les ouvrières restent pacifiques.
	var col := _game.sas.column
	await _wait(1.0)
	before = GameState.integrity
	_place(col.workers[0].global_position + Vector3(0.2, 0.05, 0.0), 0.0)
	await _wait(2.0)
	_check(GameState.integrity >= before, "ouvrières pacifiques au contact")


# --- Larves -----------------------------------------------------------------------------

func _test_larvae() -> void:
	var dropper := _game.bath.larvae
	var point: Vector3 = dropper.get_node("DropPoints/P1").global_position
	_place(point + Vector3(0.0, 0.05, 0.0), 90.0)
	await _wait(0.3)
	var started := dropper.drops_started
	dropper.drop(point)
	await _wait(0.5)
	_check(dropper.active.is_empty(), "larve : avertissement avant la chute (poussière, ombre)")
	await _wait(1.4)
	_check(dropper.active.size() >= 1 and _nino.is_slowed(), "larve tombée : Nin0 ralenti, jamais tué (intégrité %d)" % roundi(GameState.integrity))
	_place(point + Vector3(-1.5, 0.05, 0.0), 90.0)
	await _wait(12.0)
	_check(dropper.drops_started > started + 1 and dropper.active.size() <= dropper.max_active, "chutes répétées, nombre limité (%d actives)" % dropper.active.size())
	_teleport_marker(_game.bath.get_node("Markers/BathEntry"))
	await _wait(8.0)
	_check(dropper.active.is_empty(), "les larves disparaissent (aucune accumulation)")


# --- Escabeau ---------------------------------------------------------------------------

func _test_stool() -> void:
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.8)
	# Appuis successifs : [point d'appel, point d'arrivée] ; y = sommet de l'appui.
	# Nin0 marche jusqu'au bord de chaque appui puis saute (comme le joueur).
	var route := [
		[Vector3(-62.45, 0.0, -26.4), Vector3(-63.15, 0.75, -26.4)],
		[Vector3(-63.85, 0.75, -26.4), Vector3(-64.75, 1.5, -26.4)],
		[Vector3(-65.25, 1.5, -26.4), Vector3(-65.85, 2.25, -26.95)],
		[Vector3(-65.85, 2.25, -26.95), Vector3(-66.3, 3.0, -26.0)],
		[Vector3(-66.58, 3.0, -26.21), Vector3(-67.2, 3.75, -26.7)],
		[Vector3(-67.2, 3.75, -27.0), Vector3(-67.2, 4.5, -27.85)],
		[Vector3(-67.2, 4.5, -27.85), Vector3(-67.25, 5.25, -28.6)],
		[Vector3(-67.25, 5.25, -28.95), Vector3(-67.25, 6.0, -29.45)],
		[Vector3(-67.25, 6.0, -29.8), Vector3(-67.25, 6.75, -30.4)],
		[Vector3(-67.7, 6.75, -31.7), Vector3(-67.9, 7.5, -32.3)],
		[Vector3(-67.6, 7.5, -32.4), Vector3(-66.95, 8.25, -32.4)],
		[Vector3(-65.4, 8.25, -32.4), Vector3(-64.7, 8.5, -32.4)],
	]
	var ok := 0
	var max_rise := 0.0
	for i in route.size():
		var hop: Array = route[i]
		max_rise = maxf(max_rise, hop[1].y - hop[0].y)
		if await _hop(hop[0], hop[1]):
			ok += 1
		else:
			print("    saut %d manqué (y = %.2f, attendu %.2f)" % [i, _nino.global_position.y, hop[1].y])
	_check(ok == route.size(), "escabeau : %d/%d sauts réussis jusqu'au plan du lavabo (mode jambes)" % [ok, route.size()])
	_check(max_rise <= 0.8, "aucun saut impossible (montée max %.2f u, saut 1,0 u)" % max_rise)
	# Arrivée sur le plan : la rencontre se déclenche ; on la réinitialise pour la suite.
	await _wait(0.5)
	_game.bath.arena.reset_fight()
	_game.bath.arena._attempts = 0  # la vraie première rencontre est testée plus loin
	_game.bath.arena.queen.hide_submerged()
	_place(Vector3(-67.2, 6.85, -31.6), -90.0)
	await _wait(1.5)
	# Point sûr en haut de l'escabeau, chute récupérable.
	_place(Vector3(-67.2, 6.85, -31.6), -90.0)
	await _wait(1.0)
	_check(GameState.resume_point == &"stool_top" or _nino._spawn_transform.origin.distance_to(_game.bath.marker("StoolTop").origin) < 0.1, "point sûr en haut de l'escabeau")


# --- Reine ------------------------------------------------------------------------------

func _test_boss() -> void:
	var arena := _game.bath.arena
	var queen := arena.queen
	_nino.force_mode(NinoController.Mode.LEGS)
	_place(Vector3(-64.4, 8.55, -31.75), -90.0)
	_check(not queen.visible, "avant la rencontre, la reine est cachée dans la matière")
	var intro := await _wait_until(2.0, func() -> bool: return arena.phase == SinkArena.Phase.INTRO)
	await _wait(0.6)
	_check(intro and not _nino.controls_enabled and GameState.boss_started and arena.is_cinematic(), "mini-cinématique : caméra sur l'arène, contrôle retiré")
	var revealed := await _wait_until(3.0, func() -> bool: return queen.visible and queen.global_position.y > 8.0)
	_check(revealed, "la reine émerge progressivement de la matière")
	var boss_music := await _wait_until(4.0, func() -> bool: return Music.desired == &"boss")
	_check(boss_music and arena.phase == SinkArena.Phase.INTRO, "musique du combat lancée pendant la présentation")
	await _wait(1.5)
	_check(Music.current == &"boss" and Music.audible_count() == 1, "musique de la reine jouée, seule audible")
	var fight := await _wait_until(6.0, func() -> bool: return arena.phase == SinkArena.Phase.FIGHT)
	_check(fight and _nino.controls_enabled and queen.is_fighting() and not arena.is_cinematic(), "combat : caméra et contrôle rendus")
	_check(queen.spit_damage > 12.0 and queen.melee_damage > 30.0 and queen.melee_windup >= 1.0, "dégâts relevés (acide %d, morsure %d), préparations lisibles" % [queen.spit_damage, queen.melee_damage])
	_check(_game.zone_at(_nino.global_position) == 3 and GameState.in_combat, "combat en cours")
	# Mobilité : la reine se déplace dans toute la vasque sans en sortir.
	var inside := true
	var start_pos := queen.global_position
	_place(Vector3(-62.4, 8.2, -30.25), 90.0)
	for i in 16:
		await _wait(0.5)
		inside = inside and queen.is_inside_walk_area(queen.global_position) and queen.global_position.y > 7.4 and queen.global_position.y < 8.6
		if i == 5:
			_place(Vector3(-55.4, 8.2, -30.2), -90.0)
	_check(queen.travelled > 1.0 and queen.global_position.distance_to(start_pos) > 0.5, "la reine se déplace (%.1f u parcourues)" % queen.travelled)
	_check(inside, "elle reste dans la vasque, sur les zones praticables")
	# Enlisement dans la matière.
	GameState.restore_integrity(GameState.integrity_max)
	_place(Vector3(-61.2, 7.7, -32.2), -90.0)
	await _wait(1.5)
	_check(arena.mire.is_nino_inside() and _nino.get_speed_factor() < 0.8 and _nino.get_visual()._sink > 0.02, "matière : ralentit et enfonce progressivement")
	_check(_nino.get_accel_factor() < 0.5, "matière : accélération réduite (inertie du liquide)")
	_place(Vector3(-62.4, 8.2, -30.25), -90.0)
	await _wait(0.6)
	_check(not arena.mire.is_nino_inside() and is_equal_approx(_nino.get_accel_factor(), 1.0), "sur un débris flottant : aucun enlisement (refuge sûr)")
	_place(Vector3(-61.2, 7.7, -32.2), -90.0)
	await _wait(1.0)
	_check(_nino.get_jump_factor() < 1.0 and _nino.damage_taken_multiplier > 1.0, "matière : saut réduit, plus vulnérable")
	# Crachat d'acide : préparation, trajectoire, ralentissement.
	var spits := queen.spits
	var acid_before := queen.acid_hits
	# Nin0 bouge (sinon la reine vient le chercher au contact) jusqu'au crachat.
	var spat := false
	for i in 12:
		_place(Vector3(-61.6, 7.7, -30.5) if i % 2 == 0 else Vector3(-62.3, 7.7, -32.9), -90.0)
		if await _wait_until(1.0, func() -> bool: return queen.spits > spits):
			spat = true
			break
	_check(spat, "la reine crache de l'acide à distance (préparation visible)")
	var hit := await _wait_until(3.0, func() -> bool: return queen.acid_hits > acid_before)
	_check(hit and _nino.is_slowed(), "acide : dégâts modérés et ralentissement temporaire")
	_place(Vector3(-55.4, 8.15, -30.2), -90.0)
	await _wait(2.4)
	_check(not _nino.is_slowed(), "ralentissement limité dans le temps")
	# Esquive : se déplacer pendant le vol.
	var hits := queen.acid_hits
	await _wait_until(5.0, func() -> bool: return queen.state == AntQueen.State.SPIT_WINDUP)
	await _wait_until(2.0, func() -> bool: return queen.state == AntQueen.State.SPIT_RECOVER)
	var dodge := Vector3(-62.4, 8.2, -30.25) if _nino.global_position.x > -59.0 else Vector3(-55.4, 8.15, -30.2)
	_place(dodge, -90.0)
	await _wait(1.3)
	_check(queen.acid_hits == hits, "crachat esquivé en se déplaçant")
	# Coup de mandibules au contact.
	GameState.restore_integrity(GameState.integrity_max)
	await _wait_until(4.0, func() -> bool: return queen.state in [AntQueen.State.WATCH, AntQueen.State.MOVE])
	var front := queen.global_position - queen.global_basis.z * 1.1
	_place(Vector3(front.x, queen.global_position.y + 0.1, front.z), 0.0)
	var windup := await _wait_until(6.0, func() -> bool: return queen.state == AntQueen.State.MELEE_WINDUP)
	_check(windup, "au contact : préparation lente de la morsure")
	# Dégâts comptés au moment du coup (le bouclier se recharge pendant la préparation).
	var taken := [0.0]
	var count := func(loss: float, shield_loss: float) -> void: taken[0] += loss + shield_loss
	_game.integrity.damaged.connect(count)
	var hits_before := queen.melee_hits
	var melee := await _wait_until(3.0, func() -> bool: return queen.melee_hits > hits_before)
	_game.integrity.damaged.disconnect(count)
	_check(melee and taken[0] >= 30.0, "morsure de la reine : très dangereuse (%.0f)" % taken[0])
	GameState.restore_integrity(GameState.integrity_max)
	await _wait(1.0)
	var front2 := queen.global_position - queen.global_basis.z * 1.1
	_place(Vector3(front2.x, queen.global_position.y + 0.1, front2.z), 0.0)
	await _wait_until(6.0, func() -> bool: return queen.state == AntQueen.State.MELEE_WINDUP)
	var melee_hits := queen.melee_hits
	var away := queen.global_position + queen.global_basis.z * 0.0 + (Vector3(-62.4, 8.2, -30.25) - queen.global_position).normalized() * 2.6
	_place(Vector3(clampf(away.x, -63.0, -55.0), 8.2, clampf(away.z, -33.8, -29.8)), 90.0)
	await _wait(1.6)
	_check(queen.melee_hits == melee_hits, "morsure esquivée (portée limitée)")
	# Échec : remise en place propre, progression conservée.
	_director.integrity.take_damage(999.0, true)
	var reset := await _wait_until(6.0, func() -> bool: return arena.phase == SinkArena.Phase.IDLE and _nino.controls_enabled)
	_check(reset and queen.state == AntQueen.State.DORMANT and not GameState.queen_defeated and not arena.is_cinematic(), "échec : arène et reine réinitialisées")
	await _wait(0.5)
	_check(Music.desired == &"labyrinth", "après l'échec, retour à la musique des labyrinthes")
	_check(_nino.global_position.distance_to(_game.bath.marker("StoolTop").origin) < 0.6, "reprise au point sûr avant le combat (haut de l'escabeau)")
	_check(GameState.has_memory(&"memory_02") and GameState.has_discovery(&"plan_armor_1"), "progression conservée après l'échec")
	# Victoire : traverser jusqu'à l'anneau, tirer la chaînette.
	_place(Vector3(-64.4, 8.55, -31.75), -90.0)
	await _wait_until(4.0, func() -> bool: return arena.phase == SinkArena.Phase.FIGHT)
	_check(arena.phase == SinkArena.Phase.FIGHT, "nouvel essai (présentation raccourcie)")
	_check(not arena.ring_interact.enabled or arena.phase == SinkArena.Phase.FIGHT, "anneau actif pendant le combat seulement")
	_place(Vector3(-53.75, 8.55, -32.6), 0.0)
	await _wait(0.4)
	arena.ring_interact.interacted.emit(_nino)
	await _wait(0.2)
	_check(arena.phase == SinkArena.Phase.DRAINING, "vidange déclenchée par l'anneau (interaction physique)")
	await _wait(1.0)
	_check(arena.is_cinematic() and not _nino.controls_enabled, "fin du combat mise en scène (caméra sur la vasque)")
	await _wait(1.5)
	_check(queen.state == AntQueen.State.SWEPT, "la reine réagit et tente de rejoindre son éponge")
	var won := await _wait_until(9.0, func() -> bool: return arena.phase == SinkArena.Phase.DONE)
	_check(won and GameState.queen_defeated and not queen.visible, "la matière s'évacue, la reine est emportée")
	_check(not arena.mire.monitoring and not GameState.in_combat, "plus d'enlisement après la vidange")
	var p1 := arena.get_node("Platforms/P1Sponge") as Node3D
	_check(8.5 - (p1.global_position.y + 0.2) <= 0.95, "après la vidange, on ressort du lavabo (marche %.2f u)" % (8.5 - (p1.global_position.y + 0.2)))
	var plan := await _wait_until(10.0, func() -> bool: return _game.blueprint._open)
	_check(plan, "réflexion : plan du canon présenté")
	await _wait(2.6)
	_game.blueprint.close()
	await _wait(0.3)
	_check(GameState.has_discovery(&"plan_cannon") and not GameState.has_cannon(), "plan du canon débloqué (à fabriquer)")
	await _wait(0.8)
	_check(Music.desired == &"labyrinth", "après la victoire, retour à la musique des labyrinthes")
	_check(_objective() == "Fabriquer le canon à l'imprimante", "objectif : retour à l'imprimante")
	_place(Vector3(-64.4, 8.55, -31.75), -90.0)
	await _wait(1.0)
	_check(arena.phase == SinkArena.Phase.DONE, "victoire définitive (pas de nouveau combat)")


# --- Canon ------------------------------------------------------------------------------

func _test_cannon() -> void:
	_teleport_marker(_director.get_node("Checkpoints/Printer"))
	await _wait(0.5)
	_check(_director._printer_upgrades().any(func(u: UpgradeData) -> bool: return u.id == &"cannon"), "imprimante : plan du canon proposé")
	GameState.fragments = 4
	_director._on_upgrade_requested(&"cannon")
	await _wait(0.5)
	_check(not _nino.controls_enabled and _director.printer.state == Printer3D.State.SERVICING, "impression du canon en cours")
	var done := await _wait_until(40.0, func() -> bool: return GameState.has_cannon() and _nino.controls_enabled)
	var model := _nino.get_visual().get_cannon()
	_check(done and model != null and model.visible, "canon imprimé puis installé physiquement sur Nin0")
	_check(GameState.ammo_plastic >= 6 and GameState.fragments == 1, "premier chargement de billes (%d)" % GameState.ammo_plastic)
	_check(GameState.upgrades.count(&"cannon") == 1 and GameState.module_slots == 2 and not GameState.equipped_modules.has(&"cannon"), "amélioration majeure permanente (aucun emplacement utilisé)")
	# Tir.
	var cannon := _game.cannon
	var ammo := GameState.ammo_plastic
	await _wait(0.5)
	_check(cannon.fire() and GameState.ammo_plastic == ammo - 1, "tir : une bille consomme un plastique")
	var impacts := [0]
	cannon.hit.connect(func(_c: Object) -> void: impacts[0] += 1)
	await _wait(1.2)
	_check(impacts[0] >= 1, "la bille touche le décor (collision physique)")
	# Sur un soldat.
	var soldier: AntSoldier = _game.bath.get_node("Soldiers/SoldierToilet")
	soldier.reset_to_post()
	_place(soldier.global_position + Vector3(0.0, 0.05, 2.0), 0.0)
	await _wait(0.3)
	var muzzle := model.get_muzzle()
	cannon._launch(muzzle, (soldier.global_position + Vector3.UP * 0.1 - muzzle).normalized() * cannon.ammo.speed)
	var staggered := await _wait_until(1.5, func() -> bool: return soldier.state == AntSoldier.State.STAGGER or soldier.health < soldier.max_health)
	_check(staggered, "une bille touche un soldat (recul)")
	_teleport_marker(_game.bath.get_node("Markers/BathEntry"))
	# Munitions épuisées : clic, rien ne bloque.
	var saved := GameState.ammo_plastic
	GameState.ammo_plastic = 0
	await _wait(0.5)
	_check(not cannon.fire(), "sans billes : clic à vide, aucun blocage")
	GameState.ammo_plastic = saved


# --- Cuisine ----------------------------------------------------------------------------

func _test_kitchen() -> void:
	var door := _game.sas.kitchen_door
	_teleport_marker(_game.sas.get_node("Markers/KitchenDoorFront"))
	# De retour au sas avec le canon : courte mise en scène sur le crochet.
	var lesson := await _wait_until(3.0, func() -> bool: return _game._sequence and not _nino.controls_enabled)
	await _wait(1.6)
	_check(lesson and get_viewport().get_camera_3d() != _camera.get_camera(), "mise en scène : la caméra montre le crochet en hauteur")
	var ready := await _wait_until(10.0, func() -> bool: return GameState.seen_notices.has(&"kitchen_latch_lesson") and _nino.controls_enabled)
	_check(ready and get_viewport().get_camera_3d() == _camera.get_camera(), "contrôle et caméra rendus après la mise en scène")
	var ring := _game.sas.get_node_or_null("FireSpotRing") as Node3D
	_check(ring != null and ring.visible and door._glow_light != null, "repère de tir au sol et crochet mis en valeur")
	await _wait(1.0)
	_check(not door.is_unlocked, "aucun tir automatique : le joueur tire lui-même")
	_check(not await _drive(Vector3(-40.0, 0.05, 8.0), 90.0, 4, 2.5), "cuisine toujours fermée avant le tir")
	# Depuis le repère, en vision focalisée, le crochet se vise (caméra levée jusqu'à 62°).
	_teleport_marker(_game.sas.get_node("Markers/FireSpot"))
	await _wait(0.5)
	var aim: Dictionary = _director.focus_vision.find_aimed(_nino.global_position + Vector3.UP * 0.4, (door.latch_focus.global_position - _nino.global_position - Vector3.UP * 0.4).normalized())
	_check(aim.target == door.latch_focus and aim.status == FocusVision.Status.OK, "loquet repérable avec la vision focalisée depuis le repère")
	_camera.set_first_person(true)
	await _wait(0.4)
	var cam := _camera.get_camera()
	var hook := door.latch_focus.global_position
	var to := hook - cam.global_position
	_camera.rotation.y = atan2(-to.x, -to.z) + deg_to_rad(2.0)
	_camera.pitch = asin(to.normalized().y)
	await _wait(0.3)
	to = hook - cam.global_position
	var off_axis := rad_to_deg((-cam.global_basis.z).angle_to(to))
	_check(off_axis < 6.0 and rad_to_deg(_camera.pitch) > 35.0, "angle de visée confortable (%.0f° de hauteur)" % rad_to_deg(_camera.pitch))
	_check(_game.cannon.aim_point().distance_to(hook) < 0.05, "aide à la visée : le crochet est ciblé malgré un léger écart")
	GameState.ammo_plastic = maxi(GameState.ammo_plastic, 4)
	var shots := _game.cannon.shots
	_game.cannon._cooldown = 0.0
	_check(_game.cannon.fire() and _game.cannon.shots == shots + 1, "le joueur tire (commande du canon)")
	var unlocked := await _wait_until(3.0, func() -> bool: return door.is_unlocked)
	_camera.set_first_person(false)
	_check(unlocked, "la bille (trajectoire compensée) soulève le crochet : la porte se déverrouille")
	var opened := await _wait_until(5.0, func() -> bool: return GameState.kitchen_unlocked)
	var angle := rad_to_deg(door.get_node("Hinge").rotation.y)
	_check(opened and angle > 12.0 and angle < 20.0, "la porte s'entrouvre légèrement (%.0f°), sans dévoiler la cuisine" % angle)
	_check(not ring.visible, "le repère disparaît")
	_check(_objective() == "Entrer dans la cuisine", "objectif : entrer dans la cuisine")
	var reached := await _drive(Vector3(-40.0, 0.05, 3.6), 90.0, 4, 6.0)
	_check(reached, "la cuisine est accessible")
	var ended := await _wait_until(6.0, func() -> bool: return _game.chapter_end.visible)
	_check(ended and GameState.chapter2_completed, "fin du chapitre 2 à l'entrée de la cuisine")
	await _wait(1.8)
	_game.chapter_end._on_continue()
	await _wait(0.3)
	_check(not get_tree().paused and _nino.controls_enabled, "« Continuer à explorer »")
	_check(not await _drive(Vector3(-38.0, 0.05, 31.5), 90.0, 4, 3.0) or _game.zone_at(_nino.global_position) != 6, "cuisine ↔ salon toujours fermé")
	_check(not await _drive(Vector3(-31.5, 0.05, 5.0), 180.0, 6, 3.0), "salon toujours fermé après l'ouverture de la cuisine")


## Objectif affiché hors mode développement (le mode développement n'en affiche pas).
func _objective() -> String:
	GameState.dev_mode = false
	var text := GameState.get_objective()
	GameState.dev_mode = true
	return text


# --- Ressources -------------------------------------------------------------------------

func _test_resources() -> void:
	var pickup: ResourcePickup = _game.sas.get_node("Pickups/PlasticUmbrella")
	var reserve: ResourcePickup = _game.sas.get_node("Pickups/PlasticReserve")
	GameState.playtime += 1000.0
	pickup.refresh()
	reserve.refresh()
	GameState.ammo_plastic = 0
	GameState.seen_notices.erase(&"resource_plastic")
	var notices := [0]
	var count := func(_k: StringName) -> void: notices[0] += 1
	GameState.resource_discovered.connect(count)
	_place(reserve.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	await _wait(0.5)
	_check(GameState.ammo_plastic == reserve.amount and not reserve.visible, "plastique ramassé (+%d billes)" % reserve.amount)
	_check(notices[0] == 1 and _game.hud._notice_title.text == "Plastique à projectiles découvert", "première découverte du plastique annoncée")
	_place(pickup.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	await _wait(0.5)
	_check(notices[0] == 1 and GameState.ammo_plastic == reserve.amount + pickup.amount, "pas de seconde annonce (simple ramassage)")
	_check(GameState.ammo_plastic <= GameState.PLASTIC_MAX, "compteur borné (%d / %d)" % [GameState.ammo_plastic, GameState.PLASTIC_MAX])
	GameState.resource_discovered.disconnect(count)
	# Réapparition : après un délai de jeu, loin de Nin0, jamais instantanée.
	_place(Vector3(-20.0, 0.05, 0.0), 0.0)
	await _wait(2.5)
	_check(not pickup.visible, "pas de réapparition immédiate")
	GameState.playtime += pickup.respawn_delay + 1.0
	await _wait(2.5)
	_check(pickup.visible, "ressource ordinaire réapparue après un délai")
	var hub: Array = _director.get_node("Pickups").get_children()
	_check(hub.all(func(p: Node) -> bool: return (p as ResourcePickup).respawn_delay > 0.0), "filament du placard : ressource ordinaire (réapparaît)")
	_check(not GameState.is_pickup_available(&"memory_02", 0.0) or not GameState.has_memory(&"memory_02") or GameState.memory_count() == GameState.memories.size(), "les souvenirs restent uniques")


# --- Sauvegardes ------------------------------------------------------------------------

func _test_saves() -> void:
	GameState.dev_mode = false
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.resume_point = &"bath"
	GameState.save()
	var snapshot := {
		"species": GameState.species.duplicate(), "upgrades": GameState.upgrades.duplicate(), "equipped": GameState.equipped_modules.duplicate(),
		"ammo": GameState.ammo_plastic, "fragments": GameState.fragments, "memories": GameState.memories.duplicate(),
		"reads": GameState.memory_reads.size(), "discoveries": GameState.discoveries.duplicate(),
	}
	GameState.reset_progress()
	GameState.load_save()
	_check(GameState.species == snapshot.species and GameState.upgrades == snapshot.upgrades and GameState.equipped_modules == snapshot.equipped, "sauvegarde : espèces, améliorations, équipement")
	_check(GameState.ammo_plastic == snapshot.ammo and GameState.fragments == snapshot.fragments, "sauvegarde : deux ressources")
	_check(GameState.memories == snapshot.memories and GameState.memory_reads.size() == snapshot.reads, "sauvegarde : souvenirs et commentaires")
	_check(GameState.queen_defeated and GameState.kitchen_unlocked and GameState.chapter2_completed and GameState.worker_met and GameState.boss_started,
			"sauvegarde : reine vaincue, cuisine, chapitre, rencontre")
	_check(GameState.discoveries.has(&"plan_cannon") and GameState.discoveries.has(&"plan_armor_1") and GameState.resume_point == &"bath", "sauvegarde : plans et point de reprise")
	_check(_game._resume_transform() is Transform3D, "reprise dans la salle de bain possible")
	# Sauvegarde du lot 4 (version 4) : relue, valeurs du lot 5 par défaut.
	var old := ConfigFile.new()
	old.set_value("meta", "version", 4)
	for flag in ["woke_up", "tutorial_done", "printer_seen", "power_on", "printer_understood", "legs_printed", "legs_installed", "door_opened", "injured", "repaired"]:
		old.set_value("progress", flag, true)
	old.set_value("nino", "fragments", 2)
	old.set_value("collections", "memories", PackedStringArray(["memory_01"]))
	old.save(GameState.TEST_SAVE_PATH)
	GameState.reset_progress()
	GameState.load_save()
	_check(GameState.repaired and GameState.fragments == 2 and GameState.has_memory(&"memory_01"), "ancienne sauvegarde (lot 4) relue")
	_check(not GameState.queen_defeated and GameState.species.is_empty() and GameState.ammo_plastic == 0 and GameState.equipped_modules.is_empty(), "ancienne sauvegarde : chapitre 2 non commencé")
	GameState.erase_save()
	GameState.save_path = GameState.SAVE_PATH
	var now := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_existed and now == _personal, "la sauvegarde personnelle n'a pas été touchée")


# --- Outils -----------------------------------------------------------------------------

## Parcours en largeur sur une grille (pas de 0,25 u) : Nin0 (0,36 u de large) peut-il
## aller de a à b au sol, en ignorant les obstacles plus bas que `low` (enjambés) ?
func _reachable(a: Vector3, b: Vector3, low: float, high: float, margin := 0.0) -> bool:
	var space := _nino.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.34 + margin, high - low, 0.34 + margin)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var step := 0.25
	var start := Vector2i(roundi(a.x / step), roundi(a.z / step))
	var goal := Vector2i(roundi(b.x / step), roundi(b.z / step))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size() and head < 60000:
		var cell := queue[head]
		head += 1
		if (cell - goal).length() <= 2.0:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + d
			if seen.has(next):
				continue
			seen[next] = true
			var x := next.x * step
			var z := next.y * step
			if x < -75.0 or x > -40.0 or z < -35.0 or z > 0.0:
				continue
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, (low + high) * 0.5, z))
			if space.intersect_shape(query, 1).is_empty():
				queue.append(next)
	return false


## Un collisionneur du monde occupe-t-il ce point ?
func _solid_at(point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	return not _nino.get_world_3d().direct_space_state.intersect_point(query, 1).is_empty()


## Le corps d'un soldat passe-t-il sur tout le trajet (boucle) ?
func _path_clear(points: PackedVector3Array) -> bool:
	var space := _nino.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.22, 0.14, 0.22)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		for k in 21:
			query.transform = Transform3D(Basis.IDENTITY, a.lerp(b, k / 20.0) + Vector3.UP * 0.12)
			if not space.intersect_shape(query, 1).is_empty():
				return false
	return true


## Saut d'un appui à l'autre en mode jambes (vraie physique).
func _hop(from: Vector3, to: Vector3) -> bool:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var yaw := atan2(-flat.x, -flat.z)
	_nino.global_position = from + Vector3.UP * 0.05
	_nino.rotation.y = yaw
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = yaw
	_camera.snap_to_target()
	await _wait(0.35)
	Input.action_press("jump")
	Input.action_press("move_forward")
	var airborne := false
	for i in 120:
		await get_tree().physics_frame
		var remaining := Vector2(to.x - _nino.global_position.x, to.z - _nino.global_position.z).length()
		if remaining < 0.12 or (_nino.global_position.y > to.y - 0.05 and remaining < 0.35 and _nino.velocity.y < 0.0):
			Input.action_release("move_forward")
		if i > 18:
			Input.action_release("jump")
		if not _nino.is_on_floor():
			airborne = true
		elif airborne:
			break
	Input.action_release("move_forward")
	Input.action_release("jump")
	await _wait(0.3)
	return absf(_nino.global_position.y - to.y) < 0.12


func _drive(from: Vector3, yaw_degrees: float, zone: int, timeout := 6.0) -> bool:
	_place(from, yaw_degrees)
	await _wait(0.2)
	return await _hold_until(timeout, func() -> bool: return _game.zone_at(_nino.global_position) == zone)


func _place(position: Vector3, yaw_degrees: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = deg_to_rad(yaw_degrees)
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = deg_to_rad(yaw_degrees)
	_camera.snap_to_target()


func _teleport_marker(marker: Node3D) -> void:
	_nino.global_transform = marker.global_transform
	_nino.velocity = Vector3.ZERO
	_nino.set_checkpoint(marker.global_transform)
	_camera.rotation.y = marker.global_rotation.y
	_camera.snap_to_target()


func _texts(root: Node) -> PackedStringArray:
	var list := PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		list.append((node as Label).text)
	return list


func _find_button(root: Node, text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == text and not _dying(node):
			return node
	return Button.new()


## Vrai si le nœud ou l'un de ses parents attend sa suppression (interface reconstruite).
func _dying(node: Node) -> bool:
	while node:
		if node.is_queued_for_deletion():
			return true
		node = node.get_parent()
	return false


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


func _wait_until(timeout: float, condition: Callable) -> bool:
	for i in ceili(timeout * 60.0):
		await get_tree().physics_frame
		if condition.call():
			return true
	return false


func _wait(seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await get_tree().physics_frame


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "ÉCHEC", label])
	if not condition:
		_failures += 1
