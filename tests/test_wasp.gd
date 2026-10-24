extends Node
## Test du combat des guêpes, des billes pointues et de la porte du salon (lot 7B),
## sans affichage :
##   godot --headless --fixed-fps 60 --path . res://tests/test_wasp.tscn
## Joue dans la scène de développement (aucune sauvegarde personnelle touchée).

const APARTMENT := preload("res://scenes/levels/apartment.tscn")
const ARENA_SPOT := Vector3(-70.8, 9.05, 40.0)

var _failures := 0
var _dev: Node3D
var _game: GameWorld
var _kitchen: KitchenZone
var _arena: WaspArena
var _nino: NinoController
var _camera: ThirdPersonCamera
var _personal_existed := false
var _personal := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	seed(7)
	_personal_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	_personal = FileAccess.get_file_as_string(GameState.SAVE_PATH) if _personal_existed else ""
	GameState.save_path = GameState.TEST_SAVE_PATH
	GameState.erase_save()
	_dev = APARTMENT.instantiate()
	add_child(_dev)
	_game = _dev.game
	_kitchen = _game.kitchen
	_arena = _kitchen.wasp_arena
	_nino = _dev.nino
	_camera = _dev.camera
	await _wait(1.5)
	_game.run_dev_scenario(&"wasps")
	await _wait(1.0)

	await _test_setup()
	await _test_intro()
	await _test_phase1()
	await _test_pause()
	await _test_phase1_retry()
	await _test_transition()
	await _test_phase2_retry()
	await _test_phase2_patterns()
	await _test_victory()
	await _test_sting_ammo()
	await _test_salon_door()
	await _test_saves()

	Sfx.stop_all_loops()
	GameState.erase_save()
	GameState.save_path = GameState.SAVE_PATH
	_check(FileAccess.file_exists(GameState.SAVE_PATH) == _personal_existed and
			(not _personal_existed or FileAccess.get_file_as_string(GameState.SAVE_PATH) == _personal),
			"sauvegarde personnelle intacte")
	print("\n%s : %d échec(s)" % ["SUCCÈS" if _failures == 0 else "ÉCHEC", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- Avant le combat ----------------------------------------------------------------------

func _test_setup() -> void:
	_check(_arena.phase == WaspArena.Phase.IDLE and not _arena.great.visible, "arène au repos : aucune guêpe visible avant d'arriver près de la fenêtre")
	_check(_objective() == "Explorer les hauteurs de la cuisine", "objectif avant le combat : explorer les hauteurs")
	var pickups := _kitchen.get_node("Pickups").get_children().filter(func(p: Node) -> bool:
		return String(p.name).begins_with("PlasticArena"))
	_check(pickups.size() == 3 and pickups.all(func(p: ResourcePickup) -> bool: return p.respawn_delay <= 60.0 and p.global_position.y > 8.9),
			"réserves de plastique autour de l'arène, réapparition rapide (%d)" % pickups.size())
	_check(SpeciesCatalog.find(&"wasp") != null and UpgradeCatalog.find(&"sting_bead") != null, "guêpe dans l'encyclopédie, billes pointues dans le catalogue")
	# Le plan de travail n'est accessible qu'avec le saut chargé : vérifié par test_kitchen.
	_check(ARENA_SPOT.y > 9.0 and _arena.TRIGGER_MIN.y > 8.0, "arène en hauteur (plan de travail, 9 u)")


func _test_intro() -> void:
	_place(ARENA_SPOT, 0.0)
	var engaged := await _wait_until(3.0, func() -> bool: return _game.cine.is_active())
	_check(engaged and not _nino.controls_enabled and GameState.hazards_suspended(), "intro : caméra de mise en scène, contrôle retiré, dangers suspendus")
	_check(GameState.wasp_started and not _kitchen.get_node("Creatures/SpiderWindow").visible, "rencontre enregistrée ; l'araignée de la fenêtre s'est terrée")
	var hp := GameState.integrity + GameState.shield
	var done := await _wait_until(20.0, func() -> bool: return _arena.phase == WaspArena.Phase.PHASE1 and _nino.controls_enabled)
	_check(done and not _game.cine.is_active(), "fin de l'intro : contrôle rendu, phase 1")
	_check(GameState.integrity + GameState.shield >= hp - 0.01, "aucun dégât pendant l'intro")
	_check(_arena.alive_minions() == 2 and _arena.great.global_position.distance_to(_arena.perch) < 0.6,
			"deux petites guêpes, la grosse perchée sur le linteau (%.2f u)" % _arena.great.global_position.distance_to(_arena.perch))
	await _wait(1.6)
	_check(Music.desired == &"boss", "musique du combat")
	_check(_objective() == "Chasser les guêpes de la fenêtre", "objectif : chasser les guêpes")
	_check(GameState.in_combat, "en combat (modules verrouillés)")


func _test_phase1() -> void:
	_nino.damage_taken_multiplier = 0.1
	var hits := [0]
	var on_hit := func(_a: float, _b: float) -> void: hits[0] += 1
	_game.integrity.damaged.connect(on_hit)
	var max_attacking := 0
	var windup_seen := false
	var spike_windup := false
	var start_spikes := _arena.great.spikes_thrown
	for i in 14 * 60:
		await get_tree().physics_frame
		var attacking := 0
		for minion in _arena.minions:
			if minion.is_attacking():
				attacking += 1
			if minion.state == WaspMinion.State.WINDUP:
				windup_seen = true
		max_attacking = maxi(max_attacking, attacking)
		if _arena.great.state == GreatWasp.State.SPIKE_WINDUP:
			spike_windup = true
	_game.integrity.damaged.disconnect(on_hit)
	_check(windup_seen and max_attacking == 1, "petites guêpes : préparation annoncée, une seule attaque à la fois")
	_check(spike_windup and _arena.great.spikes_thrown > start_spikes, "grosse guêpe : préparation visible puis piques (%d)" % (_arena.great.spikes_thrown - start_spikes))
	_check(hits[0] >= 1, "Nin0 peut être touché (piqué ou atteint par une pique : %d)" % hits[0])
	var health := _arena.great.health
	_game.cannon._impact(_arena.great.global_position, Vector3.UP, _arena.great.hit_body)
	_check(_arena.great.health == health and not _arena.great.is_vulnerable(), "phase 1 : la grosse guêpe est hors d'atteinte (la bille ricoche)")


func _test_pause() -> void:
	_place(Vector3(-64.0, 0.05, 32.0), 0.0)
	var paused := await _wait_until(3.0, func() -> bool: return _arena.paused)
	_check(paused and _arena.phase == WaspArena.Phase.PHASE1, "Nin0 descend du plan de travail : combat en pause (phase conservée)")
	await _wait(1.0)
	var spikes := _arena.great.spikes_thrown
	await _wait(4.0)
	_check(_arena.great.spikes_thrown == spikes and _arena.minions.all(func(m: WaspMinion) -> bool: return not m.is_attacking()),
			"en pause : aucune attaque, les guêpes se replient")
	_place(ARENA_SPOT, 0.0)
	var resumed := await _wait_until(3.0, func() -> bool: return not _arena.paused)
	_check(resumed and _arena.phase == WaspArena.Phase.PHASE1 and _arena.alive_minions() == 2, "retour sur le plan de travail : le combat reprend")


func _test_phase1_retry() -> void:
	# Une petite guêpe touchée, puis Nin0 hors service : tout est remis en place.
	var minion := _arena.minions[0]
	await _wait_until(3.0, func() -> bool: return minion.state != WaspMinion.State.ENTER)
	_game.cannon._impact(minion.global_position, Vector3.UP, minion.hit_body)
	_check(minion.health == minion.max_health - 1, "une bille blesse une petite guêpe")
	_game._on_shutdown_finished()
	_check(_arena.phase in [WaspArena.Phase.IDLE, WaspArena.Phase.INTRO], "Nin0 hors service : le combat se remet en place")
	var again := await _wait_until(4.0, func() -> bool: return _arena.phase == WaspArena.Phase.INTRO)
	_check(again and _arena.attempts == 2, "nouvel essai depuis le point de reprise (intro courte)")
	var done := await _wait_until(10.0, func() -> bool: return _arena.phase == WaspArena.Phase.PHASE1 and _nino.controls_enabled)
	_check(done and _arena.alive_minions() == 2 and _arena.minions.all(func(m: WaspMinion) -> bool: return m.health == m.max_health),
			"phase 1 recommencée : deux petites guêpes intactes")


func _test_transition() -> void:
	for minion in _arena.minions.duplicate():
		await _wait_until(3.0, func() -> bool: return minion.state != WaspMinion.State.ENTER)
		for k in minion.max_health:
			_game.cannon._impact(minion.global_position, Vector3.UP, minion.hit_body)
			await _wait(0.1)
		_check(not minion.is_alive() and minion.body.wings_folded, "petite guêpe KO après %d billes (tombe, ailes repliées)" % minion.max_health)
	var cine := await _wait_until(3.0, func() -> bool: return _game.cine.is_active() and _game.cine.reason == &"wasp_phase")
	_check(cine and GameState.hazards_suspended(), "changement de phase : courte mise en scène, dangers suspendus")
	var angry := await _wait_until(3.0, func() -> bool: return _arena.great.body.anger > 0.5)
	_check(angry, "la grosse guêpe constate la défaite et se met en colère")
	var done := await _wait_until(12.0, func() -> bool: return _arena.phase == WaspArena.Phase.PHASE2 and _nino.controls_enabled)
	_check(done and GameState.wasp_phase2 and _arena.great.phase == 2, "phase 2 : contrôle rendu, étape sauvegardée")
	_check(_arena.great.global_position.y < _arena.perch.y - 3.0, "elle est descendue dans l'arène (y = %.1f)" % _arena.great.global_position.y)


func _test_phase2_retry() -> void:
	# Vraie mise hors service (intégrité à zéro) : redémarrage au point de reprise de l'arène.
	_nino.damage_taken_multiplier = 1.0
	_game.integrity._protection = 0.0
	_game.integrity.take_damage(999.0, true)
	var restarted := await _wait_until(6.0, func() -> bool: return not _game.integrity._shutting_down and _arena.phase != WaspArena.Phase.PHASE2)
	_check(restarted and _nino.global_position.distance_to(_arena.checkpoint) < 1.0, "hors service : Nin0 redémarre sur le plan de travail, près de l'arène")
	_nino.damage_taken_multiplier = 0.1
	var again := await _wait_until(4.0, func() -> bool: return _arena.phase == WaspArena.Phase.INTRO)
	var done := await _wait_until(10.0, func() -> bool: return _nino.controls_enabled and _arena.phase != WaspArena.Phase.INTRO)
	_check(again and done and _arena.phase == WaspArena.Phase.PHASE2 and _arena.alive_minions() == 0,
			"échec en phase 2 : reprise directement en phase 2 (pas depuis le début)")
	_check(_arena.great.health == _arena.great.max_health, "la grosse guêpe repart avec toute sa santé (%d)" % _arena.great.health)


func _test_phase2_patterns() -> void:
	var great := _arena.great
	var seen := {}
	var max_minions := 0
	var invulnerable_ok := true
	var sting_hits := [0]
	var on_hit := func(_a: float, _b: float) -> void:
		if great.state in [GreatWasp.State.CHARGE, GreatWasp.State.RECOVER]:
			sting_hits[0] += 1
	_game.integrity.damaged.connect(on_hit)
	# Blessée sous 75 % : le repli avec soin devient possible.
	for k in 5:
		await _wait_until(4.0, func() -> bool: return great.is_vulnerable())
		_game.cannon._impact(great.global_position, Vector3.UP, great.hit_body)
		await _wait(0.2)
	var after_hits := great.health
	_check(after_hits < great.max_health, "phase 2 : la grosse guêpe est vulnérable (%d / %d)" % [after_hits, great.max_health])
	for i in 40 * 60:
		await get_tree().physics_frame
		seen[great.state] = true
		max_minions = maxi(max_minions, _arena.alive_minions())
		if great.state == GreatWasp.State.HEAL and Engine.get_physics_frames() % 30 == 0:
			var h := great.health
			_game.cannon._impact(great.global_position, Vector3.UP, great.hit_body)
			invulnerable_ok = invulnerable_ok and great.health == h
		if seen.has(GreatWasp.State.CHARGE) and seen.has(GreatWasp.State.HEAL) and great.calls_used >= 1 and max_minions >= 1 and i > 20 * 60:
			break
	_game.integrity.damaged.disconnect(on_hit)
	_check(seen.has(GreatWasp.State.STING_WINDUP) and seen.has(GreatWasp.State.CHARGE), "pattern A : dard annoncé puis charge")
	_check(seen.has(GreatWasp.State.RETREAT) and seen.has(GreatWasp.State.HEAL) and invulnerable_ok, "pattern B : repli à l'abri, soin, intouchable pendant le soin")
	_check(great.heals_used <= great.max_heals, "soins limités (%d / %d)" % [great.heals_used, great.max_heals])
	_check(seen.has(GreatWasp.State.CALL) and great.calls_used >= 1 and great.calls_used <= great.max_calls and max_minions >= 1, "pattern C : appel de renfort, limité (%d / %d)" % [great.calls_used, great.max_calls])
	_check(max_minions <= WaspArena.MAX_MINIONS, "renforts simultanés limités (%d)" % max_minions)
	_check(sting_hits[0] >= 1, "la charge peut toucher Nin0 (%d)" % sting_hits[0])
	# Le retrait se fait à l'abri : la boîte à biscuits masque la guêpe depuis le plan de travail.
	var space := _nino.get_world_3d().direct_space_state
	var blocked := space.intersect_ray(PhysicsRayQueryParameters3D.create(ARENA_SPOT + Vector3.UP * 0.4, _arena.retreat, 1))
	_check(not blocked.is_empty(), "zone de repli hors de la ligne de tir depuis l'arène")


func _test_victory() -> void:
	var great := _arena.great
	_nino.damage_taken_multiplier = 0.0
	var won := await _wait_until(60.0, func() -> bool:
		if great.is_vulnerable() and Engine.get_physics_frames() % 15 == 0:
			_game.cannon._impact(great.global_position, Vector3.UP, great.hit_body)
		return _arena.phase in [WaspArena.Phase.VICTORY, WaspArena.Phase.DONE])
	_check(won and GameState.wasp_defeated, "grosse guêpe vaincue (billes pendant ses moments vulnérables)")
	var cine := await _wait_until(2.0, func() -> bool: return _game.cine.is_active() and _game.cine.reason == &"wasp_victory")
	_check(cine and not _nino.controls_enabled, "victoire : mise en scène, observation du dard")
	var opened := await _wait_until(25.0, func() -> bool: return _game.blueprint._open)
	_check(opened and _arena.phase == WaspArena.Phase.DONE and not great.visible, "la grosse guêpe repart par la fenêtre ; plan présenté")
	_game.blueprint.close()
	await _wait(0.5)
	_check(GameState.has_discovery(&"plan_sting_bead") and not GameState.has_upgrade(&"sting_bead"), "plan des billes pointues : à fabriquer (pas d'amélioration gratuite)")
	_check(_objective() == "Fabriquer les billes pointues à l'imprimante", "objectif : fabriquer les billes pointues")
	await _wait_until(4.0, func() -> bool: return _nino.controls_enabled)
	_check(_kitchen.get_node("Creatures/SpiderWindow").visible and Music.desired != &"boss", "après le combat : l'araignée revient, musique de la cuisine")
	_place(ARENA_SPOT, 0.0)
	await _wait(2.0)
	_check(_arena.phase == WaspArena.Phase.DONE and not _game.cine.is_active(), "le boss ne revient jamais")
	_nino.damage_taken_multiplier = 1.0


# --- Billes pointues ------------------------------------------------------------------------

func _test_sting_ammo() -> void:
	var upgrade := UpgradeCatalog.find(&"sting_bead")
	_check(upgrade.required_discovery == &"plan_sting_bead" and upgrade.cost_fragments > 0, "fabrication à l'imprimante (plan requis, %d filaments)" % upgrade.cost_fragments)
	var cannon := _game.cannon
	_check(cannon.available_ammo().size() == 1, "avant fabrication : billes ordinaires seulement")
	GameState.add_upgrade(&"sting_bead")
	await _wait(0.2)
	_check(cannon.available_ammo().size() == 2 and cannon.ammo.id == &"sting_bead", "billes pointues installées et sélectionnées")
	var label := _game.hud._ammo_label
	_check(label.visible and label.text.contains("pointues"), "interface : munition affichée (« %s »)" % label.text)
	cannon.cycle_ammo()
	_check(cannon.ammo.id == &"bead" and GameState.ammo_type == &"bead" and label.text.contains("billes"), "Q : retour aux billes ordinaires")
	cannon.cycle_ammo()
	_check(cannon.ammo.id == &"sting_bead", "Q : billes pointues")
	GameState.ammo_plastic = 10
	cannon._cooldown = 0.0
	_check(cannon.fire() and GameState.ammo_plastic == 8, "une bille pointue coûte 2 plastiques")
	GameState.ammo_plastic = 1
	cannon._cooldown = 0.0
	_check(not cannon.fire() and GameState.ammo_plastic == 1, "pas assez de plastique : tir impossible, rien n'est perdu")
	GameState.ammo_plastic = 12
	await _wait(1.0)


func _test_salon_door() -> void:
	var door := _game.sas.salon_door
	_check(not door.is_open and _game.blockout.get_node_or_null("Openings/DoorSasSalonPanel") == null, "porte du salon : battant réel (plus de bloc provisoire)")
	_place(Vector3(-31.5, 0.05, 8.0), 180.0)
	await _wait(0.6)
	_check(_game.zone_at(_nino.global_position) == GameWorld.ZONE_SAS, "devant la porte du salon (sas)")
	# Passage bloqué tant que la porte est fermée.
	_place(Vector3(-30.2, 0.05, 10.8), 180.0)
	await _hold(2.0)
	_check(_nino.global_position.z < 12.4, "porte fermée : passage bloqué (z = %.2f)" % _nino.global_position.z)
	# Observation → déduction → repère discret.
	_game.current_zone = GameWorld.ZONE_SAS
	_game._on_salon_door_examined()
	_check(door._glow_light != null and GameState.seen_notices.has(&"salon_elastic_plan"), "Nin0 comprend : une bille pointue percerait l'élastique (repère discret)")
	# Bille ronde : rebondit.
	var cannon := _game.cannon
	cannon.select_ammo(&"bead")
	cannon._impact(door.elastic_focus.global_position, Vector3.BACK, door._target, cannon.ammo)
	await _wait(0.3)
	_check(not door.is_open and _game._shown.has(&"elastic_bounce"), "bille ronde : l'élastique la renvoie")
	cannon.select_ammo(&"sting_bead")
	cannon._impact(door.elastic_focus.global_position, Vector3.BACK, door._target, cannon.ammo)
	var opened := await _wait_until(6.0, func() -> bool: return GameState.salon_opened)
	_check(opened and door.is_open, "bille pointue : l'élastique cède, la porte s'entrouvre")
	var angle := rad_to_deg(door._hinge.rotation.y)
	_check(angle > 20.0 and angle < 40.0, "entrouverte juste assez (%.0f°)" % angle)
	_check(_objective() == "Entrer dans le salon", "objectif : entrer dans le salon")
	# Le battant (charnière à l'est) barre le chemin direct vers l'est (chambre).
	_place(Vector3(-29.0, 0.05, 10.6), 180.0)
	await _hold(2.5)
	_check(_nino.global_position.z < 14.0, "côté charnière : le battant barre le passage direct vers l'est (z = %.2f)" % _nino.global_position.z)
	# Passage réel : seuil, puis l'espace entre le mur et le battant ne s'ouvre que vers
	# l'ouest (première partie du salon).
	_place(Vector3(-30.2, 0.05, 10.8), 180.0)
	var inside := await _walk(180.0, 3.0, func() -> bool: return _nino.global_position.z > 12.9)
	var west := inside and await _walk(90.0, 5.0, func() -> bool: return _nino.global_position.x < -36.0)
	var through := west and await _walk(180.0, 4.0, func() -> bool: return _nino.global_position.z > 17.5)
	_check(through, "Nin0 se glisse dans l'entrebâillement et ressort vers l'ouest, la première partie du salon (%.1f, %.1f)" % [_nino.global_position.x, _nino.global_position.z])
	await _wait(0.6)
	_check(_game.zone_at(_nino.global_position) == GameWorld.ZONE_SALON and GameState.salon_entered, "entrée dans le salon enregistrée")
	_check(_objective() == "Explorer le salon", "objectif : explorer le salon")
	var curtain := _game.blockout.get_node_or_null("Openings/CurtainChamberLock")
	_check(curtain != null, "chambre toujours verrouillée (rideau)")


func _test_saves() -> void:
	GameState.dev_mode = false
	GameState.save()
	GameState.load_save()
	_check(GameState.wasp_started and GameState.wasp_phase2 and GameState.wasp_defeated and GameState.salon_opened and GameState.salon_entered,
			"sauvegarde : étapes des guêpes et du salon conservées")
	_check(GameState.has_upgrade(&"sting_bead") and GameState.ammo_type == &"sting_bead" and GameState.has_discovery(&"plan_sting_bead"),
			"sauvegarde : billes pointues et munition choisie")
	# Ancienne sauvegarde (sans les clés du lot 7) : valeurs par défaut.
	var config := ConfigFile.new()
	config.load(GameState.save_path)
	for key in ["wasp_started", "wasp_phase2", "wasp_defeated", "salon_opened", "salon_entered"]:
		config.erase_section_key("progress", key)
	config.erase_section_key("nino", "ammo_type")
	config.save(GameState.save_path)
	GameState.load_save()
	_check(not GameState.wasp_defeated and not GameState.salon_opened and GameState.ammo_type == &"bead", "ancienne sauvegarde : lisible, valeurs par défaut")
	GameState.dev_mode = true


# --- Utilitaires ------------------------------------------------------------------------------

## Objectif affiché hors mode développement.
func _objective() -> String:
	GameState.dev_mode = false
	var text := GameState.get_objective()
	GameState.dev_mode = true
	return text


func _place(position: Vector3, yaw_degrees: float) -> void:
	_nino.global_position = position
	_nino.rotation.y = deg_to_rad(yaw_degrees)
	_nino.velocity = Vector3.ZERO
	_camera.rotation.y = deg_to_rad(yaw_degrees)
	_camera.snap_to_target()


## Marche vers une direction (caméra orientée) jusqu'à la condition.
func _walk(yaw_degrees: float, timeout: float, condition: Callable) -> bool:
	_camera.rotation.y = deg_to_rad(yaw_degrees)
	return await _hold_until(timeout, condition)


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
