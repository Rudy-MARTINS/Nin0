extends Node
## Progression de la démo (autoload « GameState »).
##
## Sauvegarde légère (à partir de l'installation des jambes) : progression, découvertes,
## intégrité, fragments de filament, souvenirs, améliorations.
## « Nouvelle partie » et « Recommencer la démo » effacent cette sauvegarde.
## Les sauvegardes des versions précédentes restent lisibles (valeurs par défaut).

signal progress_changed
signal modal_changed(open: bool)
signal discovery_added(id: StringName)
## Intégrité, bouclier ou fragments modifiés.
signal stats_changed
signal memory_added(id: StringName)
signal upgrade_added(id: StringName)

## Sauvegarde du joueur. Les tests automatiques utilisent TEST_SAVE_PATH (voir
## `save_path`) pour ne jamais toucher à la sauvegarde personnelle.
const SAVE_PATH := "user://nino_demo.cfg"
const TEST_SAVE_PATH := "user://nino_test.cfg"
## 1 = lot 1-2 (jambes + découvertes) ; 3 = lot 3.
const SAVE_VERSION := 3
const BASE_INTEGRITY := 100.0
const BASE_SHIELD := 20.0
## Archives fragmentées (souvenirs) : paramètres communs.
const ARCHIVE: MemoryArchive = preload("res://assets/memories/archive.tres")

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
## Chute en ouvrant la porte : Nin0 est endommagé et doit être réparé.
var injured := false
var repaired := false
var demo_completed := false

## Découvertes faites (identifiants), dans l'ordre.
var discoveries: Array[StringName] = []

## Intégrité (santé) et bouclier (absorbe une partie des dégâts, se recharge).
var integrity := BASE_INTEGRITY
var integrity_max := BASE_INTEGRITY
var shield := BASE_SHIELD
var shield_max := BASE_SHIELD
## Vrai après le premier dommage : la jauge d'intégrité devient visible.
var integrity_known := false
## Fragments de filament possédés, et identifiants des fragments déjà ramassés.
var fragments := 0
var collected_pickups: Array[StringName] = []
var repairs_done := 0
## Souvenirs retrouvés (identifiants uniques, sans doublon).
var memories: Array[StringName] = []
## Améliorations fabriquées (identifiants).
var upgrades: Array[StringName] = []
## Emplacements de modules secondaires (donnée préparée ; aucun module dans la démo).
var module_slots := 2

## Vrai quand une interface modale (imprimante, pause, fin) capte la souris.
var modal_open := false:
	set(value):
		if modal_open == value:
			return
		modal_open = value
		modal_changed.emit(value)

## Fichier de sauvegarde utilisé (SAVE_PATH en jeu, TEST_SAVE_PATH pendant les tests).
var save_path := SAVE_PATH
## Mode développement (exploration de l'appartement) : aucune sauvegarde n'est
## écrite ni effacée, la progression du joueur reste intacte.
var dev_mode := false

## Quand vrai, le prochain chargement du niveau saute l'écran titre.
var skip_title_once := false


func has_save() -> bool:
	var config := ConfigFile.new()
	return config.load(save_path) == OK and bool(config.get_value("progress", "legs_installed", false))


func save() -> void:
	if dev_mode:
		return
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("progress", "legs_installed", legs_installed)
	config.set_value("progress", "discoveries", _to_strings(discoveries))
	for flag in SAVED_FLAGS:
		config.set_value("progress", flag, get(flag))
	config.set_value("nino", "integrity", integrity)
	config.set_value("nino", "integrity_max", integrity_max)
	config.set_value("nino", "shield", shield)
	config.set_value("nino", "integrity_known", integrity_known)
	config.set_value("nino", "fragments", fragments)
	config.set_value("nino", "repairs_done", repairs_done)
	config.set_value("collections", "pickups", _to_strings(collected_pickups))
	config.set_value("collections", "memories", _to_strings(memories))
	config.set_value("collections", "upgrades", _to_strings(upgrades))
	config.save(save_path)


## Indicateurs sauvegardés en plus des jambes (lot 3).
const SAVED_FLAGS := [&"legs_deployed_once", &"reached_window", &"handle_identified", &"door_opened", &"injured", &"repaired"]


func load_save() -> void:
	reset_progress()
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
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
		_append_unique(discoveries, StringName(id))
	# Lot 3 (absents des anciennes sauvegardes : valeurs par défaut).
	for flag in SAVED_FLAGS:
		set(flag, bool(config.get_value("progress", flag, false)))
	for id in config.get_value("collections", "pickups", []):
		_append_unique(collected_pickups, StringName(id))
	# Un souvenir ne s'obtient que par l'observation : rien n'est déduit des découvertes.
	for id in config.get_value("collections", "memories", []):
		_append_unique(memories, StringName(id))
	for id in config.get_value("collections", "upgrades", []):
		_append_unique(upgrades, StringName(id))
	fragments = maxi(int(config.get_value("nino", "fragments", 0)), 0)
	repairs_done = maxi(int(config.get_value("nino", "repairs_done", 0)), 0)
	integrity_known = bool(config.get_value("nino", "integrity_known", false))
	_recompute_stats()
	integrity = clampf(float(config.get_value("nino", "integrity", integrity_max)), 1.0, integrity_max)
	shield = clampf(float(config.get_value("nino", "shield", shield_max)), 0.0, shield_max)
	progress_changed.emit()
	stats_changed.emit()


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
	injured = false
	repaired = false
	demo_completed = false
	discoveries.clear()
	collected_pickups.clear()
	memories.clear()
	upgrades.clear()
	fragments = 0
	repairs_done = 0
	integrity_known = false
	_recompute_stats()
	integrity = integrity_max
	shield = shield_max
	modal_open = false
	stats_changed.emit()


