"""Salle de bain (zone 3) jouable : territoire des fourmis. Labyrinthe gauche (souvenir 2),
labyrinthe droit (soldats, gravier, marches, larves), escabeau, meuble-lavabo et arène
de la reine (matière visqueuse, débris flottants, vidange). Usage : gen_bathroom.py <sortie>"""
import sys
sys.path.insert(0, sys.path[0])
from gen_common import *
random.seed(11)
g = Gen("BathroomZone", "res://scripts/zones/bathroom_zone.gd")
s = g.s
TERRAIN = s.ext_res("Script", "res://scripts/zones/terrain_zone.gd")
LARVA = s.ext_res("Script", "res://scripts/zones/larva_dropper.gd")
SOLDIER = s.ext_res("Script", "res://scripts/creatures/ant_soldier.gd")
ARENA = s.ext_res("Script", "res://scripts/zones/sink_arena.gd")
PLATFORM = s.ext_res("Script", "res://scripts/zones/floating_platform.gd")
QUEEN = s.ext_res("Script", "res://scripts/creatures/ant_queen.gd")
CABLE = s.ext_res("Script", "res://scripts/props/cable.gd")
MEM_PROFILE = s.ext_res("Resource", "res://assets/observation/memory_detail.tres")
MEMORY_02 = s.ext_res("Resource", "res://assets/memories/memory_02.tres")
tiles = s.ext_res("Shader", "res://assets/shaders/tiles.gdshader")
g.M["tiles_floor"] = s.sub("ShaderMaterial", "Mat_tiles_floor", f"shader = {tiles}\nshader_parameter/tile_size = 1.5\nshader_parameter/plane_axis = 1")
g.M["tiles_wall_x"] = s.sub("ShaderMaterial", "Mat_tiles_wall_x", f"shader = {tiles}\nshader_parameter/tile_size = 1.5\nshader_parameter/plane_axis = 0\nshader_parameter/tile_color = Color(0.86, 0.9, 0.92, 1)")
g.M["tiles_wall_z"] = s.sub("ShaderMaterial", "Mat_tiles_wall_z", f"shader = {tiles}\nshader_parameter/tile_size = 1.5\nshader_parameter/plane_axis = 2\nshader_parameter/tile_color = Color(0.86, 0.9, 0.92, 1)")
for k, c, r, m in (("ceramic", (0.95, 0.95, 0.93), 0.15, 0.0), ("enamel", (0.93, 0.94, 0.94), 0.2, 0.0), ("chrome", (0.75, 0.77, 0.8), 0.15, 0.9),
        ("vanity", (0.86, 0.84, 0.8), 0.6, 0.0), ("counter", (0.32, 0.34, 0.36), 0.35, 0.0), ("denim", (0.22, 0.3, 0.45), 1.0, 0.0),
        ("denim_dark", (0.17, 0.22, 0.34), 1.0, 0.0), ("plastic_w", (0.92, 0.92, 0.9), 0.4, 0.0), ("plastic_b", (0.3, 0.55, 0.8), 0.35, 0.0),
        ("plastic_g", (0.4, 0.68, 0.45), 0.35, 0.0), ("plastic_p", (0.85, 0.5, 0.65), 0.35, 0.0), ("plastic_y", (0.95, 0.8, 0.3), 0.35, 0.0),
        ("cardboard", (0.72, 0.56, 0.38), 0.9, 0.0), ("wicker", (0.62, 0.48, 0.3), 0.9, 0.0), ("dirt", (0.34, 0.25, 0.17), 1.0, 0.0),
        ("dirt_light", (0.46, 0.36, 0.25), 1.0, 0.0), ("pebble", (0.55, 0.52, 0.48), 0.8, 0.0), ("tile_shard", (0.8, 0.84, 0.84), 0.3, 0.0),
        ("cotton", (0.96, 0.95, 0.92), 1.0, 0.0), ("towel", (0.45, 0.62, 0.66), 1.0, 0.0), ("wood_w", (0.88, 0.86, 0.8), 0.6, 0.0),
        ("wood_rail", (0.7, 0.55, 0.36), 0.6, 0.0), ("sponge", (0.92, 0.82, 0.35), 1.0, 0.0), ("sponge_g", (0.35, 0.6, 0.35), 1.0, 0.0),
        ("cap", (0.85, 0.25, 0.2), 0.4, 0.0), ("soap", (0.9, 0.75, 0.82), 0.5, 0.0), ("paper", (0.9, 0.88, 0.82), 0.95, 0.0),
        ("paper_ink", (0.35, 0.33, 0.32), 0.95, 0.0), ("rubber", (0.1, 0.1, 0.1), 0.8, 0.0), ("larva_pile", (0.95, 0.92, 0.82), 0.5, 0.0),
        ("mirror", (0.7, 0.78, 0.82), 0.05, 0.6), ("bucket", (0.25, 0.55, 0.75), 0.4, 0.0), ("lessive", (0.9, 0.45, 0.2), 0.5, 0.0)):
    g.mat(k, c, r, m)
for k, c in (("tee_red", (0.72, 0.28, 0.24)), ("tee_grey", (0.6, 0.62, 0.64)), ("tee_navy", (0.2, 0.25, 0.4)),
        ("tee_green", (0.38, 0.5, 0.36)), ("tee_cream", (0.88, 0.84, 0.74)), ("tee_mustard", (0.8, 0.62, 0.25)),
        ("towel_blue", (0.42, 0.6, 0.72)), ("towel_white", (0.9, 0.9, 0.86)), ("towel_rose", (0.82, 0.6, 0.62)),
        ("fabric_dark", (0.12, 0.12, 0.14)), ("rag", (0.7, 0.66, 0.55))):
    g.mat(k, c, 1.0)
