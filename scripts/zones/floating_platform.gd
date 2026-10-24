class_name FloatingPlatform
extends AnimatableBody3D
## Débris flottant sur la matière du lavabo (éponge, bouchon, savon…) : léger
## balancement vertical et, pour certains, dérive lente aller-retour. Nin0 est porté.
## À la vidange, le débris descend avec le niveau et cesse de dériver.

@export var bob_amplitude := 0.04
@export var bob_speed := 1.3
## Amplitude de dérive (aller-retour autour de la position de départ).
@export var drift := Vector3.ZERO
@export var drift_speed := 0.5

var floating := true
var _origin: Vector3
var _time := 0.0
var _drop := 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	if not floating:
		return
	var offset := drift * sin(_time * drift_speed) + Vector3.UP * (sin(_time * bob_speed) * bob_amplitude)
	position = _origin + offset + Vector3.DOWN * _drop


## Vidange : le débris descend de `amount` en `duration` secondes et se pose.
func settle(amount: float, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "_drop", amount, duration)
	tween.parallel().tween_property(self, "bob_amplitude", 0.0, duration)
	tween.parallel().tween_property(self, "drift", Vector3.ZERO, duration)


## Retour à l'état initial (réinitialisation de l'arène).
func restore(bob: float, drift_value: Vector3) -> void:
	_drop = 0.0
	bob_amplitude = bob
	drift = drift_value
	floating = true
	position = _origin
