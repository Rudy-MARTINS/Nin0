class_name Printer3D
extends Node3D
## Imprimante 3D du placard-hub (unique dans le jeu, GDD §4).
##
## - Impression : chauffe, déplacements de la tête et du plateau, pièces révélées
##   couche par couche (shader print_reveal), progression sur l'écran.
## - Installation : Nin0 monte sur le plateau ; le plateau le transporte sous la
##   tête, qui saisit chaque jambe imprimée et l'emboîte sur ses fixations.
## - Entretien (lot 3) : réparation ou renfort de châssis. Nin0 se place sur le
##   plateau et la tête travaille directement sur son corps (même mécanique).
## La progression (alimentation, objectifs) est gérée par le directeur de niveau.

signal print_progressed(progress: float)
signal print_finished
signal leg_attached(index: int)
signal installation_finished
signal service_progressed(progress: float)
signal service_finished

enum State { OFF, READY, HEATING, PRINTING, DONE, INSTALLING, EMPTY, SERVICING }

## Durée de l'impression des jambes (secondes).
@export var print_duration := 10.0
@export var heat_duration := 1.5
## Hauteur des pièces imprimées (unités locales).
@export var part_height := 0.47
## Position du plateau quand il présente les pièces (vers l'avant).
@export var bed_presented_z := 1.0
## Emplacement de Nin0 sur le plateau (coordonnée z locale au plateau).
@export var rider_spot_z := 0.75

const BED_TOP := 0.12
const HIP_HEIGHT := 0.43

var state := State.OFF

var _time := 0.0
var _progress := 0.0
var _print_materials: Array[ShaderMaterial] = []
var _screen_material: ShaderMaterial
var _nozzle_material: StandardMaterial3D
var _led_material: StandardMaterial3D
var _gantry_rest_y := 0.0
var _carried: Node3D
## Décalage entre la buse et la pièce saisie (hanche des jambes, support du canon…).
var _carried_offset := Vector3(0.0, HIP_HEIGHT, 0.0)
var _rider: Node3D

@onready var interactable: Interactable = $Interactable
@onready var install_zone: Area3D = $Bed/InstallZone
@onready var _bed: Node3D = $Bed
@onready var _gantry: Node3D = $Gantry
@onready var _head: Node3D = $Gantry/Head
@onready var _printed_legs: Node3D = $Bed/PrintedLegs
@onready var _spool: Node3D = $Spool
@onready var _filament: Cable = $Filament
@onready var _spark: OmniLight3D = $Gantry/Head/Spark


## Matériaux de la machine (glow-up) : silhouette et palette conservées, surfaces
## enrichies — coque en plastique grainé, montants en aluminium brossé, plateau métallique.
const MATERIAL_FAMILIES := {"Mat_body": &"plastic", "Mat_dark": &"plastic", "Mat_accent": &"plastic",
	"Mat_alu": &"metal", "Mat_sheet": &"plastic"}


func _dress_materials() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var standard := (node as MeshInstance3D).material_override as StandardMaterial3D
		if standard == null or standard.has_meta(&"nino_dressed"):
			continue
		var id := standard.resource_path.get_slice("::", 1)
		standard.set_meta(&"nino_dressed", true)
		if MATERIAL_FAMILIES.has(id):
			MaterialLibrary.apply_family(standard, MATERIAL_FAMILIES[id])


func _ready() -> void:
	_screen_material = ($Body/Screen as MeshInstance3D).material_override
	_nozzle_material = ($Gantry/Head/Nozzle as MeshInstance3D).material_override
	_led_material = ($Body/PowerLed as MeshInstance3D).material_override
	_gantry_rest_y = _gantry.position.y
	_dress_materials()
	# Le corps de collision du plateau suit réellement le plateau (sinon, synchronisé
	# à la physique, il restait en arrière : Nin0 flottait ou traversait le plateau).
	($Bed/BedBody as AnimatableBody3D).sync_to_physics = false
	for mesh in _printed_legs.find_children("*", "MeshInstance3D", true, false):
		var material := (mesh as MeshInstance3D).material_override as ShaderMaterial
		if material and not _print_materials.has(material):
			_print_materials.append(material)
	_set_cut(-1.0)
	_printed_legs.visible = false
	_spark.light_energy = 0.0
	_build_fx()
	_apply_power_visuals(false)