g.mat("sludge", (0.3, 0.33, 0.2), 0.15, extra="transparency = 1\nalbedo_color = Color(0.28, 0.32, 0.18, 0.92)")
g.mat("stain", (0.32, 0.3, 0.2), 1.0, extra="transparency = 1\nalbedo_color = Color(0.32, 0.3, 0.2, 0.3)\ncull_mode = 2")
g.mat("drain_hole", (0.02, 0.02, 0.02), 1.0)

# ------------------------------------------------------------------ revêtements (sans collision)
g.group("Surfaces")
SUR = "Surfaces"
g.decal("FloorTiles", SUR, (29.4, 34.4), (-60.3, 0.006, -17.8), "tiles_floor", rx(-90))
g.decal("WallTilesNorth", SUR, (29.4, 12.0), (-60.3, 6.0, -34.97), "tiles_wall_z")
g.decal("WallTilesWest", SUR, (34.4, 12.0), (-74.97, 6.0, -17.8), "tiles_wall_x", ry(90))
g.decal("WallTilesSouth", SUR, (29.4, 12.0), (-60.3, 6.0, -0.63), "tiles_wall_z", ry(180))
g.decal("WallTilesEastA", SUR, (22.8, 12.0), (-45.63, 6.0, -23.6), "tiles_wall_x", ry(-90))
g.decal("WallTilesEastB", SUR, (2.4, 12.0), (-45.63, 6.0, -1.8), "tiles_wall_x", ry(-90))
for i in range(8):
    g.decal(f"Damp{i}", SUR, (random.uniform(2, 5), random.uniform(2, 6)), (random.uniform(-73, -48), random.uniform(1, 4), -34.95), "stain")
g.decal("DampFloor", SUR, (5.0, 3.0), (-56.0, 0.012, -27.0), "stain", rx(-90))

# ------------------------------------------------------------------ appareils sanitaires
g.group("Fixtures")
F = "Fixtures"
# Baignoire contre le mur ouest (partie sud).
g.prop("Tub", F, (7.6, 5.6, 17.4), (-71.2, 2.8, -9.3), "enamel", bevel=0.6)
g.prop("TubInner", F, (6.2, 0.1, 15.8), (-71.2, 5.56, -9.3), "chrome", bevel=0.05, collide=False)
g.prop("TubFaucet", F, (1.2, 1.2, 0.6), (-74.6, 7.0, -9.3), "chrome", collide=False)
# Amas de la colonie sur le rebord de la baignoire (larves visibles, galerie en hauteur).
g.sphere("RimNest", F, 0.9, (-67.9, 5.8, -17.2), "dirt", (1.2, 0.6, 1.6))
for i in range(5):
    g.sphere(f"RimLarva{i}", F, 0.12, (-67.7 + random.uniform(-0.4, 0.4), 6.1, -17.2 + random.uniform(-0.8, 0.8)), "larva_pile", (1.0, 0.8, 1.8))
# WC (angle nord-est).
g.prop("ToiletBase", F, (4.0, 4.0, 5.5), (-49.0, 2.0, -31.8), "ceramic", bevel=0.8)
g.prop("ToiletSeat", F, (4.2, 0.4, 4.6), (-49.0, 4.2, -31.4), "plastic_w", bevel=0.4, collide=False)
g.prop("ToiletTank", F, (4.6, 4.2, 2.2), (-49.0, 6.3, -33.8), "ceramic", bevel=0.4)
# Meuble-lavabo (mur nord) : caisson, plan, vasque. Plan de travail à 85 cm.
g.prop("VanityCabinet", F, (12.0, 6.6, 6.3), (-59.0, 3.3, -31.75), "vanity", bevel=0.1)
for i, x in enumerate((-62.0, -56.0)):
    g.prop(f"VanityDoor{i}", F, (5.6, 5.8, 0.08), (x, 3.4, -28.58), "wood_w", collide=False, bevel=0.02)
# Bords de la vasque : tablier (6,6 → 8,0) + plan (8,0 → 8,5), parois pleines.
for nm, sz, x, z in (("West", (1.5, 6.5), -64.25, -31.75), ("East", (1.5, 6.5), -53.75, -31.75), ("Back", (9.0, 0.8), -59.0, -34.6), ("Front", (9.0, 0.9), -59.0, -28.95)):
    g.prop(f"Apron{nm}", F, (sz[0], 1.4, sz[1]), (x, 7.3, z), "vanity", bevel=0.02)
    g.prop(f"Counter{nm}", F, (sz[0], 0.5, sz[1]), (x, 8.25, z), "counter", bevel=0.04)
g.prop("BasinSkirtW", F, (0.04, 1.1, 4.8), (-63.48, 7.45, -31.8), "ceramic", collide=False, bevel=0.0)
g.prop("BasinSkirtE", F, (0.04, 1.1, 4.8), (-54.52, 7.45, -31.8), "ceramic", collide=False, bevel=0.0)
g.prop("BasinSkirtN", F, (9.0, 1.1, 0.04), (-59.0, 7.45, -34.18), "ceramic", collide=False, bevel=0.0)
g.prop("BasinSkirtS", F, (9.0, 1.1, 0.04), (-59.0, 7.45, -29.42), "ceramic", collide=False, bevel=0.0)
g.prop("BasinBottom", F, (9.0, 0.3, 4.8), (-59.0, 6.75, -31.8), "ceramic")
g.prop("Tap", F, (1.0, 2.4, 1.0), (-59.0, 9.7, -34.6), "chrome", cyl=True)
g.prop("TapSpout", F, (0.5, 0.5, 2.0), (-59.0, 10.3, -33.7), "chrome", collide=False)
g.prop("Mirror", F, (10.0, 8.0, 0.15), (-59.0, 16.0, -34.9), "mirror", collide=False)
g.prop("MirrorFrame", F, (10.4, 8.4, 0.1), (-59.0, 16.0, -34.97), "wood_w", collide=False)
g.prop("ToothCup", F, (0.9, 1.1, 0.9), (-63.9, 9.05, -34.55), "plastic_g", cyl=True)
g.prop("SoapBar", F, (1.0, 0.35, 0.6), (-53.8, 8.68, -29.4), "soap", collide=False)
# Distributeur de savon sur le rebord avant : on ne contourne pas la vasque par le bord.
g.prop("SoapPump", F, (1.0, 1.6, 0.9), (-59.0, 9.3, -28.95), "plastic_p", cyl=True, bevel=0.2)
g.prop("SoapPumpHead", F, (0.3, 0.4, 0.7), (-59.0, 10.3, -29.1), "plastic_w", collide=False)
# Serviette pendue au plan, où la colonie a bâti une galerie : les larves en tombent.
g.prop("TowelBar", F, (0.3, 8.0, 0.3), (-59.0, 7.6, -28.35), "chrome", cyl=True, rot=rz(90), collide=False)
g.prop("Towel", F, (6.0, 6.8, 0.35), (-59.0, 4.1, -28.25), "towel", bevel=0.15, collide=False)
g.sphere("TowelNest", F, 0.8, (-59.4, 4.6, -27.9), "dirt", (2.2, 0.8, 0.6))
for i in range(4):
    g.sphere(f"TowelLarva{i}", F, 0.1, (-60.2 + i * 0.5, 5.0, -27.75), "larva_pile", (1.8, 0.8, 1.0))
