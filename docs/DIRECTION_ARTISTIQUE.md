# Direction artistique de Nin0

3D indépendante, stylisée, chaleureuse et légèrement mélancolique. Formes simples et
lisibles, couleurs douces, surfaces qui racontent l'usure d'un vrai appartement. Pas de
photoréalisme. Toutes les ressources sont **originales** (procédurales ou dessinées en code).

## Palette

| Rôle | Couleur | Usage |
|---|---|---|
| Crème | `#F7EDD9` (0.97, 0.93, 0.85) | châssis de Nin0, textes, logo |
| Orange doux | `#F59947` (0.96, 0.6, 0.28) | accents, survol, liserés, bulle de l'antenne |
| Cyan | `#80EDFF` (0.5, 0.93, 1.0) | écran-visage, scan, focus clavier, savoir appris |
| Bleu-gris profond | `#181C24` (0.095, 0.11, 0.14) | fonds de panneaux, ombres d'interface |

Constantes : `UiKit.CREAM`, `UiKit.ORANGE`, `UiKit.CYAN`, `UiKit.INK`.

## Bibliothèque de matériaux

`scripts/core/material_library.gd` (`MaterialLibrary`). Chaque `StandardMaterial3D` généré
(identifiant `Mat_<nom>`) reçoit, selon sa famille, un détail d'albédo en niveaux de gris
(sa couleur est conservée), une normal map, une carte de rugosité, en projection
triplanaire (aucune UV à refaire). Familles :

| Famille | Tuile | Caractère |
|---|---|---|
| wood | 30 cm | cernes déformés, fibres dans le fil |
| cardboard | 22 cm | fibres courtes, cannelures, taches d'humidité |
| paper | 16 cm | grain fin |
| fabric | 8 cm | armure toile (48 fils), duvet |
| metal | 12 cm | brossé, rayures fines |
| plastic | 14 cm | micro-grain, éraflures mates |
| plaster | 60 cm | mouchetis, coups de rouleau |
| ceramic | 24 cm | émail lisse, craquelures |
| floor | 40 cm | grain usé |

La famille est déduite de mots-clés de l'identifiant (`KEYWORDS`, le premier qui correspond
gagne) ; vitres, eau, écrans, émissifs, transparents et matériaux déjà texturés sont
ignorés. Un matériau créé en code peut appeler `MaterialLibrary.apply_family(mat, &"wood")`.
L'imprimante utilise une table explicite (`Printer3D.MATERIAL_FAMILIES`). Le modèle de
Nin0 n'est pas modifié.

Textures : `assets/textures/materials/<famille>_{albedo,normal,rough}.png`, 512², raccordables,
produites par `tools/art/gen_textures.py` (numpy + Pillow, bruit filtré par FFT, aucune
ressource externe). Régénération : `python3 tools/art/gen_textures.py`.

## Lumière par pièce

`scripts/level/atmosphere.gd` (`Atmosphere`) : l'Environment est dupliqué puis fondu vers
l'ambiance de la pièce (lumière ambiante, brume, luminosité, contraste, saturation, lueur,
intensité du soleil et des lumières d'appoint, exposition). Tonemap filmique, vignettage
discret (`assets/shaders/vignette.gdshader`).

| Ambiance | Intention |
|---|---|
| title / sleep | pénombre de l'atelier, Nin0 isolé par un faisceau chaud |
| hub | refuge : chaud, nostalgique, contraste modéré |
| sas | neutre, poussiéreux, zone de transition |
| bath | froid, humide, un peu inquiétant |
| kitchen | jour de la fenêtre, dessous de meubles sombres, contrasté |
| salon | doux, vaste, légèrement mélancolique |

Rendu : Compatibility (OpenGL) — pas de SSAO, SSIL ni brouillard volumétrique ; les faisceaux
de fenêtre sont des plans additifs (`light_shaft.gdshader`), estompés près de la caméra.

## Interface

Thème commun `assets/ui/nino_theme.tres` : panneaux bleu-gris profond, liseré orange en
haut, coins arrondis, ombre douce ; boutons crème translucides, survol orange, **focus
clavier cyan** (distinct du survol). Constructeurs : `UiKit` (`panel`, `label`, `button`…).
Logo : `TitleLogo` (vectoriel, yeux qui clignent, antenne qui oscille).

Règles : textes lisibles à 1366×768, rien ne recouvre le HUD de mode/objectif, les bulles
de pensée évitent les panneaux visibles, une seule fenêtre modale à la fois.

## Effets

Poussière dans la lumière (atelier), étincelles de Nin0, volutes et halo de l'imprimante,
lueur cyan de l'écran-visage au réveil, retour du scan en cyan.
