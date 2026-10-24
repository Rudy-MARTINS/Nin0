class_name BlueprintSchematic
extends Control
## Schéma mécanique stylisé (traits de plan, tracé progressif).
## « cannon » : goutte projetée → ressort comprimé → tube → bille.
## « armor » : anneaux de l'exosquelette → plaques articulées sur le châssis.

const LINE := Color(0.62, 0.9, 1.0)
const GRID := Color(0.3, 0.5, 0.7, 0.25)
const ACCENT := Color(0.98, 0.6, 0.25)

var kind: StringName = &"cannon":
	set(value):
		kind = value
		queue_redraw()
var progress := 1.0:
	set(value):
		progress = value
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.05, 0.12, 0.22, 0.9))
	var step := 20.0
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID, 1.0)
		x += step
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
		y += step
	if kind == &"armor":
		_draw_armor()
	else:
		_draw_cannon()


func _stage(index: int, count: int) -> float:
	return clampf(progress * count - index, 0.0, 1.0)


func _draw_cannon() -> void:
	var cy := size.y * 0.5
	# 1. Goutte crachée (référence : la reine), trajectoire en pointillés.
	var a := _stage(0, 4)
	if a > 0.0:
		var drop := Vector2(50, cy - 30)
		draw_circle(drop, 12.0 * a, Color(0.6, 0.95, 0.3, 0.8))
		for i in int(6 * a):
			draw_circle(drop + Vector2(20 + i * 12, -sin(i * 0.5) * 18 + 8), 2.5, LINE)
	# 2. Ressort comprimé + culasse.
	var b := _stage(1, 4)
	if b > 0.0:
		var x0 := 170.0
		draw_rect(Rect2(x0, cy - 22, 70 * b, 44), LINE, false, 2.0)
		for i in int(7 * b):
			var xs := x0 + 6 + i * 9
			draw_line(Vector2(xs, cy - 16), Vector2(xs + 5, cy + 16), ACCENT, 2.0)
	# 3. Tube.
	var c := _stage(2, 4)
	if c > 0.0:
		draw_rect(Rect2(240, cy - 12, 180 * c, 24), LINE, false, 2.0)
		draw_line(Vector2(240, cy), Vector2(240 + 180 * c, cy), Color(LINE, 0.4), 1.0)
		draw_rect(Rect2(200, cy - 54, 40, 30), LINE, false, 2.0)
		for i in 3:
			draw_circle(Vector2(210 + i * 10, cy - 38), 4.0, Color(0.3, 0.55, 0.95))
	# 4. Bille projetée.
	var d := _stage(3, 4)
	if d > 0.0:
		var bead := Vector2(430 + 90 * d, cy - 10 * d)
		draw_circle(bead, 8.0, Color(0.3, 0.55, 0.95))
		draw_line(Vector2(425, cy), bead, Color(LINE, 0.6), 1.5)


func _draw_armor() -> void:
	var cy := size.y * 0.5
	# 1. Anneaux d'un abdomen (exosquelette).
	var a := _stage(0, 3)
	for i in int(4 * a + 0.5):
		draw_arc(Vector2(110, cy), 30.0 + i * 12.0, PI * 0.15, PI * 0.85, 18, LINE, 2.0)
	# 2. Flèche de transposition.
	var b := _stage(1, 3)
	if b > 0.0:
		draw_line(Vector2(200, cy), Vector2(200 + 90 * b, cy), ACCENT, 3.0)
		if b >= 1.0:
			draw_line(Vector2(290, cy), Vector2(278, cy - 8), ACCENT, 3.0)
			draw_line(Vector2(290, cy), Vector2(278, cy + 8), ACCENT, 3.0)
	# 3. Châssis de Nin0 et plaques articulées.
	var c := _stage(2, 3)
	if c > 0.0:
		draw_rect(Rect2(330, cy - 40, 150, 80), LINE, false, 2.0)
		for i in int(4 * c + 0.5):
			draw_rect(Rect2(320 + i * 4, cy - 50 + i * 22, 170 - i * 8, 16), ACCENT, false, 2.0)
