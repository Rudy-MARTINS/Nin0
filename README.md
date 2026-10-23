# NINO 🤖

Jeu 3D indépendant en préparation avec **Godot 4** et **GDScript**.

Un minuscule robot éducatif explore un appartement abandonné où la nature et les insectes ont repris leurs droits. Exploration, plateformes, améliorations imprimées en 3D et écosystème autonome.

## État du projet

**Lot 1 — Contrôles (prototype).** Une scène de test jouable : Nino provisoire en mode roues, caméra troisième personne et escalade sur surfaces autorisées.

- Conception : [docs/GDD.md](docs/GDD.md)
- Prototype Lot 1 (commandes, architecture, hypothèses) : [docs/PROTOTYPE_LOT1.md](docs/PROTOTYPE_LOT1.md)
- Moteur : Godot 4 (branche stable)
- Plateforme initiale : Windows
- Outils : Godot, VS Code, Codex, Git

## Ouvrir le projet

1. Installer Godot 4.
2. Cloner ce dépôt.
3. Dans le gestionnaire de projets Godot, choisir **Importer** puis sélectionner `project.godot`.
4. Ouvrir le projet puis appuyer sur **F5** : la scène de test `scenes/levels/test_level.tscn` se lance.

Commandes : **Z Q S D** / flèches pour rouler et grimper, **souris** pour la caméra, **C** pour lâcher une paroi, **R** pour réapparaître, **Échap** pour libérer la souris.

## Premier objectif

Construire un prototype 3D gris : caméra troisième personne, Nino roulant, collisions et escalade simple sur surfaces autorisées. **Nino ne saute pas au départ.**

Les améliorations, la transformation et les fourmis viendront par petits lots testables.

> Le GDD contient des spoilers de conception : ne pas afficher son contenu narratif directement dans le jeu.
