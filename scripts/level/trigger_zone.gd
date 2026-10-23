class_name TriggerZone
extends Area3D
## Zone qui détecte Nin0 (couche physique 3 « joueur »). Le directeur de niveau
## écoute `player_entered` pour les indices, points de réapparition et la fin.

signal player_entered(zone: TriggerZone)
signal player_exited(zone: TriggerZone)

## Identifiant lu par le directeur de niveau.
@export var id := &""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 2
	monitoring = true
	monitorable = false
	body_entered.connect(func(body: Node3D) -> void:
		if body is NinoController:
			player_entered.emit(self))
	body_exited.connect(func(body: Node3D) -> void:
		if body is NinoController:
			player_exited.emit(self))


func contains_player(player: NinoController) -> bool:
	return overlaps_body(player)
