class_name PauseMenu
extends CanvasLayer
## Menu pause (Échap) : reprendre, recommencer la démo, quitter. Rappel des commandes,
## découvertes et archives fragmentées (souvenirs retrouvés, consultables).

## Désactivé pendant l'écran titre, les séquences et l'écran de fin.
var allowed := false
## Découvertes de la pièce (identifiants, renseignés par le niveau).
var discovery_ids: Array[StringName] = []

@onready var _resume_button: Button = $Center/Panel/Margin/VBox/Buttons/ResumeButton
@onready var _restart_button: Button = $Center/Panel/Margin/VBox/Buttons/RestartButton
@onready var _quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton
@onready var _legs_controls: Control = $Center/Panel/Margin/VBox/LegsControls
@onready var _focus_controls: Control = $Center/Panel/Margin/VBox/FocusControls
@onready var _discoveries: Label = $Center/Panel/Margin/VBox/Discoveries
@onready var _archives: Control = $Center/Panel/Margin/VBox/Archives
@onready var _archives_label: Label = $Center/Panel/Margin/VBox/Archives/Label
@onready var _archives_button: Button = $Center/Panel/Margin/VBox/Archives/ArchivesButton
@onready var _archives_text: RichTextLabel = $Center/Panel/Margin/VBox/ArchivesText


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	_restart_button.pressed.connect(func() -> void: GameState.restart_demo(true))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_archives_button.pressed.connect(func() -> void:
		_archives_text.visible = not _archives_text.visible)


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
	var known := discovery_ids.filter(func(id: StringName) -> bool: return GameState.has_discovery(id)).size()
	_discoveries.text = "Découvertes : %d / %d" % [known, discovery_ids.size()]
	_discoveries.visible = not discovery_ids.is_empty()
	# Les archives n'apparaissent qu'après le premier fragment retrouvé.
	_archives.visible = GameState.memory_count() > 0
	_archives_label.text = "Archives fragmentées — %d/%d" % [GameState.memory_count(), GameState.ARCHIVE.total]
	_archives_text.visible = false
	_archives_text.text = archives_text()
	visible = true
	get_tree().paused = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()


## Fragments retrouvés, dégradés selon la progression actuelle des archives.
static func archives_text() -> String:
	var archive := GameState.ARCHIVE
	var corruption := GameState.memory_corruption()
	var blocks: PackedStringArray = []
	for id in GameState.memories:
		var memory := archive.get_entry(id)
		if memory == null:
			continue
		var lines: PackedStringArray = []
		for i in memory.lines.size():
			lines.append(MemoryArchive.degrade(memory.lines[i], corruption, hash(memory.id) + i * 31 + GameState.memory_count() * 7))
		blocks.append("[b]%s[/b]\n%s" % [memory.title, "  ".join(lines)])
	return "\n".join(blocks)


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