func _process(delta: float) -> void:
	_time += delta
	match state:
		State.HEATING:
			_nozzle_material.emission_energy_multiplier = minf(_nozzle_material.emission_energy_multiplier + delta * 2.0, 3.0)
		State.PRINTING:
			_animate_printing(delta)
	if _carried:
		# La pièce saisie pend sous la buse.
		var hip_offset := _carried.global_basis * _carried_offset
		_carried.global_position = _nozzle_tip() - hip_offset
	_update_filament()
	# Buse chaude : fines volutes et lueur orangée pendant l'extrusion.
	var hot := _nozzle_material.emission_energy_multiplier > 1.5
	if _nozzle_fx.emitting != hot:
		_nozzle_fx.emitting = hot


## Effets du glow-up : volutes de la buse et halo de l'écran sur la machine.
var _nozzle_fx: CPUParticles3D
var _screen_glow: OmniLight3D


func _build_fx() -> void:
	_nozzle_fx = CPUParticles3D.new()
	_nozzle_fx.name = "NozzleWisps"
	_nozzle_fx.emitting = false
	_nozzle_fx.amount = 14
	_nozzle_fx.lifetime = 1.4
	_nozzle_fx.local_coords = false
	_nozzle_fx.direction = Vector3.UP
	_nozzle_fx.spread = 25.0
	_nozzle_fx.gravity = Vector3(0, 0.05, 0)
	_nozzle_fx.initial_velocity_min = 0.03
	_nozzle_fx.initial_velocity_max = 0.08
	_nozzle_fx.scale_amount_min = 0.6
	_nozzle_fx.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(1, 0.0))
	_nozzle_fx.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.012
	mesh.height = 0.024
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	_nozzle_fx.mesh = mesh
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.7, 0.4, 0.5))
	ramp.set_color(1, Color(0.85, 0.85, 0.85, 0.0))
	_nozzle_fx.color_ramp = ramp
	$Gantry/Head/Nozzle.add_child(_nozzle_fx)
	_nozzle_fx.position = Vector3(0, -0.08, 0)
	_screen_glow = OmniLight3D.new()
	_screen_glow.name = "ScreenGlow"
	_screen_glow.light_color = Color(0.5, 0.9, 1.0)
	_screen_glow.omni_range = 0.6
	_screen_glow.light_energy = 0.0
	$Body/Screen.add_child(_screen_glow)
	_screen_glow.position = Vector3(0, 0, 0.08)


func set_powered(on: bool) -> void:
	if on and state == State.OFF:
		state = State.READY
		_apply_power_visuals(true)
		Sfx.play(&"printer_wake", -6.0)
	elif not on:
		state = State.OFF
		_apply_power_visuals(false)


func is_powered() -> bool:
	return state != State.OFF


func start_print() -> void:
	if state != State.READY:
		return
	state = State.HEATING
	Sfx.play(&"blip", -4.0)
	_screen_material.set_shader_parameter("mode", 1)
	_screen_material.set_shader_parameter("progress", 0.0)
	_printed_legs.visible = true
	_set_cut(-1.0)
	await get_tree().create_timer(heat_duration).timeout
	state = State.PRINTING
	_progress = 0.0
	Sfx.set_loop(&"printer", &"print_motor", -14.0)


## Vrai si Nin0 peut être installé (pièces prêtes) et se trouve sur la zone du plateau.
func is_rider_on_bed(body: Node3D) -> bool:
	return state == State.DONE and install_zone.overlaps_body(body)