# Linge entassé dans l'angle nord-ouest.
g.prop("LaundryHeap", F, (6.0, 3.0, 9.0), (-72.0, 1.5, -25.0), "towel", bevel=1.2)

# ------------------------------------------------------------------ séparation : pantalon abandonné (le ticket vient de sa poche)
g.group("Trousers")
for i, (x, z, w, h) in enumerate(((-65.0, -13.7, 4.4, 1.9), (-60.6, -13.6, 4.6, 2.1), (-56.0, -13.8, 4.6, 1.8), (-51.6, -13.5, 3.2, 1.6))):
    g.prop(f"Leg{i}", "Trousers", (w, h, 1.9), (x, h / 2, z), "denim" if i % 2 else "denim_dark", rot=ry(random.uniform(-6, 6)), bevel=0.55)
g.prop("Pocket", "Trousers", (1.4, 0.15, 1.2), (-66.0, 1.75, -12.85), "denim_dark", rot=rx(-25), collide=False)
g.prop("Belt", "Trousers", (0.4, 1.0, 1.9), (-67.0, 1.0, -13.7), "rubber", collide=False)

TEES = ["tee_red", "tee_grey", "tee_navy", "tee_green", "tee_cream", "tee_mustard"]
TOWELS = ["towel_blue", "towel_white", "towel_rose"]
def collider(name, parent, size, pos):
    """Collision seule (les textiles visibles sont plus souples et ne collisionnent pas)."""
    s.node(name, "StaticBody3D", parent, f"transform = {tf(I, pos)}\ncollision_mask = 0")
    box_shape(s, "Shape", f"{parent}/{name}", size, (0, 0, 0))
def folded_stack(name, parent, pos, length, depth, height, along_x, palette):
    """Pile de vêtements pliés : couches arrondies, légèrement décalées, plis visibles."""
    layers = max(3, int(height / 0.27))
    lh = height / layers
    for k in range(layers):
        mat = random.choice(palette)
        jitter = (random.uniform(-0.08, 0.08), random.uniform(-0.08, 0.08))
        size = (length * random.uniform(0.92, 1.0), lh * 1.02, depth * random.uniform(0.9, 1.0)) if along_x else (depth * random.uniform(0.9, 1.0), lh * 1.02, length * random.uniform(0.92, 1.0))
        p = (pos[0] + jitter[0], lh * (k + 0.5), pos[1] + jitter[1])
        g.prop(f"{name}L{k}", parent, size, p, mat, rot=ry(random.uniform(-4, 4)), bevel=min(lh * 0.45, 0.12), collide=False)
        # Pli : bourrelet sur le bord avant de chaque couche.
        fold = (size[0] * 0.96, lh * 0.35, 0.12) if along_x else (0.12, lh * 0.35, size[2] * 0.96)
        off = (0.0, -size[2] * 0.48) if along_x else (-size[0] * 0.48, 0.0)
        g.prop(f"{name}F{k}", parent, fold, (p[0] + off[0], p[1] + lh * 0.18, p[2] + off[1]), mat, bevel=0.05, collide=False, shadow=False)
def rolled_towel(name, parent, pos, length, radius, along_x, mat, y=None):
    rot = rz(90) if along_x else rx(90)
    g.prop(name, parent, (radius * 2, length, radius * 2), (pos[0], radius if y is None else y, pos[1]), mat, rot=rot, cyl=True, bevel=radius * 0.5, collide=False)
    g.prop(f"{name}Edge", parent, (radius * 2.05, 0.18, radius * 2.05), (pos[0] + (length * 0.3 if along_x else 0), radius if y is None else y, pos[1] + (0 if along_x else length * 0.3)), "towel_white", rot=rot, cyl=True, bevel=0.05, collide=False, shadow=False)
def laundry_heap(name, parent, pos, rx_, rz_, h):
    """Tas de linge : volumes mous de couleurs variées."""
    for k in range(7):
        a = k * 0.9
        r = random.uniform(0.45, 0.75)
        g.sphere(f"{name}B{k}", parent, r, (pos[0] + math.cos(a) * rx_ * 0.45, h * random.uniform(0.35, 0.7), pos[1] + math.sin(a) * rz_ * 0.45), random.choice(TEES + TOWELS), (rx_ / r * 0.45, h / r * 0.45, rz_ / r * 0.45))
def rag(name, parent, pos, size, mat="rag", y=0.04):
    g.cloth(name, parent, pos, size, mat)
