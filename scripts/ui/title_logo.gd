class_name TitleLogo
extends Control
## Logo « Nin0 » (lot 7, glow-up) : les lettres « Nin » en crème, suivies d'un « 0 » qui
## est l'écran-visage de Nin0 — cadre arrondi, deux yeux cyan qui clignent, petite antenne
## à bulle orange. Dessiné en vectoriel (aucune image externe), il respire doucement.

const CREAM := Color(0.97, 0.93, 0.85)
const SCREEN := Color(0.06, 0.08, 0.11)
const CYAN := Color(0.45, 0.95, 1.0)
const ORANGE := Color(0.96, 0.55, 0.2)

@export var font_size := 124

var _time := 0.0
var _blink := 0.0
var _next_blink := 2.2
var _font: Font


func _ready() -> void:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.9
	variation.spacing_glyph = 10
	_font = variation
	custom_minimum_size = Vector2(font_size * 3.3, font_size * 1.25)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.16
		_next_blink = randf_range(2.6, 5.0)
	_blink = maxf(_blink - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var baseline := font_size * 1.0
	var text := "Nin"
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Ombre portée douce, puis lettres.
	draw_string(_font, Vector2(4, baseline + 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.35))
	draw_string(_font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CREAM)
	# Le « 0 » : écran-visage de Nin0.
	var h := font_size * 0.74
	var w := h * 0.82
	var origin := Vector2(width + font_size * 0.08, baseline - h)
	var rect := Rect2(origin, Vector2(w, h))
	var radius := w * 0.26
	_rounded(rect.grow(font_size * 0.07), radius + font_size * 0.06, CREAM)
	_rounded(rect, radius, SCREEN)
	# Lueur de l'écran, yeux qui respirent et clignent.
	var glow := 0.5 + 0.5 * sin(_time * 1.7)
	var eye_h := h * 0.36 * (0.1 if _blink > 0.0 else 1.0)
	for side in [-1.0, 1.0]:
		var c := rect.get_center() + Vector2(side * w * 0.2, -h * 0.02)
		draw_circle(c, w * 0.2, Color(CYAN.r, CYAN.g, CYAN.b, 0.08 + 0.06 * glow))
		_ellipse(c, Vector2(w * 0.1, eye_h * 0.5), CYAN)
		if _blink <= 0.0:
			draw_circle(c + Vector2(-w * 0.03, -eye_h * 0.18), w * 0.025, Color(1, 1, 1, 0.85))
	# Antenne : tige et bulle orange, qui oscille à peine.
	var tip := Vector2(rect.end.x - w * 0.18, rect.position.y - font_size * 0.07)
	var top := tip + Vector2(font_size * 0.05 + sin(_time * 2.1) * 2.0, -font_size * 0.2)
	draw_line(tip, top, CREAM, font_size * 0.035, true)
	draw_circle(top, font_size * 0.06, ORANGE)
	draw_circle(top + Vector2(-2, -2), font_size * 0.02, Color(1, 0.85, 0.6))


func _rounded(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	draw_style_box(box, rect)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 28:
		points.append(center + Vector2.from_angle(TAU * k / 28.0) * radii)
	draw_colored_polygon(points, color)
