# Lot 7 — Cuisine, saut chargé, guêpes, salon

> Branche : `claude/lot7-cuisine-salon` (**non fusionnée** : validation manuelle du créateur attendue).
> `main` contient le lot 6 validé (PR Rudy-MARTINS/Nin0#2, commit `3e1510e`).

## Lot 7A — Finitions, saut chargé, souvenir n° 3

### Finitions des chapitres existants

- **Imprimante** : à la première interaction, Nin0 observe la machine pièce par pièce (tête
  d'impression, plateau, bobine), penche la tête, réfléchit, puis l'interface s'ouvre.
  Avant toute installation (jambes, réparation, canon, améliorations), il recule à une place
  d'attente face à la machine : le plateau ne le pousse plus et il ne « saute » plus au départ.
- **Tutoriel** : inchangé (avancer, reculer, tourner, caméra obligatoires sur le plateau de départ).
- **Chute de la poignée** (gag) : projeté sur le coin de l'étagère, Nin0 vacille, tombe, rebondit
  sur un chausson, atterrit et glisse ; la gomme délogée au passage lui tombe sur la tête.
  Puis il constate ses dégâts et pense à l'imprimante.
- **Dégâts de chute** proportionnels à la hauteur réelle : aucun jusqu'à 4,5 u (sauts, saut chargé),
  puis 2,2 par unité (chute du plan de travail, 9 u : ≈ 10 ; dessus des placards, 21 u : ≈ 36).
- **État abîmé** (intégrité < 35 %) : parasites du visage, étincelles, pas un peu hésitant,
  vitesse −12 %. Les passages restent faisables (testé : retour à l'imprimante après la chute).
- **Lisibilité, collisions** : les livres du bas de la bibliothèque, la poignée du parapluie (sas)
  et le tuyau du meuble sous l'évier sont devenus solides (ils étaient traversables). Aucun objet
  « domino » n'existe dans le projet ; les petits accessoires ont été vérifiés par requêtes physiques.
  Les bulles de pensée s'écartent des textes de l'interface (objectif, aides, messages).
  Les éléments fixes à observer ont un léger halo chaud qui respire (pas d'icône), éteint une fois identifiés.
  Caméra : dans un couloir étroit, à l'arrêt, elle pivote doucement vers le côté dégagé.
- **Réactions** : variantes de gestes (hochements, inclinaisons, secouer la tête) sans répétition
  immédiate ; au-delà de trois réactions du même type en 45 s, Nin0 devient plus discret.
- **Salle de bain** : 15 % d'étourdissement (1 s) sur une morsure de soldat, sans cumul (immunité 5 s) ;
  deux rondes de soldats de plus ; trois flaques savonneuses qui ralentissent ; liquide du lavabo
  légèrement corrosif (2 toutes les 1,6 s après 1,2 s de grâce, grésillement et aide) ;
  la reine bouscule plus fort et marche d'un pas lourd. Le combat n'est pas reconstruit.
- **Sécurité des séquences** : toute séquence scriptée (installations, mises en scène), la lecture
  d'une fiche d'espèce, la vidange et la reprise du combat de la reine suspendent les dangers ;
  courte protection à la reprise (système existant réutilisé).

### Escalade retirée

Décision de design : Nin0 ne grimpe plus aux murs. La mécanique est désactivée par défaut
(`climbing_enabled = false`), son code conservé pour les tests. Audit : un seul passage
obligatoire l'utilisait hors cuisine (le carton derrière la chaise, retour à l'imprimante) ;
il se rejoint désormais par une **règle en bois posée en pente**. Le fragment de la caisse
à jouets se rejoint par trois **cubes-marches**. Toutes les escalades de la cuisine sont remplacées.

### Cuisine : entrée, puce, saut chargé

- **Présentation de la pièce** à la première entrée : vue d'ensemble, cafards au ras du sol,
  araignée en chasse sous les meubles, mouvements derrière le réfrigérateur ; une **puce** saute
  aux pieds de Nin0 puis bondit d'un coup sur le couvercle de la poubelle. Dangers suspendus.
- **Puce** (nouvelle espèce, pacifique) : perchoirs, petits bonds, grands sauts, fuit si l'on s'approche.
  Le joueur doit l'analyser lui-même → réflexion de Nin0 → **technique Saut chargé** apprise.
- **Saut chargé** (technique apprise en observant la puce — *plus fabriquée à l'imprimante
  depuis les correctifs du lot 7*, voir plus bas) :
  appui bref = saut normal (1 u) ; appui maintenu (jambes, au sol) = Nin0 se ramasse, frémit,
  son montant, petit arc de charge à l'écran ; au relâchement, saut jusqu'à 3,4 u.
  Jamais de charge en l'air. Court tutoriel juste après l'apprentissage.
- **Parcours repensés** (sans escalade) :
  - sol → caisse (0,7, saut normal) → carton (3,4) → carton (6,2) → plan de travail (9,0) ;
  - autre accès : packs d'eau (2,6 puis 5,0) → tiroir resté ouvert (6,3) → plan de travail ;
  - plan de travail → boîte de céréales (12) → étagère aimantée du réfrigérateur (15) → dessus (18) ;
  - plan de travail → micro-ondes (12,2) → étagère (15) → casier à épices (18,2 puis 21) → dessus des placards ;
  - avant l'amélioration : sol, dessous des meubles, meuble sous l'évier, caisse ; le plan de travail
    et les hauteurs restent hors de portée.
- **Faune plus dense, mise KO** : 7 cafards au sol (dont 2 « courageux » qui chargent et pincent),
  2 araignées de sol de plus (coin des cartons, pied du réfrigérateur). Trois billes mettent une
  araignée KO (sur le dos, pattes qui frémissent, puis disparition) ; un cafard touché deux fois
  aussi. Retour ≈ 60 s plus tard, jamais à moins de 9 u de Nin0 ni dans le champ de la caméra.
  Les créatures pacifiques (puce, ouvrières) restent pacifiques.
- **Arrière-plan** : le couple du micro-ondes (devenu une marche) est passé sur le dessus de la hotte,
  rendu inaccessible ; le haut du placard est est fermé par une collision.

### Souvenir n° 3 — la liste du réfrigérateur

Petite feuille manuscrite aimantée sur la porte du réfrigérateur (texture volontairement peu lisible).
Le joueur la scanne avec la vision focalisée ; Nin0 la déchiffre ligne par ligne :
« À faire — 1. Fleurs — 2. Récupérer costume au pressing — 3. Acheter des bougies —
4. Préparer la chambre — 5. Anniversaire R… » (rayé). Le nom n'est jamais complété.
Hésitation avant la dernière ligne, long silence, musique baissée ; Nin0 reste perplexe
(« Une liste… des choses à faire. La dernière est rayée. Pourquoi ? »).
L'archive 03/07 n'est accordée qu'après ce scan ; réobserver la note ne redéclenche rien.

## Lot 7B — Guêpes, billes pointues, porte du salon

### Combat des guêpes (cuisine, plan de travail ouest)

Arène : le plan de travail autour de l'évier et de la fenêtre (9 u), accessible seulement
avec le saut chargé. Les guêpes entrent par une imposte entrouverte en haut de la fenêtre.
Trois réserves de plastique (réapparition 45 s) entourent l'arène. L'araignée de la fenêtre
se terre pendant le combat et revient après.

1. **Intro** (première fois) : bourdonnement, deux petites guêpes entrent, la grosse guêpe
   se pose sur le linteau, remarque Nin0 et s'énerve (abdomen rouge, « !! ») ; Nin0 sursaute.
   Musique « boss ». Dangers suspendus pendant toute la séquence.
2. **Phase 1** : les petites guêpes tournent autour de Nin0 et attaquent en piqué, **une seule
   à la fois**, après une préparation lisible (« ! », abdomen relevé, bourdonnement aigu).
   La grosse reste perchée, **hors d'atteinte** (la bille ricoche avec un petit clic), et lance
   des piques après une préparation de 0,85 s (« ! », abdomen relevé, lueur).
   Petite guêpe : 3 billes → KO (tombe ailes repliées, disparaît ; pas de retour).
3. **Transition** (petite mise en scène) : la grosse regarde les petites à terre, se met en
   colère, descend dans l'arène. Contrôle rendu. **Étape sauvegardée.**
4. **Phase 2** (16 points de vie) — patterns :
   - A : approche, dard annoncé (0,9 s), charge en ligne droite, ouverture après la charge ;
   - B : repli derrière la boîte à biscuits sur le dessus des placards (hors de la ligne de tir,
     invulnérable), petit soin (+3), **2 fois au plus** et seulement sous 75 % ;
   - C : immobile près de la fenêtre, elle appelle une petite guêpe (2 s 5) ; **dégâts ×1,5**
     pendant l'appel ; **3 appels au plus**, **2 petites guêpes simultanées au plus**.
5. **Victoire** : la grosse tombe, sonnée ; Nin0 jubile (« Yeeeaah ! »), observe le dard
   (« Ce dard… » / « Une pointe… elle percerait ! »), la guêpe repart par la fenêtre en titubant
   et **ne revient jamais**. Plan **Billes pointues** présenté : à fabriquer à l'imprimante.

Échecs et sorties :
- Nin0 descend du plan de travail : **pause** (les guêpes se replient, aucune attaque), reprise
  à son retour dans la même phase.
- Nin0 hors service : redémarrage sur le plan de travail ; en phase 1, tout recommence
  (intro courte) ; **en phase 2, reprise directement en phase 2**, jamais depuis le début.

### Billes pointues (seconde munition)

- Plan « plan_sting_bead » (victoire) → amélioration « Chargeur de billes pointues »
  (3 filaments) à l'imprimante.
- **A** (AZERTY ; Q en QWERTY, même touche physique) : changer de munition. Choix sauvegardé.
- Bille pointue : 2 plastiques par tir, dégâts ×2, trajectoire plus tendue, **perce**.
  Les billes ordinaires restent utilisables et coûtent toujours 1 plastique.
- Interface : petite étiquette à côté du compteur de plastique, seulement quand on possède
  les deux munitions.

### Porte du salon (côté sas)

Le pêne de la porte est cassé (ruban adhésif) ; un gros élastique tendu entre la poignée et
une patère du mur la retient fermée côté sas. Avant les billes pointues, Nin0 le remarque
(« Retenue par un élastique… ») ; une bille ronde rebondit dessus ; après la victoire :
« Il faudrait une pointe… comme ce dard. » Avec les billes pointues, il comprend, un repère
discret (lueur chaude) apparaît, **le joueur tire** : l'élastique claque, le courant d'air
entrouvre la porte de 30° vers le salon.

Topologie : la charnière est côté est. Le battant entrouvert forme avec le mur un recoin
qui ne s'ouvre que **vers l'ouest** : Nin0 entre dans le salon par sa première partie, sans
mur invisible. Le chemin direct vers la chambre (est) est barré par le battant lui-même.
La chambre reste verrouillée (rideau). Le bloc provisoire « porte fermée » du blockout est
remplacé par ce vrai battant.

### Mode développement

Ctrl+9 : guêpes (plan de travail, canon, saut chargé, plastique) · Ctrl+0 : porte du salon
(billes pointues fabriquées).

## Lot 7C — Début du salon, Nathan, box internet, trophées

### Salon, première partie (x < 0)

Pièce vécue et stylisée, entièrement originale (aucune photo du créateur) :
canapé contre le mur ouest (il bloque la porte de la cuisine, toujours fermée), coussin
tombé et pouf, table basse et table gigogne sur un tapis, meuble TV bas avec télévision,
deux consoles, manettes et jeux, porte vitrée fumée sur une niche ; bureau avec écran,
clavier, lampe, tour d'ordinateur et chaise à roulettes écartée ; meuble à casiers et
panier ; porte-fenêtre lumineuse (soleil au sol, poussière dans le rayon) ; étendoir avec
serviettes et chaussettes, panier de linge.

Gameplay :
- **Sous les meubles** : dessous du canapé (1,2 u, cafards, miettes), table basse, bureau.
- **Par-dessus** : coussin (1,0) → pouf (2,6) → table basse (4,0) au saut chargé ; tour
  d'ordinateur → bureau (7,5) ; panier → étendoir (6,1 puis 9,3) ; casier haut (filament).
- **Tir et couverture** : le dessus du meuble TV domine la pièce (séquence de protection).
- Le meuble TV (5,0) n'est accessible qu'avec Nathan (voir la bascule).

**Seconde partie barrée** par un encombrement réel, dans le prolongement du meuble de
séparation : piles de bacs de rangement (16,8 u), paravent replié, grande plante devant la
porte-fenêtre. Aucun mur invisible. La chambre reste verrouillée (rideau).

Musique : « living room - Nin0 », bouclée proprement (voir `assets/music/LISEZMOI.md`).

### Nathan (souvenir n° 4)

Figurine articulée originale (≈ 13 cm à l'échelle de la maison, trois fois Nin0) :
casquette d'explorateur, écharpe rouge, gilet orange, pantalon bleu, rotules apparentes ;
il bouge par petits à-coups, comme un jouet, avec des clics d'articulations.

- **Rencontre obligatoire, déclenchée seulement par un scan** : Nin0 remarque une figurine
  inerte contre l'accoudoir ; le joueur l'observe avec la vision focalisée.
- Courte mise en scène (dangers suspendus) : Nathan s'anime, sursaute, Nin0 aussi. Échange
  sous-titré (sons de robot pour Nin0, petits sons de jouet pour Nathan). Nathan révèle
  **seulement** : Nin0 est un robot, lui un jouet ; ils ont été fabriqués pour être utilisés
  ensemble ; il y a un humain qu'il appelle « le géant », dont la place est la chambre ; il ne
  l'a pas vu depuis longtemps ; il n'était pas méchant ; Nathan commence à s'inquiéter.
- **Archive 04/07** accordée à la fin ; réobserver Nathan ne redéclenche rien.
- **Compagnon** : **G** ouvre une petite barre d'ordres, **1** Suis-moi · **2** Attends ·
  **3** Va là-bas (point au centre de l'écran) · **4** Interagis (objet visé ou le plus proche).
  Rappel discret de l'ordre en cours en bas à gauche. Le jeu continue pendant le choix.
- Nathan ne meurt jamais et ne se perd pas : coincé plus de 3,5 s ou trop loin, il réapparaît
  près de Nin0, **hors du champ de la caméra**, sur un sol libre. Effrayé, il fuit vers un abri
  (sous la table basse), se calme, puis reprend son ordre.

### Première coopération : la bascule

Une grande règle sur un rouleau de ruban adhésif, devant le meuble TV. Au repos, le bout
côté meuble touche le sol. Nin0 seul est trop léger pour la faire basculer (il le comprend
en l'examinant). Ordre **Interagis** : Nathan monte sur la règle, dépasse le point d'appui,
elle bascule ; il s'assoit au bout et la tient. L'autre bout se lève à 4,4 u contre la porte
vitrée du meuble : Nin0 gravit la règle et saute sur le meuble TV (5,0).

### Séquence de protection

Dès que Nin0 arrive sur le meuble TV pendant que Nathan tient la règle, des cafards sortent
de sous le canapé et filent vers Nathan (au plus deux à la fois). Nin0 tire depuis sa
hauteur : deux billes (ou une pointue) par cafard. Un cafard qui atteint Nathan lui fait peur
(il lâche la règle, fuit à l'abri puis revient la tenir) : jamais de dégât, jamais d'échec
définitif. Trois cafards mis KO : Nathan remercie Nin0, la box devient observable.

### Box internet (souvenir n° 5)

Scan obligatoire (possible seulement une fois la protection réussie). Nin0 se connecte au
réseau de la maison ; **interface de recherche fictive** (pas de vrai navigateur, aucune
marque réelle) : recherche « NIN0 », résultats, puis fiche « Nin0 — compagnon robotique ·
Modèle de série · Série 0 » où s'alignent trois rangées de robots identiques. Nin0 comprend
qu'il est un modèle commercial, **pas pourquoi il est ici**. Aucune information sur les
habitants. Archive 05/07.

### Archives

Souvenirs 1 (dessin), 2 (ticket), 3 (liste), 4 (Nathan), 5 (box) ; **6 et 7 : à définir**.
Les souvenirs 3, 4 et 5 exigent un vrai scan. Contenu des archives inchangé (objet, lignes
dégradées, interprétations successives de Nin0).

### Trophées internes

Autoload `Achievements`, identifiants stables, sauvegarde séparée (`user://nino_trophies.cfg`,
conservée après « Nouvelle partie » ; fichier distinct pour les tests). La progression ne
dépend jamais d'un trophée. Les anciennes sauvegardes débloquent silencieusement ce qui est
déjà mérité. Annonce discrète (« Trophée : … »), onglet **Trophées** dans l'inventaire
(secrets masqués).

| Catégorie | Trophées |
|---|---|
| Progression | jambes, canon, reine, entrée de la cuisine, saut chargé, grosse guêpe, billes pointues, entrée du salon |
| Découverte | toutes les espèces, sept souvenirs, toutes les améliorations |
| Coopération | première énigme avec Nathan (bascule) |
| Secrets | la gomme sur la tête, le dessus des placards de la cuisine, dix créatures KO dans la cuisine, une bille ronde sur l'élastique |

### Mode développement

`--scenario=salon` : salon ouvert, améliorations installées, Nathan encore inerte.

### Commandes ajoutées (lot 7)

| Touche (AZERTY) | Action |
|---|---|
| Espace (maintenir, jambes) | Saut chargé |
| A | Changer de munition (billes / billes pointues) |
| G | Ordres à Nathan, puis 1 à 4 |

## Lot 7 — Correctifs après test manuel et glow-up visuel

### Correctifs (étape 1)

- **Fin du chapitre 2** : le bouton « Quitter » devient **« Rester dans le sas »** ; il annule
  l'entrée de la cuisine sans rien perdre (Nin0 est replacé devant la porte, face au sas).
  Pendant l'écran, Nin0 est immobilisé et les dangers sont suspendus.
- **Saut chargé = technique** apprise en analysant la puce (cinématique d'observation,
  accroupissement, schéma « TECHNIQUE APPRISE »). Aucun coût, aucune fabrication. Drapeau
  `charged_jump_learned` ; les anciennes sauvegardes (amélioration ou plan) sont converties.
  Section **Techniques** dans l'onglet Équipement de l'inventaire.
- **Installation du canon** : Nin0 saute en arc jusqu'à une place d'attente calculée devant
  la machine (raycast au sol) au lieu d'être téléporté de travers.
- **Après le canon** : pensée en deux temps sur le crochet du sas, objectif « Retourner à la
  porte de la cuisine, dans le sas ».
- **Labyrinthe** : trois soldates de plus ; présentation cinématique unique à la première
  entrée (dangers suspendus).
- **Sas** : les éclats de plâtre gris (« taches ») sont retirés.
- **Audio** : limiteur sur le bus Master (−1 dB), bus Music −1 dB, volumes des morceaux
  rapprochés (cible ≈ −26 LUFS, boss −25), corrections par effet sonore (`Sfx.LEVELS`).

### Glow-up visuel (étapes 2 à 5)

Voir **docs/DIRECTION_ARTISTIQUE.md** (palette, matériaux, lumière par pièce, interface).

- Écran titre : logo vectoriel « Nin0 » (le 0 est l'écran-visage), Nin0 en veille dont
  l'écran respire, faisceau chaud, menu aligné à gauche avec liseré orange.
- Réveil : plan large puis lent rapprochement, pénombre qui s'éclaire, yeux qui s'allument
  par à-coups avec une lueur cyan sur la tête ; le tutoriel et la durée sont inchangés.
- Atelier : textures procédurales sur bois, tissus, métal, plastique ; faisceaux de fenêtre
  adoucis (estompés près de la caméra).
- Imprimante : silhouette et palette conservées ; coque grainée, montants en alu brossé,
  halo de l'écran, volutes à la buse pendant l'extrusion.
- Ambiances par pièce : refuge chaud, sas neutre, salle de bain froide, cuisine contrastée,
  salon doux (fondus de 2,4 s).
- Interface : thème commun bleu-gris profond à liseré orange, focus clavier cyan.
- Nin0 : antenne à ressort (accélérations, sauts, oscillation au repos).
