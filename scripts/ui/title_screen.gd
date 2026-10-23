class_name TitleScreen
extends CanvasLayer
## Écran d'accueil minimal, superposé à la scène (Nin0 endormi sur son socle).

signal start_requested(resume: bool)

@onready var _start_button: Button = $Panel/Margin/VBox/Buttons/StartButton
@onready var _continue_button: Button = $Panel/Margin/VBox/Buttons/ContinueButton
@onready var _quit_button: Button = $Panel/Margin/VBox/Buttons/QuitButton


func _ready() -> void:
	visible = false
	_start_button.pressed.connect(_on_start.bind(false))
	_continue_button.pressed.connect(_on_start.bind(true))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())


func open() -> void:
	var has_save := GameState.has_save()
	_continue_button.visible = has_save
	_start_button.text = "Nouvelle partie" if has_save else "Commencer"
	visible = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(_continue_button if has_save else _start_button).grab_focus()


func _on_start(resume: bool) -> void:
	Sfx.play(&"blip", -6.0)
	visible = false
	GameState.modal_open = false
	start_requested.emit(resume)
