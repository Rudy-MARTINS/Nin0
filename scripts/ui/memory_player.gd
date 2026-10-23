class_name MemoryPlayer
extends CanvasLayer
## Lecture d'un souvenir retrouvé : signal détecté, parasites d'interface, fragments
## de mots, enregistrement incomplet, fragment mémorisé. Courte (≈ 8 s), sans rien révéler.
## Le texte est dégradé selon le nombre de fragments retrouvés (MemoryArchive).

signal line_shown(index: int)

const TINT := Color(0.55, 0.95, 1.0)

var playing := false

var _veil: ColorRect
var _caption: Label
var _lines: VBoxContainer
var _footer: Label


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/memory_glitch.gdshader")
	material.set_shader_parameter("intensity", 0.0)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.material = material
	add_child(_veil)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(620, 0)
	center.add_child(box)
	_caption = _make_label(15, Color(TINT, 0.75))
	box.add_child(_caption)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 6)
	box.add_child(_lines)
	_footer = _make_label(15, Color(1.0, 0.8, 0.55, 0.9))
	box.add_child(_footer)
	visible = false


## Joue la séquence. `found_count` : fragments retrouvés (celui-ci compris).
func play(memory: MemoryData, found_count: int, total: int, corruption: float) -> void:
	playing = true
	visible = true
	_caption.text = ""
	_footer.text = ""
	for child in _lines.get_children():
		child.queue_free()
	Sfx.play(&"signal", -6.0)
	await _set_intensity(0.85, 0.35)
	Sfx.set_loop(&"memory", &"static", -14.0)
	await _flicker_caption("SIGNAL DÉTECTÉ", 0.9)
	await _set_intensity(0.55, 0.4)
	_caption.text = "LECTURE · %s" % memory.title.to_upper()
	for i in memory.lines.size():
		var line := MemoryArchive.degrade(memory.lines[i], corruption, hash(memory.id) + i * 31 + found_count * 7)
		var label := _make_label(24, TINT)
		_lines.add_child(label)
		await _type_line(label, line)
		line_shown.emit(i)
		if randf() < corruption:
			Sfx.play(&"glitch", -10.0, randf_range(0.8, 1.2))
		await get_tree().create_timer(0.45).timeout
	await _flicker_caption("ENREGISTREMENT INCOMPLET", 0.8)
	_footer.text = "Fragment mémorisé · Archives fragmentées — %d/%d" % [found_count, total]
	Sfx.play(&"focus_lock", -8.0)
	await get_tree().create_timer(1.8).timeout
	Sfx.stop_loop(&"memory")
	var fade := create_tween()
	fade.tween_property(_lines, "modulate:a", 0.0, 0.5)
	fade.parallel().tween_property(_caption, "modulate:a", 0.0, 0.5)
	fade.parallel().tween_property(_footer, "modulate:a", 0.0, 0.5)
	await fade.finished
	await _set_intensity(0.0, 0.4)
	_lines.modulate.a = 1.0
	_caption.modulate.a = 1.0
	_footer.modulate.a = 1.0
	visible = false
	playing = false


func _type_line(label: Label, line: String) -> void:
	# Les caractères arrivent avec des sautes : brefs glyphes parasites avant le bon.
	for i in line.length():
		label.text = line.substr(0, i) + MemoryArchive.GLYPHS[randi() % MemoryArchive.GLYPHS.size()]
		await get_tree().create_timer(0.035).timeout
		label.text = line.substr(0, i + 1)
	await get_tree().create_timer(0.05).timeout


func _flicker_caption(text: String, duration: float) -> void:
	var steps := int(duration / 0.08)
	for i in steps:
		_caption.text = text if i % 3 != 1 else ""
		await get_tree().create_timer(0.08).timeout
	_caption.text = text


func _set_intensity(value: float, duration: float) -> void:
	var material := _veil.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("intensity", v),
			float(material.get_shader_parameter("intensity")), value, duration)
	await tween.finished


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.theme = load("res://assets/ui/nino_theme.tres")
	return label
