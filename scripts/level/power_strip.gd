class_name PowerStrip
extends Node3D
## Multiprise sous l'établi : son interrupteur alimente l'imprimante 3D.

signal switched_on

var is_on := false

@onready var interactable: Interactable = $Interactable
@onready var _rocker: Node3D = $Rocker
@onready var _rocker_material: StandardMaterial3D = ($Rocker/Switch as MeshInstance3D).material_override
@onready var _glow: OmniLight3D = $Rocker/Glow


func _ready() -> void:
	interactable.interacted.connect(func(_by: Node3D) -> void: switch_on())
	_apply_visuals()


func switch_on() -> void:
	if is_on:
		return
	is_on = true
	interactable.enabled = false
	Sfx.play(&"click")
	var tween := create_tween()
	tween.tween_property(_rocker, "rotation:x", deg_to_rad(-14.0), 0.12)
	await tween.finished
	_apply_visuals()
	Sfx.play(&"power_on", -4.0)
	switched_on.emit()


## État « allumé » sans animation (chargement d'une sauvegarde).
func set_on_immediately() -> void:
	is_on = true
	interactable.enabled = false
	_rocker.rotation.x = deg_to_rad(-14.0)
	_apply_visuals()


func _apply_visuals() -> void:
	# Interrupteur éteint : rouge sombre, mais repérable dans la pénombre.
	_rocker_material.emission_energy_multiplier = 2.2 if is_on else 0.6
	_glow.light_energy = 0.6 if is_on else 0.25
