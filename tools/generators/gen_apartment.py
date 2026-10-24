"""Blockout de l'appartement (zones 2 à 7) autour du placard-hub existant.
Échelle : 1 unité = 10 cm. Le placard (zone 1) reste dans workshop.tscn.
Usage : gen_apartment.py <sortie.tscn>"""
import sys, os, re, math
sys.path.insert(0, sys.path[0])
from tscn import *

OUT = sys.argv[1]
s = Scene()
PROP = s.ext_res("Script", "res://scripts/props/prop_block.gd")
H = 24.0          # hauteur sous plafond (2,40 m), comme le placard
T = 0.6           # épaisseur des murs
DOOR_H = 20.8     # hauteur des portes (2,08 m), comme la porte du placard
mats = {}
def mat(key, color, rough=0.85, extra=""):
    if key not in mats:
        mats[key] = std_mat(s, f"Mat_{key}", color, rough, extra=extra)
    return mats[key]
mat("wall", (0.84, 0.82, 0.77))
mat("frame", (0.9, 0.88, 0.83), 0.6)
mat("mass", (0.6, 0.6, 0.62), 0.9)
mat("mass_dark", (0.45, 0.45, 0.48), 0.9)
mat("ceiling", (0.88, 0.87, 0.84))
mat("door", (0.5, 0.36, 0.24), 0.6)
mat("curtain", (0.62, 0.2, 0.18), 1.0, "cull_mode = 2")
mat("glass", (0.75, 0.88, 0.95), 0.05, "transparency = 1\nalbedo_color = Color(0.75, 0.88, 0.95, 0.18)")
mat("garden", (0.42, 0.55, 0.32), 1.0)
mat("blocker", (1.0, 0.3, 0.2), 1.0, "transparency = 1\nalbedo_color = Color(1, 0.3, 0.2, 0.0)")

def box(name, parent, size, pos, m, collide=True, rot=I, climbable=False, shadow=True):
    props = f"transform = {tf(rot, pos)}\nscript = {PROP}\nsize = {v3(size)}\nbevel = 0.02\nmaterial = {mats[m]}"
    if not collide: props += "\ncollide = false"
    if climbable: props += "\nclimbable = true"
    if not shadow: props += "\ncast_shadow = false"
    s.node(name, "StaticBody3D", parent, props)

s.node("ApartmentBlockout", "Node3D", None)
for group in ("Floors", "Walls", "Openings", "Ceilings", "Volumes", "Lights", "Labels", "Zones", "Spawns", "Connections", "Exterior"):
    s.node(group, "Node3D", ".")

# ------------------------------------------------------------------ zones (intérieurs)
# numéro, id, titre, (x0, z0, x1, z1), couleur du sol, état
ZONES = [
    (1, "placard", "Placard-hub", (-15.0, -15.0, 15.0, 12.0), None, "Première démo (lots 1 à 3)"),
    (2, "sas", "Sas", (-45.0, -15.0, -15.6, 12.0), (0.5, 0.47, 0.42), "Jouable (lot 5) — fourmis ouvrières"),
    (3, "salle_de_bain", "Salle de bain", (-75.0, -35.0, -45.6, -0.6), (0.78, 0.8, 0.78), "Jouable (lot 5) — colonie, reine"),
    (4, "cuisine", "Cuisine", (-75.0, 0.0, -45.6, 57.0), (0.74, 0.58, 0.42), "Jouable (lot 6) — araignées, cafards"),
    (6, "salon", "Salon", (-45.0, 12.6, 45.0, 57.0), (0.7, 0.58, 0.42), "Fermé — deux étapes d'exploration"),
    (7, "chambre", "Chambre", (15.6, -35.0, 45.0, 12.0), (0.58, 0.52, 0.7), "Verrouillée jusqu'à la fin"),
]
for num, zid, title, (x0, z0, x1, z1), color, status in ZONES:
    cx, cz, w, d = (x0 + x1) / 2, (z0 + z1) / 2, x1 - x0, z1 - z0
    if color:
        mat(f"floor_{zid}", color, 0.9)
        # Sol : léger débord sous les murs pour éviter les jours.
        fx0, fx1 = x0 - T / 2, x1 + T / 2
        if zid == "sas":
            fx1 = -15.6  # le sol du placard (workshop.tscn) commence au seuil de la porte
        box(f"Floor_{zid}", "Floors", (fx1 - fx0, 0.4, d + T), ((fx0 + fx1) / 2, -0.2, cz), f"floor_{zid}")
        box(f"Ceiling_{zid}", "Ceilings", (w + T, 1.0, d + T), (cx, H + 0.4, cz), "ceiling")
        if zid not in ("sas", "salle_de_bain", "cuisine"):  # zones jouables : éclairage propre (lots 5, 6)
            s.node(f"Light_{zid}", "OmniLight3D", "Lights", f"transform = {tf(I, (cx, H - 3.0, cz))}\nlight_color = Color(1, 0.93, 0.84, 1)\nlight_energy = 0.7\nomni_range = {max(w, d) * 0.85 + 8:.1f}\nomni_attenuation = 0.8")
    shape = s.sub("BoxShape3D", f"ZoneShape_{zid}", f"size = {v3((w, H, d))}")
    s.node(f"Zone{num}", "Area3D", "Zones", f"transform = {tf(I, (cx, H / 2, cz))}\ncollision_layer = 0\ncollision_mask = 4\nmonitorable = false\nmetadata/number = {num}\nmetadata/zone_id = &\"{zid}\"\nmetadata/title = \"{title}\"\nmetadata/status = \"{status}\"")
    s.node("Shape", "CollisionShape3D", f"Zones/Zone{num}", f"shape = {shape}")
    s.node(f"Label{num}", "Label3D", "Labels", f"transform = {tf(I, (cx, 9.0, cz))}\npixel_size = 0.013\nbillboard = 1\nmodulate = Color(1, 0.95, 0.85, 0.9)\noutline_size = 10\nfont_size = 72\ntext = \"{num} · {title.upper()}\\n{status}\"")

