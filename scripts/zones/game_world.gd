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
## Lot 6 : la cuisine (araignées, cafards) s'explore ensuite librement.
## Le salon reste fermé (ouverture À DÉFINIR) ; la chambre reste verrouillée.

signal encounter_finished
signal chapter_completed

const ZONE_HUB := 1
const ZONE_SAS := 2
const ZONE_BATH := 3
const ZONE_KITCHEN := 4
const ZONE_SALON := 6

## Mode développement : scénario à préparer au démarrage (voir apartment_dev.gd).
var dev_scenario: StringName = &""
var current_zone := 0
## Ouvrière de la première rencontre (tant qu'elle est présente).
var encounter_worker: AntWorker

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
## Musique d'exploration autorisée (après le début de la partie, pas à l'écran titre).
var _music_on := false
var _boss_music := false
var _mood_tween: Tween
## Caméra des mises en scène du lot 7 (entrée de la cuisine, puce, souvenirs…).
var cine: CineCamera
var _charge_tutorial := false
var _base_ambient := -1.0

@onready var workshop: Node3D = $Workshop
@onready var blockout: Node3D = $Blockout
@onready var sas: SasZone = $SasZone
@onready var bath: BathroomZone = $BathroomZone
@onready var kitchen: KitchenZone = $KitchenZone


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
		director.reactions.react(&"failure")
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
	kitchen.examined.connect(func(data: DiscoveryData) -> void: director._on_examined(data))
	GameState.upgrade_added.connect(_on_upgrade_added)
	nino.charged_jump.connect(func(power: float) -> void:
		if _charge_tutorial and power > 0.5:
			_charge_tutorial = false
			director.reactions.react(&"upgrade", null, true)
			hud.show_toast("Saut chargé maîtrisé", 2.5))
	kitchen.salon_door_examined.connect(_on_salon_door_examined)
	var wasps := kitchen.wasp_arena
	wasps.engaged.connect(_play_wasp_intro)
	wasps.minions_defeated.connect(_play_wasp_transition)
	wasps.boss_defeated.connect(_play_wasp_victory)
	wasps.fight_reset.connect(func() -> void:
		_boss_music = false
		kitchen.set_window_spider_hidden(false))
	wasps.fight_paused.connect(func() -> void:
		if not _shown.has(&"wasp_paused"):
			_shown[&"wasp_paused"] = true
			thoughts.think([&"wasp", &"up"], "Elles m'attendent là-haut…", 2.4, true))
	sas.salon_door.bounced.connect(_on_salon_elastic_bounced)
	sas.salon_door.opened.connect(_on_salon_opened)
	cannon.ammo_changed.connect(func(ammo: AmmoData) -> void:
		hud.set_ammo(ammo, cannon.available_ammo().size() > 1))
	kitchen.spider_alerted.connect(_on_spider_alerted)
	for spider in kitchen.get_spiders():
		spider.attacked_nino.connect(func(_s: KitchenSpider) -> void: director.reactions.react(&"danger", null, true))
	for soldier in bath.get_soldiers():
		soldier.alerted.connect(_on_soldier_alerted)
	bath.larvae.landed_near.connect(func(point: Vector3) -> void: director.reactions.react(&"puzzled", point + Vector3.UP * 3.0))
	integrity.shutdown_finished.connect(func() -> void: director.reactions.react(&"failure", null, true))
	GameState.resource_discovered.connect(func(_kind: StringName) -> void: director.reactions.react(&"discovery"))
	var arena := bath.arena
	arena.mire.entered_liquid.connect(func() -> void:
		_hint_once(&"mire_acid", "Le liquide du lavabo abîme Nin0 peu à peu : rejoignez vite les [color=#c8e07a]débris flottants[/color]", 5.0))
	arena.mire.ticked.connect(func(_d: float) -> void:
		if not _shown.has(&"mire_tick"):
			_shown[&"mire_tick"] = true
			nino.get_visual().show_emotion(NinoVisual.Emotion.WORRIED, 1.4)
			thoughts.think([&"acid", &"damage"], "", 1.6, true))
	arena.intro_started.connect(_on_arena_intro)
	arena.boss_music_started.connect(func() -> void:
		_boss_music = true
		_update_music())
	arena.fight_reset.connect(func() -> void: _boss_music = false)
	arena.cinematic_changed.connect(func(active: bool) -> void: hud.set_gameplay_visible(not active))
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
	chapter_end.continue_requested.connect(func() -> void:
		if current_zone == ZONE_KITCHEN:
			play_kitchen_intro())
	cine = CineCamera.new()
	cine.changed.connect(func(active: bool) -> void: hud.set_gameplay_visible(not active))
	add_child(cine)


# --- Démarrage, reprise ---------------------------------------------------------------

