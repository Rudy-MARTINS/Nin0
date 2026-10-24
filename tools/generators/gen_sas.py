"""Sas (zone 2) jouable : décor d'abandon, colonne de fourmis, porte du salon (fermée),
porte de la cuisine (loquet à déclencher au canon), ressources. Usage : gen_sas.py <sortie>"""
import sys
sys.path.insert(0, sys.path[0])
from gen_common import *
random.seed(5)
g = Gen("SasZone", "res://scripts/zones/sas_zone.gd")
s = g.s
COLUMN = s.ext_res("Script", "res://scripts/creatures/ant_column.gd")
KDOOR = s.ext_res("Script", "res://scripts/zones/kitchen_door.gd")
LANDMARK = s.ext_res("Resource", "res://assets/observation/landmark.tres")
g.mat("wood", (0.42, 0.3, 0.2), 0.7)
g.mat("wood_dark", (0.26, 0.18, 0.12), 0.8)
g.mat("plinth", (0.3, 0.22, 0.15), 0.8)
g.mat("shoe", (0.24, 0.3, 0.4), 0.9)
g.mat("shoe_b", (0.55, 0.22, 0.18), 0.9)
g.mat("sole", (0.88, 0.86, 0.8), 0.7)
g.mat("umbrella", (0.18, 0.22, 0.3), 0.6)
g.mat("metal", (0.55, 0.56, 0.58), 0.35, 0.8)
g.mat("paper", (0.86, 0.84, 0.78), 0.9)
g.mat("leaf", (0.55, 0.42, 0.24), 0.9)
g.mat("plaster", (0.84, 0.82, 0.77), 0.9)
g.mat("mat", (0.55, 0.42, 0.26), 1.0)
g.mat("dirt", (0.36, 0.27, 0.18), 1.0)
g.mat("door", (0.5, 0.36, 0.24), 0.6)
g.mat("brass", (0.78, 0.62, 0.32), 0.3, 0.85)
g.mat("toy", (0.85, 0.3, 0.25), 0.6)
g.mat("scarf", (0.55, 0.5, 0.3), 1.0)
for k, a in (("dust", 0.28), ("stain", 0.32), ("crack", 0.85)):
    col = {"dust": (0.55, 0.52, 0.46), "stain": (0.3, 0.27, 0.2), "crack": (0.12, 0.1, 0.08)}[k]
    g.mat(k, col, 1.0, extra=f"transparency = 1\nalbedo_color = Color({col[0]}, {col[1]}, {col[2]}, {a})\ncull_mode = 2")

g.group("Decor")
D = "Decor"
# Plinthes.
g.prop("PlinthNorth", D, (29.4, 0.8, 0.15), (-30.3, 0.4, -14.92), "plinth", collide=False)
g.prop("PlinthSouthA", D, (8.6, 0.8, 0.15), (-40.3, 0.4, 11.92), "plinth", collide=False)
g.prop("PlinthSouthB", D, (11.0, 0.8, 0.15), (-21.1, 0.4, 11.92), "plinth", collide=False)
# Poussière au sol, taches d'humidité, fissure d'où sortent les fourmis.
for i in range(9):
    x, z = random.uniform(-43, -18), random.uniform(-13, 10)
    g.decal(f"Dust{i}", D, (random.uniform(2, 5), random.uniform(1.5, 4)), (x, 0.012 + i * 0.001, z), "dust", rx(-90))
