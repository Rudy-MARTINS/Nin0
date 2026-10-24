class_name FocusOverlay
extends Control
## Habillage de la vision focalisée : masque « jumelles », réticule, repères,
## anneau de progression et état de la visée (trop loin, mauvais angle).
## `play_calibration` joue la première mise au point du système optique.

const TINT := Color(0.45, 0.92, 1.0)
const STATUS_TEXT := {
	FocusVision.Status.TOO_FAR: "TROP LOIN",
	FocusVision.Status.BAD_ANGLE: "ANGLE INSUFFISANT",
}

var _markers: Array = []
var _locked := false
var _progress := 0.0
var _status := FocusVision.Status.OK
var _time := 0.0
## 0..1 : flou et balayage de calibrage (première utilisation).
var _calibration := 0.0
var _caption := ""

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


func update_targets(markers: Array, locked: FocusTarget, progress: float, status := FocusVision.Status.OK) -> void:
	_markers = markers
	_locked = locked != null and not locked.is_identified
	_progress = progress
	_status = status
	_reticle.queue_redraw()


## Première mise au point : le système optique se calibre (balayage, réticule qui se
## resserre), puis affiche le nom de la nouvelle capacité. Renvoie quand c'est fini.
func play_calibration(duration := 2.4) -> void:
	set_active(true)
	_markers = []
	_locked = false
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _calibration = v, 1.0, 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_caption = "SYSTÈME OPTIQUE · CALIBRAGE"
	await get_tree().create_timer(duration * 0.6).timeout
	_caption = "VISION FOCALISÉE"
	Sfx.play(&"focus_lock", -6.0)
	await tween.finished
	await get_tree().create_timer(0.6).timeout
	_caption = ""
	set_active(false)


func _process(delta: float) -> void:
	if visible:
		_time += delta
		_reticle.queue_redraw()


func _draw_reticle() -> void:
	var view := size
	var center := view * 0.5
	_mask.material.set_shader_parameter("view_size", view)
	var r := _reticle
	var font := get_theme_default_font()
	var blocked := _status != FocusVision.Status.OK
	var color := Color(1.0, 0.75, 0.4) if _locked else (Color(TINT, 0.35) if blocked else Color(TINT, 0.85))
	# Calibrage : réticule écarté qui se resserre, lignes de balayage.
	var gap := 10.0 + _calibration * 60.0
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		r.draw_line(center + dir * gap, center + dir * (gap + 16.0), color, 2.0, true)
	r.draw_arc(center, 34.0 + _calibration * 50.0, 0.0, TAU, 48, Color(color, 0.4), 1.5, true)
	if _calibration > 0.0:
		var sweep := fmod(_time * 1.6, 1.0) * view.y
		r.draw_line(Vector2(0.0, sweep), Vector2(view.x, sweep), Color(TINT, 0.35 * _calibration), 2.0)
		for k in 6:
			var y := fmod(sweep + k * 37.0, view.y)
			r.draw_line(Vector2(center.x - 260.0, y), Vector2(center.x + 260.0, y), Color(TINT, 0.08 * _calibration), 1.0)
	if _locked and _progress > 0.0:
		r.draw_arc(center, 34.0, -PI * 0.5, -PI * 0.5 + TAU * _progress, 48, color, 4.0, true)
	if blocked and STATUS_TEXT.has(_status):
		r.draw_string(font, center + Vector2(-120.0, 64.0), STATUS_TEXT[_status], HORIZONTAL_ALIGNMENT_CENTER, 240.0, 14, Color(TINT, 0.6))
	if _caption != "":
		r.draw_string(font, center + Vector2(-220.0, -70.0), _caption, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 18, Color(TINT, 0.9))
	# Repères (cercles en pointillés qui pulsent).
	for marker in _markers:
		var pulse := 22.0 + sin(_time * 4.0) * 4.0
		for k in 12:
			var a := TAU * k / 12.0 + _time * 0.8
			r.draw_arc(marker, pulse, a, a + TAU / 24.0, 4, Color(1.0, 0.8, 0.45, 0.9), 2.5, true)
