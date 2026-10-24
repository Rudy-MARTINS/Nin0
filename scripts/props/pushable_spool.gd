class_name PushableSpool
extends RigidBody3D
## Bobine de filament vide (légère) que Nin0 peut pousser en roulant contre elle.
## Elle reste à plat (rotations bloquées) et glisse sur son support.
##
## Sécurité anti-blocage : une bobine tombée hors de son support, ou posée sur une
## bobine déjà en place, revient d'elle-même à sa position de départ.

signal slotted(spool: PushableSpool)
signal reset_done(spool: PushableSpool)

## Chute (en unités) au-delà de laquelle la bobine est considérée comme perdue.
@export var lost_drop := 1.5
## Délai avant la réinitialisation d'une bobine perdue.
@export var reset_delay := 1.2

var is_slotted := false

var _start: Transform3D
var _lost_time := 0.0
var _sliding_time := 0.0


func _ready() -> void:
	_start = global_transform
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	add_to_group(&"pushable")


func _physics_process(delta: float) -> void:
	if _sliding_time > 0.0:
		_sliding_time -= delta
		if _sliding_time <= 0.0:
			Sfx.stop_loop(&"spool")
	if is_slotted:
		return
	var lost := global_position.y < _start.origin.y - lost_drop or global_position.y > _start.origin.y + 0.5
	_lost_time = _lost_time + delta if lost else 0.0
	if _lost_time > reset_delay:
		reset()


## Poussée appliquée par Nin0 : la bobine avance dans sa direction de déplacement,
## un peu moins vite que lui (elle frotte sur son support).
func push(direction: Vector3, speed: float) -> void:
	if is_slotted:
		return
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var push_velocity := direction.normalized() * speed
	linear_velocity = Vector3(push_velocity.x, linear_velocity.y, push_velocity.z)
	if speed > 0.2:
		Sfx.set_loop(&"spool", &"spool_slide", -14.0)
		_sliding_time = 0.15


## Remet la bobine à sa place d'origine.
func reset() -> void:
	if is_slotted:
		return
	_lost_time = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = _start
	scale = Vector3.ONE
	Sfx.play(&"pickup", -12.0, 0.8)
	reset_done.emit(self)


## Encastre la bobine dans un emplacement : elle devient un élément fixe du chemin.
func snap_into(target: Transform3D) -> void:
	if is_slotted:
		return
	is_slotted = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_transform", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		Sfx.play(&"spool_drop", -2.0)
		slotted.emit(self))


## État « déjà en place » (chargement d'une sauvegarde).
func set_slotted_immediately(target: Transform3D) -> void:
	is_slotted = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	global_transform = target
