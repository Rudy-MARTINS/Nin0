class_name DiscoveryData
extends Resource
## Une découverte : un objet que NINO peut examiner (et éventuellement emporter).
## Réutilisable pour toutes les pièces : créer un fichier .tres par découverte.

@export var id: StringName
## Nom court affiché brièvement à la découverte (« Croquis de jambes »).
@export var title := ""
## Pensée de NINO : pictogrammes (voir ThoughtIcon.ICONS) et texte très court facultatif.
@export var thought_icons: Array[StringName] = [&"eye", &"question"]
@export var thought_text := ""
## Deuxième pensée facultative (déduction), affichée après la première.
@export var conclusion_icons: Array[StringName] = []
@export var conclusion_text := ""
## Si vrai, NINO emporte l'objet (il disparaît du décor).
@export var collectible := false