func _on_play_began() -> void:
	inventory.allowed = true
	_music_on = true
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
		_show_fire_spot(false)
	elif GameState.has_cannon() and GameState.seen_notices.has(&"kitchen_latch_lesson"):
		sas.kitchen_door.highlight(true)
		_show_fire_spot(true)
	bath.arena.apply_saved_state()
	bath.reset_creatures()
	kitchen.reset_creatures()
	kitchen.wasp_arena.apply_saved_state()
	if GameState.salon_opened:
		sas.salon_door.set_open_immediately()
	elif GameState.has_upgrade(&"sting_bead") and GameState.seen_notices.has(&"salon_elastic_plan"):
		sas.salon_door.highlight(true)
	cannon.select_ammo(GameState.ammo_type, false)
	hud.set_ammo(cannon.ammo, cannon.available_ammo().size() > 1)
	nino.charged_jump_unlocked = GameState.has_upgrade(&"charged_jump")
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
			return kitchen.marker("KitchenEntry") if GameState.chapter2_completed else sas.marker("KitchenDoorFront")
		&"kitchen_counter":
			return kitchen.marker("CounterWest")
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
	if nino and nino.charged_jump_unlocked:
		hud.set_charge(nino.charge)
	_tick -= delta
	if _tick > 0.0 or nino == null:
		return
	_tick = 0.25
	var zone := zone_at(nino.global_position)
	if zone != current_zone and zone != 0:
		var previous := current_zone
		current_zone = zone
		_on_zone_changed(previous, zone)
	GameState.in_combat = bath.any_soldier_engaged() or bath.arena.phase in [SinkArena.Phase.INTRO, SinkArena.Phase.FIGHT] \
			or kitchen.any_spider_engaged() or kitchen.wasp_arena.is_active()
	_update_music()
	if current_zone == ZONE_BATH and GameState.woke_up and nino.is_on_floor():
		_update_bath_checkpoints()
	if current_zone == ZONE_KITCHEN and GameState.chapter2_completed and nino.is_on_floor():
		_update_kitchen_checkpoints()
	# Ouvrière croisée de près : intérêt (rarement, voir NinoReactions).
	if current_zone == ZONE_SAS and GameState.worker_met and not _sequence:
		for worker in sas.column.workers:
			if worker.global_position.distance_to(nino.global_position) < 0.7:
				director.reactions.react(&"peaceful", worker.global_position)
				break
	if current_zone == ZONE_SAS and GameState.has_cannon() and not GameState.kitchen_unlocked and not _sequence \
			and not GameState.seen_notices.has(&"kitchen_latch_lesson") and nino.is_on_floor() and nino.controls_enabled:
		play_latch_lesson()


## Une seule musique de zone : combat de la reine > salle de bain (labyrinthes) >
## cuisine > placard et sas (« Petit Refuge », jamais relancé s'il joue déjà).
func music_for_state() -> StringName:
	if _boss_music:
		return &"boss"
	match current_zone:
		ZONE_BATH:
			return &"labyrinth"
		ZONE_KITCHEN:
			return &"kitchen"
		ZONE_SALON:
			return &"living_room" if Music.has_track(&"living_room") else &"hub"
		ZONE_HUB, ZONE_SAS:
			return &"hub"
	return Music.desired


func _update_music() -> void:
	if not _music_on:
		return
	var id := music_for_state()
	if id != &"" and id != Music.desired:
		Music.play(id, INF, 1.2 if id == &"boss" else Music.CROSSFADE)


func zone_at(point: Vector3) -> int:
	for zone in _zones:
		var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		var local := zone.to_local(point)
		if absf(local.x) <= box.size.x / 2 and absf(local.z) <= box.size.z / 2 and absf(local.y) <= box.size.y / 2:
			return int(zone.get_meta("number"))
	return 0


func _on_zone_changed(_previous: int, zone: int) -> void:
	_set_kitchen_mood(zone == ZONE_KITCHEN)
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
			elif GameState.chapter2_completed:
				_set_resume(&"kitchen", kitchen.marker("KitchenEntry"))
				if not GameState.seen_notices.has(&"kitchen_intro"):
					play_kitchen_intro()
		ZONE_SALON:
			if GameState.salon_opened and not GameState.salon_entered:
				GameState.set_flag(&"salon_entered")
				nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 2.0)
				thoughts.think([&"eye", &"sun", &"exclamation"], "", 2.4)


## Points sûrs de la salle de bain : pied de l'escabeau, haut de l'escabeau.
func _update_bath_checkpoints() -> void:
	var p := nino.global_position
	var base := bath.marker("StoolBase")
	var top := bath.marker("StoolTop")
	if p.y < 0.5 and p.distance_to(base.origin) < 1.6 and GameState.resume_point != &"stool":
		_set_resume(&"stool", base)
	elif p.y > 6.6 and p.y < 7.2 and Vector2(p.x - top.origin.x, p.z - top.origin.z).length() < 1.8 and GameState.resume_point != &"stool_top":
		_set_resume(&"stool_top", top)


## Ambiance de la cuisine : lumière ambiante plus faible (la fenêtre éclaire, les
## dessous de meubles restent sombres), brume un peu plus froide. Retour progressif.
func _set_kitchen_mood(on: bool) -> void:
	var world := workshop.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world == null or world.environment == null:
		return
	if _base_ambient < 0.0:
		# Copie propre à cette partie : la ressource de la scène reste intacte.
		world.environment = world.environment.duplicate()
		_base_ambient = world.environment.ambient_light_energy
	var env := world.environment
	if _mood_tween:
		_mood_tween.kill()
	_mood_tween = create_tween().set_parallel(true)
	_mood_tween.tween_property(env, "ambient_light_energy", _base_ambient * (0.5 if on else 1.0), 2.0)
	_mood_tween.tween_property(env, "fog_density", 0.004 if on else 0.0025, 2.0)


