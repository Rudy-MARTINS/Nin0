class_name KitchenCreature
extends Node3D
## Base commune des créatures de la cuisine (lot 6) : araignées et cafards.
##
## Déplacement cinématique (sans physique) sur un territoire fait de rectangles
## horizontaux (`areas` : AABB, la hauteur de la surface est `position.y`) ; les
## obstacles (`blockers`) sont évités. Les créatures ne bloquent jamais Nin0 : seul un
## petit corps sur la couche « cibles des projectiles » (32) reçoit les billes du canon.
##
## Niveau de détail : au loin, le comportement est mis à jour moins souvent et
## l'animation du corps s'arrête (affrontements d'arrière-plan simplifiés).
## Toutes les créatures se figent pendant les séquences non interactives
## (GameState.hazards_suspended).

const PROFILE: ObservationProfile = preload("res://assets/observation/creature.tres")
## Distances (u) du niveau de détail : complet, réduit, minimal.
const LOD_NEAR := 14.0
const LOD_MID := 28.0

## Territoire : rectangles horizontaux (coordonnées globales).
@export var areas: Array[AABB] = []
## Obstacles à contourner (coordonnées globales).
@export var blockers: Array[AABB] = []
## Créature d'arrière-plan (zone inaccessible) : jamais hostile envers Nin0.
@export var background := false

var body: Node3D
var focus: FocusTarget
var hit_body: StaticBody3D
## Fréquence de mise à jour actuelle (1 = chaque image), pour les tests.
var lod_interval := 1
var _emote: Label3D
var _nino: NinoController
var _integrity: NinoIntegrity
var _lod_accum := 0.0
var _lod_frame := 0
var _route: Array[Vector3] = []


