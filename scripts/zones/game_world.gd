class_name GameWorld
extends Node3D
## Jeu complet (scène principale depuis le lot 5) : placard-hub + appartement.
##
## Le placard garde son directeur (workshop_director.gd, mode `embedded`) : réveil,
## jambes, vision, chute, réparation, imprimante. Ce script prend le relais au-delà du
## seuil — chapitre 2 « Le territoire des fourmis » :
## sas (première ouvrière, analyse, plan Armure I, colonne, portes) → salle de bain
## (labyrinthes, soldats, souvenir n° 2, escabeau) → lavabo (reine, vidange, plan du
## canon) → retour à l'imprimante (canon) → loquet de la cuisine → fin du chapitre.
## Le salon reste fermé (ouverture À DÉFINIR) ; la chambre reste verrouillée.

signal encounter_finished
signal chapter_completed

const ZONE_HUB := 1
const ZONE_SAS := 2
const ZONE_BATH := 3
const ZONE_KITCHEN := 4

## Mode développement : scénario à préparer au démarrage (voir apartment_dev.gd).
var dev_scenario: StringName = &""
var current_zone := 0

var director: Node3D
var nino: NinoController
var camera: ThirdPersonCamera
var hud: Hud
var thoughts: ThoughtBubbles
var focus_vision: FocusVision
var integrity: NinoIntegrity
var cannon: NinoCannon
var species_card: SpeciesCard
var blueprint: BlueprintScreen
var inventory: InventoryMenu
var chapter_end: ChapterEnd

var _zones: Array[Area3D] = []
var _shown := {}
var _encounter_running := false
var _sequence := false
var _tick := 0.0

@onready var workshop: Node3D = $Workshop
@onready var blockout: Node3D = $Blockout
@onready var sas: SasZone = $SasZone
@onready var bath: BathroomZone = $BathroomZone


func _ready() -> void:
	director = workshop
	nino = workshop.get_node("Nino")
	camera = workshop.get_node("ThirdPersonCamera")
	hud = workshop.get_node("Hud")
	thoughts = workshop.get_node("ThoughtBubbles")
	focus_vision = workshop.get_node("FocusVision")
	integrity = workshop.get_node("Integrity")
	# Le décor provisoire du sas (démo seule) laisse place à la vraie zone.
	var backdrop := workshop.get_node_or_null("Sas")
	if backdrop:
		backdrop.queue_free()
	blockout.get_node("Labels").visible = GameState.dev_mode
	for zone in blockout.get_node("Zones").get_children():
		_zones.append(zone as Area3D)
	_build_ui()
	cannon = NinoCannon.new()
	cannon.name = "Cannon"
	cannon.nino = nino
	cannon.camera = camera
	add_child(cannon)
	cannon.empty.connect(func() -> void:
		_hint_once(&"ammo_empty", "Plus de billes : ramassez du [color=#7fb8ff]plastique à projectiles[/color]", 4.0))
	director.resume_resolver = _resume_transform
	director.play_began.connect(_on_play_began)
	director.cannon_installed.connect(_on_cannon_installed)
	focus_vision.target_identified.connect(_on_target_identified)
	integrity.shutdown_finished.connect(_on_shutdown_finished)
	GameState.progress_changed.connect(_update_hub_blocker)
	sas.encounter_zone_entered.connect(_on_encounter_zone)
	sas.salon_door_examined.connect(_on_salon_door_examined)
	sas.kitchen_door.examined.connect(_on_kitchen_door_examined)
	sas.kitchen_door.unlocked.connect(_on_kitchen_unlocked)
	bath.entered.connect(func() -> void: pass)
	for soldier in bath.get_soldiers():
		soldier.alerted.connect(_on_soldier_alerted)
	var arena := bath.arena
	arena.intro_started.connect(_on_arena_intro)
	arena.fight_started.connect(_on_fight_started)
	arena.queen_defeated.connect(_on_queen_defeated)
	arena.queen.acid_hit_nino.connect(_on_acid_hit)
	for node in get_tree().get_nodes_in_group(&"resource_pickups"):
		var pickup := node as ResourcePickup
		if not workshop.is_ancestor_of(pickup):
			pickup.collected.connect(func(_p: ResourcePickup) -> void: nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 0.8))


