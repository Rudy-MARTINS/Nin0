class_name SasZone
extends Node3D
## Sas (zone 2), jouable au lot 5 : décor, colonne d'ouvrières, porte du salon (élastique à percer,
## lot 7), porte de la cuisine (loquet). La mise en scène est pilotée par GameWorld.

signal salon_door_examined
signal encounter_zone_entered

@onready var column: AntColumn = $AntColumn
@onready var kitchen_door: KitchenDoor = $KitchenDoor
@onready var salon_door: SalonDoor = $SalonDoor
@onready var salon_inspect: Interactable = $SalonDoor/SalonDoorInspect


func _ready() -> void:
	salon_inspect.interacted.connect(func(_by: Node3D) -> void: salon_door_examined.emit())
	($EncounterZone as Area3D).body_entered.connect(func(body: Node3D) -> void:
		if body is NinoController:
			encounter_zone_entered.emit())


func marker(name: String) -> Transform3D:
	return (get_node("Markers/" + name) as Node3D).global_transform


func encounter_point(name: String) -> Vector3:
	return (get_node("Encounter/" + name) as Node3D).global_position
