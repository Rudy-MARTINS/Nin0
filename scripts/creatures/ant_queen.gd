class_name AntQueen
extends Node3D
## Reine de la colonie, gardienne du lavabo (premier boss majeur). Lente, territoriale,
## elle ne quitte pas son île. Deux attaques, toujours annoncées :
## - crachat d'acide (à distance, préféré) : préparation, cible au sol visible, arc lisible,
##   dégâts modérés et ralentissement temporaire limité ;
## - coup de mandibules (au contact) : longue préparation, portée courte, gros dégâts,
##   récupération exploitable.
## Elle n'est pas vaincue par les armes : la vidange du lavabo la prive de son terrain.

signal acid_spat
signal acid_hit_nino
signal melee_hit_nino

enum State { DORMANT, INTRO, WATCH, SPIT_WINDUP, SPIT_RECOVER, MELEE_WINDUP, MELEE_STRIKE, MELEE_RECOVER, SWEPT, GONE }

const SPECIES: SpeciesData = preload("res://assets/species/ant_queen.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

@export var body_length := 1.25
@export var spit_windup := 1.0
@export var spit_cooldown := Vector2(1.6, 2.4)
@export var spit_flight := 0.95
@export var spit_damage := 12.0
@export var spit_radius := 0.42
@export var spit_slow := 0.55
@export var spit_slow_time := 1.6
@export var puddle_time := 3.5
@export var melee_range := 1.5
@export var melee_trigger := 1.7
@export var melee_windup := 1.0
@export var melee_damage := 30.0
@export var melee_recover := 1.5

var state := State.DORMANT
var body: AntBody
var spits := 0
var acid_hits := 0
var melee_hits := 0

var _timer := 0.0
var _nino: NinoController
var _integrity: NinoIntegrity
var _focus: FocusTarget
var _emote: Label3D
var _home: Transform3D
var _puddles: Array[Node3D] = []
var _projectiles: Array[Node3D] = []
var _acid_material: StandardMaterial3D
var _marker_material: StandardMaterial3D


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
	_marker_material.no_depth_test = false


func is_fighting() -> bool:
	return state in [State.WATCH, State.SPIT_WINDUP, State.SPIT_RECOVER, State.MELEE_WINDUP, State.MELEE_STRIKE, State.MELEE_RECOVER]


## Présentation : elle se redresse, agite les antennes, grogne.
func play_intro() -> void:
	state = State.INTRO
	_emote.text = "!"
	Sfx.play(&"queen_roar", -4.0)
	var tween := create_tween()
	tween.tween_property(body, "rear", 1.0, 0.6)
	tween.tween_property(body, "excitement", 1.0, 0.3)
	tween.tween_interval(1.0)
	tween.tween_property(body, "rear", 0.0, 0.5)
	tween.parallel().tween_property(body, "excitement", 0.0, 0.5)
	await tween.finished
	_emote.text = ""


func start_fight() -> void:
	_set_state(State.WATCH)
	_timer = 1.2


## Réinitialisation propre (échec, sortie de l'arène).
func reset() -> void:
	_clear_effects()
	transform = _home
	scale = Vector3.ONE
	visible = true
	body.rear = 0.0
	body.excitement = 0.0
	body.head_tilt = 0.0
	_emote.text = ""
	_focus.enabled = true
	state = State.DORMANT


## Défaite : la matière part, la reine perd pied et glisse, emportée vers la bonde.
func swept_away(drain_point: Vector3, duration: float) -> void:
	_clear_effects()
	state = State.SWEPT
	_focus.enabled = false
	_emote.text = "?!"
	Sfx.play(&"queen_defeat", -4.0)
	body.excitement = 1.0
	var tween := create_tween()
	tween.tween_property(body, "rear", 1.0, 0.4)
	tween.tween_interval(duration * 0.35)
	tween.tween_property(self, "rotation:y", rotation.y + TAU * 1.5, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "global_position", drain_point, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector3.ONE * 0.08, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	state = State.GONE


## Chargement : déjà vaincue.
func set_gone() -> void:
	_clear_effects()
	visible = false
	_focus.enabled = false
	state = State.GONE


func _physics_process(delta: float) -> void:
	if not is_fighting():
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
		if _nino == null:
			return
	_timer -= delta
	var distance := _flat_distance(_nino.global_position)
	match state:
		State.WATCH:
			_face(_nino.global_position, delta, 3.0)
			body.head_tilt = lerpf(body.head_tilt, 0.0, delta * 3.0)
			if distance < melee_trigger and _nino.global_position.y < global_position.y + 0.8:
				_set_state(State.MELEE_WINDUP)
			elif _timer <= 0.0:
				_set_state(State.SPIT_WINDUP)
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
				_set_state(State.WATCH)
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
				_set_state(State.WATCH)


func _set_state(next: State) -> void:
	state = next
	match next:
		State.WATCH:
			_emote.text = ""
			_timer = randf_range(spit_cooldown.x, spit_cooldown.y)
		State.SPIT_WINDUP:
			_timer = spit_windup
			Sfx.play(&"windup", -6.0, 0.7)
		State.SPIT_RECOVER:
			_timer = 0.6
		State.MELEE_WINDUP:
			_timer = melee_windup
			_emote.text = "!"
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
		if _nino and _nino.global_position.distance_to(puddle.global_position) < spit_radius * 0.8 and not _nino.is_slowed():
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
