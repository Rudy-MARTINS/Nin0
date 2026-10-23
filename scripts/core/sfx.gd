extends Node
## Sons de la démo (autoload « Sfx »), entièrement synthétisés au démarrage :
## aucun fichier audio externe, donc aucune question de licence.
## Provisoires : à remplacer par un vrai sound design plus tard.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _loops := {}  # clé -> AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sounds()
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Joue un son court. volume_db : volume relatif ; pitch : hauteur.
func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Son inconnu : %s" % sound)
		return
	var player := _get_free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## Démarre (ou ajuste) un son en boucle identifié par `key`.
func set_loop(key: StringName, sound: StringName, volume_db: float, pitch := 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(key)
	if player == null:
		player = AudioStreamPlayer.new()
		add_child(player)
		_loops[key] = player
	if player.stream != _streams.get(sound):
		player.stream = _streams.get(sound)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	if not player.playing:
		player.play()


func stop_loop(key: StringName) -> void:
	var player: AudioStreamPlayer = _loops.get(key)
	if player:
		player.stop()


func stop_all_loops() -> void:
	for key in _loops:
		(_loops[key] as AudioStreamPlayer).stop()


func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]


# --- Synthèse -------------------------------------------------------------------

func _build_sounds() -> void:
	_streams[&"blip"] = _tone([[880.0, 880.0, 0.06]], 0.25)
	_streams[&"boot"] = _tone([[300.0, 900.0, 0.3], [900.0, 900.0, 0.05], [1200.0, 1200.0, 0.08]], 0.25)
	_streams[&"happy"] = _tone([[700.0, 760.0, 0.07], [1050.0, 1150.0, 0.1]], 0.22)
	_streams[&"curious"] = _tone([[520.0, 820.0, 0.14]], 0.18)
	_streams[&"surprised"] = _tone([[600.0, 1400.0, 0.12]], 0.22)
	_streams[&"hurt"] = _tone([[700.0, 260.0, 0.25]], 0.25, true)
	_streams[&"thud"] = _noise_burst(0.22, 0.6, 0.08)
	_streams[&"click"] = _click()
	_streams[&"power_on"] = _tone([[90.0, 180.0, 0.4], [880.0, 880.0, 0.06], [1320.0, 1320.0, 0.1]], 0.3)
	_streams[&"print_done"] = _tone([[660.0, 660.0, 0.12], [880.0, 880.0, 0.12], [1320.0, 1320.0, 0.25]], 0.25)
	_streams[&"servo"] = _servo(0.8)
	_streams[&"jump"] = _tone([[320.0, 640.0, 0.12]], 0.2)
	_streams[&"step"] = _noise_burst(0.04, 0.25, 0.01)
	_streams[&"print_motor"] = _print_motor()
	_streams[&"wheels"] = _wheel_hum()
	_streams[&"ambience"] = _ambience(6.0)
	# Lot 2
	_streams[&"thought"] = _tone([[900.0, 1300.0, 0.05], [1300.0, 1250.0, 0.04]], 0.12)
	_streams[&"tutorial_ok"] = _tone([[880.0, 880.0, 0.05], [1320.0, 1320.0, 0.08]], 0.12)
	_streams[&"discovery"] = _tone([[660.0, 660.0, 0.08], [990.0, 990.0, 0.08], [1320.0, 1480.0, 0.2]], 0.16)
	_streams[&"pickup"] = _tone([[500.0, 1100.0, 0.12], [1100.0, 1100.0, 0.06]], 0.18)
	_streams[&"power_up"] = _power_up()
	_streams[&"printer_wake"] = _tone([[523.0, 523.0, 0.1], [659.0, 659.0, 0.1], [784.0, 784.0, 0.18]], 0.2)
	_streams[&"spool_slide"] = _scrape()
	_streams[&"spool_drop"] = _noise_burst(0.3, 0.9, 0.005)
	_streams[&"book_fall"] = _noise_burst(0.4, 1.0, 0.004)
	_streams[&"focus_in"] = _tone([[300.0, 700.0, 0.18]], 0.1)
	_streams[&"focus_out"] = _tone([[700.0, 300.0, 0.15]], 0.08)
	_streams[&"focus_lock"] = _tone([[1200.0, 1200.0, 0.05], [1600.0, 1600.0, 0.09]], 0.14)
	_streams[&"door_latch"] = _click()
	_streams[&"door_creak"] = _creak(2.2)


