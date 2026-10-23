class_name PrinterPanel
extends CanvasLayer
## Interface de l'imprimante 3D. Une seule amélioration dans cette démo : les jambes.
## Pas d'inventaire ni de ressources : seule l'alimentation électrique est requise.

signal print_requested
signal closed

@onready var _status: Label = $Center/Panel/Margin/VBox/Status
@onready var _requirement: Label = $Center/Panel/Margin/VBox/Card/Info/Requirement
@onready var _print_button: Button = $Center/Panel/Margin/VBox/Buttons/PrintButton
@onready var _close_button: Button = $Center/Panel/Margin/VBox/Buttons/CloseButton


func _ready() -> void:
	visible = false
	_print_button.pressed.connect(_on_print_pressed)
	_close_button.pressed.connect(close)


## powered : imprimante alimentée ; already_printed : jambes déjà fabriquées.
func open(powered: bool, already_printed: bool) -> void:
	if already_printed:
		_status.text = "Impression terminée"
		_status.modulate = Color(0.55, 1.0, 0.6)
		_requirement.text = "✔ Fabriquées"
	elif powered:
		_status.text = "Prête"
		_status.modulate = Color(0.55, 0.85, 1.0)
		_requirement.text = "✔ Alimentation électrique"
	else:
		_status.text = "Hors tension"
		_status.modulate = Color(1.0, 0.5, 0.4)
		_requirement.text = "✖ Alimentation électrique requise"
	_print_button.disabled = not powered or already_printed
	visible = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _print_button.disabled:
		_close_button.grab_focus()
	else:
		_print_button.grab_focus()
	Sfx.play(&"blip", -8.0)


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _on_print_pressed() -> void:
	if _print_button.disabled:
		return
	visible = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		if _print_button.disabled:
			close()
		else:
			_on_print_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
