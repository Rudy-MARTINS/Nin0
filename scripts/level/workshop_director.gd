extends Node3D
## Directeur de la première démo (placard-hub).
##
## Fil conducteur : Nin0 observe → comprend → agit. Ses pensées (bulles) disent ce
## qu'il remarque ou déduit ; l'objectif (HUD) dit ce que le joueur cherche à faire.
##
## Déroulement : titre → réveil → mini-tutoriel → imprimante hors tension → câble →
## multiprise → retour par les bobines → compréhension de l'imprimante → impression →
## carnet renversé → installation sur le plateau → premiers pas → fenêtre → vision
## focalisée sur la poignée → étagère → la porte s'ouvre, Nin0 chute et s'abîme →
## retour à l'imprimante avec les jambes → réparation → la porte ouverte → fin.
## Facultatif : souvenirs (vision focalisée), fragments de filament, renfort de châssis.
## Seul (workshop.tscn), le placard reste la première démo et se termine au seuil.
## Intégré au jeu complet (game.tscn, `embedded`), le seuil ne termine plus rien :
## l'appartement continue (lot 5), l'imprimante fabrique aussi Armure I et le canon.

signal play_began
signal cannon_installed
signal module_fabricated(upgrade: UpgradeData)

const TITLE_CAMERA_YAW := deg_to_rad(65.0)
const GAMEPLAY_ARM := 1.8
## Dégâts de la chute scriptée (directs, sans bouclier) : visibles, jamais mortels.
const DOOR_FALL_DAMAGE := 45.0
## Fragments de filament nécessaires à une réparation.
const REPAIR_COST := 3
const FIRST_REPAIR_DURATION := 6.0
const REPAIR_DURATION := 3.0
const UPGRADE_DURATION := 4.0

enum Tutorial { NONE, FORWARD, BACK, CAMERA, DONE }

## Intégré au jeu complet : pas de fin de démo au seuil (voir game_world.gd).
@export var embedded := false
## Point de reprise hors du placard (fourni par le jeu complet) : renvoie un Transform3D
## ou null pour reprendre dans le placard.
var resume_resolver: Callable

var _title_active := false
var _title_time := 0.0
var _waiting_wake_input := false
var _sequence_running := false
var _tutorial := Tutorial.NONE
var _step_distance := 0.0
var _turned := 0.0
var _last_position := Vector3.ZERO
var _last_yaw := 0.0
var _thoughts_shown := {}
var _pending_handle_thought := false
var _last_print_percent := -1

@onready var nino: NinoController = $Nino
@onready var camera: ThirdPersonCamera = $ThirdPersonCamera
@onready var hud: Hud = $Hud
@onready var thoughts: ThoughtBubbles = $ThoughtBubbles
@onready var printer: Printer3D = $Printer3D
@onready var power_strip: PowerStrip = $PowerStrip
@onready var notebook: ToppleRamp = $Notebook
@onready var door: ClosetDoor = $ClosetDoor
@onready var spool_slot: SpoolSlot = $Geometry/SpoolSlot
@onready var spools: Array[Node] = [$Geometry/Spool0, $Geometry/Spool1]
@onready var focus_vision: FocusVision = $FocusVision
@onready var printer_panel: PrinterPanel = $PrinterPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var end_screen: EndScreen = $EndScreen
@onready var title_screen: TitleScreen = $TitleScreen
@onready var integrity: NinoIntegrity = $Integrity
@onready var memory_player: MemoryPlayer = $MemoryPlayer
@onready var drawing_focus: FocusTarget = $Geometry/DrawingFocus
@onready var _interactor: Interactor = $Nino/Interactor
@onready var _checkpoints: Node3D = $Checkpoints


func _ready() -> void:
	nino.state_changed.connect(_on_nino_state_changed)
	nino.mode_changed.connect(_on_mode_changed)
	nino.transform_refused.connect(func(reason: String) -> void: hud.show_hint(reason, 2.0))
	nino.respawned.connect(_on_nino_respawned)
	_interactor.focus_changed.connect(_on_focus_changed)
	printer.interactable.interacted.connect(_on_printer_interacted)
	printer.print_progressed.connect(_on_print_progressed)
	printer.print_finished.connect(_on_print_finished)
	printer_panel.repair_requested.connect(_on_repair_requested)
	printer_panel.upgrade_requested.connect(_on_upgrade_requested)
	for pickup in $Pickups.get_children():
		(pickup as ResourcePickup).collected.connect(_on_fragment_collected)
	power_strip.switched_on.connect(_on_power_switched_on)
	notebook.toppled.connect(_on_notebook_toppled)
	door.interactable.interacted.connect(func(_by: Node3D) -> void: _open_door())
	spool_slot.filled.connect(_on_spool_slotted)
	focus_vision.target_identified.connect(_on_focus_target_identified)
	focus_vision.focus_changed.connect(_on_focus_changed_mode)
	printer_panel.print_requested.connect(_on_print_requested)
	printer_panel.closed.connect(_on_panel_closed)
	title_screen.start_requested.connect(_on_start_requested)
	for zone in $Zones.get_children():
		(zone as TriggerZone).player_entered.connect(_on_zone_entered)
	var examinables := $Discoveries.get_children()
	for examinable in examinables:
		(examinable as Examinable).examined.connect(_on_examined)
	for examinable in examinables:
		pause_menu.discovery_ids.append((examinable as Examinable).discovery.id)
	GameState.progress_changed.connect(_refresh_objective)
	GameState.modules_changed.connect(_refresh_equipment)

	Sfx.stop_all_loops()
	Sfx.set_loop(&"ambience", &"ambience", -18.0)
	nino.set_checkpoint(_checkpoint("Start"))
	_set_sleeping()

	if GameState.dev_mode:
		_start_dev_session.call_deferred()
		return
	# Musique d'introduction : une seule fois au démarrage du jeu (prototype interne).
	Music.play_once(&"intro")
	if GameState.skip_title_once:
		GameState.skip_title_once = false
		_start_new_game()
	else:
		_show_title()


