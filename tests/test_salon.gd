extends Node
## Test du début du salon (lot 7C), sans affichage :
##   godot --headless --fixed-fps 60 --path . res://tests/test_salon.tscn
## Joue dans la scène de développement (aucune sauvegarde personnelle touchée) :
## agencement, seconde partie barrée, musique, Nathan (souvenir n° 4, ordres, récupération),
## bascule (coopération), protection, box internet (souvenir n° 5), trophées, sauvegardes.

const APARTMENT := preload("res://scenes/levels/apartment.tscn")

var _failures := 0
var _dev: Node3D
var _game: GameWorld
var _salon: SalonZone
var _nathan: Nathan
var _nino: NinoController
var _camera: ThirdPersonCamera
var _director: Node3D
var _personal_existed := false
var _personal := ""
var _trophies_existed := false
var _trophies := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	seed(9)
	_personal_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_existed else ""
	_trophies_existed = FileAccess.file_exists(Achievements.SAVE_PATH)
	_trophies = FileAccess.get_file_as_string(Achievements.SAVE_PATH) if _trophies_existed else ""
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	Achievements.reset_test_file()
	_dev = APARTMENT.instantiate()
	add_child(_dev)
	_game = _dev.game
	_salon = _game.salon
	_nathan = _salon.nathan
	_nino = _dev.nino
	_camera = _dev.camera
	_director = _dev.workshop
	await _wait(1.5)
	_game.run_dev_scenario(&"salon")
	await _wait(1.0)

	await _test_layout()
	await _test_blocked()
	await _test_meeting()
	await _test_orders()
	await _test_seesaw()
	await _test_protection()
	await _test_box()
	await _test_trophies()
	await _test_saves()

	Sfx.stop_all_loops()
	GameState.erase_save()
	Achievements.reset_test_file()
	GameState.save_path = GameState.SAVE_PATH
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_existed and
			(not _personal_existed or FileAccess.get_file_as_string(GameState.SAVE_PATH) == _personal),
			"sauvegarde personnelle intacte")
	_check(FileAccess.file_exists(Achievements.SAVE_PATH) == _trophies_existed and
			(not _trophies_existed or FileAccess.get_file_as_string(Achievements.SAVE_PATH) == _trophies),
			"trophées personnels intacts")
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- Lieu ---------------------------------------------------------------------------------

func _test_layout() -> void:
	await _wait(1.0)
	_check(_game.zone_at(_nino.global_position) == GameWorld.ZONE_SALON and GameState.salon_entered, "scénario : Nin0 dans le salon (entrée enregistrée)")
	await _wait(1.5)
	_check(Music.desired == &"living_room" and Music.has_track(&"living_room"), "musique « living room - Nin0 » dans le salon")
	var track: Dictionary = Music.TRACKS[&"living_room"]
	var length := (load(track.path) as AudioStream).get_length()
	_check(track.loop and track.loop_offset > 30.0 and length - track.loop_offset > 35.0 and length < 80.0,
			"boucle du salon : reprise à %.2f s, coupée avant le fondu (%.2f s)" % [track.loop_offset, length])
	var volumes := _game.blockout.get_node("Volumes")
	_check(["SofaBase", "SofaBack", "CoffeeTable", "TvStand"].all(func(n: String) -> bool: return volumes.get_node_or_null(n) == null),
			"volumes provisoires de la première partie retirés du blockout")
	_check(_game.blockout.get_node_or_null("Lights/Light_salon") == null and _salon.get_node_or_null("WindowSun") is SpotLight3D, "éclairage propre : porte-fenêtre lumineuse")
	var furniture := _salon.get_node("Furniture")
	for n in ["SofaSeat", "CoffeeTop", "NestTop", "TvStandTop", "Tv", "ConsoleA", "DeskTop", "Monitor", "PcTower", "ChairSeat", "CubbyTop", "RackHigh", "InternetBox"]:
		if furniture.get_node_or_null(n) == null:
			_check(false, "meuble manquant : " + n)
	_check(true, "contenu : canapé, tables basses, meuble TV et consoles, bureau + ordinateur + chaise, rangements, étendoir, box")
	_check(_objective() == "Explorer le salon", "objectif : explorer le salon")
	# Sous le canapé et sous la table basse : on passe (dessous ouverts).
	var space := _nino.get_world_3d().direct_space_state
	var under_sofa := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-34.0, 0.4, 32.0), Vector3(-44.4, 0.4, 32.0), 1))
	_check(under_sofa.is_empty(), "passage sous le canapé (jusqu'au mur)")
	var under_table := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-26.0, 0.4, 27.0), Vector3(-26.0, 0.4, 39.0), 1))
	_check(under_table.is_empty(), "passage sous la table basse")
	# Hauteurs : la table basse se rejoint par le coussin et le pouf (saut chargé), le meuble TV non.
	_check(_top_at(Vector3(-34.9, 6.0, 34.5)) < 1.2 and absf(_top_at(Vector3(-32.3, 6.0, 34.5)) - 2.6) < 0.1 and absf(_top_at(Vector3(-26.0, 6.0, 33.0)) - 4.0) < 0.15,
			"marches : coussin (1,0) → pouf (2,6) → table basse (4,0)")
	_check(absf(_top_at(Vector3(-12.6, 8.0, 31.0)) - 5.0) < 0.1, "meuble TV : 5,0 (hors de portée depuis le sol, même avec le saut chargé)")


