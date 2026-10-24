extends Node
## Test de la cuisine (lot 6), sans affichage :
##   godot --headless --fixed-fps 60 --path . res://tests/test_kitchen.tscn
## Joue dans la scène de développement (aucune sauvegarde personnelle touchée) :
## navigation, salon fermé, collisions des meubles, routes verticales (vraie physique),
## araignées, cafards, affrontements sans Nin0 (dont l'arrière-plan simplifié),
## canon, ressources, encyclopédie, découvertes et sauvegardes.

const APARTMENT := preload("res://scenes/levels/apartment.tscn")

var _failures := 0
var _dev: Node3D
var _game: GameWorld
var _kitchen: KitchenZone
var _nino: NinoController
var _camera: ThirdPersonCamera
var _director: Node3D
var _personal_existed := false
var _personal := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	seed(6)
	_personal_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_existed else ""
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	_dev = APARTMENT.instantiate()
	add_child(_dev)
	_game = _dev.game
	_kitchen = _game.kitchen
	_nino = _dev.nino
	_camera = _dev.camera
	_director = _dev.workshop
	await _wait(1.5)
	_game.run_dev_scenario(&"kitchen_inside")
	await _wait(1.0)

	await _test_layout()
	await _test_collisions()
	await _test_routes()
	await _test_roaches()
	await _test_spiders()
	await _test_ecosystem()
	await _test_cannon()
	await _test_resources()
	await _test_saves()

	Sfx.stop_all_loops()
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- Lieu ---------------------------------------------------------------------------------

func _test_layout() -> void:
	_check(_game.zone_at(_nino.global_position) == GameWorld.ZONE_KITCHEN, "scénario : Nin0 dans la cuisine")
	await _wait(1.5)
	_check(Music.desired == &"kitchen" and Music.current == &"kitchen" and Music.audible_count() <= 1, "musique « kitchen - Nin0 » seule audible")
	_check(Music.TRACKS[&"kitchen"].loop and not Music.has_track(&"living_room"), "musique de la cuisine en boucle ; salon non intégré")
	var track: Dictionary = Music.TRACKS[&"kitchen"]
	var length := (load(track.path) as AudioStream).get_length()
	_check(track.loop_offset > 20.0 and length - track.loop_offset > 45.0 and length < 80.0,
			"boucle de la cuisine : reprise après l'intro (%.2f s), fin coupée avant le fondu (%.2f s)" % [track.loop_offset, length])
	_check(_objective() == "Explorer la cuisine", "objectif : explorer la cuisine")
	var volumes := _game.blockout.get_node("Volumes")
	_check(["KitchenCounter", "KitchenUpper", "KitchenFridge", "KitchenTable"].all(func(n: String) -> bool: return volumes.get_node_or_null(n) == null),
			"volumes provisoires de la cuisine retirés du blockout")
	_check(_game.blockout.get_node_or_null("Lights/Light_cuisine") == null and _kitchen.get_node_or_null("WindowSun") is SpotLight3D, "éclairage propre : lumière de la fenêtre")
	# Salon toujours fermé (porte du mur est, côté cuisine).
	_check(not await _drive(Vector3(-50.0, 0.05, 31.5), -90.0, 6, 3.0), "cuisine → salon : toujours fermé")
	_kitchen.salon_door_examined.emit()
	await _wait(0.3)
	_check(_game._shown.has(&"salon_door"), "porte du salon examinable depuis la cuisine")
	# Retour vers le sas : on contourne le battant entrouvert par son extrémité libre.
	_check(_clear_line(Vector3(-50.0, 0.0, 1.6), Vector3(-46.3, 0.0, 1.6)) and _clear_line(Vector3(-46.3, 0.0, 1.6), Vector3(-46.3, 0.0, 4.4)),
			"le battant entrouvert se contourne côté cuisine")
	_check(await _drive(Vector3(-46.3, 0.05, 4.4), -90.0, 2, 6.0), "retour au sas par la porte entrouverte")
	_check(await _drive(Vector3(-40.0, 0.05, 4.0), 90.0, 4, 6.0), "et retour dans la cuisine")
	await _wait(0.6)
	_check(GameState.resume_point == &"kitchen" and _game._resume_transform() is Transform3D \
			and (_game._resume_transform() as Transform3D).origin.distance_to(_kitchen.marker("KitchenEntry").origin) < 0.1, "point de reprise : entrée de la cuisine")