# ------------------------------------------------------------------ labyrinthe gauche (sud) : vers le souvenir n° 2
g.group("MazeLeft")
L = "MazeLeft"
# Mur A (z ≈ -5) : flacon d'eau de Javel, shampoing couchés, paquet de rouleaux.
g.prop("BleachBottle", L, (1.6, 3.6, 1.6), (-65.2, 0.8, -5.0), "plastic_w", rot=rz(90), cyl=True, bevel=0.3)
g.prop("ShampooLying", L, (1.6, 3.8, 1.6), (-61.3, 0.8, -5.0), "plastic_b", rot=rz(90), cyl=True, bevel=0.3)
collider("RollPack", L, (4.0, 1.6, 1.0), (-57.2, 0.8, -5.0))
for i in range(4):
    g.prop(f"Roll{i}", L, (0.98, 1.5, 0.98), (-58.7 + i * 1.0, 0.75, -5.0), "paper", cyl=True, bevel=0.15, collide=False)
    g.prop(f"RollCore{i}", L, (0.3, 0.02, 0.3), (-58.7 + i * 1.0, 1.51, -5.0), "cardboard", cyl=True, bevel=0.0, collide=False, shadow=False)
g.prop("RollWrap", L, (4.05, 0.5, 1.02), (-57.2, 0.75, -5.0), "plastic_w", bevel=0.2, collide=False)
# Mur B (limite du vestibule) : panier à linge et seau.
g.prop("Basket", L, (3.5, 4.0, 3.6), (-51.85, 2.0, -7.2), "wicker", bevel=0.3)
g.prop("Bucket", L, (2.6, 3.0, 2.6), (-51.9, 1.5, -10.7), "bucket", cyl=True, bevel=0.15)
# Mur C (z ≈ -10.4) : gel douche, lotion, boîte de cotons.
g.prop("ShowerGel", L, (1.8, 3.5, 1.8), (-54.6, 1.75, -10.4), "plastic_p", cyl=True, bevel=0.3)
g.prop("Lotion", L, (1.6, 3.0, 1.6), (-56.4, 1.5, -10.4), "plastic_y", cyl=True, bevel=0.3)
collider("CottonBox", L, (2.6, 1.8, 1.8), (-58.9, 0.9, -10.4))
folded_stack("ClothesC", L, (-58.9, -10.4), 2.6, 1.9, 1.8, True, TEES)
# Mur D (bout ouest du couloir central) : boîte de lessive.
collider("Detergent", L, (1.2, 2.0, 5.9), (-64.0, 1.0, -8.35))
folded_stack("TowelsD1", L, (-64.0, -9.8), 2.9, 1.3, 2.0, False, TOWELS)
folded_stack("TowelsD2", L, (-64.0, -6.9), 2.9, 1.3, 2.0, False, TOWELS)
# Porte-savon sur pieds en travers du couloir haut : passage bas (roues) ou par-dessus (jambes).
g.prop("SoapDish", L, (1.4, 0.15, 1.6), (-64.0, 0.72, -12.05), "plastic_b", bevel=0.05)
for i, (dx, dz) in enumerate(((-0.55, -0.65), (0.55, -0.65), (-0.55, 0.65), (0.55, 0.65))):
    g.prop(f"SoapDishFoot{i}", L, (0.12, 0.65, 0.12), (-64.0 + dx, 0.32, -12.05 + dz), "plastic_b", cyl=True, bevel=0.02)
# Récompenses des culs-de-sac.
g.pickup("PlasticDeadEnd", L, "bath_pl_deadend", (-62.6, 0.05, -2.6), 1, 3, 200.0)
g.pickup("FilamentDeadEnd", L, "bath_fil_deadend", (-54.6, 0.05, -12.0), 0, 1, 300.0)
# Souvenir n° 2 : ticket de caisse froissé, appuyé contre le pantalon, dans le recoin.
g.group("Ticket", L)
T = f"{L}/Ticket"
g.prop("TicketHalfA", T, (0.8, 0.02, 0.75), (-65.7, 0.12, -10.9), "paper", rot=mul(ry(15), rz(-12)), bevel=0.005, collide=False)
g.prop("TicketHalfB", T, (0.8, 0.02, 0.75), (-65.55, 0.36, -11.55), "paper", rot=mul(ry(15), mul(rz(-8), rx(-48))), bevel=0.005, collide=False)
for i in range(2):
    g.prop(f"TicketLine{i}", T, (0.5 - 0.1 * i, 0.005, 0.03), (-65.66, 0.138, -10.62 - i * 0.1), "paper_ink", rot=mul(ry(15), rz(-12)), bevel=0.001, collide=False)
g.prop("TicketCrumple", T, (0.25, 0.08, 0.2), (-65.95, 0.16, -10.7), "paper", rot=mul(ry(40), rz(20)), bevel=0.03, collide=False)
s.node("TicketText", "Label3D", T, f"transform = {tf(mul(ry(15), mul(rz(-12), mul(rx(-90), rz(180)))), (-65.72, 0.145, -10.98))}\npixel_size = 0.0018\nmodulate = Color(0.25, 0.23, 0.22, 0.85)\nfont_size = 32\noutline_size = 0\ntext = \"··· ····\\n·· « NIN0 » ··\\n··· ·· ·····\\n····\"")
s.node("TicketFocus", "Marker3D", T, f"transform = {tf(I, (-65.6, 0.25, -11.2))}\nscript = {g.FOCUS}\nid = &\"memory_02\"\nradius = 0.55\nprofile = {MEM_PROFILE}\nfacing = Vector3(0.75, 0.66, 0)\nmemory = {MEMORY_02}\nthought_icons = Array[StringName]([&\"eye\"])")

