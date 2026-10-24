"""Cuisine (zone 4) jouable, lot 6 : cuisine compacte en L d'après le croquis.
Intérieur x[-75, -45.6], z[0, 57], plafond 24 (1 u = 10 cm). Porte du sas au mur est
(z 2,5 à 10,6), porte du salon fermée au mur est (z 26 à 37).
Croquis → monde : « gauche » (porte) = est, « haut » (cuisinière) = sud (z 57),
« droite » (évier, fenêtre) = ouest (x -75, façade).
Usage : gen_kitchen.py <sortie.tscn>"""
import sys
sys.path.insert(0, sys.path[0])
from gen_common import *
random.seed(6)
g = Gen("KitchenZone", "res://scripts/zones/kitchen_zone.gd")
s = g.s
SPIDER = s.ext_res("Script", "res://scripts/creatures/kitchen_spider.gd")
ROACH = s.ext_res("Script", "res://scripts/creatures/kitchen_roach.gd")
EXAM = s.ext_res("Script", "res://scripts/interaction/examinable.gd")
FLEA = s.ext_res("Script", "res://scripts/creatures/kitchen_flea.gd")
MEMORY3 = s.ext_res("Resource", "res://assets/memories/memory_03.tres")
MEMPROF = s.ext_res("Resource", "res://assets/observation/memory_detail.tres")
DISC = s.ext_res("Script", "res://scripts/discovery/discovery_data.gd")
WARENA = s.ext_res("Script", "res://scripts/zones/wasp_arena.gd")

# ------------------------------------------------------------------ matériaux
g.mat("cabinet", (0.9, 0.89, 0.86), 0.5)
g.mat("cabinet_shade", (0.8, 0.79, 0.76), 0.6)
g.mat("handle", (0.06, 0.06, 0.07), 0.35, 0.4)
g.mat("worktop", (0.4, 0.48, 0.55), 0.42)
g.mat("tile", (0.6, 0.61, 0.62), 0.35)
g.mat("grout", (0.42, 0.43, 0.44), 0.9)
g.mat("steel", (0.74, 0.76, 0.78), 0.25, 0.8)
g.mat("steel_dark", (0.45, 0.47, 0.5), 0.3, 0.8)
g.mat("hob", (0.1, 0.1, 0.11), 0.3, 0.2)
g.mat("grate", (0.16, 0.16, 0.17), 0.6, 0.5)
g.mat("knob", (0.2, 0.2, 0.22), 0.5)
g.mat("plank", (0.6, 0.46, 0.32), 0.9)
g.mat("wood", (0.66, 0.5, 0.34), 0.7)
g.mat("wood_dark", (0.36, 0.26, 0.18), 0.8)
g.mat("bin", (0.07, 0.07, 0.08), 0.4, 0.3)
g.mat("cardboard", (0.66, 0.5, 0.32), 0.95)
g.mat("cardboard_dark", (0.5, 0.37, 0.23), 0.95)
g.mat("cereal", (0.85, 0.62, 0.2), 0.8)
g.mat("cereal_band", (0.3, 0.45, 0.7), 0.8)
g.mat("towel", (0.82, 0.3, 0.26), 1.0)
g.mat("towel_stripe", (0.95, 0.92, 0.86), 1.0)
g.mat("plate", (0.95, 0.95, 0.93), 0.3)
g.mat("plate_blue", (0.55, 0.68, 0.82), 0.3)
g.mat("glass_jar", (0.8, 0.88, 0.85), 0.1, extra="transparency = 1\nalbedo_color = Color(0.8, 0.88, 0.85, 0.45)")
g.mat("pot", (0.72, 0.38, 0.24), 0.9)
g.mat("soil", (0.25, 0.18, 0.12), 1.0)
g.mat("leaf", (0.32, 0.5, 0.24), 0.8)
g.mat("leaf_dry", (0.55, 0.5, 0.28), 0.9)
g.mat("sprout", (0.85, 0.85, 0.65), 0.8)
g.mat("potato", (0.62, 0.48, 0.3), 0.9)
g.mat("crumb", (0.82, 0.64, 0.36), 0.9)
g.mat("peel", (0.56, 0.42, 0.22), 0.9)
g.mat("sponge", (0.95, 0.8, 0.25), 1.0)
g.mat("sponge_green", (0.3, 0.6, 0.35), 1.0)
g.mat("pipe", (0.86, 0.86, 0.84), 0.4)
g.mat("bottle", (0.3, 0.55, 0.8), 0.3)
g.mat("bottle_b", (0.85, 0.85, 0.3), 0.3)
g.mat("magnet_a", (0.95, 0.85, 0.2), 0.5)
g.mat("magnet_b", (0.85, 0.25, 0.25), 0.5)
g.mat("magnet_c", (0.25, 0.6, 0.35), 0.5)
g.mat("magnet_d", (0.3, 0.45, 0.85), 0.5)
g.mat("paper", (0.95, 0.93, 0.86), 0.9)
g.mat("ink", (0.3, 0.3, 0.38), 0.9)
g.mat("cable", (0.1, 0.1, 0.1), 0.6)
g.mat("mug", (0.25, 0.5, 0.55), 0.4)
g.mat("tin", (0.6, 0.2, 0.18), 0.4, 0.5)
g.mat("frame", (0.92, 0.91, 0.88), 0.5)
g.mat("husk", (0.5, 0.35, 0.2), 0.7, extra="transparency = 1\nalbedo_color = Color(0.5, 0.35, 0.2, 0.75)")
g.mat("blocker", (1.0, 0.3, 0.2), 1.0, extra="transparency = 1\nalbedo_color = Color(1, 0.3, 0.2, 0.0)")
g.mat("sky", (0.86, 0.93, 1.0), 1.0, extra="shading_mode = 0\nemission_enabled = true\nemission = Color(0.86, 0.93, 1, 1)\nemission_energy_multiplier = 1.4")
g.mat("foliage", (0.36, 0.52, 0.34), 1.0, extra="shading_mode = 0\nalbedo_color = Color(0.36, 0.52, 0.34, 1)")
g.mat("silk", (0.93, 0.93, 0.9), 1.0, extra="shading_mode = 0\ntransparency = 1\nalbedo_color = Color(0.93, 0.93, 0.9, 0.55)\ncull_mode = 2")
g.mat("silk_sheet", (0.9, 0.9, 0.88), 1.0, extra="shading_mode = 0\ntransparency = 1\nalbedo_color = Color(0.9, 0.9, 0.88, 0.1)\ncull_mode = 2")
g.mat("cocoon", (0.94, 0.93, 0.88), 0.9)
for k, a, col in (("dust", 0.3, (0.55, 0.52, 0.46)), ("stain", 0.35, (0.32, 0.24, 0.16)), ("mold", 0.4, (0.25, 0.3, 0.2)), ("shadow", 0.5, (0.02, 0.02, 0.03))):
    g.mat(k, col, 1.0, extra=f"transparency = 1\nalbedo_color = Color({col[0]}, {col[1]}, {col[2]}, {a})\ncull_mode = 2")

g.group("Furniture")
g.group("Appliances")
g.group("Decor")
g.group("Webs")
F, A, D, W = "Furniture", "Appliances", "Decor", "Webs"

# ------------------------------------------------------------------ outils
def run_cabinet(name, x0, x1, z0, z1, front, door_w=6.0, top=8.6, worktop=True, skip=()):
    """Meuble bas : caisson surélevé (vide de 1 u dessous : passages des cafards), pieds,
    portes blanches et poignées noires, plan de travail gris-bleu."""
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    g.prop(f"{name}Carcass", F, (x1 - x0, top - 1.0, z1 - z0), (cx, (top + 1.0) / 2, cz), "cabinet", bevel=0.04)
    if worktop:
        if front == "-z":
            g.prop(f"{name}Top", F, (x1 - x0, 0.4, z1 - z0 + 0.35), (cx, top + 0.2, cz - 0.175), "worktop", bevel=0.05)
        else:
            g.prop(f"{name}Top", F, (x1 - x0 + 0.35, 0.4, z1 - z0), (cx + 0.175, top + 0.2, cz), "worktop", bevel=0.05)
    # Pieds de réglage (le dessous reste ouvert).
    along = (x0, x1) if front == "-z" else (z0, z1)
    n = max(2, int((along[1] - along[0]) / 5.0) + 1)
    for i in range(n):
        a = along[0] + 0.4 + (along[1] - along[0] - 0.8) * i / (n - 1)
        p = (a, 0.5, z0 + 0.5) if front == "-z" else (x1 - 0.5, 0.5, a)
        g.prop(f"{name}Foot{i}", F, (0.3, 1.0, 0.3), p, "steel_dark", cyl=True, collide=False, shadow=False)
    # Façades : portes (ou tiroirs sous le plan de travail) et poignées.
    count = max(1, round((along[1] - along[0]) / door_w))
    w = (along[1] - along[0]) / count
    for i in range(count):
        if i in skip:
            continue
        a = along[0] + w * (i + 0.5)
        if front == "-z":
            g.prop(f"{name}Door{i}", F, (w - 0.15, 5.6, 0.08), (a, 3.95, z0 - 0.04), "cabinet", bevel=0.03, collide=False)
            g.prop(f"{name}Drawer{i}", F, (w - 0.15, 1.6, 0.08), (a, 7.75, z0 - 0.04), "cabinet", bevel=0.03, collide=False)
            g.prop(f"{name}Handle{i}", F, (w * 0.4, 0.16, 0.16), (a, 7.75, z0 - 0.17), "handle", bevel=0.05, collide=False)
            g.prop(f"{name}Knob{i}", F, (0.16, 1.4, 0.16), (a + w * 0.38, 5.6, z0 - 0.17), "handle", bevel=0.05, collide=False)
        else:
            g.prop(f"{name}Door{i}", F, (0.08, 5.6, w - 0.15), (x1 + 0.04, 3.95, a), "cabinet", bevel=0.03, collide=False)
            g.prop(f"{name}Drawer{i}", F, (0.08, 1.6, w - 0.15), (x1 + 0.04, 7.75, a), "cabinet", bevel=0.03, collide=False)
            g.prop(f"{name}Handle{i}", F, (0.16, 0.16, w * 0.4), (x1 + 0.17, 7.75, a), "handle", bevel=0.05, collide=False)
            g.prop(f"{name}Knob{i}", F, (0.16, 1.4, 0.16), (x1 + 0.17, 5.6, a - w * 0.38), "handle", bevel=0.05, collide=False)