func _test_collisions() -> void:
	# Meubles pleins (Nin0 ne les traverse pas), dessous des meubles bas ouvert.
	var solids := {
		"réfrigérateur": Vector3(-49.6, 9.0, 53.6), "caisson ouest": Vector3(-72.0, 5.0, 24.0), "caisson sud": Vector3(-68.0, 5.0, 54.0),
		"plan de travail": Vector3(-70.0, 8.8, 45.0), "poubelle": Vector3(-49.0, 3.0, 15.0), "micro-ondes": Vector3(-72.5, 10.6, 54.4),
		"placards hauts": Vector3(-68.0, 17.0, 55.0), "fond de l'évier": Vector3(-72.0, 6.9, 31.0), "pile de cartons": Vector3(-72.4, 2.0, 18.1),
		"étagère": Vector3(-73.3, 14.85, 48.0), "cafetière": Vector3(-67.1, 11.0, 54.9),
	}
	var missing := solids.keys().filter(func(k: String) -> bool: return not _solid_at(solids[k]))
	_check(missing.is_empty(), "collisions des meubles et appareils %s" % ("" if missing.is_empty() else str(missing)))
	_check(_clear_line(Vector3(-72.0, 0.0, 21.0), Vector3(-72.0, 0.0, 50.0)) and _clear_line(Vector3(-73.0, 0.0, 54.0), Vector3(-54.0, 0.0, 54.0)),
			"dessous des meubles bas praticable (passage des cafards et de Nin0)")
	_check(_clear_line(Vector3(-72.0, 1.25, 29.0), Vector3(-72.0, 1.25, 37.0), 0.5), "intérieur du meuble sous l'évier praticable")
	# Nin0 bute contre le réfrigérateur au lieu de le traverser.
	_nino.force_mode(NinoController.Mode.WHEELS)
	_place(Vector3(-49.6, 0.05, 47.5), 180.0)
	await _hold_until(2.5, func() -> bool: return false)
	_check(_nino.global_position.z < 50.4, "Nin0 bute contre le réfrigérateur")
	# Interstice derrière le réfrigérateur : visible mais fermé.
	_check(_solid_at(Vector3(-46.1, 1.0, 50.15)) and _solid_at(Vector3(-46.1, 18.15, 53.6)), "interstice du réfrigérateur inaccessible (sol et dessus)")


