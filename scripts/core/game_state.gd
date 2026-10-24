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
signal species_added(id: StringName)
signal modules_changed
## Première découverte d'un type de ressource (explication affichée une seule fois).
signal resource_discovered(kind: StringName)
## Partie chargée (avant progress_changed) : rattrapage silencieux des trophées.
signal save_loaded
## Dangers suspendus (séquence non interactive) ou rétablis.
signal hazards_changed(suspended: bool)

## Sauvegarde du joueur. Les tests automatiques utilisent TEST_SAVE_PATH (voir
## `save_path`) pour ne jamais toucher à la sauvegarde personnelle.
const SAVE_PATH := "user://nino_demo.cfg"
const TEST_SAVE_PATH := "user://nino_test.cfg"
## 1 = lot 1-2 (jambes + découvertes) ; 3 = lot 3 ; 5 = lot 5 (sas, salle de bain).
const SAVE_VERSION := 5
const BASE_INTEGRITY := 100.0
const BASE_SHIELD := 20.0
## Archives fragmentées (souvenirs) : paramètres communs.
const ARCHIVE: MemoryArchive = preload("res://assets/memories/archive.tres")
## Plastique à munitions transportable au maximum.
const PLASTIC_MAX := 24
## Ressources ordinaires (réapparaissent) : identifiants des types.
const RESOURCE_FILAMENT := &"filament"
const RESOURCE_PLASTIC := &"plastic"

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
## Emplacements de modules secondaires (2 au départ, 3 plus tard).
var module_slots := 2
## Modules secondaires équipés (identifiants d'améliorations MODULE possédées).
var equipped_modules: Array[StringName] = []

# --- Lot 5 : chapitre du sas et de la salle de bain -------------------------------------
var sas_entered := false
var worker_met := false
var bathroom_entered := false
var boss_started := false
var queen_defeated := false
var kitchen_unlocked := false
var chapter2_completed := false
# --- Lot 7 : guêpes, billes pointues, salon ------------------------------------------------
var wasp_started := false
## Phase 2 atteinte : en cas d'échec, le combat reprend en phase 2.
var wasp_phase2 := false
var wasp_defeated := false
var salon_opened := false
var salon_entered := false
## Nathan : première énigme de coopération (bascule), séquence de protection.
var seesaw_done := false
var protection_done := false
## Munition choisie pour le canon (identifiant AmmoData).
var ammo_type: StringName = &"bead"
## Espèces analysées (encyclopédie biologique), dans l'ordre.
var species: Array[StringName] = []
## Plastique à munitions (une bille = une unité).
var ammo_plastic := 0
## Temps de jeu cumulé (secondes) : sert à la réapparition des ressources ordinaires.
var playtime := 0.0
## Ressource ordinaire ramassée → temps de jeu au ramassage.
var pickup_times := {}
## Explications déjà présentées (première découverte de chaque ressource, etc.).
var seen_notices: Array[StringName] = []
## Lectures des souvenirs (historique conservé, jamais effacé) :
## identifiant → liste de { "found": n, "lines": PackedStringArray, "comment": String }.
var memory_reads := {}
## Dernier point de reprise du chapitre (« Continuer »).
var resume_point: StringName = &""
## Vrai pendant qu'un ennemi poursuit Nin0 (changement de modules interdit).
var in_combat := false

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
	config.set_value("collections", "equipped_modules", _to_strings(equipped_modules))
	config.set_value("collections", "species", _to_strings(species))
	config.set_value("collections", "seen_notices", _to_strings(seen_notices))
	config.set_value("collections", "pickup_times", _string_keys(pickup_times))
	config.set_value("collections", "memory_reads", _string_keys(memory_reads))
	config.set_value("nino", "ammo_plastic", ammo_plastic)
	config.set_value("nino", "ammo_type", String(ammo_type))
	config.set_value("progress", "playtime", playtime)
	config.set_value("progress", "resume_point", String(resume_point))
	config.save(save_path)


