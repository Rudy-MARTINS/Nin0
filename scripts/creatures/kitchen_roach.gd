class_name KitchenRoach
extends KitchenCreature
## Cafard des bois (lot 6) : rapide, discret, opportuniste. Il explore, fouille les
## miettes, se cache sous les meubles, fuit les araignées et Nin0, se défend quand il
## est acculé (cabrage, petite morsure), puis reprend ses habitudes.
## Proie des araignées : un cafard attrapé disparaît (cocon) et un autre réapparaît
## plus tard dans une cachette, loin du regard de Nin0.

signal fled(roach: KitchenRoach, from: Node3D)
signal defended(roach: KitchenRoach)

enum State { WANDER, FORAGE, FLEE, HIDE, DEFEND, CAUGHT }

const SPECIES: SpeciesData = preload("res://assets/species/roach.tres")

## Cachettes (sous les meubles, derrière les appareils), coordonnées globales.
@export var hides: PackedVector3Array = []
@export var walk_speed := 0.9
@export var flee_speed := 3.2
## Distance d'alerte face à une araignée en chasse, et face à Nin0.
@export var spider_alert := 2.6
@export var nino_alert := 1.3
@export var nip_damage := 6.0
@export var respawn_time := 40.0
## Vigilance face au bond d'une araignée (0 = ne la voit jamais venir, 1 = normal).
@export var wariness := 1.0

var state := State.WANDER
var threat: Node3D
var _timer := 0.0
var _hide_target := Vector3.ZERO
var _windup := 0.0
var _nip_done := false


func _ready() -> void:
	var roach := RoachBody.new()
	roach.body_length = randf_range(0.22, 0.28)
	roach.body_color = Color(0.42, 0.24, 0.12).lerp(Color(0.34, 0.2, 0.1), randf())
	body = roach
	add_child(body)
	_setup_common(SPECIES, 0.14, Vector3(0.22, 0.12, 0.3), [&"roach", &"eye"])
	add_to_group(&"roaches")
	_timer = randf_range(0.5, 2.0)


func is_available() -> bool:
	return visible and state != State.CAUGHT


## Une araignée l'a attrapé : il disparaît, un autre reviendra plus tard.
func captured() -> void:
	_set_state(State.CAUGHT)
	visible = false
	hit_body.collision_layer = 0
	focus.enabled = false


## Réaction à une menace proche (araignée qui se prépare, Nin0, bille).
func alarm(from: Node3D, allow_defend := true) -> void:
	if state in [State.CAUGHT, State.FLEE, State.DEFEND]:
		return
	threat = from
	var hide = _pick_hide(from.global_position)
	if hide == null:
		# Acculé : il se dresse et se défend, ou tente un sprint vers le point le plus éloigné.
		if allow_defend and randf() < 0.5:
			_set_state(State.DEFEND)
			return
		hide = _farthest_point(from.global_position)
		if hide == null:
			if allow_defend:
				_set_state(State.DEFEND)
			return
	_hide_target = hide
	_set_state(State.FLEE)
	fled.emit(self, from)


## Une araignée se ramasse pour bondir sur lui : il la remarque (ou non) à temps.
func sense_pounce(spider: Node3D) -> void:
	if state in [State.CAUGHT, State.FLEE, State.DEFEND]:
		return
	var roll := randf() / maxf(wariness, 0.001)
	if roll < 0.38:
		alarm(spider)
	elif roll < 0.5:
		threat = spider
		_set_state(State.DEFEND)


func is_defending() -> bool:
	return state == State.DEFEND


func on_projectile_hit(projectile: Node3D) -> void:
	if state == State.CAUGHT:
		return
	Sfx.play(&"impact_small", -6.0, 1.3)
	state = State.WANDER
	alarm(projectile, false)