# ------------------------------------------------------------------ labyrinthe droit (nord) : galeries gardées par les soldats
g.group("MazeRight")
R = "MazeRight"
def cloth_wall(name, x0, z0, x1, z1, h=1.6):
    """Mur de galerie fait de linge (même emprise de collision que l'ancien mur de terre),
    avec quelques miettes de terre laissées par les fourmis au sommet."""
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    w, d = abs(x1 - x0), abs(z1 - z0)
    collider(name, R, (w, h, d), (cx, h / 2, cz))
    along_x = w >= d
    length = max(w, d)
    n = max(1, int(length / 1.7 + 0.5))
    seg = length / n
    for k in range(n):
        t = (k + 0.5) / n
        px, pz = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
        if k % 3 == 2:
            # Serviette roulée posée sur une serviette pliée.
            folded_stack(f"{name}S{k}", R, (px, pz), seg * 0.98, min(w, d) + 0.2, h * 0.45, along_x, TOWELS)
            rolled_towel(f"{name}T{k}", R, (px, pz), seg * 0.9, (min(w, d) + 0.2) * 0.5, along_x, random.choice(TOWELS), y=h * 0.45 + (min(w, d) + 0.2) * 0.5)
        else:
            folded_stack(f"{name}S{k}", R, (px, pz), seg * 0.98, min(w, d) + 0.2, h, along_x, TEES)
        for j in range(3):
            g.sphere(f"{name}Dirt{k}_{j}", R, 0.07, (px + random.uniform(-0.3, 0.3), h + 0.02, pz + random.uniform(-0.2, 0.2)), "dirt_light", (1.2, 0.6, 1.0))
# Couloir 1 (x -49.5..-45.6, z -15..-20.5) : gravier.
cloth_wall("Wall1", -50.2, -16.5, -49.6, -20.0)
# Couloir 2 (z -19.5..-22, x -49.5..-57) : marche de carrelage avec rampe.
cloth_wall("Wall2", -47.0, -22.7, -53.6, -22.2)
cloth_wall("Wall3", -50.2, -18.6, -57.6, -19.1)
g.prop("TileStep", R, (1.4, 0.4, 2.4), (-53.0, 0.2, -20.75), "tile_shard", bevel=0.04)
g.prop("TileRamp", R, (1.4, 0.12, 1.6), (-51.8, 0.2, -21.3), "tile_shard", rot=rz(-14), bevel=0.02)
# Couloir 3 (x -57..-54.5, z -22..-26) : passage étroit entre deux cailloux.
# Lot 5.1 (finitions) : ouverture vers l'alcôve du linge (z -19.6 à -21.6).
cloth_wall("Wall4", -57.6, -21.6, -57.1, -25.4)
cloth_wall("Wall4N", -57.6, -19.1, -57.1, -19.6)
cloth_wall("Wall5", -54.0, -22.7, -53.5, -27.6)
g.sphere("PebbleA", R, 0.55, (-55.6, 0.45, -24.0), "pebble", (1.0, 0.8, 1.1))
g.prop("PebbleACol", R, (1.0, 0.9, 1.1), (-55.6, 0.45, -24.0), "pebble", cyl=True, collide=True, shadow=False)
g.sphere("PebbleB", R, 0.5, (-56.9, 0.4, -24.1), "pebble", (1.0, 0.8, 1.0))
g.prop("PebbleBCol", R, (0.95, 0.8, 0.95), (-56.9, 0.4, -24.1), "pebble", cyl=True, collide=True, shadow=False)
# Couloir 4 (devant le meuble, z -25.5..-28.3) : carrelage soulevé (jambes), larves.
# Sortie basse de l'alcôve vers l'escabeau (x -65.6 à -64.0), sous une serviette.
cloth_wall("Wall6", -57.6, -25.0, -64.0, -24.5)
cloth_wall("Wall6W", -65.6, -25.0, -66.4, -24.5)
g.prop("RaisedTile", R, (1.5, 0.36, 2.8), (-60.6, 0.18, -26.9), "tile_shard", bevel=0.04)
# Poche près du WC (cul-de-sac gardé) et ses ressources.
g.pickup("PlasticToilet", R, "bath_pl_toilet", (-51.6, 0.05, -27.6), 1, 4, 200.0)
g.pickup("FilamentToilet", R, "bath_fil_toilet", (-52.4, 0.05, -24.2), 0, 1, 300.0)
# Comblement de la zone fermée entre le pantalon et les galeries (fouillis de cotons).
for i, (x, z) in enumerate(((-59.5, -16.6), (-62.5, -16.2), (-65.5, -17.4), (-55.5, -16.4))):
    g.sphere(f"Cotton{i}", R, 1.0, (x, 0.85, z), "cotton", (1.2, 0.85, 1.1))
    g.prop(f"CottonCol{i}", R, (2.1, 1.6, 1.9), (x, 0.8, z), "cotton", cyl=True, shadow=False)
collider("ClosedFill", R, (16.0, 1.8, 3.4), (-58.6, 0.9, -16.8))
for i, x in enumerate((-64.0, -60.5, -57.0, -53.5)):
    laundry_heap(f"Heap{i}", R, (x, -16.8), 3.6, 3.4, 1.9)
# Alcôve du linge (lot 5.1) : détour depuis le couloir de la marche, refuge en hauteur
# (piles de vêtements en escalier : les soldats ne voient pas Nin0 là-haut), ressources,
# et sortie basse vers l'escabeau sous une serviette tendue (roues seulement).
A_ = "MazeRight/Alcove"
g.group("Alcove", R)
collider("AlcoveWestFill", A_, (0.8, 1.8, 5.4), (-66.4, 0.9, -21.8))
laundry_heap("AlcoveHeap", A_, (-66.0, -20.4), 1.6, 2.4, 1.6)
for name, (x, z, w, d, h) in [("RefugeStep1", (-60.3, -23.5, 1.4, 1.3, 0.5)), ("RefugeStep2", (-61.75, -23.55, 1.5, 1.35, 1.0)), ("RefugeTop", (-63.4, -23.2, 1.8, 1.9, 1.5))]:
    collider(name, A_, (w, h, d), (x, h / 2, z))
    folded_stack(f"{name}Cloth", A_, (x, z), w, d, h, True, TEES if name != "RefugeTop" else TOWELS)