g.decal("StainNorth", D, (6.0, 9.0), (-40.0, 18.0, -14.97), "stain")
g.decal("StainNorthLow", D, (4.0, 2.5), (-20.0, 1.5, -14.97), "stain")
g.decal("StainBath", D, (3.0, 6.0), (-44.97, 3.0, -1.0), "stain", ry(90))
g.decal("CrackWest", D, (0.25, 3.2), (-44.97, 1.6, 11.3), "crack", mul(ry(90), rz(6)))
g.decal("CrackWestB", D, (0.18, 1.8), (-44.96, 3.6, 11.0), "crack", mul(ry(90), rz(-20)))
g.decal("CrackCeiling", D, (0.2, 6.0), (-33.0, 23.85, -6.0), "crack", mul(rx(90), rz(30)))
g.sphere("DirtPile", D, 0.7, (-44.3, 0.0, 11.2), "dirt", (1.4, 0.2, 1.0))
for i in range(6):
    g.sphere(f"DirtGrain{i}", D, 0.12, (-43.6 + random.uniform(-0.6, 0.6), 0.06, 10.5 + random.uniform(-0.8, 0.8)), "dirt")
# Meuble à chaussures (mur nord), chaussures, parapluie tombé.
g.prop("ShoeCabinet", D, (10.0, 9.0, 3.4), (-31.0, 4.6, -13.25), "wood", bevel=0.08)
g.prop("ShoeCabinetTop", D, (10.4, 0.3, 3.7), (-31.0, 9.25, -13.2), "wood_dark", bevel=0.06)
for i, x in enumerate((-35.6, -26.4)):
    g.prop(f"ShoeCabinetFoot{i}", D, (0.6, 0.2, 2.8), (x, 0.1, -13.25), "wood_dark", collide=False)
for i, x in enumerate((-33.5, -28.5)):
    g.prop(f"ShoeCabinetDoor{i}", D, (4.6, 7.6, 0.08), (x, 4.7, -11.52), "wood_dark", bevel=0.02, collide=False)
    g.prop(f"ShoeCabinetKnob{i}", D, (0.25, 0.25, 0.25), (x + (1.9 if i == 0 else -1.9), 5.0, -11.42), "brass", cyl=True, rot=rx(90), collide=False)
g.prop("KeyTray", D, (2.0, 0.3, 1.2), (-33.5, 9.55, -13.0), "metal", bevel=0.05)
g.prop("ShoeA", D, (1.1, 1.0, 2.7), (-24.0, 0.55, -11.4), "shoe", rot=ry(18), bevel=0.4)
g.prop("ShoeASole", D, (1.15, 0.25, 2.75), (-24.0, 0.12, -11.4), "sole", rot=ry(18), bevel=0.1, collide=False)
g.prop("ShoeB", D, (1.1, 1.0, 2.7), (-21.8, 0.55, -10.6), "shoe_b", rot=ry(-35), bevel=0.4)
g.prop("ShoeBSole", D, (1.15, 0.25, 2.75), (-21.8, 0.12, -10.6), "sole", rot=ry(-35), bevel=0.1, collide=False)
g.prop("UmbrellaShaft", D, (0.25, 10.0, 0.25), (-37.0, 0.35, 10.3), "metal", rot=mul(ry(-6), rz(90)), cyl=True)
g.prop("UmbrellaCanopy", D, (1.1, 5.0, 1.1), (-38.6, 0.6, 10.0), "umbrella", rot=mul(ry(-6), rz(90)), cyl=True, bevel=0.4)
g.prop("UmbrellaHandle", D, (0.5, 1.2, 0.5), (-32.4, 0.4, 11.1), "wood_dark", rot=mul(ry(-6), rz(90)), cyl=True)
# Débris : boulette de papier, feuille morte, éclats de plâtre (fissure du plafond).
g.mat("paper_b", (0.8, 0.78, 0.72), 0.95)
g.mat("ink", (0.25, 0.25, 0.32), 0.9)
g.crumpled_paper("PaperBall", D, (-38.0, 0.0, -5.5), 0.62, ["paper", "paper_b"], ink="ink")
g.prop("DeadLeaf", D, (1.6, 0.05, 2.4), (-25.0, 0.03, 4.0), "leaf", rot=ry(35), collide=False)
for i in range(7):
    g.prop(f"PlasterChip{i}", D, (random.uniform(0.2, 0.6), 0.12, random.uniform(0.2, 0.5)), (-33.0 + random.uniform(-2.5, 2.5), 0.06, -6.0 + random.uniform(-2, 2)), "plaster", rot=ry(random.uniform(0, 90)), collide=False)
