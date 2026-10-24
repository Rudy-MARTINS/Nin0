class_name Hud
extends CanvasLayer
## Interface de jeu discrète : objectif, action contextuelle, indice, mode, annonces,
## intégrité (après le premier choc) et fragments de filament (après le premier).
## Rien n'est affiché en permanence sauf l'objectif (petit) et le mode (une fois réveillé).

const KEY_COLOR := "#ffd08a"

@onready var _objective_box: Control = $Objective
@onready var _objective_label: Label = $Objective/Text
@onready var _prompt_box: Control = $Prompt
@onready var _prompt_key: Label = $Prompt/Row/KeyBadge/Key
@onready var _prompt_label: Label = $Prompt/Row/Text
@onready var _hint_label: RichTextLabel = $Hint
@onready var _mode_box: Control = $Mode
@onready var _mode_label: Label = $Mode/Value
@onready var _toast_label: Label = $Toast
@onready var _fader: ColorRect = $Fader
@onready var _status_box: Control = $Status
@onready var _gauge: IntegrityGauge = $Status/Gauge
@onready var _fragments_box: Control = $Fragments
@onready var _fragments_label: Label = $Fragments/Count
@onready var _plastic_box: Control = $Plastic
@onready var _plastic_label: Label = $Plastic/Count

var _hint_tween: Tween
var _hint_serial := 0
var _toast_tween: Tween
var _objective_tween: Tween
var _mode_known := false
var _gameplay_visible := true
var _last_fragments := -1
var _last_plastic := -1
var _notice: PanelContainer
var _notice_title: Label
var _notice_text: Label
var _notice_icon: ThoughtIcon
var _notice_tween: Tween


func _ready() -> void:
	_objective_box.modulate.a = 0.0
	_prompt_box.visible = false
	_hint_label.modulate.a = 0.0
	_mode_box.visible = false
	_toast_label.modulate.a = 0.0
	GameState.stats_changed.connect(refresh_stats)
	GameState.resource_discovered.connect(_on_resource_discovered)
	_build_notice()
	refresh_stats()


