class_name KitchenSpider
extends KitchenCreature
## Araignée de la cuisine (lot 6) : prédatrice territoriale. Elle guette depuis son
## repaire (coin sombre, hauteur, derrière un appareil), observe, traque, se ramasse
## puis bondit ; elle descend au bout de son fil pour une embuscade et remonte ensuite.
## Elle chasse les cafards (cocon) ; envers Nin0, elle défend son territoire : elle le
## surveille, l'avertit, puis attaque s'il s'attarde trop près — morsure annoncée,
## esquivable. Trois billes la font battre en retraite vers son repaire.
## Pendant qu'elle emballe une proie, elle ignore Nin0 (occasion de passer).

signal hunt_started(spider: KitchenSpider, prey: Node3D)
signal prey_caught(spider: KitchenSpider, prey: Node3D, at: Vector3)
signal hunt_failed(spider: KitchenSpider, prey: Node3D)
signal attacked_nino(spider: KitchenSpider)
signal noticed_nino(spider: KitchenSpider)

enum State { LURK, PATROL, WATCH, STALK, WINDUP, POUNCE, RECOVER, FEED, RETURN, RETREAT }

const SPECIES: SpeciesData = preload("res://assets/species/spider.tres")

## Repaire (coordonnées globales) : coin sombre ou point d'ancrage en hauteur.
@export var home := Vector3.ZERO
## Point d'ancrage du fil au-dessus du repaire (cocons suspendus).
@export var web_anchor := Vector3.INF
@export var walk_speed := 0.55
@export var stalk_speed := 0.45
@export var climb_speed := 1.4
@export var drop_speed := 2.4
## Portée de chasse ; une araignée perchée voit loin en contrebas.
@export var hunt_range := 6.0
@export var notice_range := 4.0
## En deçà, Nin0 menace le repaire : l'araignée finit par attaquer.
@export var threat_range := 2.2
@export var pounce_range := 1.1
@export var bite_damage := 16.0
@export var windup_time := 0.7
@export var max_health := 3
@export var success_chance := 1.0

var state := State.LURK
var prey: Node3D
var health := 3
var cocoons: Array[Node3D] = []
var _timer := 0.0
var _threat_time := 0.0
var _bites := 0
var _thread: MeshInstance3D
var _thread_top := Vector3.INF
var _carried: Node3D
var _hit_done := false
## Après une retraite, elle laisse Nin0 tranquille un moment.
var _calm := 0.0
## Après une chasse (réussie ou non), elle se repose avant la suivante.
var _rest := 0.0


func _ready() -> void:
	var spider := SpiderBody.new()
	spider.body_length = randf_range(0.24, 0.3)
	body = spider
	add_child(body)
	_setup_common(SPECIES, 0.18, Vector3(0.34, 0.2, 0.34), [&"spider", &"eye"])
	add_to_group(&"spiders")
	health = max_health
	if home == Vector3.ZERO:
		home = global_position
	_thread = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.006
	cylinder.bottom_radius = 0.006
	cylinder.height = 1.0
	cylinder.radial_segments = 4
	_thread.mesh = cylinder
	var silk := StandardMaterial3D.new()
	silk.albedo_color = Color(0.92, 0.92, 0.9, 0.7)
	silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	silk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_thread.material_override = silk
	_thread.top_level = true
	_thread.visible = false
	add_child(_thread)
	_timer = randf_range(2.0, 5.0)


## En chasse d'un cafard (les cafards proches le sentent).
func is_hunting() -> bool:
	return state in [State.STALK, State.WINDUP, State.POUNCE] and prey != null and prey != _nino


## Hostile envers Nin0 en ce moment (combat).
func is_engaged() -> bool:
	return prey == _nino and state in [State.STALK, State.WINDUP, State.POUNCE, State.RECOVER]


func on_projectile_hit(projectile: Node3D) -> void:
	if state == State.RETREAT:
		return
	health -= 1
	Sfx.play(&"impact_small", -6.0, 0.9)
	var push := global_position - projectile.global_position
	push.y = 0.0
	(body as SpiderBody).excitement = 1.0
	if health <= 0:
		_set_state(State.RETREAT)
	elif not background:
		# Provoquée : elle s'en prend à Nin0.
		prey = _nino
		_set_state(State.RECOVER)


