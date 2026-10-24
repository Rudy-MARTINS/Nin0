class_name SalonDoor
extends Node3D
## Porte sas ↔ salon (lot 7). Son pêne ne tient plus : la porte est retenue fermée par un
## gros élastique tendu entre la poignée et une patère du mur, côté sas. Une bille ronde
## rebondit dessus ; une bille pointue (inspirée du dard de la guêpe) le perce, il claque,
## et le courant d'air du salon entrouvre la porte vers l'intérieur du salon.
## La charnière est côté est : le battant entrouvert barre le passage direct vers la
## chambre et oriente Nin0 vers la première partie du salon (ouest).

signal opened
signal bounced
signal examined

## Juste assez pour que Nin0 se glisse dans l'entrebâillement.
@export var open_angle := 30.0
@export var open_duration := 2.6

var is_open := false
var _glow_light: OmniLight3D
var _glow: Tween

@onready var interactable: Interactable = $SalonDoorInspect
@onready var elastic_focus: FocusTarget = $ElasticFocus
@onready var _hinge: Node3D = $Hinge
@onready var _elastic: Node3D = $Elastic
@onready var _target: StaticBody3D = $ElasticTarget
@onready var _snapped: Node3D = $Snapped
@onready var _light: OmniLight3D = $SalonLight


func _ready() -> void:
	($Hinge/Panel as AnimatableBody3D).sync_to_physics = false
	_target.set_meta("projectile_receiver", self)
	_target.add_to_group(&"cannon_targets")
	_target.set_meta("aim_point", elastic_focus.global_position)
	_snapped.visible = false
	interactable.interacted.connect(func(_by: Node3D) -> void: examined.emit())


## Une bille a touché l'élastique : seule une pointe le perce.
func on_projectile_hit(projectile: Node3D) -> void:
	if is_open:
		return
	if bool(projectile.get_meta("piercing", false)):
		open()
		return
	# Bille ronde : l'élastique se tend, vibre, renvoie la bille.
	Sfx.play(&"boing", -6.0, 1.3)
	var wobble := create_tween()
	for k in 4:
		wobble.tween_property(_elastic, "scale:y", 1.0 + 0.9 * (1.0 - k * 0.25) * (1 if k % 2 == 0 else -1), 0.06)
	wobble.tween_property(_elastic, "scale:y", 1.0, 0.06)
	bounced.emit()


## Repère discret (lueur chaude pulsante) une fois que Nin0 a compris quoi viser.
func highlight(on: bool) -> void:
	if on and _glow_light == null and not is_open:
		_glow_light = OmniLight3D.new()
		_glow_light.light_color = Color(1.0, 0.85, 0.45)
		_glow_light.omni_range = 1.6
		_glow_light.light_energy = 0.0
		add_child(_glow_light)
		_glow_light.global_position = elastic_focus.global_position + Vector3(0.0, 0.0, -0.4)
		_glow = create_tween().set_loops()
		_glow.tween_property(_glow_light, "light_energy", 1.4, 0.7)
		_glow.tween_property(_glow_light, "light_energy", 0.25, 0.7)
	elif not on and _glow_light:
		if _glow:
			_glow.kill()
		_glow_light.queue_free()
		_glow_light = null


func open() -> void:
	if is_open:
		return
	is_open = true
	highlight(false)
	_disable_lock()
	Sfx.play(&"impact_small", -2.0, 1.8)
	Sfx.play(&"boing", -2.0, 0.7)
	_elastic.visible = false
	_snapped.visible = true
	var lash := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for child in _snapped.get_children():
		var end := child as Node3D
		lash.tween_property(end, "rotation:z", _hang_angle(end), 0.3)
	await get_tree().create_timer(0.6).timeout
	Sfx.play(&"door_creak", -6.0, 1.0)
	var swing := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	swing.tween_property(_hinge, "rotation:y", deg_to_rad(open_angle), open_duration)
	swing.tween_property(_light, "light_energy", 0.6, open_duration)
	await swing.finished
	opened.emit()


## Chargement : porte déjà entrouverte.
func set_open_immediately() -> void:
	is_open = true
	_disable_lock()
	_elastic.visible = false
	_snapped.visible = true
	for child in _snapped.get_children():
		(child as Node3D).rotation.z = _hang_angle(child)
	_hinge.rotation.y = deg_to_rad(open_angle)
	_light.light_energy = 0.6


## Bouts de l'élastique coupé : ils retombent le long du mur et de la porte.
func _hang_angle(end: Node3D) -> float:
	return -1.3 if String(end.name).ends_with("A") else 1.3


func _disable_lock() -> void:
	interactable.enabled = false
	elastic_focus.enabled = false
	_target.remove_from_group(&"cannon_targets")
	_target.collision_layer = 0