## Installation assistée des jambes sur Nin0 (posé sur le plateau).
func install_legs(nino: NinoController) -> void:
	if state != State.DONE:
		return
	state = State.INSTALLING
	nino.begin_scripted()
	_rider = nino
	var visual := nino.get_visual()
	_screen_material.set_shader_parameter("mode", 1)
	# 1. Nin0 se place sur le plateau, face à la machine.
	var spot := _bed.to_global(Vector3(0.0, BED_TOP + 0.01, rider_spot_z))
	var settle := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	settle.tween_property(nino, "global_position", spot, 0.5)
	settle.tween_property(nino, "rotation:y", global_rotation.y, 0.5)
	await settle.finished
	Sfx.play(&"blip", -6.0)
	var legs := _printed_legs.get_children()
	for i in legs.size():
		var leg := legs[i] as Node3D
		# 2. Le plateau ramène la pièce sous la buse.
		await _move_bed(-leg.position.z, 0.6)
		await _move_head(leg.global_position + Vector3.UP * (HIP_HEIGHT + 0.03), 0.6)
		_carried = leg
		Sfx.play(&"click", -10.0, 1.4)
		await _move_head(_nozzle_tip() + Vector3.UP * 0.35, 0.4)
		# 3. Le plateau avance Nin0 ; la tête amène la jambe sur sa fixation, repliée sur le côté.
		await _move_bed(-rider_spot_z, 0.6)
		var side := -1.0 if i == 0 else 1.0
		var fold := create_tween()
		fold.tween_property(leg, "rotation:z", side * deg_to_rad(80.0), 0.4)
		var mount := visual.get_leg_mount_positions()[i] + Vector3(side * 0.02, 0.0, 0.0)
		await _move_head(mount + Vector3.UP * 0.25, 0.5)
		await _move_head(mount, 0.35)
		# 4. Emboîtement.
		_carried = null
		leg.visible = false
		visual.set_leg_visible(i, true)
		visual.react_to_jump()
		Sfx.play(&"click", 0.0, 0.9)
		Sfx.play(&"servo", -10.0, 1.4)
		_flash()
		leg_attached.emit(i)
		await _move_head(_nozzle_tip() + Vector3.UP * 0.5, 0.4)
	# 5. La tête se range, le plateau ramène Nin0 à l'avant.
	var park := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	park.tween_property(_gantry, "position:y", _gantry_rest_y, 0.8)
	park.tween_property(_head, "position:x", 1.4, 0.8)
	await park.finished
	await _move_bed(bed_presented_z, 0.8)
	_screen_material.set_shader_parameter("mode", 0)
	_rider = null
	state = State.EMPTY
	nino.end_scripted()
	installation_finished.emit()


## Entretien de Nin0 (réparation, renfort) : il saute sur le plateau, le plateau le
## glisse sous la tête, qui balaie son corps en déposant du filament (étincelles).
func service(nino: NinoController, duration: float) -> void:
	if state != State.EMPTY:
		return
	state = State.SERVICING
	nino.begin_scripted()
	var visual := nino.get_visual()
	await _step_to_waiting_spot(nino)
	_screen_material.set_shader_parameter("mode", 1)
	_screen_material.set_shader_parameter("progress", 0.0)
	# 1. Nin0 se hisse sur le plateau présenté à l'avant.
	await _move_bed(bed_presented_z, 0.4)
	var spot := _bed.to_global(Vector3(0.0, BED_TOP + 0.01, rider_spot_z))
	var from := nino.global_position
	var apex := (from + spot) * 0.5 + Vector3.UP * 0.6
	var hop := create_tween().set_trans(Tween.TRANS_SINE)
	hop.tween_method(func(t: float) -> void:
		nino.global_position = from.lerp(apex, t).lerp(apex.lerp(spot, t), t)
	, 0.0, 1.0, 0.5)
	hop.parallel().tween_property(nino, "rotation:y", global_rotation.y, 0.5)
	Sfx.play(&"jump", -8.0)
	await hop.finished
	visual.react_to_landing(4.0)
	_rider = nino
	Sfx.play(&"blip", -6.0)
	# 2. Le plateau l'amène sous la tête.
	await _move_bed(-rider_spot_z, 0.8)
	_nozzle_material.emission_energy_multiplier = 2.5
	Sfx.set_loop(&"printer", &"repair_loop", -12.0)
	var elapsed := 0.0
	var next_spark := 0.0
	var body_top := nino.global_position + Vector3.UP * 0.62
	while elapsed < duration:
		var t := elapsed / duration
		# Balayage : allers-retours latéraux, de haut en bas puis remontée.
		var sweep := Vector3(sin(elapsed * 5.0) * 0.17, -0.3 * sin(t * PI), 0.0)
		_move_head_now(body_top + global_basis * sweep)
		_screen_material.set_shader_parameter("progress", t)
		service_progressed.emit(t)
		if elapsed >= next_spark:
			next_spark = elapsed + randf_range(0.25, 0.6)
			_flash()
			visual.emit_sparks(5)
			visual.glitch_pulse(0.3, 0.15)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	service_progressed.emit(1.0)
	Sfx.stop_loop(&"printer")
	Sfx.play(&"repair_done", -6.0)
	_nozzle_material.emission_energy_multiplier = 0.0
	_flash()
	# 3. La tête se range, le plateau ramène Nin0 à l'avant.
	var park := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	park.tween_property(_gantry, "position:y", _gantry_rest_y, 0.7)
	park.tween_property(_head, "position:x", 1.4, 0.7)
	await park.finished
	await _move_bed(bed_presented_z, 0.8)
	_screen_material.set_shader_parameter("mode", 0)
	_rider = null
	# Nin0 redescend du plateau à sa place d'attente avant de reprendre le contrôle.
	await _hop_to(nino, waiting_spot(nino), 0.5)
	state = State.EMPTY
	nino.end_scripted()
	service_finished.emit()


