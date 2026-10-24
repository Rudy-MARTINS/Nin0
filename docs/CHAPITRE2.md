# Chapitre 2 — Le territoire des fourmis (lot 5)

Suite jouable de la première démo : Nin0 franchit la porte du placard, découvre le sas, la colonie de fourmis de la salle de bain, affronte la reine dans le lavabo, fabrique un canon à l'imprimante et ouvre la porte de la cuisine. **Le chapitre se termine à l'entrée de la cuisine** ; le salon reste fermé.

> Statuts : **[DÉVELOPPÉ]** = jouable et testé automatiquement ; **[PROPOSITION]** = choix technique ou de mise en scène pris pour avancer, à valider ; **[À DÉFINIR]** = décision ouverte, rien n'est inventé.

## Lancer

| Scène | Usage |
|---|---|
| `scenes/levels/game.tscn` | **Jeu complet** (scène principale, F5) : écran titre, placard, puis l'appartement. |
| `scenes/levels/workshop.tscn` | Première démo seule (inchangée, fin au seuil du sas). |
| `scenes/levels/apartment.tscn` | Mode développement (F6) : jeu complet, placard résolu, aucune sauvegarde, scénarios de test. |

### Commandes ajoutées

| Touche (AZERTY) | Action |
|---|---|
| Clic gauche ou X | Tirer une bille (canon installé) |
| Clic droit / Maj (maintenir) | Vision focalisée : analyser un insecte, repérer le loquet, viser plus précisément |
| Tab ou I | Inventaire (Ressources, Équipement, Archives, Bestiaire) ; aussi depuis la pause |
| Q / D (inventaire ouvert) | Changer d'onglet |

### Mode développement — scénarios (aucune sauvegarde)