## Hauteur du premier obstacle sous un point.
func _top_at(point: Vector3) -> float:
	var space := _nino.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point, point + Vector3.DOWN * 20.0, 1))
	return (hit.position as Vector3).y if not hit.is_empty() else -1.0


func _test_blocked() -> void:
	# La seconde partie (est) est barrée par l'encombrement : bacs, paravent, plante.
	var crossed := false
	for z in [20.0, 31.0, 37.0, 43.5, 50.0, 55.0]:
		_place(Vector3(-3.0, 0.05, z), -90.0)
		await _hold(2.0)
		if _nino.global_position.x > 0.5:
			crossed = true
	_check(not crossed, "seconde partie du salon inaccessible (encombrement physique, aucun mur invisible)")
	var space := _nino.get_world_3d().direct_space_state
	for z in [31.0, 43.6, 50.0]:
		var top := _top_at(Vector3(1.5, 23.0, z))
		if top < 16.5:
			_check(false, "encombrement trop bas à z = %.1f (%.1f)" % [z, top])
	_check(true, "encombrement haut (≥ 16,5 u) : on ne peut pas passer par-dessus")
	_check(_game.blockout.get_node_or_null("Openings/CurtainChamberLock") != null, "chambre toujours verrouillée")
	_place(_salon.marker("SalonEntry").origin, 180.0)
	await _wait(0.5)


# --- Nathan -------------------------------------------------------------------------------

func _test_meeting() -> void:
	_check(not _nathan.is_awake() and _nathan.body.dormant > 0.9, "Nathan : figurine inerte avant d'être observée")
	var noticed := await _wait_until(4.0, func() -> bool: return _game._shown.has(&"scan_nathan"))
	_check(noticed and not GameState.has_memory(&"memory_04"), "Nin0 remarque la figurine ; invitation à l'observer (aucune rencontre automatique)")
	_place(_nathan.global_position + Vector3(1.6, 0.05, -2.2), 145.0)
	await _wait(0.4)
	var eye := _nino.global_position + Vector3.UP * 0.4
	var aim: Dictionary = _director.focus_vision.find_aimed(eye, (_nathan.focus.global_position - eye).normalized())
	_check(aim.target == _nathan.focus, "Nathan est observable (vision focalisée)")
	var hp := GameState.integrity + GameState.shield
	_director.focus_vision.target_identified.emit(_nathan.focus)
	var started := await _wait_until(2.0, func() -> bool: return _game.cine.is_active() and _game.cine.reason == &"memory_04")
	_check(started and not _nino.controls_enabled and GameState.hazards_suspended(), "rencontre : courte mise en scène, contrôle retiré, dangers suspendus")
	var said := {}
	var listen := func() -> void:
		if _game.subtitles.showing:
			said[_game.subtitles._text.text] = _game.subtitles._name.text
	get_tree().physics_frame.connect(listen)
	var done := await _wait_until(60.0, func() -> bool: return GameState.has_memory(&"memory_04") and _nino.controls_enabled and not _game.cine.is_active())
	get_tree().physics_frame.disconnect(listen)
	_check(done and _nathan.is_awake(), "fin de la rencontre : Nathan s'anime, archive 04/07")
	var lines := said.keys()
	_check(said.values().has("Nathan") and said.values().has("Nin0"), "échange sous-titré : Nathan (jouet) et Nin0 (robot)")
	for key in ["robot", "jouet", "ensemble", "géant", "chambre", "longtemps", "méchant", "inquiéter"]:
		if not lines.any(func(l: String) -> bool: return l.contains(key)):
			_check(false, "Nathan révèle : « %s » manquant" % key)
	_check(true, "Nathan révèle seulement : robot / jouet / faits ensemble / le géant, la chambre, longtemps, pas méchant, inquiet")
	_check(GameState.integrity + GameState.shield >= hp - 0.01 and not GameState.hazards_suspended(), "aucun dégât pendant la rencontre ; dangers rétablis")
	_check(_game.commands.enabled and _nathan.state == Nathan.State.FOLLOW, "Nathan devient compagnon (ordres disponibles)")
	_check(_objective() == "Atteindre la lumière qui clignote, avec Nathan", "objectif : la lumière qui clignote")
	var count := GameState.memory_count()
	_director.focus_vision.target_identified.emit(_nathan.focus)
	await _wait(1.0)
	_check(GameState.memory_count() == count and _nino.controls_enabled, "réobserver Nathan ne redéclenche rien")