## Points sûrs de la cuisine : entrée, plan de travail (ouest).
func _update_kitchen_checkpoints() -> void:
	var p := nino.global_position
	var counter := kitchen.marker("CounterWest")
	if p.y > 8.8 and p.y < 9.4 and p.distance_to(counter.origin) < 2.0 and GameState.resume_point != &"kitchen_counter":
		_set_resume(&"kitchen_counter", counter)
	elif p.y < 0.5 and p.distance_to(kitchen.marker("KitchenEntry").origin) < 2.0 and GameState.resume_point != &"kitchen":
		_set_resume(&"kitchen", kitchen.marker("KitchenEntry"))


# --- Cuisine : entrée, puce, saut chargé, souvenir n° 3 (lot 7) --------------------------

## Présentation panoramique : une cuisine immense à l'échelle de Nin0, des cafards qui
## circulent, une araignée qui chasse, des mouvements dans les recoins inaccessibles…
## puis une puce bondit d'un coup tout en haut de la poubelle : Nin0 en reste bouche bée.
func play_kitchen_intro() -> void:
	if GameState.seen_notices.has(&"kitchen_intro") or cine.is_active() or _sequence:
		return
	GameState.seen_notices.append(&"kitchen_intro")
	GameState.save()
	_sequence = true
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	var flea := kitchen.get_flea()
	flea.hold = true
	flea.global_position = kitchen.flea_intro_start()
	# Une chasse en cours pour le plan suivant (sans Nin0).
	kitchen.stage_intro_hunt()
	cine.reason = &"kitchen_intro"
	cine.begin(60.0)
	# 1. La pièce, immense.
	await cine.move(Vector3(-47.0, 15.0, 3.0), Vector3(-50.0, 12.0, 9.0), Vector3(-62.0, 4.0, 36.0), 3.2)
	# 2. Des cafards au ras du sol.
	var roach := kitchen.get_roaches()[0]
	await cine.move(roach.global_position + Vector3(2.4, 1.2, -2.4), roach.global_position + Vector3(1.4, 0.7, -1.6), roach, 2.2)
	# 3. Une araignée en chasse sous les meubles.
	var spider := kitchen.get_node("Creatures/SpiderUnder") as KitchenSpider
	await cine.move(Vector3(-66.0, 1.6, 47.0), Vector3(-68.0, 1.0, 49.5), spider, 2.6)
	# 4. Derrière le réfrigérateur, ça bouge aussi.
	await cine.move(Vector3(-47.8, 4.5, 47.6), Vector3(-47.2, 3.4, 49.0), Vector3(-46.1, 0.5, 53.0), 2.0)
	# 5. Retour sur Nin0 : une puce à ses pieds… et le bond.
	var visual := nino.get_visual()
	cine.shot(nino.global_position + Vector3(-1.6, 1.2, 2.2), flea.global_position + Vector3.UP * 0.6)
	visual.look_target = flea.global_position
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 3.0)
	await _wait(1.2)
	cine.follow(flea, Vector3(1.8, 1.4, -3.2))
	visual.look_target = kitchen.flea_intro_perch()
	await flea.jump_to(kitchen.flea_intro_perch(), 2.5)
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 2.0)
	Sfx.play(&"surprised", -6.0)
	await _wait(1.0)
	cine.shot(nino.global_position + Vector3(-1.4, 0.9, 1.4), nino.global_position + Vector3.UP * 0.5)
	visual.set_tilt(10.0)
	thoughts.think([&"flea", &"up", &"exclamation"], "Si haut… d'un seul bond ?!", 2.6, true)
	await _wait(2.6)
	visual.set_tilt(0.0)
	thoughts.think([&"eye", &"binoculars"], "", 1.8)
	await _wait(1.2)
	visual.look_target = null
	cine.end()
	flea.hold = false
	flea.linger(18.0)
	nino.controls_enabled = true
	_sequence = false
	if not GameState.has_species(&"flea"):
		_hint_once(&"scan_flea", "Observez la [color=#ffd28a]puce[/color] avec la vision focalisée", 6.0)


## Observer → comprendre : les pattes de la puce stockent l'énergie, puis la libèrent.
func _flea_reflection() -> void:
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.0)
	thoughts.think([&"eye", &"flea"], "Ses pattes se replient…", 2.2, true)
	await _wait(2.4)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think([&"legs", &"energy"], "…comme un ressort ?", 2.2, true)
	await _wait(2.4)
	visual.show_emotion(NinoVisual.Emotion.ENTHUSIASTIC, 1.5)
	thoughts.think([&"robot", &"legs", &"idea"], "Mes jambes aussi pourraient !", 2.4, true)
	await _wait(2.0)
	species_card.hide_card()
	await blueprint.present(&"charged_jump", "SAUT CHARGÉ",
			"Amélioration permanente des jambes : des ressorts accumulent l'énergie pendant que Nin0 se ramasse, puis la libèrent d'un coup. Appui bref : saut normal ; appui maintenu : saut bien plus haut. À fabriquer à l'imprimante du placard (filament structurel).",
			[&"flea", &"arrow", &"legs", &"up"])
	GameState.add_discovery(&"plan_charged_jump")
	hud.show_toast("Plan découvert : Saut chargé", 3.0)


func _on_upgrade_added(id: StringName) -> void:
	if id == &"sting_bead":
		cannon.select_ammo(&"sting_bead")
		await _wait_until(30.0, func() -> bool: return nino.controls_enabled and not _sequence)
		_hint_once(&"sting_bead", "%s : changer de munition (billes / billes pointues)" % Hud.key("Q"), 7.0)
		return
	if id != &"charged_jump":
		return
	nino.charged_jump_unlocked = true
	_charge_tutorial = true
	await _wait_until(30.0, func() -> bool: return nino.controls_enabled and not _sequence)
	_hint_once(&"charged_jump", "Jambes déployées : maintenez %s pour charger, relâchez pour bondir" % Hud.key("Espace"), 8.0)


