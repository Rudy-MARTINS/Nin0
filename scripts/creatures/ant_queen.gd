class_name AntQueen
extends Node3D
## Reine de la colonie, gardienne du lavabo (premier boss majeur). Imposante et lente,
## elle se déplace dans toute la vasque (matière, débris, éponge) : elle se repositionne,
## vient chercher Nin0 s'il s'attarde, et garde ses distances pour cracher.
## Deux attaques, toujours annoncées :
## - crachat d'acide (à distance, préféré) : préparation, cible au sol visible, arc lisible,
##   dégâts et ralentissement temporaire ;
## - coup de mandibules (au contact) : longue préparation, portée courte, très gros dégâts,
##   récupération exploitable.
## Elle n'est pas vaincue par les armes : la vidange du lavabo la prive de son terrain.
## Elle reste dans la vasque (zone praticable bornée) et ne traverse pas Nin0.

signal acid_spat
signal acid_hit_nino
signal melee_hit_nino

enum State { DORMANT, INTRO, WATCH, MOVE, SPIT_WINDUP, SPIT_RECOVER, MELEE_WINDUP, MELEE_STRIKE, MELEE_RECOVER, SWEPT, GONE }

const SPECIES: SpeciesData = preload("res://assets/species/ant_queen.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

@export var body_length := 1.25
## Zone praticable du centre de la reine (coordonnées globales x/z) : l'intérieur de la
## vasque, moins la moitié de son corps. Renseignée par l'arène.
@export var walk_min := Vector2(-62.6, -33.5)
@export var walk_max := Vector2(-55.4, -30.1)
@export var walk_speed := 0.7
@export var approach_speed := 0.85
## Temps passé par Nin0 au même endroit avant qu'elle vienne le chercher.
@export var linger_time := 3.0
@export var spit_windup := 1.0
@export var spit_cooldown := Vector2(1.5, 2.2)
@export var spit_flight := 0.95
## Lot 5.1 : dégâts relevés (12 → 18 ; morsure 30 → 42), préparations inchangées ou allongées.
@export var spit_damage := 18.0
@export var spit_radius := 0.42
@export var spit_slow := 0.5
@export var spit_slow_time := 2.0
@export var puddle_time := 3.5
@export var melee_range := 1.5
@export var melee_trigger := 1.7
@export var melee_windup := 1.1
@export var melee_damage := 42.0
@export var melee_recover := 1.5

var state := State.DORMANT
var body: AntBody
var spits := 0
var acid_hits := 0
var melee_hits := 0
## Distance totale parcourue pendant le combat (contrôle de mobilité).
var travelled := 0.0
## Pas lourds (présence physique) : petit choc sourd régulier quand elle marche.
var _step_timer := 0.0

var _timer := 0.0
var _spit_timer := 1.2
var _move_target := Vector3.ZERO
var _move_time := 0.0
var _approaching := false
var _linger := 0.0
var _linger_anchor := Vector3.ZERO
var _nino: NinoController
var _integrity: NinoIntegrity
var _focus: FocusTarget
var _emote: Label3D
var _home: Transform3D
var _collider: AnimatableBody3D
var _puddles: Array[Node3D] = []
var _projectiles: Array[Node3D] = []
var _acid_material: StandardMaterial3D
var _marker_material: StandardMaterial3D
## Tweens de mise en scène (arrêtés si la rencontre est réinitialisée).
var _seq: Array[Tween] = []


func _ready() -> void:
	_home = transform
	body = AntBody.new()
	body.caste = AntBody.Caste.QUEEN
	body.body_length = body_length
	body.body_color = Color(0.5, 0.2, 0.15)
	add_child(body)
	_focus = FocusTarget.new()
	_focus.id = &"ant_queen"
	_focus.radius = 0.5
	_focus.profile = PROFILE
	_focus.species = SPECIES
	_focus.thought_icons = [&"ant_queen", &"exclamation"]
	_focus.position = Vector3(0.0, body_length * 0.3, -body_length * 0.2)
	add_child(_focus)
	# Corps touché par les billes (couche des créatures) ; ne porte pas Nin0.
	_collider = AnimatableBody3D.new()
	_collider.sync_to_physics = false
	_collider.collision_layer = 16
	_collider.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = body_length * 0.28
	capsule.height = body_length * 1.1
	shape.shape = capsule
	shape.rotation.x = PI * 0.5
	shape.position = Vector3(0.0, body_length * 0.25, 0.0)
	_collider.add_child(shape)
	add_child(_collider)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 96
	_emote.pixel_size = 0.005
	_emote.outline_size = 16
	_emote.modulate = Color(1.0, 0.55, 0.25)
	_emote.position = Vector3(0.0, body_length * 0.95, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	_acid_material = StandardMaterial3D.new()
	_acid_material.albedo_color = Color(0.62, 0.9, 0.25)
	_acid_material.emission_enabled = true
	_acid_material.emission = Color(0.45, 0.8, 0.15)
	_acid_material.emission_energy_multiplier = 0.8
	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = Color(0.6, 1.0, 0.3, 0.45)
	_marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func is_fighting() -> bool:
	return state in [State.WATCH, State.MOVE, State.SPIT_WINDUP, State.SPIT_RECOVER, State.MELEE_WINDUP, State.MELEE_STRIKE, State.MELEE_RECOVER]


func is_inside_walk_area(point: Vector3, margin := 0.05) -> bool:
	return point.x >= walk_min.x - margin and point.x <= walk_max.x + margin and point.z >= walk_min.y - margin and point.z <= walk_max.y + margin


## Révélation (cinématique) : elle émerge de la matière et monte sur son éponge.
func emerge(duration := 1.6) -> void:
	state = State.INTRO
	visible = true
	var target := _home.origin
	global_position = target + Vector3(0.0, -0.9, 1.0)
	rotation.y = _home.basis.get_euler().y
	body.excitement = 0.6
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_seq.append(tween)
	tween.tween_property(self, "global_position", target + Vector3(0.0, 0.0, 0.5), duration * 0.7)
	tween.tween_property(self, "global_position", target, duration * 0.3)
	body.motion_speed = 0.4
	await tween.finished
	body.motion_speed = 0.0
	body.excitement = 0.0


## Elle remarque Nin0 : elle se tourne vers lui, « ! ».
func notice(point: Vector3, duration := 0.7) -> void:
	_emote.text = "!"
	var to := point - global_position
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	_seq.append(tween)
	tween.tween_property(self, "rotation:y", rotation.y + wrapf(atan2(-to.x, -to.z) - rotation.y, -PI, PI), duration)
	body.head_tilt = 0.3
	await tween.finished
	body.head_tilt = 0.0


## Présentation : elle se redresse, agite les antennes, grogne.
func play_intro() -> void:
	state = State.INTRO
	_emote.text = "!"
	Sfx.play(&"queen_roar", -4.0)
	var tween := create_tween()
	_seq.append(tween)
	tween.tween_property(body, "rear", 1.0, 0.6)
	tween.tween_property(body, "excitement", 1.0, 0.3)
	tween.tween_interval(0.8)
	tween.tween_property(body, "rear", 0.0, 0.5)
	tween.parallel().tween_property(body, "excitement", 0.0, 0.5)
	await tween.finished
	_emote.text = ""


## Avant un premier combat : cachée dans la matière (révélée par la cinématique).
func hide_submerged() -> void:
	if state == State.GONE:
		return
	visible = false
	state = State.DORMANT


func start_fight() -> void:
	_set_state(State.WATCH)
	_timer = 0.8
	_spit_timer = 1.2
	travelled = 0.0
	_linger = 0.0


## Réinitialisation propre (échec, sortie de l'arène).
func reset() -> void:
	for tween in _seq:
		if tween and tween.is_valid():
			tween.kill()
	_seq.clear()
	_clear_effects()
	transform = _home
	scale = Vector3.ONE
	visible = true
	body.rear = 0.0
	body.excitement = 0.0
	body.head_tilt = 0.0
	body.motion_speed = 0.0
	_emote.text = ""
	_focus.enabled = true
	_collider.collision_layer = 16
	state = State.DORMANT


## Défaite : la matière part. Elle tente de rejoindre son éponge (zone stable), perd
## l'équilibre, puis le courant l'emporte vers la bonde.
func swept_away(drain_point: Vector3, duration: float) -> void:
	_clear_effects()
	state = State.SWEPT
	_focus.enabled = false
	_collider.collision_layer = 0
	_emote.text = "?!"
	Sfx.play(&"queen_defeat", -4.0)
	body.excitement = 1.0
	# 1. Elle se précipite vers l'éponge.
	var stable := _home.origin + Vector3(0.0, -0.1, 0.4)
	var to := stable - global_position
	var run := create_tween().set_trans(Tween.TRANS_SINE)
	run.tween_property(self, "rotation:y", rotation.y + wrapf(atan2(-to.x, -to.z) - rotation.y, -PI, PI), 0.3)
	run.tween_property(self, "global_position", stable, duration * 0.25)
	body.motion_speed = 1.2
	await run.finished
	# 2. Elle vacille, s'accroche, glisse.
	body.motion_speed = 2.0
	var wobble := create_tween()
	for i in 3:
		wobble.tween_property(self, "rotation:z", 0.25, 0.18)
		wobble.tween_property(self, "rotation:z", -0.25, 0.18)
	wobble.tween_property(self, "rotation:z", 0.0, 0.1)
	_emote.text = "!!"
	await wobble.finished
	# 3. Le courant l'emporte en tournoyant.
	body.motion_speed = 0.0
	var sweep := create_tween()
	sweep.tween_property(body, "rear", 1.0, 0.3)
	sweep.parallel().tween_property(self, "rotation:y", rotation.y + TAU * 1.5, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sweep.parallel().tween_property(self, "global_position", drain_point, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sweep.parallel().tween_property(self, "scale", Vector3.ONE * 0.08, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await sweep.finished
	visible = false
	state = State.GONE


## Chargement : déjà vaincue.
func set_gone() -> void:
	_clear_effects()
	visible = false
	_focus.enabled = false
	_collider.collision_layer = 0
	state = State.GONE


## Bille du canon : elle sursaute (aucun dégât, la reine ne se bat pas aux armes).
func on_projectile_hit(_projectile: Node3D) -> void:
	if not is_fighting():
		return
	Sfx.play(&"impact_small", -6.0, 0.8)
	body.head_tilt = -0.4
	var tween := create_tween()
	tween.tween_property(body, "head_tilt", 0.0, 0.4)


func _physics_process(delta: float) -> void:
	_collider.global_transform = global_transform
	if not is_fighting() or GameState.hazards_suspended():
		body.motion_speed = 0.0
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
		if _nino == null:
			return
	_timer -= delta
	_spit_timer -= delta
	var distance := _flat_distance(_nino.global_position)
	var nino_level := _nino.global_position.y < global_position.y + 0.8
	_update_linger(delta)
	match state:
		State.WATCH:
			_face(_nino.global_position, delta, 3.0)
			body.head_tilt = lerpf(body.head_tilt, 0.0, delta * 3.0)
			body.motion_speed = 0.0
			if distance < melee_trigger and nino_level:
				_set_state(State.MELEE_WINDUP)
			elif _timer <= 0.0:
				_choose_action(distance)
		State.MOVE:
			var target := _nino.global_position if _approaching else _move_target
			_walk_toward(target, approach_speed if _approaching else walk_speed, delta)
			_move_time -= delta
			_step_timer -= delta
			if _step_timer <= 0.0:
				_step_timer = 0.42
				Sfx.play(&"thud", -16.0, randf_range(0.55, 0.7))
			if distance < melee_trigger and nino_level:
				_set_state(State.MELEE_WINDUP)
			elif (_approaching and distance < melee_trigger * 0.9) or (not _approaching and _flat_distance(_move_target) < 0.2) or _move_time <= 0.0:
				body.motion_speed = 0.0
				_set_state(State.WATCH)
				_timer = 0.3
		State.SPIT_WINDUP:
			_face(_nino.global_position, delta, 4.0)
			body.rear = minf(body.rear + delta / spit_windup, 0.7)
			body.excitement = 0.5 + 0.5 * sin(_timer * 30.0)
			if _timer <= 0.0:
				_spit()
				_set_state(State.SPIT_RECOVER)
		State.SPIT_RECOVER:
			body.rear = maxf(body.rear - delta * 2.0, 0.0)
			body.excitement = maxf(body.excitement - delta * 2.0, 0.0)
			if _timer <= 0.0:
				_reposition_or_watch()
		State.MELEE_WINDUP:
			# Se cabre lentement, mandibles ouvertes : le moment de s'écarter.
			_face(_nino.global_position, delta, 1.6)
			body.rear = minf(body.rear + delta / melee_windup, 1.0)
			body.excitement = 1.0
			if _timer <= 0.0:
				_set_state(State.MELEE_STRIKE)
		State.MELEE_STRIKE:
			body.rear = maxf(body.rear - delta * 8.0, -0.4)
			if _timer <= 0.0:
				_strike()
				_set_state(State.MELEE_RECOVER)
		State.MELEE_RECOVER:
			body.excitement = 0.0
			body.rear = lerpf(body.rear, 0.0, delta * 1.5)
			body.head_tilt = sin(_timer * 3.0) * 0.3
			if _timer <= 0.0:
				_reposition_or_watch()
	_push_nino()


## Décision en garde : venir chercher Nin0, cracher, ou se replacer.
func _choose_action(distance: float) -> void:
	# À distance, elle préfère cracher dès que possible ; sinon elle vient chercher Nin0.
	if _spit_timer <= 0.0 and distance > 2.2:
		_set_state(State.SPIT_WINDUP)
	elif _linger >= linger_time or distance > 4.6:
		_start_move(_nino.global_position, true)
	elif _spit_timer <= 0.0:
		_set_state(State.SPIT_WINDUP)
	elif randf() < 0.75:
		_start_move(_pick_position(), false)
	else:
		_timer = 0.4


func _reposition_or_watch() -> void:
	if randf() < 0.75:
		_start_move(_pick_position(), false)
	else:
		_set_state(State.WATCH)


func _start_move(target: Vector3, approach: bool) -> void:
	_approaching = approach
	_move_target = _clamp_to_area(target)
	_move_time = 4.0 if approach else 3.0
	if approach:
		_linger = 0.0
	_set_state(State.MOVE)


## Point de repli : à distance de crachat de Nin0 (2,2 à 3,4 u), dans la vasque.
func _pick_position() -> Vector3:
	var best := global_position
	var best_score := -INF
	for i in 8:
		var candidate := Vector3(randf_range(walk_min.x, walk_max.x), global_position.y, randf_range(walk_min.y, walk_max.y))
		var d := Vector2(candidate.x - _nino.global_position.x, candidate.z - _nino.global_position.z).length()
		var score := -absf(d - 2.8) - 0.15 * candidate.distance_to(global_position)
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _clamp_to_area(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, walk_min.x, walk_max.x), point.y, clampf(point.z, walk_min.y, walk_max.y))


func _walk_toward(target: Vector3, speed: float, delta: float) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.05:
		return
	var heading := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-2.5 * delta))
	# Elle avance dans la direction de son corps (virages lents d'un gros insecte).
	var forward := -global_basis.z
	forward.y = 0.0
	var facing := forward.normalized().dot(to.normalized())
	var step := forward.normalized() * speed * clampf(facing, 0.15, 1.0) * delta
	var next := _clamp_to_area(global_position + step)
	next.y = _floor_height(next)
	travelled += Vector2(next.x - global_position.x, next.z - global_position.z).length()
	global_position = next
	body.motion_speed = speed * clampf(facing, 0.15, 1.0)


## Hauteur du support sous la reine (matière, débris, éponge), sans dépasser une marche.
func _floor_height(point: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.0, point + Vector3.DOWN * 1.5, 1, [_collider.get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return point.y
	var y: float = (hit.position as Vector3).y
	return lerpf(global_position.y, y, 0.25)


## Nin0 qui reste au même endroit finit par attirer la reine.
func _update_linger(delta: float) -> void:
	if _nino.global_position.distance_to(_linger_anchor) > 1.2:
		_linger_anchor = _nino.global_position
		_linger = 0.0
	else:
		_linger += delta


## La reine ne traverse pas Nin0 : elle le repousse doucement.
func _push_nino() -> void:
	var to := _nino.global_position - global_position
	var flat := Vector2(to.x, to.z)
	if flat.length() < body_length * 0.55 and absf(to.y) < 0.7:
		var away := Vector3(flat.x, 0.0, flat.y).normalized() if flat.length() > 0.01 else -global_basis.z
		# Masse imposante : elle bouscule franchement Nin0.
		_nino.velocity.x = away.x * 3.4
		_nino.velocity.z = away.z * 3.4
		if _nino.is_on_floor():
			_nino.velocity.y = 2.2


func _set_state(next: State) -> void:
	state = next
	match next:
		State.WATCH:
			_emote.text = ""
			_timer = randf_range(0.35, 0.8)
		State.MOVE:
			_emote.text = ""
		State.SPIT_WINDUP:
			_timer = spit_windup
			Sfx.play(&"windup", -6.0, 0.7)
		State.SPIT_RECOVER:
			_timer = 0.6
			_spit_timer = randf_range(spit_cooldown.x, spit_cooldown.y)
		State.MELEE_WINDUP:
			_timer = melee_windup
			_emote.text = "!"
			body.motion_speed = 0.0
			Sfx.play(&"windup", -4.0, 0.55)
		State.MELEE_STRIKE:
			_timer = 0.12
		State.MELEE_RECOVER:
			_timer = melee_recover
			_emote.text = ""


func _strike() -> void:
	Sfx.play(&"bite", -2.0, 0.6)
	if _nino == null:
		return
	var to := _nino.global_position - global_position
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() < melee_range and absf(to.y) < 0.9 and (-global_basis.z).dot(flat.normalized()) > 0.3:
		if _integrity and _integrity.hit(melee_damage, &"physical", global_position):
			melee_hits += 1
			melee_hit_nino.emit()


## Crachat : vise la position de Nin0 (légère anticipation), cible visible au sol.
func _spit() -> void:
	if _nino == null:
		return
	spits += 1
	acid_spat.emit()
	Sfx.play(&"acid_spit", -4.0)
	var lead := Vector3(_nino.velocity.x, 0.0, _nino.velocity.z) * 0.35
	var target := _nino.global_position + lead
	target.y = _ground_height(target)
	var start := body.get_head().global_position if body.get_head() else global_position + Vector3.UP * 0.4
	var blob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	blob.mesh = sphere
	blob.material_override = _acid_material
	get_parent().add_child(blob)
	blob.global_position = start
	_projectiles.append(blob)
	var marker := _make_marker(target)
	var trail := _make_trail()
	blob.add_child(trail)
	var height := 1.0 + start.distance_to(target) * 0.15
	var tween := blob.create_tween()
	tween.tween_method(func(t: float) -> void:
		var p := start.lerp(target, t)
		p.y += sin(t * PI) * height
		blob.global_position = p, 0.0, 1.0, spit_flight)
	await tween.finished
	if is_instance_valid(marker):
		marker.queue_free()
	if not is_instance_valid(blob):
		return
	_projectiles.erase(blob)
	blob.queue_free()
	if state in [State.SWEPT, State.GONE, State.DORMANT]:
		return
	Sfx.play(&"acid_sizzle", -6.0)
	_make_puddle(target)
	if _nino and _nino.global_position.distance_to(target) < spit_radius + 0.15:
		if _integrity and _integrity.hit(spit_damage, &"acid", target):
			acid_hits += 1
			_nino.apply_slow(spit_slow, spit_slow_time)
			acid_hit_nino.emit()


func _ground_height(point: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, point + Vector3.DOWN * 3.0, 1)
	var hit := space.intersect_ray(query)
	return (hit.position as Vector3).y if not hit.is_empty() else point.y


func _make_marker(point: Vector3) -> Node3D:
	var marker := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = spit_radius
	disc.bottom_radius = spit_radius
	disc.height = 0.01
	disc.radial_segments = 24
	marker.mesh = disc
	marker.material_override = _marker_material
	get_parent().add_child(marker)
	marker.global_position = point + Vector3.UP * 0.02
	marker.scale = Vector3(0.3, 1.0, 0.3)
	_projectiles.append(marker)
	marker.create_tween().tween_property(marker, "scale", Vector3.ONE, spit_flight * 0.8)
	marker.tree_exiting.connect(func() -> void: _projectiles.erase(marker))
	return marker


func _make_trail() -> CPUParticles3D:
	var trail := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var material := _acid_material.duplicate() as StandardMaterial3D
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = material
	trail.mesh = quad
	trail.amount = 16
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector3(0.0, -1.0, 0.0)
	trail.scale_amount_min = 0.5
	return trail


## Flaque d'acide : ralentit un instant si Nin0 marche dedans, puis s'évapore.
func _make_puddle(point: Vector3) -> void:
	var puddle := Node3D.new()
	get_parent().add_child(puddle)
	puddle.global_position = point + Vector3.UP * 0.015
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = spit_radius * 0.8
	disc.bottom_radius = spit_radius * 0.8
	disc.height = 0.01
	mesh.mesh = disc
	var material := _acid_material.duplicate() as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.75
	mesh.material_override = material
	puddle.add_child(mesh)
	_puddles.append(puddle)
	var elapsed := 0.0
	while elapsed < puddle_time and is_instance_valid(puddle):
		await get_tree().create_timer(0.25).timeout
		elapsed += 0.25
		if not is_instance_valid(puddle):
			return
		if _nino and _nino.global_position.distance_to(puddle.global_position) < spit_radius * 0.8 and not _nino.is_slowed() \
				and not GameState.hazards_suspended():
			_nino.apply_slow(0.7, 0.6)
		material.albedo_color.a = 0.75 * (1.0 - elapsed / puddle_time)
	if is_instance_valid(puddle):
		_puddles.erase(puddle)
		puddle.queue_free()


func _clear_effects() -> void:
	for node in _puddles + _projectiles:
		if is_instance_valid(node):
			node.queue_free()
	_puddles.clear()
	_projectiles.clear()


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _face(point: Vector3, delta: float, rate: float) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-rate * delta))