g.pickup("PlasticAlcove", A_, "bath_pl_alcove", (-63.4, 1.55, -23.2), 1, 3, 200.0)
g.pickup("FilamentAlcove", A_, "bath_fil_alcove", (-59.2, 0.05, -20.4), 0, 1, 300.0)
# Serviette tendue au-dessus de la sortie (passage de 0,6 u : roues oui, jambes non).
collider("TunnelPillarW", A_, (0.5, 0.6, 0.6), (-65.85, 0.3, -24.75))
collider("TunnelPillarE", A_, (0.5, 0.6, 0.6), (-63.75, 0.3, -24.75))
collider("TunnelTowel", A_, (2.6, 0.25, 0.9), (-64.8, 0.725, -24.75))
folded_stack("TunnelPillarWCloth", A_, (-65.85, -24.75), 0.5, 0.6, 0.6, False, TEES)
folded_stack("TunnelPillarECloth", A_, (-63.75, -24.75), 0.5, 0.6, 0.6, False, TEES)
g.prop("TunnelTowelMesh", A_, (2.7, 0.22, 1.0), (-64.8, 0.72, -24.75), "towel_blue", bevel=0.1, collide=False)
g.prop("TunnelTowelHangN", A_, (2.6, 0.5, 0.08), (-64.8, 0.62, -24.25), "towel_blue", bevel=0.04, collide=False)
# Chiffons et linge tombés dans les galeries (sans collision, à plat).
for i, (x, z, sz, m) in enumerate(((-48.4, -21.2, 1.6, "rag"), (-55.4, -26.9, 1.3, "towel_rose"), (-52.6, -26.0, 1.4, "tee_grey"),
        (-58.8, -2.0, 1.5, "towel_blue"), (-60.2, -7.2, 1.2, "rag"), (-57.0, -12.0, 1.1, "tee_cream"))):
    rag(f"Rag{i}", R, (x, z), sz, m)
# Nid : trou sous un carreau cassé (fin de la colonne d'ouvrières).
g.prop("NestTileA", R, (1.2, 0.15, 1.0), (-50.9, 0.08, -14.6), "tile_shard", rot=mul(ry(20), rz(12)), bevel=0.02, collide=False)
g.prop("NestHole", R, (0.9, 0.02, 0.9), (-50.3, 0.012, -14.25), "drain_hole", cyl=True, collide=False)
g.sphere("NestMound", R, 0.6, (-50.8, 0.05, -15.0), "dirt_light", (1.4, 0.4, 1.2))
# Gravier : ralentit les roues (les jambes passent sans peine).
s.node("Gravel", "Area3D", R, f"transform = {tf(I, (-47.6, 1.0, -18.3))}\nscript = {TERRAIN}\nkey = &\"gravel\"\nwheels_factor = 0.4")
s.node("Shape", "CollisionShape3D", f"{R}/Gravel", "shape = " + s.sub("BoxShape3D", "GravelShape", f"size = {v3((3.8, 2.0, 6.4))}"))
for i in range(26):
    g.sphere(f"Grain{i}", R, random.uniform(0.07, 0.14), (random.uniform(-49.3, -45.9), 0.05, random.uniform(-21.3, -15.3)), "pebble", (1.0, 0.6, 1.0))
g.decal("GravelDirt", R, (3.8, 6.2), (-47.6, 0.014, -18.3), "stain", rx(-90))
# Soldats.
g.group("Soldiers")
def soldier(name, pts):
    flat = ", ".join(f"{p[0]}, {p[1]}, {p[2]}" for p in pts)
    s.node(name, "CharacterBody3D", "Soldiers", f"transform = {tf(I, pts[0])}\nscript = {SOLDIER}\npatrol_points = PackedVector3Array({flat})")
soldier("SoldierGravel", [(-47.6, 0.02, -16.0), (-48.2, 0.02, -20.3)])
soldier("SoldierCorridor", [(-56.4, 0.02, -20.6), (-55.6, 0.02, -21.2)])
soldier("SoldierVanity", [(-58.2, 0.02, -26.4), (-58.3, 0.02, -27.6)])
soldier("SoldierToilet", [(-51.6, 0.02, -24.6), (-52.2, 0.02, -27.0)])
# Lot 5.1 : chemin principal plus dangereux à l'approche de l'escabeau.
soldier("SoldierStep", [(-48.0, 0.02, -21.1), (-50.9, 0.02, -21.1)])
soldier("SoldierPebbles", [(-55.8, 0.02, -22.5), (-55.0, 0.02, -23.2)])
soldier("SoldierTowel", [(-57.3, 0.02, -27.8), (-59.3, 0.02, -27.8)])
# Lot 5.1 : labyrinthe gauche (souvenir n° 2) gardé par des patrouilles, contournables.
soldier("SoldierLeftSouth", [(-53.0, 0.02, -2.6), (-63.5, 0.02, -2.6)])
soldier("SoldierLeftCenter", [(-55.5, 0.02, -7.6), (-62.5, 0.02, -7.6)])
soldier("SoldierLeftUpper", [(-61.5, 0.02, -12.0), (-55.0, 0.02, -12.0)])
# Lot 7 : patrolles un peu plus denses (rondes croisées sur des couloirs déjà dégagés).
soldier("SoldierLeftSouthB", [(-63.5, 0.02, -2.6), (-53.0, 0.02, -2.6)])
soldier("SoldierStepB", [(-50.9, 0.02, -21.1), (-48.0, 0.02, -21.1)])
# Flaques d'eau savonneuse : ralentissent (roues et jambes), éclaboussent.
g.mat("puddle", (0.62, 0.72, 0.8), 0.05, extra="transparency = 1\nalbedo_color = Color(0.62, 0.72, 0.8, 0.45)\nmetallic_specular = 1.0")
for i, (px, pz, sx, sz) in enumerate(((-58.4, -2.6, 2.6, 1.8), (-59.6, -7.6, 2.2, 1.6), (-55.4, -22.4, 1.8, 1.4))):
    g.decal(f"Puddle{i}", R, (sx, sz), (px, 0.016, pz), "puddle", rx(-90))
    s.node(f"PuddleZone{i}", "Area3D", R, f"transform = {tf(I, (px, 0.5, pz))}\nscript = {TERRAIN}\nkey = &\"puddle{i}\"\nwheels_factor = 0.55\nspeed_factor = 0.7\naccel_factor = 0.7\nsplash_color = Color(0.7, 0.8, 0.9, 0.8)")
    s.node("Shape", "CollisionShape3D", f"{R}/PuddleZone{i}", "shape = " + s.sub("BoxShape3D", f"PuddleShape{i}", f"size = {v3((sx, 1.0, sz))}"))