## Souvenir n° 3 : Nin0 déchiffre la liste ligne par ligne ; silence particulier devant
## la dernière, rayée. Il reste perplexe. L'archive 03/07 n'est accordée qu'ici.
func play_todo_memory(memory: MemoryData) -> void:
	if GameState.has_memory(memory.id) or _sequence:
		if GameState.has_memory(memory.id):
			director.reactions.react(&"known", null, true)
		return
	_sequence = true
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	GameState.suspend_hazards(&"memory")
	var visual := nino.get_visual()
	var note := kitchen.todo_note_position()
	visual.look_target = note
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 3.0)
	cine.reason = &"memory_03"
	cine.begin(45.0)
	cine.shot(note + Vector3(0.6, 0.3, -2.2), note)
	Sfx.play(&"focus_lock", -6.0)
	await _wait(1.0)
	var reader := TodoReader.new()
	add_child(reader)
	Music.duck(-14.0, 9.0)
	await reader.read(memory.lines)
	visual.show_emotion(NinoVisual.Emotion.HESITANT, 3.0)
	await _wait(0.4)
	reader.queue_free()
	cine.end()
	GameState.add_memory(memory.id)
	hud.show_toast("Archive retrouvée : %02d / %02d" % [memory.slot, GameState.ARCHIVE.total], 3.0)
	visual.set_tilt(8.0)
	thoughts.think([&"question", &"ellipsis"], memory.comment, 3.2, true)
	await _wait(2.6)
	visual.set_tilt(0.0)
	visual.look_target = null
	GameState.resume_hazards(&"memory")
	nino.controls_enabled = true
	_sequence = false


# --- Cuisine : guêpes de la fenêtre (lot 7) ----------------------------------------------

## Intro : bourdonnement, deux petites guêpes entrent par l'imposte, la grosse se pose sur
## le linteau, remarque Nin0 et s'énerve. Reprise (nouvel essai, phase 2) : version courte.
func _play_wasp_intro() -> void:
	var arena := kitchen.wasp_arena
	var great := arena.great
	_sequence = true
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	kitchen.set_window_spider_hidden(true)
	var visual := nino.get_visual()
	cine.reason = &"wasp_intro"
	cine.begin(58.0)
	if arena.attempts == 1 and not GameState.wasp_phase2:
		Sfx.play(&"buzz", -4.0, 0.9)
		visual.look_target = arena.window
		visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
		cine.shot(arena.window + Vector3(5.2, -2.6, 4.6), arena.window)
		await _wait(0.8)
		arena.spawn_intro_minions()
		Sfx.play(&"buzz", -2.0, 1.4)
		await _wait(1.4)
		great.global_position = arena.window + Vector3(-1.4, 1.2, 0.0)
		cine.move(arena.perch + Vector3(4.6, -2.2, 4.0), arena.perch + Vector3(3.4, -1.0, 2.6), great, 2.0)
		Sfx.play(&"buzz_angry", -2.0, 0.7)
		await great.fly_to(arena.perch, 1.8)
		great.look_toward(nino.global_position)
		await _wait(0.4)
		great.show_anger(true)
		Sfx.play(&"queen_roar", -6.0, 1.9)
		_boss_music = true
		_update_music()
		await _wait(1.2)
		cine.shot(nino.global_position + Vector3(1.4, 0.8, -1.6), nino.global_position + Vector3.UP * 0.4)
		visual.look_target = arena.perch
		visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.6)
		Sfx.play(&"surprised", -6.0)
		thoughts.think([&"wasp", &"exclamation"], "", 1.8, true)
		await _wait(1.4)
		great.show_anger(false)
		hud.show_toast("Les guêpes de la fenêtre", 3.0)
	else:
		if not GameState.wasp_phase2:
			arena.spawn_intro_minions()
			great.global_position = arena.perch
		great.look_toward(nino.global_position)
		cine.shot(great.global_position + Vector3(3.4, -1.4, -2.8), great.global_position)
		great.show_anger(true)
		Sfx.play(&"queen_roar", -6.0, 1.9)
		_boss_music = true
		_update_music()
		await _wait(1.2)
		great.show_anger(false)
	visual.look_target = null
	cine.end()
	nino.controls_enabled = true
	_sequence = false
	arena.begin_phase1()
	if GameState.wasp_phase2:
		_hint_once(&"wasp_phase2", "Tirez quand elle [color=#ffd28a]appelle des renforts[/color] ou après une charge : elle est vulnérable", 6.0)
	else:
		_hint_once(&"wasp_phase1", "Les petites guêpes s'annoncent avant de piquer (« ! ») : visez-les, esquivez les piques", 6.0)


