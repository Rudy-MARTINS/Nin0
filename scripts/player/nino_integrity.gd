class_name NinoIntegrity
extends Node
## Intégrité de Nin0 (santé) et bouclier, appliqués au personnage.
## Les valeurs vivent dans GameState (sauvegarde) ; ce nœud gère les règles :
## - les chutes abîment proportionnellement à leur hauteur, les petites non ;
## - à faible intégrité, Nin0 paraît abîmé (parasites, étincelles, démarche un peu
##   irrégulière) sans que les passages deviennent impossibles ;
## - le bouclier absorbe d'abord et se recharge après un moment sans dégâts ;
## - à 0, Nin0 se met en veille et redémarre au dernier point sûr (pas de mort).
## Le bouclier est distinct du futur module « défense active ».

signal damaged(integrity_loss: float, shield_loss: float)
signal shutdown_started
signal shutdown_finished
signal damaged_changed(active: bool)

@export var nino: NinoController
@export var shield_recharge_delay := 4.0
@export var shield_recharge_rate := 8.0
## Hauteur de chute (u) sans dégâts : sauts, saut chargé et petites descentes.
@export var fall_safe_height := 4.5
## Dégâts par unité de hauteur au-delà (chute du plan de travail, 9 u : ≈ 10).
@export var fall_damage_per_unit := 2.2
## Fraction d'intégrité en dessous de laquelle Nin0 paraît abîmé.
@export var damaged_threshold := 0.35
## Intégrité rendue au redémarrage après une mise en veille (fraction du maximum).
@export_range(0.1, 1.0) var shutdown_restore := 0.4
## Brève protection après un coup ennemi : pas de dégâts répétés à chaque image.
@export var hit_protection := 0.9

## Désactivé pendant les séquences scriptées (la chute de la porte gère ses dégâts).
var enabled := true
var _since_damage := 0.0
var _shutting_down := false
var _protection := 0.0
## État abîmé (faible intégrité) : effets ponctuels, vitesse un peu réduite.
var damaged_state := false
var _damaged_timer := 2.0
var _damaged_time := 0.0


func _ready() -> void:
	add_to_group(&"nino_integrity")
	nino.landed.connect(_on_landed)
	# Fin d'une séquence non interactive : courte protection, jamais de coup immédiat.
	GameState.hazards_changed.connect(func(suspended: bool) -> void:
		if not suspended:
			_protection = maxf(_protection, 1.0))
	GameState.stats_changed.connect(_refresh_visual)
	_refresh_visual()


func _physics_process(delta: float) -> void:
	_since_damage += delta
	_protection = maxf(_protection - delta, 0.0)
	if _since_damage > shield_recharge_delay and not _shutting_down:
		GameState.recharge_shield(shield_recharge_rate * delta)
	_update_damaged_state(delta)


## Coup porté par une créature : protection temporaire, recul et dégâts typés.
## Renvoie false si Nin0 était encore protégé (le coup ne compte pas).
func hit(amount: float, kind: StringName = &"physical", from: Vector3 = Vector3.INF) -> bool:
	# Aucune attaque ne touche pendant une séquence non interactive.
	if GameState.hazards_suspended():
		return false
	if _protection > 0.0 or _shutting_down:
		return false
	_protection = hit_protection
	take_damage(amount, false, kind)
	if from != Vector3.INF and nino.state == NinoController.State.FREE:
		var away := nino.global_position - from
		away.y = 0.0
		if away.length() > 0.01:
			nino.velocity += away.normalized() * 2.2 + Vector3.UP * 2.5
	nino.get_visual().show_emotion(NinoVisual.Emotion.HURT, 0.8)
	Sfx.play(&"hurt", -8.0)
	return true


func is_protected() -> bool:
	return _protection > 0.0


## Inflige des dégâts ; `bypass_shield` pour un choc direct (chute scriptée).
## kind « physical » : réduit par l'Armure I équipée ; « acid » : non réduit.
func take_damage(amount: float, bypass_shield := false, kind: StringName = &"physical") -> float:
	amount *= nino.damage_taken_multiplier
	if kind == &"physical":
		amount *= 1.0 - GameState.physical_damage_reduction()
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


func _on_landed(_impact_speed: float) -> void:
	var damage := fall_damage(nino.last_fall_height)
	if not enabled or damage <= 0.0:
		return
	take_damage(damage)


## Dégâts d'une chute de `height` unités (0 pour les sauts et petites descentes).
func fall_damage(height: float) -> float:
	return maxf(height - fall_safe_height, 0.0) * fall_damage_per_unit


## Faible intégrité : parasites du visage, étincelles, pas un peu hésitant.
func _update_damaged_state(delta: float) -> void:
	var low := GameState.integrity / maxf(GameState.integrity_max, 1.0) < damaged_threshold and not _shutting_down
	if low != damaged_state:
		damaged_state = low
		if low:
			nino.set_speed_modifier(&"damaged", 0.88)
			damaged_changed.emit(true)
		else:
			nino.clear_modifier(&"damaged")
			nino.get_visual().set_tilt(0.0)
			damaged_changed.emit(false)
	if not damaged_state:
		return
	var visual := nino.get_visual()
	_damaged_time += delta
	# Démarche irrégulière : légère inclinaison quand il avance.
	var moving := Vector2(nino.velocity.x, nino.velocity.z).length() > 0.3 and nino.is_on_floor()
	if nino.state == NinoController.State.FREE and nino.controls_enabled:
		visual.set_tilt(sin(_damaged_time * 9.0) * 4.0 if moving else 0.0)
	_damaged_timer -= delta
	if _damaged_timer <= 0.0:
		_damaged_timer = randf_range(2.5, 4.5)
		visual.glitch_pulse(0.45, 0.25)
		if randf() < 0.6:
			visual.emit_sparks(4)
			Sfx.play(&"spark", -16.0, randf_range(0.9, 1.2))


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