func _process(delta: float) -> void:
	if _title_active:
		_title_time += delta
		camera.rotation.y = TITLE_CAMERA_YAW + sin(_title_time * 0.2) * 0.18
	elif _waiting_wake_input:
		if _any_move_pressed():
			_waiting_wake_input = false
			_boot_nino()
	_update_tutorial(delta)


func _physics_process(_delta: float) -> void:
	# Installation des jambes : Nin0 doit se trouver sur le plateau d'impression.
	if _sequence_running:
		return
	if GameState.legs_printed and not GameState.legs_installed \
			and nino.state == NinoController.State.FREE and nino.is_on_floor() and printer.is_rider_on_bed(nino):
		_install_legs()


# --- Écran titre et démarrage ---------------------------------------------------------

func _show_title() -> void:
	_title_active = true
	hud.set_gameplay_visible(false)
	hud.set_fade(1.0)
	hud.fade_to(0.0, 1.5)
	camera.input_enabled = false
	camera.arm_length = 1.3
	camera.pitch = deg_to_rad(-8.0)
	camera.rotation.y = TITLE_CAMERA_YAW
	camera.snap_to_target()
	title_screen.open()


func _on_start_requested(resume: bool) -> void:
	_title_active = false
	if resume:
		_start_from_save()
	else:
		GameState.erase_save()
		_start_new_game()


func _start_new_game() -> void:
	GameState.reset_progress()
	_set_sleeping()
	hud.set_gameplay_visible(false)
	camera.arm_length = 1.1
	camera.pitch = deg_to_rad(-6.0)
	camera.rotation.y = TITLE_CAMERA_YAW
	camera.snap_to_target()
	hud.set_fade(1.0)
	await hud.fade_to(0.0, 1.2).finished
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.set_gameplay_visible(true)
	hud.show_hint("Appuyez sur %s pour réveiller Nin0" % Hud.key("Z Q S D"))
	_waiting_wake_input = true


func _start_from_save() -> void:
	GameState.load_save()
	_apply_progress_world()
	var spot := "Printer"
	if GameState.injured and not GameState.repaired:
		spot = "FallSpot"
	var outside: Variant = resume_resolver.call() if embedded and resume_resolver.is_valid() else null
	_begin_play_at(outside if outside is Transform3D else _checkpoint(spot))
	hud.show_hint("%s : déployer les jambes (à l'arrêt)" % Hud.key("F"), 6.0)


## Mode développement (scène de l'appartement) : Nin0 complet (jambes, vision),
## énigmes du placard résolues, porte entrouverte. Rien n'est sauvegardé.
func _start_dev_session() -> void:
	GameState.reset_progress()
	for flag in [&"woke_up", &"tutorial_done", &"printer_seen", &"power_on", &"printer_understood", &"legs_printed",
			&"legs_installed", &"legs_deployed_once", &"reached_window", &"handle_identified", &"door_opened"]:
		GameState.set(flag, true)
	GameState.progress_changed.emit()
	_apply_progress_world()
	_begin_play_at(_checkpoint("Printer"))


## Met le placard dans l'état de la progression chargée (machine, énigmes, porte…).
func _apply_progress_world() -> void:
	power_strip.set_on_immediately()
	printer.set_completed()
	notebook.set_toppled_immediately()
	spool_slot.fill_immediately(spools[0])
	nino.legs_available = true
	nino.get_visual().set_power(1.0)
	_refresh_saved_world()


func _begin_play_at(spot: Transform3D) -> void:
	_title_active = false
	title_screen.visible = false
	nino.global_transform = spot
	nino.set_checkpoint(spot)
	camera.rotation.y = nino.rotation.y
	camera.pitch = deg_to_rad(-18.0)
	camera.arm_length = GAMEPLAY_ARM
	camera.snap_to_target()
	_tutorial = Tutorial.DONE
	_enable_play()
	hud.set_gameplay_visible(true)
	hud.set_fade(1.0)
	hud.fade_to(0.0, 1.0)
	hud.set_mode("Roues")
	_refresh_objective()
	_start_exploration_music()
	play_began.emit()


