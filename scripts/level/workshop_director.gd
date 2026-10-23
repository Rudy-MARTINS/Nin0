extends Node3D
## Directeur de la première démo (placard-hub).
##
## Fil conducteur : NINO observe → comprend → agit. Ses pensées (bulles) disent ce
## qu'il remarque ou déduit ; l'objectif (HUD) dit ce que le joueur cherche à faire.
##
## Déroulement : titre → réveil → mini-tutoriel → imprimante hors tension → câble →
## multiprise → retour par les bobines → compréhension de l'imprimante → impression →
## carnet renversé → installation sur le plateau → premiers pas → fenêtre → vision
## focalisée sur la poignée → étagère → la porte s'ouvre → fin.
## Rien de la suite (fourmis, combats, autres pièces) n'est présent.

const TITLE_CAMERA_YAW := deg_to_rad(65.0)
const GAMEPLAY_ARM := 1.8

enum Tutorial { NONE, FORWARD, BACK, CAMERA, DONE }

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
	pause_menu.discovery_total = examinables.size()
	GameState.progress_changed.connect(_refresh_objective)

	Sfx.stop_all_loops()
	Sfx.set_loop(&"ambience", &"ambience", -18.0)
	nino.set_checkpoint(_checkpoint("Start"))
	_set_sleeping()

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
	# Installation des jambes : NINO doit se trouver sur le plateau d'impression.
	if not _sequence_running and GameState.legs_printed and not GameState.legs_installed \
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
	hud.show_hint("Appuyez sur %s pour réveiller NINO" % Hud.key("Z Q S D"))
	_waiting_wake_input = true


func _start_from_save() -> void:
	GameState.load_save()
	power_strip.set_on_immediately()
	printer.set_completed()
	printer.interactable.enabled = false
	notebook.set_toppled_immediately()
	spool_slot.fill_immediately(spools[0])
	nino.legs_available = true
	nino.get_visual().set_power(1.0)
	nino.global_transform = _checkpoint("Printer")
	nino.set_checkpoint(_checkpoint("Printer"))
	camera.rotation.y = 0.0
	camera.pitch = deg_to_rad(-18.0)
	camera.arm_length = GAMEPLAY_ARM
	camera.snap_to_target()
	_tutorial = Tutorial.DONE
	_enable_play()
	hud.set_fade(1.0)
	hud.fade_to(0.0, 1.0)
	hud.set_mode("Roues")
	_refresh_objective()
	hud.show_hint("%s : déployer les jambes (à l'arrêt)" % Hud.key("F"), 6.0)


func _set_sleeping() -> void:
	nino.controls_enabled = false
	camera.input_enabled = false
	pause_menu.allowed = false
	nino.get_visual().set_power(0.0)


## Réveil : l'écran vacille, NINO est d'abord confus, puis curieux.
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
			# NINO remarque la machine au bout de la table : un premier but visuel.
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
	printer_panel.open(printer.is_powered(), GameState.legs_printed)


func _on_panel_closed() -> void:
	_enable_play()
	if not GameState.power_on:
		# Observer → comprendre : pas d'énergie, d'où vient-elle ?
		nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
		thoughts.think([&"printer", &"cross", &"energy"], "", 2.2, true)
		thoughts.think([&"plug", &"question"], "D'où vient l'énergie ?", 2.6)
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


## NINO est sur le plateau : la machine le détecte et installe les jambes.
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
	Sfx.play(&"happy", -4.0)
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
	# L'imprimante, là-haut, s'éveille : NINO fait le lien entre les deux appareils.
	printer.set_powered(true)
	visual.look_target = printer.global_position + Vector3.UP
	await _wait(1.0)
	thoughts.think([&"plug", &"arrow", &"printer", &"energy"], "", 2.6)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 1.8)
	Sfx.play(&"happy", -6.0)
	await _wait(1.6)
	visual.look_target = null
	_update_printer_prompt()
	_hint_once(&"way_up", "Pour remonter sur la table, cherchez un passage le long du mur de droite.", 6.0)


func _on_spool_slotted(_spool: PushableSpool) -> void:
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	thoughts.think([&"spool", &"check"], "", 2.0, true)


func _on_nino_respawned() -> void:
	# Une bobine mal placée revient à sa place quand NINO revient au point sûr.
	for spool in spools:
		(spool as PushableSpool).reset()
	camera.snap_to_target()


func _update_printer_prompt() -> void:
	if GameState.power_on:
		printer.interactable.prompt = "Utiliser l'imprimante"
	else:
		printer.interactable.prompt = "Examiner l'imprimante"
	_interactor.refresh()


# --- NINO ------------------------------------------------------------------------

