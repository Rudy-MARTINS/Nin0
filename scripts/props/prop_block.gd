@tool
class_name PropBlock
extends StaticBody3D
## Élément de décor réutilisable : boîte ou cylindre aux arêtes adoucies,
## avec une collision assortie. Visible et modifiable dans l'éditeur.
##
## Pour une surface escaladable, cocher `climbable` (couche physique 2).

enum Shape { BOX, CYLINDER }

@export var shape: Shape = Shape.BOX:
	set(value):
		shape = value
		_queue_rebuild()
## Dimensions. Pour un cylindre : x = diamètre, y = hauteur.
@export var size := Vector3.ONE:
	set(value):
		size = value
		_queue_rebuild()
## Rayon d'arrondi des arêtes.
@export var bevel := 0.03:
	set(value):
		bevel = value
		_queue_rebuild()
@export var material: Material:
	set(value):
		material = value
		_queue_rebuild()
@export var climbable := false:
	set(value):
		climbable = value
		_queue_rebuild()
@export var collide := true:
	set(value):
		collide = value
		_queue_rebuild()
@export var cast_shadow := true:
	set(value):
		cast_shadow = value
		_queue_rebuild()

var _mesh_instance: MeshInstance3D
var _collision: CollisionShape3D
var _rebuild_queued := false


func _ready() -> void:
	_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_FRONT)
		_collision = CollisionShape3D.new()
		add_child(_collision, false, Node.INTERNAL_MODE_FRONT)

	if shape == Shape.BOX:
		_mesh_instance.mesh = MeshFactory.rounded_box(size, bevel)
		var box := BoxShape3D.new()
		box.size = size
		_collision.shape = box
	else:
		var radius := size.x * 0.5
		_mesh_instance.mesh = MeshFactory.lathe(
				MeshFactory.tire_profile(radius, size.y, minf(bevel, radius * 0.9)), 32)
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = size.y
		_collision.shape = cylinder
	_mesh_instance.material_override = material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_collision.disabled = not collide
	collision_layer = (1 | (2 if climbable else 0)) if collide else 0
	collision_mask = 0