## Indicateurs sauvegardés en plus des jambes (lot 3).
const SAVED_FLAGS := [&"legs_deployed_once", &"reached_window", &"handle_identified", &"door_opened", &"injured", &"repaired",
		&"sas_entered", &"worker_met", &"bathroom_entered", &"boss_started", &"queen_defeated", &"kitchen_unlocked", &"chapter2_completed",
		&"wasp_started", &"wasp_phase2", &"wasp_defeated", &"salon_opened", &"salon_entered",
		&"seesaw_done", &"protection_done"]


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
	# Lot 5 (absents des anciennes sauvegardes : valeurs par défaut).
	for id in config.get_value("collections", "equipped_modules", []):
		if upgrades.has(StringName(id)):
			_append_unique(equipped_modules, StringName(id))
	for id in config.get_value("collections", "species", []):
		_append_unique(species, StringName(id))
	for id in config.get_value("collections", "seen_notices", []):
		_append_unique(seen_notices, StringName(id))
	var times: Dictionary = config.get_value("collections", "pickup_times", {})
	for key in times:
		pickup_times[StringName(key)] = float(times[key])
	var reads: Dictionary = config.get_value("collections", "memory_reads", {})
	for key in reads:
		memory_reads[StringName(key)] = reads[key]
	ammo_plastic = clampi(int(config.get_value("nino", "ammo_plastic", 0)), 0, PLASTIC_MAX)
	ammo_type = StringName(config.get_value("nino", "ammo_type", "bead"))
	if ammo_type != &"bead" and not upgrades.has(ammo_type):
		ammo_type = &"bead"
	playtime = maxf(float(config.get_value("progress", "playtime", 0.0)), 0.0)
	resume_point = StringName(config.get_value("progress", "resume_point", ""))
	fragments = maxi(int(config.get_value("nino", "fragments", 0)), 0)
	repairs_done = maxi(int(config.get_value("nino", "repairs_done", 0)), 0)
	integrity_known = bool(config.get_value("nino", "integrity_known", false))
	_recompute_stats()
	integrity = clampf(float(config.get_value("nino", "integrity", integrity_max)), 1.0, integrity_max)
	shield = clampf(float(config.get_value("nino", "shield", shield_max)), 0.0, shield_max)
	save_loaded.emit()
	progress_changed.emit()
	stats_changed.emit()


func reset_progress() -> void:
	_hazard_locks.clear()
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
	sas_entered = false
	worker_met = false
	bathroom_entered = false
	boss_started = false
	queen_defeated = false
	kitchen_unlocked = false
	chapter2_completed = false
	wasp_started = false
	wasp_phase2 = false
	wasp_defeated = false
	salon_opened = false
	salon_entered = false
	seesaw_done = false
	protection_done = false
	ammo_type = &"bead"
	species.clear()
	equipped_modules.clear()
	seen_notices.clear()
	pickup_times.clear()
	memory_reads.clear()
	ammo_plastic = 0
	playtime = 0.0
	resume_point = &""
	in_combat = false
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


## Ramasse un fragment de filament ; false s'il n'est pas disponible.
func collect_fragment(pickup_id: StringName, amount := 1, respawn_delay := 0.0) -> bool:
	return collect_resource(pickup_id, RESOURCE_FILAMENT, amount, respawn_delay)


## Ramasse une ressource ordinaire (filament ou plastique).
## respawn_delay = 0 : jamais réapparue ; sinon disponible de nouveau après ce temps de jeu.
func collect_resource(pickup_id: StringName, kind: StringName, amount := 1, respawn_delay := 0.0) -> bool:
	if not is_pickup_available(pickup_id, respawn_delay):
		return false
	_append_unique(collected_pickups, pickup_id)
	pickup_times[pickup_id] = playtime
	if kind == RESOURCE_PLASTIC:
		ammo_plastic = mini(ammo_plastic + amount, PLASTIC_MAX)
	else:
		fragments += amount
	var notice := StringName("resource_" + String(kind))
	if not seen_notices.has(notice):
		seen_notices.append(notice)
		resource_discovered.emit(kind)
	_save_if_started()
	stats_changed.emit()
	return true


## Vrai si une ressource peut être ramassée (jamais prise, ou réapparue).
func is_pickup_available(pickup_id: StringName, respawn_delay := 0.0) -> bool:
	if not collected_pickups.has(pickup_id):
		return true
	if respawn_delay <= 0.0:
		return false
	return playtime - float(pickup_times.get(pickup_id, 0.0)) >= respawn_delay


## Plastique donné hors ramassage (premier chargement du canon, mode développement).
# --- Suspension des dangers ----------------------------------------------------------------
## Pendant une séquence où le joueur n'a pas le contrôle (souvenir, mise en scène,
## installation…), les ennemis cessent d'attaquer et de se déplacer, les projectiles et
## pièges ne blessent plus, les terrains n'enlisent plus. L'interface et les effets
## visuels continuent (pas de pause globale). Chaque séquence pose son propre verrou.
var _hazard_locks := {}


func suspend_hazards(reason: StringName) -> void:
	var was := hazards_suspended()
	_hazard_locks[reason] = true
	if not was:
		hazards_changed.emit(true)


func resume_hazards(reason: StringName) -> void:
	if not _hazard_locks.has(reason):
		return
	_hazard_locks.erase(reason)
	if not hazards_suspended():
		hazards_changed.emit(false)


func hazards_suspended() -> bool:
	return not _hazard_locks.is_empty()


func add_plastic(amount: int) -> void:
	ammo_plastic = clampi(ammo_plastic + amount, 0, PLASTIC_MAX)
	_save_if_started()
	stats_changed.emit()


func spend_plastic(amount := 1) -> bool:
	if ammo_plastic < amount:
		return false
	ammo_plastic -= amount
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


