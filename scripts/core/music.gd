extends Node
## Musique (autoload « Music »), distincte des effets sonores (Sfx) : bus « Music ».
##
## - `play_once` : morceau joué une seule fois par lancement du jeu (introduction).
## - `play` / `stop` : lecture avec fondu ; un seul morceau à la fois.
## - `ZONE_TRACKS` : musiques par zone, à compléter quand les compositions existeront.
## Un morceau absent du projet est ignoré sans erreur bloquante.

## Identifiant → fichier et bouclage.
## « intro » : prototype réservé aux essais internes (droits commerciaux à régulariser).
const TRACKS := {
	&"intro": {"path": "res://assets/music/intro_prototype.ogg", "loop": false},
}
## Zone (identifiant de l'appartement) → morceau. Vide pour l'instant.
const ZONE_TRACKS := {}

var current: StringName = &""

var _player: AudioStreamPlayer
var _played_once: Array[StringName] = []
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	add_child(_player)
	_player.finished.connect(func() -> void: current = &"")


func has_track(id: StringName) -> bool:
	return TRACKS.has(id) and ResourceLoader.exists(TRACKS[id].path)


## Joue un morceau une seule fois par lancement (renvoie false s'il a déjà été joué).
func play_once(id: StringName, volume_db := -4.0) -> bool:
	if _played_once.has(id):
		return false
	_played_once.append(id)
	return play(id, volume_db)


func play(id: StringName, volume_db := -4.0, fade_in := 0.0) -> bool:
	if not has_track(id):
		push_warning("Musique absente : %s" % id)
		return false
	var stream := load(TRACKS[id].path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = TRACKS[id].loop
	if _fade:
		_fade.kill()
	_player.stream = stream
	_player.volume_db = volume_db if fade_in <= 0.0 else -40.0
	_player.play()
	current = id
	if fade_in > 0.0:
		_fade = create_tween()
		_fade.tween_property(_player, "volume_db", volume_db, fade_in)
	return true


func stop(fade_out := 1.0) -> void:
	if not _player.playing:
		return
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", -40.0, fade_out)
	_fade.tween_callback(func() -> void:
		_player.stop()
		current = &"")


## Musique d'une zone (aucune pour l'instant : la zone garde le silence ou l'ambiance).
func set_zone(zone_id: StringName) -> void:
	var id: StringName = ZONE_TRACKS.get(zone_id, &"")
	if id != &"" and id != current:
		play(id, -6.0, 2.0)


func is_playing() -> bool:
	return _player.playing


func get_position() -> float:
	return _player.get_playback_position()