# Paillasson devant la porte du placard, patère et écharpe.
g.prop("DoorMat", D, (4.0, 0.06, 6.0), (-19.0, 0.03, 5.5), "mat", collide=False, bevel=0.02)
g.prop("CoatRail", D, (0.3, 0.4, 6.0), (-15.9, 17.5, -8.0), "wood_dark", collide=False)
for i, z in enumerate((-10.0, -8.0, -6.0)):
    g.prop(f"CoatHook{i}", D, (0.6, 0.15, 0.15), (-16.2, 17.2, z), "brass", collide=False)
g.prop("Scarf", D, (0.5, 7.0, 1.6), (-16.5, 13.8, -8.0), "scarf", bevel=0.2, collide=False)
# Petite boîte de billes renversée (jouet) près de la porte de la cuisine : réserve de plastique.
g.prop("BeadBox", D, (2.0, 1.4, 1.4), (-41.6, 0.7, 10.6), "toy", rot=mul(ry(25), rz(80)), bevel=0.08)
# Éclairage mesuré : plafonnier faible, lumière froide venant de la salle de bain.
s.node("CeilingLight", "OmniLight3D", ".", f"transform = {tf(I, (-30.0, 21.0, -1.5))}\nlight_color = Color(0.95, 0.9, 0.82, 1)\nlight_energy = 0.4\nomni_range = 22.0\nomni_attenuation = 0.9")
s.node("BathGlow", "OmniLight3D", ".", f"transform = {tf(I, (-43.0, 5.0, -7.5))}\nlight_color = Color(0.7, 0.82, 1, 1)\nlight_energy = 0.35\nomni_range = 10.0")

# Colonne de fourmis : de la fissure du sas jusqu'au trou du nid, dans la salle de bain.
s.node("AntColumn", "Node3D", ".", f"script = {COLUMN}\ncount = 9")
g.path("Path", "AntColumn", [(-44.2, 0.0, 11.2), (-43.4, 0.0, 9.0), (-43.6, 0.0, 6.0), (-43.2, 0.0, 2.5), (-43.4, 0.0, -1.5), (-44.0, 0.0, -5.5),
    (-45.3, 0.0, -7.2), (-47.5, 0.0, -8.4), (-49.6, 0.0, -10.0), (-50.4, 0.0, -12.6), (-50.3, 0.0, -14.2)])

# Rencontre : une ouvrière traverse le passage devant Nin0.
g.group("Encounter")
g.marker("Start", "Encounter", (-19.0, 0.0, -0.15))
g.marker("Stop", "Encounter", (-18.6, 0.0, 1.0))
g.marker("Leave", "Encounter", (-22.6, 0.0, -2.2))
g.area("EncounterZone", ".", (2.6, 2.0, 4.0), (-17.2, 1.0, 2.0))

