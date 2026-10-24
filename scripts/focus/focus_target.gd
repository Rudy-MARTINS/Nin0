class_name FocusTarget
extends Marker3D
## Élément identifiable avec la vision focalisée de Nin0 (mécanisme, passage, objet,
## souvenir…). Placer ce marqueur sur l'élément ; FocusVision le détecte quand il est
## visé, assez proche, sous un angle valable, sans obstacle, pendant assez longtemps.

signal identified(target: FocusTarget)

@export var id: StringName
## Taille approximative de l'élément (unités) : tolérance de visée.
@export var radius := 0.6
## Règles d'observation (portée, angle, temps de visée…). Vide = profil par défaut.
@export var profile: ObservationProfile
## Normale de la face observable (repère local). Nulle = observable de partout.
@export var facing := Vector3.ZERO
## Souvenir associé : l'observer l'ajoute aux archives fragmentées.
@export var memory: MemoryData
## Espèce associée (créature) : l'observer l'ajoute à l'encyclopédie biologique.
@export var species: SpeciesData
## Pensée affichée à l'identification.
@export var thought_icons: Array[StringName] = [&"exclamation"]
@export var thought_text := ""
@export var enabled := true
## Affiche un repère discret dans la vision focalisée (aide si l'élément est peu visible).
@export var show_marker := false

var is_identified := false


func _ready() -> void:
	add_to_group(&"focus_targets")


func mark_identified(silent := false) -> void:
	if is_identified:
		return
	is_identified = true
	if not silent:
		identified.emit(self)


## Direction (monde) de la face observable, ou Vector3.ZERO.
func get_facing() -> Vector3:
	if facing == Vector3.ZERO:
		return Vector3.ZERO
	return (global_basis * facing).normalized()
