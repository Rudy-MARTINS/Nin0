class_name AntColumn
extends Node3D
## Colonne de fourmis ouvrières suivant un chemin (Path3D enfant « Path ») : file
## légèrement irrégulière, vitesses et décalages variés, pauses, échanges d'antennes,
## transport de miettes et réactions ponctuelles à Nin0. Les fourmis arrivées au bout
## repartent discrètement du début (aucune accumulation d'objets).
## Optimisation : loin de Nin0, mise à jour espacée et animations coupées.

@export var count := 9
@export var speed_range := Vector2(0.28, 0.42)
## Distance au-delà de laquelle la colonne passe en mise à jour économe.
@export var active_distance := 22.0
@export var react_distance := 0.55

var workers: Array[AntWorker] = []
var _offsets: Array[float] = []
var _wander: Array[float] = []
var _curve: Curve3D
var _length := 0.0
var _slow_timer := 0.0
var _nino: Node3D


func _ready() -> void:
	var path := $Path as Path3D
	_curve = path.curve
	_length = _curve.get_baked_length()
	for i in count:
		var worker := AntWorker.new()
		worker.speed = randf_range(speed_range.x, speed_range.y)
		worker.set_carrying(randf() < 0.55)
		add_child(worker)
		workers.append(worker)
		_offsets.append(_length * float(i) / count + randf_range(-0.2, 0.2))
		_wander.append(randf() * TAU)
	_place_all(0.0)


func _physics_process(delta: float) -> void:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as Node3D
	var near := _nino != null and _nino.global_position.distance_to(global_position) < active_distance + _length
	if not near:
		_slow_timer -= delta
		if _slow_timer > 0.0:
			return
		delta = 0.25
		_slow_timer = 0.25
	for i in workers.size():
		var worker := workers[i]
		worker.body.set_process(near)
		if near and _nino and worker.react_cooldown <= 0.0 and worker.paused <= 0.0 \
				and worker.global_position.distance_to(_nino.global_position) < react_distance:
			worker.react_to(_nino.global_position + Vector3.UP * 0.3)
		# Pauses spontanées et échanges avec la fourmi qui précède.
		if near and worker.paused <= 0.0 and randf() < delta * 0.08:
			worker.paused = randf_range(0.4, 1.4)
			var ahead := workers[(i + 1) % workers.size()]
			if ahead.global_position.distance_to(worker.global_position) < 0.35:
				worker.body.excitement = 0.5
				ahead.paused = maxf(ahead.paused, worker.paused)
		_offsets[i] += worker.tick(delta)
		if _offsets[i] >= _length:
			_offsets[i] -= _length
			worker.set_carrying(randf() < 0.55)
		_wander[i] += delta * (0.8 + worker.speed)
		_place(i, delta)


func _place_all(delta: float) -> void:
	for i in workers.size():
		_place(i, delta)


func _place(i: int, delta: float) -> void:
	var worker := workers[i]
	var offset := fposmod(_offsets[i], _length)
	var p := _curve.sample_baked(offset, true)
	var ahead := _curve.sample_baked(minf(offset + 0.15, _length), true)
	var direction := ahead - p
	if direction.length() < 0.001:
		direction = p - _curve.sample_baked(maxf(offset - 0.15, 0.0), true)
	var side := direction.cross(Vector3.UP).normalized()
	# Trajet légèrement irrégulier : petites dérives latérales.
	p += side * sin(_wander[i]) * 0.06
	worker.position = p
	if delta <= 0.0:
		worker.rotation.y = atan2(-direction.x, -direction.z)
	elif worker.paused <= 0.0:
		worker.face_direction(direction, delta)


func get_worker_count() -> int:
	return workers.size()