func _physics_process(delta: float) -> void:
	if GameState.hazards_suspended():
		_hold_still()
		return
	var step := _lod_step(delta)
	if step <= 0.0:
		return
	_timer -= step
	_calm = maxf(_calm - step, 0.0)
	_rest = maxf(_rest - step, 0.0)
	var spider := body as SpiderBody
	var speed := 0.0
	match state:
		State.LURK:
			spider.head_tilt = sin(_timer * 0.8) * 0.15
			if not _scan_for_targets() and _timer <= 0.0:
				var p = random_point(global_position, 3.0) if not areas_at(global_position.y).is_empty() else _random_territory_point()
				if p != null:
					plan_route(p)
					_set_state(State.PATROL)
				else:
					_timer = randf_range(3.0, 6.0)
		State.PATROL:
			speed = follow_route(walk_speed, climb_speed, step)
			if not _scan_for_targets() and route_done():
				_go_home()
		State.WATCH:
			face(_nino.global_position, step)
			spider.rear = move_toward(spider.rear, 0.45, step * 2.0)
			# Nin0 s'attarde près du repaire, ou passe juste sous une araignée perchée.
			var territory := in_territory(_nino.global_position, 0.6)
			var near := territory and nino_distance() < threat_range
			var below := territory and not same_level(_nino.global_position, 1.0) and flat_distance(_nino.global_position) < threat_range * 1.6
			if near or below:
				_threat_time += step if near else step * 0.6
			else:
				_threat_time = maxf(_threat_time - step, 0.0)
			if _threat_time > 1.3:
				prey = _nino
				_bites = 0
				_set_state(State.STALK)
			elif not _nino_in_reach((notice_range + absf(_nino.global_position.y - global_position.y) * 0.8) * 1.3):
				spider.rear = 0.0
				_go_home()
			else:
				_scan_for_roach()
		State.STALK:
			if not _prey_valid():
				_lost_prey()
			elif prey == _nino and not in_territory(_nino.global_position, 0.8):
				_lost_prey()
			else:
				var target := prey.global_position
				if global_position.distance_to(target) < pounce_range and same_level(target, 0.45):
					_set_state(State.WINDUP)
				else:
					if _route.is_empty() or _route[-1].distance_to(target) > 0.4:
						plan_route(_clamp_target(target))
					# Approche rapide de loin, lente et feutrée à l'approche.
					var close := global_position.distance_to(target) < 3.0
					var pace := (stalk_speed if close else walk_speed * 1.5) * (1.6 if prey == _nino else 1.0)
					speed = follow_route(pace, drop_speed, step)
		State.WINDUP:
			if not _prey_valid():
				_lost_prey()
			else:
				face(prey.global_position, step, 14.0)
				spider.rear = minf(spider.rear + step / windup_time, 1.0)
				if _timer <= 0.0:
					_set_state(State.POUNCE)
		State.POUNCE:
			var dir := -global_basis.z
			global_position += Vector3(dir.x, 0.0, dir.z) * 3.6 * step
			global_position = clamp_to_level(global_position) if not areas_at(global_position.y).is_empty() else global_position
			speed = 3.6
			spider.rear = maxf(spider.rear - step * 5.0, 0.0)
			if not _hit_done and _prey_valid() and global_position.distance_to(prey.global_position) < 0.5:
				_hit_done = true
				_strike()
			if _timer <= 0.0 and state == State.POUNCE:
				if not _hit_done and prey != _nino:
					hunt_failed.emit(self, prey)
				_set_state(State.RECOVER)
		State.RECOVER:
			spider.excitement = maxf(spider.excitement - step, 0.0)
			if _timer <= 0.0:
				if prey == _nino and _bites < 2 and _prey_valid() and in_territory(_nino.global_position, 0.8):
					_set_state(State.STALK)
				else:
					_lost_prey()
		State.FEED:
			spider.excitement = 0.6
			spider.head_tilt = sin(_timer * 9.0) * 0.2
			if _timer <= 0.0:
				spider.excitement = 0.0
				spider.head_tilt = 0.0
				_go_home()
		State.RETURN:
			speed = follow_route(walk_speed * 1.2, climb_speed, step)
			if route_done():
				_arrive_home()
			elif _carried == null:
				_scan_for_targets()
		State.RETREAT:
			speed = follow_route(walk_speed * 2.5, climb_speed * 2.0, step)
			if route_done() and _timer <= 0.0:
				health = max_health
				_calm = 20.0
				spider.excitement = 0.0
				_arrive_home()
	spider.motion_speed = speed
	if _carried:
		_carried.global_position = global_position + Vector3(0.0, 0.05, 0.12).rotated(Vector3.UP, rotation.y)
	_update_thread()


## Cherche une proie (cafard) puis surveille Nin0. Renvoie true si l'état change.
func _scan_for_targets() -> bool:
	if _scan_for_roach():
		return true
	var reach := notice_range + absf(_nino.global_position.y - global_position.y) * 0.8 if _nino else 0.0
	if not background and _calm <= 0.0 and _nino_in_reach(reach) and in_territory(_nino.global_position, 0.6):
		_threat_time = 0.0
		_set_state(State.WATCH)
		noticed_nino.emit(self)
		return true
	return false


func _scan_for_roach() -> bool:
	if _rest > 0.0:
		return false
	var best: KitchenRoach
	var best_d := hunt_range
	for node in get_tree().get_nodes_in_group(&"roaches"):
		var roach := node as KitchenRoach
		if not roach.is_available() or not in_territory(roach.global_position, 0.3):
			continue
		var d := roach.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = roach
	if best == null:
		return false
	prey = best
	_set_state(State.STALK)
	hunt_started.emit(self, best)
	return true


