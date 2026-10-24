class_name ToppleRamp
extends Node3D
## Objet debout (ex. carnet) que Nin0 peut renverser : en tombant, il forme une rampe.
## Ce nœud marque le pivot (arête inférieure) ; l'enfant « Body » (AnimatableBody3D),
## placé sur le pivot, porte le visuel et la collision et c'est lui qui pivote
## (la physique suit ainsi la chute image par image).

signal toppled

## Angle final de la chute (degrés, autour de l'axe X local ; négatif = vers -Z).
@export var fallen_angle := -55.6
@export var fall_duration := 0.6

var is_toppled := false

@onready var interactable: Interactable = $Interactable
@onready var _body: Node3D = $Body


func _ready() -> void:
	interactable.enabled = false
	interactable.interacted.connect(func(_by: Node3D) -> void: topple())


func topple() -> void:
	if is_toppled:
		return
	is_toppled = true
	interactable.enabled = false
	Sfx.play(&"click", -10.0, 0.7)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_body, "rotation:x", deg_to_rad(fallen_angle), fall_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		Sfx.play(&"book_fall", -4.0)
		toppled.emit())
	# Petit rebond à l'impact.
	tween.tween_property(_body, "rotation:x", deg_to_rad(fallen_angle + 3.0), 0.08)
	tween.tween_property(_body, "rotation:x", deg_to_rad(fallen_angle), 0.12)


func set_toppled_immediately() -> void:
	is_toppled = true
	interactable.enabled = false
	_body.rotation.x = deg_to_rad(fallen_angle)
