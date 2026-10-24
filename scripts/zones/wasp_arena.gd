class_name WaspArena
extends Node3D
## Arène des guêpes (cuisine, lot 7) : plan de travail ouest, autour de l'évier et de la
## fenêtre. Accessible seulement avec le saut chargé (le plan de travail est à 9 u).
## Combat en deux phases, plus long que celui de la reine :
## - Phase 1 : deux petites guêpes attaquent au corps à corps (une seule à la fois) ;
##   la grosse guêpe reste perchée sur le linteau, hors d'atteinte, et lance des piques.
## - Transition : la grosse guêpe constate la défaite des petites, s'énerve, descend.
## - Phase 2 : patterns A (charge annoncée), B (repli à l'abri, petit soin, limité),
##   C (appel d'un renfort par la fenêtre, vulnérable pendant l'appel, limité).
## Les mises en scène (intro, changement de phase, victoire) sont jouées par GameWorld :
## l'arène émet un signal, puis attend `begin_phase1()`, `begin_phase2()` ou `finish()`.
## Sortie de l'arène (chute du plan de travail) : le combat se met en pause, les guêpes
## se replient ; il reprend au retour, dans la même phase. Échec en phase 2 : on reprend
## en phase 2 (jamais depuis le début).

signal engaged
signal minions_defeated
signal boss_defeated
signal fight_paused
signal fight_resumed
signal fight_reset
signal phase_changed(phase: int)

enum Phase { IDLE, INTRO, PHASE1, TRANSITION, PHASE2, VICTORY, DONE }

## Limites de l'arène (plan de travail ouest, évier compris).
const BOUNDS_MIN := Vector3(-75.2, 6.5, 19.8)
const BOUNDS_MAX := Vector3(-68.3, 24.0, 51.2)
## Déclencheur : près de la fenêtre, sur le plan de travail ou les rebords de l'évier.
const TRIGGER_MIN := Vector3(-75.0, 8.6, 24.0)
const TRIGGER_MAX := Vector3(-68.5, 12.0, 44.0)
## Volume de vol (les petites guêpes et la grosse en phase 2 ne sortent pas de l'arène,
## ni ne traversent l'étagère).
const AIR_MIN := Vector3(-74.4, 9.6, 21.0)
const AIR_MAX := Vector3(-69.0, 19.0, 43.5)
const MAX_MINIONS := 2

## Désactivé par certains tests (exploration de la cuisine sans combat).
@export var enabled := true
## Perchoir de la grosse guêpe (phase 1), repli à l'abri (derrière la boîte à biscuits,
## sur le dessus des placards), entrée par la fenêtre.
@export var perch := Vector3(-74.4, 21.2, 33.0)
@export var retreat := Vector3(-64.0, 22.1, 56.6)
@export var window := Vector3(-74.7, 15.4, 33.0)
@export var minion_hover := PackedVector3Array([Vector3(-72.0, 11.6, 36.0), Vector3(-71.2, 12.0, 30.0)])
@export var checkpoint := Vector3(-70.6, 9.05, 40.5)

var phase := Phase.IDLE
var paused := false
var great: GreatWasp
var minions: Array[WaspMinion] = []
var reinforcements := 0
var attempts := 0
var _nino: NinoController
var _out_time := 0.0


func _ready() -> void:
	great = GreatWasp.new()
	great.name = "GreatWasp"
	great.arena = self
	great.perch = perch
	great.retreat = retreat
	great.window = window
	add_child(great)
	great.position = to_local(perch)
	great.visible = false
	great.defeated.connect(_on_great_defeated)
	great.call_reinforcement.connect(_on_call_reinforcement)


func is_active() -> bool:
	return phase in [Phase.INTRO, Phase.PHASE1, Phase.TRANSITION, Phase.PHASE2]


func is_fighting() -> bool:
	return phase in [Phase.PHASE1, Phase.PHASE2] and not paused


func is_inside(point: Vector3) -> bool:
	return _in_box(point, BOUNDS_MIN, BOUNDS_MAX)


func get_checkpoint() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(180.0)), checkpoint)


func _in_box(p: Vector3, lo: Vector3, hi: Vector3) -> bool:
	return p.x >= lo.x and p.x <= hi.x and p.y >= lo.y and p.y <= hi.y and p.z >= lo.z and p.z <= hi.z


func _physics_process(delta: float) -> void:
	if not enabled or phase == Phase.DONE:
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		if _nino == null:
			return
	var p := _nino.global_position
	match phase:
		Phase.IDLE:
			if GameState.chapter2_completed and not GameState.wasp_defeated and _nino.is_on_floor() \
					and _nino.controls_enabled and _in_box(p, TRIGGER_MIN, TRIGGER_MAX):
				_engage()
		Phase.PHASE1, Phase.PHASE2:
			var inside := is_inside(p)
			if paused:
				if inside and _nino.is_on_floor() and _nino.controls_enabled:
					_resume()
			elif not inside:
				_out_time += delta
				if _out_time > 0.4:
					_pause()
			else:
				_out_time = 0.0


# --- Déroulement -------------------------------------------------------------------------

