"""Outils communs aux générateurs des zones jouables (lot 5)."""
import sys, math, random
sys.path.insert(0, sys.path[0])
from tscn import *

class Gen:
    def __init__(self, root_name, script_path):
        self.s = Scene()
        self.PROP = self.s.ext_res("Script", "res://scripts/props/prop_block.gd")
        self.PICKUP = self.s.ext_res("Script", "res://scripts/props/resource_pickup.gd")
        self.INTER = self.s.ext_res("Script", "res://scripts/interaction/interactable.gd")
        self.FOCUS = self.s.ext_res("Script", "res://scripts/focus/focus_target.gd")
        self.M = {}
        script = self.s.ext_res("Script", script_path)
        self.s.node(root_name, "Node3D", None, f"script = {script}")
    def mat(self, key, color, rough=0.8, metal=0.0, extra=""):
        if key not in self.M:
            self.M[key] = std_mat(self.s, f"Mat_{key}", color, rough, metal, extra=extra)
        return self.M[key]
    def group(self, name, parent="."):
        self.s.node(name, "Node3D", parent)
    def prop(self, name, parent, size, pos, mat, rot=I, bevel=0.03, cyl=False, collide=True, climbable=False, shadow=True, layer=None):
        props = f"transform = {tf(rot, pos)}\nscript = {self.PROP}"
        if cyl: props += "\nshape = 1"
        props += f"\nsize = {v3(size)}\nbevel = {bevel}\nmaterial = {self.M[mat]}"
        if climbable: props += "\nclimbable = true"
        if not collide: props += "\ncollide = false"
        if not shadow: props += "\ncast_shadow = false"
        if layer is not None: props += f"\ncollision_layer = {layer}"
        self.s.node(name, "StaticBody3D", parent, props)
    def decal(self, name, parent, size, pos, mat, rot=I):
        """Plan fin sans collision (tache, poussière, fissure)."""
        mesh = self.s.sub("QuadMesh", f"Quad_{name}", f"size = Vector2({size[0]}, {size[1]})")
        self.s.node(name, "MeshInstance3D", parent, f"transform = {tf(rot, pos)}\nmaterial_override = {self.M[mat]}\ncast_shadow = 0\nmesh = {mesh}")
    def sphere(self, name, parent, r, pos, mat, scale_v=(1, 1, 1)):
        mesh = self.s.sub("SphereMesh", f"Sph_{str(r).replace('.', '_')}", f"radius = {r}\nheight = {2*r}\nradial_segments = 14\nrings = 7")
        self.s.node(name, "MeshInstance3D", parent, f"transform = {tf(scale(I, scale_v), pos)}\nmaterial_override = {self.M[mat]}\nmesh = {mesh}")
    def pickup(self, name, parent, pid, pos, kind=0, amount=1, delay=300.0):
        self.s.node(name, "Area3D", parent, f"transform = {tf(I, pos)}\nscript = {self.PICKUP}\nid = &\"{pid}\"\nkind = {kind}\namount = {amount}\nrespawn_delay = {delay}")
    def marker(self, name, parent, pos, yaw=0.0):
        self.s.node(name, "Marker3D", parent, f"transform = {tf(ry(yaw), pos)}")
    def area(self, name, parent, size, pos, script=None, props="", mask=4):
        shape = self.s.sub("BoxShape3D", f"AreaShape_{name}", f"size = {v3(size)}")
        extra = f"\nscript = {script}" if script else ""
        self.s.node(name, "Area3D", parent, f"transform = {tf(I, pos)}\ncollision_layer = 0\ncollision_mask = {mask}\nmonitorable = false{extra}" + (("\n" + props) if props else ""))
        self.s.node("Shape", "CollisionShape3D", f"{parent}/{name}", f"shape = {shape}")
    def interactable(self, name, parent, size, pos, prompt):
        shape = self.s.sub("BoxShape3D", f"InterShape_{name}", f"size = {v3(size)}")
        self.s.node(name, "Area3D", parent, f"transform = {tf(I, pos)}\ncollision_layer = 8\ncollision_mask = 0\nmonitoring = false\nscript = {self.INTER}\nprompt = \"{prompt}\"")
        self.s.node("Shape", "CollisionShape3D", f"{parent}/{name}", f"shape = {shape}")
    def collider(self, name, parent, size, pos, cyl=False):
        """Collision seule, sans maillage (l'apparence est faite d'autres pièces)."""
        self.s.node(name, "StaticBody3D", parent, f"transform = {tf(I, pos)}\ncollision_mask = 0")
        if cyl:
            shape = self.s.sub("CylinderShape3D", f"ColCyl_{name}", f"radius = {size[0] / 2}\nheight = {size[1]}")
        else:
            shape = self.s.sub("BoxShape3D", f"ColBox_{name}", f"size = {v3(size)}")
        self.s.node("Shape", "CollisionShape3D", f"{parent}/{name}", f"shape = {shape}")
    def crumpled_paper(self, name, parent, pos, radius, mats, ink=None):
        """Boule de papier froissé : facettes anguleuses entremêlées, plis, traces d'encre,
        et une vraie collision (cylindre)."""
        self.group(name, parent)
        path = f"{parent}/{name}" if parent != "." else name
        for k in range(9):
            sx, sy, sz = (random.uniform(0.9, 1.4) * radius for _ in range(3))
            rot = mul(rx(random.uniform(0, 90)), mul(ry(random.uniform(0, 90)), rz(random.uniform(0, 90))))
            off = (random.uniform(-0.25, 0.25) * radius, random.uniform(-0.15, 0.2) * radius, random.uniform(-0.25, 0.25) * radius)
            self.prop(f"Facet{k}", path, (sx, sy * 0.8, sz), (pos[0] + off[0], pos[1] + radius * 0.85 + off[1], pos[2] + off[2]), mats[k % len(mats)], rot=rot, bevel=0.04, collide=False)
        if ink:
            for k in range(3):
                self.prop(f"Ink{k}", path, (radius * 0.9, 0.012, 0.05), (pos[0] + random.uniform(-0.3, 0.3) * radius, pos[1] + radius * 1.62, pos[2] + random.uniform(-0.3, 0.3) * radius), ink, rot=ry(random.uniform(0, 180)), bevel=0.0, collide=False, shadow=False)
        self.collider(f"{name}Col", parent, (radius * 2.1, radius * 1.7, 0), (pos[0], pos[1] + radius * 0.85, pos[2]), cyl=True)
    def cloth(self, name, parent, pos, size, mat, folds=4):
        """Chiffon tombé à plat : couches fines et souples, bords repliés (sans collision,
        Nin0 roule dessus comme sur un tissu)."""
        self.group(name, parent)
        path = f"{parent}/{name}" if parent != "." else name
        base_rot = random.uniform(0, 180)
        for k in range(folds):
            w = size * random.uniform(0.55, 1.0)
            d = size * random.uniform(0.4, 0.8)
            off = (random.uniform(-0.25, 0.25) * size, random.uniform(-0.2, 0.2) * size)
            self.prop(f"Layer{k}", path, (w, 0.035, d), (pos[0] + off[0], 0.02 + k * 0.012, pos[1] + off[1]), mat, rot=mul(ry(base_rot + random.uniform(-40, 40)), rz(random.uniform(-4, 4))), bevel=0.016, collide=False, shadow=False)
        self.prop("Roll", path, (0.12, size * 0.7, 0.12), (pos[0], 0.06, pos[1]), mat, rot=mul(ry(base_rot), rz(90)), cyl=True, bevel=0.05, collide=False, shadow=False)
    def path(self, name, parent, points):
        flat = ", ".join(f"0, 0, 0, 0, 0, 0, {p[0]:.4g}, {p[1]:.4g}, {p[2]:.4g}" for p in points)
        curve = self.s.sub("Curve3D", f"Curve_{name}", f"_data = {{\n\"points\": PackedVector3Array({flat}),\n\"tilts\": PackedFloat32Array({', '.join('0' for _ in points)})\n}}\npoint_count = {len(points)}")
        self.s.node(name, "Path3D", parent, f"curve = {curve}")
    def write(self, path):
        self.s.write(path)