## Remet le monde dans l'état sauvegardé (porte, vision, souvenirs, objets emportés).
func _refresh_saved_world() -> void:
	focus_vision.unlocked = GameState.reached_window
	for node in get_tree().get_nodes_in_group(&"focus_targets"):
		var target := node as FocusTarget
		var known := (target.id == &"door_handle" and GameState.handle_identified) \
				or (target.memory != null and GameState.has_memory(target.memory.id))
		if known:
			target.mark_identified(true)
	if GameState.door_opened:
		door.set_open_immediately()
	else:
		door.interactable.enabled = GameState.handle_identified
	for examinable in $Discoveries.get_children():
		(examinable as Examinable).refresh_from_save()
	for pickup in $Pickups.get_children():
		(pickup as FilamentPickup).refresh()
	_refresh_equipment()
	_update_printer_prompt()


## Apparence de Nin0 selon ses améliorations (canon installé, Armure I équipée).
func _refresh_equipment() -> void:
	var visual := nino.get_visual()
	visual.set_cannon_installed(GameState.has_cannon())
	visual.set_armor_visible(GameState.is_equipped(&"armor_1"))


func _set_sleeping() -> void:
	nino.controls_enabled = false
	camera.input_enabled = false
	pause_menu.allowed = false
	nino.get_visual().set_power(0.0)


## Réveil : l'écran vacille, Nin0 est d'abord confus, puis curieux.
func _boot_nino() -> void:
	_sequence_running = true
	hud.clear_hint()
	var visual := nino.get_visual()
	Sfx.play(&"boot", -4.0)
	var flicker := create_tween()
	for value in [0.6, 0.0, 0.9, 0.2, 1.0]:
		flicker.tween_callback(visual.set_power.bind(value))
		flicker.tween_interval(0.12)
	await flicker.finished
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 0.8)
	thoughts.think([&"ellipsis"], "", 1.6)
	await _wait(1.4)
	visual.look_target = nino.global_position + nino.global_basis * Vector3(-1.5, 0.4, -1.0)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.4)
	Sfx.play(&"curious", -8.0)
	thoughts.think([&"question"], "", 1.6)
	await _wait(1.0)
	visual.look_target = nino.global_position + nino.global_basis * Vector3(1.5, 0.3, -1.0)
	await _wait(1.0)
	visual.look_target = null
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.2)
	Sfx.play(&"happy", -6.0)
	var move_camera := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	move_camera.tween_property(camera, "rotation:y", nino.rotation.y, 2.0)
	move_camera.tween_property(camera, "arm_length", GAMEPLAY_ARM, 2.0)
	move_camera.tween_property(camera, "pitch", deg_to_rad(-18.0), 2.0)
	await move_camera.finished
	GameState.set_flag(&"woke_up")
	_enable_play()
	hud.set_mode("Roues")
	_start_tutorial_step(Tutorial.FORWARD)
	_start_exploration_music()
	play_began.emit()


## L'introduction s'arrête, « Petit Refuge » (placard et sas) prend le relais.
## Le jeu complet choisit ensuite la musique selon la zone (game_world.gd).
func _start_exploration_music() -> void:
	Music.play(&"hub", Music.DEFAULT_VOLUME, 2.0)


func _enable_play() -> void:
	_sequence_running = false
	nino.controls_enabled = true
	camera.input_enabled = true
	pause_menu.allowed = true
	camera.capture_mouse()


func _disable_play() -> void:
	_sequence_running = true
	nino.controls_enabled = false
	camera.input_enabled = false
	pause_menu.allowed = false
	hud.hide_prompt()


# --- Mini-tutoriel : avancer, reculer, orienter la caméra --------------------------------

func _start_tutorial_step(step: Tutorial) -> void:
	_tutorial = step
	_step_distance = 0.0
	_turned = 0.0
	_last_position = nino.global_position
	_last_yaw = camera.rotation.y
	match step:
		Tutorial.FORWARD:
			hud.show_hint("%s : avancer" % Hud.key("Z"))
		Tutorial.BACK:
			hud.show_hint("%s : reculer" % Hud.key("S"))
		Tutorial.CAMERA:
			hud.show_hint("%s : orienter la caméra" % Hud.key("Souris"))
		Tutorial.DONE:
			hud.clear_hint()
			GameState.set_flag(&"tutorial_done")
			# Nin0 remarque la machine au bout de la table : un premier but visuel.
			nino.get_visual().look_target = printer.global_position + Vector3.UP * 1.5
			thoughts.think([&"eye", &"printer"], "", 2.4)
			await _wait(2.0)
			nino.get_visual().look_target = null


func _update_tutorial(_delta: float) -> void:
	if _tutorial in [Tutorial.NONE, Tutorial.DONE] or _sequence_running:
		return
	var moved := Vector2(nino.global_position.x - _last_position.x, nino.global_position.z - _last_position.z).length()
	_last_position = nino.global_position
	match _tutorial:
		Tutorial.FORWARD:
			if Input.is_action_pressed("move_forward"):
				_step_distance += moved
			if _step_distance > 1.2:
				_complete_tutorial_step(Tutorial.BACK)
		Tutorial.BACK:
			if Input.is_action_pressed("move_back"):
				_step_distance += moved
			if _step_distance > 0.8:
				_complete_tutorial_step(Tutorial.CAMERA)
		Tutorial.CAMERA:
			_turned += absf(wrapf(camera.rotation.y - _last_yaw, -PI, PI))
			_last_yaw = camera.rotation.y
			if _turned > 1.0:
				_complete_tutorial_step(Tutorial.DONE)


