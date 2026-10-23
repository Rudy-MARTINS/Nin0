class_name ClosetDoor
extends Node3D
## Grande porte du placard (vers le sas). Poignée à levier (bec-de-cane) :
## NINO, trop léger pour tourner un bouton, s'y suspend et l'abaisse de son poids.
## Ce nœud est placé sur l'axe des gonds ; la porte s'ouvre vers l'extérieur.

signal opened

## Angle d'ouverture (degrés, autour de Y).
@export var open_angle := 80.0
@export var open_duration := 3.2

var is_open := false

@onready var interactable: Interactable = $Interactable
@onready var _hinge: Node3D = $Hinge
@onready var _lever_pivot: Node3D = $Hinge/LeverPivot
@onready var _grip_point: Node3D = $Hinge/LeverPivot/GripPoint


func _ready() -> void:
	interactable.enabled = false


## Position où NINO se suspend (suit le levier et la porte).
func get_grip_position() -> Vector3:
	return _grip_point.global_position


## NINO, suspendu au levier, l'abaisse de son poids : le pêne se libère.
func pull_lever(rider: Node3D = null) -> void:
	if is_open:
		return
	is_open = true
	interactable.enabled = false
	var lever := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	lever.tween_property(_lever_pivot, "rotation:x", deg_to_rad(38.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if rider:
		lever.parallel().tween_method(func(_v: float) -> void:
			rider.global_position = get_grip_position() + Vector3.DOWN * 0.55, 0.0, 1.0, 0.6)
	await lever.finished
	Sfx.play(&"door_latch", 0.0, 0.6)


## La porte, déverrouillée, pivote lentement vers l'extérieur ; le levier remonte.
func swing_open() -> void:
	Sfx.play(&"door_creak", -4.0)
	var swing := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	swing.tween_property(_lever_pivot, "rotation:x", 0.0, 0.4)
	swing.parallel().tween_property(_hinge, "rotation:y", deg_to_rad(open_angle), open_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await swing.finished
	opened.emit()