## segments : liste de [fréquence début, fréquence fin, durée]. Enveloppe douce par segment.
func _tone(segments: Array, amplitude: float, square := false) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var phase := 0.0
	for segment in segments:
		var count := int(segment[2] * RATE)
		for i in count:
			var t := float(i) / count
			var freq := lerpf(segment[0], segment[1], t)
			phase += TAU * freq / RATE
			var value := sin(phase)
			if square:
				value = signf(value) * 0.5 + sin(phase) * 0.5
			var envelope := minf(t * 12.0, 1.0) * minf((1.0 - t) * 6.0, 1.0)
			samples.append(value * amplitude * envelope)
	return _to_wav(samples)


func _noise_burst(duration: float, amplitude: float, attack: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var low := 0.0
	for i in count:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.08)  # filtre passe-bas grossier
		var envelope := minf(t / attack, 1.0) * exp(-t * 18.0)
		samples.append(low * amplitude * 3.0 * envelope)
	return _to_wav(samples)


func _click() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for i in int(0.05 * RATE):
		var t := float(i) / RATE
		samples.append((randf_range(-1.0, 1.0) * 0.4 + sin(TAU * 1800.0 * t) * 0.5) * exp(-t * 90.0))
	return _to_wav(samples)


## Mise sous tension : clac grave puis bourdonnement qui monte.
func _power_up() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(0.9 * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / RATE
		var freq := 50.0 + minf(t / 0.6, 1.0) * 70.0
		phase += TAU * freq / RATE
		var hum := (sin(phase) + sin(phase * 2.0) * 0.5 + sin(phase * 3.0) * 0.25) * 0.18
		var envelope := minf(t / 0.05, 1.0) * clampf((0.9 - t) / 0.3, 0.0, 1.0)
		var thump := randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.6
		samples.append(hum * envelope + thump)
	return _to_wav(samples)


## Frottement de plastique sur carton (bobine poussée). Boucle.
func _scrape() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var low := 0.0
	for i in RATE:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.25)
		var grain := 0.6 + 0.4 * sin(TAU * 13.0 * t)
		samples.append(low * 0.22 * grain)
	return _to_wav(samples, true)


## Grincement de porte : fréquence qui glisse lentement avec trémolo.
func _creak(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var freq := 180.0 + sin(t * 5.0) * 40.0 + t * 60.0
		phase += TAU * freq / RATE
		var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
		var stutter := 0.5 + 0.5 * signf(sin(t * 90.0 + sin(t * 7.0) * 3.0))
		var envelope := minf(t * 8.0, 1.0) * minf((1.0 - t) * 4.0, 1.0)
		samples.append(saw * 0.08 * stutter * envelope)
	return _to_wav(samples)


func _servo(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var freq := 220.0 + sin(t * PI) * 380.0
		phase += TAU * freq / RATE
		var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
		var tremolo := 0.75 + 0.25 * sin(t * TAU * 18.0)
		var envelope := minf(t * 10.0, 1.0) * minf((1.0 - t) * 8.0, 1.0)
		samples.append(saw * 0.12 * tremolo * envelope)
	return _to_wav(samples)


## Moteurs pas-à-pas : notes qui changent régulièrement. Boucle d'une seconde.
func _print_motor() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var notes := [196.0, 262.0, 233.0, 311.0, 220.0, 294.0, 247.0, 330.0]
	var phase := 0.0
	var count := RATE
	for i in count:
		var note: float = notes[int(float(i) / count * notes.size())]
		phase += TAU * note / RATE
		var value := signf(sin(phase)) * 0.35 + sin(phase * 2.0) * 0.25
		samples.append(value * 0.09)
	return _to_wav(samples, true)


func _wheel_hum() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := RATE  # 1 s ; fréquences entières pour une boucle sans clic
	for i in count:
		var t := float(i) / RATE
		var value := sin(TAU * 140.0 * t) * 0.5 + sin(TAU * 280.0 * t) * 0.25 + sin(TAU * 563.0 * t) * 0.08
		value *= 0.85 + 0.15 * sin(TAU * 6.0 * t)
		samples.append(value * 0.12)
	return _to_wav(samples, true)


## Ambiance de pièce : souffle très doux, bouclé par fondu enchaîné.
func _ambience(duration: float) -> AudioStreamWAV:
	var count := int(duration * RATE)
	var raw := PackedFloat32Array()
	raw.resize(count)
	var brown := 0.0
	for i in count:
		brown = clampf(brown + randf_range(-1.0, 1.0) * 0.02, -1.0, 1.0)
		raw[i] = brown
	var fade := int(RATE * 1.0)
	var samples := PackedFloat32Array()
	for i in count - fade:
		var value := raw[i]
		if i < fade:
			var t := float(i) / fade
			value = raw[i] * t + raw[count - fade + i] * (1.0 - t)
		samples.append(value * 0.25)
	return _to_wav(samples, true)


func _to_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