func _complete_tutorial_step(next: Tutorial) -> void:
	Sfx.play(&"tutorial_ok", -6.0)
	_start_tutorial_step(next)


func _any_move_pressed() -> bool:
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			return true
	return false


## Pensée affichée une seule fois par partie.
func _think_once(id: StringName, icons: Array, text := "", duration := 2.6) -> bool:
	if _thoughts_shown.has(id):
		return false
	_thoughts_shown[id] = true
	thoughts.think(icons, text, duration)
	return true


func _hint_once(id: StringName, bbcode: String, duration := 5.0) -> void:
	if _thoughts_shown.has(id):
		return
	_thoughts_shown[id] = true
	hud.show_hint(bbcode, duration)


# --- Interactions et découvertes --------------------------------------------------------

func _on_focus_changed(target: Interactable) -> void:
	if target:
		hud.show_prompt("E", target.prompt)
	else:
		hud.hide_prompt()


func _on_examined(data: DiscoveryData) -> void:
	var visual := nino.get_visual()
	if GameState.add_discovery(data.id):
		hud.show_toast("Découverte : %s" % data.title, 2.0)
		if String(data.id).begins_with("plan_"):
			Sfx.jingle(&"jingle_plan")
		else:
			Sfx.play(&"pickup" if data.collectible else &"discovery", -6.0)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think(data.thought_icons, data.thought_text, 2.4, true)
	if not data.conclusion_icons.is_empty():
		thoughts.think(data.conclusion_icons, data.conclusion_text, 2.6)


func _on_printer_interacted(_by: Node3D) -> void:
	GameState.set_flag(&"printer_seen")
	_disable_play()
	if printer.is_powered() and not GameState.printer_understood:
		# Observer → comprendre : la machine fabrique des pièces.
		var visual := nino.get_visual()
		visual.look_target = printer.global_position + Vector3(0.0, 1.2, 0.0)
		visual.show_emotion(NinoVisual.Emotion.CURIOUS, 4.0)
		thoughts.think([&"eye", &"printer"], "", 1.6, true)
		await _wait(2.1)
		thoughts.think([&"printer", &"arrow", &"gear"], "Elle fabrique…", 1.8)
		await _wait(2.3)
		visual.look_target = null
		GameState.set_flag(&"printer_understood")
	if GameState.injured:
		printer_panel.open(true, true, REPAIR_COST, _printer_upgrades())
	else:
		printer_panel.open(printer.is_powered(), GameState.legs_printed)


func _on_panel_closed() -> void:
	_enable_play()
	if not GameState.power_on:
		# Observer → comprendre : pas d'énergie, d'où vient-elle ?
		nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
		thoughts.think([&"printer", &"cross", &"energy"], "Pas d'énergie…", 2.2, true)
		# Le regard suit le câble qui part de la machine.
		_glance(Vector3(1.6, 8.3, -14.3), 2.4)
		thoughts.think([&"plug", &"question"], "Le câble…", 2.4)
	elif GameState.injured and not GameState.repaired and GameState.fragments < REPAIR_COST:
		# Pas assez de filament : Nin0 regarde autour de lui.
		nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
		thoughts.think([&"filament", &"question"], "", 2.4, true)
	_update_printer_prompt()


func _on_print_requested() -> void:
	_enable_play()
	GameState.set_flag(&"printing")
	printer.interactable.enabled = false
	printer.start_print()
	nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 3.0)
	thoughts.think([&"legs", &"arrow", &"robot"], "Pour moi ?", 2.6, true)


func _on_print_progressed(progress: float) -> void:
	var percent := int(progress * 100.0)
	if percent != _last_print_percent:
		_last_print_percent = percent
		GameState.set_print_progress(progress)


func _on_print_finished() -> void:
	GameState.printing = false
	GameState.set_flag(&"legs_printed")
	nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	hud.show_toast("Impression terminée", 2.5)
	notebook.interactable.enabled = true
	thoughts.think([&"legs", &"exclamation"], "", 2.0, true)
	thoughts.think([&"up", &"question"], "Comment monter ?", 2.6)
	await _wait(1.0)
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	Sfx.play(&"happy", -6.0)


func _on_notebook_toppled() -> void:
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	thoughts.think([&"idea"], "", 2.0, true)


## Nin0 est sur le plateau : la machine le détecte et installe les jambes.
func _install_legs() -> void:
	_disable_play()
	thoughts.think([&"printer", &"robot", &"question"], "", 1.8, true)
	var frame := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	frame.tween_property(camera, "rotation:y", deg_to_rad(38.0), 1.0)
	frame.tween_property(camera, "arm_length", 1.5, 1.0)
	frame.tween_property(camera, "pitch", deg_to_rad(-16.0), 1.0)
	await printer.install_legs(nino)
	nino.legs_available = true
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	Sfx.jingle(&"jingle_install")
	GameState.set_flag(&"legs_installed")
	nino.set_checkpoint(_checkpoint("Printer"))
	hud.show_toast("Jambes mécaniques installées", 3.0)
	thoughts.think([&"legs", &"check"], "", 2.0)
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", GAMEPLAY_ARM, 0.8)
	await back.finished
	_enable_play()
	hud.show_hint("%s : déployer les jambes (à l'arrêt)" % Hud.key("F"))


