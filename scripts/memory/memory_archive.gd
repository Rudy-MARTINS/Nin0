class_name MemoryArchive
extends Resource
## Archives fragmentées : paramètres communs des souvenirs (nombre total, dégradation).
## Un seul souvenir est défini dans cette démo ; les autres seront ajoutés comme
## de simples ressources MemoryData, sans changer le code.

const GLYPHS := ["·", "~", "#", "%", "/", "_"]

@export var total := 7
@export var entries: Array[MemoryData] = []
## Dégradation avec un seul fragment retrouvé, puis avec tous.
@export_range(0.0, 1.0) var corruption_first := 0.62
@export_range(0.0, 1.0) var corruption_all := 0.06


func get_entry(id: StringName) -> MemoryData:
	for entry in entries:
		if entry.id == id:
			return entry
	return null


## Dégradation (0..1) selon le nombre de fragments retrouvés, quel que soit l'ordre.
func corruption(found_count: int) -> float:
	if total <= 1:
		return corruption_all
	var t := clampf(float(found_count - 1) / float(total - 1), 0.0, 1.0)
	return lerpf(corruption_first, corruption_all, t)


## Applique des parasites à une ligne, de façon reproductible (même graine = même résultat).
static func degrade(line: String, amount: float, seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var words := line.split(" ", false)
	var out: PackedStringArray = []
	for word in words:
		if rng.randf() < amount * 0.35:
			out.append("…" if rng.randf() < 0.5 else "bzz")
			continue
		var chars := ""
		for c in word:
			if c != "…" and rng.randf() < amount * 0.45:
				chars += GLYPHS[rng.randi() % GLYPHS.size()]
			else:
				chars += c
		out.append(chars)
	return " ".join(out)


## Nombre de caractères altérés entre deux versions d'une ligne (tests, réglages).
static func altered_count(original: String, degraded: String) -> int:
	var count := absi(original.length() - degraded.length())
	for i in mini(original.length(), degraded.length()):
		if original[i] != degraded[i]:
			count += 1
	return count
