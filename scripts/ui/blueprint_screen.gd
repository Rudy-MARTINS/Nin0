class_name BlueprintScreen
extends CanvasLayer
## Découverte d'un plan : Nin0 « dessine » ce qu'il vient de comprendre (pictogrammes,
## schéma mécanique), puis le plan rejoint la mémoire de l'imprimante.
## Le jeu est figé le temps de la présentation (E ou Échap pour continuer).

signal closed

var _root: Control
var _title: Label
var _subtitle: Label
var _icons: HBoxContainer
var _schematic: BlueprintSchematic
var _hint: Label
var _open := false


func _init() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.1, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := UiKit.panel()
	center.add_child(panel)
	var box := UiKit.vbox(UiKit.margin(panel, 26), 12)
	UiKit.label(box, "▣ NOUVEAU PLAN", 15, UiKit.SCAN_COLOR)
	_title = UiKit.label(box, "", 28, UiKit.TITLE_COLOR)
	_subtitle = UiKit.label(box, "", 16, UiKit.DIM_COLOR, true)
	_subtitle.custom_minimum_size.x = 560.0
	_icons = UiKit.hbox(box, 8)
	_schematic = BlueprintSchematic.new()
	_schematic.custom_minimum_size = Vector2(560, 220)
	box.add_child(_schematic)
	_hint = UiKit.label(box, "E : continuer", 14, UiKit.DIM_COLOR)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	visible = false


## kind : &"armor" ou &"cannon" (schéma dessiné) ; icons : raisonnement en pictogrammes.
func present(kind: StringName, title: String, subtitle: String, icons: Array) -> void:
	_title.text = title
	_subtitle.text = subtitle
	for child in _icons.get_children():
		child.queue_free()
	for name in icons:
		UiKit.icon(_icons, name, 44)
	_schematic.kind = kind
	_schematic.progress = 0.0
	visible = true
	_open = true
	_hint.modulate.a = 0.0
	GameState.modal_open = true
	get_tree().paused = true
	Sfx.jingle(&"jingle_plan")
	var tween := create_tween()
	tween.tween_property(_schematic, "progress", 1.0, 2.2)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.4)
	await closed


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	GameState.modal_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _schematic.progress < 1.0:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