# Porte du salon : fermée (blockout). Nin0 peut l'examiner.
g.interactable("SalonDoorInspect", ".", (9.0, 2.0, 1.6), (-31.5, 1.0, 11.2), "Examiner la porte")
# Porte de la cuisine : battant à charnière, loquet en hauteur côté sas.
s.node("KitchenDoor", "Node3D", ".", f"transform = {tf(I, (-45.3, 0.0, 10.6))}\nscript = {KDOOR}")
s.node("Hinge", "Node3D", "KitchenDoor")
s.node("Panel", "AnimatableBody3D", "KitchenDoor/Hinge", "collision_mask = 0")
box_shape(s, "Shape", "KitchenDoor/Hinge/Panel", (0.4, 20.2, 8.1), (0.0, 10.1, -4.05))
g.prop("Slab", "KitchenDoor/Hinge/Panel", (0.4, 20.2, 8.1), (0.0, 10.1, -4.05), "door", collide=False, bevel=0.05)
g.prop("MoldingUpper", "KitchenDoor/Hinge/Panel", (0.06, 7.0, 6.0), (0.22, 14.2, -4.05), "wood_dark", collide=False, bevel=0.02)
g.prop("MoldingLower", "KitchenDoor/Hinge/Panel", (0.06, 6.0, 6.0), (0.22, 5.0, -4.05), "wood_dark", collide=False, bevel=0.02)
g.prop("Knob", "KitchenDoor/Hinge/Panel", (0.6, 0.6, 0.6), (0.4, 10.0, -7.3), "brass", cyl=True, rot=rz(90), collide=False)
g.prop("Eye", "KitchenDoor/Hinge/Panel", (0.18, 0.5, 0.18), (0.32, 14.0, -7.7), "brass", collide=False)
# Crochet (sur le chambranle) : il retient le battant ; une bille peut le soulever.
s.node("HookPivot", "Node3D", "KitchenDoor", f"transform = {tf(I, (0.35, 14.0, -8.75))}")
g.prop("HookBase", "KitchenDoor", (0.2, 0.6, 0.35), (0.33, 14.0, -8.8), "brass", collide=False)
g.prop("Hook", "KitchenDoor/HookPivot", (0.12, 0.12, 1.1), (0.0, 0.0, 0.5), "brass", bevel=0.04, collide=False)
s.node("HookTarget", "StaticBody3D", "KitchenDoor/HookPivot", "collision_layer = 32\ncollision_mask = 0")
box_shape(s, "Shape", "KitchenDoor/HookPivot/HookTarget", (0.7, 0.7, 1.6), (0.0, 0.0, 0.5))
s.node("LatchFocus", "Marker3D", "KitchenDoor/HookPivot", f"transform = {tf(I, (0.0, 0.0, 0.5))}\nscript = {g.FOCUS}\nid = &\"kitchen_latch\"\nradius = 0.6\nprofile = {LANDMARK}\nthought_icons = Array[StringName]([&\"lock\", &\"up\"])")
g.interactable("KitchenDoorInspect", "KitchenDoor", (1.6, 2.0, 7.6), (0.9, 1.0, -4.1), "Examiner la porte")
s.node("KitchenLight", "OmniLight3D", "KitchenDoor", f"transform = {tf(I, (-6.0, 8.0, -4.0))}\nlight_color = Color(1, 0.85, 0.62, 1)\nlight_energy = 0.0\nomni_range = 14.0")

# Ressources ordinaires (réapparaissent) et réserve de plastique près de la cuisine.
g.group("Pickups")
g.pickup("FilamentShoes", "Pickups", "sas_fil_shoes", (-26.6, 0.05, -10.6), 0)
g.pickup("FilamentCorner", "Pickups", "sas_fil_corner", (-43.6, 0.05, -13.6), 0)
g.pickup("PlasticUmbrella", "Pickups", "sas_pl_umbrella", (-34.6, 0.05, 8.4), 1, 3, 180.0)
g.pickup("PlasticCabinet", "Pickups", "sas_pl_cabinet", (-17.4, 0.05, -13.6), 1, 3, 180.0)
g.pickup("PlasticReserve", "Pickups", "sas_pl_reserve", (-40.4, 0.05, 9.0), 1, 4, 25.0)

g.group("Markers")
g.marker("SasEntry", "Markers", (-19.5, 0.05, 1.4), 90)
g.marker("KitchenDoorFront", "Markers", (-38.0, 0.05, 6.5), 90)
# Repère de tir : assez loin pour viser le crochet en vision focalisée (≈ 50°).
g.marker("FireSpot", "Markers", (-33.5, 0.05, 3.2), 82)
g.write(sys.argv[1])
print("sas ok")
