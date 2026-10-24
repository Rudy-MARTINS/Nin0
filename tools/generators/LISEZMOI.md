# Générateurs de scènes (outils de développement)

Scripts Python qui produisent les scènes des zones jouables à partir d'une description
en code (positions en unités de jeu, 1 u = 10 cm). Ils ne sont pas utilisés par le jeu.

| Script | Scène produite |
|---|---|
| `gen_apartment.py` | `scenes/levels/apartment_blockout.tscn` (murs, sols, zones de l'appartement) |
| `gen_sas.py` | `scenes/zones/sas_zone.tscn` |
| `gen_bathroom.py` | `scenes/zones/bathroom_zone.tscn` |
| `gen_kitchen.py` | `scenes/zones/kitchen_zone.tscn` |

Usage (depuis la racine du projet) :

```
python3 tools/generators/gen_kitchen.py scenes/zones/kitchen_zone.tscn
godot --headless --editor --quit        # import (nouvelles classes, uid des scripts)
python3 tools/generators/add_uids.py .  # ajoute les uid:// manquants dans les scènes
```

L'uid de chaque scène est conservé lors d'une régénération (`tscn.py`).
