

## État du projet

**Première démo jouable (lot 2).** NINO s'éveille dans le placard-hub, comprend son environnement à travers ses pensées, rallume l'imprimante 3D, construit son chemin de retour avec des bobines, reçoit ses deux jambes sur la plateforme d'impression, apprend à observer et ouvre la grande porte du placard.

- Conception : [docs/GDD.md](docs/GDD.md)
- Première démo (déroulement, commandes, architecture, limites) : [docs/DEMO.md](docs/DEMO.md)
- Prototype Lot 1 (déplacement, escalade) : [docs/PROTOTYPE_LOT1.md](docs/PROTOTYPE_LOT1.md)
- Moteur : Godot 4 (branche stable)
- Plateforme initiale : Windows
- Outils : Godot, VS Code, Codex, Git

## Ouvrir le projet

1. Installer Godot 4 (le projet est vérifié avec **4.3** et **4.7**).
2. Cloner ce dépôt.
3. Dans le gestionnaire de projets Godot, choisir **Importer** puis sélectionner `project.godot`.
4. Ouvrir le projet puis appuyer sur **F5** : l'écran titre de la démo s'affiche.

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Se déplacer ; sur une paroi : monter / descendre |
| Souris | Caméra |
| E (ou Entrée) | Interagir, examiner |
| Clic droit ou Maj (maintenir) | Observer (vision focalisée, débloquée en cours de démo) |
| C | Lâcher une paroi |
| F | Roues ↔ jambes (à l'arrêt, au sol, une fois les jambes obtenues) |
| Espace | Sauter (mode jambes uniquement) |
| R | Revenir au dernier point sûr (replace aussi les bobines) |
| Échap | Pause (reprendre, recommencer la démo, quitter) |

Bac à sable de déplacement (jambes disponibles d'emblée) : ouvrir `scenes/levels/test_level.tscn` puis **F6**.

## Prochaines étapes

Les fourmis, l'incident, les combats, les autres pièces et améliorations viendront par petits lots testables (voir GDD §10).

> Le GDD contient des spoilers de conception : ne pas afficher son contenu narratif directement dans le jeu.
