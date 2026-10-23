# Première démo jouable — l'atelier

Ce document décrit la démo telle qu'elle est implémentée : déroulement, architecture, choix provisoires et limites connues. Le GDD reste la référence de conception ; rien ici ne le modifie.

> Ce document ne contient pas de spoiler du scénario. Les indices dans la pièce (dessin d'enfant, cadre retourné, croquis technique) sont volontairement ambigus.

## Lancer la démo

1. Ouvrir le projet dans Godot **4.3** (ou une version 4.x plus récente).
2. Appuyer sur **F5** : l'écran titre apparaît au-dessus de NINO endormi.
3. **Commencer** lance une nouvelle partie. **Continuer** n'apparaît que si les jambes ont déjà été obtenues.
4. **Échap** ouvre la pause. Elle permet de reprendre, de **recommencer la démo** (la progression sauvegardée est alors effacée) ou de quitter.

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Se déplacer ; sur une paroi : monter / descendre / se décaler |
| Souris | Caméra |
| E (ou Entrée) | Interagir (imprimante, interrupteur) |
| C | Lâcher une paroi |
| F | Roues ↔ jambes (seulement à l'arrêt et au sol) |
| Espace | Sauter (mode jambes uniquement) |
| R | Revenir au dernier point sûr |
| Échap | Pause |

Les touches de déplacement sont définies par position physique : Z Q S D sur un clavier AZERTY correspondent à W A S D sur un QWERTY.

## Déroulement

1. **Réveil.** NINO est éteint sur son socle de recharge, sur l'établi. Une touche de déplacement l'active : son écran vacille, il regarde autour de lui et la caméra se place derrière lui. Les commandes sont ensuite présentées une par une (rouler, puis regarder autour).
2. **L'établi.** NINO avance parmi des objets à son échelle (gobelet à crayons, règle, livres, tournevis, rouleau d'adhésif) vers l'imprimante 3D, visible dès le départ au bout de l'établi. Le rebord de la fenêtre, juste au-dessus du socle, est inaccessible : des marches trop hautes pour des roues l'annoncent.
3. **L'imprimante, hors tension.** L'interface montre la seule amélioration disponible, « Jambes mécaniques », et le prérequis manquant : l'alimentation électrique. Le câble de l'imprimante longe l'établi puis descend le long des cartons jusqu'au sol.
4. **Exploration du sol.** Le joueur descend en se laissant tomber du carton (aucun dégât, mais NINO réagit au choc). Le sol propose un tapis, un fauteuil sous lequel on peut passer, un ours en peluche, des cubes en bois, un ballon, un coffre à jouets escaladable (facultatif), une plante, du lierre, des feuilles mortes, des papiers et un tube en carton à traverser en roulant.
5. **La tâche.** Sous l'établi, dans la pénombre, la multiprise de l'imprimante est éteinte : son interrupteur rouge luit faiblement. Un appui sur **E** l'allume.
6. **Retour.** NINO escalade les deux cartons, qui ont la texture « escaladable », puis regagne l'établi.
7. **Impression.** Après une courte chauffe de la buse, la tête d'impression et le plateau se déplacent. Les deux jambes apparaissent couche par couche, avec une bande lumineuse sur la couche en cours. Une barre de progression s'affiche sur l'écran de l'imprimante, accompagnée d'un son de moteurs pas-à-pas. Un signal sonore marque la fin.
8. **Installation.** « Récupérer les jambes » : elles quittent le plateau et rejoignent les fixations orange sur les flancs de NINO, où elles restent repliées.
9. **Jambes.** **F**, à l'arrêt, déclenche la transformation : NINO reste immobile environ 0,8 s, se redresse et rentre ses roues. En mode jambes, NINO est plus lent, plus précis et peut sauter. Des marches (boîte d'allumettes, pile de livres) mènent au rebord de la fenêtre.
10. **Conclusion.** Sur le rebord, NINO regarde dehors et la caméra s'éloigne lentement. L'écran affiche ensuite « NINO — Fin de la première démo ».

Aucune fourmi, aucun combat et aucun événement de la suite ne sont présents.

## Architecture

```
scripts/core/game_state.gd        Autoload : progression, objectif courant, sauvegarde légère
scripts/core/sfx.gd               Autoload : sons synthétisés au démarrage (aucun fichier audio)
scripts/player/nino_controller.gd Roues, jambes, saut, transformation, escalade, réactions
scripts/player/nino_visual.gd     Expressions, regard, roues, jambes (IK procédurale), rebonds
scripts/camera/third_person_camera.gd  Caméra (SpringArm3D anti-traversée)
scripts/interaction/              Interactable (zone) + Interactor (sur NINO, touche E)
scripts/level/workshop_director.gd     Enchaînement de la démo (indices, objectifs, séquences)
scripts/level/printer_3d.gd       Imprimante : alimentation, impression, livraison des jambes
scripts/level/power_strip.gd      Multiprise (la tâche de la démo)
scripts/level/trigger_zone.gd     Zones d'indices, de points sûrs et de fin
scripts/ui/                       HUD, panneau de l'imprimante, titre, pause, fin
scripts/props/, scripts/tools/    Accessoires générés : boîtes arrondies, câbles, végétation
assets/shaders/                   Visage de NINO, parquet, bois, plâtre, tapis, impression…
assets/textures/                  Deux images originales (dessin d'enfant, croquis des jambes)
assets/ui/nino_theme.tres         Thème commun des interfaces
scenes/levels/workshop.tscn       La démo (scène principale)
scenes/levels/test_level.tscn     Bac à sable de déplacement (jambes disponibles, F6)
scenes/props/                     Imprimante 3D, multiprise
tests/                            Tests automatiques (scènes à lancer sans affichage)
```

