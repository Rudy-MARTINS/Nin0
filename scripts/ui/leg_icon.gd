@tool
extends Control
## Petite icône dessinée de l'amélioration « Jambes mécaniques ».

@export var line_color := Color(0.93, 0.89, 0.8)
@export var joint_color := Color(0.93, 0.48, 0.14)


func _draw() -> void:
	var s := size / 100.0
	for offset in [-14.0, 14.0]:
		var hip := Vector2(50.0 + offset, 18.0) * s
		var knee := Vector2(50.0 + offset + 10.0, 50.0) * s
		var ankle := Vector2(50.0 + offset, 80.0) * s
		draw_line(hip, knee, line_color, 7.0 * s.x, true)
		draw_line(knee, ankle, line_color.darkened(0.35), 6.0 * s.x, true)
		draw_line(ankle + Vector2(-9.0, 6.0) * s, ankle + Vector2(7.0, 6.0) * s, Color(0.25, 0.25, 0.27), 6.0 * s.x, true)
		for joint in [hip, knee, ankle]:
			draw_circle(joint, 5.0 * s.x, joint_color)
