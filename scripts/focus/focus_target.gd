class_name FocusTarget
extends Marker3D
## Élément identifiable avec la vision focalisée de NINO (mécanisme, passage, objet…).
## Placer ce marqueur sur l'élément ; FocusVision le détecte quand il est visé.

signal identified(target: FocusTarget)

@export var id: StringName
## Taille approximative de l'élément (unités) : tolérance de visée.
@export var radius := 0.6
## Pensée affichée à l'identification.
@export var thought_icons: Array[StringName] = [&"exclamation"]
@export var thought_text := ""
@export var enabled := true
## Affiche un repère discret dans la vision focalisée (aide si l'élément est peu visible).
@export var show_marker := false

var is_identified := false


func _ready() -> void:
	add_to_group(&"focus_targets")


func mark_identified() -> void:
	if is_identified:
		return
	is_identified = true
	identified.emit(self)
