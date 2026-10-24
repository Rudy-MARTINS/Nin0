class_name TerrainZone
extends Area3D
## Zone de terrain : modifie la vitesse et le saut de Nin0 tant qu'il s'y trouve.
## - Gravier, cailloux : ralentit les roues seulement (les jambes passent).
## - Matière visqueuse (lavabo) : ralentit, alourdit (accélération réduite), enfonce,
##   réduit le saut, rend vulnérable. Seulement dans le liquide (sous `active_below_y`) :
##   les débris flottants restent des refuges sûrs.
## Toujours réversible : en sortant de la zone, Nin0 retrouve ses capacités.

@export var key: StringName = &"terrain"
@export_range(0.05, 1.0) var wheels_factor := 1.0
@export_range(0.05, 1.0) var speed_factor := 1.0
@export_range(0.1, 1.0) var jump_factor := 1.0
## Accélération réduite (inertie dans un liquide épais).
@export_range(0.05, 1.0) var accel_factor := 1.0
## Dégâts reçus multipliés (enlisement).
@export var damage_factor := 1.0
## Enfoncement visuel maximal (unités) et vitesse d'enfoncement.
@export var sink_depth := 0.0
@export var sink_speed := 0.12
## Hauteur (globale) au-dessus de laquelle Nin0 n'est plus « dedans » (sur un débris).
@export var active_below_y := INF
## Éclaboussures visibles quand Nin0 avance dedans (alpha 0 = aucune).
@export var splash_color := Color(0, 0, 0, 0)

var _inside: NinoController
var _active := false
var _sink := 0.0
var _splash: CPUParticles3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Vrai si Nin0 subit réellement le terrain (dans la zone et dans le liquide).
func is_nino_inside() -> bool:
	return _inside != null and _active


func get_sink() -> float:
	return _sink


func _physics_process(delta: float) -> void:
	if _inside == null:
		return
	var should := _inside.global_position.y < active_below_y
	if should != _active:
		_set_active(should)
	if not _active:
		if _sink > 0.0:
			_sink = maxf(_sink - delta * 0.8, 0.0)
			_inside.get_visual().set_sink(_sink)
		return
	if _splash:
		_splash.global_position = _inside.global_position + Vector3.UP * 0.05
		_splash.emitting = Vector3(_inside.velocity.x, 0.0, _inside.velocity.z).length() > 0.15 and _inside.is_on_floor()
	if sink_depth <= 0.0 or GameState.hazards_suspended():
		return
	# On s'enfonce à l'arrêt ou en marchant ; sauter ou sortir dégage aussitôt.
	if _inside.is_on_floor():
		_sink = minf(_sink + sink_speed * delta, sink_depth)
	else:
		_sink = maxf(_sink - delta * 0.6, 0.0)
	var depth_ratio := _sink / sink_depth
	_inside.set_speed_modifier(key, lerpf(1.0, speed_factor, 0.5 + depth_ratio * 0.5))
	_inside.get_visual().set_sink(_sink)


func _set_active(on: bool) -> void:
	_active = on
	var nino := _inside
	if on:
		if wheels_factor < 1.0:
			nino.set_wheels_modifier(key, wheels_factor)
		if speed_factor < 1.0:
			nino.set_speed_modifier(key, speed_factor)
		if jump_factor < 1.0:
			nino.set_jump_modifier(key, jump_factor)
		if accel_factor < 1.0:
			nino.set_accel_modifier(key, accel_factor)
		nino.damage_taken_multiplier = damage_factor
		if splash_color.a > 0.0 and _splash == null:
			_splash = _make_splash()
		if sink_depth > 0.0:
			Sfx.play(&"sludge", -8.0, randf_range(0.9, 1.1))
	else:
		nino.clear_modifier(key)
		nino.damage_taken_multiplier = 1.0
		if _splash:
			_splash.emitting = false


func _on_body_entered(body: Node3D) -> void:
	var nino := body as NinoController
	if nino == null:
		return
	_inside = nino
	_set_active(nino.global_position.y < active_below_y)


func _on_body_exited(body: Node3D) -> void:
	var nino := body as NinoController
	if nino == null or nino != _inside:
		return
	if _active:
		_set_active(false)
	nino.get_visual().set_sink(0.0)
	_inside = null
	_sink = 0.0


func _make_splash() -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var material := StandardMaterial3D.new()
	material.albedo_color = splash_color
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = material
	particles.mesh = quad
	particles.amount = 14
	particles.lifetime = 0.5
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.18
	particles.direction = Vector3.UP
	particles.spread = 50.0
	particles.initial_velocity_min = 0.4
	particles.initial_velocity_max = 0.9
	particles.gravity = Vector3(0.0, -4.0, 0.0)
	particles.emitting = false
	add_child(particles)
	return particles


## Désactive la zone (vidange) : rend à Nin0 ses capacités.
func disable() -> void:
	if _inside:
		_on_body_exited(_inside)
	set_deferred("monitoring", false)
