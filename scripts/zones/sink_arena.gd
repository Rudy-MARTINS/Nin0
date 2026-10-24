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

enum Phase { IDLE, INTRO, FIGHT, DRAINING, DONE }

## Baisse du niveau de matière à la vidange (unités).
const DRAIN_DROP := 0.38
const DRAIN_TIME := 6.0

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


func get_checkpoint() -> Transform3D:
	return ($ArenaCheckpoint as Node3D).global_transform


func is_nino_inside() -> bool:
	return _nino != null and _bounds.overlaps_body(_nino)


func _on_trigger_entered(body: Node3D) -> void:
	if phase != Phase.IDLE or GameState.queen_defeated or not body is NinoController:
		return
	_nino = body
	start()


## Lance la rencontre : courte présentation, puis le combat.
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
	if _attempts > 0:
		Sfx.play(&"queen_roar", -8.0, 1.1)
		await get_tree().create_timer(0.8).timeout
	else:
		await queen.play_intro()
	_attempts += 1
	if phase != Phase.INTRO:
		return
	_nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	await get_tree().create_timer(0.6).timeout
	_nino.controls_enabled = true
	phase = Phase.FIGHT
	ring_interact.enabled = true
	queen.start_fight()
	fight_started.emit()


## Échec ou sortie de l'arène : remise en place complète (la progression est conservée).
func reset_fight() -> void:
	if phase in [Phase.DONE, Phase.DRAINING, Phase.IDLE]:
		return
	phase = Phase.IDLE
	GameState.in_combat = false
	ring_interact.enabled = false
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


func pull_drain() -> void:
	phase = Phase.DRAINING
	ring_interact.enabled = false
	drain_started.emit()
	if _nino:
		_nino.controls_enabled = false
		_nino.get_visual().show_emotion(NinoVisual.Emotion.FOCUSED, 0.8)
	Sfx.play(&"click", -4.0, 0.7)
	var pull := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pull.tween_property(_ring, "position", _ring.position + Vector3(0.45, 0.1, 0.25), 0.35)
	pull.parallel().tween_method(_pull_chain, 0.0, 1.0, 0.35)
	await pull.finished
	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_plug, "position", _plug.position + Vector3(0.6, 0.75, -0.4), 0.4)
	Sfx.play(&"thud", -4.0, 1.6)
	await pop.finished
	if _nino:
		_nino.controls_enabled = true
		_nino.get_visual().show_emotion(NinoVisual.Emotion.SURPRISED, 1.5)
	Sfx.set_loop(&"drain", &"drain", -4.0)
	mire.disable()
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
	if _nino:
		_nino.get_visual().show_emotion(NinoVisual.Emotion.HAPPY, 2.0)
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
