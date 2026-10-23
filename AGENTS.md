# Instructions pour Codex — NINO

Lire **docs/GDD.md** avant toute modification du gameplay. C'est la référence pour les décisions validées, propositions et questions ouvertes.

## Règles de développement

- Moteur : Godot 4, GDScript ; cible initiale : Windows, 3D.
- Modifications petites, réversibles et testables ; ne pas générer tout le jeu en une seule fois.
- Avant d'implémenter une mécanique non définie, proposer une hypothèse explicite et demander validation.
- Nino commence avec des roues et une capacité d'escalade, **sans saut**.
- Premier module majeur : **deux jambes articulées**, après impression ; passage roues ↔ jambes avec animation et immobilisation.
- Une seule imprimante 3D pour le périmètre actuel ; retour par raccourcis.
- Fourmis pacifiques jusqu'à l'incident scénarisé après obtention des jambes.
- Ne jamais révéler le scénario secret dans les textes, niveaux ou interfaces visibles avant la révélation prévue.
- Privilégier les assets originaux et simples ; vérifier toute licence externe.
- Utiliser des noms de fichiers et de nodes cohérents, éviter les dépendances inutiles.
- Après chaque tâche, détailler fichiers modifiés, tests effectués et manipulations nécessaires dans Godot.
- **Ne pas** modifier le GDD validé ou publier de spoiler sans demande.

## Lot suivant

Créer une première scène de test et un personnage provisoire avec roues, caméra, collisions et escalade basique. Ne pas développer l'impression 3D ni le système d'insectes à cette étape.
