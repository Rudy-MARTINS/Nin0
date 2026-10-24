class_name KitchenFlea
extends Node3D
## Puce (lot 7) : minuscule, pacifique, reconnaissable à ses sauts. Elle se tient sur
## des perchoirs (sol, sac en papier, couvercle de la poubelle…), se toilette, fait de
## petits bonds sur place et, de temps en temps, un saut spectaculaire vers un perchoir
## très haut pour sa taille. Si Nin0 s'approche trop, elle bondit ailleurs.
## Jamais hostile. Analysable : inspire le saut chargé (« Observer → comprendre »).

signal jumped(from: Vector3, to: Vector3)

const SPECIES: SpeciesData = preload("res://assets/species/flea.tres")
const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")

## Perchoirs (coordonnées globales).
@export var perches: PackedVector3Array = []
@export var rest_min := 3.0
@export var rest_max := 7.0
## Distance à laquelle Nin0 la fait fuir.
@export var shy_distance := 0.9

var body: FleaBody
var focus: FocusTarget
var flying := false
var jumps := 0
## Si vrai, elle reste sur place (mise en scène).
var hold := false
var _timer := 3.0
var _perch := 0
var _nino: NinoController


func _ready() -> void:
	body = FleaBody.new()
	add_child(body)
	focus = FocusTarget.new()
	focus.id = &"flea"
	focus.radius = 0.14
	focus.profile = PROFILE
	focus.species = SPECIES
	focus.thought_icons = [&"flea", &"eye"]
	focus.position = Vector3(0.0, 0.08, 0.0)
	add_child(focus)
	add_to_group(&"fleas")
	if perches.is_empty():
		perches = PackedVector3Array([global_position])
	_perch = _nearest_perch(global_position)
	_timer = randf_range(rest_min, rest_max)


func _physics_process(delta: float) -> void:
	if flying or hold or GameState.hazards_suspended():
		return
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
	_timer -= delta
	body.crouch = lerpf(body.crouch, 0.0, 1.0 - exp(-6.0 * delta))
	var shy := _nino != null and _nino.global_position.distance_to(global_position) < shy_distance
	if shy or _timer <= 0.0:
		var next := _pick_perch(shy)
		if next >= 0:
			jump_to(perches[next])
			_perch = next
		_timer = randf_range(rest_min, rest_max)
	elif randf() < delta * 0.4:
		# Petit bond sur place (impatience).
		_hop()


## Saut en arc vers `target`, hauteur proportionnelle à la distance (spectaculaire).
func jump_to(target: Vector3, apex_extra := 1.2) -> void:
	if flying:
		return
	flying = true
	var from := global_position
	var flat := Vector2(target.x - from.x, target.z - from.z)
	if flat.length() > 0.01:
		rotation.y = atan2(-flat.x, -flat.y)
	# Préparation : les pattes se compriment.
	var prep := create_tween()
	prep.tween_property(body, "crouch", 1.0, 0.25)
	await prep.finished
	if _nino and global_position.distance_to(_nino.global_position) < 14.0:
		Sfx.play(&"charged_jump", -14.0, 1.8)
	body.crouch = 0.0
	body.stretch = 1.0
	var apex := maxf(from.y, target.y) + apex_extra + flat.length() * 0.15
	var duration := 0.35 + sqrt(maxf(apex - from.y, 0.1) / 12.5) + flat.length() * 0.03
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var p := from.lerp(target, t)
		global_position = Vector3(p.x, _arc_height(from.y, target.y, apex, t), p.z), 0.0, 1.0, duration)
	await tween.finished
	global_position = target
	body.stretch = 0.0
	body.crouch = 0.5
	flying = false
	jumps += 1
	jumped.emit(from, target)


func _arc_height(y0: float, y1: float, apex: float, t: float) -> float:
	# Deux demi-paraboles raccordées à l'apex (montée rapide, descente).
	var split := clampf(sqrt(apex - y0) / (sqrt(apex - y0) + sqrt(maxf(apex - y1, 0.01))), 0.2, 0.8)
	if t < split:
		var u := t / split
		return apex - (apex - y0) * (1.0 - u) * (1.0 - u)
	var v := (t - split) / (1.0 - split)
	return apex - (apex - y1) * v * v


func _hop() -> void:
	flying = true
	var base := global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", base + Vector3.UP * 0.25, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", base, 0.14).set_ease(Tween.EASE_IN)
	await tween.finished
	flying = false


func _pick_perch(away_from_nino: bool) -> int:
	if perches.size() < 2:
		return -1
	var best := -1
	var best_score := -INF
	for i in perches.size():
		if i == _perch:
			continue
		var score := randf()
		if away_from_nino and _nino:
			score += perches[i].distance_to(_nino.global_position) * 0.3
		if score > best_score:
			best_score = score
			best = i
	return best


func _nearest_perch(point: Vector3) -> int:
	var best := 0
	for i in perches.size():
		if perches[i].distance_to(point) < perches[best].distance_to(point):
			best = i
	return best
