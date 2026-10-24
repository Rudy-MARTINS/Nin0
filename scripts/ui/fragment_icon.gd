@tool
extends Control
## Pictogramme « fragment de filament » : petit fil enroulé (vectoriel).

@export var color := Color(0.95, 0.6, 0.25)


func _draw() -> void:
	var c := size * 0.5
	var points := PackedVector2Array()
	for i in 40:
		var t := float(i) / 39.0
		var a := t * TAU * 2.2
		var r := 3.0 + t * 6.0
		points.append(c + Vector2(cos(a), sin(a)) * r)
	draw_polyline(points, color, 2.0, true)