func _test_orders() -> void:
	# Suis-moi : il rejoint Nin0.
	_place(Vector3(-30.0, 0.05, 22.0), 180.0)
	var followed := await _wait_until(8.0, func() -> bool: return _nathan.global_position.distance_to(_nino.global_position) < 2.4)
	_check(followed, "Suis-moi : Nathan suit Nin0")
	# Attends : il reste sur place.
	_game.commands.choose(1, Vector3.INF)
	var spot := _nathan.global_position
	_place(Vector3(-22.0, 0.05, 22.0), 180.0)
	await _wait(2.0)
	_check(_nathan.state == Nathan.State.WAIT and _nathan.global_position.distance_to(spot) < 0.4, "Attends : Nathan reste où il est")
	# Va là-bas : vers un point visé.
	_game._on_order(&"goto", Vector3(-26.0, 0.0, 26.0))
	var went := await _wait_until(8.0, func() -> bool: return _nathan.global_position.distance_to(Vector3(-26.0, 0.0, 26.0)) < 0.6)
	_check(went, "Va là-bas : Nathan rejoint le point désigné")
	# Interface légère : barre des ordres (G), rappel de l'ordre en cours.
	_game.commands.open()
	_check(_game.commands.is_open and _game.commands._items.size() == 4, "barre des quatre ordres (Suis-moi, Attends, Va là-bas, Interagis)")
	_game.commands.choose(0, Vector3.INF)
	_check(not _game.commands.is_open and _nathan.state == Nathan.State.FOLLOW and _game.commands._status.text.contains("suit"), "ordre choisi : barre refermée, rappel discret")
	# Récupération : Nin0 très loin → Nathan réapparaît près de lui, hors champ.
	_place(Vector3(-40.0, 0.05, 50.0), 0.0)
	_nathan.global_position = Vector3(-2.0, 0.0, 14.0)
	await _wait(0.2)
	_nathan.recover_near(_nino)
	await _wait(0.3)
	_check(_nathan.global_position.distance_to(_nino.global_position) < 2.5, "récupération : Nathan coincé réapparaît près de Nin0")
	var cam := get_viewport().get_camera_3d()
	_check(cam == null or not cam.is_position_in_frustum(_nathan.global_position + Vector3.UP * 0.6), "réapparition hors du champ de la caméra")
	# Peur : il fuit vers l'abri, puis reprend son ordre.
	_nathan.scare(_nino)
	_check(_nathan.state == Nathan.State.SCARED, "effrayé, il fuit vers un abri (jamais blessé)")
	var calm := await _wait_until(14.0, func() -> bool: return _nathan.state == Nathan.State.FOLLOW)
	_check(calm, "puis il revient et reprend son ordre")