# Larves tombant de la galerie de la serviette.
s.node("Larvae", "Node3D", R, f"transform = {tf(I, (-59.2, 0.0, -26.9))}\nscript = {LARVA}")
g.group("DropPoints", f"{R}/Larvae")
for i, (x, z) in enumerate(((-58.0, -26.7), (-59.4, -27.1), (-60.8, -26.6))):
    g.marker(f"P{i}", f"{R}/Larvae/DropPoints", (x + 59.2, 0.02, z + 26.9))

# ------------------------------------------------------------------ escabeau et appuis (vers le plan du lavabo)
g.group("Stool")
ST = "Stool"
g.prop("Step1", ST, (3.5, 0.3, 2.4), (-67.25, 2.1, -26.4), "wood_w", bevel=0.05)
g.prop("Step2", ST, (3.5, 0.3, 2.4), (-67.25, 4.35, -28.8), "wood_w", bevel=0.05)
g.prop("StoolTop", ST, (3.5, 0.3, 4.4), (-67.25, 6.6, -32.2), "wood_w", bevel=0.05)
for i, x in enumerate((-68.95, -65.55)):
    g.prop(f"RailFront{i}", ST, (0.25, 6.9, 0.3), (x, 3.3, -25.4), "wood_rail", rot=rx(-12), collide=False)
    g.prop(f"RailBack{i}", ST, (0.25, 6.8, 0.3), (x, 3.4, -34.2), "wood_rail", collide=False)
    g.prop(f"Brace{i}", ST, (0.2, 0.2, 8.6), (x, 1.0, -29.8), "wood_rail", collide=False)
g.prop("Crossbar", ST, (3.6, 0.2, 0.2), (-67.25, 1.0, -25.6), "wood_rail", collide=False)
g.prop("BoxA", ST, (1.3, 0.75, 1.1), (-63.4, 0.375, -26.4), "cardboard", bevel=0.05)
g.prop("ClothB", ST, (1.3, 0.5, 1.3), (-64.9, 0.25, -26.4), "towel", bevel=0.12)
g.prop("RollB", ST, (1.1, 1.0, 1.1), (-64.9, 1.0, -26.4), "paper", cyl=True, bevel=0.12)
g.prop("CupC", ST, (1.0, 0.75, 1.0), (-66.3, 2.625, -26.0), "plastic_g", cyl=True, bevel=0.08)
g.prop("BottleD", ST, (0.9, 1.5, 0.9), (-67.2, 3.0, -26.7), "plastic_p", cyl=True, bevel=0.15)
g.prop("SoapDishE", ST, (1.2, 0.75, 0.8), (-67.25, 4.875, -28.7), "plastic_b", bevel=0.08)
g.prop("ClothsF", ST, (1.3, 1.5, 0.8), (-67.25, 5.25, -29.6), "towel", bevel=0.2)
g.prop("BoxG", ST, (0.9, 0.75, 1.0), (-67.9, 7.125, -32.5), "cardboard", bevel=0.05)
g.prop("BooksH", ST, (2.0, 1.5, 1.4), (-66.2, 7.5, -32.5), "plastic_y", bevel=0.08)

# ------------------------------------------------------------------ arène du lavabo
s.node("SinkArena", "Node3D", ".", f"script = {ARENA}")
A = "SinkArena"
mesh = s.sub("BoxMesh", "SludgeMesh", "size = Vector3(8.9, 0.04, 4.7)")
s.node("Sludge", "MeshInstance3D", A, f"transform = {tf(I, (-59.0, 7.72, -31.8))}\nmaterial_override = {g.M['sludge']}\nmesh = {mesh}")
s.node("MireFloor", "StaticBody3D", A, f"transform = {tf(I, (-59.0, 7.47, -31.8))}\ncollision_mask = 0")
box_shape(s, "Shape", f"{A}/MireFloor", (8.9, 0.3, 4.7), (0, 0, 0))
s.node("MireZone", "Area3D", A, f"transform = {tf(I, (-59.0, 7.95, -31.8))}\nscript = {TERRAIN}\nkey = &\"mire\"\nspeed_factor = 0.38\njump_factor = 0.62\naccel_factor = 0.3\ndamage_factor = 1.25\ntick_damage = 2.0\ntick_interval = 1.6\ntick_grace = 1.2\nsink_depth = 0.2\nsink_speed = 0.16\nactive_below_y = 7.82\nsplash_color = Color(0.35, 0.4, 0.22, 0.85)")
s.node("Shape", "CollisionShape3D", f"{A}/MireZone", "shape = " + s.sub("BoxShape3D", "MireShape", f"size = {v3((8.9, 0.7, 4.7))}"))
g.group("Platforms", A)
def platform(name, pos, size, matk, cyl=False, bob=0.04, drift=(0, 0, 0), speed=0.5):
    s.node(name, "AnimatableBody3D", f"{A}/Platforms", f"transform = {tf(I, pos)}\ncollision_mask = 0\nscript = {PLATFORM}\nbob_amplitude = {bob}\ndrift = {v3(drift)}\ndrift_speed = {speed}")
    if cyl:
        shape = s.sub("CylinderShape3D", f"PlatShape_{name}", f"radius = {size[0] / 2}\nheight = {size[1]}")
        s.node("Shape", "CollisionShape3D", f"{A}/Platforms/{name}", f"shape = {shape}")
    else:
        box_shape(s, "Shape", f"{A}/Platforms/{name}", size, (0, 0, 0))
    g.prop("Mesh", f"{A}/Platforms/{name}", size, (0, 0, 0), matk, cyl=cyl, collide=False, bevel=min(size) * 0.25)