func _on_nino_state_changed(state: NinoController.State) -> void:
	if state == NinoController.State.CLIMBING:
		_hint_once(&"climb_controls", "%s / %s : monter et descendre    ·    %s : lâcher prise" % [Hud.key("Z"), Hud.key("S"), Hud.key("C")], 6.0)


func _on_mode_changed(mode: NinoController.Mode) -> void:
	hud.set_mode("Jambes" if mode == NinoController.Mode.LEGS else "Roues")
	if mode == NinoController.Mode.LEGS and not GameState.legs_deployed_once:
		GameState.set_flag(&"legs_deployed_once")
		_first_steps_reaction()


## Premiers pas : NINO découvre ses jambes (surprise, regard vers le bas, curiosité).
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
				_think_once(&"cable", [&"plug", &"down"], "Le câble descend…", 2.6)
		&"under_bench":
			if not GameState.power_on:
				_think_once(&"strip", [&"plug", &"exclamation"], "", 2.2)
		&"ramp_bottom":
			if GameState.power_on and not spool_slot.is_filled():
				_think_once(&"ramp", [&"up"], "", 1.8)
		&"spools":
			if not spool_slot.is_filled() and _think_once(&"spools", [&"spool", &"arrow", &"question"], "", 2.6):
				_hint_once(&"push", "Roulez contre une bobine pour la pousser.", 5.0)
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
			if GameState.handle_identified:
				nino.set_checkpoint(_checkpoint("Shelf"))


## Au rebord de la fenêtre, NINO remarque la grande porte du placard.
func _reach_window() -> void:
	GameState.set_flag(&"reached_window")
	nino.set_checkpoint(_checkpoint("Window"))
	focus_vision.unlocked = true
	var visual := nino.get_visual()
	visual.look_target = door.get_grip_position()
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 3.0)
	thoughts.think([&"door", &"question"], "", 2.6, true)
	await _wait(2.0)
	visual.look_target = null
	hud.show_hint("Maintenez %s (ou %s) pour observer la porte" % [Hud.key("clic droit"), Hud.key("Maj")])


func _on_focus_target_identified(target: FocusTarget) -> void:
	if target.id == &"door_handle" and not GameState.handle_identified:
		GameState.set_flag(&"handle_identified")
		door.interactable.enabled = true
		hud.show_toast("Poignée repérée", 2.0)
		hud.clear_hint()
		_pending_handle_thought = true


func _on_focus_changed_mode(active: bool) -> void:
	if not active and _pending_handle_thought:
		_pending_handle_thought = false
		nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
		thoughts.think([&"handle", &"exclamation"], "", 2.0, true)
		thoughts.think([&"robot", &"up", &"handle"], "Je peux l'atteindre ?", 2.8)
		await _wait(2.5)
		_hint_once(&"shelf_hint", "Les boîtes, au bout gauche de la table, mènent à l'étagère.", 6.0)


## NINO saisit le levier ; son poids l'abaisse et la porte s'ouvre.
func _open_door() -> void:
	_disable_play()
	GameState.set_flag(&"door_opened")
	nino.begin_scripted()
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.FOCUSED, 1.0)
	var start := nino.global_position
	var grip := door.get_grip_position() + Vector3.DOWN * 0.55
	var apex := (start + grip) * 0.5 + Vector3.UP * 0.8
	var leap := create_tween().set_trans(Tween.TRANS_SINE)
	leap.tween_method(func(t: float) -> void:
		nino.global_position = start.lerp(apex, t).lerp(apex.lerp(grip, t), t)
	, 0.0, 1.0, 0.55)
	Sfx.play(&"jump", -8.0)
	await leap.finished
	var shot := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shot.tween_property(camera, "rotation:y", deg_to_rad(70.0), 3.0)
	shot.tween_property(camera, "pitch", deg_to_rad(-8.0), 3.0)
	shot.tween_property(camera, "arm_length", 3.2, 3.0)
	await door.open(nino)
	hud.set_gameplay_visible(false)
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	visual.look_target = door.global_position + Vector3(-8.0, 3.0, -4.0)
	thoughts.think([&"eye", &"exclamation"], "", 2.0, true)
	await _wait(1.8)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 3.0)
	await _wait(1.2)
	GameState.set_flag(&"demo_completed")
	Sfx.stop_loop(&"wheels")
	end_screen.show_end()


# --- Utilitaires ------------------------------------------------------------------

func _refresh_objective() -> void:
	hud.set_objective(GameState.get_objective())


func _checkpoint(marker_name: String) -> Transform3D:
	return (_checkpoints.get_node(marker_name) as Node3D).global_transform


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