func _test_seesaw() -> void:
	var seesaw := _salon.seesaw
	_check(seesaw.east_end_height() < 0.6 and not seesaw.held, "bascule au repos : l'extrémité côté meuble TV touche le sol")
	# Nin0 seul : trop léger, la règle ne bouge pas ; il ne peut pas atteindre le meuble TV.
	_place(seesaw.surface_point(-3.0) + Vector3.UP * 0.3, 90.0)
	await _wait(1.5)
	_check(not seesaw.held, "Nin0 seul : trop léger pour faire basculer la règle")
	seesaw.inspect.interacted.emit(_nino)
	await _wait(0.2)
	_check(_game._shown.has(&"seesaw"), "Nin0 comprend : il faut Nathan (indice sur l'ordre « Interagis »)")
	_place(Vector3(-17.0, 0.05, 43.5), 180.0)
	await _wait(1.0)
	_game._on_order(&"interact", seesaw.companion_point())
	var climbing := await _wait_until(10.0, func() -> bool: return _nathan.state == Nathan.State.SCRIPTED)
	_check(climbing, "Interagis : Nathan rejoint la règle et monte dessus")
	var held := await _wait_until(12.0, func() -> bool: return seesaw.held and _nathan.is_holding())
	_check(held and GameState.seesaw_done, "la règle bascule sous son poids ; il la tient (énigme résolue)")
	await _wait(1.0)
	_check(absf(seesaw.east_end_height() - 4.45) < 0.2, "extrémité est levée à %.2f (sous le meuble TV, 5,0)" % seesaw.east_end_height())
	_check(_objective() == "Monter sur le meuble de la télévision", "objectif : monter sur le meuble TV")
	# Nin0 monte la règle (vraie physique) jusqu'au meuble TV.
	_place(seesaw.surface_point(-4.4) + Vector3.UP * 0.2, -90.0)
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.4)
	var up := await _hold_until(8.0, func() -> bool: return _nino.global_position.y > 4.3)
	_check(up, "Nin0 gravit la règle inclinée (%.2f)" % _nino.global_position.y)
	Input.action_press("move_forward")
	await _wait(0.1)
	Input.action_press("jump")
	await _wait(0.2)
	Input.action_release("jump")
	var landed := await _wait_until(2.0, func() -> bool: return _salon.on_tv_stand(_nino.global_position) and _nino.is_on_floor())
	Input.action_release("move_forward")
	_check(landed, "saut sur le meuble de la télévision (%s)" % _nino.global_position)


func _test_protection() -> void:
	var started := await _wait_until(3.0, func() -> bool: return _salon.protection_active)
	_check(started, "sur le meuble TV : des cafards sortent de sous le canapé, vers Nathan")
	_check(_game.subtitles.showing, "Nathan appelle à l'aide (sous-titre)")
	var raider: SalonRaider
	var spawned := await _wait_until(4.0, func() -> bool:
		var list := get_tree().get_nodes_in_group(&"salon_raiders")
		if list.is_empty():
			return false
		raider = list[0]
		return true)
	_check(spawned and _salon.active_raiders() <= SalonZone.RAIDERS_AT_ONCE, "pilleurs : au plus deux à la fois")
	# Un pilleur atteint Nathan : il a peur, lâche la règle, puis revient la tenir.
	var reached := await _wait_until(30.0, func() -> bool: return _nathan.state == Nathan.State.SCARED)
	_check(reached and not _salon.seesaw.held, "un cafard atteint Nathan : il prend peur et lâche la règle (sans dégât)")
	# Sans nouveau cafard pendant un moment (Nin0 a fait le ménage) : il revient.
	_salon._spawn_timer = 999.0
	for node in get_tree().get_nodes_in_group(&"salon_raiders"):
		node.queue_free()
	var back := await _wait_until(30.0, func() -> bool: return _nathan.is_holding())
	_salon._spawn_timer = 0.5
	_check(back, "Nathan revient tenir la règle")
	# Nin0 tire : deux billes (ou une pointue) par cafard.
	_game.cannon.select_ammo(&"bead")
	var won := await _wait_until(60.0, func() -> bool:
		for node in get_tree().get_nodes_in_group(&"salon_raiders"):
			var r := node as SalonRaider
			if r.is_active() and Engine.get_physics_frames() % 20 == 0:
				_game.cannon._impact(r.global_position, Vector3.UP, r.hit_body, _game.cannon.ammo)
		return GameState.protection_done)
	_check(won and _salon.raiders_down >= SalonZone.RAIDERS_NEEDED, "protection réussie : trois cafards mis KO")
	_check(_salon.box_focus.enabled and _objective() == "Analyser la box internet", "la box devient observable ; objectif : l'analyser")


