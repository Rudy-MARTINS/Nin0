class_name FocusTarget
extends Marker3D
## Élément identifiable avec la vision focalisée de Nin0 (mécanisme, passage, objet,
## souvenir…). Placer ce marqueur sur l'élément ; FocusVision le détecte quand il est
## visé, assez proche, sous un angle valable, sans obstacle, pendant assez longtemps.

signal identified(target: FocusTarget)

@export var id: StringName
## Taille approximative de l'élément (unités) : tolérance de visée.
@export var radius := 0.6
## Règles d'observation (portée, angle, temps de visée…). Vide = profil par défaut.
@export var profile: ObservationProfile
## Normale de la face observable (repère local). Nulle = observable de partout.
@export var facing := Vector3.ZERO
## Souvenir associé : l'observer l'ajoute aux archives fragmentées.
@export var memory: MemoryData
## Espèce associée (créature) : l'observer l'ajoute à l'encyclopédie biologique.
@export var species: SpeciesData
## Pensée affichée à l'identification.
@export var thought_icons: Array[StringName] = [&"exclamation"]
@export var thought_text := ""
@export var enabled := true
## Affiche un repère discret dans la vision focalisée (aide si l'élément est peu visible).
@export var show_marker := false
## Léger halo chaud qui « respire » sur les éléments fixes à observer (lisibilité par
## l'éclairage, sans icône). Jamais sur les créatures ; éteint une fois identifié.
@export var glint := true

var is_identified := false
var _glint_light: OmniLight3D
var _glint_time := 0.0


func _ready() -> void:
	add_to_group(&"focus_targets")
	if glint and species == null:
		_glint_light = OmniLight3D.new()
		_glint_light.light_color = Color(1.0, 0.86, 0.6)
		_glint_light.omni_range = clampf(radius * 2.2, 0.6, 2.5)
		_glint_light.light_energy = 0.0
		_glint_light.shadow_enabled = false
		add_child(_glint_light)
		_glint_time = randf() * TAU


func _process(delta: float) -> void:
	if _glint_light == null:
		set_process(false)
		return
	_glint_time += delta
	var on := enabled and not is_identified
	var target := (0.22 + 0.12 * sin(_glint_time * 1.6)) if on else 0.0
	_glint_light.light_energy = lerpf(_glint_light.light_energy, target, 1.0 - exp(-3.0 * delta))
	if not on and _glint_light.light_energy < 0.01:
		_glint_light.light_energy = 0.0


func mark_identified(silent := false) -> void:
	if is_identified:
		return
	is_identified = true
	if not silent:
		identified.emit(self)


## Direction (monde) de la face observable, ou Vector3.ZERO.
func get_facing() -> Vector3:
	if facing == Vector3.ZERO:
		return Vector3.ZERO
	return (global_basis * facing).normalized()