func _setup_common(species: SpeciesData, focus_radius: float, hit_size: Vector3, icons: Array[StringName]) -> void:
	focus = FocusTarget.new()
	focus.id = species.id
	focus.radius = focus_radius
	focus.profile = PROFILE
	focus.species = species
	focus.thought_icons = icons
	focus.position = Vector3(0.0, hit_size.y * 0.5, 0.0)
	add_child(focus)
	hit_body = StaticBody3D.new()
	hit_body.collision_layer = 32
	hit_body.collision_mask = 0
	hit_body.set_meta("projectile_receiver", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = hit_size
	shape.shape = box
	shape.position = Vector3(0.0, hit_size.y * 0.5, 0.0)
	hit_body.add_child(shape)
	add_child(hit_body)
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 64
	_emote.pixel_size = 0.004
	_emote.outline_size = 12
	_emote.modulate = Color(1.0, 0.45, 0.3)
	_emote.position = Vector3(0.0, hit_size.y + 0.2, 0.0)
	_emote.no_depth_test = true
	add_child(_emote)
	_lod_frame = randi() % 8


## Pas de temps de comportement (0 = rien à faire cette image) selon la distance à Nin0.
func _lod_step(delta: float) -> float:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group(&"nino") as NinoController
		_integrity = get_tree().get_first_node_in_group(&"nino_integrity") as NinoIntegrity
	var distance := global_position.distance_to(_nino.global_position) if _nino else 0.0
	lod_interval = 1 if distance < LOD_NEAR else (3 if distance < LOD_MID else 8)
	if body:
		body.set_process(distance < LOD_MID)
	_lod_accum += delta
	_lod_frame += 1
	if _lod_frame % lod_interval != 0:
		return 0.0
	var step := minf(_lod_accum, 0.2)
	_lod_accum = 0.0
	return step


func nino_distance() -> float:
	return global_position.distance_to(_nino.global_position) if _nino else INF


func flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func same_level(point: Vector3, tolerance := 0.5) -> bool:
	return absf(point.y - global_position.y) < tolerance


## Rectangles du territoire à la hauteur `y`.
func areas_at(y: float) -> Array[AABB]:
	var list: Array[AABB] = []
	for area in areas:
		if absf(area.position.y - y) < 0.3:
			list.append(area)
	return list


func in_territory(point: Vector3, margin := 0.0, tolerance := 0.6) -> bool:
	for area in areas:
		if absf(area.position.y - point.y) > tolerance:
			continue
		if point.x >= area.position.x - margin and point.x <= area.end.x + margin \
				and point.z >= area.position.z - margin and point.z <= area.end.z + margin:
			return true
	return false


func is_blocked(point: Vector3) -> bool:
	for blocker in blockers:
		if blocker.grow(0.08).has_point(point + Vector3.UP * 0.05):
			return true
	return false


## Point libre du territoire (même niveau), dans `radius` autour de `around`.
func random_point(around: Vector3, radius: float, tries := 8) -> Variant:
	var level := areas_at(around.y)
	if level.is_empty():
		return null
	for i in tries:
		var area: AABB = level[randi() % level.size()]
		var p := Vector3(randf_range(area.position.x, area.end.x), area.position.y, randf_range(area.position.z, area.end.z))
		if radius > 0.0:
			var offset := Vector2(p.x - around.x, p.z - around.z).limit_length(radius)
			p = clamp_to_level(Vector3(around.x + offset.x, around.y, around.z + offset.y))
		if not is_blocked(p) and path_clear(around, p):
			return p
	return null


## Ramène un point à l'intérieur du rectangle le plus proche de son niveau.
func clamp_to_level(point: Vector3) -> Vector3:
	var best := point
	var best_d := INF
	for area in areas_at(point.y):
		var c := Vector3(clampf(point.x, area.position.x, area.end.x), area.position.y, clampf(point.z, area.position.z, area.end.z))
		var d := Vector2(c.x - point.x, c.z - point.z).length()
		if d < best_d:
			best_d = d
			best = c
	return best


## Trajet horizontal sans obstacle et sans sortir du territoire.
func path_clear(from: Vector3, to: Vector3) -> bool:
	var steps := maxi(int(Vector2(to.x - from.x, to.z - from.z).length() / 0.25), 1)
	for i in steps + 1:
		var p := from.lerp(to, float(i) / steps)
		p.y = to.y
		if is_blocked(p) or not in_territory(p, 0.05, 0.3):
			return false
	return true


## Prépare un trajet : marche sur le niveau actuel, passage vertical (paroi, fil) au
## bord le plus proche, puis marche sur le niveau de la cible.
func plan_route(target: Vector3) -> void:
	_route.clear()
	var here := global_position
	if absf(target.y - here.y) < 0.3:
		_route.append(target)
		return
	var edge := here
	if not areas_at(here.y).is_empty():
		edge = clamp_to_level(Vector3(target.x, here.y, target.z))
	if edge.distance_to(here) > 0.05:
		_route.append(edge)
	_route.append(Vector3(edge.x, target.y, edge.z))
	if _route[-1].distance_to(target) > 0.05:
		_route.append(target)


func route_done() -> bool:
	return _route.is_empty()


## Avance le long du trajet ; renvoie la vitesse effective (animation).
func follow_route(speed: float, vertical_speed: float, step: float) -> float:
	if _route.is_empty():
		return 0.0
	var next: Vector3 = _route[0]
	var to := next - global_position
	var vertical := absf(to.y) > 0.05 and Vector2(to.x, to.z).length() < 0.6
	var rate := vertical_speed if vertical else speed
	var travel := rate * step
	if to.length() <= travel:
		global_position = next
		_route.pop_front()
	else:
		global_position += to.normalized() * travel
	if not vertical and Vector2(to.x, to.z).length() > 0.01:
		face(next, step, 12.0)
	_on_vertical(vertical, to.y)
	return rate


## Passage vertical (surchargé : fil de l'araignée).
func _on_vertical(_active: bool, _dy: float) -> void:
	pass


func face(point: Vector3, step: float, rate := 10.0) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-rate * step))


func set_emote(text: String) -> void:
	_emote.text = text
