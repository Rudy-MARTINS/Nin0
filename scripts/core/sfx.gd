extends Node
## Sons de la démo (autoload « Sfx »), entièrement synthétisés au démarrage :
## aucun fichier audio externe, donc aucune question de licence.
## Provisoires : à remplacer par un vrai sound design plus tard.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _loops := {}  # clé -> AudioStreamPlayer
## Jingles de découverte joués (identifiant → nombre), pour vérifier l'unicité.
var jingle_counts := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sounds()
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = &"Sfx"
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


## Jingle de découverte (scan, plan, installation) : la musique s'efface un instant
## puis reprend ; rien n'est interrompu.
func jingle(id: StringName) -> void:
	jingle_counts[id] = int(jingle_counts.get(id, 0)) + 1
	var stream: AudioStreamWAV = _streams.get(id)
	Music.duck(-12.0, stream.get_length() if stream else 1.0)
	play(id, -2.0)


## Démarre (ou ajuste) un son en boucle identifié par `key`.
func set_loop(key: StringName, sound: StringName, volume_db: float, pitch := 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(key)
	if player == null:
		player = AudioStreamPlayer.new()
		player.bus = &"Sfx"
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
	# Lot 3 : blessure, réparation, vision, souvenirs, fragments.
	_streams[&"spark"] = _crackle(0.25, 0.5)
	_streams[&"impact"] = _impact()
	_streams[&"grind"] = _grind(1.4)
	_streams[&"static"] = _static_loop()
	_streams[&"signal"] = _tone([[1900.0, 1900.0, 0.05], [1200.0, 1200.0, 0.03], [1900.0, 1900.0, 0.05], [2400.0, 2300.0, 0.12]], 0.1)
	_streams[&"glitch"] = _crackle(0.35, 0.8)
	_streams[&"optic"] = _tone([[400.0, 1600.0, 0.35], [1600.0, 1500.0, 0.05], [900.0, 2200.0, 0.2]], 0.1)
	_streams[&"fragment"] = _tone([[1300.0, 1700.0, 0.06], [2000.0, 2000.0, 0.07]], 0.14)
	_streams[&"repair_loop"] = _repair_loop()
	_streams[&"cartoon_fall"] = _slide_whistle(0.9)
	# Lot 5 : fourmis, analyse, combat, lavabo, canon.
	_streams[&"ant_chitter"] = _chitter(0.35)
	_streams[&"scan"] = _tone([[600.0, 1800.0, 0.5], [1800.0, 1700.0, 0.1]], 0.08)
	_streams[&"species"] = _tone([[880.0, 880.0, 0.07], [1175.0, 1175.0, 0.07], [1568.0, 1760.0, 0.18]], 0.14)
	_streams[&"blueprint"] = _tone([[523.0, 523.0, 0.08], [659.0, 659.0, 0.08], [784.0, 784.0, 0.08], [1046.0, 1100.0, 0.3]], 0.16)
	_streams[&"soldier_alert"] = _tone([[300.0, 520.0, 0.08], [520.0, 300.0, 0.1]], 0.2, true)
	_streams[&"bite"] = _noise_burst(0.12, 0.8, 0.003)
	_streams[&"windup"] = _tone([[200.0, 420.0, 0.35]], 0.12, true)
	_streams[&"larva_warn"] = _crackle(0.6, 0.35)
	_streams[&"larva_drop"] = _noise_burst(0.25, 0.7, 0.01)
	_streams[&"acid_spit"] = _spit()
	_streams[&"acid_sizzle"] = _crackle(0.8, 0.3)
	_streams[&"sludge"] = _squelch()
	_streams[&"drain"] = _gurgle_loop()
	_streams[&"queen_roar"] = _tone([[160.0, 110.0, 0.5], [110.0, 140.0, 0.3]], 0.25, true)
	# Lot 5.1 : jingles originaux (timbre de clochette, harmonies simples).
	_streams[&"jingle_scan"] = _jingle([
		[2200.0, 0.0, 0.05, 0.25], [1760.0, 0.06, 0.05, 0.2],
		[659.3, 0.16, 0.14, 0.5], [880.0, 0.28, 0.14, 0.5], [1108.7, 0.40, 0.14, 0.5],
		[1318.5, 0.52, 0.55, 0.6], [440.0, 0.52, 0.55, 0.3], [659.3, 0.52, 0.55, 0.25],
	])
	_streams[&"jingle_plan"] = _jingle([
		[392.0, 0.0, 0.16, 0.45], [523.3, 0.16, 0.16, 0.5], [659.3, 0.32, 0.16, 0.5],
		[587.3, 0.50, 0.12, 0.45], [784.0, 0.64, 0.20, 0.55],
		[1046.5, 0.88, 0.85, 0.6], [523.3, 0.88, 0.85, 0.3], [659.3, 0.88, 0.85, 0.3], [784.0, 0.88, 0.85, 0.3],
		[261.6, 0.88, 0.85, 0.35],
	])
	_streams[&"jingle_install"] = _jingle([
		[392.0, 0.0, 0.09, 0.45], [493.9, 0.09, 0.09, 0.45], [587.3, 0.18, 0.09, 0.45],
		[784.0, 0.27, 0.09, 0.5], [987.8, 0.36, 0.09, 0.5],
		[1174.7, 0.46, 0.6, 0.55], [784.0, 0.46, 0.6, 0.35], [392.0, 0.46, 0.6, 0.3],
	])
	_streams[&"bubbles"] = _bubbles(1.2)
	# Petits sons robotiques de personnalité et petite voix « Yeeeaah ! » (synthèse originale).
	_streams[&"chirp_known"] = _tone([[900.0, 1200.0, 0.06], [1200.0, 1100.0, 0.05]], 0.12)
	_streams[&"chirp_worried"] = _tone([[700.0, 520.0, 0.1], [560.0, 640.0, 0.08], [600.0, 480.0, 0.12]], 0.14)
	_streams[&"chirp_frustrated"] = _tone([[420.0, 300.0, 0.12], [330.0, 260.0, 0.14]], 0.16, true)
	_streams[&"chirp_hesitant"] = _tone([[600.0, 760.0, 0.08], [760.0, 700.0, 0.1], [720.0, 900.0, 0.12]], 0.12)
	_streams[&"chirp_question"] = _tone([[520.0, 980.0, 0.18]], 0.14)
	_streams[&"yeah"] = _yeah()
	_streams[&"queen_defeat"] = _tone([[400.0, 120.0, 1.2]], 0.2, true)
	_streams[&"shot"] = _shot()
	_streams[&"impact_small"] = _click()
	_streams[&"empty_click"] = _tone([[1500.0, 1400.0, 0.03]], 0.1, true)
	_streams[&"unlock"] = _tone([[700.0, 700.0, 0.05], [1046.0, 1046.0, 0.08], [1318.0, 1400.0, 0.2]], 0.16)
	_streams[&"repair_done"] = _tone([[523.0, 523.0, 0.1], [784.0, 784.0, 0.1], [1046.0, 1046.0, 0.1], [1568.0, 1568.0, 0.3]], 0.2)
	# Lot 6 : cuisine (araignées, cafards).
	_streams[&"spider_hiss"] = _hiss(0.45)
	_streams[&"roach_skitter"] = _skitter(0.4)
	_streams[&"web_thread"] = _tone([[1800.0, 2600.0, 0.25]], 0.05)
	_streams[&"wrap"] = _crackle(0.5, 0.18)


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


## Jingle polyphonique : notes [fréquence, début, durée, volume], timbre de clochette
## (fondamentale + harmoniques amorties) pour un son chaleureux et non agressif.
func _jingle(notes: Array) -> AudioStreamWAV:
	var length := 0.0
	for note in notes:
		length = maxf(length, float(note[1]) + float(note[2]) + 0.35)
	var samples := PackedFloat32Array()
	samples.resize(int(length * RATE))
	for note in notes:
		var start := int(float(note[1]) * RATE)
		var count := int((float(note[2]) + 0.35) * RATE)
		for i in count:
			var t := float(i) / RATE
			var hold: float = note[2]
			var held: bool = t < hold
			var envelope := minf(t * 200.0, 1.0) * (exp(-t * 2.5) if held else exp(-hold * 2.5) * exp(-(t - hold) * 9.0))
			var phase: float = TAU * float(note[0]) * t
			var value := sin(phase) + 0.35 * sin(phase * 2.0) * exp(-t * 6.0) + 0.12 * sin(phase * 3.0) * exp(-t * 10.0)
			var index := start + i
			if index < samples.size():
				samples[index] += value * float(note[3]) * envelope * 0.32
	return _to_wav(samples)


## « Yeeeaah ! » robotique : glissement de voyelle /i/ → /a/ (deux formants qui se
## déplacent), hauteur qui monte puis retombe, légère modulation métallique. Court et mignon.
func _yeah() -> AudioStreamWAV:
	var duration := 0.75
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var pitch := lerpf(330.0, 520.0, minf(t * 2.2, 1.0)) - maxf(t - 0.6, 0.0) * 260.0
		phase += TAU * pitch / RATE
		# Formants : « i » (300 / 2300 Hz) vers « a » (750 / 1200 Hz).
		var vowel := smoothstep(0.1, 0.45, t)
		var f1 := lerpf(300.0, 750.0, vowel)
		var f2 := lerpf(2300.0, 1200.0, vowel)
		var value := 0.0
		for h in range(1, 14):
			var freq := pitch * h
			var gain := exp(-pow((freq - f1) / 180.0, 2.0)) + 0.6 * exp(-pow((freq - f2) / 260.0, 2.0)) + 0.05
			value += sin(phase * h) * gain / h * 2.0
		value *= 1.0 + 0.25 * sin(TAU * 60.0 * t * duration)  # grain électronique
		var envelope := minf(t * 25.0, 1.0) * minf((1.0 - t) * 6.0, 1.0)
		samples[i] = clampf(value * envelope * 0.22, -1.0, 1.0)
	return _to_wav(samples)


func _bubbles(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(duration * RATE))
	var t0 := 0.0
	while t0 < duration - 0.1:
		var freq := randf_range(300.0, 700.0)
		var start := int(t0 * RATE)
		for i in int(0.08 * RATE):
			var t := float(i) / RATE
			var index := start + i
			if index < samples.size():
				samples[index] += sin(TAU * (freq + t * 4000.0) * t) * exp(-t * 40.0) * 0.3
		t0 += randf_range(0.05, 0.15)
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


## Cliquetis de mandibules et d'antennes (fourmis).
func _chitter(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	for i in count:
		var t := float(i) / RATE
		var tick := _step(0.6, sin(TAU * 38.0 * t))
		samples.append(sin(TAU * 3200.0 * t) * tick * 0.12 * exp(-t * 4.0))
	return _to_wav(samples)


## Souffle d'araignée : bruit filtré, montée puis chute (menace).
func _hiss(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var low := 0.0
	for i in count:
		var t := float(i) / RATE
		var env := minf(t / 0.06, 1.0) * exp(-maxf(t - 0.12, 0.0) * 7.0)
		var noise := randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.35)
		samples.append((noise - low) * env * 0.32)
	return _to_wav(samples)


## Course de cafard : cliquetis rapides et irréguliers de pattes.
func _skitter(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	for i in count:
		var t := float(i) / RATE
		var tick := _step(0.75, sin(TAU * 52.0 * t + sin(t * 31.0) * 2.0))
		samples.append(randf_range(-1.0, 1.0) * tick * 0.16 * (1.0 - t / duration))
	return _to_wav(samples)


## Crachat liquide (jet acide).
func _spit() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(0.4 * RATE)
	var low := 0.0
	for i in count:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.35)
		samples.append(low * 0.5 * exp(-t * 9.0) + sin(TAU * (900.0 - t * 1500.0) * t) * 0.1 * exp(-t * 12.0))
	return _to_wav(samples)


## Pas dans la matière visqueuse.
func _squelch() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(0.3 * RATE)
	var low := 0.0
	for i in count:
		var t := float(i) / count
		low = lerpf(low, randf_range(-1.0, 1.0), 0.06)
		samples.append((low * 1.6 + sin(TAU * (180.0 - 120.0 * t) * t * 0.3) * 0.2) * sin(PI * t) * 0.5)
	return _to_wav(samples)


## Vidange : glouglou en boucle.
func _gurgle_loop() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var low := 0.0
	for i in RATE:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.04)
		var bubble := sin(TAU * (220.0 + 80.0 * sin(TAU * 6.0 * t)) * t) * 0.08 * _step(0.3, sin(TAU * 9.0 * t))
		samples.append(low * 0.9 + bubble)
	return _to_wav(samples, true)


## Tir du canon : déclic de ressort et souffle.
func _shot() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(0.18 * RATE)
	for i in count:
		var t := float(i) / RATE
		samples.append((sin(TAU * 700.0 * t) * exp(-t * 60.0) * 0.4) + randf_range(-1.0, 1.0) * 0.25 * exp(-t * 30.0))
	return _to_wav(samples)


## Sifflet à coulisse descendant (chute cartoon).
func _slide_whistle(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var freq := lerpf(1900.0, 380.0, t * t) * (1.0 + 0.02 * sin(t * TAU * 22.0))
		phase += TAU * freq / RATE
		var envelope := minf(t * 30.0, 1.0) * minf((1.0 - t) * 10.0, 1.0)
		samples.append(sin(phase) * 0.22 * envelope)
	return _to_wav(samples)


## Grésillement électrique : impulsions aléatoires.
func _crackle(duration: float, amplitude: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var burst := 0.0
	for i in count:
		var t := float(i) / count
		if randf() < 0.004:
			burst = 1.0
		burst *= 0.993
		var envelope := minf(t * 20.0, 1.0) * (1.0 - t)
		samples.append(randf_range(-1.0, 1.0) * burst * amplitude * envelope)
	return _to_wav(samples)


## Choc lourd de la chute : coup grave et cliquetis métalliques.
func _impact() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(0.7 * RATE)
	var low := 0.0
	for i in count:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.05)
		var thump := sin(TAU * (70.0 - t * 40.0) * t) * exp(-t * 9.0) * 0.7
		var rattle := sin(TAU * 2100.0 * t) * sin(TAU * 1370.0 * t) * exp(-t * 7.0) * 0.12 * _step(0.06, t)
		samples.append(thump + low * exp(-t * 14.0) * 1.4 + rattle)
	return _to_wav(samples)


## Grincement mécanique inquiétant (servomoteur abîmé).
func _grind(duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var freq := 95.0 + sin(t * 23.0) * 25.0 + sin(t * 61.0) * 10.0
		phase += TAU * freq / RATE
		var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
		var stutter := 0.4 + 0.6 * _step(0.0, sin(t * 140.0 + sin(t * 9.0) * 4.0))
		var envelope := minf(t * 6.0, 1.0) * minf((1.0 - t) * 3.0, 1.0)
		samples.append((saw * 0.13 + randf_range(-0.03, 0.03)) * stutter * envelope)
	return _to_wav(samples)


## Neige de signal (souvenirs) : bruit filtré avec battements. Boucle.
func _static_loop() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var low := 0.0
	for i in RATE:
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.6)
		var beat := 0.7 + 0.3 * sin(TAU * 7.0 * t)
		samples.append(low * 0.09 * beat)
	return _to_wav(samples, true)


## Réparation : moteurs, petites soudures. Boucle d'une seconde.
func _repair_loop() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var phase := 0.0
	for i in RATE:
		var t := float(i) / RATE
		var note := 247.0 if fmod(t, 0.25) < 0.125 else 330.0
		phase += TAU * note / RATE
		var weld := randf_range(-1.0, 1.0) * 0.05 * _step(0.8, sin(TAU * 3.0 * t))
		samples.append(signf(sin(phase)) * 0.04 + sin(phase * 2.0) * 0.03 + weld)
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


func _step(edge: float, x: float) -> float:
	return 1.0 if x >= edge else 0.0