func _nino_in_reach(reach: float) -> bool:
	return _nino != null and _nino.visible and nino_distance() < reach


func _prey_valid() -> bool:
	if prey == null or not is_instance_valid(prey):
		return false
	if prey is KitchenRoach:
		return (prey as KitchenRoach).is_available() and in_territory(prey.global_position, 0.4)
	return prey == _nino and _nino.visible


func _strike() -> void:
	if prey == _nino:
		_bites += 1
		Sfx.play(&"bite", -6.0, 0.8)
		if _integrity and _integrity.hit(bite_damage, &"physical", global_position):
			attacked_nino.emit(self)
		return
	var roach := prey as KitchenRoach
	if roach.is_defending() or randf() > success_chance:
		# La proie se défend : l'araignée recule.
		hunt_failed.emit(self, roach)
		roach.alarm(self, false)
		return
	roach.captured()
	Sfx.play(&"wrap", -14.0)
	prey_caught.emit(self, roach, global_position)
	_set_state(State.FEED)


func _lost_prey() -> void:
	(body as SpiderBody).rear = 0.0
	if prey == _nino:
		_calm = 4.0
	elif prey != null:
		_rest = randf_range(6.0, 11.0)
	prey = null
	_go_home()


func _go_home() -> void:
	plan_route(home)
	_set_state(State.RETURN)


func _arrive_home() -> void:
	if _carried:
		var anchor := web_anchor if web_anchor != Vector3.INF else home + Vector3.UP * 0.4
		var spot := anchor + Vector3(randf_range(-0.25, 0.25), -0.35 - 0.1 * cocoons.size(), randf_range(-0.25, 0.25))
		_carried.global_position = spot
		_carried.set_meta("anchor", anchor)
		cocoons.append(_carried)
		while cocoons.size() > 3:
			cocoons.pop_front().queue_free()
		_carried = null
	_set_state(State.LURK)


## Cocon emporté vers le repaire après l'emballage.
func carry(cocoon: Node3D) -> void:
	_carried = cocoon


func _random_territory_point() -> Variant:
	if areas.is_empty():
		return null
	var area: AABB = areas[randi() % areas.size()]
	return random_point(Vector3(area.get_center().x, area.position.y, area.get_center().z), 0.0)


func _clamp_target(target: Vector3) -> Vector3:
	var level := areas_at(target.y)
	if level.is_empty():
		return target
	var p := clamp_to_level(target)
	p.y = target.y
	return p


func _hold_still() -> void:
	(body as SpiderBody).motion_speed = 0.0
	if state in [State.WINDUP, State.POUNCE]:
		(body as SpiderBody).rear = 0.0
		_set_state(State.RECOVER)


## Passage vertical : l'araignée descend (ou remonte) au bout de son fil.
func _on_vertical(active: bool, dy: float) -> void:
	if not active:
		_thread_top = Vector3.INF
	elif _thread_top == Vector3.INF:
		_thread_top = global_position if dy < 0.0 else _route[0] if not _route.is_empty() else global_position


func _update_thread() -> void:
	var length := _thread_top.y - global_position.y if _thread_top != Vector3.INF else 0.0
	_thread.visible = length > 0.2
	if _thread.visible:
		_thread.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, length, 1.0)), Vector3(global_position.x, global_position.y + length * 0.5 + 0.15, global_position.z))


func _set_state(next: State) -> void:
	state = next
	var spider := body as SpiderBody
	match next:
		State.LURK:
			_timer = randf_range(4.0, 9.0)
			set_emote("")
			spider.rear = 0.0
		State.PATROL, State.RETURN:
			set_emote("")
		State.WATCH:
			set_emote("?")
			if nino_distance() < 10.0:
				Sfx.play(&"spider_hiss", -16.0, 1.2)
		State.STALK:
			set_emote("")
			_route.clear()
		State.WINDUP:
			_timer = windup_time
			_route.clear()
			set_emote("!" if prey == _nino else "")
			if prey is KitchenRoach:
				(prey as KitchenRoach).sense_pounce(self)
			if nino_distance() < 12.0:
				Sfx.play(&"spider_hiss", -10.0 if prey == _nino else -16.0)
		State.POUNCE:
			_timer = 0.28
			_hit_done = false
		State.RECOVER:
			_timer = 1.0
			set_emote("")
			spider.rear = 0.0
		State.FEED:
			_route.clear()
			_timer = 3.0
			_rest = randf_range(12.0, 20.0)
			set_emote("")
		State.RETREAT:
			prey = null
			set_emote("")
			plan_route(home)
			_timer = 8.0
			Sfx.play(&"spider_hiss", -10.0, 0.8)