func _build_ui() -> void:
	species_card = SpeciesCard.new()
	add_child(species_card)
	blueprint = BlueprintScreen.new()
	add_child(blueprint)
	inventory = InventoryMenu.new()
	inventory.allowed = false
	add_child(inventory)
	(workshop.get_node("PauseMenu") as PauseMenu).inventory = inventory
	chapter_end = ChapterEnd.new()
	add_child(chapter_end)


# --- Démarrage, reprise ---------------------------------------------------------------

func _on_play_began() -> void:
	inventory.allowed = true
	if GameState.dev_mode:
		# Exploration libre : la rencontre du sas se teste avec son scénario (Ctrl+1).
		GameState.worker_met = true
	_apply_saved_world()
	if GameState.dev_mode and dev_scenario != &"":
		run_dev_scenario(dev_scenario)
		dev_scenario = &""


## Remet l'appartement dans l'état de la progression (portes, arène, ressources).
func _apply_saved_world() -> void:
	_update_hub_blocker()
	if GameState.kitchen_unlocked:
		sas.kitchen_door.set_unlocked_immediately()
	bath.arena.apply_saved_state()
	bath.reset_creatures()
	for node in get_tree().get_nodes_in_group(&"resource_pickups"):
		(node as ResourcePickup).refresh()
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		if target.species and GameState.has_species(target.species.id):
			target.mark_identified(true)


## Le seuil du placard reste bloqué jusqu'à la réparation (comme dans la démo).
func _update_hub_blocker() -> void:
	if GameState.repaired or GameState.dev_mode:
		var blocker := workshop.get_node_or_null("Geometry/SasBlocker")
		if blocker:
			blocker.queue_free()


## Point de reprise d'une partie sauvegardée hors du placard (null = placard).
func _resume_transform() -> Variant:
	match GameState.resume_point:
		&"sas":
			return sas.marker("SasEntry")
		&"kitchen":
			return sas.marker("KitchenDoorFront")
		&"bath":
			return bath.marker("BathEntry")
		&"stool":
			return bath.marker("StoolBase")
		&"stool_top":
			return bath.marker("StoolTop")
	return null


func _set_resume(point: StringName, checkpoint: Variant = null) -> void:
	if checkpoint is Transform3D:
		nino.set_checkpoint(checkpoint)
	if GameState.resume_point != point:
		GameState.resume_point = point
		GameState.save()


# --- Suivi des zones ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0 or nino == null:
		return
	_tick = 0.25
	var zone := zone_at(nino.global_position)
	if zone != current_zone and zone != 0:
		var previous := current_zone
		current_zone = zone
		_on_zone_changed(previous, zone)
	GameState.in_combat = bath.any_soldier_engaged() or bath.arena.phase in [SinkArena.Phase.INTRO, SinkArena.Phase.FIGHT]
	if current_zone == ZONE_BATH and GameState.woke_up and nino.is_on_floor():
		_update_bath_checkpoints()


func zone_at(point: Vector3) -> int:
	for zone in _zones:
		var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		var local := zone.to_local(point)
		if absf(local.x) <= box.size.x / 2 and absf(local.z) <= box.size.z / 2 and absf(local.y) <= box.size.y / 2:
			return int(zone.get_meta("number"))
	return 0


func _on_zone_changed(_previous: int, zone: int) -> void:
	if not GameState.woke_up or GameState.dev_mode and not GameState.legs_installed:
		return
	match zone:
		ZONE_HUB:
			_set_resume(&"")
		ZONE_SAS:
			if not GameState.sas_entered:
				GameState.set_flag(&"sas_entered")
				# Un lieu abandonné, silencieux : Nin0 hésite un instant.
				nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 2.4)
				thoughts.think([&"eye", &"question"], "", 2.2)
			_set_resume(&"sas", sas.marker("SasEntry"))
		ZONE_BATH:
			if not GameState.bathroom_entered:
				GameState.set_flag(&"bathroom_entered")
				nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.4)
				thoughts.think([&"ant", &"ant", &"eye"], "", 2.4)
				_glance(Vector3(-50.3, 0.2, -14.2), 1.6)
			_set_resume(&"bath", bath.marker("BathEntry"))
		ZONE_KITCHEN:
			if GameState.kitchen_unlocked and not GameState.chapter2_completed:
				_complete_chapter()


