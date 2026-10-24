class_name BathroomZone
extends Node3D
## Salle de bain (zone 3), jouable au lot 5 : labyrinthe gauche (souvenir n° 2),
## labyrinthe droit gardé par les soldats, escabeau, arène du lavabo (reine).
## La progression est pilotée par GameWorld ; cette scène expose ses éléments.

signal entered

@onready var arena: SinkArena = $SinkArena
@onready var larvae: LarvaDropper = $MazeRight/Larvae
@onready var ticket_focus: FocusTarget = $MazeLeft/Ticket/TicketFocus


func _ready() -> void:
	($EntryZone as Area3D).body_entered.connect(func(body: Node3D) -> void:
		if body is NinoController:
			entered.emit())


func get_soldiers() -> Array[AntSoldier]:
	var list: Array[AntSoldier] = []
	for child in $Soldiers.get_children():
		if child is AntSoldier:
			list.append(child)
	return list


func any_soldier_engaged() -> bool:
	for soldier in get_soldiers():
		if soldier.is_engaged():
			return true
	return false


## Réinitialisation de zone (retour après une absence) : soldats à leur poste.
func reset_creatures() -> void:
	for soldier in get_soldiers():
		soldier.reset_to_post()
		soldier.calm(2.5)


func marker(name: String) -> Transform3D:
	return (get_node("Markers/" + name) as Node3D).global_transform
