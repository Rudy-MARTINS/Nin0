class_name TerrainZone
extends Area3D
## Zone de terrain : modifie la vitesse et le saut de Nin0 tant qu'il s'y trouve.
## - Gravier, cailloux : ralentit les roues seulement (les jambes passent).
## - Matière visqueuse (lavabo) : ralentit, enfonce, réduit le saut, rend vulnérable.
## Toujours réversible : en sortant de la zone, Nin0 retrouve ses capacités.

@export var key: StringName = &"terrain"
@export_range(0.05, 1.0) var wheels_factor := 1.0
@export_range(0.05, 1.0) var speed_factor := 1.0
@export_range(0.1, 1.0) var jump_factor := 1.0
## Dégâts reçus multipliés (enlisement).
@export var damage_factor := 1.0
## Enfoncement visuel maximal (unités) et vitesse d'enfoncement.
@export var sink_depth := 0.0
@export var sink_speed := 0.12

var _inside: NinoController
var _sink := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func is_nino_inside() -> bool:
	return _inside != null


func get_sink() -> float:
	return _sink


func _physics_process(delta: float) -> void:
	if sink_depth <= 0.0 or _inside == null:
		return
	# On s'enfonce à l'arrêt ou en marchant ; sauter ou sortir dégage aussitôt.
	if _inside.is_on_floor():
		_sink = minf(_sink + sink_speed * delta, sink_depth)
	else:
		_sink = maxf(_sink - delta * 0.6, 0.0)
	var depth_ratio := _sink / sink_depth
	_inside.set_speed_modifier(key, lerpf(1.0, speed_factor, 0.5 + depth_ratio * 0.5))
	_inside.get_visual().set_sink(_sink)


func _on_body_entered(body: Node3D) -> void:
	var nino := body as NinoController
	if nino == null:
		return
	_inside = nino
	if wheels_factor < 1.0:
		nino.set_wheels_modifier(key, wheels_factor)
	if speed_factor < 1.0:
		nino.set_speed_modifier(key, speed_factor)
	if jump_factor < 1.0:
		nino.set_jump_modifier(key, jump_factor)
	nino.damage_taken_multiplier = damage_factor
	if sink_depth > 0.0:
		Sfx.play(&"sludge", -8.0, randf_range(0.9, 1.1))


func _on_body_exited(body: Node3D) -> void:
	var nino := body as NinoController
	if nino == null or nino != _inside:
		return
	nino.clear_modifier(key)
	nino.damage_taken_multiplier = 1.0
	nino.get_visual().set_sink(0.0)
	_inside = null
	_sink = 0.0


## Désactive la zone (vidange) : rend à Nin0 ses capacités.
func disable() -> void:
	if _inside:
		_on_body_exited(_inside)
	set_deferred("monitoring", false)
