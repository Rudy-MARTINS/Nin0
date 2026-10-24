class_name GreatWasp
extends Node3D
## Grosse guêpe (boss de la cuisine, lot 7). Deux phases :
## - Phase 1 : perchée sur le linteau de la fenêtre, hors d'atteinte, elle lance des
##   piques (préparation visible : abdomen relevé et lueur) pendant que deux petites
##   guêpes attaquent au corps à corps.
## - Phase 2 (après la défaite des petites) : elle descend dans l'arène et alterne
##   trois patterns, avec des limites strictes pour ne jamais rendre le combat
##   interminable :
##   A. corps à corps : approche, préparation annoncée du dard, charge ;
##   B. repli et récupération : zone haute à l'abri des billes, petit soin (2 fois max) ;
##   C. appel de renfort : immobile près de la fenêtre, vulnérable (dégâts accrus),
##      une petite guêpe arrive (3 appels max, 2 renforts simultanés au plus).

signal defeated
signal health_changed(value: int)
signal call_reinforcement(at: Vector3)

enum State { IDLE, PERCH, SPIKE_WINDUP, DESCEND, HOVER, STING_WINDUP, CHARGE, RECOVER, RETREAT, HEAL, RETURN, CALL, DOWN, HOLD }

const SPECIES: SpeciesData = preload("res://assets/species/wasp.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

@export var max_health := 16
@export var sting_damage := 18.0
@export var spike_damage := 10.0
@export var spike_interval := 2.4
@export var heal_amount := 3
@export var max_heals := 2
@export var max_calls := 3

var state := State.IDLE
var health := 16
var phase := 1
var heals_used := 0
var calls_used := 0
var spikes_thrown := 0
var body: WaspBody
var hit_body: StaticBody3D
var focus: FocusTarget
var arena: WaspArena
## Points fournis par l'arène.
var perch := Vector3.ZERO
var retreat := Vector3.ZERO
var window := Vector3.ZERO
var _nino: NinoController
var _integrity: NinoIntegrity
var _timer := 0.0
var _melee_left := 3
var _charge_dir := Vector3.ZERO
var _hit_done := false
var _angle := 0.0
var _emote: Label3D
var _hold := Vector3.ZERO


func _ready() -> void:
	body = WaspBody.new()
	body.body_length = 1.3
	add_child(body)
	hit_body = StaticBody3D.new()
	hit_body.collision_layer = 32
	hit_body.collision_mask = 0
	hit_body.set_meta("projectile_receiver", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 0.8, 1.35)
	shape.shape = box
	hit_body.add_child(shape)
	add_child(hit_body)
	focus = FocusTarget.new()
	focus.id = &"great_wasp"
	focus.radius = 0.65
	focus.profile = PROFILE
	focus.species = SPECIES
	focus.thought_icons = [&"wasp", &"exclamation"]
	add_child(focus)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 72
	_emote.pixel_size = 0.005
	_emote.outline_size = 14
	_emote.modulate = Color(1.0, 0.45, 0.3)
	_emote.position = Vector3(0.0, 1.05, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	health = max_health


## Vulnérable aux billes en ce moment ? (Phase 1 et repli : hors d'atteinte.)
func is_vulnerable() -> bool:
	return phase == 2 and state not in [State.RETREAT, State.HEAL, State.DESCEND, State.DOWN, State.IDLE, State.HOLD]


func start_phase1() -> void:
	phase = 1
	global_position = perch
	_set_state(State.PERCH)


func start_phase2() -> void:
	phase = 2
	_melee_left = 3
	_set_state(State.HOVER)


## Repli sans combattre (combat en pause, changement de phase).
func hold_at(point: Vector3) -> void:
	if state == State.DOWN:
		return
	_hold = point
	_set_state(State.HOLD)


func resume_fight() -> void:
	if state == State.DOWN:
		return
	_set_state(State.PERCH if phase == 1 else State.HOVER)


## Mise en scène : vol jusqu'à un point (awaitable).
func fly_to(point: Vector3, duration: float) -> void:
	_set_state(State.IDLE)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", point, duration)
	await tween.finished


## Mise en scène : regarde un point (Nin0, les petites guêpes à terre).
func look_toward(point: Vector3) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = atan2(-to.x, -to.z)


## Mise en scène de transition : colère visible (teinte, ailes, « !! »).
func show_anger(on: bool) -> void:
	body.anger = 1.0 if on else 0.0
	body.aim = 0.6 if on else 0.0
	_emote.text = "!!" if on else ""


## Après la défaite : sonnée, elle se redresse et repart par la fenêtre en titubant.
func fly_away(point: Vector3) -> void:
	_set_state(State.IDLE)
	_emote.text = ""
	body.wings_folded = false
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(body, "rotation:z", 0.0, 0.5)
	tween.tween_property(self, "global_position", global_position + Vector3.UP * 1.2, 0.8)
	tween.tween_property(self, "global_position", point, 2.0)
	tween.parallel().tween_property(body, "rotation:x", 0.25, 2.0)
	await tween.finished


func reset_fight() -> void:
	phase = 1
	health = max_health
	heals_used = 0
	calls_used = 0
	body.anger = 0.0
	body.aim = 0.0
	body.wings_folded = false
	body.rotation = Vector3.ZERO
	visible = true
	hit_body.collision_layer = 32
	_set_state(State.IDLE)


func on_projectile_hit(projectile: Node3D) -> void:
	if not is_vulnerable():
		# La bille ricoche : elle est trop loin ou à l'abri.
		Sfx.play(&"empty_click", -8.0, 2.2)
		return
	var damage := int(projectile.get_meta("damage", 1))
	if state == State.CALL:
		damage = int(ceil(damage * 1.5))
	health = maxi(health - damage, 0)
	health_changed.emit(health)
	Sfx.play(&"impact_small", -4.0, 0.8)
	body.anger = 1.0
	if health <= 0:
		_set_state(State.DOWN)
		defeated.emit()


func _physics_process(delta: float) -> void:
	if state in [State.IDLE, State.DOWN]:
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
	if _nino == null:
		return
	if GameState.hazards_suspended():
		if state in [State.STING_WINDUP, State.CHARGE, State.SPIKE_WINDUP]:
			_set_state(State.RECOVER if phase == 2 else State.PERCH)
		return
	_timer -= delta
	var target := _nino.global_position + Vector3.UP * 0.35
	match state:
		State.HOLD:
			_fly_to(_hold, 4.0, delta)
			_face(target, delta)
			body.aim = maxf(body.aim - delta * 2.0, 0.0)
		State.PERCH:
			_fly_to(perch, 3.0, delta)
			_face(target, delta)
			body.aim = maxf(body.aim - delta * 2.0, 0.0)
			if _timer <= 0.0:
				_set_state(State.SPIKE_WINDUP)
		State.SPIKE_WINDUP:
			_face(target, delta)
			body.aim = minf(body.aim + delta * 1.5, 1.0)
			if _timer <= 0.0:
				_throw_spike(target)
				_set_state(State.PERCH)
		State.HOVER:
			_angle += delta * 0.9
			var spot := _nino.global_position + Vector3(cos(_angle) * 2.6, 1.6, sin(_angle) * 2.6)
			_fly_to(_clamped(spot), 3.5, delta)
			_face(target, delta)
			if _timer <= 0.0:
				_next_pattern()
		State.STING_WINDUP:
			_face(target, delta)
			body.anger = minf(body.anger + delta * 1.5, 1.0)
			body.aim = body.anger
			if _timer <= 0.0:
				_set_state(State.CHARGE)
		State.CHARGE:
			global_position += _charge_dir * 8.0 * delta
			if not _hit_done and global_position.distance_to(target) < 0.75:
				_hit_done = true
				Sfx.play(&"bite", -4.0, 0.7)
				if _integrity:
					_integrity.hit(sting_damage, &"physical", global_position)
			if _timer <= 0.0 or global_position.y < _floor_y() + 0.3:
				_set_state(State.RECOVER)
		State.RECOVER:
			# Brève ouverture : plus bas, plus lente.
			_fly_to(global_position + Vector3.UP * 0.6, 1.2, delta)
			body.anger = maxf(body.anger - delta * 0.6, 0.0)
			body.aim = body.anger
			if _timer <= 0.0:
				_set_state(State.HOVER)
		State.RETREAT:
			_fly_to(retreat, 5.0, delta)
			if global_position.distance_to(retreat) < 0.2:
				_set_state(State.HEAL)
		State.HEAL:
			_face(target, delta)
			if _timer <= 0.0:
				health = mini(health + heal_amount, max_health)
				health_changed.emit(health)
				_set_state(State.RETURN)
		State.RETURN:
			_fly_to(_clamped(_nino.global_position + Vector3(0.0, 1.8, 2.4)), 5.0, delta)
			if _timer <= 0.0:
				_set_state(State.HOVER)
		State.CALL:
			_fly_to(window + Vector3(1.4, -1.0, 0.0), 3.0, delta)
			body.anger = 0.5 + 0.5 * sin(_timer * 12.0)
			if _timer <= 0.0:
				call_reinforcement.emit(window)
				calls_used += 1
				_set_state(State.HOVER)


## Choix du pattern suivant : surtout le corps à corps, puis repli ou renfort, limités.
func _next_pattern() -> void:
	if _melee_left > 0:
		_melee_left -= 1
		_set_state(State.STING_WINDUP)
		return
	_melee_left = 2 + randi() % 2
	var can_heal := heals_used < max_heals and health < int(max_health * 0.75)
	var can_call := calls_used < max_calls and (arena == null or arena.alive_minions() < 2)
	if can_heal and (not can_call or randf() < 0.5):
		heals_used += 1
		_set_state(State.RETREAT)
	elif can_call:
		_set_state(State.CALL)
	else:
		_set_state(State.STING_WINDUP)


func _throw_spike(target: Vector3) -> void:
	var spike := WaspSpike.new()
	spike.damage = spike_damage
	get_parent().add_child(spike)
	# Légère anticipation du déplacement de Nin0.
	var lead := Vector3(_nino.velocity.x, 0.0, _nino.velocity.z) * 0.35
	spike.launch(global_position + Vector3.UP * 0.1 - global_basis.z * 0.4, target + lead)
	spikes_thrown += 1
	Sfx.play(&"spike_throw", -8.0, 1.0)


func _set_state(next: State) -> void:
	state = next
	match next:
		State.PERCH:
			_timer = spike_interval
			_emote.text = ""
		State.SPIKE_WINDUP:
			_timer = 0.85
			_emote.text = "!"
			Sfx.play(&"windup", -6.0, 1.1)
		State.HOVER:
			_timer = randf_range(1.2, 2.0)
			_emote.text = ""
		State.STING_WINDUP:
			_timer = 0.9
			_emote.text = "!"
			Sfx.play(&"buzz_angry", -4.0, 0.9)
		State.CHARGE:
			_timer = 0.5
			_hit_done = false
			_charge_dir = ((_nino.global_position + Vector3.UP * 0.35) - global_position).normalized()
			_emote.text = ""
		State.RECOVER:
			_timer = 1.1
			_emote.text = ""
		State.RETREAT:
			_emote.text = ""
		State.HEAL:
			_timer = 3.0
			_emote.text = "+"
		State.RETURN:
			_timer = 1.4
			_emote.text = ""
		State.CALL:
			_timer = 2.5
			_emote.text = "♪"
			Sfx.play(&"soldier_alert", -4.0, 1.4)
		State.DOWN:
			_emote.text = ""
			hit_body.collision_layer = 0
			body.wings_folded = true
			body.anger = 0.0
			var fall := create_tween()
			fall.tween_property(self, "global_position:y", _floor_y() + 0.05, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			fall.parallel().tween_property(body, "rotation:z", PI * 0.5, 0.7)
			Sfx.play(&"queen_defeat", -6.0, 1.3)


func _fly_to(point: Vector3, speed: float, delta: float) -> void:
	var to := point - global_position
	if to.length() > 0.001:
		global_position += to.normalized() * minf(to.length(), speed * delta)


func _face(point: Vector3, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-6.0 * delta))


func _floor_y() -> float:
	return arena.floor_height(global_position) if arena else 0.0


func _clamped(point: Vector3) -> Vector3:
	return arena.clamp_air(point) if arena else point
