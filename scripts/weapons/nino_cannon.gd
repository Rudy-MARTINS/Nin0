class_name NinoCannon
extends Node
## Tir du canon à projectiles plastiques (amélioration majeure). Commande « fire »
## (clic gauche ou X) : vise le centre de la caméra ; en vision focalisée, la visée
## suit le grossissement (pas de seconde caméra). Chaque tir consomme du plastique.
## Les billes touchent ennemis, objets réactifs et mécanismes (on_projectile_hit).

signal fired
signal hit(collider: Object)
signal empty
signal ammo_changed(ammo: AmmoData)

const AMMO: AmmoData = preload("res://assets/upgrades/ammo_bead.tres")
const AMMO_STING: AmmoData = preload("res://assets/upgrades/ammo_sting.tres")
## Munitions connues, dans l'ordre du changement (touche A en AZERTY).
const AMMO_TYPES: Array[AmmoData] = [AMMO, AMMO_STING]
## Monde, créatures, cibles de projectiles.
const HIT_MASK := 1 | 16 | 32

@export var cooldown := 0.35

var nino: NinoController
var camera: ThirdPersonCamera
var ammo: AmmoData = AMMO
var shots := 0
var _cooldown := 0.0
var _bead_material: StandardMaterial3D
var _bead_mesh: Mesh
var _meshes := {}
var _materials := {}


func _ready() -> void:
	for type in AMMO_TYPES:
		var material := StandardMaterial3D.new()
		material.albedo_color = type.color
		material.roughness = 0.25
		if type.piercing:
			material.metallic = 0.6
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = type.radius
			cone.height = type.radius * 4.0
			cone.radial_segments = 8
			_meshes[type.id] = cone
		else:
			var sphere := SphereMesh.new()
			sphere.radius = type.radius
			sphere.height = type.radius * 2.0
			sphere.radial_segments = 10
			sphere.rings = 5
			_meshes[type.id] = sphere
		_materials[type.id] = material
	select_ammo(GameState.ammo_type, false)


## Munitions utilisables (améliorations possédées).
func available_ammo() -> Array[AmmoData]:
	var list: Array[AmmoData] = []
	for type in AMMO_TYPES:
		if type.requires_upgrade == &"" or GameState.has_upgrade(type.requires_upgrade):
			list.append(type)
	return list


func select_ammo(id: StringName, notify := true) -> bool:
	for type in available_ammo():
		if type.id == id:
			ammo = type
			_bead_mesh = _meshes[type.id]
			_bead_material = _materials[type.id]
			if GameState.ammo_type != id:
				GameState.ammo_type = id
				GameState._save_if_started()
			if notify:
				ammo_changed.emit(ammo)
			return true
	if notify:
		return false
	ammo = AMMO
	_bead_mesh = _meshes[AMMO.id]
	_bead_material = _materials[AMMO.id]
	return false


## Munition suivante (touche A en AZERTY) ; false s'il n'y en a qu'une.
func cycle_ammo() -> bool:
	var list := available_ammo()
	if list.size() < 2:
		return false
	var index := list.find(ammo)
	select_ammo(list[(index + 1) % list.size()].id)
	Sfx.play(&"click", -8.0, 1.4 if ammo.piercing else 1.0)
	return true


func can_fire() -> bool:
	return GameState.has_cannon() and nino != null and nino.controls_enabled and not GameState.modal_open \
			and nino.state == NinoController.State.FREE


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if Input.is_action_just_pressed("fire") and can_fire():
		fire()
	if Input.is_action_just_pressed("switch_ammo") and GameState.has_cannon() and not GameState.modal_open:
		cycle_ammo()


## Point visé : centre de l'écran, premier obstacle sur la ligne de visée.
## Aide à la visée : un mécanisme (groupe « cannon_targets ») proche du centre de la
## vue devient le point visé.
const ASSIST_DEGREES := 6.0


func aim_point() -> Vector3:
	var assisted := _assisted_target()
	if assisted != Vector3.INF:
		return assisted
	var cam := camera.get_camera()
	var origin := cam.global_position
	var forward := -cam.global_basis.z
	var space := nino.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * (ammo.max_range + 3.0), HIT_MASK, [nino.get_rid()])
	query.collide_with_areas = false
	var result := space.intersect_ray(query)
	return result.position if not result.is_empty() else origin + forward * ammo.max_range


