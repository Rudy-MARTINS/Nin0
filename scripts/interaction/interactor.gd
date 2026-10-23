class_name Interactor
extends Area3D
## Détecte l'objet interactif le plus proche de NINO et déclenche l'interaction (touche E).

signal focus_changed(target: Interactable)

@export var player: NinoController

var focused: Interactable


func _ready() -> void:
	collision_layer = 0
	collision_mask = Interactable.LAYER
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	var best: Interactable = null
	var best_distance := INF
	if player.can_interact():
		for area in get_overlapping_areas():
			var candidate := area as Interactable
			if candidate == null or not candidate.enabled:
				continue
			var distance := global_position.distance_squared_to(candidate.global_position)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	if best != focused:
		focused = best
		focus_changed.emit(focused)
	player.get_visual().look_target = focused.get_look_position() if focused else null

	if focused and Input.is_action_just_pressed("interact"):
		focused.interact(player)


## Force la réévaluation (après un changement de texte ou d'état).
func refresh() -> void:
	focused = null