## Points sûrs de la salle de bain : pied de l'escabeau, haut de l'escabeau.
func _update_bath_checkpoints() -> void:
	var p := nino.global_position
	var base := bath.marker("StoolBase")
	var top := bath.marker("StoolTop")
	if p.y < 0.5 and p.distance_to(base.origin) < 1.6 and GameState.resume_point != &"stool":
		_set_resume(&"stool", base)
	elif p.y > 6.6 and p.y < 7.2 and Vector2(p.x - top.origin.x, p.z - top.origin.z).length() < 1.8 and GameState.resume_point != &"stool_top":
		_set_resume(&"stool_top", top)


# --- Sas : première rencontre ---------------------------------------------------------

func _on_encounter_zone() -> void:
	if GameState.worker_met or _encounter_running or not GameState.legs_installed:
		return
	play_encounter()


## L'ouvrière traverse, découvre Nin0, s'arrête ; antennes, tête penchée ; ils
## s'observent en silence ; elle repart. Contrôle retiré environ 4 secondes.
func play_encounter() -> void:
	_encounter_running = true
	var ant := AntWorker.new()
	ant.name = "FirstWorker"
	sas.add_child(ant)
	var start := sas.encounter_point("Start")
	var stop := sas.encounter_point("Stop")
	var leave := sas.encounter_point("Leave")
	ant.global_position = start
	ant.face_direction(stop - start, 1.0)
	var visual := nino.get_visual()
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	await _walk_ant(ant, stop, 0.5)
	# Découverte : arrêt net, antennes agitées, tête penchée.
	var to_nino := nino.global_position - ant.global_position
	ant.face_direction(to_nino, 1.0)
	ant.body.motion_speed = 0.0
	ant.body.excitement = 1.0
	Sfx.play(&"ant_chitter", -8.0, 1.1)
	visual.look_target = ant.global_position + Vector3.UP * 0.08
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	Sfx.set_loop(&"ambience", &"ambience", -30.0)
	await _wait(0.7)
	ant.body.excitement = 0.3
	var tilt := create_tween()
	tilt.tween_property(ant.body, "head_tilt", 0.45, 0.4)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.6)
	thoughts.think([&"ant", &"question"], "", 2.2)
	await _wait(1.3)
	# Silence : ils s'observent.
	var back := create_tween()
	back.tween_property(ant.body, "head_tilt", -0.25, 0.5)
	await _wait(0.7)
	ant.body.head_tilt = 0.0
	ant.body.excitement = 0.0
	Sfx.set_loop(&"ambience", &"ambience", -18.0)
	nino.controls_enabled = true
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.2)
	GameState.set_flag(&"worker_met")
	encounter_finished.emit()
	_encounter_running = false
	# Elle reprend sa route (sans hâte) ; Nin0 la suit des yeux.
	_follow_with_eyes(ant, 2.5)
	await _walk_ant(ant, leave, 0.36)
	# Elle se glisse sous le meuble à chaussures, vers la colonne.
	if is_instance_valid(ant):
		var fade := create_tween()
		fade.tween_property(ant, "scale", Vector3.ONE * 0.05, 0.6)
		await fade.finished
	if is_instance_valid(ant):
		ant.queue_free()
	if focus_vision.unlocked and not GameState.has_species(&"ant_worker"):
		thoughts.think([&"eye", &"ant", &"question"], "", 2.4)
		_hint_once(&"analyze", "Maintenez %s : observer de près" % Hud.key("clic droit"), 5.0)


func _walk_ant(ant: AntWorker, to: Vector3, speed: float) -> void:
	if not is_instance_valid(ant):
		return
	var from := ant.global_position
	var duration := from.distance_to(to) / speed
	ant.face_direction(to - from, 1.0)
	ant.body.motion_speed = speed
	var tween := create_tween()
	tween.tween_property(ant, "global_position", to, duration)
	await tween.finished
	if is_instance_valid(ant):
		ant.body.motion_speed = 0.0


func _follow_with_eyes(target: Node3D, duration: float) -> void:
	var visual := nino.get_visual()
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(target):
		visual.look_target = target.global_position + Vector3.UP * 0.05
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	visual.look_target = null


# --- Analyse (encyclopédie biologique) -------------------------------------------------

