class_name KitchenZone
extends Node3D
## Cuisine (zone 4), jouable au lot 6 : cuisine compacte en L (croquis du créateur).
## Niveaux : sol et dessous des meubles, plan de travail, évier et fenêtre,
## réfrigérateur, dessus des placards. Écosystème : araignées (prédatrices
## territoriales) et cafards (proies rapides) qui interagissent sans Nin0, y compris
## dans des zones visibles mais inaccessibles (arrière-plan simplifié au loin).
## La progression est pilotée par GameWorld ; cette scène expose ses éléments et tient
## le compte des affrontements (diagnostic, tests).

signal entered
signal salon_door_examined
signal examined(data: DiscoveryData)
signal spider_alerted(spider: KitchenSpider)

## Affrontements observés depuis le chargement : chasses, captures, échecs, défenses.
var stats := {&"hunts": 0, &"catches": 0, &"fails": 0, &"defends": 0, &"flees": 0}

var _cocoon_mesh: SphereMesh
var _cocoon_material: StandardMaterial3D


func _ready() -> void:
	($EntryZone as Area3D).body_entered.connect(func(body: Node3D) -> void:
		if body is NinoController:
			entered.emit())
	($SalonDoorInspect as Interactable).interacted.connect(func(_by: Node3D) -> void: salon_door_examined.emit())
	for node in $Discoveries.get_children():
		(node as Examinable).examined.connect(func(data: DiscoveryData) -> void: examined.emit(data))
	for spider in get_spiders():
		spider.hunt_started.connect(func(_s: KitchenSpider, _p: Node3D) -> void: stats[&"hunts"] += 1)
		spider.prey_caught.connect(_on_prey_caught)
		spider.hunt_failed.connect(func(_s: KitchenSpider, _p: Node3D) -> void: stats[&"fails"] += 1)
		spider.noticed_nino.connect(func(s: KitchenSpider) -> void: spider_alerted.emit(s))
	for roach in get_roaches():
		roach.defended.connect(func(_r: KitchenRoach) -> void: stats[&"defends"] += 1)
		roach.fled.connect(func(_r: KitchenRoach, _from: Node3D) -> void: stats[&"flees"] += 1)
	_cocoon_mesh = SphereMesh.new()
	_cocoon_mesh.radius = 0.08
	_cocoon_mesh.height = 0.26
	_cocoon_mesh.radial_segments = 10
	_cocoon_mesh.rings = 5
	_cocoon_material = StandardMaterial3D.new()
	_cocoon_material.albedo_color = Color(0.94, 0.93, 0.88)
	_cocoon_material.roughness = 0.9


func get_spiders() -> Array[KitchenSpider]:
	var list: Array[KitchenSpider] = []
	for child in $Creatures.get_children():
		if child is KitchenSpider:
			list.append(child)
	return list


func get_roaches() -> Array[KitchenRoach]:
	var list: Array[KitchenRoach] = []
	for child in $Creatures.get_children():
		if child is KitchenRoach:
			list.append(child)
	return list


## Une araignée défend son territoire contre Nin0 en ce moment.
func any_spider_engaged() -> bool:
	for spider in get_spiders():
		if spider.is_engaged():
			return true
	return false


## Retour après une absence : les araignées regagnent leur repaire, apaisées un instant.
func reset_creatures() -> void:
	for spider in get_spiders():
		if spider.state != KitchenSpider.State.FEED:
			spider.global_position = spider.home
			spider.prey = null
			spider._set_state(KitchenSpider.State.LURK)


func marker(name: String) -> Transform3D:
	return (get_node("Markers/" + name) as Node3D).global_transform


## Proie attrapée : un cocon de soie, emporté au repaire puis suspendu.
func _on_prey_caught(spider: KitchenSpider, _prey: Node3D, at: Vector3) -> void:
	stats[&"catches"] += 1
	var cocoon := MeshInstance3D.new()
	cocoon.mesh = _cocoon_mesh
	cocoon.material_override = _cocoon_material
	cocoon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cocoon.add_to_group(&"kitchen_cocoons")
	add_child(cocoon)
	cocoon.global_position = at
	spider.carry(cocoon)
