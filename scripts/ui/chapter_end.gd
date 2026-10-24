class_name ChapterEnd
extends CanvasLayer
## Fin de chapitre (lot 5 : la cuisine est ouverte). Sobre ; le joueur continue dans
## la cuisine (lot 6, rien n'est perdu) ou quitte.

signal continue_requested

var _root: Control
var _content: Control
var _continue: Button


func _init() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.02, 0.85)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_content = UiKit.vbox(center, 14)
	_content.theme = UiKit.THEME
	UiKit.label(_content, "CHAPITRE 2 TERMINÉ", 16, UiKit.SCAN_COLOR).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.label(_content, "Le territoire des fourmis", 34, UiKit.TITLE_COLOR).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text := UiKit.label(_content, "La cuisine s'ouvre… Quelque chose y vit.", 17, UiKit.DIM_COLOR)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var buttons := UiKit.hbox(_content, 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_continue = UiKit.button(buttons, "Entrer dans la cuisine")
	_continue.pressed.connect(_on_continue)
	UiKit.button(buttons, "Quitter").pressed.connect(func() -> void: get_tree().quit())
	visible = false


func show_end() -> void:
	visible = true
	_root.modulate.a = 0.0
	GameState.modal_open = true
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 1.6)
	await tween.finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_continue.grab_focus()


func _on_continue() -> void:
	visible = false
	get_tree().paused = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	continue_requested.emit()
