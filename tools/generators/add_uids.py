"""Ajoute les uid:// (format Godot 4.4+) aux en-têtes et aux ext_resource des .tscn/.tres,
sans modifier le reste du contenu. Usage : add_uids.py <racine du projet>"""
import os, re, sys, random
ROOT = sys.argv[1]
ALPHA = "abcdefghijklmnopqrstuvwxyz0123456789"
def new_uid(used):
    while True:
        n = random.getrandbits(63) or 1
        s = ""
        while n:
            s = ALPHA[n % 36] + s
            n //= 36
        u = "uid://" + s
        if u not in used:
            used.add(u); return u
def res_path(p): return "res://" + os.path.relpath(p, ROOT).replace(os.sep, "/")
files = []
for r, ds, fs in os.walk(ROOT):
    ds[:] = [d for d in ds if not d.startswith(".")]
    files += [os.path.join(r, f) for f in fs]
uids, used = {}, set()
for f in files:  # uid existants : .uid (scripts, shaders), .import (textures), en-têtes
    if f.endswith(".uid"):
        u = open(f).read().strip(); uids[res_path(f[:-4])] = u
    elif f.endswith(".import"):
        m = re.search(r'^uid="(uid://[a-z0-9]+)"', open(f, encoding="utf-8").read(), re.M)
        if m: uids[res_path(f[:-7])] = m.group(1)
    elif f.endswith((".tscn", ".tres")):
        m = re.search(r'uid="(uid://[a-z0-9]+)"', open(f, encoding="utf-8").readline())
        if m: uids[res_path(f)] = m.group(1)
used |= set(uids.values())
scenes = [f for f in files if f.endswith((".tscn", ".tres"))]
for f in scenes:
    if res_path(f) not in uids: uids[res_path(f)] = new_uid(used)
missing = 0
for f in scenes:
    text = open(f, encoding="utf-8").read()
    lines = text.split("\n")
    if 'uid="' not in lines[0]:
        lines[0] = lines[0][:-1] + ' uid="%s"]' % uids[res_path(f)]
    for i, line in enumerate(lines):
        if line.startswith("[ext_resource") and ' uid="' not in line:
            path = re.search(r'path="([^"]+)"', line).group(1)
            if path in uids:
                lines[i] = re.sub(r'(type="[^"]+")', r'\1 uid="%s"' % uids[path], line, count=1)
            else:
                print("SANS UID", f, path); missing += 1
    new = "\n".join(lines)
    if new != text:
        open(f, "w", encoding="utf-8").write(new)
print("fichiers:", len(scenes), "références sans uid:", missing)
