extends Node3D
## Directeur de la première démo (atelier).
##
## Enchaîne : écran titre → réveil interactif → exploration → alimentation de
## l'imprimante → impression → installation des jambes → essai du mode jambes →
## rebord de la fenêtre → conclusion. Aucun élément de la suite (fourmis, combats).

const TITLE_CAMERA_YAW := deg_to_rad(65.0)
const GAMEPLAY_ARM := 1.8

var _title_active := false
var _title_time := 0.0
var _waiting_wake_input := false
var _sequence_running := false
var _tutorial_step := 0
var _tutorial_time := 0.0
var _moved := 0.0
var _turned := 0.0
var _last_position := Vector3.ZERO
var _last_yaw := 0.0
var _hints_shown := {}

@onready var nino: NinoController = $Nino
@onready var camera: ThirdPersonCamera = $ThirdPersonCamera
@onready var hud: Hud = $Hud
@onready var printer: Printer3D = $Printer3D
@onready var power_strip: PowerStrip = $PowerStrip
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
	_interactor.focus_changed.connect(_on_focus_changed)
	printer.interactable.interacted.connect(_on_printer_interacted)
	printer.print_finished.connect(_on_print_finished)
	power_strip.switched_on.connect(_on_power_switched_on)
	printer_panel.print_requested.connect(_on_print_requested)
	printer_panel.closed.connect(_on_panel_closed)
	title_screen.start_requested.connect(_on_start_requested)
	for zone in $Zones.get_children():
		(zone as TriggerZone).player_entered.connect(_on_zone_entered)
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
	nino.legs_available = true
	nino.get_visual().set_power(1.0)
	nino.global_transform = _checkpoint("Printer")
	nino.set_checkpoint(_checkpoint("Printer"))
	camera.rotation.y = 0.0
	camera.pitch = deg_to_rad(-18.0)
	camera.arm_length = GAMEPLAY_ARM
	camera.snap_to_target()
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


## Réveil : l'écran s'allume en vacillant, NINO regarde autour de lui, la caméra se place.
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
	await get_tree().create_timer(0.8).timeout
	visual.look_target = nino.global_position + nino.global_basis * Vector3(-1.5, 0.4, -1.0)
	visual.show_emotion(NinoVisual.Emotion.CURIOUS, 2.0)
	Sfx.play(&"curious", -8.0)
	await get_tree().create_timer(0.9).timeout
	visual.look_target = nino.global_position + nino.global_basis * Vector3(1.5, 0.3, -1.0)
	await get_tree().create_timer(0.9).timeout
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
	_tutorial_step = 1
	_last_position = nino.global_position
	hud.show_hint("%s ou flèches : rouler" % Hud.key("Z Q S D"))


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


# --- Tutoriel progressif ----------------------------------------------------------------

func _update_tutorial(delta: float) -> void:
	if _tutorial_step == 0 or _sequence_running:
		return
	_tutorial_time += delta
	match _tutorial_step:
		1:
			_moved += Vector2(nino.global_position.x - _last_position.x, nino.global_position.z - _last_position.z).length()
			_last_position = nino.global_position
			if _moved > 2.5:
				_tutorial_step = 2
				_tutorial_time = 0.0
				_last_yaw = camera.rotation.y
				hud.show_hint("%s : regarder autour" % Hud.key("Souris"))
		2:
			_turned += absf(wrapf(camera.rotation.y - _last_yaw, -PI, PI))
			_last_yaw = camera.rotation.y
			if _turned > 1.2 or _tutorial_time > 8.0:
				_tutorial_step = 0
				hud.clear_hint()


func _any_move_pressed() -> bool:
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			return true
	return false


func _hint_once(id: StringName, bbcode: String, duration := 5.0) -> void:
	if _hints_shown.has(id):
		return
	_hints_shown[id] = true
	hud.show_hint(bbcode, duration)


# --- Interactions -------------------------------------------------------------------

func _on_focus_changed(target: Interactable) -> void:
	if target:
		hud.show_prompt("E", target.prompt)
	else:
		hud.hide_prompt()


func _on_printer_interacted(_by: Node3D) -> void:
	if GameState.legs_printed and not GameState.legs_installed:
		_install_legs()
		return
	GameState.set_flag(&"printer_seen")
	_disable_play()
	hud.hide_prompt()
	printer_panel.open(printer.is_powered(), GameState.legs_printed)


func _on_panel_closed() -> void:
	_enable_play()
	if not GameState.power_on:
		hud.show_hint("L'imprimante n'est pas alimentée. Son câble descend au bout de l'établi…", 6.0)
	_update_printer_prompt()


func _on_print_requested() -> void:
	_enable_play()
	GameState.set_flag(&"printing")
	printer.interactable.enabled = false
	printer.start_print()
	nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 3.0)
	hud.show_hint("L'impression commence…", 3.0)


