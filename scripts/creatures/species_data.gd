class_name SpeciesData
extends Resource
## Fiche de l'encyclopédie biologique : une espèce analysée par Nin0 avec sa vision
## focalisée. Un fichier .tres par espèce ; les fiches se consultent dans l'inventaire.
## Le texte est l'analyse de Nin0, pas celle d'un narrateur.

@export var id: StringName
@export var display_name := ""
@export var classification := ""
@export_multiline var description := ""
@export var behavior := ""
@export var traits: PackedStringArray = []
## Idée mécanique inspirée par l'espèce (vide si aucune).
@export var mechanical_inspiration := ""
## Plan débloqué par l'analyse (identifiant de découverte, vide si aucun).
@export var unlocks_plan: StringName
## Pictogramme (voir ThoughtIcon) et couleur de la fiche.
@export var icon: StringName = &"ant"
@export var color := Color(0.55, 0.32, 0.22)