func _on_power_switched_on() -> void:
	GameState.set_flag(&"power_on")
	nino.set_checkpoint(_checkpoint("Floor"))
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	thoughts.think([&"question"], "", 1.2, true)
	await _wait(0.6)
	# L'imprimante, là-haut, s'éveille : Nin0 fait le lien entre les deux appareils.
	printer.set_powered(true)
	visual.look_target = printer.global_position + Vector3.UP
	await _wait(1.0)
	thoughts.think([&"plug", &"arrow", &"printer", &"energy"], "", 2.6)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.8)
	Sfx.play(&"happy", -6.0)
	await _wait(1.6)
	visual.look_target = null
	_update_printer_prompt()
	# Remonter : un regard vers la planche à repasser, sans indication écrite.
	_glance(Vector3(13.5, 4.0, -3.0), 2.0)
	thoughts.think([&"up", &"question"], "", 2.2)


func _on_spool_slotted(_spool: PushableSpool) -> void:
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	thoughts.think([&"spool", &"check"], "", 2.0, true)


func _on_nino_respawned() -> void:
	# Une bobine mal placée revient à sa place quand Nin0 revient au point sûr.
	for spool in spools:
		(spool as PushableSpool).reset()
	camera.snap_to_target()


func _update_printer_prompt() -> void:
	# Après l'installation des jambes, la machine sert de nouveau une fois Nin0 abîmé.
	if GameState.legs_installed:
		printer.interactable.enabled = GameState.injured
	if GameState.power_on:
		printer.interactable.prompt = "Utiliser l'imprimante"
	else:
		printer.interactable.prompt = "Examiner l'imprimante"
	_interactor.refresh()


# --- Nin0 ------------------------------------------------------------------------

func _on_nino_state_changed(state: NinoController.State) -> void:
	if state == NinoController.State.CLIMBING:
		_hint_once(&"climb_controls", "%s / %s : monter et descendre    ·    %s : lâcher prise" % [Hud.key("Z"), Hud.key("S"), Hud.key("C")], 6.0)


func _on_mode_changed(mode: NinoController.Mode) -> void:
	hud.set_mode("Jambes" if mode == NinoController.Mode.LEGS else "Roues")
	if mode == NinoController.Mode.LEGS and not GameState.legs_deployed_once:
		GameState.set_flag(&"legs_deployed_once")
		_first_steps_reaction()


## Premiers pas : Nin0 découvre ses jambes (surprise, regard vers le bas, curiosité).
func _first_steps_reaction() -> void:
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	visual.react_to_landing(6.0)
	visual.look_target = nino.global_position + nino.global_basis * Vector3(0.0, -0.4, -0.6)
	Sfx.play(&"surprised", -6.0)
	thoughts.think([&"legs", &"exclamation"], "", 1.8, true)
	await _wait(1.4)
	visual.look_target = null
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	thoughts.think([&"happy"], "", 1.6)
	hud.show_toast("Mode jambes", 2.0)
	hud.show_hint("%s : sauter    ·    %s : revenir aux roues" % [Hud.key("Espace"), Hud.key("F")], 7.0)


# --- Zones ----------------------------------------------------------------------

func _on_zone_entered(zone: TriggerZone) -> void:
	if _sequence_running or not GameState.woke_up:
		return
	match zone.id:
		&"floor":
			if not GameState.power_on:
				nino.set_checkpoint(_checkpoint("Floor"))
		&"cable_hint":
			if GameState.printer_seen and not GameState.power_on:
				_think_once(&"cable", [&"plug", &"down"], "Où va-t-il ? Plus bas ?", 2.6)
		&"under_bench":
			if not GameState.power_on:
				_think_once(&"strip", [&"plug", &"exclamation"], "", 2.2)
		&"ramp_bottom":
			if GameState.power_on and not spool_slot.is_filled():
				_think_once(&"ramp", [&"up"], "", 1.8)
		&"spools":
			if not spool_slot.is_filled():
				_think_once(&"spools", [&"spool", &"arrow", &"question"], "Légère ?", 2.6)
		&"notch":
			if not spool_slot.is_filled():
				_hint_once(&"stuck", "%s : revenir au dernier point sûr" % Hud.key("R"), 5.0)
		&"printer_front":
			if GameState.power_on and not GameState.printer_understood:
				_think_once(&"printer_powered", [&"printer", &"energy"], "", 2.0)
		&"bench_top":
			if GameState.power_on and not GameState.legs_installed:
				nino.set_checkpoint(_checkpoint("Printer"))
		&"window_steps":
			if not GameState.legs_installed:
				_think_once(&"too_high", [&"up", &"question"], "Trop haut…", 2.4)
		&"window_sill":
			if GameState.legs_installed and not GameState.reached_window:
				_reach_window()
		&"shelf_steps":
			if GameState.handle_identified:
				_think_once(&"shelf_route", [&"up", &"handle"], "", 2.2)
		&"shelf_top":
			if GameState.handle_identified and not GameState.injured:
				nino.set_checkpoint(_checkpoint("Shelf"))
		&"drawing":
			if GameState.has_memory(drawing_focus.id):
				return
			if not focus_vision.unlocked:
				# Un dessin d'enfant : Nin0 le remarque, sans savoir pourquoi.
				if _think_once(&"drawing_seen", [&"eye", &"question"], "", 2.2):
					_glance(drawing_focus.global_position, 1.8)
			elif not _thoughts_shown.has(&"drawing_signal"):
				# Vision disponible : un faible signal, l'écran du visage grésille.
				_thoughts_shown[&"drawing_signal"] = true
				nino.get_visual().glitch_pulse(0.6, 0.4)
				Sfx.play(&"signal", -16.0)
				_glance(drawing_focus.global_position, 1.6)
		&"chair_route":
			if GameState.injured and not GameState.repaired and nino.mode == NinoController.Mode.LEGS:
				if _think_once(&"chair_route", [&"book", &"up"], "", 2.2):
					_glance(Vector3(-9.5, 7.0, -6.0), 1.8)
		&"doorway":
			if GameState.repaired and embedded:
				# Jeu complet : on franchit le seuil vers le sas, rien ne s'arrête.
				if not GameState.demo_completed:
					GameState.set_flag(&"demo_completed")
			elif GameState.repaired:
				_finish_demo()
			elif GameState.injured:
				_think_once(&"doorway_hurt", [&"robot", &"damage", &"printer"], "", 2.4)