func _test_routes() -> void:
	_nino.force_mode(NinoController.Mode.WHEELS)
	# Sol → plan de travail : torchon pendu (escalade).
	var towel := await _climb(Vector3(-64.6, 0.05, 49.9), 180.0, 9.0)
	_check(towel, "torchon : du sol au plan de travail (escalade)")
	# Sol → cartons (4,6) → plan de travail (9,0).
	var low := await _climb(Vector3(-71.6, 0.05, 15.5), 180.0, 4.6)
	var high := low and await _climb(Vector3(-72.6, 4.65, 16.4), 180.0, 9.0)
	_check(low and high, "pile de cartons : deux escalades jusqu'au plan de travail")
	_nino.global_position.z = 21.0
	await _wait(0.4)
	_check(_nino.is_on_floor() and absf(_nino.global_position.y - 9.0) < 0.15, "les cartons rejoignent le plan de travail")
	# Plan de travail → céréales (14) → calendrier → dessus du réfrigérateur (18).
	var cereal := await _climb(Vector3(-55.0, 9.05, 52.0), -90.0, 14.0)
	var fridge := cereal and await _climb(Vector3(-53.2, 14.05, 52.0), -90.0, 18.0)
	_check(cereal and fridge, "céréales puis calendrier aimanté : dessus du réfrigérateur")
	# Plan de travail → étagère (15) → casier à épices → dessus des placards (21).
	var shelf := await _climb(Vector3(-73.4, 9.05, 43.4), 180.0, 15.0)
	var rack := shelf and await _climb(Vector3(-72.4, 15.05, 47.6), 90.0, 21.0)
	_check(shelf and rack, "étagère puis casier à épices : dessus des placards hauts")
	_nino.global_position = Vector3(-74.0, 21.1, 54.5)
	await _wait(0.5)
	_check(_nino.is_on_floor() and absf(_nino.global_position.y - 21.0) < 0.15, "le casier rejoint le dessus des placards")
	# Le dessus est coupé par la hotte : le haut du placard est (arrière-plan) reste hors d'atteinte.
	_check(not _solid_at(Vector3(-59.0, 20.9, 54.2)) and _solid_at(Vector3(-59.0, 21.0, 56.0)), "la hotte coupe le dessus des placards (partie est inaccessible)")
	# Plan de travail → pot de basilic → rebord de la fenêtre (saut, jambes).
	_nino.force_mode(NinoController.Mode.LEGS)
	await _wait(0.6)
	var pot := await _hop(Vector3(-72.2, 9.05, 38.7), Vector3(-73.0, 9.6, 38.7))
	var sill := pot and await _hop(Vector3(-73.2, 9.65, 38.6), Vector3(-74.4, 10.2, 38.2))
	_check(pot and sill, "pot de basilic puis rebord de la fenêtre (sauts)")
	# Bac de l'évier : on en ressort par l'éponge.
	var sponge := await _hop(Vector3(-70.95, 7.05, 32.6), Vector3(-70.95, 7.55, 31.6))
	var soap := sponge and await _hop(Vector3(-70.95, 7.6, 31.6), Vector3(-70.95, 8.1, 30.45))
	var brush := soap and await _hop(Vector3(-70.95, 8.15, 30.45), Vector3(-70.95, 8.6, 29.3))
	var out := brush and await _hop(Vector3(-70.95, 8.65, 29.1), Vector3(-70.95, 9.0, 27.4))
	_check(sponge and soap and brush and out, "bac de l'évier : on en ressort (éponge, flacon, brosse)")
	# Meuble sous l'évier : marche puis porte entrouverte.
	var step := await _hop(Vector3(-67.6, 0.05, 34.4), Vector3(-68.4, 0.65, 34.4))
	var inside := step and await _hop(Vector3(-68.7, 0.7, 34.4), Vector3(-69.8, 1.2, 34.4))
	_check(step and inside, "meuble sous l'évier : passage secondaire (porte entrouverte)")
	_nino.force_mode(NinoController.Mode.WHEELS)
	await _wait(0.6)


# --- Cafards ------------------------------------------------------------------------------

func _test_roaches() -> void:
	var roaches := _kitchen.get_roaches()
	_check(roaches.size() >= 8, "cafards présents (%d)" % roaches.size())
	_place(Vector3(-49.0, 0.05, 6.5), 90.0)
	var roach := _kitchen.get_node("Creatures/RoachFloor0") as KitchenRoach
	var start := roach.global_position
	await _wait(6.0)
	_check(roach.global_position.distance_to(start) > 0.5 or roach.state == KitchenRoach.State.FORAGE, "un cafard explore ou fouille seul")
	# Fuite devant Nin0 vers une cachette.
	roach._set_state(KitchenRoach.State.WANDER)
	roach.global_position = Vector3(-62.0, 0.0, 30.0)
	_place(Vector3(-62.0, 0.05, 31.0), 0.0)
	var fled := await _wait_until(1.5, func() -> bool: return roach.state == KitchenRoach.State.FLEE)
	_check(fled, "le cafard fuit Nin0")
	var hidden := await _wait_until(8.0, func() -> bool: return roach.state == KitchenRoach.State.HIDE)
	_check(hidden and roach.flat_distance(_nino.global_position) > 1.5, "…jusqu'à une cachette, à distance")
	_check(Array(roach.hides).any(func(h: Vector3) -> bool: return h.distance_to(roach.global_position) < 0.1), "la cachette est un abri prévu (dessous de meuble, carton…)")
	var resumed := await _wait_until(10.0, func() -> bool: return roach.state in [KitchenRoach.State.WANDER, KitchenRoach.State.FORAGE])
	_check(resumed, "puis il reprend ses habitudes")
	# Acculé, il se défend (cabrage, petite morsure) puis s'échappe.
	_place(Vector3(-49.0, 0.05, 6.5), 90.0)
	var nest := _kitchen.get_node("Creatures/RoachNest") as KitchenRoach
	var saved_hides := nest.hides
	nest.hides = PackedVector3Array()
	nest._set_state(KitchenRoach.State.WANDER)
	nest.alarm(_nino)
	_check(nest.state == KitchenRoach.State.DEFEND and nest._emote.text == "!", "acculé, le cafard se dresse (défense annoncée)")
	_nino.global_position = nest.global_position + Vector3(0.3, 0.05, 0.0)
	var before := GameState.integrity + GameState.shield
	await _wait(1.3)
	var lost := before - (GameState.integrity + GameState.shield)
	_check(lost > 0.0 and lost <= nest.nip_damage + 0.01, "petite morsure défensive (%.0f)" % lost)
	nest.hides = saved_hides
	_place(Vector3(-49.0, 0.05, 6.5), 90.0)
	await _wait(1.6)