## Changement de phase : la grosse guêpe voit les petites à terre, s'énerve, descend.
func _play_wasp_transition() -> void:
	var arena := kitchen.wasp_arena
	var great := arena.great
	await _wait(0.7)
	_sequence = true
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	var visual := nino.get_visual()
	cine.reason = &"wasp_phase"
	cine.begin(55.0)
	var fallen := nino.global_position
	for minion in arena.minions:
		if is_instance_valid(minion):
			fallen = minion.global_position
	cine.shot(great.global_position + Vector3(3.0, -1.2, -2.6), great.global_position)
	great.look_toward(fallen)
	await _wait(1.0)
	great.look_toward(nino.global_position)
	great.show_anger(true)
	Sfx.play(&"buzz_angry", 0.0, 0.8)
	Sfx.play(&"queen_roar", -4.0, 1.7)
	await _wait(1.1)
	var down_to := arena.clamp_air(nino.global_position + Vector3(1.6, 2.0, -2.0))
	cine.follow(great, Vector3(2.6, 0.6, -2.4))
	await great.fly_to(down_to, 1.6)
	cine.shot(nino.global_position + Vector3(1.2, 0.7, -1.5), nino.global_position + Vector3.UP * 0.4)
	visual.look_target = great.global_position
	visual.show_emotion(NinoVisual.Emotion.WORRIED, 1.6)
	thoughts.think([&"wasp", &"exclamation"], "La grande…", 1.8, true)
	await _wait(1.2)
	great.show_anger(false)
	visual.look_target = null
	cine.end()
	nino.controls_enabled = true
	_sequence = false
	arena.begin_phase2()
	_hint_once(&"wasp_phase2", "Tirez quand elle [color=#ffd28a]appelle des renforts[/color] ou après une charge : elle est vulnérable", 6.0)


## Victoire : la grosse guêpe tombe, sonnée ; Nin0 observe son dard → plan des billes
## pointues (à fabriquer à l'imprimante). Elle repart par la fenêtre et ne revient plus.
func _play_wasp_victory() -> void:
	var arena := kitchen.wasp_arena
	var great := arena.great
	_sequence = true
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	var visual := nino.get_visual()
	cine.reason = &"wasp_victory"
	cine.begin(52.0)
	await _wait(0.1)
	var at := great.global_position
	cine.shot(at + Vector3(2.4, 1.2, -2.2), at)
	await _wait(1.2)
	at = great.global_position
	cine.shot(nino.global_position + Vector3(1.4, 0.8, -1.6), nino.global_position + Vector3.UP * 0.4)
	visual.look_target = at
	visual.show_emotion(NinoVisual.Emotion.ENTHUSIASTIC, 2.0)
	director.reactions.react(&"upgrade", null, true)
	await _wait(1.6)
	# Observation du dard.
	cine.shot(at + Vector3(0.9, 0.5, -0.9), at + Vector3(0.0, 0.05, 0.0))
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.4)
	thoughts.think([&"wasp", &"eye"], "Ce dard…", 2.2, true)
	await _wait(2.4)
	thoughts.think([&"sting", &"idea"], "Une pointe… elle percerait !", 2.4, true)
	await _wait(2.2)
	cine.follow(great, Vector3(2.8, 1.0, -2.0))
	await arena.finish()
	visual.look_target = null
	cine.end()
	kitchen.set_window_spider_hidden(false)
	await _wait(0.3)
	await blueprint.present(&"sting", "BILLES POINTUES",
			"Second chargeur du canon : des billes prolongées d'une pointe dure, inspirées du dard de la guêpe. Elles frappent plus fort et percent ce qui fait rebondir une bille ronde. Coûtent deux plastiques. À fabriquer à l'imprimante du placard.",
			[&"wasp", &"arrow", &"sting", &"cannon"])
	GameState.add_discovery(&"plan_sting_bead")
	hud.show_toast("Plan découvert : billes pointues", 3.0)
	_boss_music = false
	_update_music()
	nino.controls_enabled = true
	_sequence = false
	thoughts.think([&"printer", &"question"], "", 2.4)


# --- Cuisine : araignées ----------------------------------------------------------------

## Une araignée a repéré Nin0 près de son repaire : il comprend qu'il dérange.
func _on_spider_alerted(spider: KitchenSpider) -> void:
	if _shown.has(&"spider_alert"):
		director.reactions.react(&"danger", spider.global_position + Vector3.UP * 0.1)
		return
	_shown[&"spider_alert"] = true
	nino.get_visual().show_emotion(NinoVisual.Emotion.WORRIED, 1.8)
	nino.get_visual().look_target = spider.global_position + Vector3.UP * 0.1
	thoughts.think([&"spider", &"exclamation"], "", 1.8, true)
	thoughts.think([&"house", &"cross"], "Son territoire…", 2.2)
	await _wait(1.6)
	nino.get_visual().look_target = null


# --- Sas : première rencontre ---------------------------------------------------------

func _on_encounter_zone() -> void:
	if GameState.worker_met or _encounter_running or not GameState.legs_installed:
		return
	play_encounter()


