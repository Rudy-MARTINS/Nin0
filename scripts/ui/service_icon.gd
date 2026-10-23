@tool
extends Control
## Pictogrammes du panneau de l'imprimante : 0 = réparation (clé), 1 = renfort de châssis.

@export_enum("Réparation", "Châssis") var kind := 0
@export var color := Color(1.0, 0.86, 0.62)


func _draw() -> void:
	var c := size * 0.5
	var s := minf(size.x, size.y) / 80.0
	draw_circle(c, 36.0 * s, Color(1, 1, 1, 0.06))
	if kind == 0:
		# Clé plate en diagonale.
		var a := c + Vector2(-18, 18) * s
		var b := c + Vector2(14, -14) * s
		draw_line(a, b, color, 7.0 * s, true)
		draw_arc(b + Vector2(4, -4) * s, 10.0 * s, PI * 0.1, PI * 1.6, 16, color, 5.0 * s, true)
		draw_circle(a, 5.0 * s, color)
	else:
		# Châssis : cadre et longerons croisés.
		var r := Rect2(c - Vector2(24, 16) * s, Vector2(48, 32) * s)
		draw_rect(r, color, false, 4.0 * s)
		draw_line(r.position, r.end, color, 3.0 * s, true)
		draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), color, 3.0 * s, true)
		draw_line(c + Vector2(0, -24) * s, c + Vector2(0, -32) * s, color, 3.0 * s, true)
		draw_line(c + Vector2(-6, -28) * s, c + Vector2(6, -28) * s, color, 3.0 * s, true)