def web(name, center, radius, plane="x", torn=False, rings=3, spokes=8):
    """Toile radiale (fils fins, sans collision) dans le plan x (mur ouest/est) ou z."""
    g.group(name, W)
    path = f"{W}/{name}"
    cx, cy, cz = center
    def pt(angle, r):
        dx, dy = math.cos(angle) * r, math.sin(angle) * r
        return (cx, cy + dy, cz + dx) if plane == "x" else (cx + dx, cy + dy, cz)
    def seg(n, a, b):
        mx, my, mz = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2)
        L = math.dist(a, b)
        if plane == "x":
            ang = math.degrees(math.atan2(b[1] - a[1], b[2] - a[2]))
            rot = rx(-ang)
            size = (0.012, 0.012, L)
        else:
            ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
            rot = rz(ang)
            size = (L, 0.012, 0.012)
        g.prop(n, path, size, (mx, my, mz), "silk", rot=rot, bevel=0.0, collide=False, shadow=False)
    k = 0
    for i in range(spokes):
        if torn and i in (2, 3):
            continue
        ang = math.tau * i / spokes + 0.2
        seg(f"S{k}", (cx, cy, cz), pt(ang, radius)); k += 1
    for r in range(rings):
        rr = radius * (0.35 + 0.6 * r / max(1, rings - 1)) * 0.95
        for i in range(spokes):
            if torn and i in (1, 2, 3, 4) and r > 0:
                continue
            a0 = math.tau * i / spokes + 0.2
            a1 = math.tau * (i + 1) / spokes + 0.2
            seg(f"R{k}", pt(a0, rr), pt(a1, rr)); k += 1
    if torn:
        # Fils arrachés qui pendent.
        for i in range(3):
            a = pt(math.tau * (2 + i * 0.4) / spokes, radius * 0.7)
            seg(f"T{k}", a, (a[0], a[1] - radius * random.uniform(0.4, 0.9), a[2])); k += 1

def sheet_web(name, corner, size, plane="xz"):
    """Toile en nappe (coin sombre, dessous de meuble)."""
    g.decal(name, W, size, corner, "silk_sheet", rx(-90) if plane == "xz" else (ry(90) if plane == "x" else I))

def cocoon(name, parent, pos, length=0.32):
    g.sphere(name, parent, length / 2, pos, "cocoon", (0.6, 1.0, 0.6))
    g.prop(f"{name}Thread", parent, (0.01, 0.5, 0.01), (pos[0], pos[1] + length / 2 + 0.25, pos[2]), "silk", bevel=0.0, collide=False, shadow=False)

def husk(name, parent, pos):
    """Restes stylisés de proie : carapace vide, quelques pattes."""
    g.sphere(name, parent, 0.12, pos, "husk", (0.9, 0.35, 1.4))
    for i in range(3):
        g.prop(f"{name}Leg{i}", parent, (0.015, 0.015, 0.22), (pos[0] + random.uniform(-0.2, 0.2), pos[1] + 0.01, pos[2] + random.uniform(-0.25, 0.25)), "husk", rot=ry(random.uniform(0, 180)), bevel=0.0, collide=False, shadow=False)

def aabb(x0, y, z0, x1, z1, h=0.0):
    return f"AABB({x0:.4g}, {y:.4g}, {z0:.4g}, {x1 - x0:.4g}, {h:.4g}, {z1 - z0:.4g})"

def vecs(points):
    return "PackedVector3Array(" + ", ".join(f"{p[0]:.4g}, {p[1]:.4g}, {p[2]:.4g}" for p in points) + ")"

# ------------------------------------------------------------------ sol, murs (finitions)
# Parquet clair : lames (le sol lui-même vient du blockout).
for i in range(15):
    x = -74.6 + i * 2.0
    g.prop(f"PlankLine{i}", D, (0.04, 0.012, 56.8), (x, 0.006, 28.5), "plank", bevel=0.0, collide=False, shadow=False)
for i in range(22):
    x = -74.0 + (i % 15) * 2.0
    z = random.uniform(2, 55)
    g.prop(f"PlankJoint{i}", D, (2.0, 0.013, 0.04), (x, 0.006, z), "plank", bevel=0.0, collide=False, shadow=False)
# Plinthes (murs est et nord) ; crédence en carreaux gris (mur sud, mur ouest).
g.prop("PlinthNorth", D, (29.4, 0.8, 0.15), (-60.3, 0.4, 0.08), "frame", collide=False)
g.prop("BacksplashSouth", D, (22.0, 5.5, 0.06), (-64.0, 11.75, 56.96), "tile", bevel=0.0, collide=False)
g.prop("BacksplashWestLow", D, (0.06, 1.7, 31.0), (-74.96, 9.85, 35.5), "tile", bevel=0.0, collide=False)
g.prop("BacksplashWestA", D, (0.06, 5.5, 7.0), (-74.96, 11.75, 23.5), "tile", bevel=0.0, collide=False)
for i in range(4):
    g.prop(f"GroutWestV{i}", D, (0.02, 5.5, 0.05), (-74.92, 11.75, 21.0 + i * 2.0), "grout", bevel=0.0, collide=False, shadow=False)
for i in range(5):
    g.prop(f"GroutWestH{i}", D, (0.02, 0.05, 7.0), (-74.92, 9.5 + i * 1.1, 23.5), "grout", bevel=0.0, collide=False, shadow=False)
for i in range(11):
    g.prop(f"GroutSouthV{i}", D, (0.05, 5.5, 0.02), (-74.0 + i * 2.0, 11.75, 56.92), "grout", bevel=0.0, collide=False, shadow=False)
for i in range(5):
    g.prop(f"GroutSouthH{i}", D, (22.0, 0.05, 0.02), (-64.0, 9.5 + i * 1.1, 56.92), "grout", bevel=0.0, collide=False, shadow=False)

# ------------------------------------------------------------------ meubles bas en L
# Rang sud (cuisinière) : x[-75, -53], profondeur z[51, 57].
run_cabinet("SouthA", -75.0, -63.0, 51.0, 57.0, "-z", skip=())
run_cabinet("SouthOven", -63.0, -55.0, 51.0, 57.0, "-z", door_w=8.0, skip=(0,))
run_cabinet("SouthB", -55.0, -52.8, 51.0, 57.0, "-z", door_w=2.2)
# Four sous la plaque : porte vitrée sombre, poignée-barre.
g.prop("OvenDoor", A, (6.0, 5.6, 0.12), (-59.0, 4.4, 50.94), "hob", bevel=0.05, collide=False)
g.prop("OvenWindow", A, (4.2, 2.6, 0.04), (-59.0, 4.6, 50.86), "steel_dark", bevel=0.02, collide=False)
g.prop("OvenHandle", A, (0.22, 5.0, 0.22), (-59.0, 7.55, 50.7), "steel", cyl=True, rot=rz(90), collide=False)
for i in range(4):
    g.prop(f"StoveKnob{i}", A, (0.4, 0.3, 0.4), (-61.6 + i * 1.6, 8.15, 50.8), "knob", cyl=True, rot=rx(90), collide=False)
# Rang ouest (évier, égouttoir) : x[-75, -69], z[20, 51] ; meuble sous l'évier à part.
run_cabinet("WestA", -75.0, -69.0, 20.0, 28.0, "+x")
run_cabinet("WestB", -75.0, -69.0, 38.0, 51.0, "+x")

