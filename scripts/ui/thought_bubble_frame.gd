class_name ThoughtBubbleFrame
extends MarginContainer
## Fond de la bulle de pensée : forme arrondie et petits ronds menant à la tête de Nin0.

@export var fill := Color(0.98, 0.96, 0.92, 0.96)
@export var outline := Color(0.17, 0.15, 0.14, 0.35)

## Position de la tête de Nin0, relative à la bulle (mise à jour chaque image).
var tail_target := Vector2(-20.0, 60.0)

var _style := StyleBoxFlat.new()


func _ready() -> void:
	_style.bg_color = fill
	_style.border_color = outline
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(22)
	_style.shadow_color = Color(0, 0, 0, 0.25)
	_style.shadow_size = 6


func _draw() -> void:
	# Petits ronds de pensée entre la tête et la bulle.
	var start := Vector2(size.x * 0.18, size.y)
	var end := tail_target
	for i in 3:
		var t := 0.25 + i * 0.25
		var radius := lerpf(9.0, 4.0, float(i) / 2.0)
		var point := start.lerp(end, t)
		draw_circle(point, radius + 1.5, outline)
		draw_circle(point, radius, fill)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