## L'ouvrière traverse, découvre Nin0, s'arrête ; antennes, tête penchée. Nin0
## l'observe, ses yeux se calibrent, il pense « jumelles » : le joueur est invité à
## l'analyser. L'ouvrière attend un moment (cible visible sur elle), puis repart.
## Le scan n'est jamais lancé automatiquement.
func play_encounter() -> void:
	_encounter_running = true
	var ant := AntWorker.new()
	ant.name = "FirstWorker"
	sas.add_child(ant)
	encounter_worker = ant
	var start := sas.encounter_point("Start")
	var stop := sas.encounter_point("Stop")
	var leave := sas.encounter_point("Leave")
	ant.global_position = start
	ant.face_direction(stop - start, 1.0)
	var visual := nino.get_visual()
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	GameState.suspend_hazards(&"encounter")
	await _walk_ant(ant, stop, 0.5)
	# Découverte : arrêt net, antennes agitées, tête penchée.
	ant.face_direction(nino.global_position - ant.global_position, 1.0)
	ant.body.motion_speed = 0.0
	ant.body.excitement = 1.0
	Sfx.play(&"ant_chitter", -8.0, 1.1)
	visual.look_target = ant.global_position + Vector3.UP * 0.08
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	Sfx.set_loop(&"ambience", &"ambience", -30.0)
	await _wait(0.7)
	ant.body.excitement = 0.3
	create_tween().tween_property(ant.body, "head_tilt", 0.45, 0.4)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 1.4)
	Sfx.play(&"curious", -10.0)
	await _wait(1.0)
	# Curiosité réciproque : elle s'approche prudemment, antennes tendues vers Nin0…
	var careful := ant.global_position.lerp(nino.global_position, 0.22)
	careful.y = ant.global_position.y
	ant.body.head_tilt = 0.0
	ant.body.excitement = 1.0
	await _walk_ant(ant, careful, 0.18)
	Sfx.play(&"ant_chitter", -12.0, 1.3)
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 0.8)
	visual.react_to_landing(2.0)
	await _wait(0.6)
	# … puis recule d'un pas.
	var back_step := careful.lerp(stop, 0.6)
	ant.body.excitement = 0.4
	var retreat := create_tween()
	retreat.tween_property(ant, "global_position", back_step, 0.5)
	await retreat.finished
	ant.face_direction(nino.global_position - ant.global_position, 1.0)
	await _wait(0.3)
	# Nin0 force sa vue : petit calibrage optique, pensée « jumelles ».
	for i in 2:
		visual.show_emotion(NinoVisual.Emotion.FOCUSED, 0.5)
		Sfx.play(&"servo", -18.0, 1.8)
		await _wait(0.45)
	visual.glitch_pulse(0.4, 0.3)
	Sfx.play(&"optic", -8.0)
	thoughts.think([&"binoculars", &"ant"], "", 3.0, true)
	ant.body.head_tilt = 0.0
	ant.body.excitement = 0.0
	Sfx.set_loop(&"ambience", &"ambience", -18.0)
	nino.controls_enabled = true
	GameState.resume_hazards(&"encounter")
	visual.look_target = null
	GameState.set_flag(&"worker_met")
	encounter_finished.emit()
	_encounter_running = false
	var analyzed := GameState.has_species(&"ant_worker")
	if not analyzed:
		_mark_scan_target(ant, true)
		hud.show_hint("Maintenez %s : vision focalisée — visez la fourmi" % Hud.key("clic droit"), 9.0)
		# Elle reste là, curieuse, le temps d'être analysée (ou que Nin0 s'éloigne).
		var waited := 0.0
		while waited < 25.0 and is_instance_valid(ant) and not GameState.has_species(&"ant_worker") \
				and nino.global_position.distance_to(ant.global_position) < 3.5:
			ant.body.excitement = 0.15 + 0.15 * sin(waited * 3.0)
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
		if is_instance_valid(ant):
			_mark_scan_target(ant, false)
			ant.body.excitement = 0.0
		if GameState.has_species(&"ant_worker"):
			await _wait(1.2)
	# Elle reprend sa route (sans hâte) vers le meuble à chaussures.
	if is_instance_valid(ant):
		await _walk_ant(ant, leave, 0.36)
	if is_instance_valid(ant):
		var fade := create_tween()
		fade.tween_property(ant, "scale", Vector3.ONE * 0.05, 0.6)
		await fade.finished
	if is_instance_valid(ant):
		ant.queue_free()
	encounter_worker = null
	if focus_vision.unlocked and not GameState.has_species(&"ant_worker"):
		thoughts.think([&"binoculars", &"ant", &"question"], "", 2.4)


## Cible visuelle sur l'ouvrière à analyser : anneau pulsant et repère de la vision.
func _mark_scan_target(ant: AntWorker, on: bool) -> void:
	ant.focus.show_marker = on
	var ring := ant.get_node_or_null("ScanRing") as MeshInstance3D
	if on and ring == null:
		ring = MeshInstance3D.new()
		ring.name = "ScanRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 0.13
		torus.outer_radius = 0.16
		ring.mesh = torus
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.55, 0.95, 1.0, 0.8)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = material
		ring.position = Vector3(0.0, 0.02, 0.0)
		ant.add_child(ring)
		var pulse := ring.create_tween().set_loops()
		pulse.tween_property(ring, "scale", Vector3.ONE * 1.25, 0.5)
		pulse.tween_property(ring, "scale", Vector3.ONE, 0.5)
	if ring:
		ring.visible = on


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
	elif target.memory and target.memory.presentation == &"todo":
		play_todo_memory(target.memory)
	elif target.id == &"salon_elastic":
		_on_salon_door_examined()
	elif target.id == &"kitchen_latch":
		if GameState.has_cannon():
			thoughts.think([&"lock", &"cannon", &"exclamation"], "Une bille… pourrait le soulever.", 2.8, true)
		else:
			thoughts.think([&"lock", &"eye"], "Un crochet léger…", 2.2, true)
			thoughts.think([&"up", &"cross"], "Trop haut pour moi.", 2.4)


func _on_species_analyzed(data: SpeciesData) -> void:
	if not GameState.add_species(data.id):
		return
	# Analyse importante : rien ne peut toucher Nin0 pendant la lecture de la fiche.
	GameState.suspend_hazards(&"analysis")
	species_card.show_species(data)
	_resume_after_card()
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var other := node as FocusTarget
		if other.species == data:
			other.mark_identified(true)
	if data.unlocks_plan == &"plan_armor_1" and not GameState.has_discovery(&"plan_armor_1"):
		await _wait(1.2)
		await _armor_reflection()
	elif data.unlocks_plan == &"plan_charged_jump" and not GameState.has_discovery(&"plan_charged_jump"):
		await _wait(1.2)
		await _flea_reflection()


