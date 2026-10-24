class_name Examinable
extends Interactable
## Objet que Nin0 peut examiner : déclenche une pensée et enregistre une découverte.
## Le directeur de niveau écoute `examined` pour la mise en scène.

signal examined(data: DiscoveryData)

@export var discovery: DiscoveryData
## Nœud visuel masqué quand l'objet est emporté (découverte « collectible »).
@export var visual: Node3D


func _ready() -> void:
	super()
	if discovery and prompt == "Interagir":
		prompt = "Prendre" if discovery.collectible else "Examiner"
	interacted.connect(_on_interacted)
	refresh_from_save()


## Un objet déjà emporté (sauvegarde) n'apparaît plus.
func refresh_from_save() -> void:
	if discovery and discovery.collectible and GameState.has_discovery(discovery.id):
		_remove()


func _on_interacted(_by: Node3D) -> void:
	if discovery == null:
		return
	if discovery.collectible:
		_remove()
	examined.emit(discovery)


func _remove() -> void:
	enabled = false
	if visual:
		visual.visible = false