## Intégrité, bouclier et fragments (affichés seulement une fois connus).
func refresh_stats() -> void:
	_gauge.set_values(GameState.integrity, GameState.integrity_max, GameState.shield, GameState.shield_max)
	_status_box.visible = _gameplay_visible and GameState.integrity_known
	_fragments_box.visible = _gameplay_visible and (GameState.fragments > 0 or not GameState.collected_pickups.is_empty())
	if GameState.fragments != _last_fragments:
		if _last_fragments >= 0 and GameState.fragments > _last_fragments:
			var pop := create_tween()
			_fragments_box.scale = Vector2.ONE * 1.25
			_fragments_box.pivot_offset = _fragments_box.size * Vector2(1.0, 0.5)
			pop.tween_property(_fragments_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		_last_fragments = GameState.fragments
		_fragments_label.text = str(GameState.fragments)
	var plastic_known := GameState.seen_notices.has(&"resource_plastic") or GameState.has_cannon()
	_plastic_box.visible = _gameplay_visible and plastic_known
	if GameState.ammo_plastic != _last_plastic:
		if _last_plastic >= 0 and GameState.ammo_plastic > _last_plastic:
			var pop2 := create_tween()
			_plastic_box.scale = Vector2.ONE * 1.25
			_plastic_box.pivot_offset = _plastic_box.size * Vector2(1.0, 0.5)
			pop2.tween_property(_plastic_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		_last_plastic = GameState.ammo_plastic
		_plastic_label.text = "%d / %d" % [GameState.ammo_plastic, GameState.PLASTIC_MAX]


## Explication affichée une seule fois, à la première découverte d'une ressource.
## Ne bloque rien : un petit cartouche en bas à droite, qui disparaît seul.
func show_notice(icon: StringName, title: String, text: String, duration := 5.0) -> void:
	_notice_icon.icon = icon
	_notice_title.text = title
	_notice_text.text = text
	if _notice_tween:
		_notice_tween.kill()
	_notice.visible = _gameplay_visible
	_notice_tween = create_tween()
	_notice_tween.tween_property(_notice, "modulate:a", 1.0, 0.3)
	_notice_tween.tween_interval(duration)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.6)


func _on_resource_discovered(kind: StringName) -> void:
	if kind == GameState.RESOURCE_PLASTIC:
		show_notice(&"plastic", "Plastique à projectiles découvert", "Permet de fabriquer les munitions du canon.")
	else:
		show_notice(&"filament", "Filament structurel découvert", "Matériau de réparation et de fabrication.")


func _build_notice() -> void:
	_notice = PanelContainer.new()
	_notice.theme = _objective_box.theme
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_notice.offset_left = -430.0
	_notice.offset_top = -150.0
	_notice.offset_right = -28.0
	_notice.offset_bottom = -70.0
	_notice.modulate.a = 0.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_notice.add_child(row)
	_notice_icon = ThoughtIcon.new()
	_notice_icon.custom_minimum_size = Vector2(52, 52)
	row.add_child(_notice_icon)
	var col := VBoxContainer.new()
	row.add_child(col)
	_notice_title = Label.new()
	_notice_title.add_theme_font_size_override("font_size", 18)
	_notice_title.add_theme_color_override("font_color", Color(1, 0.86, 0.62))
	col.add_child(_notice_title)
	_notice_text = Label.new()
	_notice_text.add_theme_font_size_override("font_size", 15)
	col.add_child(_notice_text)
	add_child(_notice)


## Met en forme une touche dans un texte d'indice : « [E] ».
static func key(name: String) -> String:
	return "[color=%s][b]%s[/b][/color]" % [KEY_COLOR, name]


## Textes de l'interface que les bulles de pensée ne doivent pas recouvrir.
func text_controls() -> Array[Control]:
	var list: Array[Control] = [_objective_box, _hint_label, _toast_label, _notice]
	for name in ["Status", "Prompt"]:
		var node := get_node_or_null(name) as Control
		if node:
			list.append(node)
	return list


func set_objective(text: String) -> void:
	if text == _objective_label.text and _objective_box.modulate.a > 0.5:
		return
	# Même objectif dont seul le détail change (ex. pourcentage) : pas de fondu.
	if _objective_box.modulate.a > 0.9 and text != "" \
			and text.get_slice("…", 0) == _objective_label.text.get_slice("…", 0):
		_objective_label.text = text
		return
	if _objective_tween:
		_objective_tween.kill()
	_objective_tween = create_tween()
	if _objective_box.modulate.a > 0.0:
		_objective_tween.tween_property(_objective_box, "modulate:a", 0.0, 0.25)
	_objective_tween.tween_callback(func() -> void: _objective_label.text = text)
	if text != "":
		_objective_tween.tween_property(_objective_box, "modulate:a", 1.0, 0.5)


func show_prompt(key_name: String, text: String) -> void:
	_prompt_key.text = key_name
	_prompt_label.text = text
	_prompt_box.visible = true


func hide_prompt() -> void:
	_prompt_box.visible = false


## Affiche un indice. duration = 0 : reste affiché jusqu'au prochain indice ou `clear_hint`.
func show_hint(bbcode: String, duration := 0.0) -> void:
	_hint_serial += 1
	var serial := _hint_serial
	if _hint_tween:
		_hint_tween.kill()
	_hint_label.text = "[center]%s[/center]" % bbcode
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_label, "modulate:a", 1.0, 0.3)
	if duration > 0.0:
		_hint_tween.tween_interval(duration)
		_hint_tween.tween_callback(func() -> void:
			if serial == _hint_serial:
				clear_hint())


func clear_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_label, "modulate:a", 0.0, 0.4)


func show_toast(text: String, duration := 3.0) -> void:
	_toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.4)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.8)


func set_mode(text: String) -> void:
	_mode_known = true
	_mode_box.visible = true
	_mode_label.text = text


func set_gameplay_visible(value: bool) -> void:
	_gameplay_visible = value
	for node: CanvasItem in [_objective_box, _hint_label, _toast_label]:
		node.visible = value
	if _notice:
		_notice.visible = value
	_mode_box.visible = value and _mode_known
	refresh_stats()
	if not value:
		hide_prompt()


## Fondu de l'écran (0 = transparent, 1 = noir). Renvoie le Tween pour pouvoir l'attendre.
func fade_to(alpha: float, duration: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_fader, "color:a", alpha, duration)
	return tween


func set_fade(alpha: float) -> void:
	_fader.color.a = alpha
