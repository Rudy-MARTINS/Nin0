class_name Printer3D
extends Node3D
## Imprimante 3D de l'atelier (unique dans le périmètre actuel, GDD §4).
##
## Mise en scène de l'impression : chauffe de la buse, déplacements de la tête et du
## plateau, pièces révélées couche par couche (shader print_reveal), signal de fin.
## La progression (alimentation, jambes) est gérée par le directeur de niveau.

signal print_finished
signal legs_delivered

enum State { OFF, READY, HEATING, PRINTING, DONE, EMPTY }

## Durée de l'impression des jambes (secondes).
@export var print_duration := 10.0
@export var heat_duration := 1.5
## Hauteur des pièces imprimées (unités locales).
@export var part_height := 0.47

var state := State.OFF

var _time := 0.0
var _progress := 0.0
var _print_materials: Array[ShaderMaterial] = []
var _screen_material: ShaderMaterial
var _nozzle_material: StandardMaterial3D
var _led_material: StandardMaterial3D
var _gantry_rest_y := 0.0
var _bed_top_y := 0.0

@onready var interactable: Interactable = $Interactable
@onready var _bed: Node3D = $Bed
@onready var _gantry: Node3D = $Gantry
@onready var _head: Node3D = $Gantry/Head
@onready var _printed_legs: Node3D = $Bed/PrintedLegs
@onready var _spool: Node3D = $Spool
@onready var _filament: Cable = $Filament


func _ready() -> void:
	_screen_material = ($Body/Screen as MeshInstance3D).material_override
	_nozzle_material = ($Gantry/Head/Nozzle as MeshInstance3D).material_override
	_led_material = ($Body/PowerLed as MeshInstance3D).material_override
	_gantry_rest_y = _gantry.position.y
	_bed_top_y = _printed_legs.position.y
	for mesh in _printed_legs.find_children("*", "MeshInstance3D", true, false):
		var material := (mesh as MeshInstance3D).material_override as ShaderMaterial
		if material and not _print_materials.has(material):
			_print_materials.append(material)
	_set_cut(-1.0)
	_printed_legs.visible = false
	_apply_power_visuals(false)


func _process(delta: float) -> void:
	_time += delta
	match state:
		State.HEATING:
			_nozzle_material.emission_energy_multiplier = minf(_nozzle_material.emission_energy_multiplier + delta * 2.0, 3.0)
		State.PRINTING:
			_animate_printing(delta)
	_update_filament()


func set_powered(on: bool) -> void:
	if on and state == State.OFF:
		state = State.READY
		_apply_power_visuals(true)
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


## Les jambes quittent le plateau et rejoignent les fixations de NINO.
func deliver_legs(mount_positions: Array[Vector3]) -> void:
	if state != State.DONE:
		return
	state = State.EMPTY
	var legs := _printed_legs.get_children()
	var tween := create_tween().set_parallel(true)
	for i in mini(legs.size(), mount_positions.size()):
		var leg := legs[i] as Node3D
		var start := leg.global_position
		var finish := mount_positions[i] + Vector3.DOWN * 0.42
		var apex := (start + finish) * 0.5 + Vector3.UP * 0.6
		tween.tween_method(func(t: float) -> void:
			# Courbe de Bézier quadratique : petit arc au-dessus du plateau.
			leg.global_position = start.lerp(apex, t).lerp(apex.lerp(finish, t), t)
			leg.scale = Vector3.ONE * lerpf(1.0, 0.9, t)
		, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(i * 0.15)
	await tween.finished
	_printed_legs.visible = false
	Sfx.play(&"click", -2.0)
	legs_delivered.emit()
	_screen_material.set_shader_parameter("mode", 0)
	var back := create_tween()
	back.tween_property(_bed, "position:z", 0.0, 1.0)


## État après chargement d'une sauvegarde : sous tension, jambes déjà récupérées.
func set_completed() -> void:
	state = State.EMPTY
	_apply_power_visuals(true)
	_printed_legs.visible = false


func _animate_printing(delta: float) -> void:
	_progress = minf(_progress + delta / print_duration, 1.0)
	var layer := _progress * part_height
	_set_cut(_printed_legs.global_position.y + layer)
	_screen_material.set_shader_parameter("progress", _progress)
	# Trajectoire de la tête : allers-retours au-dessus de chaque pièce.
	var side := -1.0 if fmod(_time, 1.2) < 0.6 else 1.0
	_head.position.x = lerpf(_head.position.x, side * 0.18 + sin(_time * 13.0) * 0.07, 1.0 - exp(-20.0 * delta))
	_bed.position.z = sin(_time * 9.0) * 0.06
	_gantry.position.y = _bed.position.y + _bed_top_y + layer + 0.015
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
	tween.tween_property(_bed, "position:z", 1.0, 1.4)
	await tween.finished
	print_finished.emit()


func _set_cut(world_height: float) -> void:
	for material in _print_materials:
		material.set_shader_parameter("cut_height", world_height)


func _apply_power_visuals(on: bool) -> void:
	_screen_material.set_shader_parameter("power", 1.0 if on else 0.0)
	_screen_material.set_shader_parameter("mode", 0)
	_led_material.emission_energy_multiplier = 2.5 if on else 0.0
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