func _physics_process(delta: float) -> void:
	if state == State.CAUGHT:
		_timer -= delta
		if _timer <= 0.0:
			_respawn()
		return
	if GameState.hazards_suspended():
		(body as RoachBody).motion_speed = 0.0
		return
	var step := _lod_step(delta)
	if step <= 0.0:
		return
	_timer -= step
	var roach := body as RoachBody
	var speed := 0.0
	match state:
		State.WANDER:
			_watch_threats()
			if state == State.WANDER:
				speed = follow_route(walk_speed, walk_speed, step)
				if route_done() or _timer <= 0.0:
					if randf() < 0.45:
						_set_state(State.FORAGE)
					else:
						var p = random_point(global_position, 3.0)
						if p != null:
							plan_route(p)
						_timer = randf_range(2.0, 4.5)
		State.FORAGE:
			# Fouille sur place : antennes, petits pas.
			roach.head_tilt = sin(_timer * 5.0) * 0.25
			_watch_threats()
			if state == State.FORAGE and _timer <= 0.0:
				roach.head_tilt = 0.0
				_set_state(State.WANDER)
		State.FLEE:
			speed = follow_route(flee_speed, flee_speed, step)
			if route_done():
				_set_state(State.HIDE)
		State.HIDE:
			if not background and _nino and nino_distance() < 0.6 and same_level(_nino.global_position):
				threat = _nino
				_set_state(State.DEFEND)
			elif _timer <= 0.0:
				_set_state(State.WANDER)
		State.DEFEND:
			roach.rear = minf(roach.rear + step * 4.0, 1.0)
			if threat:
				face(threat.global_position, step, 14.0)
			# Petite morsure si Nin0 reste collé à lui.
			if not _nip_done and not background and threat == _nino and _timer < 0.5 and nino_distance() < 0.55:
				_nip_done = true
				Sfx.play(&"bite", -10.0, 1.4)
				if _integrity:
					_integrity.hit(nip_damage, &"physical", global_position)
			if _timer <= 0.0:
				roach.rear = 0.0
				var hide = _pick_hide(threat.global_position if threat else global_position)
				if hide != null:
					_hide_target = hide
					_set_state(State.FLEE)
				else:
					_set_state(State.WANDER)
	roach.motion_speed = speed
	roach.excitement = 1.0 if state in [State.FLEE, State.DEFEND] else (0.25 if state == State.HIDE else 0.0)


## Surveille les araignées en chasse et Nin0.
func _watch_threats() -> void:
	for node in get_tree().get_nodes_in_group(&"spiders"):
		var spider := node as KitchenSpider
		if spider.is_hunting() and spider.global_position.distance_to(global_position) < spider_alert:
			alarm(spider)
			return
	if not background and _nino and nino_distance() < nino_alert and same_level(_nino.global_position, 0.6):
		alarm(_nino)


## Cachette atteignable la plus proche qui l'éloigne de la menace (jamais vers elle).
func _pick_hide(from: Vector3) -> Variant:
	var best: Variant = null
	var best_d := INF
	var danger := Vector2(from.x - global_position.x, from.z - global_position.z)
	for hide in hides:
		if not same_level(hide, 0.3):
			continue
		var away := Vector2(hide.x - from.x, hide.z - from.z).length()
		var to_hide := Vector2(hide.x - global_position.x, hide.z - global_position.z)
		var mine := to_hide.length()
		if mine < 0.2 or away < maxf(danger.length() + 0.5, 1.5):
			continue
		if danger.length() > 0.01 and to_hide.normalized().dot(danger.normalized()) > 0.3:
			continue
		if mine < best_d and path_clear(global_position, hide):
			best_d = mine
			best = hide
	return best


## Point libre du territoire le plus éloigné de la menace (sprint désespéré).
func _farthest_point(from: Vector3) -> Variant:
	var best: Variant = null
	var best_d := Vector2(from.x - global_position.x, from.z - global_position.z).length() + 0.8
	for i in 8:
		var p = random_point(global_position, 4.0, 1)
		if p == null:
			continue
		var d := Vector2(p.x - from.x, p.z - from.z).length()
		if d > best_d:
			best_d = d
			best = p
	return best


func _respawn() -> void:
	# Réapparaît dans une cachette éloignée de Nin0.
	var spots := Array(hides)
	spots.shuffle()
	for spot in spots:
		if _nino == null or (spot as Vector3).distance_to(_nino.global_position) > 6.0:
			global_position = spot
			break
	visible = true
	hit_body.collision_layer = 32
	focus.enabled = true
	_route.clear()
	_set_state(State.HIDE)


func _set_state(next: State) -> void:
	state = next
	match next:
		State.WANDER:
			_timer = randf_range(1.5, 3.5)
			set_emote("")
		State.FORAGE:
			_route.clear()
			_timer = randf_range(1.2, 3.0)
		State.FLEE:
			plan_route(_hide_target)
			set_emote("")
			if nino_distance() < 12.0:
				Sfx.play(&"roach_skitter", -14.0, randf_range(0.9, 1.2))
		State.HIDE:
			_timer = randf_range(3.5, 7.0)
		State.DEFEND:
			_route.clear()
			_timer = 1.1
			_nip_done = false
			set_emote("!")
			if nino_distance() < 12.0:
				Sfx.play(&"spider_hiss", -18.0, 1.8)
			defended.emit(self)
		State.CAUGHT:
			_route.clear()
			_timer = respawn_time
			set_emote("")