# --- Araignées ----------------------------------------------------------------------------

func _test_spiders() -> void:
	var spiders := _kitchen.get_spiders()
	_check(spiders.size() >= 5 and spiders.filter(func(s: KitchenSpider) -> bool: return s.background).size() >= 3, "araignées : repaires accessibles et d'arrière-plan")
	var spider := _kitchen.get_node("Creatures/SpiderUnder") as KitchenSpider
	# Territoriale : elle surveille, avertit, puis attaque si Nin0 s'attarde.
	for s in spiders:
		s._calm = 0.0
	spider.global_position = spider.home
	spider.prey = null
	spider._set_state(KitchenSpider.State.LURK)
	_nino.force_mode(NinoController.Mode.WHEELS)
	_place(spider.home + Vector3(1.6, 0.05, -0.8), 90.0)
	var watch := await _wait_until(2.0, func() -> bool: return spider.state == KitchenSpider.State.WATCH)
	_check(watch, "l'araignée repère Nin0 près de son repaire et l'observe")
	_check(_game._shown.has(&"spider_alert"), "Nin0 comprend : son territoire")
	var hp := GameState.integrity + GameState.shield
	var windup := await _wait_until(6.0, func() -> bool: return spider.state == KitchenSpider.State.WINDUP)
	_check(windup and spider._emote.text == "!" and GameState.integrity + GameState.shield >= hp - 0.01, "elle se ramasse avant de bondir (attaque annoncée, pas encore de dégâts)")
	var bitten := await _wait_until(3.0, func() -> bool: return GameState.integrity + GameState.shield < hp)
	_check(bitten, "morsure si Nin0 reste à portée")
	_check(GameState.in_combat, "combat signalé (araignée engagée)")
	# Nin0 quitte le territoire : elle regagne son repaire.
	_place(Vector3(-60.0, 0.05, 40.0), 0.0)
	var home := await _wait_until(14.0, func() -> bool: return spider.state == KitchenSpider.State.LURK and spider.global_position.distance_to(spider.home) < 0.2)
	_check(home and not spider.is_engaged(), "Nin0 parti : elle retourne à son repaire")
	# Séquence non interactive : morsure annulée.
	spider._calm = 0.0
	spider.prey = _nino
	_place(spider.home + Vector3(0.9, 0.05, -0.4), 90.0)
	spider._set_state(KitchenSpider.State.WINDUP)
	GameState.suspend_hazards(&"test")
	hp = GameState.integrity + GameState.shield
	await _wait(1.5)
	_check(spider.state != KitchenSpider.State.POUNCE and GameState.integrity + GameState.shield >= hp - 0.01, "séquence non interactive : l'araignée se fige, aucune morsure")
	GameState.resume_hazards(&"test")
	_place(Vector3(-60.0, 0.05, 40.0), 0.0)
	await _wait(0.5)
	# Billes : trois touches la font battre en retraite (et elle laisse Nin0 tranquille).
	var marker := Node3D.new()
	add_child(marker)
	marker.global_position = spider.global_position + Vector3(1.0, 0.1, 0.0)
	for i in 3:
		spider.on_projectile_hit(marker)
	marker.queue_free()
	_check(spider.state == KitchenSpider.State.RETREAT, "trois billes : retraite vers le repaire")
	# Le corps de tir est sur la couche des cibles du canon, sans bloquer Nin0.
	_check(spider.hit_body.collision_layer == 32 and (spider.hit_body.collision_layer & 1) == 0, "araignée : cible des billes, jamais un obstacle")
	# Embuscade : l'araignée du repaire descend au bout de son fil sur le plan de travail.
	var lair := _kitchen.get_node("Creatures/SpiderLair") as KitchenSpider
	lair._calm = 0.0
	lair.global_position = lair.home
	lair._set_state(KitchenSpider.State.LURK)
	var bait := _kitchen.get_node("Creatures/RoachCounter1") as KitchenRoach
	for r in [bait, _kitchen.get_node("Creatures/RoachCounter0")]:
		r.wariness = 0.0
		r.spider_alert = 0.0
	lair._rest = 0.0
	bait.global_position = Vector3(-62.5, 9.0, 52.4)
	bait._set_state(KitchenRoach.State.FORAGE)
	bait._timer = 30.0
	var threads := [false]
	var watch_thread := func() -> void:
		if lair._thread.visible:
			threads[0] = true
	get_tree().physics_frame.connect(watch_thread)
	var caught := await _wait_until(30.0, func() -> bool: return lair.state == KitchenSpider.State.FEED)
	get_tree().physics_frame.disconnect(watch_thread)
	_check(caught and threads[0], "embuscade : descente au fil, bond, capture du cafard")
	var victim := lair.prey as KitchenRoach
	if victim:
		bait = victim
	_check(not bait.visible and get_tree().get_nodes_in_group(&"kitchen_cocoons").size() >= 1, "la proie devient un cocon")
	# Pendant qu'elle emballe sa proie, elle ignore Nin0 (occasion de passer).
	_place(lair.global_position + Vector3(0.8, 0.05, -0.6), 0.0)
	await _wait(1.0)
	_check(lair.state == KitchenSpider.State.FEED, "occupée à emballer : elle ignore Nin0")
	_place(Vector3(-60.0, 0.05, 40.0), 0.0)
	var back := await _wait_until(40.0, func() -> bool: return lair.state == KitchenSpider.State.LURK and lair.cocoons.size() >= 1)
	_check(back and lair.cocoons[-1].global_position.y > 20.0, "le cocon est emporté et suspendu au repaire")
	bait.respawn_time = 1.0
	bait._timer = minf(bait._timer, 1.0)
	_place(Vector3(-49.0, 0.05, 6.5), 90.0)
	var respawned := await _wait_until(4.0, func() -> bool: return bait.visible and bait.state != KitchenRoach.State.CAUGHT)
	_check(respawned and bait.hides.has(bait.global_position), "un autre cafard réapparaît plus tard dans une cachette")
	for r in _kitchen.get_roaches():
		r.wariness = 1.0
		r.spider_alert = 2.6