# Plaque de cuisson (gaz) : 4 brûleurs et grilles, poêle oubliée.
g.prop("Hob", A, (6.2, 0.06, 5.0), (-59.0, 9.03, 53.8), "hob", bevel=0.02, collide=False)
for i, (bx, bz) in enumerate(((-61.4, 52.6), (-56.6, 52.6), (-61.4, 55.2), (-56.6, 55.2))):
    g.prop(f"Burner{i}", A, (1.0, 0.18, 1.0), (bx, 9.1, bz), "steel_dark", cyl=True, collide=False)
    g.prop(f"GrateA{i}", A, (2.0, 0.12, 0.12), (bx, 9.3, bz), "grate", bevel=0.02, collide=False)
    g.prop(f"GrateB{i}", A, (0.12, 0.12, 2.0), (bx, 9.3, bz), "grate", bevel=0.02, collide=False)
g.prop("Pan", A, (2.4, 0.6, 2.4), (-56.6, 9.6, 55.2), "steel_dark", cyl=True, bevel=0.1)
g.prop("PanHandle", A, (0.25, 0.2, 2.6), (-56.6, 9.8, 53.0), "hob", bevel=0.05, collide=False)
# Hotte et sa cheminée jusqu'au plafond (coupe le dessus des placards hauts en deux).
g.prop("Hood", A, (6.0, 1.5, 3.4), (-59.0, 16.75, 55.3), "steel", bevel=0.1)
g.prop("HoodChimney", A, (3.0, 6.5, 2.0), (-59.0, 20.75, 56.0), "steel", bevel=0.05)

# Évier double encastré (deux bacs, fond à 7,0), robinet col-de-cygne, éponges-marches.
# Plan de travail découpé autour des bacs.
g.prop("SinkTopBack", F, (0.8, 0.4, 10.0), (-74.6, 8.8, 33.0), "worktop", bevel=0.04)
g.prop("SinkTopFront", F, (1.15, 0.4, 10.0), (-69.22, 8.8, 33.0), "worktop", bevel=0.04)
g.prop("SinkTopEndA", F, (6.35, 0.4, 0.2), (-71.82, 8.8, 28.1), "worktop", bevel=0.02)
g.prop("SinkTopEndB", F, (6.35, 0.4, 0.2), (-71.82, 8.8, 37.9), "worktop", bevel=0.02)
g.prop("SinkFloor", A, (4.4, 0.2, 9.6), (-72.0, 6.9, 33.0), "steel", bevel=0.02)
for nm, size, pos in (("SinkWallBack", (0.1, 2.0, 9.6), (-74.15, 8.0, 33.0)), ("SinkWallFront", (0.1, 2.0, 9.6), (-69.85, 8.0, 33.0)),
        ("SinkWallA", (4.4, 2.0, 0.1), (-72.0, 8.0, 28.25)), ("SinkWallB", (4.4, 2.0, 0.1), (-72.0, 8.0, 37.75)), ("SinkDivider", (4.4, 2.0, 0.2), (-72.0, 8.0, 33.0))):
    g.prop(nm, A, size, pos, "steel", bevel=0.02)
for i, z in enumerate((30.6, 35.4)):
    g.prop(f"Drain{i}", A, (0.7, 0.04, 0.7), (-72.0, 7.02, z), "steel_dark", cyl=True, collide=False)
# Chaque bac : éponge (7,55), flacon (8,1), brosse (8,6) puis le plan de travail (9,0).
for k, (z0, dz) in enumerate(((31.6, -1.15), (34.0, 1.15))):
    tag = "AB"[k]
    g.prop(f"SpongeStep{tag}", A, (1.3, 0.55, 1.0), (-70.95, 7.28, z0), "sponge", bevel=0.1)
    g.prop(f"SpongeStep{tag}Green", A, (1.3, 0.15, 1.0), (-70.95, 7.62, z0), "sponge_green", bevel=0.05, collide=False)
    g.prop(f"SoapStep{tag}", A, (1.1, 1.1, 0.9), (-70.95, 7.55, z0 + dz), "bottle_b", bevel=0.15)
    g.prop(f"BrushStep{tag}", A, (1.1, 1.6, 0.9), (-70.95, 7.8, z0 + 2 * dz), "bottle", bevel=0.15)
g.prop("FaucetBase", A, (0.6, 0.4, 0.6), (-74.6, 9.2, 33.0), "steel", cyl=True)
g.prop("FaucetNeck", A, (0.25, 3.2, 0.25), (-74.6, 10.8, 33.0), "steel", cyl=True, collide=False)
g.prop("FaucetSpout", A, (0.22, 2.0, 0.22), (-73.7, 12.3, 33.0), "steel", cyl=True, rot=rz(90), collide=False)
g.prop("DirtyMug", A, (1.0, 1.2, 1.0), (-73.2, 7.6, 35.6), "mug", cyl=True, bevel=0.1)
g.decal("SinkStain", A, (2.0, 1.4), (-72.4, 7.015, 31.4), "stain", rx(-90))
g.decal("MoldSink", A, (0.6, 0.5), (-74.08, 8.3, 30.2), "mold", ry(90))
# Meuble sous l'évier : intérieur accessible (porte entrouverte), tuyaux, nid de cafards.
SU = "Furniture/SinkUnit"
g.group("SinkUnit", F)
g.prop("Floor", SU, (5.8, 0.2, 10.0), (-72.1, 1.1, 33.0), "cabinet_shade", bevel=0.02)
g.prop("SideA", SU, (5.8, 5.6, 0.2), (-72.1, 4.0, 28.1), "cabinet", bevel=0.02)
g.prop("SideB", SU, (5.8, 5.6, 0.2), (-72.1, 4.0, 37.9), "cabinet", bevel=0.02)
g.prop("Back", SU, (0.2, 5.6, 10.0), (-74.9, 4.0, 33.0), "cabinet_shade", bevel=0.02)
g.prop("DoorClosed", SU, (0.12, 5.6, 4.9), (-69.0, 4.0, 30.5), "cabinet", bevel=0.03)
g.prop("DoorClosedKnob", SU, (0.16, 1.4, 0.16), (-68.85, 4.6, 32.6), "handle", collide=False)
# Porte entrouverte (pivot côté z 38) : ouverture assez large pour Nin0.
g.prop("DoorAjar", SU, (0.12, 5.6, 4.9), (-66.84, 4.0, 36.8), "cabinet", rot=ry(-62), bevel=0.03)
g.prop("DoorAjarKnob", SU, (0.16, 1.4, 0.16), (-65.1, 4.6, 35.95), "handle", rot=ry(-62), collide=False)
g.prop("DoorStep", SU, (1.0, 0.65, 1.4), (-68.5, 0.33, 34.4), "sponge_green", bevel=0.1)
g.prop("TrapPipe", SU, (0.8, 4.4, 0.8), (-72.5, 4.6, 30.6), "pipe", cyl=True, collide=False)
g.prop("TrapBend", SU, (0.8, 1.4, 0.8), (-72.5, 2.6, 31.6), "pipe", cyl=True, rot=rx(90))
g.prop("PipeOut", SU, (0.7, 4.0, 0.7), (-74.4, 3.0, 32.8), "pipe", cyl=True, rot=rz(90))
g.prop("BottleA", SU, (1.0, 2.8, 1.0), (-73.6, 2.6, 35.0), "bottle", cyl=True, bevel=0.2)
g.prop("BottleB", SU, (0.8, 2.2, 0.8), (-74.0, 2.3, 36.6), "bottle_b", cyl=True, bevel=0.2)
g.prop("OldRag", SU, (1.8, 0.12, 1.6), (-71.0, 1.26, 29.5), "towel", bevel=0.05, collide=False)
for i in range(6):
    g.sphere(f"NestCrumb{i}", SU, 0.08, (-73.6 + random.uniform(-0.6, 0.6), 1.25, 36.4 + random.uniform(-0.6, 0.6)), "crumb")
g.decal("SinkUnitDark", SU, (5.4, 9.6), (-72.1, 1.21, 33.0), "shadow", rx(-90))
# Égouttoir (plateau bas : marche ; les cafards passent dessous).
g.prop("RackTray", A, (3.6, 0.3, 3.2), (-72.6, 9.15, 41.2), "steel_dark", bevel=0.05)
for i in range(5):
    g.prop(f"RackPlate{i}", A, (2.4, 0.1, 2.4), (-73.8 + i * 0.6, 10.4, 41.2), "plate" if i % 2 else "plate_blue", cyl=True, rot=rz(90), collide=False)
