extends Node
## Trophées internes (autoload « Achievements », lot 7), sans plateforme externe.
## Identifiants stables (ne jamais les renommer : ils sont sauvegardés). La progression ne
## dépend jamais d'un trophée : ils ne font que constater ce que le joueur a accompli.
## Sauvegarde à part (user://nino_trophies.cfg) : elle survit à « Nouvelle partie ».
## Les conditions de progression sont réévaluées au chargement d'une partie (les anciennes
## sauvegardes débloquent donc les trophées déjà mérités, sans annonce).

signal unlocked(id: StringName)

const SAVE_PATH := "user://nino_trophies.cfg"
const TEST_SAVE_PATH := "user://nino_trophies_test.cfg"

## Catégories d'affichage.
const PROGRESSION := &"progression"
const DISCOVERY := &"discovery"
const COOPERATION := &"cooperation"
const SECRET := &"secret"

## id → [titre, description, catégorie]. Les trophées secrets cachent leur description.
const LIST := {
	&"legs": ["Premiers pas", "Installer les jambes articulées.", PROGRESSION],
	&"cannon": ["Ressort et bille", "Installer le canon à projectiles.", PROGRESSION],
	&"queen": ["Bonde ouverte", "Vaincre la reine des fourmis.", PROGRESSION],
	&"kitchen": ["Au-delà du loquet", "Entrer dans la cuisine.", PROGRESSION],
	&"charged_jump": ["Comme une puce", "Apprendre le saut chargé en observant la puce.", PROGRESSION],
	&"great_wasp": ["Fenêtre libérée", "Vaincre la grosse guêpe.", PROGRESSION],
	&"sting_bead": ["Pointe acérée", "Fabriquer les billes pointues.", PROGRESSION],
	&"salon": ["Entrebâillement", "Entrer dans le salon.", PROGRESSION],
	&"all_species": ["Naturaliste", "Analyser toutes les espèces connues.", DISCOVERY],
	&"seven_memories": ["Mémoire retrouvée", "Retrouver les sept souvenirs.", DISCOVERY],
	&"all_upgrades": ["Atelier complet", "Fabriquer toutes les améliorations.", DISCOVERY],
	&"seesaw": ["À deux, c'est mieux", "Résoudre la première énigme avec Nathan.", COOPERATION],
	&"bonk": ["Bonk !", "Recevoir quelque chose sur la tête.", SECRET],
	&"rooftop": ["Tout là-haut", "Atteindre le dessus des placards de la cuisine.", SECRET],
	&"pest_control": ["Ménage de printemps", "Mettre dix créatures KO dans la cuisine.", SECRET],
	&"bounce": ["Ça rebondit", "Tirer une bille ronde sur l'élastique de la porte du salon.", SECRET],
}

var _unlocked := {}
var _counters := {}


func _ready() -> void:
	load_file()
	GameState.save_loaded.connect(func() -> void:
		load_file()
		evaluate(true))
	GameState.progress_changed.connect(evaluate)
	GameState.upgrade_added.connect(func(_id: StringName) -> void: evaluate())
	GameState.species_added.connect(func(_id: StringName) -> void: evaluate())
	GameState.memory_added.connect(func(_id: StringName) -> void: evaluate())


func save_path() -> String:
	return TEST_SAVE_PATH if GameState.save_path == GameState.TEST_SAVE_PATH else SAVE_PATH


func is_unlocked(id: StringName) -> bool:
	return _unlocked.has(id)


func unlocked_count() -> int:
	return _unlocked.size()


func info(id: StringName) -> Array:
	return LIST.get(id, ["?", "", SECRET])


## Débloque un trophée (une seule fois). `quiet` : sans annonce (rattrapage au chargement).
func unlock(id: StringName, quiet := false) -> bool:
	if not LIST.has(id) or _unlocked.has(id) or GameState.dev_mode:
		return false
	_unlocked[id] = Time.get_unix_time_from_system()
	save_file()
	if not quiet:
		unlocked.emit(id)
	return true


## Compteur pour les trophées cumulatifs (ex. mises KO) : renvoie la nouvelle valeur.
func add_count(key: StringName, amount := 1) -> int:
	_counters[key] = int(_counters.get(key, 0)) + amount
	save_file()
	return _counters[key]


## Réévalue les trophées de progression et de découverte d'après la partie en cours.
func evaluate(quiet := false) -> void:
	if GameState.dev_mode:
		return
	var checks := {
		&"legs": GameState.legs_installed,
		&"cannon": GameState.has_cannon(),
		&"queen": GameState.queen_defeated,
		&"kitchen": GameState.chapter2_completed,
		&"charged_jump": GameState.charged_jump_learned,
		&"great_wasp": GameState.wasp_defeated,
		&"sting_bead": GameState.has_upgrade(&"sting_bead"),
		&"salon": GameState.salon_entered,
		&"all_species": SpeciesCatalog.all().all(func(d: SpeciesData) -> bool: return GameState.has_species(d.id)),
		&"seven_memories": GameState.memory_count() >= GameState.ARCHIVE.total,
		&"all_upgrades": UpgradeCatalog.all().all(func(u: UpgradeData) -> bool:
			return GameState.has_upgrade(u.id) or (u.id == &"legs" and GameState.legs_installed) or not u.fabricable),
		&"seesaw": GameState.seesaw_done,
	}
	for id in checks:
		if checks[id]:
			unlock(id, quiet)


func load_file() -> void:
	_unlocked.clear()
	_counters.clear()
	var config := ConfigFile.new()
	if config.load(save_path()) != OK:
		return
	var stored: Dictionary = config.get_value("trophies", "unlocked", {})
	for key in stored:
		if LIST.has(StringName(key)):
			_unlocked[StringName(key)] = stored[key]
	var counters: Dictionary = config.get_value("trophies", "counters", {})
	for key in counters:
		_counters[StringName(key)] = int(counters[key])


func save_file() -> void:
	var config := ConfigFile.new()
	var stored := {}
	for key in _unlocked:
		stored[String(key)] = _unlocked[key]
	var counters := {}
	for key in _counters:
		counters[String(key)] = _counters[key]
	config.set_value("trophies", "unlocked", stored)
	config.set_value("trophies", "counters", counters)
	config.save(save_path())


## Tests : efface la sauvegarde des trophées de test (jamais celle du joueur).
func reset_test_file() -> void:
	if save_path() != TEST_SAVE_PATH:
		return
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	_unlocked.clear()
	_counters.clear()
