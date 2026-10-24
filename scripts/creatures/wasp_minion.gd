class_name WaspMinion
extends Node3D
## Petite guêpe (boss de la cuisine, lot 7) : rapide, attaque au corps à corps.
## Elle tourne autour de Nin0, s'annonce (bourdonnement aigu, abdomen rouge, « ! »),
## pique en ligne droite vers la position visée, puis remonte. Une seule petite guêpe
## attaque à la fois (attaques lisibles). Trois billes la mettent KO : elle tombe,
## ailes repliées, puis disparaît (pas de réapparition pendant le combat).

signal knocked_out(minion: WaspMinion)

enum State { ENTER, HOVER, WINDUP, DIVE, RECOVER, LEAVE, KO }

const SPECIES: SpeciesData = preload("res://assets/species/wasp.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

@export var max_health := 3
@export var bite_damage := 12.0
@export var orbit_radius := 2.2
@export var orbit_height := 1.4
@export var dive_speed := 7.0

var state := State.ENTER
var health := 3
var body: WaspBody
var hit_body: StaticBody3D
var focus: FocusTarget
## Arène propriétaire (coordination des attaques, limites).
var arena: WaspArena
var _nino: NinoController
var _integrity: NinoIntegrity
var _timer := 0.0
var _angle := 0.0
var _dive_target := Vector3.ZERO
var _dive_dir := Vector3.ZERO
var _hit_done := false
var _enter_target := Vector3.ZERO
var _emote: Label3D


func _ready() -> void:
	body = WaspBody.new()
	body.body_length = 0.38
	add_child(body)
	hit_body = StaticBody3D.new()
	hit_body.collision_layer = 32
	hit_body.collision_mask = 0
	hit_body.set_meta("projectile_receiver", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.36, 0.3, 0.42)
	shape.shape = box
	hit_body.add_child(shape)
	add_child(hit_body)
	focus = FocusTarget.new()
	focus.id = &"wasp"
	focus.radius = 0.2
	focus.profile = PROFILE
	focus.species = SPECIES
	focus.thought_icons = [&"wasp", &"exclamation"]
	add_child(focus)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 64
	_emote.pixel_size = 0.004
	_emote.outline_size = 12
	_emote.modulate = Color(1.0, 0.45, 0.3)
	_emote.position = Vector3(0.0, 0.36, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	health = max_health
	_angle = randf() * TAU
	add_to_group(&"wasps")


## Entrée par la fenêtre jusqu'à `point`.
func enter(point: Vector3) -> void:
	_enter_target = point
	state = State.ENTER


func is_attacking() -> bool:
	return state in [State.WINDUP, State.DIVE]


func is_alive() -> bool:
	return state != State.KO


func _physics_process(delta: float) -> void:
	if state == State.KO:
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
	if _nino == null:
		return
	if GameState.hazards_suspended() and state not in [State.ENTER, State.LEAVE]:
		if state in [State.WINDUP, State.DIVE]:
			_set_state(State.RECOVER)
		return
	_timer -= delta
	var focus_point := _nino.global_position + Vector3.UP * 0.35
	match state:
		State.ENTER:
			_fly_to(_enter_target, 6.0, delta)
			if global_position.distance_to(_enter_target) < 0.2:
				_set_state(State.HOVER)
		State.HOVER:
			_angle += delta * 1.3
			var orbit := _nino.global_position + Vector3(cos(_angle) * orbit_radius, orbit_height, sin(_angle) * orbit_radius)
			_fly_to(_clamped(orbit), 4.5, delta)
			_face(focus_point, delta)
			if _timer <= 0.0 and (arena == null or arena.can_attack(self)):
				_set_state(State.WINDUP)
		State.WINDUP:
			_face(focus_point, delta)
			body.anger = minf(body.anger + delta * 2.0, 1.0)
			body.aim = body.anger
			if _timer <= 0.0:
				_set_state(State.DIVE)
		State.DIVE:
			global_position += _dive_dir * dive_speed * delta
			if not _hit_done and global_position.distance_to(focus_point) < 0.45:
				_hit_done = true
				Sfx.play(&"bite", -6.0, 1.3)
				if _integrity:
					_integrity.hit(bite_damage, &"physical", global_position)
			if _timer <= 0.0 or global_position.distance_to(_dive_target) < 0.2 or global_position.y < _floor_y():
				_set_state(State.RECOVER)
		State.RECOVER:
			_fly_to(global_position + Vector3.UP * 2.0 - _dive_dir, 3.0, delta)
			body.anger = maxf(body.anger - delta, 0.0)
			body.aim = body.anger
			if _timer <= 0.0:
				_set_state(State.HOVER)
		State.LEAVE:
			_fly_to(_enter_target, 5.0, delta)


func leave(point: Vector3) -> void:
	if state == State.KO:
		return
	_enter_target = point
	_set_state(State.LEAVE)


## Retour au combat après une pause (Nin0 revenu dans l'arène).
func come_back() -> void:
	if state == State.LEAVE:
		_set_state(State.HOVER)


func on_projectile_hit(projectile: Node3D) -> void:
	if state == State.KO or state == State.ENTER:
		return
	health -= int(projectile.get_meta("damage", 1))
	Sfx.play(&"impact_small", -6.0, 1.4)
	body.anger = 1.0
	if health <= 0:
		_knock_out()
	elif state in [State.WINDUP, State.DIVE]:
		_set_state(State.RECOVER)


func _knock_out() -> void:
	_set_state(State.KO)
	_emote.text = ""
	hit_body.collision_layer = 0
	focus.enabled = false
	body.wings_folded = true
	body.anger = 0.0
	Sfx.play(&"thud", -8.0, 1.8)
	var fall := create_tween()
	var ground := Vector3(global_position.x, _floor_y(), global_position.z)
	fall.tween_property(self, "global_position", ground, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(body, "rotation:z", PI, 0.5)
	fall.tween_interval(2.2)
	fall.tween_property(body, "scale", body.scale * 0.05, 0.4)
	fall.tween_callback(func() -> void: visible = false)
	knocked_out.emit(self)


func _set_state(next: State) -> void:
	state = next
	match next:
		State.HOVER:
			_timer = randf_range(1.6, 3.0)
			_emote.text = ""
		State.WINDUP:
			_timer = 0.65
			_emote.text = "!"
			if _nino and global_position.distance_to(_nino.global_position) < 16.0:
				Sfx.play(&"buzz", -6.0, 1.5)
		State.DIVE:
			_timer = 0.55
			_hit_done = false
			_dive_target = _nino.global_position + Vector3.UP * 0.35
			_dive_dir = (_dive_target - global_position).normalized()
			_emote.text = ""
		State.RECOVER:
			_timer = 0.8
			_emote.text = ""


func _fly_to(point: Vector3, speed: float, delta: float) -> void:
	var to := point - global_position
	var step := minf(to.length(), speed * delta)
	if to.length() > 0.001:
		global_position += to.normalized() * step


func _face(point: Vector3, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-10.0 * delta))


func _floor_y() -> float:
	return arena.floor_height(global_position) + 0.1 if arena else 0.1


func _clamped(point: Vector3) -> Vector3:
	return arena.clamp_air(point) if arena else point
