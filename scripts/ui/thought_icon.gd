@tool
class_name ThoughtIcon
extends Control
## Pictogramme des pensées de Nin0, dessiné en vectoriel (aucune image externe).
## Le langage des pensées repose sur ces symboles : ajouter un cas dans `_draw_icon`
## suffit pour en créer un nouveau.

const INK := Color(0.17, 0.15, 0.14)
const ACCENT := Color(0.93, 0.48, 0.14)
const ENERGY := Color(0.98, 0.72, 0.1)
const COOL := Color(0.25, 0.6, 0.85)

const ICONS := [
	&"question", &"exclamation", &"ellipsis", &"idea", &"happy", &"eye", &"printer", &"legs",
	&"plug", &"energy", &"arrow", &"up", &"down", &"gear", &"door", &"handle", &"spool", &"robot",
	&"check", &"cross", &"frame", &"house", &"book", &"sun", &"wrench", &"damage", &"filament",
	&"ant", &"ant_soldier", &"ant_queen", &"shield", &"cannon", &"acid", &"lock", &"plastic",
]

@export var icon: StringName = &"question":
	set(value):
		icon = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(46, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	_draw_icon(icon, size)


func _draw_icon(name: StringName, area: Vector2) -> void:
	var s := minf(area.x, area.y) / 100.0
	var c := area * 0.5
	var w := 7.0 * s
	match name:
		&"question", &"exclamation":
			var font := ThemeDB.fallback_font
			var glyph := "?" if name == &"question" else "!"
			var font_size := int(84 * s)
			var text_size := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, Vector2(c.x - text_size.x * 0.5, c.y + font_size * 0.36), glyph,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ACCENT if name == &"exclamation" else INK)
		&"ellipsis":
			for i in 3:
				draw_circle(c + Vector2((i - 1) * 26.0, 8.0) * s, 8.0 * s, INK)
		&"idea":
			draw_circle(c + Vector2(0, -8) * s, 24.0 * s, ENERGY)
			draw_rect(Rect2(c + Vector2(-12, 14) * s, Vector2(24, 16) * s), INK)
			for k in 5:
				var a := PI + PI * (k + 0.5) / 5.0
				var d := Vector2(cos(a), sin(a))
				draw_line(c + Vector2(0, -8) * s + d * 31.0 * s, c + Vector2(0, -8) * s + d * 43.0 * s, ENERGY, w * 0.7, true)
		&"happy":
			# Les yeux « contents » de Nin0 : deux arcs.
			for side in [-1.0, 1.0]:
				draw_arc(c + Vector2(side * 20.0, 8.0) * s, 14.0 * s, PI, TAU, 12, COOL, w, true)
		&"eye":
			var points := PackedVector2Array()
			for i in 25:
				var t := TAU * i / 24.0
				points.append(c + Vector2(cos(t) * 40.0, sin(t) * 20.0 * absf(sin(t)) * 1.3) * s)
			draw_polyline(points, INK, w * 0.8, true)
			draw_circle(c, 13.0 * s, COOL)
			draw_circle(c, 5.0 * s, INK)
		&"printer":
			draw_rect(Rect2(c + Vector2(-36, 18) * s, Vector2(72, 18) * s), INK)
			draw_rect(Rect2(c + Vector2(-32, -34) * s, Vector2(7, 52) * s), INK)
			draw_rect(Rect2(c + Vector2(25, -34) * s, Vector2(7, 52) * s), INK)
			draw_rect(Rect2(c + Vector2(-32, -38) * s, Vector2(64, 7) * s), INK)
			draw_rect(Rect2(c + Vector2(-8, -16) * s, Vector2(16, 14) * s), ACCENT)
			draw_rect(Rect2(c + Vector2(-20, 12) * s, Vector2(40, 5) * s), ACCENT)
		&"legs":
			for side in [-1.0, 1.0]:
				var hip := c + Vector2(side * 14.0, -32.0) * s
				var knee := c + Vector2(side * 14.0 + 10.0, 0.0) * s
				var ankle := c + Vector2(side * 14.0, 30.0) * s
				draw_line(hip, knee, INK, w, true)
				draw_line(knee, ankle, INK, w, true)
				draw_line(ankle + Vector2(-9, 5) * s, ankle + Vector2(8, 5) * s, INK, w, true)
				for joint in [hip, knee]:
					draw_circle(joint, 6.0 * s, ACCENT)
		&"plug":
			draw_rect(Rect2(c + Vector2(-18, -14) * s, Vector2(36, 30) * s), INK)
			draw_line(c + Vector2(-9, -14) * s, c + Vector2(-9, -34) * s, INK, w, true)
			draw_line(c + Vector2(9, -14) * s, c + Vector2(9, -34) * s, INK, w, true)
			draw_polyline(PackedVector2Array([c + Vector2(0, 16) * s, c + Vector2(0, 30) * s, c + Vector2(26, 36) * s]), INK, w * 0.8, true)
		&"energy":
			draw_colored_polygon(PackedVector2Array([c + Vector2(6, -42) * s, c + Vector2(-22, 6) * s, c + Vector2(-2, 6) * s,
					c + Vector2(-8, 42) * s, c + Vector2(22, -8) * s, c + Vector2(2, -8) * s]), ENERGY)
		&"arrow":
			draw_line(c + Vector2(-30, 0) * s, c + Vector2(22, 0) * s, INK, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(34, 0) * s, c + Vector2(14, -16) * s, c + Vector2(14, 16) * s]), INK)
		&"up":
			draw_line(c + Vector2(0, 30) * s, c + Vector2(0, -20) * s, INK, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -34) * s, c + Vector2(-16, -14) * s, c + Vector2(16, -14) * s]), INK)
		&"down":
			draw_line(c + Vector2(0, -30) * s, c + Vector2(0, 20) * s, INK, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, 34) * s, c + Vector2(-16, 14) * s, c + Vector2(16, 14) * s]), INK)
		&"gear":
			var gear := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48.0
				var r := (34.0 if (i / 3) % 2 == 0 else 25.0) * s
				gear.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(gear, INK)
			draw_circle(c, 10.0 * s, Color.WHITE)
		&"door":
			draw_rect(Rect2(c + Vector2(-22, -38) * s, Vector2(44, 76) * s), INK, false, w)
			draw_rect(Rect2(c + Vector2(4, -4) * s, Vector2(14, 5) * s), ACCENT)
		&"handle":
			draw_circle(c + Vector2(-18, 0) * s, 12.0 * s, INK)
			draw_line(c + Vector2(-18, 0) * s, c + Vector2(30, 0) * s, ACCENT, w * 1.6, true)
		&"spool":
			draw_circle(c, 36.0 * s, INK)
			draw_circle(c, 26.0 * s, Color(0.93, 0.89, 0.8))
			draw_circle(c, 11.0 * s, INK)
			draw_circle(c, 5.0 * s, Color.WHITE)
		&"robot":
			draw_line(c + Vector2(10, -26) * s, c + Vector2(16, -40) * s, INK, w * 0.6, true)
			draw_circle(c + Vector2(16, -40) * s, 6.0 * s, ACCENT)
			var head := Rect2(c + Vector2(-32, -24) * s, Vector2(64, 48) * s)
			draw_rect(head, Color(0.93, 0.89, 0.8))
			draw_rect(head, INK, false, w * 0.7)
			draw_rect(Rect2(c + Vector2(-22, -14) * s, Vector2(44, 26) * s), INK)
			draw_rect(Rect2(c + Vector2(-13, -8) * s, Vector2(7, 13) * s), COOL)
			draw_rect(Rect2(c + Vector2(6, -8) * s, Vector2(7, 13) * s), COOL)
		&"check":
			draw_polyline(PackedVector2Array([c + Vector2(-28, 2) * s, c + Vector2(-8, 22) * s, c + Vector2(30, -22) * s]), Color(0.3, 0.65, 0.35), w * 1.4, true)
		&"cross":
			draw_line(c + Vector2(-24, -24) * s, c + Vector2(24, 24) * s, Color(0.8, 0.25, 0.2), w * 1.3, true)
			draw_line(c + Vector2(24, -24) * s, c + Vector2(-24, 24) * s, Color(0.8, 0.25, 0.2), w * 1.3, true)
		&"frame":
			draw_rect(Rect2(c + Vector2(-34, -28) * s, Vector2(68, 56) * s), Color(0.55, 0.38, 0.22))
			draw_rect(Rect2(c + Vector2(-24, -18) * s, Vector2(48, 36) * s), Color(0.85, 0.82, 0.74))
		&"house":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -2) * s, c + Vector2(0, -32) * s, c + Vector2(30, -2) * s]), ACCENT)
			draw_rect(Rect2(c + Vector2(-22, -2) * s, Vector2(44, 34) * s), INK, false, w * 0.8)
		&"book":
			draw_rect(Rect2(c + Vector2(-30, -26) * s, Vector2(60, 52) * s), COOL)
			draw_line(c + Vector2(0, -26) * s, c + Vector2(0, 26) * s, INK, w * 0.6, true)
		&"sun":
			draw_circle(c, 18.0 * s, ENERGY)
			for k in 8:
				var d := Vector2.from_angle(TAU * k / 8.0)
				draw_line(c + d * 26.0 * s, c + d * 38.0 * s, ENERGY, w * 0.7, true)
		&"wrench":
			draw_line(c + Vector2(-26, 26) * s, c + Vector2(14, -14) * s, INK, w * 1.4, true)
			draw_arc(c + Vector2(18, -18) * s, 14.0 * s, PI * 0.1, PI * 1.6, 16, INK, w * 1.2, true)
			draw_circle(c + Vector2(-26, 26) * s, 6.0 * s, ACCENT)
		&"damage":
			# Éclair de choc (étincelle brisée).
			draw_polyline(PackedVector2Array([c + Vector2(6, -38) * s, c + Vector2(-14, 2) * s, c + Vector2(6, 2) * s,
					c + Vector2(-8, 38) * s]), ENERGY, w * 1.2, true)
			draw_line(c + Vector2(16, -10) * s, c + Vector2(30, -18) * s, ACCENT, w * 0.7, true)
			draw_line(c + Vector2(-24, 16) * s, c + Vector2(-34, 24) * s, ACCENT, w * 0.7, true)
		&"filament":
			var coil := PackedVector2Array()
			for k in 40:
				var t := float(k) / 39.0
				coil.append(c + Vector2.from_angle(t * TAU * 2.2) * (8.0 + t * 24.0) * s)
			draw_polyline(coil, ACCENT, w * 0.8, true)
		&"ant", &"ant_soldier", &"ant_queen":
			# Fourmi de profil : trois segments, pattes, antenne, œil.
			var body := Color(0.45, 0.24, 0.16) if name == &"ant" else (Color(0.36, 0.14, 0.1) if name == &"ant_soldier" else Color(0.45, 0.18, 0.26))
			var head_r := 10.0 if name == &"ant" else 13.0
			var abdomen := Vector2(16, 12) if name != &"ant_queen" else Vector2(22, 16)
			for k in 3:
				var x := -14.0 + k * 12.0
				draw_line(c + Vector2(x, 4) * s, c + Vector2(x - 6, 22) * s, INK, w * 0.5, true)
			_draw_ellipse(c + Vector2(-22, 0) * s, abdomen * s, body)
			_draw_ellipse(c + Vector2(-2, 0) * s, Vector2(9, 7) * s, body)
			draw_circle(c + Vector2(18, -4) * s, head_r * s, body)
			draw_circle(c + Vector2(21, -7) * s, 4.0 * s, Color.WHITE)
			draw_circle(c + Vector2(22, -7) * s, 2.0 * s, INK)
			draw_polyline(PackedVector2Array([c + Vector2(22, -14) * s, c + Vector2(28, -30) * s, c + Vector2(36, -32) * s]), INK, w * 0.45, true)
			if name == &"ant_soldier":
				draw_line(c + Vector2(28, 2) * s, c + Vector2(38, 8) * s, ACCENT, w * 0.8, true)
			if name == &"ant_queen":
				draw_colored_polygon(PackedVector2Array([c + Vector2(10, -16) * s, c + Vector2(14, -26) * s, c + Vector2(18, -18) * s, c + Vector2(22, -26) * s, c + Vector2(26, -16) * s]), ENERGY)
		&"shield":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -28) * s, c + Vector2(26, -28) * s, c + Vector2(22, 8) * s, c + Vector2(0, 32) * s, c + Vector2(-22, 8) * s]), Color(0.93, 0.89, 0.8))
			draw_polyline(PackedVector2Array([c + Vector2(-26, -28) * s, c + Vector2(26, -28) * s, c + Vector2(22, 8) * s, c + Vector2(0, 32) * s, c + Vector2(-22, 8) * s, c + Vector2(-26, -28) * s]), INK, w * 0.7, true)
			draw_line(c + Vector2(-20, -6) * s, c + Vector2(20, -6) * s, ACCENT, w, true)
		&"cannon":
			draw_rect(Rect2(c + Vector2(-28, -10) * s, Vector2(40, 20) * s), Color(0.93, 0.89, 0.8))
			draw_rect(Rect2(c + Vector2(-28, -10) * s, Vector2(40, 20) * s), INK, false, w * 0.6)
			draw_rect(Rect2(c + Vector2(12, -6) * s, Vector2(18, 12) * s), ACCENT)
			draw_circle(c + Vector2(38, 0) * s, 5.0 * s, COOL)
		&"acid":
			draw_circle(c + Vector2(0, 8) * s, 18.0 * s, Color(0.55, 0.85, 0.2))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 0) * s, c + Vector2(0, -32) * s, c + Vector2(14, 0) * s]), Color(0.55, 0.85, 0.2))
		&"lock":
			draw_arc(c + Vector2(0, -8) * s, 14.0 * s, PI, TAU, 16, INK, w, true)
			draw_rect(Rect2(c + Vector2(-20, -8) * s, Vector2(40, 32) * s), ACCENT)
		&"plastic":
			for k in 3:
				draw_circle(c + Vector2(-14 + k * 14, (k % 2) * 10 - 4) * s, 11.0 * s, COOL)
				draw_circle(c + Vector2(-17 + k * 14, (k % 2) * 10 - 8) * s, 3.5 * s, Color(1, 1, 1, 0.8))
		_:
			draw_circle(c, 10.0 * s, INK)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 24:
		points.append(center + Vector2.from_angle(TAU * k / 24.0) * radii)
	draw_colored_polygon(points, color)