## Fabrication d'une amélioration majeure (lot 5 : canon) puis installation physique :
## la pièce est imprimée couche par couche sur le plateau, Nin0 monte, la tête saisit la
## pièce et l'emboîte sur sa fixation (même mécanique que les jambes).
## `part` : modèle à imprimer (ajouté au plateau) ; `install` : appelé à l'emboîtement.
func fabricate_and_install(nino: NinoController, part: Node3D, mount: Callable, install: Callable, duration := 7.0) -> void:
	if state != State.EMPTY:
		return
	state = State.SERVICING
	nino.begin_scripted()
	var visual := nino.get_visual()
	await _step_to_waiting_spot(nino)
	# 1. Impression sur le plateau, à l'avant de la zone de Nin0.
	var pivot := Node3D.new()
	_bed.add_child(pivot)
	pivot.position = Vector3(0.0, BED_TOP + 0.005, -0.15)
	pivot.add_child(part)
	part.position = Vector3(0.0, 0.07, 0.0)
	pivot.scale = Vector3(1.0, 0.02, 1.0)
	_screen_material.set_shader_parameter("mode", 1)
	_screen_material.set_shader_parameter("progress", 0.0)
	Sfx.play(&"blip", -4.0)
	await _move_bed(0.15, 0.6)
	var heat := create_tween()
	heat.tween_property(_nozzle_material, "emission_energy_multiplier", 3.0, 1.0)
	await heat.finished
	Sfx.set_loop(&"printer", &"print_motor", -14.0)
	var elapsed := 0.0
	while elapsed < duration:
		var t := elapsed / duration
		pivot.scale.y = lerpf(0.02, 1.0, t)
		var top := pivot.global_position + Vector3.UP * (0.02 + 0.16 * t)
		var sweep := global_basis * Vector3(sin(elapsed * 9.0) * 0.08, 0.0, 0.0)
		_move_head_now(top + sweep)
		_bed.position.z = 0.15 + sin(elapsed * 7.0) * 0.04
		_screen_material.set_shader_parameter("progress", t)
		service_progressed.emit(t)
		Sfx.set_loop(&"printer", &"print_motor", -14.0, 0.9 + 0.2 * sin(elapsed * 2.3))
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	pivot.scale.y = 1.0
	Sfx.stop_loop(&"printer")
	Sfx.play(&"print_done", -4.0)
	_nozzle_material.emission_energy_multiplier = 0.0
	_screen_material.set_shader_parameter("mode", 2)
	var park := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	park.tween_property(_gantry, "position:y", _gantry_rest_y, 0.8)
	park.tween_property(_head, "position:x", 1.4, 0.8)
	await park.finished
	await _move_bed(bed_presented_z, 0.8)
	# 2. Présentation : la pièce sur le plateau, Nin0 la regarde.
	visual.look_target = part.global_position
	visual.show_emotion(NinoVisual.Emotion.SURPRISED, 1.2)
	await get_tree().create_timer(1.2).timeout
	visual.look_target = null
	# 3. Nin0 se hisse sur le plateau (derrière la pièce).
	var spot := _bed.to_global(Vector3(0.0, BED_TOP + 0.01, rider_spot_z))
	var from := nino.global_position
	var apex := (from + spot) * 0.5 + Vector3.UP * 0.6
	var hop := create_tween().set_trans(Tween.TRANS_SINE)
	hop.tween_method(func(k: float) -> void:
		nino.global_position = from.lerp(apex, k).lerp(apex.lerp(spot, k), k)
	, 0.0, 1.0, 0.5)
	hop.parallel().tween_property(nino, "rotation:y", global_rotation.y, 0.5)
	Sfx.play(&"jump", -8.0)
	await hop.finished
	visual.react_to_landing(4.0)
	_rider = nino
	_screen_material.set_shader_parameter("mode", 1)
	# 4. La tête saisit la pièce…
	await _move_head(part.global_position + Vector3.UP * 0.07, 0.6)
	var held := part.global_transform
	pivot.remove_child(part)
	add_child(part)
	part.global_transform = held
	_carried_offset = Vector3(0.0, 0.07, 0.0)
	_carried = part
	Sfx.play(&"click", -10.0, 1.4)
	await _move_head(_nozzle_tip() + Vector3.UP * 0.3, 0.4)
	pivot.queue_free()
	# … le plateau amène Nin0 sous la tête, la pièce descend sur sa fixation.
	await _move_bed(-rider_spot_z, 0.7)
	var target: Vector3 = mount.call()
	await _move_head(target + Vector3.UP * 0.07 + Vector3.UP * 0.22, 0.5)
	var align := create_tween()
	align.tween_property(part, "global_rotation", nino.get_visual().global_rotation, 0.3)
	await _move_head(target + Vector3.UP * 0.07, 0.35)
	# 5. Emboîtement.
	_carried = null
	_carried_offset = Vector3(0.0, HIP_HEIGHT, 0.0)
	part.queue_free()
	install.call()
	visual.react_to_jump()
	Sfx.play(&"click", 0.0, 0.9)
	Sfx.play(&"servo", -10.0, 1.4)
	_flash()
	visual.emit_sparks(6)
	await _move_head(_nozzle_tip() + Vector3.UP * 0.5, 0.4)
	var rest := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	rest.tween_property(_gantry, "position:y", _gantry_rest_y, 0.8)
	rest.tween_property(_head, "position:x", 1.4, 0.8)
	await rest.finished
	await _move_bed(bed_presented_z, 0.8)
	_screen_material.set_shader_parameter("mode", 0)
	_rider = null
	await _hop_to(nino, waiting_spot(nino), 0.5)
	state = State.EMPTY
	nino.end_scripted()
	installation_finished.emit()


