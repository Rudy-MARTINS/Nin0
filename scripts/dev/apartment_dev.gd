extends Node3D
## MODE DÉVELOPPEMENT — exploration de l'appartement et scénarios du chapitre 2.
##
## Scène séparée du jeu normal : elle instancie le jeu complet (game.tscn) avec
## placard résolu, Nin0 complet (roues, jambes, vision), porte entrouverte ;
## GameState.dev_mode empêche toute écriture ou suppression de sauvegarde.
##
## Touches : 1–7 aller à une zone · F1 aide · F2 carte · F3 plafonds ·
## F4 caméra libre (Z Q S D, Espace / C, Maj = rapide) ·
## Ctrl + 1…7 : scénarios (rencontre du sas, labyrinthe gauche, labyrinthe droit,
## escabeau, boss, fabrication du canon, porte de la cuisine).
## Démarrer : propriétés `start_zone` / `scenario`, ou « -- --zone=6 », « -- --scenario=boss ».

@export_range(1, 7) var start_zone := 1
@export var free_camera_speed := 14.0
## Scénario de test préparé au démarrage (vide = aucun).
## sas, maze, right, stool, boss, cannon, kitchen (voir SCENARIOS).
@export var scenario := ""

const SCENARIOS := [&"sas", &"maze", &"right", &"stool", &"boss", &"cannon", &"kitchen"]

const ZONE_COLORS := {
	1: Color(0.85, 0.7, 0.45), 2: Color(0.72, 0.66, 0.56), 3: Color(0.55, 0.72, 0.8), 4: Color(0.78, 0.5, 0.38),
	5: Color(0.5, 0.75, 0.45), 6: Color(0.7, 0.58, 0.42), 7: Color(0.58, 0.52, 0.7),
}

var nino: NinoController
var camera: ThirdPersonCamera
var current_zone := 0

var _zones: Array[Area3D] = []
var _info: Label
var _help: Label
var _map: Control
var _free_cam: Camera3D
var _free := false
var _free_yaw := 0.0
var _free_pitch := 0.0

@onready var game: GameWorld = $Game
@onready var workshop: Node3D = $Game/Workshop
@onready var blockout: Node3D = $Game/Blockout


func _enter_tree() -> void:
	GameState.dev_mode = true


func _ready() -> void:
	nino = workshop.get_node("Nino")
	camera = workshop.get_node("ThirdPersonCamera")
	for zone in blockout.get_node("Zones").get_children():
		_zones.append(zone as Area3D)
	_build_hud()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			start_zone = clampi(int(arg.get_slice("=", 1)), 1, 7)
		elif arg.begins_with("--scenario="):
			scenario = arg.get_slice("=", 1)
	# Le directeur du placard prépare la session au premier passage ; on place ensuite Nin0.
	await get_tree().process_frame
	await get_tree().process_frame
	go_to_zone(start_zone)
	if scenario != "":
		game.run_dev_scenario(StringName(scenario))


func _process(delta: float) -> void:
	if _free:
		_move_free_camera(delta)
	var focus_point := _free_cam.global_position if _free else nino.global_position
	current_zone = zone_at(focus_point)
	_update_info(focus_point)
	if _map.visible:
		_map.queue_redraw()


## Téléporte Nin0 au point d'apparition d'une zone (sans rien sauvegarder).
func go_to_zone(number: int) -> void:
	var spawn := blockout.get_node_or_null("Spawns/Spawn%d" % number) as Marker3D
	if spawn == null:
		return
	if _free:
		_set_free_camera(false)
	nino.global_transform = spawn.global_transform
	nino.velocity = Vector3.ZERO
	nino.set_checkpoint(spawn.global_transform)
	camera.rotation.y = spawn.global_rotation.y
	camera.snap_to_target()


## Numéro de la zone contenant un point (0 = hors des zones).
func zone_at(point: Vector3) -> int:
	for zone in _zones:
		var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		var local := zone.to_local(point)
		if absf(local.x) <= box.size.x / 2 and absf(local.z) <= box.size.z / 2 and absf(local.y) <= box.size.y / 2:
			return int(zone.get_meta("number"))
	return 0


func get_zone(number: int) -> Area3D:
	for zone in _zones:
		if int(zone.get_meta("number")) == number:
			return zone
	return null


func _unhandled_input(event: InputEvent) -> void:
	if _free and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_free_yaw -= event.relative.x * 0.003
		_free_pitch = clampf(_free_pitch - event.relative.y * 0.003, -1.5, 1.5)
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or GameState.modal_open:
		return
	var code := key.physical_keycode
	if key.ctrl_pressed and code >= KEY_1 and code <= KEY_7:
		game.run_dev_scenario(SCENARIOS[code - KEY_1])
	elif code >= KEY_1 and code <= KEY_7:
		go_to_zone(code - KEY_0)
	elif key.keycode >= KEY_KP_1 and key.keycode <= KEY_KP_7:
		go_to_zone(key.keycode - KEY_KP_0)
	elif code == KEY_F1:
		_help.visible = not _help.visible
	elif code == KEY_F2:
		_map.visible = not _map.visible
	elif code == KEY_F3:
		toggle_ceilings()
	elif code == KEY_F4:
		_set_free_camera(not _free)
	else:
		return
	get_viewport().set_input_as_handled()


## Masque / affiche les plafonds (lecture des volumes depuis la caméra libre).
func toggle_ceilings() -> void:
	var ceilings := blockout.get_node("Ceilings")
	ceilings.visible = not ceilings.visible
	(workshop.get_node("Geometry/Ceiling") as Node3D).visible = ceilings.visible