g.prop("RackWireA", A, (3.6, 0.06, 0.06), (-72.6, 10.0, 39.7), "steel", bevel=0.0, collide=False)
g.prop("RackWireB", A, (3.6, 0.06, 0.06), (-72.6, 10.0, 42.7), "steel", bevel=0.0, collide=False)
# Pot de basilic : marche vers le rebord de la fenêtre.
g.prop("BasilPot", D, (1.4, 0.6, 1.4), (-73.4, 9.3, 38.7), "pot", cyl=True, bevel=0.1)
g.prop("BasilSoil", D, (1.2, 0.06, 1.2), (-73.4, 9.61, 38.7), "soil", cyl=True, collide=False)
for i in range(5):
    g.sphere(f"BasilLeaf{i}", D, 0.28, (-73.0 + random.uniform(-0.3, 0.3), 9.9 + random.uniform(0, 0.4), 38.7 + random.uniform(-0.4, 0.4)), "leaf" if i < 3 else "leaf_dry", (1.0, 0.5, 1.3))

# Pile de cartons (coin nord-ouest) : route vers le plan de travail (4,6 + 4,4 = 9,0).
# Lot 7 (sans escalade) : caisse 0,7 → carton 3,4 → carton 6,2 → plan de travail 9,0
# (un saut normal, puis trois sauts chargés de hauteurs différentes).
g.prop("Crate", F, (1.6, 0.7, 1.4), (-71.6, 0.35, 15.45), "wood", bevel=0.05)
g.prop("BoxLow", F, (4.4, 3.4, 3.8), (-72.4, 1.7, 18.1), "cardboard", bevel=0.06)
g.prop("BoxLowTape", F, (4.42, 0.1, 0.8), (-72.4, 3.42, 18.1), "cardboard_dark", bevel=0.0, collide=False)
g.prop("BoxHigh", F, (3.0, 2.8, 2.4), (-72.9, 4.8, 18.8), "cardboard_dark", bevel=0.06)
g.prop("BoxHighFlap", F, (2.8, 0.08, 1.0), (-72.9, 6.24, 18.2), "cardboard", rot=rx(-8), bevel=0.0, collide=False)