## État après chargement d'une sauvegarde : sous tension, jambes déjà installées.
func set_completed() -> void:
	state = State.EMPTY
	_apply_power_visuals(true)
	_printed_legs.visible = false
	_bed.position.z = bed_presented_z


func _animate_printing(delta: float) -> void:
	_progress = minf(_progress + delta / print_duration, 1.0)
	var layer := _progress * part_height
	_set_cut(_printed_legs.global_position.y + layer)
	_screen_material.set_shader_parameter("progress", _progress)
	print_progressed.emit(_progress)
	# Trajectoire de la tête : allers-retours au-dessus de chaque pièce.
	var side := -1.0 if fmod(_time, 1.2) < 0.6 else 1.0
	_head.position.x = lerpf(_head.position.x, side * 0.18 + sin(_time * 13.0) * 0.07, 1.0 - exp(-20.0 * delta))
	_bed.position.z = sin(_time * 9.0) * 0.06
	_gantry.position.y = _bed.position.y + BED_TOP + layer + 0.015
	Sfx.set_loop(&"printer", &"print_motor", -14.0, 0.9 + 0.2 * sin(_time * 2.3))
	if _progress >= 1.0:
		_finish_print()


func _finish_print() -> void:
	state = State.DONE
	_set_cut(100.0)
	Sfx.stop_loop(&"printer")
	Sfx.play(&"print_done", -4.0)
	_screen_material.set_shader_parameter("mode", 2)
	_nozzle_material.emission_energy_multiplier = 0.0
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_gantry, "position:y", _gantry_rest_y, 1.2)
	tween.tween_property(_head, "position:x", 1.4, 1.2)
	tween.tween_property(_bed, "position:z", bed_presented_z, 1.4)
	await tween.finished
	print_finished.emit()


## Déplace le plateau (et Nin0 s'il est dessus pendant l'installation).
func _move_bed(z: float, duration: float) -> void:
	var start := _bed.position.z
	var rider_start := _rider.global_position if _rider else Vector3.ZERO
	var axis := global_basis.z
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(value: float) -> void:
		_bed.position.z = value
		if _rider:
			_rider.global_position = rider_start + axis * (value - start)
	, start, z, duration)
	Sfx.play(&"servo", -16.0, 0.7)
	await tween.finished