# --- Écosystème autonome ------------------------------------------------------------------

func _test_ecosystem() -> void:
	# Nin0 loin, immobile : les affrontements continuent sans lui.
	_place(_kitchen.marker("KitchenEntry").origin, 90.0)
	await _wait(0.5)
	var stats0 := _kitchen.stats.duplicate()
	var bg := _kitchen.get_node("Creatures/BgSpiderFridge") as KitchenSpider
	var far := bg.lod_interval > 1 and not bg.body.is_processing()
	var t0 := Time.get_ticks_usec()
	var frames := [0]
	var measure := func() -> void: frames[0] += 1
	get_tree().physics_frame.connect(measure)
	await _wait(80.0)
	get_tree().physics_frame.disconnect(measure)
	var hunts := int(_kitchen.stats[&"hunts"]) - int(stats0[&"hunts"])
	var outcomes := int(_kitchen.stats[&"catches"]) + int(_kitchen.stats[&"fails"]) + int(_kitchen.stats[&"flees"]) \
			- int(stats0[&"catches"]) - int(stats0[&"fails"]) - int(stats0[&"flees"])
	_check(hunts >= 3 and outcomes >= 3, "affrontements autonomes sans Nin0 (%d chasses, %d issues : %s)" % [hunts, outcomes, str(_kitchen.stats)])
	_check(far, "au loin : comportement mis à jour moins souvent, animation arrêtée (arrière-plan simplifié)")
	var bg_hunts := [0]
	for name in ["BgSpiderFridge", "BgSpiderCabinet", "BgSpiderMicrowave"]:
		var s := _kitchen.get_node("Creatures/" + name) as KitchenSpider
		bg_hunts[0] += 1 if s.cocoons.size() > 0 or s.state != KitchenSpider.State.LURK else 0
	_check(bg_hunts[0] >= 1, "arrière-plan (derrière le frigo, dessus des placards, micro-ondes) vivant")
	_check(Array(_kitchen.get_roaches()).all(func(r: KitchenRoach) -> bool: return r.in_territory(r.global_position, 0.3, 0.3) or not r.visible),
			"chaque cafard reste dans son territoire")
	_check(Array(_kitchen.get_spiders()).all(func(s: KitchenSpider) -> bool: return s.global_position.distance_to(s.home) < 40.0), "chaque araignée reste près de son repaire")
	# Coût : temps de jeu simulé pour 80 s (indicatif, sans rendu).
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / maxf(frames[0], 1)
	_check(ms < 40.0, "coût moyen d'une image avec l'écosystème complet : %.2f ms" % ms)


