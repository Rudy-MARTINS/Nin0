extends Node
## Musique (autoload « Music »), distincte des effets sonores (Sfx) : bus « Music ».
##
## Un seul morceau audible à la fois : deux lecteurs servent au fondu enchaîné (court)
## lors d'un changement. Redemander le morceau déjà en cours ne fait rien (pas de
## redémarrage entre le placard et le sas, ni lors d'une interaction).
## - `play_once` : morceau joué une seule fois par lancement (introduction).
## - `play` : change de morceau (fondu enchaîné) ; `stop` : fondu vers le silence.
## - `duck` : baisse passagère du volume (jingles de découverte).
## - `desired` : dernier morceau demandé, même si son fichier n'est pas encore dans le
##   projet (il est alors remplacé par du silence, sans erreur bloquante).
## Les morceaux sont des prototypes internes (droits commerciaux non confirmés).

## Identifiant → fichier et bouclage. Les fichiers absents sont signalés une fois.
const TRACKS := {
	&"intro": {"path": "res://assets/music/intro_prototype.ogg", "loop": false},
	# « Petit Refuge » : placard-hub et sas.
	&"hub": {"path": "res://assets/music/petit_refuge.ogg", "loop": true},
	# « ant labyrinth - Nin0 », V3 (raccord fin/début corrigé) : salle de bain.
	&"labyrinth": {"path": "res://assets/music/ant_labyrinth.ogg", "loop": true},
	# « boss fight - Nin0 », V2 (≈ 2 min 58) : reine des fourmis.
	&"boss": {"path": "res://assets/music/boss_fight.ogg", "loop": true},
	# « kitchen - Nin0 » : cuisine (lot 6).
	&"kitchen": {"path": "res://assets/music/kitchen.ogg", "loop": true},
	# « living room - Nin0 » : salon, à ne pas utiliser avant son ouverture.
	&"living_room": {"path": "res://assets/music/living_room.ogg", "loop": true},
}
const DEFAULT_VOLUME := -6.0
const CROSSFADE := 0.8

## Morceau réellement audible (vide = silence).
var current: StringName = &""
## Dernier morceau demandé (peut être absent du projet).
var desired: StringName = &""
## Historique des changements (diagnostic et tests).
var changes: Array[StringName] = []

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _played_once: Array[StringName] = []
var _warned: Array[StringName] = []
var _fades: Array[Tween] = [null, null]
var _duck_tween: Tween
var _volume := DEFAULT_VOLUME


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		add_child(player)
		player.finished.connect(_on_finished.bind(i))
		_players.append(player)


func has_track(id: StringName) -> bool:
	return TRACKS.has(id) and ResourceLoader.exists(TRACKS[id].path)


## Joue un morceau une seule fois par lancement (renvoie false s'il a déjà été joué).
func play_once(id: StringName, volume_db := -4.0) -> bool:
	if _played_once.has(id):
		return false
	_played_once.append(id)
	return play(id, volume_db, 0.0)


## Change de morceau. Sans effet si `id` est déjà demandé (aucun redémarrage).
func play(id: StringName, volume_db := DEFAULT_VOLUME, fade := CROSSFADE) -> bool:
	if id == desired and (current == id or not has_track(id)):
		return current == id
	desired = id
	changes.append(id)
	if not has_track(id):
		if not _warned.has(id):
			_warned.append(id)
			push_warning("Musique absente (silence en attendant le fichier) : %s" % id)
		_fade_out(_active, fade)
		current = &""
		return false
	var stream := load(TRACKS[id].path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = TRACKS[id].loop
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = TRACKS[id].loop
	# Fondu enchaîné : l'ancien lecteur s'éteint, l'autre démarre.
	_fade_out(_active, fade)
	_active = 1 - _active
	var player := _players[_active]
	if _fades[_active]:
		_fades[_active].kill()
	_volume = volume_db
	player.stream = stream
	player.volume_db = volume_db if fade <= 0.0 else -40.0
	player.play()
	current = id
	if fade > 0.0:
		_fades[_active] = create_tween()
		_fades[_active].tween_property(player, "volume_db", volume_db, fade)
	return true


## Fondu vers le silence (le morceau demandé devient vide).
func stop(fade_out := 1.0) -> void:
	desired = &""
	current = &""
	_fade_out(_active, fade_out)


## Baisse passagère du volume (jingle), puis retour progressif.
func duck(amount_db := -10.0, duration := 1.6) -> void:
	if _duck_tween:
		_duck_tween.kill()
	var bus := AudioServer.get_bus_index(&"Music")
	if bus < 0:
		return
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), AudioServer.get_bus_volume_db(bus), amount_db, 0.15)
	_duck_tween.tween_interval(duration)
	_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), amount_db, 0.0, 0.8)


## Nombre de lecteurs réellement audibles (contrôle « une seule musique »).
func audible_count() -> int:
	var count := 0
	for player in _players:
		if player.playing and player.volume_db > -30.0:
			count += 1
	return count


func is_playing() -> bool:
	return _players[_active].playing


func get_position() -> float:
	return _players[_active].get_playback_position()


func _fade_out(index: int, duration: float) -> void:
	var player := _players[index]
	if not player.playing:
		return
	if _fades[index]:
		_fades[index].kill()
	if duration <= 0.0:
		player.stop()
		return
	_fades[index] = create_tween()
	_fades[index].tween_property(player, "volume_db", -40.0, duration)
	_fades[index].tween_callback(player.stop)


func _on_finished(index: int) -> void:
	# Fin d'un morceau non bouclé (introduction) : silence jusqu'à la prochaine demande.
	if index == _active and current != &"" and not TRACKS[current].loop:
		current = &""