## Au rebord de la fenêtre, Nin0 remarque quelque chose au loin : il plisse les yeux,
## force sa vue, son système optique réagit et se calibre. Nouvelle capacité.
func _reach_window() -> void:
	GameState.set_flag(&"reached_window")
	nino.set_checkpoint(_checkpoint("Window"))
	_disable_play()
	var visual := nino.get_visual()
	var target := door.get_grip_position()
	var to_door := target - nino.global_position
	var turn := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	turn.tween_property(camera, "rotation:y", atan2(-to_door.x, -to_door.z) + 0.25, 1.4)
	turn.tween_property(camera, "pitch", deg_to_rad(-6.0), 1.4)
	visual.look_target = target
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think([&"eye", &"question"], "", 1.8, true)
	await _wait(1.6)
	# Les yeux se plissent : il essaie de mieux voir.
	for i in 2:
		visual.show_emotion(NinoVisual.Emotion.FOCUSED, 0.7)
		Sfx.play(&"servo", -18.0, 1.8)
		await _wait(0.8)
		visual.show_emotion(NinoVisual.Emotion.NEUTRAL, 0.25)
		await _wait(0.3)
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 2.0)
	visual.glitch_pulse(0.5, 0.3)
	Sfx.play(&"optic", -6.0)
	await focus_vision.overlay.play_calibration()
	visual.look_target = null
	focus_vision.unlocked = true
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.2)
	hud.show_toast("Nouvelle capacité : vision focalisée", 2.5)
	_enable_play()
	hud.show_hint("Maintenez %s ou %s : vision focalisée" % [Hud.key("clic droit"), Hud.key("Maj")], 7.0)


func _on_focus_target_identified(target: FocusTarget) -> void:
	if target.memory != null:
		_acquire_memory(target.memory)
	elif target.id == &"door_handle" and not GameState.handle_identified:
		GameState.set_flag(&"handle_identified")
		door.interactable.enabled = not GameState.door_opened
		hud.show_toast("Poignée repérée", 2.0)
		hud.clear_hint()
		_pending_handle_thought = true


## Souvenir : signal, parasites, fragments de mots, Nin0 cherche à comprendre.
func _acquire_memory(memory: MemoryData) -> void:
	if not GameState.add_memory(memory.id):
		return
	_disable_play()
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	visual.glitch_pulse(1.0, 1.0)
	await _wait(0.6)
	await memory_player.play(memory, GameState.memory_count(), GameState.ARCHIVE.total, GameState.memory_corruption())
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.4)
	visual.glitch_pulse(0.4, 0.3)
	# Le commentaire de Nin0 vient des données du souvenir (conservé dans les archives).
	thoughts.think([&"question"], memory.comment, 2.6, true)
	await _wait(1.8)
	_enable_play()


func _on_focus_changed_mode(active: bool) -> void:
	if not active and _pending_handle_thought:
		_pending_handle_thought = false
		nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
		thoughts.think([&"handle", &"exclamation"], "", 2.0, true)
		thoughts.think([&"robot", &"up", &"handle"], "Je peux l'atteindre ?", 2.8)
		await _wait(1.0)
		# Le regard passe des boîtes à l'étagère : le chemin se devine.
		_glance(Vector3(-13.8, 9.2, -10.0), 1.2)
		await _wait(1.2)
		_glance(Vector3(-13.8, 10.2, -3.0), 1.4)


