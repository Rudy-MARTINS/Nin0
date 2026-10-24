class_name SinkArena
extends Node3D
## Arène du lavabo : matière visqueuse (ralentit, enfonce, rend vulnérable), débris
## flottants, île de la reine, bonde reliée par une chaînette à un anneau sur le rebord.
## Victoire sans arme : tirer l'anneau ouvre la bonde, la matière s'évacue, la reine perd
## son terrain et elle est emportée. Échec : tout est remis en place, sans rien perdre.

signal intro_started
signal fight_started
signal fight_reset
signal drain_started
signal queen_defeated
## La musique du combat doit démarrer (moment choisi par la mise en scène).
signal boss_music_started
## Caméra de mise en scène active (true) ou rendue au joueur (false).
signal cinematic_changed(active: bool)

enum Phase { IDLE, INTRO, FIGHT, DRAINING, DONE }

## Baisse du niveau de matière à la vidange (unités).
const DRAIN_DROP := 0.38
const DRAIN_TIME := 6.0
const BASIN_CENTER := Vector3(-59.0, 7.8, -31.8)

var phase := Phase.IDLE

@onready var queen: AntQueen = $Queen
@onready var ring_interact: Interactable = $RingInteract
@onready var mire: TerrainZone = $MireZone
@onready var _sludge: MeshInstance3D = $Sludge
@onready var _floor: StaticBody3D = $MireFloor
@onready var _island: AnimatableBody3D = $QueenIsland
@onready var _plug: Node3D = $Plug
@onready var _ring: Node3D = $Ring
@onready var _chain: Cable = $Chain
@onready var _bounds: Area3D = $ArenaBounds

var _nino: NinoController
var _attempts := 0
var _cam: Camera3D
var _previous_cam: Camera3D
var _cam_tween: Tween
var _initial := {}
var _platform_state := {}


func _ready() -> void:
	_initial = {
		"sludge": _sludge.position, "floor": _floor.position, "island": _island.position,
		"plug": _plug.position, "ring": _ring.position, "chain": _chain.points,
	}
	for platform in $Platforms.get_children():
		_platform_state[platform] = [platform.bob_amplitude, platform.drift]
	ring_interact.enabled = false
	ring_interact.interacted.connect(_on_ring_pulled)
	($ArenaTrigger as Area3D).body_entered.connect(_on_trigger_entered)
	_bounds.body_exited.connect(_on_bounds_exited)
	apply_saved_state()
	# Avant la première rencontre, la reine est cachée dans la matière.
	if not GameState.queen_defeated:
		queen.hide_submerged.call_deferred()


func get_checkpoint() -> Transform3D:
	return ($ArenaCheckpoint as Node3D).global_transform


func is_nino_inside() -> bool:
	return _nino != null and _bounds.overlaps_body(_nino)


func _on_trigger_entered(body: Node3D) -> void:
	if phase != Phase.IDLE or GameState.queen_defeated or not body is NinoController:
		return
	_nino = body
	start()


## Lance la rencontre : mini-cinématique (première fois) ou présentation raccourcie.
func start() -> void:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
	phase = Phase.INTRO
	GameState.boss_started = true
	GameState.in_combat = true
	_nino.set_checkpoint(get_checkpoint())
	intro_started.emit()
	# On attend que Nin0 ait posé le pied sur le rebord (jamais d'arrêt en plein saut).
	var waited := 0.0
	while not _nino.is_on_floor() and waited < 1.5:
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	_nino.controls_enabled = false
	_nino.velocity = Vector3.ZERO
	var first := _attempts == 0
	_attempts += 1
	if first:
		if not await _intro_cinematic():
			return
	else:
		# Nouvel essai : la reine est déjà là ; un grognement et la musique repart.
		GameState.suspend_hazards(&"arena_retry")
		Sfx.play(&"queen_roar", -8.0, 1.1)
		boss_music_started.emit()
		await get_tree().create_timer(0.8).timeout
		GameState.resume_hazards(&"arena_retry")
		if phase != Phase.INTRO:
			return
	_nino.controls_enabled = true
	phase = Phase.FIGHT
	ring_interact.enabled = true
	queen.start_fight()
	fight_started.emit()


