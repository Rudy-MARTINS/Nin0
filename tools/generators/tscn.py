"""Petit utilitaire d'écriture de fichiers .tscn (scènes Godot 4)."""
import math

def rows(m): return ", ".join(f"{v:.6g}" for r in m for v in r)
def mul(a, b): return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def rx(d):
    t=math.radians(d); c,s=math.cos(t),math.sin(t); return [[1,0,0],[0,c,-s],[0,s,c]]
def ry(d):
    t=math.radians(d); c,s=math.cos(t),math.sin(t); return [[c,0,s],[0,1,0],[-s,0,c]]
def rz(d):
    t=math.radians(d); c,s=math.cos(t),math.sin(t); return [[c,-s,0],[s,c,0],[0,0,1]]
I=[[1,0,0],[0,1,0],[0,0,1]]
def scale(m, s): return [[m[i][j]*(s[j] if isinstance(s,(list,tuple)) else s) for j in range(3)] for i in range(3)]
def tf(rot, pos): return f"Transform3D({rows(rot)}, {pos[0]:.6g}, {pos[1]:.6g}, {pos[2]:.6g})"
def v3(v): return f"Vector3({v[0]:.6g}, {v[1]:.6g}, {v[2]:.6g})"

class Scene:
    def __init__(self):
        self.ext = []      # (type, path, id)
        self.subs = []
        self.nodes = []
        self._ext_ids = {}
        self._sub_ids = set()
    def ext_res(self, typ, path):
        if path not in self._ext_ids:
            rid = f"{len(self.ext)+1}_{path.split('/')[-1].split('.')[0][:12]}"
            self._ext_ids[path] = rid
            self.ext.append((typ, path, rid))
        return f'ExtResource("{self._ext_ids[path]}")'
    def sub(self, typ, rid, props=""):
        if rid not in self._sub_ids:
            self._sub_ids.add(rid)
            self.subs.append(f'[sub_resource type="{typ}" id="{rid}"]' + (("\n" + props) if props else ""))
        return f'SubResource("{rid}")'
    def node(self, name, typ, parent, props="", instance=None, node_paths=None):
        head = f'[node name="{name}"'
        if typ: head += f' type="{typ}"'
        if parent is not None: head += f' parent="{parent}"'
        if node_paths: head += ' node_paths=PackedStringArray(' + ", ".join(f'"{n}"' for n in node_paths) + ')'
        if instance: head += f' instance={instance}'
        head += "]"
        self.nodes.append(head + (("\n" + props) if props else ""))
    def write(self, path):
        import os, re
        header = "[gd_scene format=3]"
        if os.path.exists(path):  # conserve l'uid de la scène (références uid:// des autres fichiers)
            m = re.search(r'uid="(uid://[a-z0-9]+)"', open(path, encoding="utf-8").readline())
            if m:
                header = f'[gd_scene format=3 uid="{m.group(1)}"]'
        out = header + "\n\n"
        for typ, p, rid in self.ext:
            out += f'[ext_resource type="{typ}" path="{p}" id="{rid}"]\n'
        out += "\n" + "\n\n".join(self.subs) + "\n\n" + "\n\n".join(self.nodes) + "\n"
        open(path, "w").write(out)

def std_mat(scene, rid, albedo, rough=0.6, metal=0.0, emission=None, energy=1.0, extra=""):
    props = f"albedo_color = Color({albedo[0]}, {albedo[1]}, {albedo[2]}, 1)\nroughness = {rough}"
    if metal: props += f"\nmetallic = {metal}"
    if emission: props += f"\nemission_enabled = true\nemission = Color({emission[0]}, {emission[1]}, {emission[2]}, 1)\nemission_energy_multiplier = {energy}"
    if extra: props += "\n" + extra
    return scene.sub("StandardMaterial3D", rid, props)

def pmesh(scene, name, parent, kind, size, bevel, pos, mat, rot=I, segments=None, extra=""):
    script = scene.ext_res("Script", "res://scripts/tools/procedural_mesh.gd")
    props = f"transform = {tf(rot, pos)}\nmaterial_override = {mat}\nscript = {script}\nkind = {kind}\nsize = {v3(size)}\nbevel = {bevel}"
    if segments: props += f"\nsegments = {segments}"
    if extra: props += "\n" + extra
    scene.node(name, "MeshInstance3D", parent, props)

def sphere(scene, name, parent, r, pos, mat, extra=""):
    mesh = scene.sub("SphereMesh", f"Sphere_{str(r).replace('.','_')}", f"radius = {r}\nheight = {2*r}\nradial_segments = 16\nrings = 8")
    scene.node(name, "MeshInstance3D", parent, f"transform = {tf(I,pos)}\nmaterial_override = {mat}\nmesh = {mesh}" + (("\n"+extra) if extra else ""))

def box_shape(scene, name, parent, size, pos, rot=I):
    shape = scene.sub("BoxShape3D", "BoxShape_" + "_".join(f"{v:g}".replace('.','p').replace('-','m') for v in size), f"size = {v3(size)}")
    scene.node(name, "CollisionShape3D", parent, f"transform = {tf(rot,pos)}\nshape = {shape}")
BOX, CYL = 0, 1
