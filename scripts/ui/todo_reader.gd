class_name TodoReader
extends CanvasLayer
## Lecture d'un document manuscrit par Nin0 (souvenir n° 3, la liste du réfrigérateur).
## Une feuille apparaît ; Nin0 déchiffre les lignes une à une (petit bip à chaque ligne).
## La dernière ligne, rayée, arrive après une hésitation, puis un long silence.
## Le nom après « R » reste volontairement illisible : il n'est jamais complété.

const PAPER := Color(0.96, 0.94, 0.86)
const INK := Color(0.2, 0.2, 0.3)

var _sheet: PanelContainer
var _lines: VBoxContainer
var _caption: Label


func _init() -> void:
	layer = 8
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.04, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_sheet = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(4)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 36
	style.content_margin_bottom = 36
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 12
	_sheet.add_theme_stylebox_override("panel", style)
	_sheet.rotation_degrees = -2.0
	_sheet.custom_minimum_size = Vector2(460, 0)
	center.add_child(_sheet)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 10)
	_sheet.add_child(_lines)
	_caption = Label.new()
	_caption.add_theme_color_override("font_color", Color(0.62, 0.9, 1.0))
	_caption.add_theme_font_size_override("font_size", 16)
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.position.y -= 90
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.text = "Nin0 déchiffre…"
	add_child(_caption)
	_sheet.modulate.a = 0.0


## Lit les lignes ; la dernière est présentée rayée, avec un silence avant et après.
func read(lines: PackedStringArray) -> void:
	var appear := create_tween()
	appear.tween_property(_sheet, "modulate:a", 1.0, 0.6)
	await appear.finished
	for i in lines.size():
		var last := i == lines.size() - 1
		if last:
			# Hésitation : quelque chose est différent sur cette ligne.
			_caption.text = "…"
			await get_tree().create_timer(1.4).timeout
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(380, 0)
		label.add_theme_color_override("default_color", INK)
		label.add_theme_font_size_override("normal_font_size", 30 if i == 0 else 24)
		label.add_theme_font_size_override("bold_font_size", 30)
		label.text = _format(lines[i], i == 0, last)
		label.visible_ratio = 0.0
		_lines.add_child(label)
		Sfx.play(&"blip", -14.0, 1.0 + i * 0.05)
		var type := create_tween()
		type.tween_property(label, "visible_ratio", 1.0, 0.35 + lines[i].length() * 0.03)
		await type.finished
		await get_tree().create_timer(0.55).timeout
	# Silence particulier devant la ligne rayée.
	_caption.text = ""
	await get_tree().create_timer(2.6).timeout
	var fade := create_tween()
	fade.tween_property(_sheet, "modulate:a", 0.0, 0.6)
	await fade.finished


func _format(line: String, title: bool, struck: bool) -> String:
	var text := line.replace(" (rayé)", "")
	if title:
		return "[b]%s[/b]" % text
	if struck:
		# Le nom après « R » reste presque illisible (jamais complété).
		return "[s]%s[/s]" % text.replace("R…", "R[color=#8a8a99]~·~[/color]")
	return text