func _on_target_identified(target: FocusTarget) -> void:
	if target.species:
		_on_species_analyzed(target.species)
	elif target.id == &"kitchen_latch":
		if GameState.has_cannon():
			thoughts.think([&"lock", &"cannon", &"exclamation"], "Une bille… pourrait le soulever.", 2.8, true)
		else:
			thoughts.think([&"lock", &"eye"], "Un crochet léger…", 2.2, true)
			thoughts.think([&"up", &"cross"], "Trop haut pour moi.", 2.4)


func _on_species_analyzed(data: SpeciesData) -> void:
	if not GameState.add_species(data.id):
		return
	species_card.show_species(data)
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var other := node as FocusTarget
		if other.species == data:
			other.mark_identified(true)
	if data.unlocks_plan == &"plan_armor_1" and not GameState.has_discovery(&"plan_armor_1"):
		await _wait(1.2)
		await _armor_reflection()


## Observer → protection → protection mécanique : le plan Armure I.
func _armor_reflection() -> void:
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.0)
	thoughts.think([&"eye", &"ant"], "Cette carapace…", 2.2, true)
	await _wait(2.4)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think([&"shield", &"question"], "Elle la protège ?", 2.2, true)
	await _wait(2.4)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	thoughts.think([&"robot", &"shield", &"idea"], "Une protection… mécanique !", 2.4, true)
	await _wait(2.0)
	species_card.hide_card()
	await blueprint.present(&"armor", "ARMURE I",
			"Module de défense passive : plaques rigides articulées, inspirées de l'exosquelette des fourmis. Réduit une partie des dégâts physiques, sans rendre invincible. À fabriquer à l'imprimante du placard (filament structurel).",
			[&"ant", &"arrow", &"shield", &"robot"])
	GameState.add_discovery(&"plan_armor_1")
	hud.show_toast("Plan découvert : Armure I", 3.0)


# --- Portes du sas --------------------------------------------------------------------

func _on_salon_door_examined() -> void:
	nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	if _shown.has(&"salon_door"):
		thoughts.think([&"door", &"lock"], "", 2.0, true)
		return
	_shown[&"salon_door"] = true
	thoughts.think([&"door", &"lock"], "Fermée…", 2.2, true)
	thoughts.think([&"robot", &"cross"], "Pas par là. Pas encore.", 2.6)


func _on_kitchen_door_examined() -> void:
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	var hook := sas.kitchen_door.latch_focus.global_position
	if GameState.has_cannon():
		thoughts.think([&"lock", &"up"], "Ce crochet…", 2.0, true)
		thoughts.think([&"cannon", &"arrow", &"lock"], "D'ici, en visant ?", 2.6)
	else:
		thoughts.think([&"door", &"lock"], "Bloquée…", 2.0, true)
		thoughts.think([&"up", &"question"], "Quelque chose, là-haut ?", 2.4)
	_glance(hook, 2.0)


func _on_kitchen_unlocked() -> void:
	GameState.set_flag(&"kitchen_unlocked")
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	visual.look_target = sas.kitchen_door.global_position + Vector3(0.0, 2.0, 0.0)
	await _wait(1.4)
	visual.look_target = null
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.4)
	thoughts.think([&"door", &"check", &"question"], "Ouverte…", 2.6, true)
	hud.show_toast("La porte de la cuisine s'est ouverte", 3.0)


func _complete_chapter() -> void:
	GameState.set_flag(&"chapter2_completed")
	nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 3.0)
	thoughts.think([&"eye", &"question"], "", 2.4)
	await _wait(2.2)
	chapter_completed.emit()
	chapter_end.show_end()


# --- Salle de bain : soldats, reine ----------------------------------------------------

func _on_soldier_alerted(_soldier: AntSoldier) -> void:
	if _shown.has(&"soldier_alert"):
		return
	_shown[&"soldier_alert"] = true
	nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	thoughts.think([&"ant_soldier", &"exclamation"], "", 1.8, true)


func _on_arena_intro() -> void:
	var queen := bath.arena.queen.global_position
	var to := queen - nino.global_position
	var frame := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	frame.tween_property(camera, "rotation:y", atan2(-to.x, -to.z), 1.0)
	frame.tween_property(camera, "pitch", deg_to_rad(-16.0), 1.0)
	frame.tween_property(camera, "arm_length", 2.6, 1.0)
	nino.get_visual().look_target = queen + Vector3.UP * 0.5
	if not _shown.has(&"queen_intro"):
		_shown[&"queen_intro"] = true
		hud.show_toast("La reine de la colonie", 3.0)