## 1. vue de l'arène ; 2. la reine émerge de la matière ; 3. elle remarque Nin0 ;
## 4. elle se redresse (musique du combat) ; 5. Nin0 surpris ; 6. contrôle rendu.
## Renvoie false si la rencontre a été interrompue.
func _intro_cinematic() -> bool:
	queen.hide_submerged()
	_cine_begin()
	_cine_move(Vector3(-55.6, 11.6, -25.4), Vector3(-56.8, 10.5, -27.0), BASIN_CENTER, 2.6)
	await get_tree().create_timer(0.6).timeout
	if phase != Phase.INTRO:
		return false
	Sfx.play(&"bubbles", -4.0)
	Sfx.play(&"sludge", -4.0, 0.7)
	await queen.emerge(1.6)
	if phase != Phase.INTRO:
		return false
	var q := queen.global_position
	_cine_shot(q + Vector3(-1.5, 1.0, 2.1), q + Vector3(0.0, 0.45, 0.0))
	await queen.notice(_nino.global_position, 0.7)
	if phase != Phase.INTRO:
		return false
	boss_music_started.emit()
	await queen.play_intro()
	if phase != Phase.INTRO:
		return false
	_shot_on_nino()
	_nino.get_visual().look_target = queen.global_position + Vector3.UP * 0.5
	_nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.4)
	Sfx.play(&"surprised", -6.0)
	await get_tree().create_timer(1.1).timeout
	_nino.get_visual().look_target = null
	_cine_end()
	return phase == Phase.INTRO


# --- Caméra de mise en scène ------------------------------------------------------------

func _cine_begin() -> void:
	if _cam:
		return
	_previous_cam = get_viewport().get_camera_3d()
	_cam = Camera3D.new()
	_cam.fov = 58.0
	add_child(_cam)
	_cam.make_current()
	GameState.suspend_hazards(&"arena_cinematic")
	cinematic_changed.emit(true)


func _cine_end() -> void:
	if _cam == null:
		return
	if _cam_tween:
		_cam_tween.kill()
	if is_instance_valid(_previous_cam):
		_previous_cam.make_current()
	_cam.queue_free()
	_cam = null
	GameState.resume_hazards(&"arena_cinematic")
	cinematic_changed.emit(false)


func is_cinematic() -> bool:
	return _cam != null