func _engage() -> void:
	phase = Phase.INTRO
	attempts += 1
	GameState.set_flag(&"wasp_started")
	_nino.set_checkpoint(get_checkpoint())
	great.visible = true
	great.reset_fight()
	if GameState.wasp_phase2:
		# Reprise : les petites guêpes sont déjà vaincues, la grosse est dans l'arène.
		great.global_position = _hover_point(0)
	else:
		great.global_position = window + Vector3(0.6, 2.0, 0.0)
	engaged.emit()


## Mise en scène terminée (ou sautée) : la phase 1 commence (ou la phase 2 en reprise).
func begin_phase1() -> void:
	if phase != Phase.INTRO:
		return
	if GameState.wasp_phase2:
		_start_phase2()
		return
	phase = Phase.PHASE1
	paused = false
	if alive_minions() < MAX_MINIONS:
		spawn_intro_minions()
	great.start_phase1()
	phase_changed.emit(1)


## Les petites guêpes de la mise en scène d'intro (elles entrent par la fenêtre).
func spawn_intro_minions() -> void:
	_clear_minions()
	for i in MAX_MINIONS:
		_spawn_minion(minion_hover[i % minion_hover.size()], 3)


func begin_phase2() -> void:
	if phase != Phase.TRANSITION:
		return
	GameState.set_flag(&"wasp_phase2")
	_start_phase2()


func _start_phase2() -> void:
	phase = Phase.PHASE2
	paused = false
	reinforcements = 0
	great.start_phase2()
	phase_changed.emit(2)


## Après la mise en scène de victoire : la grosse guêpe, sonnée, repart par la fenêtre.
func finish() -> void:
	if phase != Phase.VICTORY:
		return
	phase = Phase.DONE
	_clear_minions()
	await great.fly_away(window + Vector3(-1.5, 1.0, 0.0))
	great.visible = false


func _on_minion_ko(_minion: WaspMinion) -> void:
	if phase != Phase.PHASE1:
		return
	if alive_minions() == 0:
		phase = Phase.TRANSITION
		great.hold_at(perch)
		minions_defeated.emit()


func _on_great_defeated() -> void:
	if phase != Phase.PHASE2:
		return
	phase = Phase.VICTORY
	for minion in minions:
		minion.leave(window + Vector3(-1.5, 0.5, 0.0))
	GameState.wasp_defeated = true
	GameState.save()
	boss_defeated.emit()


func _on_call_reinforcement(_at: Vector3) -> void:
	if phase != Phase.PHASE2 or alive_minions() >= MAX_MINIONS:
		return
	reinforcements += 1
	_spawn_minion(_hover_point(reinforcements), 2)


## Pause : Nin0 a quitté le plan de travail. Les guêpes se replient sans se soigner.
func _pause() -> void:
	paused = true
	_out_time = 0.0
	for minion in minions:
		minion.leave(window + Vector3(0.9, 1.6, 0.0))
	great.hold_at(perch if phase == Phase.PHASE1 else retreat)
	fight_paused.emit()


func _resume() -> void:
	paused = false
	_nino.set_checkpoint(get_checkpoint())
	for minion in minions:
		minion.come_back()
	great.resume_fight()
	Sfx.play(&"soldier_alert", -6.0, 1.5)
	fight_resumed.emit()


## Nin0 hors service pendant le combat : tout se remet en place. En phase 2, on reprend
## en phase 2 (la grosse guêpe retrouve sa santé, les renforts sont rappelés).
func reset_fight() -> void:
	if not is_active():
		return
	phase = Phase.IDLE
	paused = false
	_clear_minions()
	great.reset_fight()
	great.global_position = perch
	great.visible = false
	fight_reset.emit()


## Chargement d'une partie où les guêpes sont déjà vaincues.
func apply_saved_state() -> void:
	if GameState.wasp_defeated:
		phase = Phase.DONE
		_clear_minions()
		great.visible = false
		great.set_physics_process(false)


# --- Services pour les guêpes ---------------------------------------------------------------

## Une seule petite guêpe attaque à la fois (attaques lisibles).
func can_attack(minion: WaspMinion) -> bool:
	if not is_fighting():
		return false
	for other in minions:
		if other != minion and other.is_alive() and other.is_attacking():
			return false
	return not (great.state in [GreatWasp.State.STING_WINDUP, GreatWasp.State.CHARGE])


func alive_minions() -> int:
	var count := 0
	for minion in minions:
		if minion.is_alive():
			count += 1
	return count


## Hauteur du sol sous un point (plan de travail, fond de l'évier…).
func floor_height(at: Vector3 = Vector3.INF) -> float:
	if at == Vector3.INF:
		return 9.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at + Vector3.DOWN * 12.0, 1)
	var hit := space.intersect_ray(query)
	return (hit.position as Vector3).y if not hit.is_empty() else 9.0


func clamp_air(point: Vector3) -> Vector3:
	return point.clamp(AIR_MIN, AIR_MAX)


func _hover_point(index: int) -> Vector3:
	return minion_hover[index % minion_hover.size()]


func _spawn_minion(target: Vector3, health: int) -> void:
	var minion := WaspMinion.new()
	minion.arena = self
	minion.max_health = health
	add_child(minion)
	minion.global_position = window + Vector3(-0.2, randf_range(-0.5, 0.5), randf_range(-1.5, 1.5))
	minion.enter(target)
	minion.knocked_out.connect(_on_minion_ko)
	minions.append(minion)


func _clear_minions() -> void:
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	minions.clear()