| Touches | Scénario |
|---|---|
| Ctrl + 1 | Rencontre de la première ouvrière (entrée du sas) |
| Ctrl + 2 | Labyrinthe gauche (souvenir n° 2) |
| Ctrl + 3 | Labyrinthe droit (soldats) |
| Ctrl + 4 | Pied de l'escabeau |
| Ctrl + 5 | Haut de l'escabeau, juste avant la reine |
| Ctrl + 6 | Fabrication du canon (devant l'imprimante, reine vaincue, filament fourni) |
| Ctrl + 7 | Porte de la cuisine (canon installé, billes fournies) |

En ligne de commande : `-- --scenario=boss` (sas, maze, right, stool, boss, cannon, kitchen) ; `-- --zone=3` reste disponible.

## Déroulement

1. **Sas** [DÉVELOPPÉ] — décor abandonné (poussière, taches d'humidité, fissures, meuble à chaussures, parapluie tombé, feuille morte, éclats de plâtre, paillasson, porte-manteau), lumière mesurée. En entrant, **une ouvrière traverse, découvre Nin0, s'arrête**, agite ses antennes, penche la tête ; silence ; elle repart (≈ 4,5 s sans contrôle). Elle n'attaque jamais.
2. **Analyse** [DÉVELOPPÉ] — pensée et indice discret pour la vision focalisée ; une ouvrière visée assez longtemps est identifiée : fiche **« ESPÈCE IDENTIFIÉE »** (nom, classification, activité, comportement, particularité). Pensées « Cette carapace… » → « Elle la protège ? » → « Une protection… mécanique ! » → écran de plan **ARMURE I**.
3. **Colonne d'ouvrières** [DÉVELOPPÉ] — de la fissure du mur ouest jusqu'au trou du nid sous un carreau cassé de la salle de bain : transport de débris et de nourriture, pauses, échanges, écarts, vitesses variées, réactions ponctuelles à Nin0. Elle guide vers la salle de bain sans texte.
4. **Portes** [DÉVELOPPÉ] — salon : fermée, examinable (« Fermée… », « Pas par là. Pas encore. »), aucun mécanisme. Cuisine : fermée par un **crochet** posé haut sur le chambranle, examinable, repérable à la vision focalisée (« Trop haut pour moi. »).
5. **Salle de bain** [DÉVELOPPÉ] — carrelage, baignoire, WC, meuble-lavabo avec miroir, linge entassé, serviette pendue, humidité. Un **pantalon abandonné** sépare l'entrée en deux :
   - **à gauche**, petit labyrinthe facultatif (flacons couchés, rouleaux, panier, seau, gel douche, boîte de cotons, lessive, porte-savon sur pieds à passer dessous ou dessus) ; deux culs-de-sac récompensés (plastique, filament) ; le **ticket froissé** (souvenir n° 2) dans le recoin près de la poche du pantalon ;
   - **à droite**, galeries de terre gardées par **quatre soldats** : gravier (ralentit les roues), marche de carrelage avec rampe, passage étroit entre deux cailloux, carrelage soulevé (jambes), larves qui tombent de la galerie bâtie dans la serviette ; une poche gardée près du WC (ressources) ; puis l'escabeau.
6. **Escabeau** [DÉVELOPPÉ] — carton, gant + rouleau, marche 1, gobelet, flacon, marche 2, porte-savon, gants pliés, plateau, boîte, pile de livres, rebord du plan (85 cm). Montées de 0,75 u au plus (saut : 1 u), deux points sûrs (pied et haut de l'escabeau).
7. **Reine** [DÉVELOPPÉ] — courte présentation (elle se redresse, grogne ; Nin0 surpris ; contrôle rendu). La vasque est remplie de matière visqueuse : Nin0 s'y enfonce lentement, ralentit, saute moins haut et reçoit plus de dégâts, mais peut toujours en sortir. Débris flottants (éponge, bouchons, coton, savon, tesson), deux qui dérivent. Attaques : **crachat d'acide** (préparation 1 s, cible verte au sol, arc lisible, 12 dégâts, ralentissement 1,6 s, petite flaque) préféré à distance ; **morsure** au contact (préparation 1 s, portée 1,5 u, 30 dégâts, récupération 1,5 s).
8. **Victoire sans arme** [DÉVELOPPÉ] — traverser jusqu'à l'**anneau de la chaînette** sur le rebord est et le tirer (E) : la bonde saute, gargouillis, la matière s'évacue (6 s), les débris descendent, l'île glisse, **la reine perd pied et est emportée vers la bonde en tournoyant** (sobre, sans mort graphique). Nin0 surpris puis content. Victoire définitive.
9. **Plan du canon** [DÉVELOPPÉ] — « Elle projetait… », « Un ressort… une bille… » → écran **CANON À PROJECTILES PLASTIQUES** (pictogrammes, schéma : goutte projetée → ressort → tube → bille).
10. **Imprimante** [DÉVELOPPÉ] — carte « Canon à billes » ; impression couche par couche sur le plateau, présentation, Nin0 monte, la tête saisit la pièce et l'emboîte sur son épaule droite, petit recul, réaction ; 6 billes offertes ; indice de tir.
11. **Cuisine** [DÉVELOPPÉ] — retour au sas, une bille soulève le crochet : déclic, la porte s'entrouvre lentement vers la cuisine éclairée. Entrer dans la cuisine (intérieur en blockout) termine le chapitre : écran « Chapitre 2 terminé — Le territoire des fourmis », avec **Continuer à explorer**.

Retour au placard possible à tout moment (portes ouvertes dans les deux sens), y compris avant la reine ; rien n'est réinitialisé par une visite au placard.

## Systèmes

### Fourmis
- `AntBody` (procédural, cartoon) : 6 pattes avec démarche en trépied, 2 antennes, grands yeux, mandibules ; ouvrière (≈ 1,8 cm), soldat (tête large, grosses mandibules, sourcils, ≈ 2,6 cm), reine (gros abdomen rayé doré, moignons d'ailes, ≈ 12,5 cm).
- Ouvrière (`AntWorker`) et colonne (`AntColumn`) : mise à jour réduite à 4 Hz et animation coupée loin de Nin0.
- Soldat (`AntSoldier`) : patrouille → alerte (« ! ») → poursuite (≈ vitesse des jambes) → préparation de morsure → morsure (14) → récupération → recherche (« ? ») → retour. Vue limitée (4 u, 75°, même niveau, ligne de vue). Une bille le fait reculer ; trois billes le font fuir, il revient plus tard.
- Les ouvrières restent pacifiques ; l'ancien « incident → hostilité générale » n'est pas implémenté pour ce chapitre (GDD §6).

### Roues ou jambes
Roues : plus rapides en terrain dégagé (sas, entrée, labyrinthe gauche). Gravier : roues à 40 %. Marches, carrelage soulevé, escabeau et lavabo : jambes. Soldats : vitesse ≈ jambes, donc on les distance sur roues en terrain dégagé.

### Intégrité et dégâts
`NinoIntegrity.hit()` : courte invulnérabilité (0,9 s), recul, émotion. Matière : dégâts ×1,25. Armure I : −25 % sur les dégâts physiques (pas sur l'acide). À zéro : mise en veille, redémarrage au dernier point sûr ; pendant la reine, l'arène est entièrement remise en place.

### Canon
`NinoCannon` (nœud ajouté par le jeu complet) : vise le centre de la caméra (premier obstacle sur la ligne de visée), compatible avec la vision focalisée ; bille physique (14 u/s, légère gravité, portée 20 u), collision avec le monde, les créatures (couche 5) et les cibles (couche 6) ; `on_projectile_hit()` ou métadonnée `projectile_receiver`. Munitions : `AmmoData` (`assets/upgrades/ammo_bead.tres`) ; un seul type développé, un type 2 (pointu) prévu [NON DÉVELOPPÉ].

### Ressources, réapparition
Voir GDD §4.3. Identifiants uniques par objet ; `GameState.pickup_times` mémorise l'heure de jeu du ramassage ; réapparition à au moins 8 u de Nin0.

### Inventaire
`InventoryMenu` (Tab / I ou pause) : quatre onglets construits à partir de `GameState`, `UpgradeCatalog`, `SpeciesCatalog`, `MemoryArchive`. Les archives montrent pour chaque souvenir l'objet associé, les informations récupérées (dégradées selon le nombre de souvenirs), toutes les interprétations de Nin0 (historique) et ce qui reste inconnu ; les souvenirs non trouvés sont des « signaux non identifiés ».

### Sauvegarde (version 5)
Ajouts : espèces, plans, améliorations, modules équipés, rencontre, salle de bain, reine (combat commencé, vaincue), cuisine, chapitre, plastique, temps de jeu, heures de ramassage, notifications vues, lectures des souvenirs, point de reprise (sas, salle de bain, pied ou haut de l'escabeau, porte de la cuisine). Les sauvegardes des lots 1 à 4 se chargent (valeurs par défaut).

## Fichiers principaux

| Fichier | Rôle |
|---|---|
| `scenes/levels/game.tscn`, `scripts/zones/game_world.gd` | Jeu complet, chef d'orchestre du chapitre |
| `scenes/zones/sas_zone.tscn`, `scripts/zones/sas_zone.gd`, `kitchen_door.gd` | Sas, portes |
| `scenes/zones/bathroom_zone.tscn`, `scripts/zones/bathroom_zone.gd` | Salle de bain |
| `scripts/zones/sink_arena.gd`, `floating_platform.gd`, `terrain_zone.gd`, `larva_dropper.gd` | Arène, débris, terrains, larves |
| `scripts/creatures/*.gd`, `assets/species/*.tres` | Fourmis, fiches d'espèces |
| `scripts/weapons/*.gd`, `scripts/props/cannon_model.gd` | Canon, munitions |
| `scripts/ui/species_card.gd`, `blueprint_screen.gd`, `inventory_menu.gd`, `chapter_end.gd` | Interfaces |
| `tests/test_chapter2.tscn` | Test automatique du chapitre |

Les scènes de zones sont produites par des générateurs Python hors dépôt (blockout + accessoires simples) ; elles restent éditables dans Godot.

## Décisions prises pour avancer [PROPOSITION, à valider]

- Vidange : chaînette reliant la bonde à un anneau sur le rebord est ; le tour par les rebords est bloqué par le robinet et le distributeur de savon (il faut traverser la vasque).
- Défaite de la reine : emportée vers la bonde en tournoyant et en rétrécissant (cartoon, sobre).
- Après une défaite : reprise en haut de l'escabeau ; présentation raccourcie aux essais suivants.
- Canon : 6 billes offertes à la fabrication ; une bille = un plastique ; 24 au maximum.
- Coûts : Armure I et canon 3 fragments chacun.
- Le labyrinthe gauche et le souvenir n° 2 restent accessibles avant et après la reine.
- Musique : le morceau d'introduction reste joué une fois au démarrage ; aucune musique de zone (à composer séparément).

## Limites connues

- Graphismes : accessoires en volumes simples (boîtes, cylindres, sphères), sans textures ; les galeries de terre sont des volumes arrondis.
- La colonne et les soldats ne contournent pas les obstacles par navigation : leurs trajets sont posés à la main ; un soldat coincé abandonne et reprend sa patrouille.
- Pas de son de zone ni de musique de combat ; effets sonores synthétiques.
- La caméra peut passer derrière des accessoires dans les galeries étroites (pas de transparence des obstacles).
- Les validations automatiques ne remplacent pas un essai à la manette / au clavier sous Windows (sensations, lisibilité, difficulté).

## Captures (rendu Godot 4.7, OpenGL, sans interface)

| | |
|---|---|
| ![Première ouvrière](images/lot5/01_premiere_ouvriere.png) | ![Colonne](images/lot5/02_colonne.png) |
| Première ouvrière (Nin0 intrigué) | Colonne vers la salle de bain |
| ![Labyrinthe](images/lot5/03_labyrinthe.png) | ![Soldat](images/lot5/04_soldat.png) |
| Labyrinthe gauche | Soldat en patrouille |
| ![Ticket](images/lot5/05_ticket.png) | ![Escabeau](images/lot5/06_escabeau.png) |
| Ticket froissé (souvenir n° 2) | Escabeau et appuis |
| ![Arène](images/lot5/07_arene.png) | ![Reine](images/lot5/08_reine.png) |
| Arène du lavabo | La reine sur son éponge |
| ![Canon](images/lot5/09_canon.png) | ![Cuisine](images/lot5/10_cuisine_ouverte.png) |
| Canon installé sur Nin0 | Porte de la cuisine déverrouillée |