# Porte-fenêtre (zone 5) : une ouverture du salon, pas une pièce.
s.node("Zone5", "Area3D", "Zones", f"transform = {tf(I, (-2.0, H / 2, 54.5))}\ncollision_layer = 0\ncollision_mask = 4\nmonitorable = false\nmetadata/number = 5\nmetadata/zone_id = &\"porte_fenetre\"\nmetadata/title = \"Porte-fenêtre\"\nmetadata/status = \"Ouverture fermée — jardin non validé\"")
s.node("Shape", "CollisionShape3D", "Zones/Zone5", "shape = " + s.sub("BoxShape3D", "ZoneShape_pf", f"size = {v3((20.0, H, 5.0))}"))
s.node("Label5", "Label3D", "Labels", f"transform = {tf(I, (-2.0, 23.0, 54.0))}\npixel_size = 0.02\nbillboard = 1\nmodulate = Color(1, 0.95, 0.85, 0.9)\noutline_size = 10\nfont_size = 64\ntext = \"5 · PORTE-FENÊTRE\\nJardin non validé (non jouable)\"")
# Les deux étapes du salon.
for name, x, txt in (("LabelSalonA", -24.0, "Salon — étape A"), ("LabelSalonB", 24.0, "Salon — étape B")):
    s.node(name, "Label3D", "Labels", f"transform = {tf(I, (x, 5.0, 46.0))}\npixel_size = 0.016\nbillboard = 1\nmodulate = Color(1, 0.85, 0.6, 0.85)\noutline_size = 8\nfont_size = 64\ntext = \"{txt}\"")

# ------------------------------------------------------------------ murs et ouvertures
def frame(name, axis, line, a, b, h):
    """Chambranle d'une ouverture (montants + linteau), sans collision au passage."""
    if axis == "x":
        for k, z in ((0, a + 0.2), (1, b - 0.2)):
            box(f"{name}Jamb{k}", "Openings", (0.75, h, 0.4), (line, h / 2, z), "frame")
        box(f"{name}Head", "Openings", (0.75, 0.5, b - a), (line, h - 0.25, (a + b) / 2), "frame", collide=False)
    else:
        for k, x in ((0, a + 0.2), (1, b - 0.2)):
            box(f"{name}Jamb{k}", "Openings", (0.4, h, 0.75), (x, h / 2, line), "frame")
        box(f"{name}Head", "Openings", (b - a, 0.5, 0.75), ((a + b) / 2, h - 0.25, line), "frame", collide=False)

def wall(name, axis, line, start, end, openings=()):
    """Mur le long de x = line (axis 'x') ou z = line (axis 'z'), de start à end,
    avec ouvertures (a, b, hauteur, genre, nom)."""
    cuts = sorted(openings)
    pos = start
    k = 0
    def seg(p0, p1, y0=0.0, y1=H):
        nonlocal k
        if p1 - p0 < 0.01: return
        L, hh = p1 - p0, y1 - y0
        c = (p0 + p1) / 2
        if axis == "x":
            box(f"{name}_{k}", "Walls", (T, hh, L), (line, (y0 + y1) / 2, c), "wall")
        else:
            box(f"{name}_{k}", "Walls", (L, hh, T), (c, (y0 + y1) / 2, line), "wall")
        k += 1
    for a, b, h, kind, oname in cuts:
        seg(pos, a)
        seg(a, b, h, H)  # linteau
        frame(oname, axis, line, a, b, h)
        opening_fill(oname, axis, line, a, b, h, kind)
        pos = b
    seg(pos, end)

