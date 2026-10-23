class_name NinoVisual
extends Node3D
## Représentation provisoire de Nino : roues qui tournent, inclinaison, yeux qui clignent.
## Aucune logique de gameplay ici : uniquement de l'affichage.

@export var wheel_radius := 0.07
## Inclinaison maximale vers l'avant à pleine vitesse (degrés).
@export var max_lean_degrees := 6.0
@export var blink_interval := Vector2(2.5, 5.0)
@export var blink_duration := 0.12

var _blink_timer := 0.0
var _blink_time_left := 0.0
var _eye_openness := 1.0  # 1 = ouverts, < 1 = plissés (concentration)

@onready var _wheels: Array[Node] = $Wheels.get_children()
@onready var _eyes: Node3D = $Body/Eyes


func _ready() -> void:
	_blink_timer = randf_range(blink_interval.x, blink_interval.y)


func _process(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_time_left = blink_duration
		_blink_timer = randf_range(blink_interval.x, blink_interval.y)
	_blink_time_left = maxf(_blink_time_left - delta, 0.0)
	var target_scale := 0.1 if _blink_time_left > 0.0 else _eye_openness
	_eyes.scale.y = lerpf(_eyes.scale.y, target_scale, 1.0 - exp(-30.0 * delta))


## speed : vitesse signée (u/s) ; speed_ratio : vitesse / vitesse max.
func update_motion(speed: float, speed_ratio: float, delta: float) -> void:
	for wheel in _wheels:
		(wheel as Node3D).rotation.x -= speed / wheel_radius * delta
	var lean := -deg_to_rad(max_lean_degrees) * clampf(speed_ratio, -1.0, 1.0)
	rotation.x = lerpf(rotation.x, lean, 1.0 - exp(-8.0 * delta))


func set_climbing(climbing: bool) -> void:
	_eye_openness = 0.6 if climbing else 1.0
