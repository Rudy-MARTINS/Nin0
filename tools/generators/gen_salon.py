"""Salon (zone 6), première partie jouable (lot 7). Intérieur x[-45, 45], z[12,6 ; 57],
plafond 24 (1 u = 10 cm). Entrée par la porte du sas (mur nord, x -36 à -27).
Partie 1 (ouest, x < 0) : canapé, tables basses, bureau + ordinateur + chaise, meuble TV et
consoles, rangements, porte-fenêtre lumineuse, étendoir. Partie 2 (est) : barrée par un
encombrement physique (bacs empilés, paravent, grande plante) dans le prolongement du
meuble de séparation ; la chambre (rideau, mur nord à l'est) reste inaccessible.
Usage : gen_salon.py <sortie.tscn>"""
import sys
sys.path.insert(0, sys.path[0])
from gen_common import *
random.seed(8)
g = Gen("SalonZone", "res://scripts/zones/salon_zone.gd")
s = g.s
EXAM = s.ext_res("Script", "res://scripts/interaction/examinable.gd")
DISC = s.ext_res("Script", "res://scripts/discovery/discovery_data.gd")
LANDMARK = s.ext_res("Resource", "res://assets/observation/landmark.tres")
MEMPROF = s.ext_res("Resource", "res://assets/observation/memory_detail.tres")
MEMORY5 = s.ext_res("Resource", "res://assets/memories/memory_05.tres")
SEESAW = s.ext_res("Script", "res://scripts/zones/seesaw.gd")

# ------------------------------------------------------------------ matériaux
g.mat("sofa", (0.36, 0.42, 0.5), 0.95)
g.mat("sofa_dark", (0.28, 0.33, 0.4), 0.95)
g.mat("cushion", (0.85, 0.62, 0.3), 1.0)
g.mat("cushion_b", (0.62, 0.72, 0.6), 1.0)
g.mat("throw", (0.72, 0.36, 0.3), 1.0)
g.mat("wood", (0.62, 0.46, 0.3), 0.7)
g.mat("wood_light", (0.78, 0.64, 0.46), 0.7)
g.mat("wood_dark", (0.34, 0.24, 0.16), 0.75)
g.mat("white", (0.9, 0.9, 0.88), 0.5)
g.mat("black", (0.07, 0.07, 0.08), 0.35, 0.2)
g.mat("screen", (0.04, 0.05, 0.07), 0.15, 0.3)
g.mat("grey", (0.5, 0.51, 0.53), 0.5, 0.3)
g.mat("steel", (0.72, 0.74, 0.76), 0.3, 0.8)
g.mat("chair", (0.18, 0.2, 0.24), 0.6)
g.mat("rug", (0.72, 0.6, 0.42), 1.0)
g.mat("rug_band", (0.44, 0.3, 0.22), 1.0)
g.mat("paper", (0.93, 0.92, 0.86), 0.9)
g.mat("mag_a", (0.8, 0.3, 0.3), 0.6)
g.mat("mag_b", (0.3, 0.5, 0.75), 0.6)
g.mat("mag_c", (0.9, 0.8, 0.35), 0.6)
g.mat("mug", (0.85, 0.85, 0.82), 0.4)
g.mat("console", (0.12, 0.12, 0.14), 0.4, 0.2)
g.mat("pad", (0.2, 0.22, 0.26), 0.5)
g.mat("pad_red", (0.75, 0.2, 0.2), 0.5)
g.mat("pad_blue", (0.2, 0.4, 0.8), 0.5)
g.mat("led_green", (0.3, 1.0, 0.45), 0.5, extra="emission_enabled = true\nemission = Color(0.3, 1, 0.45, 1)\nemission_energy_multiplier = 2.0")
g.mat("led_blue", (0.35, 0.6, 1.0), 0.5, extra="emission_enabled = true\nemission = Color(0.35, 0.6, 1, 1)\nemission_energy_multiplier = 2.0")
g.mat("box_case", (0.9, 0.9, 0.9), 0.3)
g.mat("glass_dark", (0.2, 0.22, 0.26), 0.1, extra="transparency = 1\nalbedo_color = Color(0.2, 0.22, 0.26, 0.55)")
g.mat("crate", (0.55, 0.62, 0.68), 0.5)
g.mat("crate_lid", (0.35, 0.42, 0.5), 0.5)
g.mat("screen_panel", (0.86, 0.8, 0.66), 0.9)
g.mat("pot", (0.7, 0.42, 0.3), 0.9)
g.mat("leaf", (0.3, 0.5, 0.26), 0.8)
g.mat("leaf_dark", (0.22, 0.38, 0.2), 0.8)
g.mat("towel", (0.9, 0.85, 0.7), 1.0)
g.mat("towel_b", (0.5, 0.66, 0.78), 1.0)
g.mat("sock", (0.45, 0.45, 0.48), 1.0)
g.mat("basket", (0.78, 0.66, 0.44), 0.9)
g.mat("tape", (0.85, 0.8, 0.62), 0.6)
g.mat("ruler", (0.86, 0.72, 0.42), 0.6)
g.mat("ink", (0.25, 0.22, 0.2), 0.9)
g.mat("cable", (0.08, 0.08, 0.08), 0.6)
g.mat("lamp", (0.92, 0.86, 0.7), 0.5, extra="emission_enabled = true\nemission = Color(1, 0.86, 0.6, 1)\nemission_energy_multiplier = 0.8")
g.mat("crumb", (0.82, 0.64, 0.36), 0.9)
g.mat("sky", (0.92, 0.96, 1.0), 1.0, extra="shading_mode = 0\nemission_enabled = true\nemission = Color(0.92, 0.96, 1, 1)\nemission_energy_multiplier = 1.6")
g.mat("sunpatch", (1.0, 0.92, 0.7), 1.0, extra="transparency = 1\nshading_mode = 0\nalbedo_color = Color(1, 0.92, 0.7, 0.22)\ncull_mode = 2")
for k, a, col in (("dust", 0.3, (0.55, 0.52, 0.46)), ("shadow", 0.5, (0.02, 0.02, 0.03))):
    g.mat(k, col, 1.0, extra=f"transparency = 1\nalbedo_color = Color({col[0]}, {col[1]}, {col[2]}, {a})\ncull_mode = 2")

