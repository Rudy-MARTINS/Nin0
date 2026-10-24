class_name NinoReactions
extends Node
## Personnalité de Nin0 : réactions contextuelles brèves et variées (visage, regard,
## petit mouvement, son robotique, parfois un pictogramme). Chaque type de réaction a
## son propre délai et une part de hasard : Nin0 ne commente pas tout ce que fait le
## joueur. Aucune information narrative n'est donnée ici.
##
## Types : unknown (objet inconnu), known (déjà vu), peaceful (créature pacifique),
## danger, discovery, failure, upgrade, strange (objet étrange), puzzled (événement
## incompréhensible).

const REACTIONS := {
	&"unknown": {"emotion": NinoVisual.Emotion.CURIOUS, "sound": &"curious", "icons": [[&"eye", &"question"], [&"question"]], "think": 0.6, "cooldown": 4.0},
	&"known": {"emotion": NinoVisual.Emotion.HAPPY, "sound": &"chirp_known", "icons": [[&"check"]], "think": 0.25, "cooldown": 6.0},
	&"peaceful": {"emotion": NinoVisual.Emotion.SURPRISED, "sound": &"curious", "icons": [[&"ant", &"eye"], [&"happy"]], "think": 0.35, "cooldown": 25.0},
	&"danger": {"emotion": NinoVisual.Emotion.WORRIED, "sound": &"chirp_worried", "icons": [[&"exclamation"]], "think": 0.3, "cooldown": 7.0},
	&"discovery": {"emotion": NinoVisual.Emotion.HAPPY, "sound": &"happy", "icons": [[&"idea"], [&"check"]], "think": 0.4, "cooldown": 3.0},
	&"failure": {"emotion": NinoVisual.Emotion.FRUSTRATED, "sound": &"chirp_frustrated", "icons": [[&"cross"], [&"damage"]], "think": 0.35, "cooldown": 8.0},
	&"upgrade": {"emotion": NinoVisual.Emotion.ENTHUSIASTIC, "sound": &"yeah", "icons": [[&"happy"]], "think": 0.0, "cooldown": 2.0},
	&"strange": {"emotion": NinoVisual.Emotion.HESITANT, "sound": &"chirp_hesitant", "icons": [[&"question", &"ellipsis"]], "think": 0.5, "cooldown": 6.0},
	&"puzzled": {"emotion": NinoVisual.Emotion.CURIOUS, "sound": &"chirp_question", "icons": [[&"question"]], "think": 0.45, "cooldown": 10.0},
}

var nino: NinoController
var thoughts: ThoughtBubbles
## Dernières réactions (diagnostic et tests).
var history: Array[StringName] = []

var _last := {}
## Variantes déjà utilisées (jamais deux fois la même à la suite) et réactions récentes
## (au-delà de trois en 45 s, Nin0 se fait plus discret : moins de pensées, son plus bas).
var _last_variant := {}
var _recent := {}
var _idle := 0.0
var _idle_next := 9.0


## Réaction de type `kind`. `look_at` : point regardé un instant. `force` ignore le délai.
## Renvoie false si la réaction a été ignorée (trop récente).
func react(kind: StringName, look_at: Variant = null, force := false) -> bool:
	var spec: Dictionary = REACTIONS.get(kind, {})
	if spec.is_empty() or nino == null:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - float(_last.get(kind, -999.0)) < float(spec.cooldown):
		return false
	_last[kind] = now
	history.append(kind)
	var recent: Array = _recent.get(kind, []).filter(func(t: float) -> bool: return now - t < 45.0)
	recent.append(now)
	_recent[kind] = recent
	var tired := recent.size() > 3
	var visual := nino.get_visual()
	visual.show_emotion(spec.emotion, 1.4)
	if not tired or randf() < 0.5:
		Sfx.play(spec.sound, (-6.0 if kind == &"upgrade" else -10.0) - (6.0 if tired else 0.0), randf_range(0.92, 1.1))
	if look_at is Vector3:
		_glance(look_at, 1.0)
	_gesture(kind, visual)
	var icons: Array = spec.icons
	if thoughts and randf() < float(spec.think) * (0.3 if tired else 1.0):
		thoughts.think(icons[_pick_variant(kind, icons.size())], "", 1.6)
	return true


## Gestuelle courte, variée selon le type et sans répétition immédiate.
func _gesture(kind: StringName, visual: NinoVisual) -> void:
	var variant := _pick_variant(StringName(String(kind) + "_gesture"), 3)
	match kind:
		&"known":
			visual.react_to_landing(2.0 + variant)  # petit hochement
		&"danger":
			visual.set_tilt([-7.0, -4.0, 5.0][variant])
			visual.react_to_landing(4.0)  # léger recul
		&"strange", &"puzzled":
			visual.set_tilt([7.0, -8.0, 11.0][variant])
		&"failure":
			# Secoue la tête.
			for k in 3:
				get_tree().create_timer(0.12 * k).timeout.connect(func() -> void: visual.set_tilt(6.0 if k % 2 == 0 else -6.0))
		&"upgrade", &"discovery":
			visual.react_to_jump()
		&"peaceful", &"unknown":
			if variant == 1:
				visual.set_tilt(6.0)
	get_tree().create_timer(0.7).timeout.connect(func() -> void: visual.set_tilt(0.0))


func _pick_variant(key: StringName, count: int) -> int:
	if count <= 1:
		return 0
	var last := int(_last_variant.get(key, -1))
	var pick := randi() % count
	if pick == last:
		pick = (pick + 1 + randi() % (count - 1)) % count
	_last_variant[key] = pick
	return pick


## Petite vie au repos : regards autour de lui, de temps en temps (sans pensée).
func _process(delta: float) -> void:
	if nino == null or not nino.controls_enabled or GameState.modal_open:
		return
	if nino.velocity.length() > 0.1:
		_idle = 0.0
		return
	_idle += delta
	if _idle > _idle_next:
		_idle = 0.0
		_idle_next = randf_range(7.0, 14.0)
		var side := -1.0 if randf() < 0.5 else 1.0
		_glance(nino.global_position + nino.global_basis * Vector3(side * 1.6, randf_range(0.0, 0.8), -1.0), 1.2)
		if randf() < 0.3:
			nino.get_visual().show_emotion(NinoVisual.Emotion.CURIOUS, 1.0)


func _glance(point: Vector3, duration: float) -> void:
	var visual := nino.get_visual()
	visual.look_target = point
	await get_tree().create_timer(duration).timeout
	if visual.look_target == point:
		visual.look_target = null