func _on_fight_started() -> void:
	nino.get_visual().look_target = null
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", 2.2, 1.0)
	thoughts.think([&"ant_queen", &"lock"], "", 2.0, true)


func _on_acid_hit() -> void:
	if _shown.has(&"acid_hit"):
		return
	_shown[&"acid_hit"] = true
	thoughts.think([&"acid", &"eye"], "Projeté… de si loin ?", 2.4, true)


func _on_shutdown_finished() -> void:
	if bath.arena.phase in [SinkArena.Phase.INTRO, SinkArena.Phase.FIGHT]:
		bath.arena.reset_fight()
	bath.reset_creatures()


## Victoire : Nin0 repense au crachat de la reine → le plan du canon.
func _on_queen_defeated() -> void:
	_sequence = true
	var visual := nino.get_visual()
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", 1.8, 1.0)
	await _wait(1.0)
	nino.controls_enabled = false
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.0)
	thoughts.think([&"acid", &"arrow"], "Elle projetait…", 2.2, true)
	await _wait(2.4)
	thoughts.think([&"gear", &"idea"], "Un ressort… une bille…", 2.4, true)
	await _wait(2.4)
	await blueprint.present(&"cannon", "CANON À PROJECTILES PLASTIQUES",
			"Amélioration majeure : un ressort comprimé propulse de petites billes de plastique. Atteint de loin les mécanismes et les créatures. À fabriquer à l'imprimante du placard.",
			[&"acid", &"arrow", &"gear", &"cannon"])
	GameState.add_discovery(&"plan_cannon")
	hud.show_toast("Plan découvert : canon à billes", 3.0)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	nino.controls_enabled = true
	_sequence = false
	thoughts.think([&"printer", &"question"], "", 2.4)


func _on_cannon_installed() -> void:
	_hint_once(&"cannon_ammo", "Les billes consomment du [color=#7fb8ff]plastique à projectiles[/color]", 5.0)


# --- Mode développement : scénarios -----------------------------------------------------

## Prépare une situation de test sans toucher aux sauvegardes (GameState.dev_mode).
func run_dev_scenario(scenario: StringName) -> void:
	if not GameState.dev_mode:
		return
	for flag in [&"injured", &"repaired", &"demo_completed", &"sas_entered"]:
		GameState.set(flag, true)
	_update_hub_blocker()
	match scenario:
		&"sas":
			GameState.worker_met = false
			_teleport(sas.marker("SasEntry"))
		&"maze":
			_teleport(bath.marker("MazeLeftEntry"))
		&"right":
			_teleport(bath.marker("MazeRightEntry"))
		&"stool":
			_teleport(bath.marker("StoolBase"))
		&"boss":
			_teleport(bath.marker("StoolTop"))
		&"cannon":
			GameState.queen_defeated = true
			GameState.add_discovery(&"plan_cannon")
			GameState.fragments = maxi(GameState.fragments, 6)
			bath.arena.apply_saved_state()
			_teleport((workshop.get_node("Checkpoints/Printer") as Node3D).global_transform)
		&"kitchen":
			GameState.queen_defeated = true
			bath.arena.apply_saved_state()
			if not GameState.has_cannon():
				GameState.add_upgrade(&"cannon")
			GameState.add_plastic(12)
			nino.get_visual().set_cannon_installed(true)
			_teleport(sas.marker("KitchenDoorFront"))
	GameState.progress_changed.emit()


func _teleport(spot: Transform3D) -> void:
	nino.global_transform = spot
	nino.velocity = Vector3.ZERO
	nino.set_checkpoint(spot)
	camera.rotation.y = spot.basis.get_euler().y
	camera.snap_to_target()


# --- Utilitaires ------------------------------------------------------------------------

func _hint_once(id: StringName, bbcode: String, duration := 5.0) -> void:
	if _shown.has(id):
		return
	_shown[id] = true
	hud.show_hint(bbcode, duration)


func _glance(point: Vector3, duration: float) -> void:
	var visual := nino.get_visual()
	visual.look_target = point
	await _wait(duration)
	if visual.look_target == point:
		visual.look_target = null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
