class_name TitleScreen
extends CanvasLayer
## Écran d'accueil, superposé à la scène (Nin0 en veille sur son socle, l'atelier dans la
## pénombre). Lot 7 (glow-up) : logo dessiné (« 0 » = écran-visage de Nin0), boutons
## sobres à liseré orange, apparition douce.

signal start_requested(resume: bool)

@onready var _start_button: Button = $Panel/Margin/VBox/Buttons/StartButton
@onready var _continue_button: Button = $Panel/Margin/VBox/Buttons/ContinueButton
@onready var _quit_button: Button = $Panel/Margin/VBox/Buttons/QuitButton


func _ready() -> void:
	visible = false
	_style()
	_start_button.pressed.connect(_on_start.bind(false))
	_continue_button.pressed.connect(_on_start.bind(true))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())


## Identité de l'écran titre : logo, sous-titre espacé, boutons discrets.
func _style() -> void:
	var title := $Panel/Margin/VBox/Title as Label
	var logo := TitleLogo.new()
	logo.name = "Logo"
	title.get_parent().add_child(logo)
	title.get_parent().move_child(logo, title.get_index())
	title.visible = false
	var subtitle := $Panel/Margin/VBox/Subtitle as Label
	subtitle.text = "PREMIÈRE  DÉMO"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.96, 0.62, 0.32, 0.95))
	subtitle.add_theme_constant_override("outline_size", 0)
	for button in [_start_button, _continue_button, _quit_button]:
		_menu_button(button)


static func _menu_button(button: Button) -> void:
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.94, 0.9, 0.82, 0.82))
	button.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.88))
	button.add_theme_color_override("font_focus_color", Color(1, 0.96, 0.88))
	button.add_theme_color_override("font_pressed_color", Color(1, 0.78, 0.5))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_left = 22
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.border_width_left = 2
	normal.border_color = Color(0.96, 0.55, 0.2, 0.25)
	var active := normal.duplicate() as StyleBoxFlat
	active.border_width_left = 5
	active.border_color = Color(0.96, 0.55, 0.2, 1.0)
	active.bg_color = Color(0.96, 0.55, 0.2, 0.1)
	active.corner_radius_top_right = 10
	active.corner_radius_bottom_right = 10
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, active)
	button.focus_entered.connect(func() -> void: Sfx.play(&"thought", -16.0, 1.3))


func open() -> void:
	var has_save := GameState.has_save()
	_continue_button.visible = has_save
	_start_button.text = "Nouvelle partie" if has_save else "Commencer"
	visible = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Apparition douce : la colonne glisse légèrement et s'éclaire.
	var column := $Panel/Margin as Control
	column.modulate.a = 0.0
	column.position.x = -24.0
	var appear := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	appear.tween_property(column, "modulate:a", 1.0, 1.6).set_delay(0.6)
	appear.tween_property(column, "position:x", 0.0, 1.6).set_delay(0.6)
	(_continue_button if has_save else _start_button).grab_focus()


func _on_start(resume: bool) -> void:
	Sfx.play(&"blip", -6.0)
	visible = false
	GameState.modal_open = false
	start_requested.emit(resume)
