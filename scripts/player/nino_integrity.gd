class_name NinoIntegrity
extends Node
## Intégrité de Nin0 (santé) et bouclier, appliqués au personnage.
## Les valeurs vivent dans GameState (sauvegarde) ; ce nœud gère les règles :
## - les grosses chutes abîment, les petites non (seuil de vitesse d'impact) ;
## - le bouclier absorbe d'abord et se recharge après un moment sans dégâts ;
## - à 0, Nin0 se met en veille et redémarre au dernier point sûr (pas de mort).
## Le bouclier est distinct du futur module « défense active ».

signal damaged(integrity_loss: float, shield_loss: float)
signal shutdown_started
signal shutdown_finished

@export var nino: NinoController
@export var shield_recharge_delay := 4.0
@export var shield_recharge_rate := 8.0
## Vitesse d'impact (u/s) au-delà de laquelle une chute fait des dégâts.
@export var fall_damage_threshold := 18.0
@export var fall_damage_per_speed := 3.0
## Intégrité rendue au redémarrage après une mise en veille (fraction du maximum).
@export_range(0.1, 1.0) var shutdown_restore := 0.4

## Désactivé pendant les séquences scriptées (la chute de la porte gère ses dégâts).
var enabled := true
var _since_damage := 0.0
var _shutting_down := false


func _ready() -> void:
	nino.landed.connect(_on_landed)
	GameState.stats_changed.connect(_refresh_visual)
	_refresh_visual()


func _physics_process(delta: float) -> void:
	_since_damage += delta
	if _since_damage > shield_recharge_delay and not _shutting_down:
		GameState.recharge_shield(shield_recharge_rate * delta)


## Inflige des dégâts ; `bypass_shield` pour un choc direct (chute scriptée).
func take_damage(amount: float, bypass_shield := false) -> float:
	var shield_before := GameState.shield
	var loss := GameState.apply_damage(amount, bypass_shield)
	_since_damage = 0.0
	damaged.emit(loss, shield_before - GameState.shield)
	var visual := nino.get_visual()
	if loss > 0.0:
		visual.glitch_pulse(1.0, 0.5)
		visual.emit_sparks(10)
		Sfx.play(&"spark", -8.0)
	elif shield_before > GameState.shield:
		visual.glitch_pulse(0.35, 0.2)
	if GameState.integrity <= 0.0 and not _shutting_down:
		_shutdown()
	return loss


func _on_landed(impact_speed: float) -> void:
	if not enabled or impact_speed <= fall_damage_threshold:
		return
	take_damage((impact_speed - fall_damage_threshold) * fall_damage_per_speed)


func _refresh_visual() -> void:
	var ratio := GameState.integrity / maxf(GameState.integrity_max, 1.0)
	# Dommages visibles seulement en dessous de 80 % d'intégrité.
	nino.get_visual().set_damage_level(clampf((0.8 - ratio) / 0.6, 0.0, 1.0))


## Mise en veille : l'écran s'éteint, Nin0 redémarre au dernier point sûr.
func _shutdown() -> void:
	_shutting_down = true
	shutdown_started.emit()
	var was_enabled := nino.controls_enabled
	nino.controls_enabled = false
	var visual := nino.get_visual()
	visual.show_emotion(NinoVisual.Emotion.DIZZY, 1.5)
	Sfx.play(&"grind", -6.0)
	await get_tree().create_timer(1.2).timeout
	visual.set_power(0.0)
	await get_tree().create_timer(1.0).timeout
	nino.respawn()
	GameState.restore_integrity(GameState.integrity_max * shutdown_restore)
	visual.set_power(1.0)
	Sfx.play(&"boot", -8.0)
	nino.controls_enabled = was_enabled
	_shutting_down = false
	shutdown_finished.emit()