func _test_box() -> void:
	var box := _salon.box_focus
	_check(box.memory != null and box.memory.id == &"memory_05" and box.memory.presentation == &"wifi", "box internet : souvenir n° 5 (scan obligatoire)")
	_check(not GameState.has_memory(&"memory_05"), "pas d'archive avant le scan")
	_place(Vector3(-12.6, 5.05, 35.5), 0.0)
	await _wait(0.6)
	_director.focus_vision.target_identified.emit(box)
	var searching := await _wait_until(4.0, func() -> bool: return _game.get_children().any(func(c: Node) -> bool: return c is WifiSearch))
	_check(searching and GameState.hazards_suspended(), "connexion au réseau : interface de recherche fictive, dangers suspendus")
	var search: WifiSearch
	for c in _game.get_children():
		if c is WifiSearch:
			search = c
	var shown := await _wait_until(10.0, func() -> bool: return search != null and is_instance_valid(search) and search._page.visible)
	_check(shown and search._field.text.contains("Nin0") and search._field.text.contains("compagnon"), "fiche produit fictive : « Nin0 — compagnon robotique », robots identiques")
	var done := await _wait_until(20.0, func() -> bool: return GameState.has_memory(&"memory_05") and _nino.controls_enabled)
	_check(done and not box.enabled, "archive 05/07 après le scan ; la box ne redéclenche rien")
	var memory := GameState.ARCHIVE.get_entry(&"memory_05")
	var text := " ".join(memory.lines) + " " + memory.comment
	_check(text.contains("modèle") and text.contains("pourquoi"), "Nin0 comprend qu'il est un modèle commercial, pas pourquoi il est ici")
	for word in ["enfant", "fils", "père", "homme", "papa"]:
		if text.to_lower().contains(word):
			_check(false, "aucune révélation : « %s » trouvé" % word)
	_check(true, "aucune information sur les habitants (pas de révélation)")
	_check(GameState.ARCHIVE.entries.size() == 5 and GameState.ARCHIVE.total == 7, "archives : 5 souvenirs définis sur 7 (6 et 7 à définir)")
	_check(_objective() == "Explorer le salon", "objectif : explorer le salon (suite à venir)")


func _test_trophies() -> void:
	GameState.dev_mode = false
	Achievements.evaluate(true)
	for id in [&"cannon", &"queen", &"kitchen", &"charged_jump", &"great_wasp", &"sting_bead", &"salon", &"seesaw"]:
		if not Achievements.is_unlocked(id):
			_check(false, "trophée attendu : " + String(id))
	_check(true, "trophées de progression et de coopération débloqués d'après la partie")
	var announced := [0]
	var on_unlock := func(_id: StringName) -> void: announced[0] += 1
	Achievements.unlocked.connect(on_unlock)
	_check(Achievements.unlock(&"bonk") and not Achievements.unlock(&"bonk") and announced[0] == 1, "un trophée ne se débloque qu'une fois (annonce unique)")
	Achievements.unlocked.disconnect(on_unlock)
	_check(not Achievements.is_unlocked(&"seven_memories"), "sept souvenirs : non débloqué (5 / 7)")
	_check(FileAccess.file_exists(Achievements.TEST_SAVE_PATH), "trophées sauvegardés à part (fichier de test)")
	Achievements.load_file()
	_check(Achievements.is_unlocked(&"seesaw") and Achievements.is_unlocked(&"bonk"), "trophées relus depuis le fichier")
	_game.inventory.refresh()
	var labels := Array(_texts(_game.inventory))
	_check(labels.any(func(l: String) -> bool: return l.begins_with("Trophées :")) and labels.has("Trophée secret") and labels.has("À deux, c'est mieux"),
			"inventaire : onglet Trophées (secrets masqués)")
	var ids := Achievements.LIST.keys()
	_check(ids.size() >= 15 and ids.has(&"all_species") and ids.has(&"all_upgrades") and ids.has(&"seven_memories"), "liste stable : progression, découverte, coopération, secrets (%d)" % ids.size())
	GameState.dev_mode = true


func _test_saves() -> void:
	GameState.dev_mode = false
	GameState.resume_point = &"salon"
	GameState.save()
	GameState.reset_progress()
	GameState.load_save()
	_check(GameState.salon_entered and GameState.seesaw_done and GameState.protection_done and GameState.has_memory(&"memory_04") and GameState.has_memory(&"memory_05"),
			"sauvegarde : étapes du salon et souvenirs 4 et 5")
	_check((_game._resume_transform() as Transform3D).origin.distance_to(_salon.marker("SalonEntry").origin) < 0.1, "reprise dans le salon")
	var config := ConfigFile.new()
	config.load(GameState.save_path)
	for key in ["seesaw_done", "protection_done"]:
		config.erase_section_key("progress", key)
	config.save(GameState.save_path)
	GameState.load_save()
	_check(not GameState.seesaw_done and not GameState.protection_done, "ancienne sauvegarde : lisible, valeurs par défaut")
	GameState.dev_mode = true


# --- Utilitaires ------------------------------------------------------------------------------

func _objective() -> String:
	GameState.dev_mode = false
	var text := GameState.get_objective()
	GameState.dev_mode = true
	return text


func _texts(root: Node) -> PackedStringArray:
	var list := PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		list.append((node as Label).text)
	return list


func _place(position: Vector3, yaw_degrees: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = deg_to_rad(yaw_degrees)
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = deg_to_rad(yaw_degrees)
	_camera.snap_to_target()


func _hold(seconds: float) -> void:
	await _hold_until(seconds, func() -> bool: return false)


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