## Amène la pointe de la buse à une position (monde). La buse ne bouge qu'en X et Y :
## la profondeur est réglée par le plateau.
func _move_head(world: Vector3, duration: float) -> void:
	var local := to_local(world)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_head, "position:x", local.x, duration)
	tween.tween_property(_gantry, "position:y", local.y, duration)
	await tween.finished


## Place immédiatement la buse (suivi image par image pendant l'entretien).
func _move_head_now(world: Vector3) -> void:
	var local := to_local(world)
	_head.position.x = lerpf(_head.position.x, local.x, 0.35)
	_gantry.position.y = lerpf(_gantry.position.y, local.y, 0.35)


func _nozzle_tip() -> Vector3:
	return _head.global_position


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(_spark, "light_energy", 2.5, 0.05)
	tween.tween_property(_spark, "light_energy", 0.0, 0.35)


func _set_cut(world_height: float) -> void:
	for material in _print_materials:
		material.set_shader_parameter("cut_height", world_height)


func _apply_power_visuals(on: bool) -> void:
	_screen_material.set_shader_parameter("power", 1.0 if on else 0.0)
	_screen_material.set_shader_parameter("mode", 0)
	_led_material.emission_energy_multiplier = 2.5 if on else 0.0
	if _screen_glow:
		_screen_glow.light_energy = 0.35 if on else 0.0
	_led_material.albedo_color = Color(0.3, 1.0, 0.4) if on else Color(0.15, 0.2, 0.15)
	_nozzle_material.emission_energy_multiplier = 0.0


func _update_filament() -> void:
	# Le filament relie la bobine à la tête d'impression.
	var start := _filament.to_local(_spool.global_position + Vector3(0.0, -0.75, 0.0))
	var finish := _filament.to_local(_head.global_position + Vector3(0.0, 0.7, 0.0))
	var middle := (start + finish) * 0.5 + Vector3(0.0, 0.25, 0.3)
	var points := PackedVector3Array([start, middle, finish])
	if points != _filament.points:
		_filament.points = points


## Avant que le plateau bouge : Nin0 recule doucement à une place d'attente, face à
## la machine, hors du plateau (évite qu'il soit poussé ou téléporté au départ).
func _step_to_waiting_spot(nino: NinoController) -> void:
	nino.velocity = Vector3.ZERO
	await _hop_to(nino, waiting_spot(nino), 0.45)


## Place d'attente face à la machine, posée sur le vrai sol (le plan de l'imprimante),
## quelle que soit la hauteur d'où Nin0 a lancé l'interface (pente, livre, rebord…).
func waiting_spot(nino: NinoController) -> Vector3:
	var spot := to_global(Vector3(0.0, 0.0, bed_presented_z + 2.1))
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 1.5, spot + Vector3.DOWN * 1.5, 1, [nino.get_rid()])
	var hit := space.intersect_ray(query)
	spot.y = (hit.position as Vector3).y if not hit.is_empty() else global_position.y
	return spot


## Petit bond lisible (arc) vers un point, en se tournant vers la machine. Sans saut de
## position : la trajectoire part toujours de la position réelle de Nin0.
func _hop_to(nino: NinoController, spot: Vector3, duration: float) -> void:
	var from := nino.global_position
	if from.distance_to(spot) < 0.03:
		var turn := create_tween()
		turn.tween_property(nino, "rotation:y", global_rotation.y, 0.3)
		await turn.finished
		return
	var lift := clampf(absf(spot.y - from.y) * 0.5 + 0.15, 0.15, 0.6)
	var apex := (from + spot) * 0.5 + Vector3.UP * (maxf(spot.y, from.y) - (from.y + spot.y) * 0.5 + lift)
	var hop := create_tween().set_trans(Tween.TRANS_SINE)
	hop.tween_method(func(k: float) -> void:
		nino.global_position = from.lerp(apex, k).lerp(apex.lerp(spot, k), k)
	, 0.0, 1.0, clampf(from.distance_to(spot) * 0.4, 0.25, duration))
	hop.parallel().tween_property(nino, "rotation:y", global_rotation.y, 0.35)
	await hop.finished
	nino.velocity = Vector3.ZERO
	nino.get_visual().react_to_landing(2.0)
