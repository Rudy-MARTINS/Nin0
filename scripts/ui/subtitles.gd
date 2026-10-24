class_name Subtitles
extends CanvasLayer
## Sous-titres des échanges entre Nin0 et Nathan (lot 7) : une ligne à la fois, en bas de
## l'écran, avec le nom de celui qui parle. Nin0 « parle » en sons robotiques, Nathan en
## petits sons de jouet ; le texte n'est qu'une traduction courte.

const COLORS := {&"nin0": Color(0.55, 0.85, 1.0), &"nathan": Color(1.0, 0.8, 0.45)}
const NAMES := {&"nin0": "Nin0", &"nathan": "Nathan"}

var showing := false
var _panel: PanelContainer
var _name: Label
var _text: Label
var _serial := 0


func _init() -> void:
	layer = 6
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = UiKit.panel()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -330.0
	_panel.offset_right = 330.0
	_panel.offset_top = -128.0
	_panel.offset_bottom = -40.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)
	var box := UiKit.vbox(UiKit.margin(_panel, 12), 2)
	_name = UiKit.label(box, "", 14, Color.WHITE)
	_text = UiKit.label(box, "", 19, Color.WHITE, true)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.modulate.a = 0.0


## Affiche une réplique (awaitable) : le son de la voix, puis le texte, puis une pause.
func say(speaker: StringName, text: String, duration := -1.0) -> void:
	_serial += 1
	var serial := _serial
	showing = true
	_name.text = NAMES.get(speaker, String(speaker))
	_name.modulate = COLORS.get(speaker, Color.WHITE)
	_text.text = text
	if speaker == &"nathan":
		Sfx.play(&"toy_voice", -6.0, randf_range(0.95, 1.15))
	else:
		Sfx.play(&"chirp_question" if text.ends_with("?") else &"chirp_known", -8.0)
	var fade := create_tween()
	fade.tween_property(_panel, "modulate:a", 1.0, 0.15)
	var wait := duration if duration > 0.0 else clampf(0.9 + text.length() * 0.045, 1.6, 4.2)
	await get_tree().create_timer(wait).timeout
	if serial == _serial:
		hide_line()


func hide_line() -> void:
	showing = false
	var fade := create_tween()
	fade.tween_property(_panel, "modulate:a", 0.0, 0.2)
