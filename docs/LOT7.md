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
