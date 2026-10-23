class_name FocusOverlay
extends Control
## Habillage de la vision focalisée : masque « jumelles », réticule, repères et
## anneau de progression de l'identification.

const TINT := Color(0.45, 0.92, 1.0)

var _markers: Array = []
var _locked := false
var _progress := 0.0
var _time := 0.0

@onready var _mask: ColorRect = $Mask
@onready var _reticle: Control = $Reticle


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false
	_reticle.draw.connect(_draw_reticle)


func set_active(value: bool) -> void:
	if value:
		visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0 if value else 0.0, 0.2)
	if not value:
		tween.tween_callback(func() -> void: visible = false)


func update_targets(markers: Array, locked: FocusTarget, progress: float) -> void:
	_markers = markers
	_locked = locked != null and not locked.is_identified
	_progress = progress
	_reticle.queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_time += delta
		_reticle.queue_redraw()


func _draw_reticle() -> void:
	var view := size
	var center := view * 0.5
	_mask.material.set_shader_parameter("view_size", view)
	# Réticule.
	var r := _reticle
	var color := Color(1.0, 0.75, 0.4) if _locked else Color(TINT, 0.85)
	var gap := 10.0
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		r.draw_line(center + dir * gap, center + dir * (gap + 16.0), color, 2.0, true)
	r.draw_arc(center, 34.0, 0.0, TAU, 48, Color(color, 0.4), 1.5, true)
	if _locked and _progress > 0.0:
		r.draw_arc(center, 34.0, -PI * 0.5, -PI * 0.5 + TAU * _progress, 48, color, 4.0, true)
	# Repères (cercles en pointillés qui pulsent).
	for marker in _markers:
		var pulse := 22.0 + sin(_time * 4.0) * 4.0
		for k in 12:
			var a := TAU * k / 12.0 + _time * 0.8
			r.draw_arc(marker, pulse, a, a + TAU / 24.0, 4, Color(1.0, 0.8, 0.45, 0.9), 2.5, true)