def opening_fill(name, axis, line, a, b, h, kind):
    c = (a + b) / 2
    L = b - a - 0.8
    if kind == "open":
        return
    def at(along, y, normal_off=0.0):
        return (line + normal_off, y, along) if axis == "x" else (along, y, line + normal_off)
    def size(length, hh, thick):
        return (thick, hh, length) if axis == "x" else (length, hh, thick)
    if kind == "closed_door":
        # Porte fermée (collision) avec sa poignée ; aucun mécanisme d'ouverture.
        box(f"{name}Panel", "Openings", size(L, h - 0.6, 0.4), at(c, (h - 0.6) / 2), "door")
        for k, off in enumerate((-0.35, 0.35)):
            box(f"{name}Knob{k}", "Openings", size(0.25, 0.25, 0.7), at(a + 0.4 + L * 0.85, 10.0, off), "frame", collide=False)
    elif kind == "curtain":
        # Rideau japonais (bandes jusqu'au sol) + verrou invisible : chambre inaccessible.
        n = 4
        for i in range(n):
            w = L / n - 0.2
            box(f"{name}Strip{i}", "Openings", size(w, h - 1.2, 0.08), at(a + 0.4 + (i + 0.5) * L / n, (h - 0.6 + 0.6) / 2 + 0.3), "curtain", collide=False, shadow=False)
        box(f"{name}Rod", "Openings", size(L + 0.6, 0.25, 0.25), at(c, h - 0.6), "mass_dark", collide=False)
        box(f"{name}Lock", "Openings", size(L, h, 0.6), at(c, h / 2), "blocker", shadow=False)
    elif kind == "glass":
        # Porte-fenêtre fermée : deux vantaux vitrés, montants et verrou.
        half = (b - a) / 2
        for i, cc in enumerate((a + half / 2, b - half / 2)):
            box(f"{name}Glass{i}", "Openings", size(half - 1.0, h - 1.6, 0.08), at(cc, h / 2), "glass", collide=False, shadow=False)
            box(f"{name}Mullion{i}", "Openings", size(0.3, h - 0.6, 0.3), at(cc - half / 2 + 0.35 if i else cc + half / 2 - 0.35, h / 2), "frame", collide=False)
        box(f"{name}Rail", "Openings", size(b - a, 0.6, 0.6), at(c, 0.3), "frame")
        box(f"{name}Lock", "Openings", size(b - a, h, 0.5), at(c, h / 2), "blocker", shadow=False)

# x = -75.3 : façade ouest
wall("WallWest", "x", -75.3, -35.6, 57.6)
# x = -45.3 : salle de bain | sas ; cuisine | sas (raccourci) ; cuisine | salon
wall("WallSasWest", "x", -45.3, -35.6, 57.6, [
    (-12.0, -3.0, DOOR_H, "open", "DoorSasBath"),
    (2.0, 11.0, DOOR_H, "open", "DoorSasKitchen"),        # porte de la cuisine : sas_zone.tscn (loquet)
    (26.0, 37.0, DOOR_H, "closed_door", "DoorSalonKitchen"),  # cuisine ↔ salon : fermé (à définir)
])
wall("WallSasNorth", "z", -15.3, -45.6, -15.6)
wall("WallBathNorth", "z", -35.3, -75.6, -45.0)
wall("WallBathKitchen", "z", -0.3, -75.0, -45.6)
wall("WallSasSalon", "z", 12.3, -45.0, -15.6, [(-36.0, -27.0, DOOR_H, "closed_door", "DoorSasSalon")])  # salon : fermé
wall("WallChamberWestNorth", "x", 15.3, -35.6, -15.6)
wall("WallChamberNorth", "z", -35.3, 15.0, 45.6)
wall("WallEast", "x", 45.3, -35.6, 57.6)
wall("WallChamberSalon", "z", 12.3, 15.6, 45.0, [(25.0, 35.0, DOOR_H, "curtain", "CurtainChamber")])
wall("WallSouth", "z", 57.3, -75.6, 45.6, [(-12.0, 8.0, 21.5, "glass", "FrenchWindow")])

# Retombée de plafond entre les deux étapes du salon (une seule pièce).
box("SalonBeam", "Walls", (2.0, 3.0, 44.4), (0.0, H - 1.5, 34.8), "wall")

