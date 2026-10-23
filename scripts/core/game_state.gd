extends Node
## Progression de la démo (autoload « GameState »).
##
## Sauvegarde légère : installation des jambes et découvertes.
## « Nouvelle partie » et « Recommencer la démo » effacent cette sauvegarde.

signal progress_changed
signal modal_changed(open: bool)
signal discovery_added(id: StringName)

const SAVE_PATH := "user://nino_demo.cfg"

## Étapes de progression, dans l'ordre normal (l'ordre réel peut varier :
## la multiprise peut être rallumée avant d'avoir examiné l'imprimante).
var woke_up := false
var tutorial_done := false
var printer_seen := false
var power_on := false
var printer_understood := false
var printing := false
## Avancement de l'impression (0..1), affiché dans l'objectif.
var print_progress := 0.0
var legs_printed := false
var legs_installed := false
var legs_deployed_once := false
var reached_window := false
var handle_identified := false
var door_opened := false
var demo_completed := false

## Découvertes faites (identifiants), dans l'ordre.
var discoveries: Array[StringName] = []

## Vrai quand une interface modale (imprimante, pause, fin) capte la souris.
var modal_open := false:
	set(value):
		if modal_open == value:
			return
		modal_open = value
		modal_changed.emit(value)

## Quand vrai, le prochain chargement du niveau saute l'écran titre.
var skip_title_once := false


func has_save() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and bool(config.get_value("progress", "legs_installed", false))


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "legs_installed", legs_installed)
	config.set_value("progress", "discoveries", discoveries.map(func(id: StringName) -> String: return String(id)))
	config.save(SAVE_PATH)


func load_save() -> void:
	reset_progress()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if bool(config.get_value("progress", "legs_installed", false)):
		woke_up = true
		tutorial_done = true
		printer_seen = true
		power_on = true
		printer_understood = true
		legs_printed = true
		legs_installed = true
	for id in config.get_value("progress", "discoveries", []):
		discoveries.append(StringName(id))
	progress_changed.emit()


func reset_progress() -> void:
	woke_up = false
	tutorial_done = false
	printer_seen = false
	power_on = false
	printer_understood = false
	printing = false
	print_progress = 0.0
	legs_printed = false
	legs_installed = false
	legs_deployed_once = false
	reached_window = false
	handle_identified = false
	door_opened = false
	demo_completed = false
	discoveries.clear()
	modal_open = false


func erase_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Modifie un indicateur de progression et prévient les observateurs.
func set_flag(flag: StringName, value: bool = true) -> void:
	if get(flag) == value:
		return
	set(flag, value)
	if flag == &"legs_installed":
		save()
	progress_changed.emit()


func set_print_progress(value: float) -> void:
	print_progress = value
	progress_changed.emit()


func has_discovery(id: StringName) -> bool:
	return discoveries.has(id)


## Enregistre une découverte ; renvoie false si elle était déjà connue.
func add_discovery(id: StringName) -> bool:
	if discoveries.has(id):
		return false
	discoveries.append(id)
	if legs_installed:
		save()
	discovery_added.emit(id)
	progress_changed.emit()
	return true


## Texte d'objectif courant, déduit de la progression.
## L'objectif dit ce que le joueur cherche à accomplir ; les pensées de NINO
## disent ce qu'il observe ou comprend (pas de répétition entre les deux).
func get_objective() -> String:
	if not woke_up or demo_completed:
		return ""
	if not tutorial_done:
		return "Prendre ses repères"
	if legs_installed:
		if not legs_deployed_once:
			return "Déployer les jambes"
		if handle_identified:
			return "Atteindre la poignée de la porte"
		if reached_window:
			return "Observer la porte"
		return "Atteindre le rebord de la fenêtre"
	if legs_printed:
		return "Rejoindre la plateforme d'impression"
	if printing:
		return "Impression en cours… %d %%" % int(print_progress * 100.0)
	if power_on:
		return "Retourner à l'imprimante" if printer_seen else "Examiner l'imprimante 3D"
	if printer_seen:
		return "Rétablir l'alimentation de l'imprimante"
	return "Explorer l'établi"


## Recharge le niveau en effaçant la progression.
func restart_demo(skip_title: bool = true) -> void:
	erase_save()
	reset_progress()
	skip_title_once = skip_title
	get_tree().paused = false
	get_tree().reload_current_scene()
