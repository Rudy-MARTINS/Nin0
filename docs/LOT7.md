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
  Le joueur doit l'analyser lui-même → réflexion de Nin0 → plan **Saut chargé**.
- **Saut chargé** (amélioration majeure permanente, 4 filaments, à l'imprimante) :
  appui bref = saut normal (1 u) ; appui maintenu (jambes, au sol) = Nin0 se ramasse, frémit,
  son montant, petit arc de charge à l'écran ; au relâchement, saut jusqu'à 3,4 u.
  Jamais de charge en l'air. Court tutoriel après l'installation.
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
- **Q** : changer de munition (billes / billes pointues). Choix sauvegardé.
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
