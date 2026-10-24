class_name Seesaw
extends Node3D
## Bascule du salon (lot 7) : une grande règle posée sur un rouleau de ruban adhésif.
## Au repos, l'extrémité est (près du meuble TV) touche le sol. Nin0 est trop léger pour
## la faire basculer ; Nathan monte dessus, dépasse le point d'appui : la règle bascule,
## il s'assoit au bout ouest et la tient. L'extrémité est se lève alors à 4,4 u, juste
## sous le dessus du meuble TV (5,0) : premier puzzle de coopération.

signal tipped(held: bool)

const REST_DEGREES := -21.2
const HELD_DEGREES := 21.2

var held := false
var _tween: Tween

@onready var hold_spot: Marker3D = $HoldSpot
@onready var climb_spot: Marker3D = $ClimbSpot
@onready var inspect: Interactable = $SeesawInspect
@onready var focus: FocusTarget = $SeesawFocus
@onready var _pivot: Node3D = $Pivot


func _ready() -> void:
	($Pivot/Board as AnimatableBody3D).sync_to_physics = false
	_pivot.rotation.z = deg_to_rad(REST_DEGREES)
	add_to_group(&"companion_targets")


func set_held(on: bool, duration := 0.7) -> void:
	if held == on:
		return
	held = on
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK if on else Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_pivot, "rotation:z", deg_to_rad(HELD_DEGREES if on else REST_DEGREES), duration)
	Sfx.play(&"thud", -6.0, 0.9 if on else 1.1)
	tipped.emit(on)


## Point de la surface de la règle (local_x de -5,8 à l'ouest à 5,8 à l'est), en global.
func surface_point(local_x: float) -> Vector3:
	return _pivot.to_global(Vector3(local_x, 0.25, 0.0))


## Hauteur actuelle de l'extrémité est (côté meuble TV).
func east_end_height() -> float:
	return surface_point(5.8).y


## Point d'interaction pour Nathan (ordre « Interagis »).
func companion_point() -> Vector3:
	return climb_spot.global_position