for grp in ("Furniture", "Decor", "Clutter"):
    g.group(grp)
F, D, C = "Furniture", "Decor", "Clutter"

# ------------------------------------------------------------------ canapé (mur ouest, devant la porte de la cuisine)
# Assise surélevée (dessous ouvert, 1,2 u : passage et cachette des cafards).
g.prop("SofaSeat", F, (7.0, 2.4, 19.0), (-39.5, 2.4, 32.0), "sofa", bevel=0.3)
g.prop("SofaBack", F, (1.6, 7.8, 21.0), (-43.8, 5.1, 32.0), "sofa_dark", bevel=0.3)
g.prop("SofaArmNorth", F, (8.6, 5.0, 1.5), (-40.3, 3.7, 21.75), "sofa_dark", bevel=0.3)
g.prop("SofaArmSouth", F, (8.6, 5.0, 1.5), (-40.3, 3.7, 42.25), "sofa_dark", bevel=0.3)
for i, (fx, fz) in enumerate(((-36.5, 21.4), (-36.5, 42.6), (-44.2, 21.4), (-44.2, 42.6))):
    g.prop(f"SofaFoot{i}", F, (0.6, 1.2, 0.6), (fx, 0.6, fz), "wood_dark", cyl=True)
for i, z in enumerate((26.8, 37.2)):
    g.prop(f"SeatCushion{i}", F, (6.6, 0.6, 9.2), (-39.4, 3.85, z), "sofa", bevel=0.25, collide=False)
g.prop("PillowBack", F, (1.2, 3.0, 3.2), (-42.4, 5.6, 25.0), "cushion", rot=rz(-12), bevel=0.4, collide=False)
g.prop("PillowBackB", F, (1.2, 2.6, 3.0), (-42.4, 5.4, 39.0), "cushion_b", rot=rz(-10), bevel=0.4, collide=False)
g.prop("Throw", F, (5.2, 0.2, 4.0), (-39.8, 4.3, 31.0), "throw", rot=ry(8), bevel=0.08, collide=False)
g.decal("UnderSofaDark", D, (7.0, 19.0), (-39.5, 0.01, 32.0), "shadow", rx(-90))
for i in range(10):
    g.sphere(f"SofaCrumb{i}", D, 0.05, (-39.5 + random.uniform(-3, 3), 0.03, 32.0 + random.uniform(-8, 8)), "crumb")
g.sphere("DustBunny", D, 0.35, (-41.5, 0.2, 27.0), "dust", (1.4, 0.6, 1.0))
# Coussin tombé et pouf : marches vers la table basse.
g.prop("FloorPillow", F, (2.2, 1.0, 2.2), (-34.9, 0.5, 34.5), "cushion", rot=ry(18), bevel=0.4)
g.prop("Pouf", F, (2.4, 2.6, 2.4), (-32.3, 1.3, 34.5), "throw", cyl=True, bevel=0.3)

