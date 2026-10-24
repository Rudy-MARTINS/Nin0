class_name WifiSearch
extends CanvasLayer
## Souvenir n° 5 (lot 7) : Nin0 se connecte au réseau de la maison par la box internet.
## Interface de recherche fictive (pas un vrai navigateur, aucune marque réelle) :
## connexion → recherche « NIN0 » → résultats → fiche produit fictive où s'alignent des
## robots identiques à Nin0. Aucune information sur les habitants de la maison.

signal finished

const BG := Color(0.05, 0.07, 0.1, 0.94)
const ACCENT := Color(0.55, 0.95, 1.0)

var _panel: PanelContainer
var _box: VBoxContainer
var _status: Label
var _field: Label
var _results: VBoxContainer
var _page: Control


func _init() -> void:
	layer = 7
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.02, 0.04, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	_panel = UiKit.panel()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 440)
	_panel.offset_left = -350.0
	_panel.offset_right = 350.0
	_panel.offset_top = -230.0
	_panel.offset_bottom = 210.0
	root.add_child(_panel)
	_box = UiKit.vbox(UiKit.margin(_panel, 18), 10)
	var head := UiKit.hbox(_box, 10)
	UiKit.label(head, "◉ LIAISON SANS FIL — NIN0", 15, ACCENT)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	_status = UiKit.label(head, "", 13, UiKit.DIM_COLOR)
	_field = UiKit.label(_box, "", 20, Color.WHITE)
	_results = UiKit.vbox(_box, 6)
	_page = Control.new()
	_page.custom_minimum_size = Vector2(660, 250)
	_page.visible = false
	_page.draw.connect(_draw_page)
	_box.add_child(_page)
	_panel.modulate.a = 0.0


## Joue la séquence complète (awaitable).
func play() -> void:
	var fade := create_tween()
	fade.tween_property(_panel, "modulate:a", 1.0, 0.3)
	Sfx.play(&"signal", -8.0)
	for i in 4:
		_status.text = "Recherche d'un réseau" + ".".repeat(i)
		await _pause(0.45)
	_status.text = "Réseau de la maison : connecté"
	Sfx.play(&"focus_lock", -8.0)
	await _pause(0.6)
	_field.text = "Recherche : "
	for c in "NIN0":
		_field.text += c
		Sfx.play(&"click", -14.0, 1.6)
		await _pause(0.22)
	await _pause(0.5)
	Sfx.play(&"scan", -10.0)
	for line in ["Nin0 — compagnon robotique · Série 0", "Nin0 : questions fréquentes", "Nin0 : pièces détachées"]:
		UiKit.label(_results, "▸ " + line, 15, ACCENT if line.begins_with("Nin0 —") else UiKit.DIM_COLOR)
		await _pause(0.35)
	await _pause(0.8)
	for child in _results.get_children():
		child.queue_free()
	_field.text = "Nin0 — compagnon robotique"
	UiKit.label(_results, "Modèle de série · Série 0 · plusieurs coloris", 14, UiKit.DIM_COLOR)
	_page.visible = true
	_page.queue_redraw()
	Sfx.play(&"glitch", -12.0)
	await _pause(4.2)
	var out := create_tween()
	out.tween_property(_panel, "modulate:a", 0.0, 0.4)
	await out.finished
	finished.emit()


func _pause(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Fiche produit fictive : trois rangées de robots identiques (silhouette de Nin0).
func _draw_page() -> void:
	var size := _page.size
	_page.draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.13, 0.17))
	var colors := [Color(0.92, 0.92, 0.9), Color(0.95, 0.75, 0.3), Color(0.5, 0.75, 0.95)]
	for row in 3:
		for col in 8:
			var c := Vector2(48 + col * 80, 46 + row * 80)
			_draw_robot(c, colors[row])


func _draw_robot(c: Vector2, body: Color) -> void:
	var ink := Color(0.12, 0.13, 0.15)
	# Roues, corps arrondi, tête-écran et deux yeux.
	_page.draw_circle(c + Vector2(-14, 24), 7.0, ink)
	_page.draw_circle(c + Vector2(14, 24), 7.0, ink)
	_page.draw_rect(Rect2(c + Vector2(-18, -2), Vector2(36, 24)), body)
	_page.draw_rect(Rect2(c + Vector2(-15, -28), Vector2(30, 24)), body)
	_page.draw_rect(Rect2(c + Vector2(-11, -24), Vector2(22, 16)), Color(0.05, 0.07, 0.1))
	_page.draw_circle(c + Vector2(-5, -16), 2.6, ACCENT)
	_page.draw_circle(c + Vector2(5, -16), 2.6, ACCENT)
	_page.draw_line(c + Vector2(0, -28), c + Vector2(0, -36), ink, 2.0)
	_page.draw_circle(c + Vector2(0, -37), 2.5, Color(1.0, 0.55, 0.2))
