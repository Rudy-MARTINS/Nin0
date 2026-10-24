class_name CompanionCommands
extends CanvasLayer
## Ordres donnés à Nathan (lot 7), interface légère : G ouvre une petite barre de quatre
## ordres (1 Suis-moi · 2 Attends · 3 Va là-bas · 4 Interagis) ; un chiffre choisit, G ou
## Échap referme. « Va là-bas » et « Interagis » visent le point au centre de l'écran.
## Le jeu continue pendant le choix (pas de pause) ; un rappel discret de l'ordre en cours
## reste affiché tant que Nathan accompagne Nin0.

signal order_given(order: StringName, point: Vector3)

const ORDERS := [
	[&"follow", "Suis-moi"],
	[&"wait", "Attends"],
	[&"goto", "Va là-bas"],
	[&"interact", "Interagis"],
]
const LABELS := {&"follow": "suit Nin0", &"wait": "attend", &"goto": "se déplace", &"interact": "agit", &"hold": "tient la règle", &"scared": "a peur !"}

var enabled := false:
	set(value):
		enabled = value
		_status.visible = value
		if not value:
			close()
var is_open := false
var _bar: PanelContainer
var _status: Label
var _items: Array[Label] = []


func _init() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_bar = UiKit.panel()
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_left = -300.0
	_bar.offset_right = 300.0
	_bar.offset_top = -200.0
	_bar.offset_bottom = -150.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bar)
	var row := UiKit.hbox(UiKit.margin(_bar, 10), 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.label(row, "Nathan :", 15, Color(1.0, 0.8, 0.45))
	for i in ORDERS.size():
		_items.append(UiKit.label(row, "%d  %s" % [i + 1, ORDERS[i][1]], 15, Color.WHITE))
	_bar.visible = false
	_status = UiKit.label(root, "", 13, Color(1.0, 0.85, 0.6))
	_status.anchor_left = 0.0
	_status.anchor_top = 1.0
	_status.anchor_bottom = 1.0
	_status.offset_left = 28.0
	_status.offset_top = -40.0
	_status.offset_bottom = -18.0
	_status.visible = false


func set_status(order: StringName) -> void:
	_status.text = "Nathan %s   ·   %s : ordres" % [LABELS.get(order, ""), Hud.key("G")]


func open() -> void:
	if not enabled or GameState.modal_open:
		return
	is_open = true
	_bar.visible = true
	Sfx.play(&"blip", -10.0, 1.2)


func close() -> void:
	is_open = false
	if _bar:
		_bar.visible = false


func choose(index: int, point: Vector3) -> void:
	if index < 0 or index >= ORDERS.size():
		return
	var order: StringName = ORDERS[index][0]
	close()
	Sfx.play(&"chirp_known", -8.0, 1.1 + index * 0.05)
	order_given.emit(order, point)


func _input(event: InputEvent) -> void:
	if not enabled or GameState.modal_open:
		return
	if event.is_action_pressed("companion"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not is_open:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var code := key.physical_keycode
		if code >= KEY_1 and code <= KEY_4:
			choose(code - KEY_1, Vector3.INF)
			get_viewport().set_input_as_handled()
		elif code == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
