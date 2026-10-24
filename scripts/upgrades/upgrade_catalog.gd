class_name UpgradeCatalog
extends RefCounted
## Liste des améliorations fabricables dans cette démo (une seule pour l'instant).
## Liste explicite : fonctionne aussi dans un jeu exporté.

const PATHS := [
	"res://assets/upgrades/legs.tres",
	"res://assets/upgrades/chassis_reinforcement_1.tres",
	"res://assets/upgrades/armor_1.tres",
	"res://assets/upgrades/cannon.tres",
	"res://assets/upgrades/charged_jump.tres",
]


static func all() -> Array[UpgradeData]:
	var list: Array[UpgradeData] = []
	for path in PATHS:
		list.append(load(path) as UpgradeData)
	return list


static func find(id: StringName) -> UpgradeData:
	for upgrade in all():
		if upgrade.id == id:
			return upgrade
	return null
