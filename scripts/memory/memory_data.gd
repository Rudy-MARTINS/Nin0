class_name MemoryData
extends Resource
## Fragment d'archive (souvenir) : élément du monde qui, observé avec la vision
## focalisée, réveille un enregistrement endommagé dans la mémoire de Nin0.
## Le texte affiché est dégradé selon le nombre de fragments déjà retrouvés.

@export var id: StringName
## Emplacement dans les archives (1 à 7) ; l'ordre de découverte reste libre.
@export_range(1, 7) var slot := 1
## Nom neutre affiché dans les archives (ne révèle rien).
@export var title := ""
## Lignes de l'enregistrement, avant dégradation. Texte provisoire : à valider.
@export var lines: PackedStringArray = []
## Objet associé (désignation discrète, affichée dans les archives).
@export var object_name := ""
## Commentaire de Nin0 après l'analyse (son interprétation, pas une information).
@export var comment := ""
## Mise en scène particulière (vide = enregistrement parasité habituel).
## « todo » : Nin0 déchiffre lui-même un document manuscrit, ligne par ligne.
@export var presentation: StringName
