class_name PauseMenu
extends CanvasLayer
## Menu pause (Échap) : reprendre, recommencer la démo, quitter. Rappel des commandes.

## Désactivé pendant l'écran titre, les séquences et l'écran de fin.
var allowed := false
## Nombre total de découvertes de la pièce (renseigné par le niveau).
var discovery_total := 0

@onready var _resume_button: Button = $Center/Panel/Margin/VBox/Buttons/ResumeButton
@onready var _restart_button: Button = $Center/Panel/Margin/VBox/Buttons/RestartButton
@onready var _quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton
@onready var _legs_controls: Control = $Center/Panel/Margin/VBox/LegsControls
@onready var _focus_controls: Control = $Center/Panel/Margin/VBox/FocusControls
@onready var _discoveries: Label = $Center/Panel/Margin/VBox/Discoveries


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	_restart_button.pressed.connect(func() -> void: GameState.restart_demo(true))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		close()
		get_viewport().set_input_as_handled()
	elif allowed and not GameState.modal_open:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_legs_controls.visible = GameState.legs_installed
	_focus_controls.visible = GameState.reached_window
	_discoveries.text = "Découvertes : %d / %d" % [GameState.discoveries.size(), discovery_total]
	_discoveries.visible = discovery_total > 0
	visible = true
	get_tree().paused = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