func _on_print_finished() -> void:
	GameState.printing = false
	GameState.set_flag(&"legs_printed")
	nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.0)
	hud.show_toast("Impression terminée", 2.5)
	printer.interactable.enabled = true
	_update_printer_prompt()
	await get_tree().create_timer(1.0).timeout
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	Sfx.play(&"happy", -6.0)


func _install_legs() -> void:
	_disable_play()
	hud.hide_prompt()
	printer.interactable.enabled = false
	# NINO se tourne vers l'imprimante ; la caméra se place de trois quarts.
	var face := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	face.tween_property(nino, "rotation:y", 0.0, 0.5)
	face.tween_property(camera, "rotation:y", deg_to_rad(40.0), 1.0)
	face.tween_property(camera, "arm_length", 1.4, 1.0)
	await face.finished
	await printer.deliver_legs(nino.get_visual().get_leg_mount_positions())
	nino.legs_available = true
	nino.get_visual().react_to_jump()
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	Sfx.play(&"happy", -4.0)
	GameState.set_flag(&"legs_installed")
	nino.set_checkpoint(_checkpoint("Printer"))
	hud.show_toast("Jambes mécaniques installées", 3.0)
	await get_tree().create_timer(1.2).timeout
	var back := create_tween().set_trans(Tween.TRANS_SINE)
	back.tween_property(camera, "arm_length", GAMEPLAY_ARM, 0.8)
	await back.finished
	_enable_play()
	hud.show_hint("%s : déployer les jambes (à l'arrêt)" % Hud.key("F"))


func _on_power_switched_on() -> void:
	GameState.set_flag(&"power_on")
	printer.set_powered(true)
	_update_printer_prompt()
	nino.set_checkpoint(_checkpoint("Floor"))
	nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 1.5)
	Sfx.play(&"happy", -6.0)
	hud.show_toast("L'imprimante est sous tension", 2.5)
	hud.show_hint("Les cartons au bout de l'établi permettent de remonter.", 6.0)


func _update_printer_prompt() -> void:
	if GameState.legs_printed and not GameState.legs_installed:
		printer.interactable.prompt = "Récupérer les jambes"
	elif GameState.power_on:
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
		hud.show_toast("Mode jambes", 2.0)
		hud.show_hint("%s : sauter    ·    %s : revenir aux roues" % [Hud.key("Espace"), Hud.key("F")], 7.0)
		Sfx.play(&"happy", -6.0)


# --- Zones ----------------------------------------------------------------------

func _on_zone_entered(zone: TriggerZone) -> void:
	if _sequence_running or not GameState.woke_up:
		return
	match zone.id:
		&"floor":
			if not GameState.power_on:
				nino.set_checkpoint(_checkpoint("Floor"))
				if GameState.printer_seen:
					_hint_once(&"follow_cable", "Le câble de l'imprimante longe le mur jusque sous l'établi.", 6.0)
		&"climb_hint":
			_hint_once(&"climb", "Roulez contre le carton pour l'escalader.", 5.0)
		&"under_bench":
			if not GameState.power_on:
				_hint_once(&"strip", "Une multiprise… éteinte.", 3.5)
		&"bench_top":
			if GameState.power_on and not GameState.legs_installed:
				nino.set_checkpoint(_checkpoint("Printer"))
		&"steps_hint":
			if GameState.legs_installed:
				_hint_once(&"steps_legs", "Sautez de marche en marche jusqu'au rebord de la fenêtre.", 5.0)
			else:
				_hint_once(&"steps_wheels", "Trop haut pour des roues… pour l'instant.", 4.0)
		&"window_sill":
			if GameState.legs_installed and not GameState.demo_completed:
				_end_demo()


func _end_demo() -> void:
	GameState.set_flag(&"demo_completed")
	_disable_play()
	hud.set_gameplay_visible(false)
	Sfx.stop_loop(&"wheels")
	var visual := nino.get_visual()
	visual.look_target = nino.global_position + Vector3(-3.0, 1.5, 0.0)
	visual.show_emotion(NinoVisual.Emotion.HAPPY, 6.0)
	Sfx.play(&"happy", -6.0)
	var shot := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shot.tween_property(nino, "rotation:y", deg_to_rad(90.0), 1.0)
	shot.tween_property(camera, "rotation:y", deg_to_rad(110.0), 4.0)
	shot.tween_property(camera, "pitch", deg_to_rad(5.0), 4.0)
	shot.tween_property(camera, "arm_length", 2.6, 4.0)
	await get_tree().create_timer(4.5).timeout
	end_screen.show_end()


# --- Utilitaires ------------------------------------------------------------------

func _refresh_objective() -> void:
	hud.set_objective(GameState.get_objective())


func _checkpoint(marker_name: String) -> Transform3D:
	return (_checkpoints.get_node(marker_name) as Node3D).global_transform
