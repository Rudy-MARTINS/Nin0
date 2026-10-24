class_name SalonRaider
extends Node3D
## Cafard « pilleur » du salon (lot 7, séquence de protection) : sort de sous le canapé et
## file vers Nathan, qui tient la bascule. S'il l'atteint, Nathan prend peur (il n'est
## jamais blessé) et le cafard repart sous le canapé. Deux billes (ou une bille pointue)
## le mettent KO : il se retourne puis disparaît.

signal reached(raider: SalonRaider)
signal knocked_out(raider: SalonRaider)

const SPECIES: SpeciesData = preload("res://assets/species/roach.tres")

@export var speed := 1.5
@export var max_health := 2

var target: Node3D
var home := Vector3.ZERO
## Points de passage (contourner les meubles), dans l'ordre de l'aller.
var path: PackedVector3Array = []
var _leg := 0
var health := 2
var body: RoachBody
var hit_body: StaticBody3D
var _ko := false
var _retreat := false
var _emote: Label3D


func _ready() -> void:
	body = RoachBody.new()
	body.body_length = 0.3
	body.body_color = Color(0.36, 0.2, 0.1)
	add_child(body)
	hit_body = StaticBody3D.new()
	hit_body.collision_layer = 32
	hit_body.collision_mask = 0
	hit_body.set_meta("projectile_receiver", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.18, 0.4)
	shape.shape = box
	shape.position = Vector3(0.0, 0.09, 0.0)
	hit_body.add_child(shape)
	add_child(hit_body)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 56
	_emote.pixel_size = 0.004
	_emote.outline_size = 10
	_emote.modulate = Color(1.0, 0.45, 0.3)
	_emote.position = Vector3(0.0, 0.42, 0.0)
	_emote.no_depth_test = true
	_emote.text = "!"
	add_child(_emote)
	health = max_health
	add_to_group(&"salon_raiders")


func is_active() -> bool:
	return not _ko and not _retreat


func on_projectile_hit(projectile: Node3D) -> void:
	if _ko:
		return
	health -= int(projectile.get_meta("damage", 1))
	Sfx.play(&"impact_small", -6.0, 1.3)
	if health <= 0:
		_knock_out()
	else:
		body.rear = 1.0
		_emote.text = "!!"


func _physics_process(delta: float) -> void:
	if _ko or GameState.hazards_suspended():
		if body:
			body.motion_speed = 0.0
		return
	var goal: Vector3
	var final := false
	if _retreat:
		final = _leg < 0
		goal = home if final else path[_leg]
	elif _leg < path.size():
		goal = path[_leg]
	else:
		final = true
		goal = target.global_position if target else home
	var to := goal - global_position
	to.y = 0.0
	body.rear = move_toward(body.rear, 0.0, delta * 2.0)
	if not final and to.length() < 0.3:
		_leg += -1 if _retreat else 1
		return
	if final and to.length() < (0.3 if _retreat else 0.45):
		if _retreat:
			queue_free()
		else:
			_retreat = true
			_leg = path.size() - 1
			_emote.text = ""
			reached.emit(self)
		return
	var step := to.normalized() * minf(speed * (1.6 if _retreat else 1.0) * delta, to.length())
	global_position += step
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-12.0 * delta))
	body.motion_speed = speed
	body.excitement = 1.0


func _knock_out() -> void:
	_ko = true
	_emote.text = ""
	hit_body.collision_layer = 0
	Sfx.play(&"thud", -10.0, 1.6)
	var flip := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flip.tween_property(body, "rotation:z", PI, 0.3)
	flip.tween_interval(1.6)
	flip.tween_property(body, "scale", body.scale * 0.05, 0.4)
	flip.tween_callback(queue_free)
	knocked_out.emit(self)
