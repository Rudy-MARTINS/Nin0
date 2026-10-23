class_name PrinterPanel
extends CanvasLayer
## Interface de l'imprimante 3D (unique). Trois cartes, affichées selon la situation :
## - jambes mécaniques (impression, avant leur installation) ;
## - réparation (après la première blessure ; coûte des fragments de filament) ;
## - améliorations dont le plan est connu (ex. Renfort de châssis I).
## E valide le bouton sélectionné, Échap ferme.

signal print_requested
signal repair_requested
signal upgrade_requested(id: StringName)
signal closed

const OK_COLOR := Color(0.55, 1.0, 0.6)
const KO_COLOR := Color(1.0, 0.5, 0.4)

var _upgrade_id: StringName

@onready var _status: Label = $Center/Panel/Margin/VBox/PowerRow/Status
@onready var _fragments: Label = $Center/Panel/Margin/VBox/PowerRow/Fragments
@onready var _plans: Label = $Center/Panel/Margin/VBox/Plans
@onready var _legs_card: Control = $Center/Panel/Margin/VBox/LegsCard
@onready var _legs_requirement: Label = $Center/Panel/Margin/VBox/LegsCard/Info/Requirement
@onready var _print_button: Button = $Center/Panel/Margin/VBox/LegsCard/Button
@onready var _repair_card: Control = $Center/Panel/Margin/VBox/RepairCard
@onready var _repair_requirement: Label = $Center/Panel/Margin/VBox/RepairCard/Info/Requirement
@onready var _repair_button: Button = $Center/Panel/Margin/VBox/RepairCard/Button
@onready var _upgrade_card: Control = $Center/Panel/Margin/VBox/UpgradeCard
@onready var _upgrade_name: Label = $Center/Panel/Margin/VBox/UpgradeCard/Info/Name
@onready var _upgrade_description: Label = $Center/Panel/Margin/VBox/UpgradeCard/Info/Description
@onready var _upgrade_requirement: Label = $Center/Panel/Margin/VBox/UpgradeCard/Info/Requirement
@onready var _upgrade_button: Button = $Center/Panel/Margin/VBox/UpgradeCard/Button
@onready var _close_button: Button = $Center/Panel/Margin/VBox/Buttons/CloseButton


func _ready() -> void:
	visible = false
	_print_button.pressed.connect(_choose.bind(print_requested))
	_repair_button.pressed.connect(_choose.bind(repair_requested))
	_upgrade_button.pressed.connect(func() -> void: _choose(upgrade_requested, _upgrade_id))
	_close_button.pressed.connect(close)


## powered : imprimante alimentée ; already_printed : jambes déjà fabriquées.
## repair_cost : coût d'une réparation (0 = réparation non proposée).
func open(powered: bool, already_printed: bool, repair_cost := 0, upgrade: UpgradeData = null) -> void:
	_status.text = "● Sous tension" if powered else "● Coupée"
	_status.modulate = OK_COLOR if powered else KO_COLOR
	var service := repair_cost > 0 or upgrade != null
	_fragments.text = "Fragments de filament : %d" % GameState.fragments if service else ""

	# Jambes : seulement tant qu'elles ne sont pas installées.
	_legs_card.visible = not GameState.legs_installed
	if already_printed:
		_legs_requirement.text = "✔ Déjà fabriquées"
	elif powered:
		_legs_requirement.text = "Prête à imprimer"
	else:
		_legs_requirement.text = "✖ Nécessite l'alimentation électrique"
	_print_button.disabled = not powered or already_printed or not _legs_card.visible

	# Réparation.
	_repair_card.visible = repair_cost > 0
	var damaged := GameState.integrity < GameState.integrity_max
	var affordable := GameState.fragments >= repair_cost
	_repair_button.disabled = not (_repair_card.visible and damaged and affordable and powered)
	if not damaged:
		_set_requirement(_repair_requirement, "✔ Intégrité au maximum", true)
	else:
		_set_requirement(_repair_requirement, "Intégrité %d / %d    ·    %s %d fragments" % [
				roundi(GameState.integrity), roundi(GameState.integrity_max), "✔" if affordable else "✖", repair_cost], affordable)

	# Amélioration (une seule dans la démo).
	_upgrade_card.visible = upgrade != null
	_upgrade_id = upgrade.id if upgrade else &""
	if upgrade:
		var owned := GameState.has_upgrade(upgrade.id)
		var can_pay := GameState.fragments >= upgrade.cost_fragments
		_upgrade_name.text = upgrade.title
		_upgrade_description.text = upgrade.description + "  (+%d intégrité max.)" % roundi(upgrade.max_integrity_bonus)
		_upgrade_button.disabled = owned or not can_pay or not powered or not GameState.repaired
		if owned:
			_set_requirement(_upgrade_requirement, "✔ Installé", true)
		elif not GameState.repaired:
			_set_requirement(_upgrade_requirement, "✖ Réparation nécessaire d'abord", false)
		else:
			_set_requirement(_upgrade_requirement, "%s %d fragments" % ["✔" if can_pay else "✖", upgrade.cost_fragments], can_pay)

	var plans := 1 + (1 if upgrade else 0)
	_plans.text = "Plans disponibles : %d" % plans
	visible = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_first_enabled_button().grab_focus()
	Sfx.play(&"blip", -8.0)


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


## Bouton actif proposé par défaut (E le valide) : celui de la première carte disponible.
func _first_enabled_button() -> Button:
	for button in [_repair_button, _print_button, _upgrade_button]:
		if not button.disabled and button.is_visible_in_tree():
			return button
	return _close_button


func _choose(sig: Signal, argument: Variant = null) -> void:
	visible = false
	GameState.modal_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if argument == null:
		sig.emit()
	else:
		sig.emit(argument)


func _set_requirement(label: Label, text: String, ok: bool) -> void:
	label.text = text
	label.modulate = Color.WHITE if ok else KO_COLOR


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused == null or focused.disabled:
			focused = _first_enabled_button()
		focused.pressed.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
