class_name Interactable
extends Area3D
## Zone d'interaction générique (couche physique 4 « interaction »).
## Le propriétaire écoute `interacted` et met à jour `prompt` / `enabled`.

signal interacted(by: Node3D)

const LAYER := 1 << 3

## Texte affiché après la touche, ex. « Examiner l'imprimante ».
@export var prompt := "Interagir"
@export var enabled := true
## Point regardé par Nin0 quand l'objet est à portée (sinon : position de la zone).
@export var look_point: Node3D


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


func get_look_position() -> Vector3:
	return look_point.global_position if look_point else global_position


func interact(by: Node3D) -> void:
	if enabled:
		interacted.emit(by)
