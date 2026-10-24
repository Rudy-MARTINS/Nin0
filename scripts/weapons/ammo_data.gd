class_name AmmoData
extends Resource
## Type de munition du canon. Lot 5 : billes de plastique. Lot 7 : billes pointues
## (inspirées du dard de la guêpe), qui percent et déclenchent certains mécanismes.

@export var id: StringName
@export var title := ""
@export var speed := 14.0
@export var gravity := 2.5
## Portée (u) : 2 m à l'échelle de Nin0, assez pour un crochet de porte.
@export var max_range := 26.0
@export var damage := 1
@export var radius := 0.035
@export var color := Color(0.3, 0.55, 0.95)
## Coût en plastique à projectiles par tir.
@export var cost := 1
## Pointue : perce (serrures à goupille, matières tendues) au lieu de rebondir.
@export var piercing := false
## Amélioration nécessaire pour utiliser cette munition (vide : toujours disponible).
@export var requires_upgrade: StringName
