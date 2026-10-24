class_name CineCamera
extends Node
## Caméra de mise en scène réutilisable (lot 7) : cadrages fixes, travellings et suivi
## d'un nœud. Pendant la séquence, les dangers sont suspendus (aucune créature ne peut
## toucher Nin0) et l'interface de jeu peut être masquée ; tout est rendu à la fin.
## Usage : `begin()`, puis `shot()` / `move()` / `follow()`, puis `end()`.

signal changed(active: bool)

var reason: StringName = &"cinematic"
var camera: Camera3D
var _previous: Camera3D
var _tween: Tween
var _follow: Node3D
var _follow_offset := Vector3.ZERO


func is_active() -> bool:
	return camera != null


func begin(fov := 58.0) -> void:
	if camera:
		return
	_previous = get_viewport().get_camera_3d()
	camera = Camera3D.new()
	camera.fov = fov
	camera.near = 0.02
	add_child(camera)
	camera.make_current()
	GameState.suspend_hazards(reason)
	changed.emit(true)


func end() -> void:
	if camera == null:
		return
	_kill()
	_follow = null
	if is_instance_valid(_previous):
		_previous.make_current()
	camera.queue_free()
	camera = null
	GameState.resume_hazards(reason)
	changed.emit(false)


## Cadrage fixe.
func shot(from: Vector3, look: Vector3) -> void:
	if camera == null:
		return
	_kill()
	_follow = null
	camera.global_position = from
	_look(look)


## Travelling de `from` à `to` en regardant `look` (ou un nœud qui bouge).
func move(from: Vector3, to: Vector3, look: Variant, duration: float) -> void:
	if camera == null:
		return
	_kill()
	_follow = null
	camera.global_position = from
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(func(k: float) -> void:
		if camera:
			camera.global_position = from.lerp(to, k)
			_look(look), 0.0, 1.0, duration)
	await _tween.finished


## Suit un nœud depuis un décalage fixe (en coordonnées globales).
func follow(node: Node3D, offset: Vector3) -> void:
	_kill()
	_follow = node
	_follow_offset = offset


func _process(delta: float) -> void:
	if camera and is_instance_valid(_follow):
		var target := _follow.global_position + _follow_offset
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-5.0 * delta))
		_look(_follow.global_position + Vector3.UP * 0.1)


func _look(target: Variant) -> void:
	var point: Vector3 = (target as Node3D).global_position if target is Node3D else target
	if camera.global_position.distance_to(point) > 0.01:
		camera.look_at(point)


func _kill() -> void:
	if _tween:
		_tween.kill()
		_tween = null