## Nin0 saisit le levier ; son poids l'abaisse et le pêne se libère. La porte
## s'ouvre d'un coup : Nin0 lâche prise, chute réellement jusqu'au sol et s'abîme.
func _open_door() -> void:
	_disable_play()
	GameState.set_flag(&"door_opened")
	integrity.enabled = false
	nino.begin_scripted()
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 1.0)
	var shot := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shot.tween_property(camera, "rotation:y", deg_to_rad(127.0), 1.2)
	shot.tween_property(camera, "pitch", deg_to_rad(-10.0), 1.2)
	shot.tween_property(camera, "arm_length", 4.0, 1.2)
	# Juste avant le saut décisif.
	thoughts.think([&"exclamation"], "LEEEROOOY JENKINS !", 1.6, true)
	await _wait(1.0)
	await _leap(nino.global_position, door.get_grip_position() + Vector3.DOWN * 0.55, 0.55)
	await door.pull_lever(nino)
	# La porte s'ouvre : secousse, Nin0 perd l'équilibre.
	door.swing_open()
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.5)
	await _wait(0.45)
	Sfx.play(&"surprised", -4.0)
	Sfx.play(&"cartoon_fall", -6.0)
	visual.glitch_pulse(0.4, 0.3)
	var follow := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	follow.tween_property(camera, "pitch", deg_to_rad(-32.0), 0.9)
	follow.tween_property(camera, "arm_length", 3.0, 0.9)
	nino.end_scripted()
	nino.velocity = Vector3(1.7, 0.8, 0.3)
	var landed := [false]
	var on_land := func(_speed: float) -> void: landed[0] = true
	nino.landed.connect(on_land, CONNECT_ONE_SHOT)
	await _wait(0.2)
	await _wait_until(3.0, func() -> bool: return landed[0] or (nino.is_on_floor() and nino.global_position.y < 1.0))
	if nino.landed.is_connected(on_land):
		nino.landed.disconnect(on_land)
	await _injury_reaction()


## Blessure : choc, étincelles, écran parasité, yeux étourdis, relevé difficile ;
## Nin0 comprend qu'il est abîmé et pense à l'imprimante. Empathie, pas punition.
func _injury_reaction() -> void:
	nino.begin_scripted()
	var visual := nino.get_visual()
	Sfx.play(&"impact", -2.0)
	integrity.take_damage(DOOR_FALL_DAMAGE, true)
	GameState.set_flag(&"injured")
	nino.set_checkpoint(_checkpoint("FallSpot"))
	visual.set_tilt(75.0)
	visual.emit_sparks(22)
	visual.glitch_pulse(1.0, 1.4)
	visual.show_emotion(NinoVisual.Emotion.DIZZY, 3.2)
	await _wait(1.0)
	Sfx.play(&"grind", -6.0)
	await _wait(2.0)
	# Relevé difficile : un premier essai échoue.
	visual.set_tilt(35.0)
	Sfx.play(&"servo", -10.0, 0.6)
	await _wait(0.5)
	visual.set_tilt(65.0)
	Sfx.play(&"thud", -10.0)
	visual.glitch_pulse(0.7, 0.4)
	await _wait(0.9)
	visual.set_tilt(0.0)
	Sfx.play(&"servo", -8.0, 0.8)
	visual.react_to_landing(5.0)
	await _wait(0.8)
	var settle := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	settle.tween_property(camera, "pitch", deg_to_rad(-18.0), 1.0)
	settle.tween_property(camera, "arm_length", GAMEPLAY_ARM, 1.0)
	visual.show_emotion(NinoVisual.Emotion.HURT, 1.6)
	visual.look_target = nino.global_position + nino.global_basis * Vector3(0.0, -0.5, -0.4)
	thoughts.think([&"robot", &"damage"], "…", 2.4, true)
	await _wait(2.4)
	# Il se souvient de la machine qui l'a assemblé.
	visual.look_target = printer.global_position + Vector3.UP
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	thoughts.think([&"printer", &"wrench"], "", 2.4)
	await _wait(2.0)
	visual.look_target = null
	_update_printer_prompt()
	nino.end_scripted()
	integrity.enabled = true
	_enable_play()


## Arrivée sur le seuil, réparé : Nin0 regarde le sas, la démo se termine.
func _finish_demo() -> void:
	_disable_play()
	nino.begin_scripted()
	var visual := nino.get_visual()
	var threshold := Vector3(-14.9, nino.global_position.y, clampf(nino.global_position.z, 3.0, 8.0))
	var shot := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shot.tween_property(camera, "rotation:y", PI / 2.0 - 0.35, 1.6)
	shot.tween_property(camera, "pitch", deg_to_rad(-8.0), 1.6)
	shot.tween_property(camera, "arm_length", 2.6, 1.6)
	shot.tween_property(nino, "global_position", threshold, 1.6)
	shot.tween_property(nino, "rotation:y", PI / 2.0, 0.8)
	await shot.finished
	visual.look_target = threshold + Vector3(-6.0, 1.5, 0.0)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	hud.set_gameplay_visible(false)
	thoughts.think([&"door", &"eye"], "", 2.0, true)
	await _wait(2.2)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 3.0)
	Sfx.play(&"happy", -6.0)
	await _wait(1.4)
	GameState.set_flag(&"demo_completed")
	Sfx.stop_loop(&"wheels")
	end_screen.show_end()


# --- Réparation et améliorations (imprimante) ------------------------------------------

