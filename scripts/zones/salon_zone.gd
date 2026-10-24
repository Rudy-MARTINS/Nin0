class_name SalonZone
extends Node3D
## Salon (zone 6), première partie jouable au lot 7 : canapé, tables basses, bureau et
## ordinateur, meuble TV et consoles, rangements, porte-fenêtre, étendoir. La seconde
## partie (est) reste barrée par un encombrement physique ; la chambre reste fermée.
## Nathan (figurine articulée) attend ici, inerte, que Nin0 l'observe. La bascule est la
## première énigme de coopération ; la séquence de protection suit (cafards pilleurs).
## La mise en scène est pilotée par GameWorld ; cette scène expose ses éléments.

signal examined(data: DiscoveryData)
signal protection_started
signal protection_won
signal raider_reached(raider: SalonRaider)

## Chemin des cafards : de sous le canapé, entre l'accoudoir et le pouf, vers la bascule.
const RAIDER_PATH := [Vector3(-36.8, 0.0, 31.5), Vector3(-35.6, 0.0, 38.6), Vector3(-30.0, 0.0, 40.6)]
## Mises KO nécessaires pour repousser les pilleurs ; au plus deux à la fois.
const RAIDERS_NEEDED := 3
const RAIDERS_AT_ONCE := 2

var nathan: Nathan
var protection_active := false
var raiders_down := 0
var _spawn_timer := 0.0

@onready var seesaw: Seesaw = $Seesaw
@onready var box_focus: FocusTarget = $Furniture/BoxFocus


func _ready() -> void:
	for node in $Discoveries.get_children():
		(node as Examinable).examined.connect(func(data: DiscoveryData) -> void: examined.emit(data))
	nathan = Nathan.new()
	nathan.name = "Nathan"
	add_child(nathan)
	nathan.global_transform = marker("NathanSpot")
	nathan.safe_spot = marker("NathanSafe").origin
	# La box n'est observable qu'une fois sur le meuble TV (après la protection).
	box_focus.enabled = false


func marker(name: String) -> Transform3D:
	return (get_node("Markers/" + name) as Node3D).global_transform


## Vrai si un point est sur le dessus du meuble TV.
func on_tv_stand(point: Vector3) -> bool:
	return point.x > -14.6 and point.x < -10.4 and point.z > 26.9 and point.z < 41.1 and point.y > 4.8 and point.y < 6.0


func box_position() -> Vector3:
	return box_focus.global_position


# --- Séquence de protection --------------------------------------------------------------

func start_protection() -> void:
	if protection_active:
		return
	protection_active = true
	raiders_down = 0
	_spawn_timer = 0.6
	protection_started.emit()


func active_raiders() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"salon_raiders"):
		if (node as SalonRaider).is_active():
			count += 1
	return count


func _physics_process(delta: float) -> void:
	if not protection_active or GameState.hazards_suspended():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and active_raiders() < RAIDERS_AT_ONCE and raiders_down + active_raiders() < RAIDERS_NEEDED:
		_spawn_raider()
		_spawn_timer = 2.4


func _spawn_raider() -> void:
	var raider := SalonRaider.new()
	raider.path = PackedVector3Array(RAIDER_PATH)
	raider.home = marker("RaiderNest").origin
	raider.target = nathan
	add_child(raider)
	raider.global_position = raider.home
	raider.reached.connect(func(r: SalonRaider) -> void:
		nathan.scare(r)
		raider_reached.emit(r))
	raider.knocked_out.connect(_on_raider_down)
	Sfx.play(&"roach_skitter", -8.0, 1.0)


func _on_raider_down(_raider: SalonRaider) -> void:
	raiders_down += 1
	if raiders_down >= RAIDERS_NEEDED and protection_active:
		protection_active = false
		for node in get_tree().get_nodes_in_group(&"salon_raiders"):
			var other := node as SalonRaider
			if other.is_active():
				other.queue_free()
		protection_won.emit()


## Interruption (Nin0 hors service, chargement) : les pilleurs disparaissent.
func stop_protection() -> void:
	protection_active = false
	for node in get_tree().get_nodes_in_group(&"salon_raiders"):
		node.queue_free()
