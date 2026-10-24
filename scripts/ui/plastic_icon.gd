@tool
extends Control
## Pictogramme « plastique à munitions » : trois billes bleues (distinct de la spirale
## orange du filament structurel).

@export var color := Color(0.3, 0.65, 1.0)


func _draw() -> void:
	var c := size * 0.5
	for k in 3:
		var p := c + Vector2(-6.0 + k * 6.0, 3.0 - (k % 2) * 6.0)
		draw_circle(p, 4.5, color)
		draw_circle(p + Vector2(-1.5, -1.5), 1.4, Color(1, 1, 1, 0.8))