func _set_free_camera(value: bool) -> void:
	_free = value
	nino.controls_enabled = not value
	camera.input_enabled = not value
	if value:
		var cam := camera.get_camera()
		_free_cam.global_transform = cam.global_transform
		_free_yaw = cam.global_rotation.y
		_free_pitch = cam.global_rotation.x
		_free_cam.make_current()
	else:
		camera.get_camera().make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _move_free_camera(delta: float) -> void:
	_free_cam.rotation = Vector3(_free_pitch, _free_yaw, 0.0)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var vertical := (1.0 if Input.is_action_pressed("jump") else 0.0) - (1.0 if Input.is_action_pressed("release_grip") else 0.0)
	var speed := free_camera_speed * (3.0 if Input.is_action_pressed("focus") else 1.0)
	var motion := _free_cam.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * vertical
	_free_cam.global_position += motion * speed * delta


# --- Interface de développement -------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var banner := _label(15, Color(1.0, 0.55, 0.35))
	banner.text = "MODE DÉVELOPPEMENT — appartement + chapitre 2 · aucune sauvegarde · F1 : aide"
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -360
	banner.offset_right = 360
	banner.offset_top = 6
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(banner)
	_info = _label(15, Color(1, 0.95, 0.85))
	_info.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info.offset_left = 28
	_info.offset_top = 40
	layer.add_child(_info)
	_help = _label(15, Color(1, 0.95, 0.85))
	_help.text = "1 à 7 (ou pavé numérique) : aller à une zone\nF2 : carte de l'appartement\nF3 : plafonds\nF4 : caméra libre (Z Q S D, Espace / C, Maj rapide)\nCtrl+1 rencontre du sas · Ctrl+2 labyrinthe gauche · Ctrl+3 labyrinthe droit\nCtrl+4 escabeau · Ctrl+5 reine · Ctrl+6 canon (imprimante) · Ctrl+7 porte cuisine\nÉchap : pause du jeu"
	_help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_help.offset_left = 20
	_help.offset_top = -290
	_help.visible = false
	layer.add_child(_help)
	_map = Control.new()
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.visible = false
	_map.draw.connect(_draw_map)
	layer.add_child(_map)
	_free_cam = Camera3D.new()
	_free_cam.fov = 70.0
	add_child(_free_cam)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return label


func _update_info(point: Vector3) -> void:
	var zone := get_zone(current_zone)
	var title := "hors zone"
	var status := ""
	if zone:
		title = "%d · %s" % [current_zone, zone.get_meta("title")]
		status = String(zone.get_meta("status"))
	_info.text = "%s\n%s\nx %.1f  y %.1f  z %.1f (unités ; 10 u = 1 m)\n%s%s" % [
		title, status, point.x, point.y, point.z,
		"CAMÉRA LIBRE" if _free else ("Jambes" if nino.mode == NinoController.Mode.LEGS else "Roues"),
		"" if (blockout.get_node("Ceilings") as Node3D).visible else " · plafonds masqués"]


## Carte vue de dessus : zones, connexions (vert = ouvert, rouge = fermé), position de Nin0.
func _draw_map() -> void:
	var view := _map.size
	var panel := Rect2(view.x - 560.0, 60.0, 540.0, 440.0)
	_map.draw_rect(panel, Color(0.04, 0.035, 0.03, 0.82))
	var world := Rect2(-78.0, -38.0, 126.0, 98.0)  # x, z
	var scale := minf((panel.size.x - 20.0) / world.size.x, (panel.size.y - 40.0) / world.size.y)
	var origin := panel.position + Vector2(10.0, 30.0)
	var to_map := func(x: float, z: float) -> Vector2:
		return origin + Vector2(x - world.position.x, z - world.position.y) * scale
	var font := ThemeDB.fallback_font
	_map.draw_string(font, panel.position + Vector2(10, 20), "Appartement — vue de dessus (nord en haut)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.9, 0.75))
	var centers := {}
	for zone in _zones:
		var number := int(zone.get_meta("number"))
		var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		var c := zone.global_position
		var a: Vector2 = to_map.call(c.x - box.size.x / 2, c.z - box.size.z / 2)
		var b: Vector2 = to_map.call(c.x + box.size.x / 2, c.z + box.size.z / 2)
		var color: Color = ZONE_COLORS.get(number, Color.GRAY)
		_map.draw_rect(Rect2(a, b - a), Color(color, 0.85 if number == current_zone else 0.5))
		_map.draw_rect(Rect2(a, b - a), Color(1, 1, 1, 0.5), false, 1.0)
		_map.draw_string(font, a + Vector2(4, 16), "%d %s" % [number, zone.get_meta("title")], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		centers[number] = (a + b) * 0.5
	for marker in blockout.get_node("Connections").get_children():
		var p: Vector2 = to_map.call(marker.global_position.x, marker.global_position.z)
		var open := String(marker.get_meta("state")) == "ouvert"
		var col := Color(0.4, 1.0, 0.5) if open else Color(1.0, 0.35, 0.3)
		for end in [int(marker.get_meta("from")), int(marker.get_meta("to"))]:
			if centers.has(end):
				_map.draw_line(centers[end], p, Color(col, 0.6), 2.0)
		_map.draw_circle(p, 5.0, col)
	var me: Vector3 = _free_cam.global_position if _free else nino.global_position
	var dot: Vector2 = to_map.call(me.x, me.z)
	_map.draw_circle(dot, 6.0, Color(0.45, 0.92, 1.0))
	var facing := -nino.global_basis.z
	_map.draw_line(dot, dot + Vector2(facing.x, facing.z) * 14.0, Color(0.45, 0.92, 1.0), 2.0)
