# Prototype Lot 1 — Contrôles (roues + escalade)

Notes techniques du premier prototype jouable. Ce document ne remplace pas le GDD : il décrit **comment** le Lot 1 est implémenté et liste les **hypothèses à valider**.

## Lancer le prototype

1. Ouvrir le projet dans Godot **4.3 ou plus récent** (branche 4.x stable).
2. Appuyer sur **F5** : la scène principale `scenes/levels/test_level.tscn` se lance.

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Rouler ; sur une paroi : monter / descendre / se décaler |
| Souris | Tourner la caméra |
| C | Lâcher la paroi |
| R | Réapparaître au point de départ |
| Échap | Libérer la souris (clic gauche pour la reprendre) |

Les touches de déplacement sont définies par **position physique** : Z Q S D sur un clavier AZERTY = W A S D sur un clavier QWERTY. Aucune touche de saut n'existe.

## Organisation

```
scenes/levels/test_level.tscn         Scène de test (pièce, obstacles, surfaces escaladables)
scenes/player/nino.tscn               Nino provisoire (CharacterBody3D + visuel en primitives)
scenes/camera/third_person_camera.tscn Caméra troisième personne (SpringArm3D)
scenes/ui/debug_hud.tscn              Mode courant + rappel des commandes
scripts/player/nino_controller.gd     Déplacement roues, escalade, hissage, réapparition
scripts/player/nino_visual.gd         Roues qui tournent, inclinaison, clignement des yeux
scripts/camera/third_person_camera.gd Suivi lissé, souris, anti-traversée
scripts/ui/debug_hud.gd               Affichage du mode
tests/test_lot1_movement.gd           Test automatique sans affichage
```

Les futures jambes pourront se fixer sur les marqueurs `Visual/Body/Modules/LegMountLeft` et `LegMountRight` (pastilles orange sur les flancs de Nino).

## Choix techniques

- **Échelle : 1 unité Godot = 10 cm réels.** Nino mesure 0,5 unité (5 cm). À l'échelle réelle, la physique de Godot devient imprécise pour des objets aussi petits ; ce facteur ×10 la stabilise sans changer les proportions du monde. Exemples : carton de 16 cm = 1,6 unité, tasse de 10 cm = 1 unité.
- **Gravité de jeu : 25 u/s²** (la vraie gravité à cette échelle serait 98 u/s², trop brutale). Réglable dans l'inspecteur de Nino.
- **Couches physiques :** 1 « monde », 2 « escaladable », 3 « joueur ».
- **Rendu :** Compatibility (OpenGL), comme configuré initialement.

### Rendre une surface escaladable

Sur un `StaticBody3D`, cocher la couche **1 « monde » et la couche 2 « escaladable »** (*Collision → Layer*). Par convention visuelle, les surfaces escaladables du prototype utilisent une texture granuleuse (carton, liège). Seules les parois quasi verticales comptent.

## Hypothèses de prototype à valider [PROPOSITION]

Ces comportements ne sont pas définis dans le GDD (§3 « à clarifier ») ; ils sont provisoires et facilement modifiables :

1. **Accroche automatique** : rouler contre une surface escaladable depuis le sol accroche Nino (pas de touche dédiée).
2. **Commandes sur la paroi** : avant/arrière = monter/descendre ; gauche/droite = déplacement latéral, relatifs à la paroi et non à la caméra.
3. **Limites** : Nino ne peut pas dépasser les bords de la surface escaladable ; il ne passe pas d'une paroi à une autre dans les angles.
4. **Sommet** : Nino se hisse automatiquement s'il y a de la place ; sinon il reste bloqué en haut.
5. **Bas** : reculer au contact du sol repasse en mode roues. **C** lâche la paroi à tout moment (chute sans dégâts).
6. **Rotation des roues** : Nino tourne sur place vers la direction demandée et ralentit s'il doit faire demi-tour (comme un petit robot à roues), plutôt que de glisser en crabe.
7. **Vitesses** : roues 3 u/s (30 cm/s), escalade 1,1 u/s.

Les valeurs se règlent dans l'inspecteur du nœud `Nino` (groupes *Roues*, *Escalade*, *Chute*) et de `ThirdPersonCamera`.

## Test automatique

Depuis la racine du projet (chemin de Godot à adapter) :

```
godot --headless --fixed-fps 60 --path . --script res://tests/test_lot1_movement.gd
```

Il vérifie : absence d'action de saut, déplacement, décélération, rotation progressive, tasse non escaladable, escalade et hissage sur le carton, lâcher, descente, limite latérale sur le liège, accès à l'étagère, montée de la pente et réapparition. Sous Windows, utiliser `Godot_v4.x_win64_console.exe` pour voir le résultat dans le terminal.

## Limites connues

- Nino ne peut pas redescendre d'une zone surélevée en marche arrière par l'escalade : il faut rouler hors du bord (chute sans dégâts).
- Pas de passage d'une paroi à une autre dans les angles ; pas d'escalade de surfaces courbes ou inclinées (> 20°).
- Le hissage est un déplacement scripté simple (Tween), sans animation dédiée.
- La caméra se rapproche instantanément face à un obstacle et ne se recentre pas automatiquement derrière Nino.
- Pas de manette pour l'instant (clavier + souris uniquement).
