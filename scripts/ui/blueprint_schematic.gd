class_name BlueprintSchematic
extends Control
## Schéma mécanique stylisé (traits de plan, tracé progressif).
## « cannon » : goutte projetée → ressort comprimé → tube → bille.
## « armor » : anneaux de l'exosquelette → plaques articulées sur le châssis.
## « charged_jump » : patte de puce repliée → ressort de jambe comprimé → grand arc.
## « sting » : dard de guêpe → pointe ajoutée à la bille → impact renforcé.

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
	match kind:
		&"armor":
			_draw_armor()
		&"charged_jump":
			_draw_charged_jump()
		&"sting":
			_draw_sting()
		_:
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


func _draw_charged_jump() -> void:
	var cy := size.y * 0.5
	# 1. Patte arrière de puce repliée en Z.
	var a := _stage(0, 3)
	if a > 0.0:
		var pts := PackedVector2Array([Vector2(60, cy - 40), Vector2(110, cy - 10), Vector2(70, cy + 20), Vector2(120, cy + 40)])
		draw_polyline(pts.slice(0, 1 + int(3 * a)), LINE, 3.0)
		draw_circle(Vector2(60, cy - 40), 10.0, Color(LINE, 0.6))
	# 2. Ressort de jambe comprimé sous le châssis.
	var b := _stage(1, 3)
	if b > 0.0:
		draw_rect(Rect2(190, cy - 50, 90, 30), LINE, false, 2.0)
		for i in int(6 * b):
			var yy := cy - 14 + i * 9
			draw_line(Vector2(215, yy), Vector2(255, yy + 4), ACCENT, 2.0)
		draw_line(Vector2(235, cy + 42), Vector2(235, cy + 50), LINE, 2.0)
	# 3. Grand arc de saut (trois fois plus haut).
	var c := _stage(2, 3)
	if c > 0.0:
		var prev := Vector2(320, cy + 40)
		for i in int(20 * c):
			var t := (i + 1) / 20.0
			var p := Vector2(320 + 180 * t, cy + 40 - 140 * 4.0 * t * (1.0 - t))
			draw_line(prev, p, ACCENT, 2.0)
			prev = p
		draw_line(Vector2(320, cy + 40), Vector2(500, cy + 40), Color(LINE, 0.5), 1.0)


func _draw_sting() -> void:
	var cy := size.y * 0.5
	# 1. Dard de guêpe (abdomen rayé, pointe).
	var a := _stage(0, 3)
	if a > 0.0:
		for i in 3:
			draw_rect(Rect2(50 + i * 22, cy - 26, 20, 52), Color(0.95, 0.8, 0.2, 0.5 * a), true)
		draw_colored_polygon(PackedVector2Array([Vector2(116, cy - 12), Vector2(116 + 40 * a, cy), Vector2(116, cy + 12)]), LINE)
	# 2. Flèche de transposition.
	var b := _stage(1, 3)
	if b > 0.0:
		draw_line(Vector2(190, cy), Vector2(190 + 80 * b, cy), ACCENT, 3.0)
	# 3. Bille pointue : bille + pointe, trait d'impact.
	var c := _stage(2, 3)
	if c > 0.0:
		draw_circle(Vector2(340, cy), 18.0, Color(0.3, 0.55, 0.95))
		draw_colored_polygon(PackedVector2Array([Vector2(356, cy - 10), Vector2(356 + 34 * c, cy), Vector2(356, cy + 10)]), ACCENT)
		for i in int(4 * c):
			draw_line(Vector2(410 + i * 12, cy - 18 + i * 3), Vector2(420 + i * 12, cy - 26 + i * 3), LINE, 2.0)