func _resume_after_card() -> void:
	await _wait(0.5)
	while species_card.showing or blueprint._open:
		await get_tree().process_frame
	GameState.resume_hazards(&"analysis")


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
	if current_zone == ZONE_SAS and not GameState.salon_opened:
		_examine_salon_elastic()
		return
	director.reactions.react(&"strange", null, true)
	if _shown.has(&"salon_door"):
		thoughts.think([&"door", &"lock"], "", 2.0, true)
		return
	_shown[&"salon_door"] = true
	thoughts.think([&"door", &"lock"], "Fermée…", 2.2, true)
	thoughts.think([&"robot", &"cross"], "Pas par là. Pas encore.", 2.6)


## Porte du salon, côté sas (lot 7) : observer → déduire. Le pêne est cassé, un gros
## élastique retient la porte. Une bille ronde rebondirait ; une pointe le percerait.
func _examine_salon_elastic() -> void:
	_shown[&"salon_door"] = true
	var door := sas.salon_door
	var visual := nino.get_visual()
	_glance(door.elastic_focus.global_position, 2.4)
	if GameState.has_upgrade(&"sting_bead"):
		visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.0)
		thoughts.think([&"door", &"eye"], "Cet élastique la retient…", 2.2, true)
		thoughts.think([&"sting", &"arrow", &"door"], "Une bille pointue le percerait !", 2.6)
		door.highlight(true)
		if not GameState.seen_notices.has(&"salon_elastic_plan"):
			GameState.seen_notices.append(&"salon_elastic_plan")
			GameState.save()
		_hint_once(&"salon_elastic", "%s : billes pointues · visez l'[color=#ffd28a]élastique[/color] puis %s" % [Hud.key("Q"), Hud.key("clic gauche / X")], 7.0)
	elif GameState.wasp_defeated:
		director.reactions.react(&"puzzled", null, true)
		thoughts.think([&"door", &"eye"], "Cet élastique la retient…", 2.2, true)
		thoughts.think([&"wasp", &"idea"], "Il faudrait une pointe… comme ce dard.", 2.8)
	elif GameState.has_cannon():
		director.reactions.react(&"strange", null, true)
		thoughts.think([&"door", &"eye"], "Retenue par un élastique…", 2.2, true)
		thoughts.think([&"cannon", &"question"], "Une bille rebondirait dessus ?", 2.6)
	else:
		director.reactions.react(&"strange", null, true)
		thoughts.think([&"door", &"lock"], "Fermée…", 2.2, true)
		thoughts.think([&"robot", &"cross"], "Pas par là. Pas encore.", 2.6)


## Une bille ronde a rebondi sur l'élastique : Nin0 comprend qu'il faut autre chose.
func _on_salon_elastic_bounced() -> void:
	if _shown.has(&"elastic_bounce"):
		director.reactions.react(&"failure")
		return
	_shown[&"elastic_bounce"] = true
	nino.get_visual().show_emotion(NinoVisual.Emotion.FRUSTRATED, 1.4)
	if GameState.has_upgrade(&"sting_bead"):
		thoughts.think([&"plastic", &"cross"], "Trop ronde… les pointues !", 2.4, true)
	else:
		thoughts.think([&"plastic", &"cross"], "Elle rebondit… trop souple.", 2.4, true)


## L'élastique a cédé : le courant d'air entrouvre la porte vers le salon.
func _on_salon_opened() -> void:
	GameState.set_flag(&"salon_opened")
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.4)
	visual.look_target = sas.salon_door.global_position + Vector3(-4.0, 4.0, 3.0)
	await _wait(1.2)
	visual.look_target = null
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.4)
	thoughts.think([&"door", &"sun", &"question"], "Entrouverte… de la lumière, de l'autre côté.", 2.8, true)
	hud.show_toast("La porte du salon s'est entrouverte", 3.0)


func _on_kitchen_door_examined() -> void:
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	var hook := sas.kitchen_door.latch_focus.global_position
	if GameState.has_cannon():
		thoughts.think([&"lock", &"up"], "Ce crochet…", 2.0, true)
		thoughts.think([&"cannon", &"arrow", &"lock"], "Depuis le repère, en visant ?", 2.6)
		sas.kitchen_door.highlight(true)
		_show_fire_spot(true)
	else:
		director.reactions.react(&"strange", null, true)
		thoughts.think([&"door", &"lock"], "Bloquée…", 2.0, true)
		thoughts.think([&"up", &"question"], "Quelque chose, là-haut ?", 2.4)
	_glance(hook, 2.0)


