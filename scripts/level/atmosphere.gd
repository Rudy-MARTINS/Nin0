class_name Atmosphere
extends Node
## Identité lumineuse par pièce (lot 7, glow-up) : lumière ambiante, brume, étalonnage
## (luminosité, contraste, saturation), lueur et intensité du soleil, avec des fondus
## doux d'une pièce à l'autre. L'Environment de la scène est dupliqué : la ressource
## d'origine n'est jamais modifiée (aucune fuite vers une autre scène).
##
## - hub : refuge, tons chauds et nostalgiques, contraste modéré ;
## - sas : lumière plus neutre, espace de transition poussiéreux ;
## - bath : dominante froide, humide, un peu inquiétante ;
## - kitchen : jour de la fenêtre, dessous de meubles sombres, plus contrasté ;
## - salon : doux, vaste, légèrement mélancolique ;
## - sleep / title : pénombre de l'atelier avant le réveil.
## Un léger vignettage, toujours discret, resserre l'image sur Nin0.

const MOODS := {
	&"title": {"ambient": Color(0.5, 0.52, 0.62), "ambient_energy": 0.32, "fog": Color(0.5, 0.48, 0.5), "fog_density": 0.004,
		"brightness": 0.94, "contrast": 1.12, "saturation": 0.92, "glow": 0.32, "sun": 0.55, "fill": 0.45, "exposure": 0.95},
	&"sleep": {"ambient": Color(0.45, 0.5, 0.62), "ambient_energy": 0.26, "fog": Color(0.42, 0.44, 0.5), "fog_density": 0.0045,
		"brightness": 0.9, "contrast": 1.14, "saturation": 0.88, "glow": 0.34, "sun": 0.42, "fill": 0.35, "exposure": 0.92},
	&"hub": {"ambient": Color(0.66, 0.58, 0.54), "ambient_energy": 0.5, "fog": Color(0.8, 0.68, 0.52), "fog_density": 0.003,
		"brightness": 1.0, "contrast": 1.08, "saturation": 1.06, "glow": 0.26, "sun": 1.0, "fill": 1.0, "exposure": 1.0},
	&"sas": {"ambient": Color(0.6, 0.6, 0.62), "ambient_energy": 0.44, "fog": Color(0.62, 0.62, 0.6), "fog_density": 0.0038,
		"brightness": 0.98, "contrast": 1.08, "saturation": 0.9, "glow": 0.2, "sun": 0.85, "fill": 0.8, "exposure": 1.0},
	&"bath": {"ambient": Color(0.5, 0.6, 0.7), "ambient_energy": 0.42, "fog": Color(0.48, 0.6, 0.64), "fog_density": 0.0055,
		"brightness": 0.96, "contrast": 1.12, "saturation": 0.88, "glow": 0.3, "sun": 0.7, "fill": 0.7, "exposure": 0.98},
	&"kitchen": {"ambient": Color(0.56, 0.6, 0.7), "ambient_energy": 0.28, "fog": Color(0.7, 0.75, 0.82), "fog_density": 0.004,
		"brightness": 1.0, "contrast": 1.14, "saturation": 1.0, "glow": 0.3, "sun": 0.9, "fill": 0.6, "exposure": 1.02},
	&"salon": {"ambient": Color(0.68, 0.63, 0.6), "ambient_energy": 0.46, "fog": Color(0.82, 0.74, 0.66), "fog_density": 0.0034,
		"brightness": 1.0, "contrast": 1.05, "saturation": 0.88, "glow": 0.3, "sun": 0.9, "fill": 0.8, "exposure": 1.0},
}

var mood: StringName = &""
var environment: Environment
var sun: DirectionalLight3D
var fills: Array[Light3D] = []
var _sun_base := 1.0
var _fill_base := {}
var _tween: Tween
var _vignette: ColorRect


func setup(world: WorldEnvironment, sun_light: DirectionalLight3D, fill_lights: Array[Light3D]) -> void:
	if world and world.environment:
		environment = world.environment.duplicate() as Environment
		world.environment = environment
		environment.adjustment_enabled = true
		environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		environment.tonemap_white = 6.0
		environment.glow_enabled = true
		environment.glow_hdr_threshold = 0.9
	sun = sun_light
	if sun:
		_sun_base = sun.light_energy
	fills = fill_lights
	for light in fills:
		_fill_base[light] = light.light_energy
	_build_vignette()


func set_mood(id: StringName, duration := 2.0) -> void:
	if environment == null or not MOODS.has(id) or id == mood:
		return
	mood = id
	var m: Dictionary = MOODS[id]
	if _tween:
		_tween.kill()
	if duration <= 0.0:
		_apply(m)
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(environment, "ambient_light_color", m.ambient, duration)
	_tween.tween_property(environment, "ambient_light_energy", m.ambient_energy, duration)
	_tween.tween_property(environment, "fog_light_color", m.fog, duration)
	_tween.tween_property(environment, "fog_density", m.fog_density, duration)
	_tween.tween_property(environment, "adjustment_brightness", m.brightness, duration)
	_tween.tween_property(environment, "adjustment_contrast", m.contrast, duration)
	_tween.tween_property(environment, "adjustment_saturation", m.saturation, duration)
	_tween.tween_property(environment, "glow_intensity", m.glow, duration)
	_tween.tween_property(environment, "tonemap_exposure", m.exposure, duration)
	if sun:
		_tween.tween_property(sun, "light_energy", _sun_base * m.sun, duration)
	for light in fills:
		if is_instance_valid(light):
			_tween.tween_property(light, "light_energy", float(_fill_base[light]) * m.fill, duration)


func _apply(m: Dictionary) -> void:
	environment.ambient_light_color = m.ambient
	environment.ambient_light_energy = m.ambient_energy
	environment.fog_light_color = m.fog
	environment.fog_density = m.fog_density
	environment.adjustment_brightness = m.brightness
	environment.adjustment_contrast = m.contrast
	environment.adjustment_saturation = m.saturation
	environment.glow_intensity = m.glow
	environment.tonemap_exposure = m.exposure
	if sun:
		sun.light_energy = _sun_base * m.sun
	for light in fills:
		if is_instance_valid(light):
			light.light_energy = float(_fill_base[light]) * m.fill


## Vignettage discret (plus marqué pendant les mises en scène).
func set_vignette(strength: float, duration := 0.8) -> void:
	if _vignette == null:
		return
	var material := _vignette.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("strength", v),
			float(material.get_shader_parameter("strength")), strength, duration)


func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/vignette.gdshader")
	material.set_shader_parameter("strength", 0.32)
	_vignette.material = material
	layer.add_child(_vignette)