# Torchon pendu au plan de travail (rang sud) : route d'escalade depuis le sol.
# Torchon pendu à la poignée du four (décor ; l'escalade n'existe plus).
g.prop("TeaTowel", F, (2.2, 7.3, 0.14), (-59.0, 3.95, 50.55), "towel", bevel=0.05)
# Route alternative : packs de bouteilles d'eau, puis tiroir resté ouvert (rang sud).
g.mat("pack_film", (0.75, 0.85, 0.95), 0.1, extra="transparency = 1\nalbedo_color = Color(0.75, 0.85, 0.95, 0.55)")
g.mat("water", (0.55, 0.75, 0.95), 0.05, extra="transparency = 1\nalbedo_color = Color(0.55, 0.75, 0.95, 0.7)")
g.prop("WaterPackA", F, (3.0, 2.6, 2.0), (-66.0, 1.3, 46.6), "pack_film", bevel=0.2)
g.prop("WaterPackB", F, (2.6, 2.4, 1.8), (-66.2, 3.8, 47.9), "pack_film", rot=ry(8), bevel=0.2)
for i in range(6):
    g.prop(f"Bottle{i}", F, (0.8, 2.3, 0.8), (-67.0 + (i % 3) * 0.95, 1.25, 46.15 + (i // 3) * 0.9), "water", cyl=True, bevel=0.2, collide=False)
g.prop("OpenDrawerBottom", F, (3.4, 0.2, 2.6), (-66.0, 6.2, 49.6), "cabinet_shade", bevel=0.02)
g.prop("OpenDrawerFront", F, (3.6, 1.4, 0.12), (-66.0, 6.9, 48.25), "cabinet", bevel=0.03)
g.prop("OpenDrawerHandle", F, (1.4, 0.16, 0.16), (-66.0, 7.0, 48.1), "handle", bevel=0.05, collide=False)
for i, x in enumerate((-67.75, -64.25)):
    g.prop(f"OpenDrawerSide{i}", F, (0.1, 1.4, 2.6), (x, 6.9, 49.6), "cabinet_shade", bevel=0.02)
for i in range(3):
    g.prop(f"Spoon{i}", F, (0.25, 0.06, 1.8), (-67.0 + i * 0.6, 6.34, 49.6), "steel", rot=ry(random.uniform(-15, 15)), bevel=0.03, collide=False)
for i in range(3):
    g.prop(f"TeaTowelStripe{i}", F, (2.24, 0.25, 0.16), (-59.0, 1.4 + i * 0.5, 50.54), "towel_stripe", bevel=0.0, collide=False)
g.prop("TeaTowelFold", F, (2.2, 0.35, 0.5), (-59.0, 7.65, 50.62), "towel", bevel=0.1, collide=False)

# ------------------------------------------------------------------ plan de travail : appareils et objets
# Micro-ondes (coin sud-ouest), cafetière, boîte de céréales, planche, miettes.
g.prop("Microwave", A, (4.2, 3.2, 4.4), (-72.5, 10.6, 54.4), "steel", bevel=0.12)
g.prop("MicrowaveDoor", A, (2.8, 2.4, 0.06), (-73.0, 10.6, 52.17), "hob", bevel=0.02, collide=False)
g.prop("MicrowavePanel", A, (0.9, 2.4, 0.06), (-71.0, 10.6, 52.17), "steel_dark", bevel=0.02, collide=False)
g.prop("CoffeeMachine", A, (2.2, 4.4, 3.0), (-67.1, 11.2, 54.9), "hob", bevel=0.15)
g.prop("CoffeeJug", A, (1.3, 1.6, 1.3), (-67.1, 9.8, 53.4), "glass_jar", cyl=True, bevel=0.1, collide=False)
g.decal("CoffeeStain", A, (1.8, 1.2), (-66.6, 9.012, 52.5), "stain", rx(-90))
# Céréales : escaladable (carton) ; marche vers le flanc du réfrigérateur.
g.prop("CerealBox", A, (1.55, 3.0, 1.6), (-53.62, 10.5, 52.0), "cereal", bevel=0.05)
g.prop("CerealBand", A, (1.57, 0.6, 1.62), (-53.62, 11.0, 52.0), "cereal_band", bevel=0.0, collide=False)
# Étagère aimantée sur le flanc du réfrigérateur (céréales 12 → étagère 15 → dessus 18).
g.prop("MagShelf", A, (1.3, 0.3, 1.8), (-53.25, 14.85, 53.7), "steel_dark", bevel=0.04)
g.prop("MagShelfLip", A, (1.3, 0.35, 0.08), (-53.25, 15.15, 52.84), "steel_dark", bevel=0.02, collide=False)
for i in range(2):
    g.prop(f"MagShelfJar{i}", A, (0.4, 0.7, 0.4), (-53.5 + i * 0.5, 15.35, 54.3), "glass_jar", cyl=True, collide=False)
for i in range(10):
    g.sphere(f"Crumb{i}", D, 0.07, (-55.5 + random.uniform(-1.4, 1.0), 9.04, 52.2 + random.uniform(-1, 1.2)), "crumb")
g.prop("CuttingBoard", A, (3.0, 0.2, 2.0), (-71.8, 9.1, 24.6), "wood", bevel=0.05)
g.prop("BreadEnd", A, (0.9, 0.7, 0.8), (-71.4, 9.55, 24.3), "crumb", bevel=0.25)

# ------------------------------------------------------------------ étagères ouvertes et placards hauts
# Étagère basse (plantes, bocaux) posée sur le plan de travail, contre le mur ouest :
# flanc escaladable (côté nord), dessus à 15. Au-dessus : casier à épices escaladable
# (face est) jusqu'au dessus des placards hauts (21).
SH = "Furniture/Shelf"
g.group("Shelf", F)
g.prop("SideNorth", SH, (3.4, 6.0, 0.3), (-73.3, 12.0, 44.15), "wood", bevel=0.04)
g.prop("SideSouth", SH, (3.4, 6.0, 0.3), (-73.3, 12.0, 51.85), "wood", bevel=0.04)
g.prop("BoardTop", SH, (3.4, 0.3, 8.0), (-73.3, 14.85, 48.0), "wood", bevel=0.04)
g.prop("BoardMid", SH, (3.4, 0.25, 7.4), (-73.3, 12.0, 48.0), "wood", bevel=0.03)
g.prop("BackPanel", SH, (0.1, 6.0, 7.4), (-74.95, 12.0, 48.0), "wood_dark", bevel=0.0, collide=False)
for i, z in enumerate((45.4, 47.4, 49.6)):
    g.prop(f"Jar{i}", SH, (1.0, 1.6, 1.0), (-73.4, 9.8, z), "glass_jar", cyl=True, bevel=0.1)
    g.prop(f"JarLid{i}", SH, (1.04, 0.2, 1.04), (-73.4, 10.7, z), "tin", cyl=True, collide=False)
g.prop("IvyPot", SH, (1.2, 1.0, 1.2), (-73.2, 12.62, 46.0), "pot", cyl=True, bevel=0.1)
for i in range(9):
    g.sphere(f"Ivy{i}", SH, 0.22, (-72.0 + random.uniform(-0.1, 0.2), 12.4 - i * 0.45, 46.0 + random.uniform(-0.5, 0.5)), "leaf", (0.5, 1.0, 1.1))
g.prop("CookBookA", SH, (2.4, 2.0, 0.5), (-73.4, 13.12, 49.4), "magnet_b", bevel=0.05)
g.prop("CookBookB", SH, (2.4, 1.8, 0.45), (-73.4, 13.02, 50.0), "magnet_d", bevel=0.05)
# Bocaux au bord du dessus : on ne peut pas descendre sur le micro-ondes (arrière-plan).
# Casier à épices en deux gradins (lot 7) : dessus de l'étagère 15 → 18,2 → 21.
g.prop("SpiceRack", SH, (2.0, 3.2, 4.0), (-74.0, 16.6, 48.0), "wood_dark", bevel=0.05)
g.prop("SpiceRackHigh", SH, (2.0, 6.0, 3.6), (-74.0, 18.0, 51.8), "wood_dark", bevel=0.05)
for i in range(8):
    g.prop(f"SpiceJar{i}", SH, (0.5, 0.9, 0.5), (-72.85, 15.6 + (i // 4) * 2.6, 46.8 + (i % 4) * 1.8), "glass_jar" if i % 3 else "tin", cyl=True, collide=False)
# Placards hauts (mur sud) : y[14,5 ; 21], profondeur z[53,6 ; 57]. Interrompus par la hotte.
for nm, x0, x1 in (("UpperWest", -75.0, -62.0), ("UpperEast", -56.0, -54.0)):
    cx = (x0 + x1) / 2
    g.prop(f"{nm}Body", F, (x1 - x0, 6.5, 3.4), (cx, 17.75, 55.3), "cabinet", bevel=0.05)
    n = max(1, round((x1 - x0) / 4.0))
    w = (x1 - x0) / n
    for i in range(n):
        a = x0 + w * (i + 0.5)
        g.prop(f"{nm}Door{i}", F, (w - 0.15, 6.2, 0.08), (a, 17.75, 53.56), "cabinet", bevel=0.03, collide=False)
        g.prop(f"{nm}Handle{i}", F, (0.16, 1.4, 0.16), (a + w * 0.38, 15.6, 53.42), "handle", collide=False)
# Dessus des placards : poussière, vieille boîte à biscuits, repaire de l'araignée.
g.decal("CabinetTopDust", D, (12.6, 3.2), (-68.5, 21.01, 55.3), "dust", rx(-90))
g.prop("CookieTin", D, (2.2, 1.4, 2.2), (-64.0, 21.7, 55.6), "tin", cyl=True, bevel=0.1)
g.prop("EastTin", D, (1.2, 1.0, 1.2), (-55.2, 21.5, 56.3), "tin", cyl=True, bevel=0.1)

# ------------------------------------------------------------------ réfrigérateur (coin sud-est), aimants
g.prop("Fridge", A, (6.0, 18.0, 6.4), (-49.6, 9.0, 53.6), "steel", bevel=0.25)
g.prop("FridgeSeam", A, (5.9, 0.08, 0.06), (-49.6, 12.6, 50.38), "steel_dark", bevel=0.0, collide=False)
g.prop("FridgeHandleTop", A, (0.3, 3.0, 0.3), (-47.3, 14.9, 50.2), "handle", collide=False)
g.prop("FridgeHandleLow", A, (0.3, 4.5, 0.3), (-47.3, 9.6, 50.2), "handle", collide=False)
for i, (mx, my, m, sz) in enumerate(((-51.2, 10.6, "magnet_a", (0.6, 0.6)), (-50.0, 11.4, "magnet_b", (0.5, 0.5)), (-48.9, 10.2, "magnet_c", (0.7, 0.4)),
        (-51.6, 7.8, "magnet_d", (0.5, 0.7)), (-49.3, 6.4, "magnet_a", (0.4, 0.4)), (-50.6, 14.4, "magnet_c", (0.5, 0.5)))):
    g.prop(f"Magnet{i}", A, (sz[0], sz[1], 0.12), (mx, my, 50.33), m, bevel=0.05, collide=False)
# Souvenir n° 3 : petite liste manuscrite aimantée (texture volontairement peu lisible :
# Nin0 la déchiffre lui-même). La dernière ligne est rayée.
g.prop("TodoNote", A, (1.6, 2.4, 0.03), (-50.6, 6.0, 50.37), "paper", rot=rz(-4), bevel=0.0, collide=False)
g.prop("TodoMagnet", A, (0.35, 0.35, 0.12), (-50.6, 7.1, 50.33), "magnet_b", bevel=0.05, collide=False)
for i, w in enumerate((0.7, 0.9, 1.25, 1.05, 1.15, 1.0)):
    g.prop(f"TodoLine{i}", A, (w, 0.05, 0.02), (-50.95 + w / 2, 6.8 - i * 0.3, 50.35), "ink", rot=rz(-4 + random.uniform(-2, 2)), bevel=0.0, collide=False, shadow=False)
g.prop("TodoStrike", A, (1.15, 0.035, 0.02), (-50.42, 5.32, 50.345), "ink", rot=rz(-8), bevel=0.0, collide=False, shadow=False)
s.node("TodoFocus", "Marker3D", "Appliances", f"transform = {tf(I, (-50.6, 6.0, 50.25))}\nscript = {g.FOCUS}\nid = &\"todo_note\"\nradius = 0.7\nprofile = {MEMPROF}\nmemory = {MEMORY3}\nfacing = Vector3(0, 0, -1)\nthought_icons = Array[StringName]([&\"eye\", &\"book\"])")
# Flanc ouest : calendrier aimanté (papier) escaladable jusqu'au dessus du réfrigérateur.
g.prop("Calendar", A, (0.16, 2.8, 2.0), (-52.68, 11.6, 51.4), "paper", bevel=0.0, collide=False)
for i in range(4):
    g.prop(f"CalendarLine{i}", A, (0.02, 0.04, 1.8), (-52.77, 10.6 + i * 0.6, 51.4), "ink", bevel=0.0, collide=False, shadow=False)
g.prop("CalendarMagnet", A, (0.12, 0.5, 0.5), (-52.78, 12.9, 51.4), "magnet_b", bevel=0.05, collide=False)
# Dessus : poussière, panier oublié, restes de proies (traces de chasse).
g.decal("FridgeTopDust", D, (5.4, 5.8), (-49.6, 18.01, 53.6), "dust", rx(-90))
g.prop("Basket", D, (2.4, 1.2, 1.8), (-48.4, 18.6, 55.4), "wood", bevel=0.2)
husk("HuskFridge", D, (-50.6, 18.05, 55.6))
husk("HuskFridgeB", D, (-50.0, 18.05, 56.1))
# Interstice derrière le réfrigérateur (vers le mur est) : visible, inaccessible.
g.prop("FridgeGapBlock", A, (1.0, 18.0, 0.5), (-46.1, 9.0, 50.15), "blocker", shadow=False)
g.prop("FridgeGapCap", A, (1.0, 0.3, 6.6), (-46.1, 18.15, 53.6), "blocker", shadow=False)
for i in range(4):
    g.prop(f"FridgeCable{i}", A, (0.14, 0.14, 2.4), (-46.2 + i * 0.12, 0.3 + i * 0.6, 50.6 + i * 0.3), "cable", rot=rx(12 * i), bevel=0.05, collide=False)
g.decal("FridgeGapDark", D, (0.95, 6.4), (-46.1, 0.01, 53.6), "shadow", rx(-90))

# ------------------------------------------------------------------ fenêtre (mur ouest, au-dessus de l'évier)
g.prop("WindowSill", D, (1.25, 0.3, 12.8), (-74.4, 10.05, 33.0), "frame", bevel=0.05)
g.prop("WindowSky", D, (0.05, 9.8, 12.0), (-74.97, 15.1, 33.0), "sky", bevel=0.0, collide=False, shadow=False)
for i, (fz, fy, r) in enumerate(((29.0, 12.4, 1.6), (31.0, 13.6, 2.2), (36.5, 12.0, 1.8), (38.0, 14.0, 1.4))):
    g.prop(f"Foliage{i}", D, (0.03, r * 1.6, r * 2.0), (-74.94, fy, fz), "foliage", bevel=0.0, collide=False, shadow=False)
g.prop("WindowHead", D, (0.8, 0.4, 12.8), (-74.6, 20.2, 33.0), "frame", bevel=0.05)
g.prop("WindowJambA", D, (0.6, 9.8, 0.4), (-74.7, 15.1, 26.8), "frame", bevel=0.04)
g.prop("WindowJambB", D, (0.6, 9.8, 0.4), (-74.7, 15.1, 39.2), "frame", bevel=0.04)
g.prop("WindowMullion", D, (0.3, 9.8, 0.25), (-74.85, 15.1, 33.0), "frame", bevel=0.03, collide=False)
g.prop("WindowTransom", D, (0.3, 0.25, 12.0), (-74.85, 16.2, 33.0), "frame", bevel=0.03, collide=False)
g.prop("SillPotA", D, (1.0, 1.0, 1.0), (-74.4, 10.7, 28.4), "pot", cyl=True, bevel=0.1)
g.prop("SillPotB", D, (0.9, 0.9, 0.9), (-74.45, 10.65, 35.6), "pot", cyl=True, bevel=0.1)
for i in range(4):
    g.sphere(f"SillLeaf{i}", D, 0.22, (-74.4, 11.4 + i * 0.15, 28.4 + random.uniform(-0.3, 0.3)), "leaf", (1.0, 0.5, 1.2))
g.prop("DriedStem", D, (0.06, 1.4, 0.06), (-74.45, 11.8, 35.6), "leaf_dry", rot=rz(14), collide=False)
for i in range(3):
    husk(f"DeadFly{i}", D, (-74.5 + random.uniform(-0.2, 0.3), 10.22, 30.5 + i * 2.1))

# ------------------------------------------------------------------ sol : poubelle, coin des cafards, traces
g.prop("Bin", D, (3.0, 6.5, 3.0), (-49.0, 3.25, 15.0), "bin", cyl=True, bevel=0.2)
g.prop("BinLid", D, (3.1, 0.3, 3.1), (-49.0, 6.6, 15.0), "bin", cyl=True, bevel=0.1, collide=False)
g.prop("BinPedal", D, (1.2, 0.2, 0.6), (-50.6, 0.2, 15.0), "steel", bevel=0.05, collide=False)
g.prop("PaperBag", D, (1.8, 2.4, 1.2), (-51.6, 1.2, 12.6), "cardboard", rot=ry(25), bevel=0.15)
# Carton aplati en « tente » (cachette des cafards), épluchures, miettes déplacées.
g.prop("TentA", D, (3.2, 0.08, 2.0), (-64.0, 0.55, 15.5), "cardboard", rot=rx(32), bevel=0.0, collide=False)
g.prop("TentB", D, (3.2, 0.08, 2.0), (-64.0, 0.55, 16.9), "cardboard", rot=rx(-32), bevel=0.0, collide=False)
for i in range(4):
    g.prop(f"Peel{i}", D, (random.uniform(0.6, 1.0), 0.05, 0.25), (-61.5 + random.uniform(-1.5, 1.5), 0.03, 18.5 + random.uniform(-1.5, 1.5)), "peel", rot=ry(random.uniform(0, 180)), bevel=0.0, collide=False, shadow=False)
for i in range(14):
    g.sphere(f"FloorCrumb{i}", D, 0.06, (-63.0 + random.uniform(-3.5, 3.0), 0.03, 18.0 + random.uniform(-3, 2.5)), "crumb")
# Traînée de miettes tirées vers la cachette (chasse ancienne), pattes éparses.
for i in range(8):
    g.sphere(f"DragCrumb{i}", D, 0.05, (-60.0 - i * 0.5, 0.03, 20.6 - i * 0.6), "crumb")
husk("HuskFloor", D, (-62.4, 0.02, 19.6))
# Pomme de terre oubliée sous l'évier, qui germe (végétation discrète).
g.sphere("Potato", D, 0.45, (-71.5, 0.32, 41.0), "potato", (1.3, 0.7, 1.0))
for i in range(4):
    g.prop(f"PotatoSprout{i}", D, (0.05, 0.8, 0.05), (-71.5 + random.uniform(-0.3, 0.3), 0.85, 41.0 + random.uniform(-0.3, 0.3)), "sprout", rot=rz(random.uniform(-30, 30)), collide=False, shadow=False)
g.prop("FloorMat", D, (5.0, 0.05, 8.0), (-65.5, 0.025, 33.0), "towel_stripe", bevel=0.02, collide=False)
g.prop("SpoonFloor", D, (0.25, 0.08, 1.6), (-57.0, 0.04, 40.0), "steel", rot=ry(40), bevel=0.04, collide=False)
for i in range(10):
    x, z = random.uniform(-68, -48), random.uniform(3, 49)
    g.decal(f"Dust{i}", D, (random.uniform(2, 5), random.uniform(1.5, 4)), (x, 0.012 + i * 0.001, z), "dust", rx(-90))
g.decal("StainFloor", D, (2.5, 1.6), (-58.5, 0.02, 47.5), "stain", rx(-90))
# Pénombre sous les meubles bas.
g.decal("UnderWestDark", D, (6.0, 31.0), (-72.0, 0.008, 35.5), "shadow", rx(-90))
g.decal("UnderSouthDark", D, (22.0, 6.0), (-64.0, 0.008, 54.0), "shadow", rx(-90))
# Plinthes cassées, tombées devant les meubles.
g.prop("PlinthFallen", D, (5.0, 0.9, 0.12), (-60.0, 0.06, 49.6), "cabinet_shade", rot=mul(ry(8), rx(-90)), bevel=0.02, collide=False)
g.prop("PlinthStanding", D, (0.12, 0.9, 6.0), (-69.4, 0.45, 23.0), "cabinet_shade", bevel=0.02, collide=False)

# ------------------------------------------------------------------ toiles et cocons (traces de vie)
web("WebLair", (-74.9, 22.6, 55.6), 1.3)                         # repaire au-dessus des placards (habitée)
sheet_web("WebLairSheet", (-72.5, 23.9, 56.0), (5.0, 2.0))
web("WebAbandoned", (-74.9, 0.6, 21.6), 0.55, torn=False, rings=2)   # sous le rang ouest (abandonnée, poussiéreuse)
sheet_web("WebUnderSouth", (-73.5, 0.98, 55.0), (3.0, 3.0))
web("WebWindow", (-74.6, 18.8, 38.4), 1.0, torn=True)             # coin de la fenêtre (déchirée)
web("WebWindowTop", (-74.7, 21.4, 28.0), 0.8)                     # au-dessus de la fenêtre (habitée)
web("WebFridgeGap", (-46.1, 4.0, 55.0), 0.45, plane="z", rings=2)
web("WebMicrowave", (-74.9, 13.4, 55.5), 0.6, rings=2)
cocoon("CocoonLairA", W, (-74.4, 22.0, 56.2))
cocoon("CocoonLairB", W, (-73.9, 21.7, 56.5), 0.26)
cocoon("CocoonWindow", W, (-74.7, 20.0, 27.4), 0.24)

# ------------------------------------------------------------------ créatures
# Territoires : rectangles horizontaux AABB(x, y, z, sx, 0, sz) ; obstacles AABB pleins.
FLOOR_OPEN = aabb(-68.9, 0.0, 0.6, -45.9, 50.2)
UNDER_WEST = aabb(-75.0, 0.0, 20.2, -69.1, 51.0)
UNDER_SOUTH = aabb(-75.0, 0.0, 51.0, -53.0, 56.8)
FLOOR_BLOCK = [aabb(-50.7, 0.0, 13.3, -47.3, 16.7, 7.0), aabb(-74.7, 0.0, 16.1, -70.1, 20.1, 9.0),
               aabb(-72.5, 0.0, 14.6, -70.7, 16.3, 1.0), aabb(-67.7, 0.0, 45.5, -64.3, 49.0, 6.0), aabb(-52.7, 0.0, 50.3, -45.6, 57.0, 18.0),
               aabb(-48.4, 0.0, 1.8, -45.6, 11.0, 20.0), aabb(-52.6, 0.0, 11.8, -50.6, 13.4, 2.4), aabb(-69.0, 0.0, 33.6, -65.0, 38.2, 6.0)]
COUNTER_WEST = [aabb(-75.0, 9.0, 20.0, -68.7, 28.0), aabb(-75.0, 9.0, 38.0, -68.7, 51.0)]
COUNTER_SOUTH = aabb(-71.0, 9.0, 50.7, -52.9, 56.8)
COUNTER_BLOCK = [aabb(-74.7, 9.0, 52.1, -70.3, 56.7, 3.3), aabb(-68.3, 9.0, 53.3, -65.9, 56.5, 4.5), aabb(-74.2, 9.0, 37.9, -72.6, 39.5, 0.6),
                 aabb(-54.5, 9.0, 51.1, -52.8, 52.9, 5.0), aabb(-75.0, 9.0, 43.9, -71.5, 52.1, 6.0), aabb(-57.9, 9.0, 53.9, -55.3, 56.5, 1.0)]
CABINET_TOP = aabb(-75.0, 21.0, 53.6, -62.1, 57.0)
SPICE_TOP = aabb(-75.0, 21.0, 50.0, -73.0, 53.6)
TOP_BLOCK = [aabb(-65.2, 21.0, 54.4, -62.8, 56.8, 1.4)]

def creature(name, script, pos, props):
    s.node(name, "Node3D", "Creatures", f"transform = {tf(ry(random.uniform(0, 360)), pos)}\nscript = {script}\n" + props)

def arr(items):
    return "Array[AABB]([" + ", ".join(items) + "])"

g.group("Creatures")
# Araignée des dessous de meubles (sol, pénombre) : repaire dans le coin sud-ouest.
creature("SpiderUnder", SPIDER, (-73.6, 0.0, 55.4), f"areas = {arr([UNDER_SOUTH, UNDER_WEST])}\nhome = Vector3(-73.6, 0, 55.4)\nweb_anchor = Vector3(-73.5, 0.95, 55.6)")
# Araignée du repaire en hauteur (dessus des placards) : descend sur le plan de travail.
creature("SpiderLair", SPIDER, (-72.0, 21.0, 56.0), f"areas = {arr([CABINET_TOP, SPICE_TOP, COUNTER_SOUTH])}\nblockers = {arr(COUNTER_BLOCK + TOP_BLOCK)}\nhome = Vector3(-72, 21, 56)\nhunt_range = 18.0\nweb_anchor = Vector3(-74.4, 23.2, 56.3)")
# Araignée de la fenêtre : guette sur le linteau, descend sur le rebord.
SILL = aabb(-75.0, 10.2, 27.0, -73.85, 39.0)
LINTEL = aabb(-75.0, 20.4, 27.0, -74.25, 39.0)
creature("SpiderWindow", SPIDER, (-74.6, 20.4, 28.2), f"areas = {arr([SILL, LINTEL])}\nblockers = {arr([aabb(-74.9, 10.2, 27.9, -73.9, 28.9, 1.0), aabb(-74.9, 10.2, 35.15, -74.0, 36.05, 0.9)])}\nhome = Vector3(-74.6, 20.4, 28.2)\nhunt_range = 16.0\nweb_anchor = Vector3(-74.7, 21.4, 28.0)")
# Cafards : sol (dessous des meubles, coin nord-ouest), plan de travail, rebord, nid sous l'évier.
FLOOR_HIDES = [(-72.0, 0.0, 23.0), (-72.6, 0.0, 30.5), (-72.0, 0.0, 44.0), (-60.0, 0.0, 54.5), (-66.0, 0.0, 55.2), (-56.0, 0.0, 55.6),
               (-64.0, 0.0, 16.2), (-47.0, 0.0, 17.6), (-53.6, 0.0, 49.4), (-60.5, 0.0, 1.2), (-68.4, 0.0, 6.0)]
for i, p in enumerate(((-63.0, 0.0, 18.0), (-60.0, 0.0, 14.0), (-66.0, 0.0, 22.0), (-58.0, 0.0, 44.0), (-61.0, 0.0, 30.0), (-56.0, 0.0, 24.0), (-64.0, 0.0, 40.0))):
    # Lot 7 : plus de cafards ; certains, courageux, chargent Nin0 au lieu de fuir.
    brave = "\nbrave = true" if i in (4, 6) else ""
    creature(f"RoachFloor{i}", ROACH, p, f"areas = {arr([FLOOR_OPEN, UNDER_WEST, UNDER_SOUTH])}\nblockers = {arr(FLOOR_BLOCK)}\nhides = {vecs(FLOOR_HIDES)}{brave}")
# Lot 7 : deux araignées de plus au sol (coin des cartons, pied du réfrigérateur).
NW_FLOOR = aabb(-69.0, 0.0, 9.0, -57.0, 24.0)
creature("SpiderNW", SPIDER, (-72.0, 0.0, 22.6), f"areas = {arr([UNDER_WEST, NW_FLOOR])}\nblockers = {arr(FLOOR_BLOCK)}\nhome = Vector3(-72, 0, 22.6)\nweb_anchor = Vector3(-72.4, 0.9, 21.6)")
FRIDGE_FLOOR = aabb(-60.0, 0.0, 40.0, -52.8, 50.2)
creature("SpiderFridge", SPIDER, (-53.4, 0.0, 49.6), f"areas = {arr([FRIDGE_FLOOR, UNDER_SOUTH])}\nblockers = {arr(FLOOR_BLOCK)}\nhome = Vector3(-53.4, 0, 49.6)\nweb_anchor = Vector3(-53.0, 1.2, 50.1)")
COUNTER_HIDES = [(-72.6, 9.0, 41.2), (-69.6, 9.0, 56.4), (-65.4, 9.0, 56.5), (-53.4, 9.0, 53.6), (-74.6, 9.0, 26.0), (-69.4, 9.0, 49.0), (-62.0, 9.0, 56.6)]
for i, p in enumerate(((-71.5, 9.0, 42.5), (-62.0, 9.0, 52.0))):
    creature(f"RoachCounter{i}", ROACH, p, f"areas = {arr(COUNTER_WEST + [COUNTER_SOUTH])}\nblockers = {arr(COUNTER_BLOCK)}\nhides = {vecs(COUNTER_HIDES)}")
creature("RoachSill", ROACH, (-74.4, 10.2, 33.0), f"areas = {arr([SILL])}\nblockers = {arr([aabb(-74.9, 10.2, 27.9, -73.9, 28.9, 1.0), aabb(-74.9, 10.2, 35.15, -74.0, 36.05, 0.9)])}\nhides = {vecs([(-74.8, 10.2, 29.4), (-74.8, 10.2, 37.4), (-74.8, 10.2, 33.4)])}")
NEST = aabb(-74.7, 1.2, 28.3, -69.2, 37.7)
creature("RoachNest", ROACH, (-73.4, 1.2, 36.2), f"areas = {arr([NEST])}\nblockers = {arr([aabb(-74.1, 1.2, 34.4, -73.0, 37.1, 3.0), aabb(-73.3, 1.2, 30.1, -71.7, 32.1, 3.0)])}\nhides = {vecs([(-74.4, 1.2, 37.4), (-74.4, 1.2, 28.6), (-69.6, 1.2, 28.6)])}")
# Arrière-plan (zones visibles, inaccessibles) : affrontements autonomes.
GAP = aabb(-46.45, 0.0, 50.8, -45.75, 56.6)
creature("BgSpiderFridge", SPIDER, (-46.1, 4.0, 55.6), f"background = true\nareas = {arr([GAP])}\nhome = Vector3(-46.1, 4, 55.6)\nweb_anchor = Vector3(-46.1, 4.4, 55.2)")
creature("BgRoachFridge", ROACH, (-46.1, 0.0, 51.4), f"background = true\nareas = {arr([GAP])}\nhides = {vecs([(-46.1, 0.0, 56.4), (-46.1, 0.0, 51.0), (-46.1, 0.0, 53.7)])}")
EAST_TOP = aabb(-55.6, 21.0, 53.7, -54.15, 56.9)
g.prop("EastTopBlock", A, (0.25, 3.0, 4.2), (-54.05, 22.5, 54.9), "blocker", shadow=False)
creature("BgSpiderCabinet", SPIDER, (-54.4, 21.0, 56.5), f"background = true\nareas = {arr([EAST_TOP])}\nblockers = {arr([aabb(-55.8, 21.0, 55.7, -54.6, 56.9, 1.0)])}\nhome = Vector3(-54.4, 21, 56.5)")
creature("BgRoachCabinet", ROACH, (-55.0, 21.0, 54.2), f"background = true\nareas = {arr([EAST_TOP])}\nblockers = {arr([aabb(-55.8, 21.0, 55.7, -54.6, 56.9, 1.0)])}\nhides = {vecs([(-55.4, 21.0, 55.3), (-54.3, 21.0, 54.0), (-54.9, 21.0, 56.6)])}")
HOOD_TOP = aabb(-61.8, 17.5, 53.7, -56.2, 54.9)
creature("BgSpiderHood", SPIDER, (-61.5, 17.5, 54.6), f"background = true\nareas = {arr([HOOD_TOP])}\nhome = Vector3(-61.5, 17.5, 54.6)\nweb_anchor = Vector3(-61.8, 19.0, 55.4)")
creature("BgRoachHood", ROACH, (-57.0, 17.5, 54.2), f"background = true\nareas = {arr([HOOD_TOP])}\nhides = {vecs([(-56.4, 17.5, 54.7), (-61.6, 17.5, 53.9), (-59.0, 17.5, 54.8)])}")
g.prop("HoodTopBlock", A, (0.3, 6.5, 3.4), (-62.15, 20.75, 55.3), "blocker", shadow=False)
g.prop("HoodTopBlockEast", A, (0.3, 6.5, 3.4), (-55.85, 20.75, 55.3), "blocker", shadow=False)
web("WebHood", (-61.95, 18.6, 55.4), 0.5, rings=2)

FLEA_PERCHES = [(-52.4, 0.0, 8.6), (-54.8, 0.0, 11.6), (-51.6, 2.42, 12.6), (-49.0, 6.75, 15.0), (-56.5, 0.0, 6.4), (-50.2, 0.0, 18.4)]
s.node("Flea", "Node3D", "Creatures", f"transform = {tf(I, FLEA_PERCHES[0])}\nscript = {FLEA}\nperches = {vecs(FLEA_PERCHES)}")

# ------------------------------------------------------------------ découvertes (traces du lieu, sans texte révélateur)
g.group("Discoveries")
def discovery(name, did, title, icons, text, cicons, ctext, size, pos):
    icon_list = ", ".join(f'&"{i}"' for i in icons)
    concl = ", ".join(f'&"{i}"' for i in cicons)
    res = s.sub("Resource", f"Disc_{name}", f"script = {DISC}\nid = &\"{did}\"\ntitle = \"{title}\"\nthought_icons = Array[StringName]([{icon_list}])\nthought_text = \"{text}\"\nconclusion_icons = Array[StringName]([{concl}])\nconclusion_text = \"{ctext}\"")
    shape = s.sub("BoxShape3D", f"DiscShape_{name}", f"size = {v3(size)}")
    s.node(name, "Area3D", "Discoveries", f"transform = {tf(I, pos)}\ncollision_layer = 8\ncollision_mask = 0\nmonitoring = false\nscript = {EXAM}\ndiscovery = {res}")
    s.node("Shape", "CollisionShape3D", f"Discoveries/{name}", f"shape = {shape}")
discovery("WebLairSpot", "kitchen_web_lair", "Toile habitée", ["web", "spider"], "Quelqu'un vit ici.", ["eye", "exclamation"], "Mieux vaut ne pas traîner.", (2.6, 2.0, 2.6), (-73.4, 22.0, 55.6))
discovery("WebAbandonedSpot", "kitchen_web_old", "Vieille toile", ["web", "question"], "Vide… et poussiéreuse.", ["spider", "cross"], "Partie depuis longtemps.", (2.0, 1.2, 2.4), (-73.0, 0.5, 21.8))
discovery("WebTornSpot", "kitchen_web_torn", "Toile déchirée", ["web", "damage"], "Arrachée.", ["roach", "question"], "Une proie s'est débattue ?", (1.8, 2.0, 2.4), (-74.2, 11.2, 38.0))
discovery("PreyRemains", "kitchen_prey_remains", "Restes de proies", ["roach", "cross"], "Il ne reste que la carapace.", ["spider", "exclamation"], "", (2.6, 1.4, 2.4), (-50.3, 18.6, 55.8))
discovery("RoachNestSpot", "kitchen_roach_nest", "Cachette des cafards", ["roach", "eye"], "Des miettes entassées.", ["house", "roach"], "Leur refuge.", (2.4, 1.6, 2.8), (-73.4, 2.0, 36.2))
discovery("DragTrail", "kitchen_drag_trail", "Traînée de miettes", ["eye", "arrow"], "Quelque chose a été tiré par ici.", ["spider", "roach"], "", (3.6, 1.0, 3.0), (-61.4, 0.5, 19.0))
discovery("SproutingPotato", "kitchen_sprout", "Pomme de terre germée", ["eye", "question"], "Elle pousse… toute seule.", ["sun", "ellipsis"], "", (1.8, 1.2, 1.8), (-71.0, 0.6, 41.0))
discovery("SillPlant", "kitchen_sill_plant", "Plante du rebord", ["sun", "eye"], "Encore verte, près de la lumière.", [], "", (1.6, 1.6, 2.0), (-74.2, 11.0, 28.6))

# ------------------------------------------------------------------ ressources
g.group("Pickups")
g.pickup("FilamentUnderWest", "Pickups", "k_fil_under_west", (-72.4, 0.05, 26.0), 0)
g.pickup("PlasticUnderWest", "Pickups", "k_pl_under_west", (-72.6, 0.05, 47.0), 1, 2, 180.0)
g.pickup("FilamentCorner", "Pickups", "k_fil_corner", (-62.0, 0.05, 13.4), 0)
g.pickup("PlasticDoorside", "Pickups", "k_pl_doorside", (-52.6, 0.05, 6.0), 1, 2, 120.0)
g.pickup("PlasticNest", "Pickups", "k_pl_nest", (-71.4, 1.25, 33.0), 1, 4, 240.0)
g.pickup("FilamentNest", "Pickups", "k_fil_nest", (-73.6, 1.25, 29.6), 0, 1, 0.0)
g.pickup("FilamentCounter", "Pickups", "k_fil_counter", (-70.4, 9.05, 21.6), 0)
g.pickup("PlasticCounter", "Pickups", "k_pl_counter", (-60.6, 9.45, 52.0), 1, 2, 180.0)
g.pickup("PlasticSill", "Pickups", "k_pl_sill", (-74.4, 10.25, 33.0), 1, 3, 240.0)
g.pickup("FilamentFridgeTop", "Pickups", "k_fil_fridge_top", (-49.6, 18.05, 52.4), 0, 2, 0.0)
g.pickup("PlasticCabinetTop", "Pickups", "k_pl_cabinet_top", (-67.0, 21.05, 55.4), 1, 5, 0.0)
g.pickup("FilamentShelf", "Pickups", "k_fil_shelf", (-72.6, 15.05, 45.6), 0, 1, 0.0)
# Lot 7 : réserves de plastique autour de l'arène des guêpes (réapparition rapide).
g.pickup("PlasticArenaA", "Pickups", "k_pl_arena_a", (-70.2, 9.05, 25.0), 1, 3, 45.0)
g.pickup("PlasticArenaB", "Pickups", "k_pl_arena_b", (-69.5, 9.05, 42.6), 1, 3, 45.0)
g.pickup("PlasticArenaC", "Pickups", "k_pl_arena_c", (-74.6, 9.05, 21.0), 1, 2, 45.0)

# ------------------------------------------------------------------ arène des guêpes (lot 7) : plan de travail ouest
# Les guêpes entrent par une imposte entrouverte en haut de la fenêtre.
g.prop("WindowVent", D, (0.08, 1.6, 4.0), (-74.6, 18.6, 30.4), "frame", rot=rz(-18), bevel=0.02, collide=False)
g.decal("WindowVentGap", D, (3.8, 1.2), (-74.93, 18.6, 30.4), "shadow", ry(90))
s.node("WaspArena", "Node3D", ".", f"script = {WARENA}")

# ------------------------------------------------------------------ porte du salon (côté cuisine), entrée, repères
g.interactable("SalonDoorInspect", ".", (1.6, 2.0, 9.0), (-46.4, 1.0, 31.5), "Examiner la porte")
g.area("EntryZone", ".", (6.0, 6.0, 9.0), (-50.0, 3.0, 6.5))
g.group("Markers")
g.marker("KitchenEntry", "Markers", (-49.0, 0.05, 6.5), 90)
g.marker("CounterWest", "Markers", (-71.0, 9.05, 23.0), 180)
g.marker("FridgeTop", "Markers", (-50.0, 18.05, 52.6), 90)
g.marker("CabinetTop", "Markers", (-70.0, 21.05, 55.2), 90)

# ------------------------------------------------------------------ éclairage : lumière de la fenêtre, pénombre ailleurs
s.node("WindowSun", "SpotLight3D", ".", f"transform = {tf(mul(ry(-90), rx(-28)), (-73.5, 18.0, 33.0))}\nlight_color = Color(1, 0.9, 0.74, 1)\nlight_energy = 3.2\nshadow_enabled = true\nspot_range = 36.0\nspot_angle = 42.0\nspot_attenuation = 0.8")
s.node("WindowGlow", "OmniLight3D", ".", f"transform = {tf(I, (-72.5, 14.0, 33.0))}\nlight_color = Color(0.85, 0.92, 1, 1)\nlight_energy = 0.7\nomni_range = 12.0")
s.node("CeilingDim", "OmniLight3D", ".", f"transform = {tf(I, (-60.0, 21.5, 28.0))}\nlight_color = Color(0.82, 0.86, 0.95, 1)\nlight_energy = 0.32\nomni_range = 34.0\nomni_attenuation = 0.9")
s.node("FridgeHalo", "OmniLight3D", ".", f"transform = {tf(I, (-49.6, 2.0, 49.0))}\nlight_color = Color(0.7, 0.85, 1, 1)\nlight_energy = 0.15\nomni_range = 4.0")
# Poussière en suspension dans le rayon de la fenêtre.
dust_mesh = s.sub("QuadMesh", "DustQuad", "size = Vector2(0.03, 0.03)")
dust_mat = s.sub("StandardMaterial3D", "DustMat", "transparency = 1\nshading_mode = 0\nbillboard_mode = 1\nalbedo_color = Color(1, 0.95, 0.82, 0.55)")
s.node("DustMotes", "CPUParticles3D", ".", f"transform = {tf(I, (-68.0, 12.0, 33.0))}\nmaterial_override = {dust_mat}\namount = 60\nlifetime = 9.0\npreprocess = 9.0\nmesh = {dust_mesh}\nemission_shape = 3\nemission_box_extents = Vector3(5, 4, 5)\ndirection = Vector3(0.2, 1, 0)\nspread = 180.0\ngravity = Vector3(0, -0.02, 0)\ninitial_velocity_min = 0.02\ninitial_velocity_max = 0.08")
g.write(sys.argv[1])
print("kitchen ok")
