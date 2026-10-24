class_name SpeciesCard
extends CanvasLayer
## Fiche « ESPÈCE IDENTIFIÉE » affichée après l'analyse d'un insecte (vision focalisée).
## Non bloquante : le jeu continue, la fiche se referme seule (ou avec Échap).
## Les fiches restent consultables dans l'inventaire (onglet Bestiaire).

signal closed

@export var duration := 8.0

var _panel: PanelContainer
var _icon: ThoughtIcon
var _name: Label
var _class: Label
var _fields: VBoxContainer
var _tween: Tween
var showing := false


func _init() -> void:
	layer = 6
	_panel = UiKit.panel()
	_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_panel.offset_left = -470.0
	_panel.offset_right = -30.0
	_panel.offset_top = -170.0
	_panel.offset_bottom = 170.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var box := UiKit.vbox(UiKit.margin(_panel, 18), 6)
	UiKit.label(box, "▣ ESPÈCE IDENTIFIÉE", 15, UiKit.SCAN_COLOR)
	var head := UiKit.hbox(box, 14)
	_icon = UiKit.icon(head, &"ant", 64)
	var names := UiKit.vbox(head, 2)
	_name = UiKit.label(names, "", 24, UiKit.TITLE_COLOR)
	_class = UiKit.label(names, "", 15, UiKit.DIM_COLOR)
	_fields = UiKit.vbox(box, 4)
	_panel.modulate.a = 0.0
	visible = false


func show_species(data: SpeciesData) -> void:
	_icon.icon = data.icon
	_name.text = data.display_name
	_class.text = "Classification : %s" % data.classification
	for child in _fields.get_children():
		child.queue_free()
	field(_fields, "Activité", data.description)
	field(_fields, "Comportement", data.behavior)
	if not data.traits.is_empty():
		field(_fields, "Particularité", " · ".join(data.traits))
	visible = true
	showing = true
	Sfx.play(&"species", -6.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.35)
	_tween.tween_interval(duration)
	_tween.tween_callback(hide_card)


static func field(parent: Control, title: String, text: String) -> void:
	var row := UiKit.vbox(parent, 0)
	UiKit.label(row, title.to_upper(), 12, UiKit.SCAN_COLOR)
	var value := UiKit.label(row, text, 15, Color.WHITE, true)
	value.custom_minimum_size.x = 380.0


func hide_card() -> void:
	if not showing:
		return
	showing = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(func() -> void:
		visible = false
		closed.emit())


func _unhandled_input(event: InputEvent) -> void:
	if showing and not GameState.modal_open and event.is_action_pressed("pause"):
		hide_card()
		get_viewport().set_input_as_handled()