## Retour au sas avec le canon : Nin0 examine la porte, la caméra montre le crochet en
## hauteur, il comprend qu'il peut l'atteindre avec son canon ; un repère de tir apparaît.
## Le joueur vise et tire lui-même.
func play_latch_lesson() -> void:
	_sequence = true
	GameState.seen_notices.append(&"kitchen_latch_lesson")
	GameState.save()
	var door := sas.kitchen_door
	var hook := door.latch_focus.global_position
	var visual := nino.get_visual()
	nino.controls_enabled = false
	nino.velocity = Vector3.ZERO
	GameState.suspend_hazards(&"latch_lesson")
	visual.look_target = door.global_position + Vector3(0.0, 4.0, -4.0)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think([&"door", &"lock"], "", 1.6, true)
	await _wait(1.2)
	door.highlight(true)
	var cam := Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	var previous := get_viewport().get_camera_3d()
	cam.make_current()
	hud.set_gameplay_visible(false)
	var from := hook + Vector3(5.6, -4.8, 4.2)
	var to := hook + Vector3(3.6, -2.6, 2.8)
	var push := create_tween().set_trans(Tween.TRANS_SINE)
	push.tween_method(func(k: float) -> void:
		cam.global_position = from.lerp(to, k)
		cam.look_at(hook), 0.0, 1.0, 2.2)
	visual.look_target = hook
	thoughts.think([&"lock", &"up"], "Ce crochet…", 1.8, true)
	await _wait(2.4)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.6)
	thoughts.think([&"cannon", &"arrow", &"lock"], "Avec mon canon !", 2.4, true)
	Sfx.play(&"curious", -6.0)
	await _wait(1.6)
	if is_instance_valid(previous):
		previous.make_current()
	cam.queue_free()
	hud.set_gameplay_visible(true)
	visual.look_target = null
	_show_fire_spot(true)
	nino.controls_enabled = true
	GameState.resume_hazards(&"latch_lesson")
	_sequence = false
	hud.show_hint("Repère au sol : maintenez %s pour viser le crochet, puis %s pour tirer" % [Hud.key("clic droit"), Hud.key("clic gauche / X")], 8.0)


## Cercle lumineux au sol : d'ici, le crochet se vise confortablement.
func _show_fire_spot(on: bool) -> void:
	var ring := sas.get_node_or_null("FireSpotRing") as MeshInstance3D
	if on and ring == null:
		ring = MeshInstance3D.new()
		ring.name = "FireSpotRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 0.42
		torus.outer_radius = 0.5
		ring.mesh = torus
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.75, 0.35, 0.85)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = material
		sas.add_child(ring)
		ring.global_position = sas.marker("FireSpot").origin + Vector3.UP * 0.02
		var pulse := ring.create_tween().set_loops()
		pulse.tween_property(ring, "scale", Vector3.ONE * 1.15, 0.6)
		pulse.tween_property(ring, "scale", Vector3.ONE, 0.6)
	if ring:
		ring.visible = on


func _on_kitchen_unlocked() -> void:
	_show_fire_spot(false)
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

func _on_soldier_alerted(soldier: AntSoldier) -> void:
	if _shown.has(&"soldier_alert"):
		director.reactions.react(&"danger", soldier.global_position + Vector3.UP * 0.1)
		return
	_shown[&"soldier_alert"] = true
	nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	thoughts.think([&"ant_soldier", &"exclamation"], "", 1.8, true)


func _on_arena_intro() -> void:
	# Cadre de jeu après la cinématique : la caméra regarde vers la vasque.
	var to := SinkArena.BASIN_CENTER - nino.global_position
	camera.rotation.y = atan2(-to.x, -to.z)
	camera.pitch = deg_to_rad(-18.0)
	camera.arm_length = 2.4
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
	if kitchen.wasp_arena.is_active():
		kitchen.wasp_arena.reset_fight()
	bath.reset_creatures()


## Victoire : Nin0 repense au crachat de la reine → le plan du canon.
func _on_queen_defeated() -> void:
	_sequence = true
	var visual := nino.get_visual()
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", 1.8, 1.0)
	await _wait(1.0)
	nino.controls_enabled = false
	GameState.suspend_hazards(&"reflection")
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
	GameState.resume_hazards(&"reflection")
	_sequence = false
	thoughts.think([&"printer", &"question"], "", 2.4)
	# Fin du combat : retour à la musique des labyrinthes.
	_boss_music = false
	_update_music()


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
		&"kitchen_inside":
			GameState.queen_defeated = true
			bath.arena.apply_saved_state()
			if not GameState.has_cannon():
				GameState.add_upgrade(&"cannon")
			GameState.add_plastic(12)
			nino.get_visual().set_cannon_installed(true)
			GameState.kitchen_unlocked = true
			GameState.chapter2_completed = true
			sas.kitchen_door.set_unlocked_immediately()
			_teleport(kitchen.marker("KitchenEntry"))
		&"wasps", &"salon_door":
			GameState.queen_defeated = true
			bath.arena.apply_saved_state()
			for id in [&"cannon", &"charged_jump"]:
				if not GameState.has_upgrade(id):
					GameState.add_upgrade(id)
			nino.charged_jump_unlocked = true
			GameState.add_plastic(GameState.PLASTIC_MAX)
			nino.get_visual().set_cannon_installed(true)
			GameState.kitchen_unlocked = true
			GameState.chapter2_completed = true
			if not GameState.seen_notices.has(&"kitchen_intro"):
				GameState.seen_notices.append(&"kitchen_intro")
			sas.kitchen_door.set_unlocked_immediately()
			if scenario == &"wasps":
				_teleport(kitchen.marker("CounterWest"))
			else:
				GameState.wasp_defeated = true
				kitchen.wasp_arena.apply_saved_state()
				GameState.add_discovery(&"plan_sting_bead")
				if not GameState.has_upgrade(&"sting_bead"):
					GameState.add_upgrade(&"sting_bead")
				_teleport(sas.marker("FireSpot"))
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


func _wait_until(timeout: float, condition: Callable) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if condition.call():
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false
