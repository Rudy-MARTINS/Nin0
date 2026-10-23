class_name SpoolSlot
extends Area3D
## Emplacement où une bobine poussée vient s'encastrer pour former un passage.
## La position finale est donnée par le nœud enfant « Target ».

signal filled(spool: PushableSpool)

var spool: PushableSpool

@onready var _target: Node3D = $Target


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func is_filled() -> bool:
	return spool != null


func get_target_transform() -> Transform3D:
	return _target.global_transform


## Remplit l'emplacement sans animation (sauvegarde).
func fill_immediately(candidate: PushableSpool) -> void:
	spool = candidate
	candidate.set_slotted_immediately(get_target_transform())


func _on_body_entered(body: Node3D) -> void:
	var candidate := body as PushableSpool
	if candidate == null or spool != null or candidate.is_slotted:
		return
	spool = candidate
	candidate.snap_into(get_target_transform())
	filled.emit(candidate)
