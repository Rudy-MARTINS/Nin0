class_name ChargeGauge
extends Control
## Indicateur discret du saut chargé : un petit arc qui se remplit sous le centre de
## l'écran pendant la charge, puis s'efface.

var value := 0.0:
	set(v):
		value = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if value <= 0.01:
		return
	var c := size * 0.5
	draw_arc(c, 22.0, 0.0, TAU, 32, Color(1, 1, 1, 0.18), 5.0, true)
	var color := Color(0.98, 0.72, 0.1).lerp(Color(1.0, 0.95, 0.5), value)
	draw_arc(c, 22.0, -PI * 0.5, -PI * 0.5 + TAU * value, 32, color, 5.0, true)
	if value >= 0.999:
		draw_circle(c, 6.0, color)