# --- Canon, ressources, encyclopédie, sauvegardes -----------------------------------------

func _test_cannon() -> void:
	var roach := _kitchen.get_node("Creatures/RoachFloor2") as KitchenRoach
	roach._set_state(KitchenRoach.State.WANDER)
	roach.global_position = Vector3(-60.0, 0.0, 30.0)
	_place(Vector3(-60.0, 0.05, 25.0), 180.0)
	await _wait(0.4)
	var space := _nino.get_world_3d().direct_space_state
	var from := _nino.global_position + Vector3.UP * 0.3
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, roach.global_position + Vector3.UP * 0.06, NinoCannon.HIT_MASK, [_nino.get_rid()]))
	_check(not hit.is_empty() and hit.collider == roach.hit_body, "le cafard est une cible pour les billes")
	GameState.ammo_plastic = maxi(GameState.ammo_plastic, 4)
	var ammo := GameState.ammo_plastic
	_game.cannon._cooldown = 0.0
	_camera.rotation.y = PI
	_camera.pitch = deg_to_rad(-4.0)
	await _wait(0.2)
	_game.cannon._impact(roach.global_position, Vector3.UP, roach.hit_body)
	_check(roach.state == KitchenRoach.State.FLEE, "touché par une bille, le cafard détale")
	_check(_game.cannon.fire() and GameState.ammo_plastic == ammo - 1, "le canon tire dans la cuisine (munitions consommées)")
	await _wait(1.0)


