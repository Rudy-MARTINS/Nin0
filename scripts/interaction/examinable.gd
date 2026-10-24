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
		prompt = "Prendre" if discovery.collectible else _curious_prompt()
	interacted.connect(_on_interacted)
	refresh_from_save()


## Un objet déjà emporté (sauvegarde) n'apparaît plus.
func refresh_from_save() -> void:
	if discovery and discovery.collectible and GameState.has_discovery(discovery.id):
		_remove()
	elif discovery and GameState.has_discovery(discovery.id):
		prompt = "Revoir"


## Verbe varié selon l'objet (Nin0 n'« examine » pas tout de la même façon).
func _curious_prompt() -> String:
	var verbs := ["Observer", "Regarder de plus près", "Inspecter", "Examiner", "Jeter un œil"]
	return verbs[absi(hash(discovery.id)) % verbs.size()]


func _on_interacted(_by: Node3D) -> void:
	if discovery == null:
		return
	if discovery.collectible:
		_remove()
	examined.emit(discovery)
	prompt = "Revoir"


func _remove() -> void:
	enabled = false
	if visual:
		visual.visible = false
