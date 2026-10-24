"""Textures procédurales originales de Nin0 (lot 7, glow-up), générées localement.
Aucune ressource externe : bruit filtré par FFT (périodique, donc raccordable), motifs
calculés. Pour chaque famille : <famille>_albedo.png (détail en niveaux de gris, multiplié
par la couleur du matériau), <famille>_normal.png, <famille>_rough.png (rugosité relative).
Usage : python3 tools/art/gen_textures.py <dossier de sortie>"""
import sys, os
import numpy as np
from PIL import Image

N = 512
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/textures/materials"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def noise(beta=2.0, aniso=(1.0, 1.0), seed=None):
    """Bruit fractal périodique (spectre en 1/f^beta), éventuellement étiré (aniso)."""
    r = np.random.default_rng(seed) if seed is not None else rng
    white = r.standard_normal((N, N))
    fx = np.fft.fftfreq(N)[None, :] * aniso[0]
    fy = np.fft.fftfreq(N)[:, None] * aniso[1]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    spec = np.fft.fft2(white) / f ** (beta / 2.0)
    spec[0, 0] = 0
    out = np.real(np.fft.ifft2(spec))
    out -= out.min()
    return out / out.max()


def norm01(a):
    a = a - a.min()
    return a / max(a.max(), 1e-9)


def normal_from_height(h, strength):
    """Normal map (OpenGL, Y+) à partir d'une hauteur périodique."""
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    nz = np.ones_like(h)
    length = np.sqrt(dx * dx + dy * dy + nz * nz)
    nx, ny, nz = -dx / length, dy / length, nz / length
    rgb = np.stack([(nx + 1) * 0.5, (ny + 1) * 0.5, (nz + 1) * 0.5], -1)
    return (rgb * 255).astype(np.uint8)


def save(name, albedo, height, rough, strength):
    Image.fromarray((np.clip(albedo, 0, 1) * 255).astype(np.uint8), "L").save(f"{OUT}/{name}_albedo.png")
    Image.fromarray(normal_from_height(height, strength), "RGB").save(f"{OUT}/{name}_normal.png")
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8), "L").save(f"{OUT}/{name}_rough.png")
    print("texture", name)


yy, xx = np.mgrid[0:N, 0:N] / N
mottle = noise(2.6, seed=1)                    # grandes taches (usure, salissures douces)

# Bois : cernes déformés + fibres fines dans le fil, nœud discret, bords plus clairs.
warp = noise(3.0, aniso=(1.0, 0.25), seed=2)
rings = 0.5 + 0.5 * np.sin((yy * 12 + warp * 0.9) * 2 * np.pi)
rings = rings ** 3
fibers = noise(1.0, aniso=(1.0, 0.03), seed=3)
wood_h = norm01(rings * 0.45 + fibers * 0.8)
wood_a = 0.8 + 0.14 * norm01(fibers) - 0.12 * rings + 0.06 * (mottle - 0.5)
save("wood", wood_a, wood_h, 0.75 + 0.25 * norm01(fibers), 2.2)

# Carton : fibres courtes en tous sens, cannelures très douces, taches d'humidité.
fiber = norm01(noise(1.0, seed=4) * 0.6 + noise(1.0, aniso=(0.2, 1.0), seed=5) * 0.4)
flutes = 0.5 + 0.5 * np.sin(yy * 2 * np.pi * 32)
card_h = norm01(fiber * 0.7 + flutes * 0.15)
card_a = 0.78 + 0.14 * fiber - 0.1 * np.clip(mottle - 0.62, 0, 1) * 3
save("cardboard", card_a, card_h, 0.85 + 0.15 * fiber, 1.6)

# Papier : grain fin et fibres, légère ondulation.
pfib = noise(0.8, seed=6)
paper_h = norm01(pfib * 0.6 + noise(2.8, seed=7) * 0.4)
save("paper", 0.86 + 0.1 * pfib + 0.04 * (mottle - 0.5), paper_h, 0.9 + 0.1 * pfib, 0.9)