# ------------------------------------------------------------------ tapis, tables basses
g.prop("Rug", D, (18.0, 0.05, 20.0), (-25.0, 0.025, 34.0), "rug", bevel=0.0, collide=False)
for i, (sx, sz, px, pz) in enumerate(((17.0, 0.4, -25.0, 24.6), (17.0, 0.4, -25.0, 43.4), (0.4, 19.2, -33.6, 34.0), (0.4, 19.2, -16.4, 34.0))):
    g.prop(f"RugBand{i}", D, (sx, 0.055, sz), (px, 0.028, pz), "rug_band", bevel=0.0, collide=False)
CT = (-26.0, 33.0)   # table basse : x[-31, -21], z[29, 37], dessus 4,0 (dessous ouvert)
g.prop("CoffeeTop", F, (10.0, 0.4, 8.0), (CT[0], 3.8, CT[1]), "wood_light", bevel=0.08)
for i, (lx, lz) in enumerate(((-30.6, 29.4), (-30.6, 36.6), (-21.4, 29.4), (-21.4, 36.6))):
    g.prop(f"CoffeeLeg{i}", F, (0.5, 3.6, 0.5), (lx, 1.8, lz), "wood_dark")
g.prop("CoffeeShelf", F, (9.0, 0.2, 7.0), (CT[0], 1.3, CT[1]), "wood_light", bevel=0.04, collide=False)
for i, (m, h) in enumerate((("mag_a", 0.18), ("mag_b", 0.16), ("mag_c", 0.2))):
    g.prop(f"Magazine{i}", F, (2.4, h, 3.2), (-28.6, 4.0 + 0.1 + i * 0.18, 31.0), m, rot=ry(random.uniform(-14, 14)), bevel=0.02)
