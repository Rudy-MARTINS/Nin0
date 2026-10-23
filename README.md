

## État du projet

**Première démo jouable (lots 2 et 3).** Nin0 s'éveille dans le placard-hub, comprend son environnement à travers ses pensées, rallume l'imprimante 3D, construit son chemin de retour avec des bobines, reçoit ses deux jambes sur la plateforme d'impression, apprend à observer et ouvre la grande porte du placard. En l'ouvrant, il chute et s'abîme : il revient à l'imprimante avec ses jambes pour se faire réparer, puis franchit la porte. Facultatif : un premier fragment de souvenir, des fragments de filament et un renfort de châssis.

- Conception : [docs/GDD.md](docs/GDD.md)
- Première démo (déroulement, commandes, architecture, limites) : [docs/DEMO.md](docs/DEMO.md)
- Systèmes préparés pour la suite (améliorations, modules, souvenirs) : [docs/SYSTEMES_FUTURS.md](docs/SYSTEMES_FUTURS.md)
- Prototype Lot 1 (déplacement, escalade) : [docs/PROTOTYPE_LOT1.md](docs/PROTOTYPE_LOT1.md)
- Moteur : **Godot 4.7** (version officielle et unique du projet, voir [docs/MIGRATION_GODOT_4_7.md](docs/MIGRATION_GODOT_4_7.md))
- Plateforme initiale : Windows
- Outils : Godot, VS Code, Codex, Git

## Ouvrir le projet

1. Installer **Godot 4.7** (version standard, pas .NET). C'est la seule version de référence du projet.
2. Cloner ce dépôt.
3. Dans le gestionnaire de projets Godot, choisir **Importer** puis sélectionner `project.godot`.
4. Ouvrir le projet puis appuyer sur **F5** : l'écran titre de la démo s'affiche.

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Se déplacer ; sur une paroi : monter / descendre |
| Souris | Caméra |
| E (ou Entrée) | Interagir, examiner, valider dans l'interface de l'imprimante |
| Clic droit ou Maj (maintenir) | Vision focalisée (débloquée en cours de démo) : repères, souvenirs |
| C | Lâcher une paroi |
| F | Roues ↔ jambes (à l'arrêt, au sol, une fois les jambes obtenues) |
| Espace | Sauter (mode jambes uniquement) |
| R | Revenir au dernier point sûr (replace aussi les bobines) |
| Échap | Pause (reprendre, recommencer la démo, quitter) |

Bac à sable de déplacement (jambes disponibles d'emblée) : ouvrir `scenes/levels/test_level.tscn` puis **F6**.

## Prochaines étapes

Les fourmis, l'incident, les combats, les autres pièces et améliorations viendront par petits lots testables (voir GDD §10).

> Le GDD contient des spoilers de conception : ne pas afficher son contenu narratif directement dans le jeu.