Principes :
- **Séparation des rôles.** Le contrôleur ne connaît ni l'interface ni la progression. Le directeur de niveau relie les signaux (interaction, fin d'impression, changement de mode, zones). L'interface ne fait qu'afficher.
- **Extensible sans sur-ingénierie.** `Interactable` sert à tout objet interactif. L'imprimante prévoit un état par amélioration, mais une seule existe pour l'instant. Pas d'inventaire ni de ressources.
- **Décor éditable dans Godot.** `PropBlock` (boîte ou cylindre arrondi avec collision), `Cable` et `LeafCluster` sont des scripts `@tool` : leurs dimensions se règlent dans l'inspecteur et le rendu se met à jour dans l'éditeur.
- **Surfaces escaladables.** Elles se trouvent sur la couche physique 2 : cocher `climbable` sur un `PropBlock`. Par convention, elles ont une texture granuleuse (carton).
- **Sauvegarde.** `user://nino_demo.cfg` contient uniquement l'état « jambes installées ». « Nouvelle partie » et « Recommencer la démo » l'effacent.

## Choix provisoires [PROPOSITION — à valider]

- **Tâche préalable :** rallumer la multiprise de l'imprimante. Aucune collecte d'objet.
- **Livraison des jambes :** elles volent du plateau jusqu'aux fixations de NINO. C'est une mise en scène simple ; une vraie séquence d'installation pourra la remplacer.
- **Transformation :** 0,8 s, comme la proposition du GDD. Elle est refusée en mouvement, en l'air, pendant l'escalade et si la place manque au-dessus de NINO.
- **Mode jambes :** 1,8 u/s (contre 3 u/s sur roues), saut d'environ 1 unité (10 cm). Relâcher Espace tôt donne un saut plus court. L'escalade reste possible dans les deux modes.
- **Chutes :** aucun dégât, seulement une réaction (surprise, puis visage « > < » pour les grosses chutes).
- **Indices narratifs :** un dessin d'enfant (une maison et deux personnages), un cadre photo retourné, des chaussons, un ours en peluche et le croquis des jambes au-dessus de l'imprimante. Aucun texte ; rien ne révèle le scénario.

## Ce qui reste provisoire (à remplacer plus tard)

- **NINO :** modèle généré dans Godot (formes arrondies) et non modélisé. Les jambes sont animées par une IK simple, sans adaptation du pied aux pentes.
- **Décor :** formes arrondies générées avec des shaders procéduraux. L'ours en peluche est fait de sphères ; la vue extérieure (immeuble, arbre) est un simple fond.
- **Sons :** synthèse procédurale provisoire (bips, moteurs, ambiance). Pas de musique.
- **Expressions :** dessinées par un shader (neutre, curieux, content, surpris, choc, concentré). Il n'y a pas d'animation squelettique.

## Tests

```
godot --headless --fixed-fps 60 --path . res://tests/test_demo_flow.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_lot1_movement.tscn
```

- `test_demo_flow` parcourt la démo entière : réveil, imprimante hors tension, multiprise, **escalade réelle** des deux cartons, impression, installation, refus de transformation en mouvement et en l'air, transformation à l'arrêt sans téléportation, saut, vitesse en mode jambes, **montée réelle** jusqu'à la fenêtre par sauts, écran de fin, reprise via « Continuer » et effacement via « Nouvelle partie ». Certains trajets intermédiaires sont raccourcis par téléportation.
- `test_lot1_movement` vérifie que le déplacement roues et l'escalade validés au Lot 1 n'ont pas régressé.

Sous Windows, utiliser `Godot_v4.x_win64_console.exe` pour voir le résultat dans le terminal.

## Limites connues

- **Jamais joué à la main.** Les tests ont tourné sans affichage, et des captures ont été faites avec un rendu logiciel. Ni la prise en main réelle, ni le rendu sur une carte graphique Windows, ni les sons n'ont été vérifiés.
- **Durée estimée :** environ 5 à 10 minutes pour une première découverte. Cette estimation n'a pas été mesurée.
- **Escalade (inchangée depuis le Lot 1) :** pas de descente par escalade depuis le haut d'une paroi, pas de passage d'une paroi à l'autre dans les angles.
- **Caméra :** dans les espaces très étroits, elle se rapproche fortement, et NINO est masqué si elle passe à moins de 3 cm de lui.
- **Message sans gravité en mode headless :** `Parameter "m" is null` apparaît uniquement avec le pilote graphique factice. Il ne s'affiche pas dans l'éditeur ni en jeu.
- **Version de Godot :** le projet est réalisé avec Godot 4.3. Une version plus récente peut ajouter des fichiers `.uid` à l'ouverture ; c'est normal.