# --- Modules secondaires (emplacements équipables) ----------------------------------------

func is_equipped(id: StringName) -> bool:
	return equipped_modules.has(id)


## Équipe un module possédé s'il reste un emplacement (hors combat).
func equip_module(id: StringName) -> bool:
	if in_combat or not upgrades.has(id) or equipped_modules.has(id) or equipped_modules.size() >= module_slots:
		return false
	var data := UpgradeCatalog.find(id)
	if data == null or data.category != UpgradeData.Category.MODULE:
		return false
	equipped_modules.append(id)
	_save_if_started()
	modules_changed.emit()
	stats_changed.emit()
	return true


func unequip_module(id: StringName) -> bool:
	if in_combat or not equipped_modules.has(id):
		return false
	equipped_modules.erase(id)
	_save_if_started()
	modules_changed.emit()
	stats_changed.emit()
	return true


## Réduction des dégâts physiques apportée par les modules équipés (0..0,9).
func physical_damage_reduction() -> float:
	var total := 0.0
	for id in equipped_modules:
		var data := UpgradeCatalog.find(id)
		if data:
			total += data.physical_damage_reduction
	return clampf(total, 0.0, 0.9)


func has_cannon() -> bool:
	return upgrades.has(&"cannon")


# --- Encyclopédie biologique ----------------------------------------------------------------

func has_species(id: StringName) -> bool:
	return species.has(id)


## Enregistre une espèce analysée ; false si elle l'était déjà.
func add_species(id: StringName) -> bool:
	if id == &"" or species.has(id):
		return false
	species.append(id)
	_save_if_started()
	species_added.emit(id)
	progress_changed.emit()
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
	# Nouvelle lecture de chaque souvenir connu : la dégradation a changé, les lectures
	# précédentes restent dans l'historique.
	for known in memories:
		var memory := ARCHIVE.get_entry(known)
		if memory:
			record_memory_read(memory)
	_save_if_started()
	memory_added.emit(id)
	progress_changed.emit()
	return true


## Conserve une lecture du souvenir (texte tel qu'il est perçu maintenant + commentaire
## de Nin0). L'historique n'est jamais effacé : les premières réactions restent consultables.
func record_memory_read(memory: MemoryData) -> void:
	var lines := PackedStringArray()
	for i in memory.lines.size():
		lines.append(MemoryArchive.degrade(memory.lines[i], memory_corruption(), hash(memory.id) + i * 31 + memories.size() * 7))
	var history: Array = memory_reads.get(memory.id, [])
	if not history.is_empty() and int(history[-1].get("found", 0)) == memories.size():
		return
	history.append({"found": memories.size(), "lines": lines, "comment": memory.comment})
	memory_reads[memory.id] = history


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


func _string_keys(dict: Dictionary) -> Dictionary:
	var out := {}
	for key in dict:
		out[String(key)] = dict[key]
	return out


func _process(delta: float) -> void:
	if woke_up and not get_tree().paused and not modal_open:
		playtime += delta


func _to_strings(list: Array[StringName]) -> Array:
	return list.map(func(id: StringName) -> String: return String(id))


## Texte d'objectif courant, déduit de la progression.
## L'objectif dit ce que le joueur cherche à accomplir ; les pensées de Nin0
## disent ce qu'il observe ou comprend (pas de répétition entre les deux).
func get_objective() -> String:
	if dev_mode or not woke_up:
		return ""
	if not tutorial_done:
		return "Prendre ses repères"
	# Chapitre 2 (jeu complet) : objectifs au-delà du seuil du placard.
	if chapter2_completed:
		if salon_entered:
			if has_memory(&"memory_05"):
				return "Explorer le salon"
			if protection_done:
				return "Analyser la box internet"
			if seesaw_done:
				return "Monter sur le meuble de la télévision"
			if has_memory(&"memory_04"):
				return "Atteindre la lumière qui clignote, avec Nathan"
			return "Explorer le salon"
		if salon_opened:
			return "Entrer dans le salon"
		if has_upgrade(&"sting_bead"):
			return "Ouvrir la porte du salon"
		if wasp_defeated:
			return "Fabriquer les billes pointues à l'imprimante"
		if wasp_started:
			return "Chasser les guêpes de la fenêtre"
		if has_upgrade(&"charged_jump"):
			return "Explorer les hauteurs de la cuisine"
		if has_discovery(&"plan_charged_jump"):
			return "Fabriquer le saut chargé à l'imprimante"
		return "Explorer la cuisine"
	if kitchen_unlocked:
		return "Entrer dans la cuisine"
	if has_cannon():
		return "Ouvrir la porte de la cuisine"
	if queen_defeated:
		return "Fabriquer le canon à l'imprimante"
	if boss_started:
		return "Traverser le lavabo"
	if bathroom_entered:
		return "Atteindre le lavabo"
	if sas_entered:
		return "Explorer le sas"
	if demo_completed:
		return ""
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