## Améliorations fabricables dont le plan est connu (ordre du catalogue).
func _printer_upgrades() -> Array[UpgradeData]:
	var list: Array[UpgradeData] = []
	for upgrade in UpgradeCatalog.all():
		if upgrade.fabricable and GameState.has_discovery(upgrade.required_discovery):
			list.append(upgrade)
	return list


func _on_repair_requested() -> void:
	if not GameState.spend_fragments(REPAIR_COST):
		_enable_play()
		return
	_disable_play()
	var start := GameState.integrity
	var duration := FIRST_REPAIR_DURATION if GameState.repairs_done == 0 else REPAIR_DURATION
	var on_progress := func(p: float) -> void:
		GameState.restore_integrity(lerpf(start, GameState.integrity_max, p))
	printer.service_progressed.connect(on_progress)
	thoughts.think([&"printer", &"robot", &"wrench"], "", 1.8, true)
	await printer.service(nino, duration)
	printer.service_progressed.disconnect(on_progress)
	GameState.complete_repair()
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	Sfx.play(&"happy", -4.0)
	hud.show_toast("Intégrité restaurée", 2.5)
	thoughts.think([&"robot", &"check"], "", 2.0)
	await _wait(1.6)
	thoughts.think([&"door", &"question"], "", 2.2)
	_update_printer_prompt()
	_enable_play()


func _on_upgrade_requested(id: StringName) -> void:
	var upgrade := UpgradeCatalog.find(id)
	if upgrade == null or not GameState.repaired or GameState.has_upgrade(id) \
			or not GameState.spend_fragments(upgrade.cost_fragments):
		_enable_play()
		return
	_disable_play()
	if upgrade.id == &"cannon":
		await _fabricate_cannon(upgrade)
		return
	thoughts.think([&"printer", &"gear", &"robot"], "", 1.8, true)
	await printer.service(nino, UPGRADE_DURATION)
	GameState.add_upgrade(id)
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	Sfx.jingle(&"jingle_install")
	if upgrade.category == UpgradeData.Category.MODULE:
		# Module secondaire : fabriqué, puis équipé s'il reste un emplacement libre.
		var equipped := GameState.equip_module(id)
		hud.show_toast("%s fabriqué%s" % [upgrade.title, "e et équipée" if equipped else "e"], 3.0)
		module_fabricated.emit(upgrade)
	else:
		hud.show_toast("%s installé" % upgrade.title, 2.5)
	_enable_play()


## Canon : impression de la pièce, présentation, installation physique sur l'épaule.
func _fabricate_cannon(upgrade: UpgradeData) -> void:
	var visual := nino.get_visual()
	thoughts.think([&"printer", &"cannon", &"robot"], "", 1.8, true)
	var frame := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	frame.tween_property(camera, "arm_length", 1.4, 1.0)
	frame.tween_property(camera, "pitch", deg_to_rad(-20.0), 1.0)
	var part := CannonModel.new()
	await printer.fabricate_and_install(nino, part, visual.get_cannon_mount_position,
			func() -> void: visual.set_cannon_installed(true), 7.0)
	GameState.add_upgrade(upgrade.id)
	# Premier chargement : de quoi essayer le canon tout de suite (jamais bloquant).
	if GameState.ammo_plastic < 6:
		GameState.add_plastic(6 - GameState.ammo_plastic)
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 0.8)
	visual.look_target = visual.get_cannon_mount_position() + Vector3.UP * 0.05
	Sfx.play(&"surprised", -8.0)
	await _wait(0.9)
	visual.get_cannon().recoil()
	Sfx.play(&"servo", -10.0, 1.6)
	await _wait(0.5)
	visual.look_target = null
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 2.5)
	Sfx.jingle(&"jingle_install")
	thoughts.think([&"cannon", &"check"], "", 2.2)
	hud.show_toast("Canon à billes installé", 3.0)
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", GAMEPLAY_ARM, 0.8)
	await back.finished
	_enable_play()
	hud.show_hint("%s : tirer une bille    ·    vision focalisée pour viser" % Hud.key("clic gauche / X"), 7.0)
	cannon_installed.emit()


func _on_fragment_collected(_pickup: ResourcePickup) -> void:
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 0.8)


## Petit bond scripté en arc (séquences).
func _leap(from: Vector3, to: Vector3, duration: float) -> void:
	var apex := (from + to) * 0.5 + Vector3.UP * 0.7
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(t: float) -> void:
		nino.global_position = from.lerp(apex, t).lerp(apex.lerp(to, t), t)
	, 0.0, 1.0, duration)
	Sfx.play(&"jump", -8.0)
	await tween.finished


# --- Utilitaires ------------------------------------------------------------------

func _refresh_objective() -> void:
	hud.set_objective(GameState.get_objective())


func _checkpoint(marker_name: String) -> Transform3D:
	return (_checkpoints.get_node(marker_name) as Node3D).global_transform


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_until(timeout: float, condition: Callable) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if condition.call():
			return true
	return false


## Bref regard de Nin0 vers un point (indice visuel plutôt qu'écrit).
func _glance(point: Vector3, duration: float) -> void:
	var visual := nino.get_visual()
	visual.look_target = point
	await _wait(duration)
	if visual.look_target == point:
		visual.look_target = null
