class_name SpeciesCatalog
extends RefCounted
## Espèces connues du jeu (liste explicite : fonctionne dans un jeu exporté).
## Les futures espèces s'ajoutent ici, avec leur fiche .tres.

const PATHS := [
	"res://assets/species/ant_worker.tres",
	"res://assets/species/ant_soldier.tres",
	"res://assets/species/ant_queen.tres",
	"res://assets/species/spider.tres",
	"res://assets/species/roach.tres",
]


static func all() -> Array[SpeciesData]:
	var list: Array[SpeciesData] = []
	for path in PATHS:
		list.append(load(path) as SpeciesData)
	return list


static func find(id: StringName) -> SpeciesData:
	for data in all():
		if data.id == id:
			return data
	return null