func _cine_shot(from: Vector3, look: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_cam.global_position = from
	_cam.look_at(look)


## Travelling lent en gardant le regard sur un point.
func _cine_move(from: Vector3, to: Vector3, look: Vector3, duration: float) -> void:
	_cine_shot(from, look)
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_method(func(k: float) -> void:
		if _cam:
			_cam.global_position = from.lerp(to, k)
			_cam.look_at(look), 0.0, 1.0, duration)


func _shot_on_nino() -> void:
	var forward := -_nino.global_basis.z
	forward.y = 0.0
	var p := _nino.global_position
	_cine_shot(p + forward.normalized() * 1.1 + Vector3(0.35, 0.4, 0.0), p + Vector3.UP * 0.3)


## Échec ou sortie de l'arène : remise en place complète (la progression est conservée).
func reset_fight() -> void:
	if phase in [Phase.DONE, Phase.DRAINING, Phase.IDLE]:
		return
	phase = Phase.IDLE
	GameState.in_combat = false
	ring_interact.enabled = false
	_cine_end()
	if _nino:
		_nino.controls_enabled = true
	queen.reset()
	_restore_arena()
	fight_reset.emit()


func _on_bounds_exited(body: Node3D) -> void:
	if body is NinoController and phase in [Phase.INTRO, Phase.FIGHT]:
		# Chute hors du meuble : la reine reprend sa place, on retente depuis l'escabeau.
		reset_fight.call_deferred()


func _restore_arena() -> void:
	_sludge.position = _initial.sludge
	_floor.position = _initial.floor
	_island.position = _initial.island
	_plug.position = _initial.plug
	_ring.position = _initial.ring
	_chain.points = _initial.chain
	for platform in _platform_state:
		platform.restore(_platform_state[platform][0], _platform_state[platform][1])


## Tirer l'anneau : la chaînette arrache la bonde, la vidange commence.
func _on_ring_pulled(_by: Node3D) -> void:
	if phase != Phase.FIGHT:
		return
	pull_drain()


## 1. Nin0 tire la chaînette ; 2. la bonde saute ; 3. la matière s'évacue ; 4-6. la
## reine réagit, cherche son éponge, glisse, le courant l'emporte ; 7. le lavabo se vide ;
## 8. Nin0 constate sa victoire (le raisonnement vers le canon suit : game_world.gd).
func pull_drain() -> void:
	phase = Phase.DRAINING
	ring_interact.enabled = false
	drain_started.emit()
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
	_nino.controls_enabled = false
	GameState.suspend_hazards(&"drain")
	_nino.velocity = Vector3.ZERO
	_nino.get_visual().show_emotion(NinoVisual.Emotion.FOCUSED, 0.8)
	Sfx.play(&"click", -4.0, 0.7)
	var pull := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pull.tween_property(_ring, "position", _ring.position + Vector3(0.45, 0.1, 0.25), 0.35)
	pull.parallel().tween_method(_pull_chain, 0.0, 1.0, 0.35)
	await pull.finished
	_cine_begin()
	_cine_shot(Vector3(-57.2, 9.6, -28.4), _plug.global_position)
	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_plug, "position", _plug.position + Vector3(0.6, 0.75, -0.4), 0.4)
	Sfx.play(&"thud", -4.0, 1.6)
	await pop.finished
	_nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.5)
	Sfx.set_loop(&"drain", &"drain", -4.0)
	mire.disable()
	_cine_move(Vector3(-55.4, 11.4, -25.6), Vector3(-56.6, 10.4, -27.2), BASIN_CENTER, DRAIN_TIME)
	var drain := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drain.tween_property(_sludge, "position:y", _sludge.position.y - DRAIN_DROP, DRAIN_TIME)
	drain.tween_property(_floor, "position:y", _floor.position.y - DRAIN_DROP, DRAIN_TIME)
	drain.tween_property(_island, "position", _island.position + Vector3(0.0, -DRAIN_DROP, 0.9), DRAIN_TIME)
	for platform in $Platforms.get_children():
		platform.settle(DRAIN_DROP, DRAIN_TIME)
	var drain_point := ($DrainPoint as Node3D).global_position
	queen.swept_away(drain_point, DRAIN_TIME)
	await get_tree().create_timer(DRAIN_TIME + 0.4).timeout
	Sfx.stop_loop(&"drain")
	phase = Phase.DONE
	GameState.in_combat = false
	GameState.queen_defeated = true
	GameState.save()
	# Nin0 constate le lavabo vide.
	_shot_on_nino()
	_nino.get_visual().look_target = BASIN_CENTER
	_nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
	Sfx.play(&"happy", -4.0)
	await get_tree().create_timer(1.5).timeout
	_nino.get_visual().look_target = null
	GameState.resume_hazards(&"drain")
	_cine_end()
	_nino.controls_enabled = true
	queen_defeated.emit()


func _pull_chain(t: float) -> void:
	var points: PackedVector3Array = (_initial.chain as PackedVector3Array).duplicate()
	var last := points.size() - 1
	points[last] = points[last].lerp(_ring.global_position, t)
	points[last - 1] = points[last - 1].lerp(points[last - 1] + Vector3(0.2, 0.3, 0.1), t)
	_chain.points = points


## Chargement d'une partie où la reine est déjà vaincue (sans effet sinon).
func apply_saved_state() -> void:
	if not GameState.queen_defeated or phase == Phase.DONE:
		return
	phase = Phase.DONE
	queen.set_gone.call_deferred()
	ring_interact.enabled = false
	mire.disable()
	_sludge.position.y -= DRAIN_DROP
	_floor.position.y -= DRAIN_DROP
	_island.position += Vector3(0.0, -DRAIN_DROP, 0.9)
	_plug.position += Vector3(0.6, 0.75, -0.4)
	_ring.position += Vector3(0.45, 0.1, 0.25)
	for platform in $Platforms.get_children():
		platform.restore(0.0, Vector3.ZERO)
		platform.set_deferred("_drop", DRAIN_DROP)
