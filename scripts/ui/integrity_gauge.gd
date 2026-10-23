class_name IntegrityGauge
extends Control
## Jauge d'intégrité (barre principale) et de bouclier (fine barre au-dessus).
## Graduation tous les 25 points : un renfort de châssis allonge visiblement la barre.

const POINTS_PER_PIXEL := 2.0 / 3.0  # 100 points = 150 px

var integrity := 100.0
var integrity_max := 100.0
var shield := 20.0
var shield_max := 20.0

var _shown_integrity := 100.0
var _flash := 0.0


func set_values(new_integrity: float, new_max: float, new_shield: float, new_shield_max: float) -> void:
	if new_integrity < integrity - 0.5:
		_flash = 1.0
	integrity = new_integrity
	integrity_max = new_max
	shield = new_shield
	shield_max = new_shield_max
	custom_minimum_size = Vector2(integrity_max / POINTS_PER_PIXEL + 4.0, 22.0)
	queue_redraw()


func _process(delta: float) -> void:
	var before := _shown_integrity
	_shown_integrity = move_toward(_shown_integrity, integrity, delta * 40.0)
	_flash = maxf(_flash - delta * 1.5, 0.0)
	if before != _shown_integrity or _flash > 0.0:
		queue_redraw()


func _draw() -> void:
	var width := integrity_max / POINTS_PER_PIXEL
	var bar := Rect2(2.0, 8.0, width, 12.0)
	draw_rect(bar.grow(2.0), Color(0.04, 0.035, 0.03, 0.75))
	var ratio := integrity / maxf(integrity_max, 1.0)
	var color := Color(1.0, 0.86, 0.62).lerp(Color(1.0, 0.36, 0.25), clampf((0.5 - ratio) * 2.0, 0.0, 1.0))
	# Partie perdue récemment (traîne), puis intégrité actuelle.
	draw_rect(Rect2(bar.position, Vector2(width * _shown_integrity / integrity_max, bar.size.y)), Color(1.0, 0.45, 0.3, 0.6))
	draw_rect(Rect2(bar.position, Vector2(width * ratio, bar.size.y)), color.lerp(Color.WHITE, _flash * 0.6))
	var tick := 25.0
	while tick < integrity_max - 0.1:
		var x := bar.position.x + width * tick / integrity_max
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(0.04, 0.035, 0.03, 0.8), 2.0)
		tick += 25.0
	# Bouclier : fine barre cyan, longueur proportionnelle à sa capacité.
	var shield_width := shield_max / POINTS_PER_PIXEL
	draw_rect(Rect2(2.0, 1.0, shield_width, 4.0), Color(0.04, 0.035, 0.03, 0.6))
	draw_rect(Rect2(2.0, 1.0, shield_width * shield / maxf(shield_max, 1.0), 4.0), Color(0.45, 0.92, 1.0, 0.9))
