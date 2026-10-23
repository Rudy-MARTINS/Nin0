class_name ObservationProfile
extends Resource
## Paramètres communs d'observation (vision focalisée). Chaque cible en référence un :
## une même règle pour toutes les observations, réglable sans toucher au code.

## Distance maximale de reconnaissance (unités ; 10 unités = 1 m).
@export var max_distance := 14.0
## Temps de visée continue nécessaire.
@export var lock_time := 0.7
## Tolérance de visée minimale (degrés), ajoutée à la taille apparente de la cible.
@export var min_aim_degrees := 2.5
## Multiplie la tolérance due à la taille apparente (1 = rayon de la cible).
@export var aim_scale := 1.0
## Angle maximal entre la face observée et le regard (180 = depuis n'importe où).
@export_range(0.0, 180.0) var max_view_angle := 180.0
## La cible doit être directement visible (pas d'obstacle entre Nin0 et elle).
@export var require_line_of_sight := true