platform("P0Cap", (-63.05, 8.05, -32.6), (0.9, 0.3, 0.9), "cap", cyl=True, bob=0.0)
platform("P1Sponge", (-62.4, 7.75, -30.25), (1.2, 0.4, 1.0), "sponge_g")
platform("P2BottleCap", (-60.7, 7.77, -30.05), (1.0, 0.3, 1.0), "plastic_b", cyl=True, drift=(0.4, 0, 0), speed=0.45)
platform("P3Cotton", (-58.8, 7.78, -29.95), (1.2, 0.25, 1.2), "cotton", cyl=True)
platform("P4Soap", (-56.9, 7.75, -30.1), (1.4, 0.4, 0.8), "soap", drift=(0, 0, 0.3), speed=0.6)
platform("P5Lid", (-55.4, 7.78, -30.2), (0.9, 0.3, 0.9), "cap", cyl=True, bob=0.02)
platform("P6Shard", (-56.4, 7.78, -32.9), (1.0, 0.3, 1.0), "tile_shard", bob=0.03)
# Île de la reine : grosse éponge au fond du lavabo.
s.node("QueenIsland", "AnimatableBody3D", A, f"transform = {tf(I, (-59.0, 7.95, -32.7))}\ncollision_mask = 0")
box_shape(s, "Shape", f"{A}/QueenIsland", (2.4, 0.5, 2.0), (0, 0, 0))
g.prop("Mesh", f"{A}/QueenIsland", (2.4, 0.5, 2.0), (0, 0, 0), "sponge", collide=False, bevel=0.2)
s.node("Queen", "Node3D", A, f"transform = {tf(ry(180), (-59.0, 8.2, -32.7))}\nscript = {QUEEN}")
# Vidange : bonde, chaînette, anneau sur le rebord est.
g.prop("DrainHole", A, (0.9, 0.02, 0.9), (-59.0, 6.91, -31.0), "drain_hole", cyl=True, collide=False)
s.node("Plug", "Node3D", A, f"transform = {tf(I, (-59.0, 7.0, -31.0))}")
g.prop("PlugMesh", f"{A}/Plug", (0.95, 0.25, 0.95), (0, 0, 0), "rubber", cyl=True, collide=False, bevel=0.05)
s.node("Chain", "MeshInstance3D", A, f"material_override = {g.M['chrome']}\nscript = {CABLE}\npoints = PackedVector3Array(-59, 7.15, -31, -57.5, 7.8, -31.6, -55.4, 8.4, -32.6, -54.2, 8.6, -33.3)\nradius = 0.035")
s.node("Ring", "Node3D", A, f"transform = {tf(I, (-54.0, 8.62, -33.4))}")
g.prop("RingMesh", f"{A}/Ring", (0.5, 0.08, 0.5), (0, 0, 0), "chrome", cyl=True, collide=False, bevel=0.03)
g.interactable("RingInteract", A, (1.6, 1.2, 1.8), (-53.8, 9.0, -33.0), "Tirer la chaînette")
g.area("ArenaTrigger", A, (1.0, 2.0, 6.0), (-64.0, 9.4, -31.75))
g.area("ArenaBounds", A, (14.0, 6.0, 8.5), (-59.0, 10.0, -31.75))
g.marker("ArenaCheckpoint", A, (-67.2, 6.8, -31.6), -90)
g.marker("DrainPoint", A, (-59.0, 6.95, -31.0))

# ------------------------------------------------------------------ zones, points sûrs, lumières
g.area("EntryZone", ".", (5.0, 3.0, 9.0), (-48.2, 1.5, -7.5))
g.group("Markers")
g.marker("BathEntry", "Markers", (-47.6, 0.05, -7.5), 90)
g.marker("StoolBase", "Markers", (-61.6, 0.05, -26.9), 90)
g.marker("StoolTop", "Markers", (-67.2, 6.8, -31.6), -90)
g.marker("MazeLeftEntry", "Markers", (-49.0, 0.05, -2.6), 90)
g.marker("MazeRightEntry", "Markers", (-47.6, 0.05, -15.0), 0)
g.marker("TicketView", "Markers", (-64.0, 0.05, -12.3), 125)
s.node("CeilingLight", "OmniLight3D", ".", f"transform = {tf(I, (-60.0, 21.0, -18.0))}\nlight_color = Color(0.86, 0.92, 1, 1)\nlight_energy = 0.55\nomni_range = 30.0\nomni_attenuation = 0.8")
s.node("MirrorLight", "OmniLight3D", ".", f"transform = {tf(I, (-59.0, 15.0, -32.0))}\nlight_color = Color(1, 0.9, 0.75, 1)\nlight_energy = 0.45\nomni_range = 10.0")
s.node("MazeGlow", "OmniLight3D", ".", f"transform = {tf(I, (-58.0, 4.0, -8.0))}\nlight_color = Color(0.85, 0.9, 1, 1)\nlight_energy = 0.25\nomni_range = 9.0")
g.write(sys.argv[1])
print("bathroom ok")
