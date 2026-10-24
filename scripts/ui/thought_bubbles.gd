class_name ThoughtBubbles
extends CanvasLayer
## Bulles de pensée de Nin0 : pictogrammes (et, si besoin, un texte très court)
## affichés au-dessus de sa tête. Une seule bulle à la fois ; une petite file
## d'attente évite les accumulations. Réutilisable dans toutes les pièces.
##
## Pensées = ce que Nin0 observe, ressent ou comprend.
## (Ne pas y répéter l'objectif affiché dans le HUD.)

signal thought_shown(icons: Array, text: String)
## Émis à chaque demande de pensée (même si elle est ensuite remplacée).
signal thought_requested(icons: Array, text: String)

const MAX_QUEUE := 2
const HEAD_OFFSET := Vector3(0.0, 0.85, 0.0)

## Nœud au-dessus duquel la bulle apparaît (Nin0).
@export var anchor: Node3D

var _queue: Array[Dictionary] = []
var _showing := false
var _time := 0.0
var _current_icons: Array = []
var _tween: Tween

@onready var _bubble: ThoughtBubbleFrame = $Bubble
@onready var _icons_box: HBoxContainer = $Bubble/Content/Icons
@onready var _label: Label = $Bubble/Content/Text


func _ready() -> void:
	_bubble.modulate.a = 0.0
	_bubble.visible = false


## Affiche une pensée. `icons` : noms de ThoughtIcon (voir ThoughtIcon.ICONS).
## `interrupt` : réaction à un événement ; remplace la bulle en cours et la file.
func think(icons: Array, text := "", duration := 2.6, interrupt := false) -> void:
	thought_requested.emit(icons, text)
	# Pas de doublon immédiat de la pensée en cours ou en attente.
	if _showing and icons == _current_icons:
		return
	if interrupt and _showing:
		_queue.clear()
		_queue.append({"icons": icons, "text": text, "duration": duration})
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_bubble, "modulate:a", 0.0, 0.12)
		_tween.tween_callback(_show_next)
		return
	for entry in _queue:
		if entry.icons == icons:
			return
	_queue.append({"icons": icons, "text": text, "duration": duration})
	while _queue.size() > MAX_QUEUE:
		_queue.pop_front()
	if not _showing:
		_show_next()


func clear() -> void:
	_queue.clear()


func is_busy() -> bool:
	return _showing or not _queue.is_empty()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_current_icons = []
		return
	_showing = true
	var entry: Dictionary = _queue.pop_front()
	_current_icons = entry.icons
	for child in _icons_box.get_children():
		child.queue_free()
	var delay := 0.0
	for icon_name in entry.icons:
		var icon := ThoughtIcon.new()
		icon.icon = icon_name
		icon.scale = Vector2.ZERO
		_icons_box.add_child(icon)
		icon.pivot_offset = icon.custom_minimum_size * 0.5
		var pop := create_tween()
		pop.tween_interval(delay)
		pop.tween_property(icon, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.18
	_label.text = entry.text
	_label.visible = entry.text != ""
	_bubble.visible = true
	_bubble.reset_size()
	_bubble.pivot_offset = Vector2(0.0, _bubble.size.y)
	_bubble.scale = Vector2(0.6, 0.6)
	Sfx.play(&"thought", -10.0, randf_range(0.95, 1.08))
	thought_shown.emit(entry.icons, entry.text)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_bubble, "modulate:a", 1.0, 0.25)
	_tween.tween_property(_bubble, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(entry.duration + delay)
	_tween.chain().tween_property(_bubble, "modulate:a", 0.0, 0.35)
	_tween.chain().tween_interval(0.15)
	_tween.chain().tween_callback(_show_next)


func _process(delta: float) -> void:
	if not _bubble.visible or anchor == null:
		return
	_time += delta
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var world := anchor.global_position + HEAD_OFFSET
	if camera.is_position_behind(world):
		_bubble.visible = false
		return
	var screen := camera.unproject_position(world)
	var viewport := get_viewport().get_visible_rect().size
	var target := screen + Vector2(26.0, -_bubble.size.y - 24.0 + sin(_time * 2.2) * 3.0)
	target.x = clampf(target.x, 12.0, viewport.x - _bubble.size.x - 12.0)
	target.y = clampf(target.y, 12.0, viewport.y - _bubble.size.y - 60.0)
	_bubble.position = target
	_bubble.tail_target = screen - target
	_bubble.queue_redraw()
