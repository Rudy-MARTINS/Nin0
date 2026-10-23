extends CanvasLayer
## HUD du bac à sable (test_level) : état courant + rappel des commandes.

@export var player: NinoController

@onready var _state_label: Label = $Panel/Margin/VBox/StateLabel

const STATE_NAMES := {
	NinoController.State.FREE: "Libre",
	NinoController.State.CLIMBING: "Escalade",
	NinoController.State.MOUNTING: "Escalade (hissage)",
	NinoController.State.TRANSFORMING: "Transformation",
}


func _ready() -> void:
	if player:
		player.state_changed.connect(_on_state_changed)
		_on_state_changed(player.state)


func _on_state_changed(new_state: NinoController.State) -> void:
	_state_label.text = "Mode : %s" % STATE_NAMES.get(new_state, "?")