func fire() -> bool:
	if _cooldown > 0.0:
		return false
	_cooldown = cooldown
	if not GameState.spend_plastic(ammo.cost):
		Sfx.play(&"empty_click", -6.0)
		empty.emit()
		return false
	shots += 1
	var visual := nino.get_visual()
	var model := visual.get_cannon()
	var muzzle := model.get_muzzle() if model else nino.global_position + Vector3.UP * 0.3
	var direction := launch_direction(muzzle, aim_point())
	if model:
		model.recoil()
	Sfx.play(&"shot", -6.0, randf_range(0.95, 1.08))
	fired.emit()
	_launch(muzzle, direction * ammo.speed, ammo)
	return true


## Direction de tir qui compense la chute de la bille (trajectoire tendue) pour qu'elle
## arrive au point visé ; tir droit si le point est hors de portée balistique.
func launch_direction(from: Vector3, target: Vector3) -> Vector3:
	var to := target - from
	var flat := Vector3(to.x, 0.0, to.z)
	var x := flat.length()
	var y := to.y
	var v := ammo.speed
	var g := ammo.gravity
	if x < 0.01 or g <= 0.0:
		return to.normalized()
	var disc := v * v * v * v - g * (g * x * x + 2.0 * y * v * v)
	if disc < 0.0:
		return to.normalized()
	var angle := atan((v * v - sqrt(disc)) / (g * x))
	return (flat.normalized() * cos(angle) + Vector3.UP * sin(angle)).normalized()


func _assisted_target() -> Vector3:
	var cam := camera.get_camera()
	var forward := -cam.global_basis.z
	var best := Vector3.INF
	var best_angle := deg_to_rad(ASSIST_DEGREES)
	for node in get_tree().get_nodes_in_group(&"cannon_targets"):
		var target := node as Node3D
		if not target.is_visible_in_tree():
			continue
		var point: Vector3 = target.get_meta("aim_point", target.global_position) if target.has_meta("aim_point") else target.global_position
		var to := point - cam.global_position
		if to.length() > ammo.max_range + 3.0:
			continue
		var angle := forward.angle_to(to)
		if angle < best_angle:
			best_angle = angle
			best = point
	return best


func _launch(from: Vector3, velocity: Vector3, type: AmmoData = AMMO) -> void:
	var bead := MeshInstance3D.new()
	bead.mesh = _meshes.get(type.id, _bead_mesh)
	bead.material_override = _materials.get(type.id, _bead_material)
	nino.get_parent().add_child(bead)
	bead.global_position = from
	var travelled := 0.0
	var space := nino.get_world_3d().direct_space_state
	while is_instance_valid(bead) and travelled < type.max_range:
		await get_tree().physics_frame
		if not is_instance_valid(bead):
			return
		var step := get_physics_process_delta_time()
		velocity.y -= type.gravity * step
		var next := bead.global_position + velocity * step
		if type.piercing and velocity.length() > 0.01:
			# La pointe suit la trajectoire.
			bead.look_at(bead.global_position + velocity, Vector3.UP if absf(velocity.normalized().y) < 0.99 else Vector3.RIGHT)
			bead.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		var query := PhysicsRayQueryParameters3D.create(bead.global_position, next, HIT_MASK, [nino.get_rid()])
		var result := space.intersect_ray(query)
		if not result.is_empty():
			_impact(result.position, result.normal, result.collider, type)
			bead.queue_free()
			return
		travelled += bead.global_position.distance_to(next)
		bead.global_position = next
	if is_instance_valid(bead):
		bead.queue_free()


func _impact(point: Vector3, normal: Vector3, collider: Object, type: AmmoData = AMMO) -> void:
	Sfx.play(&"impact_small", -8.0, randf_range(0.9, 1.2))
	var receiver: Object = collider
	if collider and not collider.has_method("on_projectile_hit") and collider.has_meta("projectile_receiver"):
		receiver = collider.get_meta("projectile_receiver")
	var marker := Node3D.new()
	nino.get_parent().add_child(marker)
	marker.global_position = point
	marker.set_meta("damage", type.damage)
	marker.set_meta("piercing", type.piercing)
	marker.set_meta("ammo", type.id)
	if receiver and receiver.has_method("on_projectile_hit"):
		receiver.on_projectile_hit(marker)
	hit.emit(receiver)
	# Petit éclat (quelques fragments bleus) puis disparition.
	var burst := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.02)
	var material := (_materials.get(type.id, _bead_material) as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = material
	burst.mesh = quad
	burst.amount = 10
	burst.lifetime = 0.35
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = normal
	burst.spread = 60.0
	burst.initial_velocity_min = 0.6
	burst.initial_velocity_max = 1.4
	burst.gravity = Vector3(0.0, -4.0, 0.0)
	marker.add_child(burst)
	burst.emitting = true
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(marker):
		marker.queue_free()
