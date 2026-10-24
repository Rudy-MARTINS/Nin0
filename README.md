

## État du projet

**Chapitre 2 jouable (lot 5) : « Le territoire des fourmis ».** Après le placard, Nin0 explore le sas, rencontre une première ouvrière, analyse les insectes (encyclopédie biologique), traverse la salle de bain gardée par des soldats, retrouve un deuxième souvenir, affronte la reine dans le lavabo (victoire sans arme, par la vidange), fabrique un canon à billes à l'imprimante et ouvre la porte de la cuisine. Détails : [docs/CHAPITRE2.md](docs/CHAPITRE2.md).

**Cuisine jouable (lot 6, branche en validation).** Cuisine compacte en L (d'après le croquis) sur plusieurs niveaux — sol et dessous des meubles, plan de travail, évier et fenêtre, réfrigérateur, dessus des placards — habitée par des araignées territoriales et des cafards des bois qui s'affrontent même sans Nin0, y compris à l'arrière-plan. Détails : [docs/CUISINE.md](docs/CUISINE.md).

**Première démo (lots 2 et 3).** Nin0 s'éveille dans le placard-hub, comprend son environnement à travers ses pensées, rallume l'imprimante 3D, construit son chemin de retour avec des bobines, reçoit ses deux jambes sur la plateforme d'impression, apprend à observer et ouvre la grande porte du placard. En l'ouvrant, il chute et s'abîme : il revient à l'imprimante avec ses jambes pour se faire réparer, puis franchit la porte. Facultatif : un premier fragment de souvenir, des fragments de filament et un renfort de châssis.

- Conception : [docs/GDD.md](docs/GDD.md)
- Première démo (déroulement, commandes, architecture, limites) : [docs/DEMO.md](docs/DEMO.md)
- Chapitre 2, sas et salle de bain, reine, canon, inventaire (lot 5) : [docs/CHAPITRE2.md](docs/CHAPITRE2.md)
- Appartement complet en blockout, mode développement (lot 4) : [docs/APPARTEMENT.md](docs/APPARTEMENT.md)
- Systèmes préparés pour la suite (améliorations, modules, souvenirs) : [docs/SYSTEMES_FUTURS.md](docs/SYSTEMES_FUTURS.md)
- Prototype Lot 1 (déplacement, escalade) : [docs/PROTOTYPE_LOT1.md](docs/PROTOTYPE_LOT1.md)
- Moteur : **Godot 4.7** (version officielle et unique du projet, voir [docs/MIGRATION_GODOT_4_7.md](docs/MIGRATION_GODOT_4_7.md))
- Plateforme initiale : Windows
- Outils : Godot, VS Code, Codex, Git

## Ouvrir le projet

1. Installer **Godot 4.7** (version standard, pas .NET). C'est la seule version de référence du projet.
2. Cloner ce dépôt.
3. Dans le gestionnaire de projets Godot, choisir **Importer** puis sélectionner `project.godot`.
4. Ouvrir le projet puis appuyer sur **F5** : l'écran titre du jeu s'affiche (`scenes/levels/game.tscn` : placard puis appartement). La première démo seule reste disponible : `scenes/levels/workshop.tscn` puis **F6**.

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Se déplacer ; sur une paroi : monter / descendre |
| Souris | Caméra |
| E (ou Entrée) | Interagir, examiner, valider dans l'interface de l'imprimante |
| Clic droit ou Maj (maintenir) | Vision focalisée (débloquée en cours de démo) : repères, souvenirs, analyse des insectes |
| Clic gauche ou X | Tirer une bille (canon, chapitre 2) |
| Tab ou I | Inventaire : ressources, équipement, archives, bestiaire |
| C | Lâcher une paroi |
| F | Roues ↔ jambes (à l'arrêt, au sol, une fois les jambes obtenues) |
| Espace | Sauter (mode jambes uniquement) |
| R | Revenir au dernier point sûr (replace aussi les bobines) |
| Échap | Pause (reprendre, inventaire, recommencer, quitter) |

Bac à sable de déplacement (jambes disponibles d'emblée) : ouvrir `scenes/levels/test_level.tscn` puis **F6**.

**Mode développement (lots 4 et 5)** : ouvrir `scenes/levels/apartment.tscn` puis **F6**. Exploration libre des sept zones (touches 1 à 7, carte F2, plafonds F3, caméra libre F4) et scénarios du chapitre 2 (Ctrl + 1 à 8 : rencontre, labyrinthes, escabeau, reine, canon, porte de la cuisine, intérieur de la cuisine), sans aucune sauvegarde. Détails : [docs/APPARTEMENT.md](docs/APPARTEMENT.md), [docs/CHAPITRE2.md](docs/CHAPITRE2.md).

**Tests automatiques** (sans affichage) : `tests/test_demo_flow.tscn` (démo), `tests/test_lot1_movement.tscn`, `tests/test_apartment.tscn`, `tests/test_chapter2.tscn`, par exemple `godot --headless --fixed-fps 60 --path . res://tests/test_chapter2.tscn`. Ils utilisent une sauvegarde de test séparée.

**Musique** : le morceau d'introduction (prototype interne, droits à régulariser) est joué une fois au lancement ; voir `assets/music/LISEZMOI.md`.

## Prochaines étapes

Le chapitre 2 s'arrête à l'entrée de la cuisine, qui s'explore ensuite (lot 6). L'ouverture du salon (mécanisme **à définir**) viendra dans un prochain lot ; la chambre reste verrouillée.

> Le GDD contient des spoilers de conception : ne pas afficher son contenu narratif directement dans le jeu.