func _test_resources() -> void:
	var pickup: ResourcePickup = _kitchen.get_node("Pickups/PlasticCounter")
	GameState.playtime += 1000.0
	pickup.refresh()
	var ammo := GameState.ammo_plastic
	_place(pickup.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	await _wait(0.5)
	_check(GameState.ammo_plastic == mini(ammo + pickup.amount, GameState.PLASTIC_MAX) and not pickup.visible, "plastique ramassé sur la plaque de cuisson")
	var fil: ResourcePickup = _kitchen.get_node("Pickups/FilamentFridgeTop")
	var fragments := GameState.fragments
	_place(fil.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	await _wait(0.5)
	_check(GameState.fragments == fragments + fil.amount and fil.respawn_delay == 0.0, "récompense unique sur le réfrigérateur (filament)")
	var all: Array = _kitchen.get_node("Pickups").get_children()
	_check(all.size() >= 10 and all.any(func(p: Node) -> bool: return (p as ResourcePickup).kind == ResourcePickup.Kind.PLASTIC and p.global_position.y > 20.0),
			"ressources réparties sur tous les niveaux (%d)" % all.size())
	# Encyclopédie : araignée et cafard analysables, sans plan inventé.
	_place(_kitchen.marker("KitchenEntry").origin, 90.0)
	await _wait(0.3)
	for id in [&"spider", &"roach"]:
		var creature: KitchenCreature = (_kitchen.get_spiders()[0] if id == &"spider" else _kitchen.get_roaches()[0])
		_director.focus_vision.target_identified.emit(creature.focus)
		await _wait(0.6)
		_check(GameState.has_species(id) and _game.species_card.showing, "fiche « ESPÈCE IDENTIFIÉE » : %s" % SpeciesCatalog.find(id).display_name)
		_check(SpeciesCatalog.find(id).unlocks_plan == &"" and not _game.blueprint._open, "%s : aucun plan ni amélioration inventés" % id)
		_game.species_card.hide_card()
		await _wait(0.3)
	_check(_kitchen.get_spiders().all(func(s: KitchenSpider) -> bool: return s.focus.is_identified), "les autres araignées sont reconnues")
	# Inventaire : bestiaire.
	_game.inventory.open()
	await _wait(0.3)
	var texts := "\n".join(_texts(_game.inventory))
	_game.inventory.close()
	await _wait(0.2)
	_check(texts.contains("Araignée domestique") or GameState.species.has(&"spider"), "inventaire : l'araignée rejoint l'encyclopédie")
	# Traces du lieu (découvertes).
	var spot := _kitchen.get_node("Discoveries/WebLairSpot") as Examinable
	spot.interacted.emit(_nino)
	await _wait(0.4)
	_check(GameState.has_discovery(&"kitchen_web_lair") and spot.prompt == "Revoir", "toile habitée : découverte enregistrée")
	var lore := _kitchen.get_node("Discoveries").get_children()
	_check(lore.size() >= 6, "traces du lieu : toiles, cachettes, restes, végétation (%d)" % lore.size())


func _test_saves() -> void:
	GameState.dev_mode = false
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.resume_point = &"kitchen"
	GameState.save()
	var snapshot := {"species": GameState.species.duplicate(), "discoveries": GameState.discoveries.duplicate(), "ammo": GameState.ammo_plastic, "pickups": GameState.collected_pickups.duplicate()}
	GameState.reset_progress()
	GameState.load_save()
	_check(GameState.species == snapshot.species and GameState.species.has(&"spider") and GameState.species.has(&"roach"), "sauvegarde : espèces de la cuisine")
	_check(GameState.discoveries == snapshot.discoveries and GameState.has_discovery(&"kitchen_web_lair"), "sauvegarde : découvertes de la cuisine")
	_check(GameState.collected_pickups == snapshot.pickups and GameState.ammo_plastic == snapshot.ammo, "sauvegarde : ressources ramassées")
	_check(GameState.chapter2_completed and GameState.resume_point == &"kitchen" and (_game._resume_transform() as Transform3D).origin.distance_to(_kitchen.marker("KitchenEntry").origin) < 0.1,
			"reprise dans la cuisine")
	GameState.erase_save()
	GameState.save_path = GameState.SAVE_PATH
	GameState.dev_mode = true
	var now := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_existed and now == _personal, "la sauvegarde personnelle n'a pas été touchée")


# --- Outils -------------------------------------------------------------------------------

## Escalade réelle : Nin0 avance vers une paroi escaladable, monte et se hisse.
func _climb(from: Vector3, yaw_degrees: float, top: float, timeout := 16.0) -> bool:
	if _nino.state == NinoController.State.CLIMBING:
		_nino._release_wall(false)
	_place(from, yaw_degrees)
	await _wait(0.3)
	var done := await _hold_until(timeout, func() -> bool: return _nino.is_on_floor() and _nino.global_position.y > top - 0.12 and _nino.state == NinoController.State.FREE)
	await _wait(0.3)
	return done and absf(_nino.global_position.y - top) < 0.15


## Une boîte de la taille de Nin0 passe-t-elle le long du segment (au ras du sol) ?
func _clear_line(a: Vector3, b: Vector3, height := 0.7) -> bool:
	var space := _nino.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.4, height - 0.1, 0.4)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for k in 41:
		query.transform = Transform3D(Basis.IDENTITY, a.lerp(b, k / 40.0) + Vector3.UP * (0.05 + height * 0.5))
		if not space.intersect_shape(query, 1).is_empty():
			return false
	return true


func _solid_at(point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	return not _nino.get_world_3d().direct_space_state.intersect_point(query, 1).is_empty()


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


## Objectif affiché hors mode développement.
func _objective() -> String:
	GameState.dev_mode = false
	var text := GameState.get_objective()
	GameState.dev_mode = true
	return text


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


func _texts(root: Node) -> PackedStringArray:
	var list := PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		list.append((node as Label).text)
	return list


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