# ------------------------------------------------------------------ volumes provisoires (échelle, verticalité)
V = "Volumes"
# Sas : meuble à chaussures.
# Salle de bain : baignoire, meuble lavabo, WC.
# Cuisine : jouable (lot 6), décor dans kitchen_zone.tscn.
# Salon, étape A : canapé, table basse, meuble TV.
box("SofaBase", V, (20.0, 4.5, 9.0), (-30.0, 2.25, 50.5), "mass")
box("SofaBack", V, (20.0, 8.5, 2.5), (-30.0, 4.25, 55.6), "mass")
box("CoffeeTable", V, (11.0, 4.0, 6.0), (-30.0, 2.0, 37.0), "mass_dark")
box("TvStand", V, (12.0, 5.0, 4.5), (-21.0, 2.5, 15.0), "mass_dark")
# Séparation partielle entre les deux étapes : meuble bas.
box("SalonDivider", V, (3.5, 10.0, 16.0), (0.0, 5.0, 20.6), "mass")
# Salon, étape B : grande bibliothèque, table de repas.
box("Bookcase", V, (4.0, 18.0, 20.0), (43.0, 9.0, 32.0), "mass")
box("DiningTable", V, (16.0, 7.5, 9.0), (22.0, 3.75, 40.0), "mass_dark")
# Chambre (inaccessible) : lit, armoire.
box("Bed", V, (16.0, 5.0, 20.0), (33.0, 2.5, -20.0), "mass")
box("Wardrobe", V, (6.0, 20.0, 14.0), (18.8, 10.0, -27.0), "mass_dark")

# ------------------------------------------------------------------ extérieur derrière la porte-fenêtre (non jouable)
box("GardenGround", "Exterior", (60.0, 0.4, 30.0), (-2.0, -0.6, 73.0), "garden", collide=False)

# ------------------------------------------------------------------ points d'apparition (mode développement) et connexions
SPAWNS = {1: ((-6.0, 8.05, -10.5), 90), 2: ((-27.0, 0.05, 0.0), 90), 3: ((-55.0, 0.05, -12.0), 90), 4: ((-58.0, 0.05, 30.0), 0),
          5: ((-2.0, 0.05, 50.0), 180), 6: ((-20.0, 0.05, 28.0), -90), 7: ((30.0, 0.05, -5.0), 180)}
for num, (p, yaw) in SPAWNS.items():
    s.node(f"Spawn{num}", "Marker3D", "Spawns", f"transform = {tf(ry(yaw), p)}")
CONNECTIONS = [
    ("placard_sas", 1, 2, "ouvert", (-15.3, 5.5)),
    ("sas_sdb", 2, 3, "ouvert", (-45.3, -7.5)),
    ("sas_salon", 2, 6, "fermé (ouverture à définir)", (-31.5, 12.3)),
    ("salon_cuisine", 6, 4, "fermé (ouverture à définir)", (-45.3, 31.5)),
    ("salon_porte_fenetre", 6, 5, "fermé (jardin non validé)", (-2.0, 57.3)),
    ("sas_cuisine", 2, 4, "verrou (canon)", (-45.3, 6.5)),
    ("salon_chambre", 6, 7, "verrouillé jusqu'à la fin", (30.0, 12.3)),
]
for cid, a, b, state, (x, z) in CONNECTIONS:
    s.node(f"C_{cid}", "Marker3D", "Connections", f"transform = {tf(I, (x, 1.0, z))}\nmetadata/from = {a}\nmetadata/to = {b}\nmetadata/state = \"{state}\"")
for name, (x, z), txt in (("LabelShortcut", (-44.0, 6.5), "Cuisine — loquet (canon)"), ("LabelSalonDoor", (-31.5, 10.8), "Salon — fermé (à définir)"),
        ("LabelCurtain", (30.0, 13.8), "Rideau japonais — accès verrouillé")):
    s.node(name, "Label3D", "Labels", f"transform = {tf(I, (x, 22.5, z))}\npixel_size = 0.014\nbillboard = 1\nmodulate = Color(1, 0.6, 0.5, 0.9)\noutline_size = 8\nfont_size = 64\ntext = \"{txt}\"")

# Conserve l'uid de l'en-tête lors d'une régénération.
uid = None
if os.path.exists(OUT):
    m = re.search(r'uid="(uid://[a-z0-9]+)"', open(OUT, encoding="utf-8").readline())
    uid = m.group(1) if m else None
s.write(OUT)
if uid:
    text = open(OUT, encoding="utf-8").read()
    text = text.replace("[gd_scene format=3]", f'[gd_scene format=3 uid="{uid}"]', 1)
    open(OUT, "w", encoding="utf-8").write(text)
print("blockout ok")
