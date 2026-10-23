extends Node
## Progression de la démo (autoload « GameState »).
##
## Seul l'essentiel est sauvegardé : l'installation des jambes.
## « Recommencer la démo » efface cette sauvegarde.

signal progress_changed
signal modal_changed(open: bool)

const SAVE_PATH := "user://nino_demo.cfg"

## Étapes de progression, dans l'ordre normal (mais l'ordre réel peut varier :
## la multiprise peut être rallumée avant d'avoir examiné l'imprimante).
var woke_up := false
var printer_seen := false
var power_on := false
var printing := false
var legs_printed := false
var legs_installed := false
var legs_deployed_once := false
var demo_completed := false

## Vrai quand une interface modale (imprimante, pause, fin) capte la souris.
var modal_open := false:
	set(value):
		if modal_open == value:
			return
		modal_open = value
		modal_changed.emit(value)

## Quand vrai, le prochain chargement du niveau saute l'écran titre.
var skip_title_once := false
## Quand vrai, le niveau démarre à partir de la sauvegarde (jambes installées).
var resume_from_save := false


func has_save() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and bool(config.get_value("progress", "legs_installed", false))


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "legs_installed", legs_installed)
	config.save(SAVE_PATH)


func load_save() -> void:
	reset_progress()
	if has_save():
		woke_up = true
		printer_seen = true
		power_on = true
		legs_printed = true
		legs_installed = true
	progress_changed.emit()


func reset_progress() -> void:
	woke_up = false
	printer_seen = false
	power_on = false
	printing = false
	legs_printed = false
	legs_installed = false
	legs_deployed_once = false
	demo_completed = false
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


## Texte d'objectif courant, déduit de la progression.
func get_objective() -> String:
	if not woke_up or demo_completed:
		return ""
	if legs_installed:
		if not legs_deployed_once:
			return "Déployer les jambes"
		return "Atteindre le rebord de la fenêtre"
	if legs_printed:
		return "Récupérer les jambes imprimées"
	if printing:
		return "Impression en cours…"
	if power_on:
		return "Utiliser l'imprimante 3D" if printer_seen else "Examiner l'imprimante 3D"
	if printer_seen:
		return "Rétablir l'alimentation de l'imprimante"
	return "Explorer l'établi"


## Recharge le niveau en effaçant la progression.
func restart_demo(skip_title: bool = true) -> void:
	erase_save()
	reset_progress()
	resume_from_save = false
	skip_title_once = skip_title
	get_tree().paused = false
	get_tree().reload_current_scene()
