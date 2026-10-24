class_name UiKit
extends RefCounted
## Petits constructeurs d'interface (style de l'ordinateur de Nin0, thème commun).

const THEME: Theme = preload("res://assets/ui/nino_theme.tres")
## Palette Nin0 (glow-up lot 7) : crème du châssis, orange doux des accents, cyan de
## l'écran-visage, bleu-gris profond des panneaux. Toute nouvelle interface s'y tient.
const CREAM := Color(0.97, 0.93, 0.85)
const ORANGE := Color(0.96, 0.6, 0.28)
const CYAN := Color(0.5, 0.93, 1.0)
const INK := Color(0.095, 0.11, 0.14)
const TITLE_COLOR := Color(1.0, 0.82, 0.58)
const SCAN_COLOR := CYAN
const DIM_COLOR := Color(0.72, 0.76, 0.8)


static func panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.theme = THEME
	return node


static func margin(parent: Control, value := 22) -> MarginContainer:
	var node := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		node.add_theme_constant_override("margin_" + side, value)
	parent.add_child(node)
	return node


static func vbox(parent: Control, separation := 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func hbox(parent: Control, separation := 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func label(parent: Control, text: String, size := 16, color := Color.WHITE, wrap := false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(node)
	return node


static func icon(parent: Control, name: StringName, size := 48) -> ThoughtIcon:
	var node := ThoughtIcon.new()
	node.icon = name
	node.custom_minimum_size = Vector2(size, size)
	parent.add_child(node)
	return node


static func button(parent: Control, text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.theme = THEME
	parent.add_child(node)
	return node