# Tissu : armure toile (fils croisés), duvet, plis très doux.
n_threads = 48
u, v = xx * n_threads, yy * n_threads
cell = (np.floor(u) + np.floor(v)) % 2
warp_thread = 0.5 + 0.5 * np.cos((u % 1 - 0.5) * np.pi * 1.7)
weft_thread = 0.5 + 0.5 * np.cos((v % 1 - 0.5) * np.pi * 1.7)
weave = np.where(cell == 0, warp_thread * (0.75 + 0.25 * weft_thread), weft_thread * (0.75 + 0.25 * warp_thread))
fuzz = noise(0.6, seed=8)
fabric_h = norm01(weave * 0.8 + fuzz * 0.25 + noise(3.0, seed=9) * 0.3)
save("fabric", 0.74 + 0.2 * weave + 0.06 * (fuzz - 0.5), fabric_h, 0.92 + 0.08 * fuzz, 2.6)

# Métal : brossé dans un sens, rayures fines, quelques marques plus mates.
brushed = noise(0.9, aniso=(0.02, 1.0), seed=10)
scratches = np.zeros((N, N))
for _ in range(60):
    y0, x0 = rng.integers(0, N, 2)
    length = rng.integers(20, 140)
    ang = rng.uniform(-0.25, 0.25)
    for t in range(length):
        x = int(x0 + t * np.cos(ang)) % N
        y = int(y0 + t * np.sin(ang)) % N
        scratches[y, x] = 1.0
metal_h = norm01(brushed * 0.8 + scratches * 0.25)
save("metal", 0.84 + 0.12 * brushed + 0.04 * scratches - 0.06 * (mottle - 0.5), metal_h, 0.55 + 0.35 * brushed + 0.3 * np.clip(mottle - 0.6, 0, 1), 1.2)

# Plastique : surface lisse, micro-grain, éraflures et zones plus mates.
micro = noise(0.5, seed=11)
scuffs = np.clip(noise(1.4, aniso=(0.3, 1.0), seed=12) - 0.72, 0, 1) * 3
plastic_h = norm01(micro * 0.3 + scuffs * 0.7)
save("plastic", 0.9 + 0.06 * micro - 0.08 * scuffs, plastic_h, 0.6 + 0.25 * micro + 0.3 * scuffs, 0.7)

# Enduit / peinture murale : mouchetis, coups de rouleau, taches anciennes.
roller = noise(2.2, aniso=(1.0, 0.25), seed=13)
grit = noise(0.7, seed=14)
plaster_h = norm01(grit * 0.5 + roller * 0.5)
save("plaster", 0.86 + 0.08 * roller + 0.05 * grit - 0.08 * np.clip(mottle - 0.65, 0, 1) * 3, plaster_h, 0.9 + 0.1 * grit, 1.4)

# Céramique / émail : très lisse, légères ondulations, craquelures fines.
crack = np.abs(noise(1.6, seed=15) - 0.5) < 0.006
ceramic_h = norm01(noise(2.6, seed=16) * 0.8 - crack * 0.4)
save("ceramic", 0.94 + 0.04 * noise(2.0, seed=17) - 0.12 * crack, ceramic_h, 0.25 + 0.2 * noise(1.8, seed=18) + 0.4 * crack, 0.6)

# Sol (lames, carrelage du placard…) : grain usé, passages plus lisses.
floor_h = norm01(noise(1.4, aniso=(0.15, 1.0), seed=19) * 0.6 + mottle * 0.4)
save("floor", 0.78 + 0.16 * floor_h - 0.06 * (mottle - 0.5), floor_h, 0.7 + 0.25 * floor_h, 1.4)

# Feuilles : nervures, transparence suggérée (albédo plus clair au centre).
vein = np.abs(np.sin((xx + noise(2.5, seed=20) * 0.1) * 2 * np.pi * 6)) < 0.08
leaf_h = norm01(noise(1.8, seed=21) * 0.6 + vein * 0.6)
save("leaf", 0.8 + 0.15 * noise(2.0, seed=22) + 0.08 * vein, leaf_h, 0.6 + 0.2 * noise(1.0, seed=23), 1.0)
