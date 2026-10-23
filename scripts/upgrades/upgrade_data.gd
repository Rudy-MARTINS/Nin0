class_name UpgradeData
extends Resource
## Amélioration fabriquée à l'imprimante (donnée configurable).
##
## Catégories (voir docs/SYSTEMES_FUTURS.md) :
## - MAJOR : grandes capacités d'exploration (jambes, micro-réservoir…), permanentes.
## - MODULE : modules secondaires équipables dans un emplacement (non développés).
## - EVOLUTION : renforcement d'un élément existant ; un niveau II remplace le niveau I.

enum Category { MAJOR, MODULE, EVOLUTION }

@export var id: StringName
@export var title := ""
@export_multiline var description := ""
@export var category := Category.EVOLUTION
## Famille (modules : défense active, attaque, planage… ; évolutions : châssis…).
@export var family: StringName
## Niveau dans la famille (I = 1, II = 2…).
@export var tier := 1
## Amélioration remplacée par celle-ci (ex. Renfort II remplace Renfort I).
@export var replaces: StringName
## Fragments de filament nécessaires à la fabrication.
@export var cost_fragments := 0
## Découverte (plan) nécessaire pour que l'imprimante propose la fabrication.
@export var required_discovery: StringName
## Effets appliqués tant que l'amélioration est possédée.
@export var max_integrity_bonus := 0.0