func erase_save() -> void:
	if dev_mode:
		return
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


## Modifie un indicateur de progression et prévient les observateurs.
func set_flag(flag: StringName, value: bool = true) -> void:
	if get(flag) == value:
		return
	set(flag, value)
	if flag == &"legs_installed" or (legs_installed and SAVED_FLAGS.has(flag)):
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


# --- Intégrité, bouclier, fragments -------------------------------------------------

## Applique des dégâts : le bouclier absorbe d'abord (sauf `bypass_shield`).
## Renvoie la perte d'intégrité réelle.
func apply_damage(amount: float, bypass_shield := false) -> float:
	if amount <= 0.0:
		return 0.0
	integrity_known = true
	var remaining := amount
	if not bypass_shield:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	var before := integrity
	integrity = maxf(integrity - remaining, 0.0)
	stats_changed.emit()
	return before - integrity


func recharge_shield(amount: float) -> void:
	if shield >= shield_max:
		return
	shield = minf(shield + amount, shield_max)
	stats_changed.emit()


func restore_integrity(value: float) -> void:
	integrity = clampf(value, 0.0, integrity_max)
	stats_changed.emit()


## Ramasse un fragment de filament (identifiant unique) ; false s'il l'était déjà.
func collect_fragment(pickup_id: StringName, amount := 1) -> bool:
	if collected_pickups.has(pickup_id):
		return false
	collected_pickups.append(pickup_id)
	fragments += amount
	_save_if_started()
	stats_changed.emit()
	return true


func spend_fragments(amount: int) -> bool:
	if fragments < amount:
		return false
	fragments -= amount
	stats_changed.emit()
	return true


## Réparation à l'imprimante : intégrité et bouclier au maximum.
func complete_repair() -> void:
	repairs_done += 1
	integrity = integrity_max
	shield = shield_max
	repaired = true
	_save_if_started()
	stats_changed.emit()
	progress_changed.emit()


# --- Améliorations -------------------------------------------------------------------

func has_upgrade(id: StringName) -> bool:
	return upgrades.has(id)


## Ajoute une amélioration (et retire celle qu'elle remplace) ; applique ses effets.
func add_upgrade(id: StringName) -> bool:
	if upgrades.has(id):
		return false
	var data := UpgradeCatalog.find(id)
	if data and data.replaces != &"":
		upgrades.erase(data.replaces)
	upgrades.append(id)
	var missing := integrity_max - integrity
	_recompute_stats()
	integrity = integrity_max - missing
	_save_if_started()
	upgrade_added.emit(id)
	stats_changed.emit()
	return true


func _recompute_stats() -> void:
	integrity_max = BASE_INTEGRITY
	shield_max = BASE_SHIELD
	for id in upgrades:
		var data := UpgradeCatalog.find(id)
		if data:
			integrity_max += data.max_integrity_bonus
	integrity = minf(integrity, integrity_max)
	shield = minf(shield, shield_max)


# --- Souvenirs (archives fragmentées) ---------------------------------------------------

func has_memory(id: StringName) -> bool:
	return memories.has(id)


## Enregistre un souvenir ; false s'il était déjà connu (aucun doublon).
func add_memory(id: StringName) -> bool:
	if id == &"" or memories.has(id):
		return false
	memories.append(id)
	_save_if_started()
	memory_added.emit(id)
	progress_changed.emit()
	return true


func memory_count() -> int:
	return memories.size()


## Dégradation actuelle des souvenirs (diminue avec le nombre retrouvé).
func memory_corruption() -> float:
	return ARCHIVE.corruption(memories.size())


## Donnée préparée pour les fins du jeu complet (aucune fin n'est développée) :
## &"complete" si les sept fragments sont retrouvés, sinon &"incomplete".
func archive_state() -> StringName:
	return &"complete" if memories.size() >= ARCHIVE.total else &"incomplete"


func _save_if_started() -> void:
	if legs_installed:
		save()


func _append_unique(list: Array[StringName], id: StringName) -> void:
	if not list.has(id):
		list.append(id)


func _to_strings(list: Array[StringName]) -> Array:
	return list.map(func(id: StringName) -> String: return String(id))


## Texte d'objectif courant, déduit de la progression.
## L'objectif dit ce que le joueur cherche à accomplir ; les pensées de Nin0
## disent ce qu'il observe ou comprend (pas de répétition entre les deux).
func get_objective() -> String:
	if dev_mode or not woke_up or demo_completed:
		return ""
	if not tutorial_done:
		return "Prendre ses repères"
	if repaired:
		return "Franchir la porte"
	if injured:
		return "Se faire réparer à l'imprimante"
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
