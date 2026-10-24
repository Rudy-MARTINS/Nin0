class_name EndScreen
extends CanvasLayer
## Conclusion sobre de la démo.

@onready var _background: ColorRect = $Background
@onready var _content: Control = $Content
@onready var _restart_button: Button = $Content/VBox/Buttons/RestartButton
@onready var _quit_button: Button = $Content/VBox/Buttons/QuitButton


func _ready() -> void:
	visible = false
	_restart_button.pressed.connect(func() -> void: GameState.restart_demo(false))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())


func show_end() -> void:
	visible = true
	_background.modulate.a = 0.0
	_content.modulate.a = 0.0
	GameState.modal_open = true
	var tween := create_tween()
	tween.tween_property(_background, "modulate:a", 1.0, 2.0)
	tween.tween_interval(0.6)
	tween.tween_property(_content, "modulate:a", 1.0, 1.5)
	await tween.finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_restart_button.grab_focus()