g.prop("Mug", F, (0.9, 1.0, 0.9), (-23.2, 4.5, 35.0), "mug", cyl=True, bevel=0.1)
g.prop("MugHandle", F, (0.15, 0.6, 0.5), (-22.65, 4.5, 35.0), "mug", bevel=0.05, collide=False)
g.prop("Remote", F, (0.7, 0.25, 2.2), (-24.6, 4.12, 31.4), "black", rot=ry(24), bevel=0.06)
for i in range(6):
    g.prop(f"RemoteKey{i}", F, (0.16, 0.06, 0.16), (-24.6 + (i % 2) * 0.22 - 0.11, 4.27, 31.0 + (i // 2) * 0.4), "grey", rot=ry(24), bevel=0.02, collide=False)
g.prop("Bowl", F, (2.0, 0.7, 2.0), (-22.8, 4.35, 31.0), "pot", cyl=True, bevel=0.2)
# Seconde table basse (gigogne), plus loin : dessous et dessus.
g.prop("NestTop", F, (5.0, 0.3, 4.0), (-26.0, 2.75, 45.5), "wood_light", bevel=0.06)
for i, (lx, lz) in enumerate(((-28.3, 43.7), (-28.3, 47.3), (-23.7, 43.7), (-23.7, 47.3))):
    g.prop(f"NestLeg{i}", F, (0.35, 2.6, 0.35), (lx, 1.3, lz), "wood_dark")
g.prop("Coaster", F, (1.0, 0.08, 1.0), (-25.0, 2.94, 45.0), "wood_dark", cyl=True, collide=False)

# ------------------------------------------------------------------ meuble TV, télévision, consoles, box internet
# Meuble bas x[-14,5 ; -10,5], z[27 ; 41], dessus 5,0 : niches ouvertes (consoles, câbles).
g.prop("TvStandTop", F, (4.0, 0.4, 14.0), (-12.5, 4.8, 34.0), "wood_dark", bevel=0.06)
g.prop("TvStandBottom", F, (4.0, 0.4, 14.0), (-12.5, 0.6, 34.0), "wood_dark", bevel=0.06)
g.prop("TvStandBack", F, (0.3, 4.6, 14.0), (-10.65, 2.7, 34.0), "wood_dark", bevel=0.03)
for i, z in enumerate((27.2, 34.0, 40.8)):
    g.prop(f"TvStandSide{i}", F, (4.0, 3.8, 0.4), (-12.5, 2.7, z), "wood_dark", bevel=0.03)
# Niche sud fermée par une porte vitrée fumée (la règle arrive face à elle).
g.prop("TvStandDoor", F, (0.1, 3.8, 6.4), (-14.48, 2.7, 37.4), "glass_dark", bevel=0.02)
g.prop("TvStandDoorKnob", F, (0.15, 0.6, 0.15), (-14.56, 2.9, 34.9), "steel", bevel=0.03, collide=False)
g.prop("ConsoleA", F, (3.0, 0.8, 2.6), (-12.3, 1.2, 30.4), "console", bevel=0.1)
g.prop("ConsoleALed", F, (0.05, 0.12, 0.6), (-13.82, 1.2, 30.4), "led_blue", bevel=0.0, collide=False)
g.prop("ConsoleB", F, (2.6, 1.6, 2.2), (-12.3, 1.6, 37.4), "white", bevel=0.2)
for i in range(4):
    g.prop(f"GameCase{i}", F, (2.0, 2.6, 0.25), (-12.4, 2.1, 38.9 + i * 0.32), ("pad_red", "pad_blue", "mag_c", "black")[i], bevel=0.02)
g.prop("TvFoot", F, (2.4, 0.3, 4.0), (-12.3, 5.15, 34.0), "black", bevel=0.05)
g.prop("TvNeck", F, (0.4, 1.4, 0.8), (-12.0, 5.9, 34.0), "black", bevel=0.05)
g.prop("Tv", F, (0.5, 7.0, 12.0), (-12.0, 9.8, 34.0), "black", bevel=0.1)
g.prop("TvScreen", F, (0.04, 6.4, 11.4), (-12.27, 9.8, 34.0), "screen", bevel=0.0, collide=False)
# Manettes (sur le sol, oubliées) et câbles.
g.prop("PadA", F, (1.6, 0.4, 1.0), (-16.6, 0.2, 29.0), "pad", rot=ry(30), bevel=0.15)
g.prop("PadB", F, (1.6, 0.4, 1.0), (-17.4, 0.2, 39.4), "pad_red", rot=ry(-50), bevel=0.15)
for i in range(5):
    g.prop(f"Cable{i}", D, (0.12, 0.12, 2.6), (-14.8 - i * 0.4, 0.06, 30.0 + i * 2.2), "cable", rot=ry(random.uniform(-40, 40)), bevel=0.04, collide=False, shadow=False)
# Box internet : petit boîtier blanc, voyants qui clignotent (souvenir n° 5, scan obligatoire).
g.prop("InternetBox", F, (1.6, 2.0, 3.0), (-11.6, 6.0, 39.2), "box_case", bevel=0.15)
g.prop("BoxLedA", F, (0.04, 0.14, 0.14), (-12.42, 6.6, 38.4), "led_green", bevel=0.0, collide=False)
g.prop("BoxLedB", F, (0.04, 0.14, 0.14), (-12.42, 6.6, 38.8), "led_green", bevel=0.0, collide=False)
g.prop("BoxLedC", F, (0.04, 0.14, 0.14), (-12.42, 6.6, 39.2), "led_blue", bevel=0.0, collide=False)
s.node("BoxGlow", "OmniLight3D", F, f"transform = {tf(I, (-12.8, 6.6, 38.8))}\nlight_color = Color(0.4, 1, 0.6, 1)\nlight_energy = 0.35\nomni_range = 1.6")
s.node("BoxFocus", "Marker3D", F, f"transform = {tf(I, (-12.0, 6.2, 39.2))}\nscript = {g.FOCUS}\nid = &\"internet_box\"\nradius = 0.9\nprofile = {MEMPROF}\nmemory = {MEMORY5}\nfacing = Vector3(-1, 0, 0)\nthought_icons = Array[StringName]([&\"eye\", &\"energy\"])")

# ------------------------------------------------------------------ bascule (règle sur rouleau de ruban adhésif)
# Au repos, l'extrémité est (B, près du meuble TV) touche le sol et l'extrémité ouest (A)
# est en l'air. Nin0 est trop léger pour la faire basculer ; Nathan monte sur la règle,
# passe le point d'appui : elle bascule, il s'assoit sur A et la tient, B se lève à 4,4.
s.node("Seesaw", "Node3D", ".", f"transform = {tf(I, (-20.0, 0.0, 40.0))}\nscript = {SEESAW}")
g.prop("Fulcrum", "Seesaw", (2.1, 1.6, 2.1), (0.0, 1.05, 0.0), "tape", cyl=True, rot=rx(90), bevel=0.2)
g.prop("FulcrumHole", "Seesaw", (1.0, 1.62, 1.0), (0.0, 1.05, 0.0), "wood_dark", cyl=True, rot=rx(90), bevel=0.0, collide=False)
s.node("Pivot", "Node3D", "Seesaw", f"transform = {tf(I, (0.0, 2.1, 0.0))}")
s.node("Board", "AnimatableBody3D", "Seesaw/Pivot", "collision_mask = 0")
box_shape(s, "Shape", "Seesaw/Pivot/Board", (11.6, 0.24, 1.4), (0.0, 0.12, 0.0))
g.prop("Ruler", "Seesaw/Pivot/Board", (11.6, 0.24, 1.4), (0.0, 0.12, 0.0), "ruler", bevel=0.03, collide=False)
for i in range(12):
    g.prop(f"Tick{i}", "Seesaw/Pivot/Board", (0.04, 0.02, 0.5 if i % 2 else 0.8), (-5.5 + i * 1.0, 0.25, -0.3), "ink", bevel=0.0, collide=False, shadow=False)
g.marker("HoldSpot", "Seesaw", (-5.2, 0.0, 0.0), 90)
g.marker("ClimbSpot", "Seesaw", (4.6, 0.0, 1.3), -90)
g.interactable("SeesawInspect", "Seesaw", (3.0, 2.0, 2.6), (-5.0, 1.0, 0.0), "Examiner la règle")
s.node("SeesawFocus", "Marker3D", "Seesaw", f"transform = {tf(I, (0.0, 1.8, 0.0))}\nscript = {g.FOCUS}\nid = &\"seesaw\"\nradius = 1.0\nprofile = {LANDMARK}\nthought_icons = Array[StringName]([&\"eye\", &\"up\"])")

# ------------------------------------------------------------------ bureau, ordinateur, chaise (mur nord, à l'est de la porte)
g.prop("DeskTop", F, (12.0, 0.4, 6.0), (-18.5, 7.3, 16.0), "wood", bevel=0.06)
for i, (lx, lz) in enumerate(((-24.2, 13.3), (-24.2, 18.7), (-12.8, 13.3), (-12.8, 18.7))):
    g.prop(f"DeskLeg{i}", F, (0.45, 7.1, 0.45), (lx, 3.55, lz), "steel")
g.prop("PcTower", F, (2.0, 5.0, 4.4), (-14.6, 2.5, 15.6), "black", bevel=0.1)
g.prop("PcLed", F, (0.05, 0.15, 0.15), (-14.6, 4.4, 17.82), "led_blue", bevel=0.0, collide=False)
g.prop("Bin", F, (2.0, 2.4, 2.0), (-11.0, 1.2, 20.2), "grey", cyl=True, bevel=0.1)
g.crumpled_paper("BinPaper", F, (-11.0, 2.4, 20.2), 0.35, ["paper"])
g.prop("MonitorFoot", F, (2.2, 0.2, 1.6), (-18.5, 7.6, 14.2), "black", bevel=0.05)
g.prop("MonitorNeck", F, (0.4, 1.4, 0.4), (-18.5, 8.3, 14.0), "black", bevel=0.05)
g.prop("Monitor", F, (7.0, 4.2, 0.35), (-18.5, 10.8, 13.9), "black", bevel=0.08)
g.prop("MonitorScreen", F, (6.6, 3.8, 0.04), (-18.5, 10.8, 14.09), "screen", bevel=0.0, collide=False)
g.prop("Keyboard", F, (5.0, 0.25, 1.6), (-18.6, 7.62, 16.6), "grey", bevel=0.05)
g.prop("Mouse", F, (0.6, 0.3, 0.9), (-14.8, 7.65, 16.8), "grey", bevel=0.15, collide=False)
g.prop("PenPot", F, (0.9, 1.4, 0.9), (-23.0, 8.2, 14.4), "steel", cyl=True, bevel=0.05)
g.prop("DeskLampBase", F, (1.2, 0.2, 1.2), (-22.6, 7.6, 18.2), "black", cyl=True, bevel=0.05)
g.prop("DeskLampArm", F, (0.18, 4.0, 0.18), (-22.0, 9.4, 17.8), "black", rot=rz(-20), bevel=0.02, collide=False)
g.prop("DeskLampHead", F, (1.6, 0.8, 1.0), (-21.0, 11.2, 17.4), "lamp", rot=rz(30), bevel=0.2, collide=False)
# Chaise de bureau (assise 4,8), roulée à l'écart du bureau.
g.prop("ChairSeat", F, (4.0, 0.6, 4.0), (-18.4, 4.5, 23.0), "chair", cyl=True, bevel=0.2)
g.prop("ChairBack", F, (3.6, 4.4, 0.5), (-18.4, 7.4, 25.0), "chair", rot=rx(-8), bevel=0.3)
g.prop("ChairColumn", F, (0.5, 3.6, 0.5), (-18.4, 2.4, 23.0), "steel", cyl=True)
for i in range(5):
    a = math.tau * i / 5
    g.prop(f"ChairLeg{i}", F, (2.2, 0.3, 0.35), (-18.4 + math.cos(a) * 1.1, 0.5, 23.0 + math.sin(a) * 1.1), "black", rot=ry(-math.degrees(a)), bevel=0.05, collide=False)
    g.prop(f"Caster{i}", F, (0.4, 0.4, 0.4), (-18.4 + math.cos(a) * 2.1, 0.2, 23.0 + math.sin(a) * 2.1), "black", cyl=True, rot=rx(90), collide=False)

# ------------------------------------------------------------------ rangements (mur sud, à l'ouest)
# Meuble à casiers : deux rangées ouvertes vers le nord, dessus à 9,0. Panier au sol.
SX0, SX1 = -44.4, -32.0
g.prop("CubbyTop", F, (SX1 - SX0, 0.4, 3.4), ((SX0 + SX1) / 2, 8.8, 55.3), "white", bevel=0.05)
g.prop("CubbyMid", F, (SX1 - SX0, 0.4, 3.4), ((SX0 + SX1) / 2, 4.5, 55.3), "white", bevel=0.05)
g.prop("CubbyBase", F, (SX1 - SX0, 0.4, 3.4), ((SX0 + SX1) / 2, 0.2, 55.3), "white", bevel=0.05)
g.prop("CubbyBack", F, (SX1 - SX0, 9.0, 0.2), ((SX0 + SX1) / 2, 4.5, 56.9), "white", bevel=0.02)
for i in range(4):
    x = SX0 + 0.2 + i * (SX1 - SX0 - 0.4) / 3
    g.prop(f"CubbySide{i}", F, (0.4, 9.0, 3.4), (x, 4.5, 55.3), "white", bevel=0.03)
g.prop("BoxInCubby0", F, (3.4, 3.4, 2.8), (-42.3, 2.1, 55.4), "basket", bevel=0.2)
g.prop("BoxInCubby1", F, (3.4, 3.4, 2.8), (-34.1, 6.4, 55.4), "crate_lid", bevel=0.2)
g.prop("BooksInCubby", F, (2.6, 3.0, 2.4), (-38.2, 2.0, 55.6), "mag_b", bevel=0.05)
g.prop("FloorBasket", F, (3.0, 2.0, 2.4), (-38.0, 1.0, 52.4), "basket", bevel=0.3)

# ------------------------------------------------------------------ porte-fenêtre lumineuse, étendoir
g.prop("WindowSkyA", D, (8.4, 19.2, 0.05), (-7.4, 10.2, 57.02), "sky", bevel=0.0, collide=False, shadow=False)
g.prop("WindowSkyB", D, (8.4, 19.2, 0.05), (3.4, 10.2, 57.02), "sky", bevel=0.0, collide=False, shadow=False)
g.decal("SunPatch", D, (12.0, 16.0), (-6.0, 0.02, 47.0), "sunpatch", mul(rx(-90), rz(12)))
# Étendoir (en A) : montants, barres basses et hautes ; serviettes, chaussettes.
RX0, RX1, RZ = -10.0, -3.0, 50.0
for i, x in enumerate((RX0, RX1)):
    for k, dz in enumerate((-2.6, 2.6)):
        g.prop(f"RackLeg{i}{k}", F, (0.18, 9.6, 0.18), (x, 4.6, RZ + dz * 0.55), "steel", rot=rx(15 if dz < 0 else -15), bevel=0.02, collide=False)
g.prop("RackLow", F, (RX1 - RX0, 0.3, 1.2), ((RX0 + RX1) / 2, 6.1, RZ - 1.3), "steel", bevel=0.04)
g.prop("RackHigh", F, (RX1 - RX0, 0.3, 1.6), ((RX0 + RX1) / 2, 9.3, RZ), "steel", bevel=0.04)
for i in range(5):
    g.prop(f"RackBar{i}", F, (RX1 - RX0, 0.1, 0.1), ((RX0 + RX1) / 2, 7.6, RZ - 1.6 + i * 0.8), "steel", bevel=0.0, collide=False)
g.prop("TowelA", F, (2.6, 4.0, 0.12), (-8.4, 5.6, RZ + 0.4), "towel", bevel=0.05, collide=False)
g.prop("TowelB", F, (2.2, 3.2, 0.12), (-4.8, 6.0, RZ + 0.8), "towel_b", bevel=0.05, collide=False)
for i in range(3):
    g.prop(f"Sock{i}", F, (0.6, 1.4, 0.1), (-6.6 + i * 0.8, 6.6, RZ - 0.4), "sock", bevel=0.05, collide=False)
g.prop("LaundryBasket", F, (3.0, 3.0, 2.6), (-12.2, 1.5, 51.0), "basket", bevel=0.3)
g.prop("LaundryTop", F, (2.6, 0.6, 2.2), (-12.2, 3.1, 51.0), "towel_b", bevel=0.25, collide=False)

# ------------------------------------------------------------------ encombrement : la seconde partie du salon reste hors d'atteinte
# Dans le prolongement du meuble de séparation (x 0, z 12,6 à 28,6) jusqu'à la porte-fenêtre.
for i, (z0, z1) in enumerate(((28.6, 34.4), (34.4, 40.2), (47.0, 52.6))):
    for k in range(3):
        g.prop(f"Crate{i}_{k}", C, (4.0, 5.4, z1 - z0 - 0.1), (2.2, 2.75 + k * 5.6, (z0 + z1) / 2), "crate", bevel=0.15)
        g.prop(f"CrateLid{i}_{k}", C, (4.1, 0.3, z1 - z0), (2.2, 5.6 + k * 5.6, (z0 + z1) / 2), "crate_lid", bevel=0.05, collide=False)
# Paravent replié (zigzag) entre les piles.
for i in range(5):
    g.prop(f"Screen{i}", C, (0.2, 17.0, 1.6), (0.9 + (0.35 if i % 2 else -0.35), 8.5, 40.9 + i * 1.3), "screen_panel", rot=ry(28 if i % 2 else -28), bevel=0.04)
g.collider("ScreenCol", C, (1.6, 17.0, 6.8), (0.9, 8.5, 43.6))
# Grande plante devant la porte-fenêtre (pot, feuillage dense).
g.prop("PlantPot", C, (4.4, 6.0, 4.4), (2.0, 3.0, 54.8), "pot", cyl=True, bevel=0.3)
g.prop("PlantTrunk", C, (0.6, 10.0, 0.6), (2.0, 11.0, 54.8), "wood_dark", cyl=True, collide=False)
for i in range(16):
    g.sphere(f"PlantLeaf{i}", C, 0.8, (2.0 + random.uniform(-2.2, 2.2), random.uniform(8.0, 17.5), 54.8 + random.uniform(-2.0, 2.0)), "leaf" if i % 3 else "leaf_dark", (1.6, 0.5, 1.0))
g.collider("PlantCol", C, (4.4, 17.0, 0), (2.0, 8.5, 54.8), cyl=True)

# ------------------------------------------------------------------ découvertes (traces du lieu, sans texte révélateur)
g.group("Discoveries")
def discovery(name, did, title, icons, text, cicons, ctext, size, pos):
    icon_list = ", ".join(f'&"{i}"' for i in icons)
    concl = ", ".join(f'&"{i}"' for i in cicons)
    res = s.sub("Resource", f"Disc_{name}", f"script = {DISC}\nid = &\"{did}\"\ntitle = \"{title}\"\nthought_icons = Array[StringName]([{icon_list}])\nthought_text = \"{text}\"\nconclusion_icons = Array[StringName]([{concl}])\nconclusion_text = \"{ctext}\"")
    shape = s.sub("BoxShape3D", f"DiscShape_{name}", f"size = {v3(size)}")
    s.node(name, "Area3D", "Discoveries", f"transform = {tf(I, pos)}\ncollision_layer = 8\ncollision_mask = 0\nmonitoring = false\nscript = {EXAM}\ndiscovery = {res}")
    s.node("Shape", "CollisionShape3D", f"Discoveries/{name}", f"shape = {shape}")
discovery("RemoteSpot", "salon_remote", "Télécommande", ["eye", "question"], "Tant de boutons…", ["robot", "ellipsis"], "", (2.6, 1.4, 3.0), (-24.6, 4.6, 31.4))
discovery("PadSpot", "salon_pad", "Manette oubliée", ["eye", "gear"], "Pour jouer ?", ["question"], "", (2.4, 1.2, 2.0), (-16.6, 0.6, 29.0))
discovery("MugSpot", "salon_mug", "Tasse", ["eye", "sun"], "Vide. Et froide.", ["ellipsis"], "", (2.0, 1.6, 2.0), (-23.2, 5.0, 35.0))
discovery("ClutterSpot", "salon_clutter", "Bacs empilés", ["eye", "up"], "Tout est entassé ici.", ["cross"], "Impossible de passer.", (2.6, 3.0, 12.0), (-1.4, 1.5, 36.0))

# ------------------------------------------------------------------ ressources
g.group("Pickups")
g.pickup("PlasticUnderSofa", "Pickups", "s_pl_under_sofa", (-39.0, 0.05, 36.0), 1, 3, 180.0)
g.pickup("PlasticCoffee", "Pickups", "s_pl_coffee", (-26.0, 4.05, 34.6), 1, 2, 120.0)
g.pickup("PlasticTvFloor", "Pickups", "s_pl_tv_floor", (-16.0, 0.05, 41.6), 1, 3, 60.0)
g.pickup("PlasticDesk", "Pickups", "s_pl_desk", (-13.8, 7.55, 18.0), 1, 3, 0.0)
g.pickup("FilamentCubby", "Pickups", "s_fil_cubby", (-42.4, 4.75, 55.0), 0, 1, 0.0)
g.pickup("FilamentRack", "Pickups", "s_fil_rack", (-6.5, 9.5, RZ), 0, 2, 0.0)
g.pickup("FilamentNest", "Pickups", "s_fil_nest", (-26.0, 2.95, 46.4), 0, 1, 0.0)

# ------------------------------------------------------------------ repères
g.group("Markers")
g.marker("SalonEntry", "Markers", (-37.6, 0.05, 15.0), 180)
g.marker("NathanSpot", "Markers", (-38.2, 0.0, 19.6), 0)
g.marker("NathanSafe", "Markers", (-26.0, 0.0, 33.0), 0)
g.marker("RaiderNest", "Markers", (-39.5, 0.0, 30.0), 90)
g.marker("TvTop", "Markers", (-12.6, 5.05, 31.0), 90)
g.marker("CoffeeTop", "Markers", (-26.0, 4.05, 33.0), 90)

# ------------------------------------------------------------------ éclairage : porte-fenêtre lumineuse, lampe chaude
s.node("WindowSun", "SpotLight3D", ".", f"transform = {tf(mul(ry(180), rx(-35)), (-3.0, 20.0, 58.5))}\nlight_color = Color(1, 0.93, 0.78, 1)\nlight_energy = 4.0\nshadow_enabled = true\nspot_range = 50.0\nspot_angle = 48.0\nspot_attenuation = 0.7")
s.node("WindowFill", "OmniLight3D", ".", f"transform = {tf(I, (-4.0, 12.0, 52.0))}\nlight_color = Color(0.9, 0.95, 1, 1)\nlight_energy = 0.8\nomni_range = 22.0")
s.node("RoomFill", "OmniLight3D", ".", f"transform = {tf(I, (-24.0, 20.0, 30.0))}\nlight_color = Color(1, 0.94, 0.86, 1)\nlight_energy = 0.55\nomni_range = 36.0\nomni_attenuation = 0.9")
s.node("DeskLight", "OmniLight3D", ".", f"transform = {tf(I, (-20.6, 10.4, 17.4))}\nlight_color = Color(1, 0.84, 0.58, 1)\nlight_energy = 0.6\nomni_range = 7.0")
dust_mesh = s.sub("QuadMesh", "DustQuad", "size = Vector2(0.03, 0.03)")
dust_mat = s.sub("StandardMaterial3D", "DustMat", "transparency = 1\nshading_mode = 0\nbillboard_mode = 1\nalbedo_color = Color(1, 0.95, 0.82, 0.55)")
s.node("DustMotes", "CPUParticles3D", ".", f"transform = {tf(I, (-6.0, 10.0, 48.0))}\nmaterial_override = {dust_mat}\namount = 70\nlifetime = 9.0\npreprocess = 9.0\nmesh = {dust_mesh}\nemission_shape = 3\nemission_box_extents = Vector3(6, 6, 6)\ndirection = Vector3(0.2, 0.1, -0.3)\nspread = 180.0\ngravity = Vector3(0, -0.02, 0)\ninitial_velocity_min = 0.02\ninitial_velocity_max = 0.08")
g.write(sys.argv[1])
print("salon ok")
