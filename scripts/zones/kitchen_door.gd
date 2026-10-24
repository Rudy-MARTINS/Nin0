class_name KitchenDoor
extends Node3D
## Porte sas ↔ cuisine (lot 5). Fermée par un crochet posé en hauteur sur le chambranle,
## hors de portée de Nin0. Une bille du canon peut soulever ce crochet léger (et non
## abaisser une poignée) : la porte se libère et s'entrouvre vers la cuisine.

signal unlocked
signal examined

## Entrouverte juste assez pour laisser passer Nin0 (lot 5.1 : 34° → 16°).
@export var open_angle := 16.0
@export var open_duration := 2.4

var is_unlocked := false
var _glow: Tween
var _glow_light: OmniLight3D

@onready var interactable: Interactable = $KitchenDoorInspect
@onready var _hinge: Node3D = $Hinge
@onready var _hook: Node3D = $HookPivot
@onready var _light: OmniLight3D = $KitchenLight
@onready var latch_focus: FocusTarget = $HookPivot/LatchFocus


func _ready() -> void:
	# Le battant suit la charnière (voir ClosetDoor).
	($Hinge/Panel as AnimatableBody3D).sync_to_physics = false
	$HookPivot/HookTarget.set_meta("projectile_receiver", self)
	var target := $HookPivot/HookTarget as Node3D
	target.add_to_group(&"cannon_targets")
	target.set_meta("aim_point", latch_focus.global_position)
	interactable.interacted.connect(func(_by: Node3D) -> void: examined.emit())


## Une bille a touché le crochet.
func on_projectile_hit(_projectile: Node3D) -> void:
	unlock()


## Met le crochet en valeur (lueur pulsante) tant qu'il reste à viser.
func highlight(on: bool) -> void:
	if on and _glow_light == null:
		_glow_light = OmniLight3D.new()
		_glow_light.light_color = Color(1.0, 0.85, 0.45)
		_glow_light.omni_range = 1.4
		_glow_light.light_energy = 0.0
		_hook.add_child(_glow_light)
		_glow_light.position = Vector3(0.3, 0.0, 0.5)
		_glow = create_tween().set_loops()
		_glow.tween_property(_glow_light, "light_energy", 1.6, 0.6)
		_glow.tween_property(_glow_light, "light_energy", 0.3, 0.6)
	elif not on and _glow_light:
		if _glow:
			_glow.kill()
		_glow_light.queue_free()
		_glow_light = null


func unlock() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	highlight(false)
	($HookPivot/HookTarget as Node3D).remove_from_group(&"cannon_targets")
	interactable.enabled = false
	latch_focus.enabled = false
	Sfx.play(&"impact_small", -4.0, 1.3)
	var hook := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hook.tween_property(_hook, "rotation:x", deg_to_rad(-85.0), 0.35)
	await hook.finished
	Sfx.play(&"unlock", -4.0)
	await get_tree().create_timer(0.4).timeout
	Sfx.play(&"door_creak", -6.0, 1.2)
	var swing := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(_hinge, "rotation:y", deg_to_rad(open_angle), open_duration)
	swing.tween_property(_light, "light_energy", 0.45, open_duration)
	await swing.finished
	unlocked.emit()


## Chargement : porte déjà ouverte.
func set_unlocked_immediately() -> void:
	is_unlocked = true
	interactable.enabled = false
	latch_focus.enabled = false
	_hook.rotation.x = deg_to_rad(-85.0)
	_hinge.rotation.y = deg_to_rad(open_angle)
	_light.light_energy = 0.45
	($HookPivot/HookTarget as Node3D).remove_from_group(&"cannon_targets")
