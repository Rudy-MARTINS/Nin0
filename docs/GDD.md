# Nin0 — Game Design Document

**Version :** 0.3 — 23 octobre 2026 (lot 5 : chapitre 2 « Le territoire des fourmis »)  
**Statut :** document de conception évolutif  
**Moteur :** Godot 4.7 (3D), version officielle unique [VALIDÉ]  
**Outils :** VS Code, Codex, Git, GitHub  
**Cible initiale :** PC Windows

> **Convention :** [VALIDÉ] = décidé ensemble ; [PROPOSITION] = hypothèse à tester ; [À DÉFINIR] = décision ouverte ; [DÉVELOPPÉ] / [NON DÉVELOPPÉ] = état dans le projet Godot. Ne pas transformer les propositions en exigences sans validation.

## 1. Vision du jeu [VALIDÉ]

Jeu d'exploration, de plateformes et de combats en 3D. Le joueur incarne **Nin0**, un minuscule robot éducatif intelligent d'environ **5 cm**, dans un appartement abandonné où la nature a repris ses droits. L'environnement est devenu un écosystème d'insectes qui évoluent et s'affrontent indépendamment du joueur.

Le jeu repose sur trois piliers :
- **Échelle miniature :** objets domestiques ordinaires transformés en reliefs, obstacles et chemins.
- **Progression physique :** Nin0 imprime des améliorations pour modifier son corps et accéder à de nouvelles zones.
- **Monde vivant :** les insectes ont leurs propres comportements et peuvent devenir hostiles selon les événements.

Le récit est principalement environnemental, avec une révélation majeure à la fin.

## 2. Nin0 : personnage et identité [VALIDÉ]

- Robot éducatif intelligent, pensé comme un cadeau pour un enfant.
- Taille : environ **5 cm**.
- Design retenu : **hybride**, à la fois mignon et artisanal/mécanique ; yeux numériques expressifs, coque claire, pièces et articulations visibles, caractère de prototype unique.
- Le personnage **n'est pas stupide** : sa vocation éducative explique son format, pas une absence d'intelligence.
- Nom officiel : **Nin0**, écrit avec le **chiffre zéro** [VALIDÉ]. Il fait écho à *niño* (« enfant » en espagnol, avec un ñ). Les anciennes graphies « NINO » / « Nino » sont abandonnées dans tout texte visible ; les noms techniques internes (scripts, nœuds) peuvent rester inchangés.
- Le corps évolue visuellement lorsque de nouveaux modules sont installés.

**Référence visuelle :** le **modèle 3D actuel de Nin0, en mode roues et en mode jambes, est validé comme base artistique** [VALIDÉ, lot 3]. Les évolutions futures l'affinent (détails, matériaux, nouveaux modules visibles) sans le redessiner.

## 3. Déplacements et transformation [VALIDÉ]

### Au début du jeu
- **Mode roues :** locomotion rapide pour parcourir les surfaces et fuir.
- **Escalade :** Nin0 peut grimper sur certaines surfaces adaptées, avec un système de préhension à concevoir.
- **Aucun saut initialement.**

### Première amélioration : deux jambes articulées
- Les jambes sont fabriquées avec l'imprimante 3D.
- Après installation, Nin0 peut alterner entre **mode roues** (rapide) et **mode jambes** (plateformes, saut, combat et précision).
- Le changement de mode déclenche une **courte animation durant laquelle Nin0 doit rester immobile**. C'est une contrainte tactique volontaire.
- **Durée de transformation :** 0,8 seconde, développée et jouable [VALIDÉ pour la démo, ajustable].
- **Deux jambes**, pas quatre.

**Développé (lots 1 à 3) :** roues, escalade des surfaces autorisées (accroche automatique, angles, descente), jambes avec saut, transformation immobile, caméra troisième personne, vision focalisée.

**Reste à définir :** vulnérabilité pendant la transformation en combat, capacités de déplacement futures (planage, super saut…).

## 4. Imprimante 3D et progression [VALIDÉ]

- **Une seule imprimante 3D**, située dans le **placard-hub** (zone 1), visible très tôt [VALIDÉ]. Pas de deuxième imprimante : les raccourcis réduisent les trajets jusqu'à elle.
- **Le modèle actuel de l'imprimante est validé** [VALIDÉ, lot 3].
- Elle fabrique (jambes, renfort de châssis, Armure I, canon), installe les pièces sur Nin0 par son plateau et **répare** Nin0 [VALIDÉ, DÉVELOPPÉ].
- Au départ, le joueur ne sait pas encore à quel point elle sera importante.
- Exploration → découverte d'un besoin / plan → récupération éventuelle de ressources → retour à l'imprimante → fabrication d'un module → ouverture de nouvelles possibilités.
- L'imprimante est un **objet physique dans le monde**, pas seulement un menu abstrait.
- Les modules majeurs ouvrent des chemins et font progresser l'aventure ; des améliorations défensives pourront venir plus tard.
- Ressource développée : **fragments de filament** (compteur simple, sans inventaire complexe) ; plans trouvés dans le décor [VALIDÉ, lot 3].
- [À DÉFINIR] Équilibrage de l'économie à l'échelle du jeu complet.

### 4.3 Deux plastiques, réapparition, inventaire [VALIDÉ, DÉVELOPPÉ au lot 5]
- **Filament structurel** (spirale orange) : réparations, coque, Renfort, Armure I, canon. **Plastique à projectiles** (billes bleues) : munitions du canon, une bille par tir, compteur « n / 24 ». Formes, couleurs, pictogrammes et compteurs distincts.
- Première découverte de chaque type : notification « Filament structurel découvert / Matériau de réparation et de fabrication. » et « Plastique à projectiles découvert / Permet de fabriquer les munitions du canon. », une seule fois (mémorisée) ; ensuite simple ramassage discret.
- **Réapparition [VALIDÉ]** : les ressources ordinaires réapparaissent après un délai de temps de jeu (plastique 3 à 4 min, filament 5 min ; réserve du sas : 25 s), jamais sous les yeux de Nin0, dans le sas, la salle de bain et le placard. Les éléments uniques (souvenirs, plans, récompenses de boss) ne réapparaissent jamais. Non expliqué au joueur.
- Anti-blocage : réserve de plastique à réapparition rapide dans le sas, premier chargement de 6 billes à la fabrication du canon, tir manqué jamais bloquant, réparation toujours possible.
- **Inventaire simplifié** (Tab / I, ou bouton de la pause) : Ressources, Équipement (majeures permanentes, modules et 2 emplacements, échange hors combat), Archives (n/7, fragments, commentaires conservés, emplacements non identifiés), Bestiaire. Alimenté par les données réelles.

### 4.1 Intégrité, bouclier et réparation [VALIDÉ, développé au lot 3]
- **Intégrité** (santé), avec effets visibles (étincelles, parasites, yeux étourdis) ; mise en veille et redémarrage au dernier point sûr au lieu de la mort.
- **Bouclier** distinct de l'intégrité, qui absorbe une partie des dégâts et se recharge après un moment sans dégâts. Distinct du futur module « défense active ».
- **Réparation** à l'imprimante contre des fragments de filament.
- Valeurs actuelles provisoires (à équilibrer) : voir `docs/SYSTEMES_FUTURS.md`.

### 4.2 Architecture des améliorations [VALIDÉ]
- **Améliorations majeures** : jambes (développées), micro-réservoir avec vaporisateur, autres capacités futures.
- **Modules secondaires** : défense active, attaque, ailes / planage, défense passive, super saut. **Deux emplacements au départ, trois plus tard.** Échange possible hors combat, **sans retour obligatoire à l'imprimante**.
- **Évolutions** : une capacité peut recevoir plusieurs niveaux ; un niveau supérieur remplace le précédent. Elles multiplient les découvertes sans multiplier les commandes. Exemple développé : Renfort de châssis I.
- Associations validées : **coccinelle → premier planage**, **papillon → planage prolongé**, **puce → super saut**, **fourmi ouvrière → Armure I** (lot 5), **reine (crachat d'acide) → canon à projectiles plastiques** (lot 5). Les autres associations restent [À DÉFINIR].
- **Armure I [VALIDÉ, DÉVELOPPÉ]** : module secondaire, famille défense passive (distincte du bouclier de base, du futur bouclier actif et du Renfort de châssis). Plan obtenu en analysant une ouvrière (exosquelette), fabriqué à l'imprimante (3 fragments), réduit de 25 % les dégâts physiques (pas l'acide), plaques visibles sur le châssis. Facultatif pour la reine.
- **Canon à projectiles plastiques [VALIDÉ, DÉVELOPPÉ]** : amélioration majeure permanente (aucun emplacement), plan obtenu après la reine, imprimé puis installé physiquement sur l'épaule droite de Nin0. Commande « tir » (clic gauche / X), visée au centre de la caméra, plus précise en vision focalisée (pas de seconde caméra). Munition 1 : billes de plastique ; architecture prête pour un type 2 (projectile pointu, [NON DÉVELOPPÉ]).
- Les modules facultatifs ne doivent pas devenir obligatoires ; ils ouvrent secrets et chemins alternatifs.

## 5. Appartement et level design [VALIDÉ]

- Appartement 3D interconnecté, avec zones pouvant jouer le rôle de niveaux sans séparation rigide.
- **Raccourcis organiques façon Dark Souls** : retour surprenant vers un lieu connu, réduction des trajets fastidieux jusqu'à l'imprimante.
- Exemples [PROPOSITIONS] : grilles de ventilation, conduits, tiroirs, câbles, fissures, meubles, espaces sous les plinthes.
- L'échelle réelle du mobilier et des insectes est une référence de conception ; ne pas grossir arbitrairement les insectes sans raison de gameplay.
- La progression est liée aux capacités physiques de Nin0 et à la découverte de raccourcis.
- Échelle technique : **1 unité Godot = 10 cm** ; Nin0 ≈ 0,5 unité [VALIDÉ, utilisé depuis le lot 1].
- À l'échelle de Nin0, un meuble est un relief entier : hauteurs, surfaces escaladables, dessous de meubles, rebords, conduits et chemins secondaires.

### 5.1 Plan de l'appartement : sept zones [VALIDÉ]

| Zone | Rôle | État |
|---|---|---|
| 1 — Placard-hub | Grande porte, table, chaise, imprimante unique ; fabrication et réparation. **Contient toute la première démo.** | Développé (lots 1 à 3) |
| 2 — Sas | Petite transition derrière la porte du placard ; première vraie zone de jeu. Première ouvrière, colonne, portes du salon et de la cuisine. | **Développé (lot 5)** |
| 3 — Salle de bain | Accessible depuis le sas. Territoire de la colonie : labyrinthes, soldats, escabeau, lavabo de la reine. | **Développé (lot 5)** |
| 4 — Cuisine | Ouverte depuis le sas par le loquet (canon). Contenu non développé. | Accès développé (lot 5), intérieur en blockout |
| 5 — Porte-fenêtre | Ouverture du salon, potentiellement vers un jardin. Pas une pièce indépendante ; **le jardin n'est pas validé comme zone jouable**. | Ouverture préparée (lot 4) |
| 6 — Salon | La plus grande pièce, allongée ; **deux grandes étapes d'exploration** dans une même pièce ; accueille progressivement les espèces rencontrées ailleurs. | Volume construit (lot 4), **fermé** pendant le chapitre 2 |
| 7 — Chambre | Derrière un **rideau japonais**, depuis le salon ; inaccessible pendant la majeure partie du jeu ; zone de la conclusion narrative. | Volume construit, accès verrouillé (lot 4) |

**Connexions [VALIDÉ] :** placard ↔ sas ; sas ↔ salle de bain ; sas ↔ salon ; salon ↔ cuisine ; salon ↔ porte-fenêtre ; sas ↔ cuisine (raccourci futur, fermé au départ) ; salon ↔ chambre (verrouillé jusqu'à la fin). Aucune autre porte ne doit modifier la progression.

**Ordre officiel de progression [VALIDÉ, lot 5] :** PLACARD → SAS → SALLE DE BAIN → CUISINE → SALON → CHAMBRE.
- La porte **sas ↔ cuisine** s'ouvre au canon : une bille soulève un crochet léger posé en haut du chambranle [DÉVELOPPÉ].
- La porte **sas ↔ salon** reste fermée pendant et après le chapitre 2 ; examinable. **Mécanisme d'ouverture [À DÉFINIR]** (ni canon, ni clé, ni boss, ni interrupteur à ce stade).
- Le passage **cuisine ↔ salon** reste fermé pendant le chapitre 2 [DÉVELOPPÉ]. Le futur passage de la porte-fenêtre est conservé.
- Orientation : en entrant dans le sas depuis le placard (vers l'ouest), la porte de la salle de bain est **devant, à droite** (mur ouest, partie nord) — conforme au souhait, conservée sans modification.

**Disposition et dimensions :** [PROPOSITION] — première disposition du lot 4, provisoire, décrite dans `docs/APPARTEMENT.md`.

## 6. Écosystème d'insectes [VALIDÉ]

- Les insectes ne sont pas de simples ennemis statiques : ils se déplacent, réagissent et peuvent interagir ou se combattre entre espèces.
- **Fourmis pacifiques au début.** Elles poursuivent leurs activités et ne s'en prennent pas spontanément à Nin0.
- **Chapitre 2 [VALIDÉ, remplace l'incident pour ce chapitre] :** les **ouvrières restent pacifiques** ; ce sont les **soldats** qui gardent les galeries de la salle de bain (patrouille, détection, poursuite, morsure annoncée, perte de trace, retour). L'ancienne idée « incident involontaire → hostilité générale, accumulation sur le corps, fuite » n'est **pas implémentée** pour ce chapitre ; elle reste une piste [À DÉFINIR] pour plus tard.
- Plus tard, des **outils ou armes défensives** pourront les faire fuir ou se décrocher (le canon fait reculer puis fuir un soldat, qui revient plus tard).

### 6.1 Bestiaire de référence [VALIDÉ en conception ; fourmis DÉVELOPPÉES au lot 5]

| Créature | Comportement | Amélioration associée |
|---|---|---|
| Fourmi ouvrière | Inoffensive (développée) | Armure I (exosquelette) |
| Fourmi soldat (guerrière) | Garde les galeries, offensive (développée) | Aucune à ce stade |
| Reine de la colonie | Premier boss (développée) | Canon à projectiles plastiques (crachat) |
| Araignée A | Offensive | Oui |
| Araignée B | Offensive | Oui, différente de l'araignée A |
| Gendarme | Inoffensif | Aucune |
| Scutigère enfant | Offensive | Aucune |
| Scutigère maman | Boss | Oui |
| Puce | Offensive | Super saut |
| Coccinelle | Inoffensive | Planage initial |
| Papillon | Inoffensif | Planage prolongé |
| Cafard des bois | Offensif | Oui, [À DÉFINIR] |

- Les fourmis ouvrières apparaissent parmi les premières rencontres du **sas**.
- Des araignées peuvent apparaître dans plusieurs pièces.
- Cafards des bois : notamment près des fenêtres, dans la cuisine et le salon.
- Le salon accueille à terme différentes espèces introduites ailleurs.
- Direction artistique des créatures : **cartoon expressive**.
- **Encyclopédie biologique [DÉVELOPPÉ, lot 5]** : la vision focalisée analyse un insecte → fiche « ESPÈCE IDENTIFIÉE » (nom, classification, activité, comportement, particularité), sauvegardée et consultable dans l'inventaire (Bestiaire), sans rejouer la première séquence. Fiches : ouvrière, soldat, reine. Interface originale (pas une copie de Pokédex).
- Les autres capacités biologiques restent **non développées**.

**À définir :** comportements détaillés, capacités manquantes, relations entre espèces, IA, quantité d'insectes affichables, persistance de l'hostilité.

## 7. Début jouable / séquence de référence

### 7.0 Chapitre 2 — Le territoire des fourmis [VALIDÉ, DÉVELOPPÉ au lot 5]
Sas : première ouvrière (courte mise en scène sans hostilité), indice discret d'analyse, fiche d'espèce, réflexion → plan Armure I, colonne d'ouvrières vers la salle de bain, porte du salon fermée, porte de la cuisine fermée. Salle de bain : à gauche un petit labyrinthe facultatif jusqu'au souvenir n° 2 (ticket), à droite des galeries gardées par des soldats (gravier, cailloux, marches, chutes de larves) jusqu'à l'escabeau, puis le plan du lavabo. Reine dans le lavabo (matière visqueuse, débris flottants, crachat d'acide, morsure) ; victoire **sans arme** en tirant la chaînette de la bonde : la matière s'évacue, la reine est emportée (sobre, sans mort graphique). Réflexion → plan du canon ; retour à l'imprimante, impression et installation ; loquet de la cuisine ; **fin du chapitre à l'entrée de la cuisine**. Détails : `docs/CHAPITRE2.md`.
- [PROPOSITION, à valider] Choix techniques du chapitre : vidange par chaînette et anneau sur le rebord, reine aspirée vers la bonde en tournoyant, 6 billes offertes à la fabrication du canon, réduction de 25 % pour Armure I, respawns (délais ci-dessus).

### 7.1 Première démo développée : le placard-hub [VALIDÉ, lots 1 à 3]
Réveil sur le socle et mini-tutoriel ; imprimante hors tension, câble, multiprise ; retour sur roues (planche à repasser, bobine poussée) ; impression et installation des jambes sur le plateau ; transformation ; vision focalisée au rebord de la fenêtre ; poignée ; chute en ouvrant la porte, blessure ; retour en jambes, réparation ; fin sur le seuil du sas. Facultatif : découvertes, premier souvenir, fragments de filament, Renfort de châssis I. Détails : `docs/DEMO.md`.

### 7.2 Structure initiale envisagée [PROPOSITION DE STRUCTURE, antérieure à la démo]
La première démo a remplacé une partie de cette séquence (la rencontre des fourmis et l'incident viendront avec le sas).

1. **Réveil :** Nin0 démarre dans l'atelier ; découverte des commandes et du mode roues.
2. **Première exploration :** escalade et observation de l'imprimante 3D, sans encore comprendre sa fonction centrale.
3. **Monde vivant :** rencontre d'une colonie de fourmis pacifique ; découverte de comportements autonomes.
4. **Obstacle :** une zone nécessite une nouvelle capacité ; découverte du plan ou des éléments nécessaires aux jambes.
5. **Raccourci :** ouverture d'un passage ramenant près de l'imprimante.
6. **Fabrication :** impression et installation des **deux jambes articulées**.
7. **Nouveau gameplay :** passage roues ↔ jambes avec immobilisation ; premier saut.
8. **Incident :** saut/action du joueur causant involontairement du tort aux fourmis.
9. **Fuite :** les fourmis se ruent sur Nin0, le recouvrent et le ralentissent ; le joueur s'éloigne pour s'en débarrasser.

L'ordre et la durée exacts de ces événements seront affinés lors du level design. Une durée initialement envisagée de 10–15 minutes **n'est pas une contrainte ferme**.

## 8. Scénario — SPOILERS / RÉSERVÉ À LA CONCEPTION [VALIDÉ]

> **Ne pas afficher ces révélations au joueur avant la fin.** Toute trace environnementale doit être conçue pour entretenir le mystère sans divulguer la solution.

Un père a entrepris de créer Nin0 comme **cadeau éducatif pour son enfant**. L'enfant est mort **avant que le robot puisse lui être offert**. Nin0 est donc un **cadeau jamais offert et un projet inachevé**. Le père, accablé par le deuil et le désespoir, a fini par se suicider. **Le destin du père constitue la révélation finale**, tandis que l'histoire de l'enfant peut être suggérée progressivement sans révéler prématurément l'ensemble.

**Origine et vocation de Nin0 [VALIDÉ — confidentiel] :** Nin0 est un **robot éducatif acheté dans le commerce**, destiné à être offert à l'enfant. Le père avait commencé à le **personnaliser** et à préparer son environnement, notamment avec l'**imprimante 3D**. Son objectif n'était pas de livrer un robot entièrement amélioré : il voulait que **l'enfant apprenne à améliorer Nin0 lui-même**, accompagné et guidé par le robot — découvrir progressivement les mécanismes, observer, réfléchir, fabriquer des pièces et faire évoluer Nin0. C'était une expérience éducative et interactive, pas un simple jouet personnalisé. Cette intention explique l'imprimante, les plans et schémas mécaniques, le caractère évolutif de Nin0, ses capacités pédagogiques et analytiques, et la découverte progressive des améliorations.

**Ironie narrative centrale [VALIDÉ — confidentiel] :** Nin0 finit par évoluer seul, accompagné du joueur, en réalisant les améliorations que l'enfant aurait dû apprendre à fabriquer.

**Souvenir n° 2 [VALIDÉ — confidentiel] :** le ticket froissé trouvé dans la salle de bain est bien le **reçu d'achat du robot lui-même**. En jeu, il ne montre qu'une référence partielle à « NIN0 », sans contexte : l'histoire doit se reconstruire progressivement par les sept souvenirs et la narration environnementale, sans révélation prématurée.

Le parcours de Nin0 a un double sens : il fabrique lui-même les améliorations qui achèvent le travail de son créateur. Le suicide n'est pas à traiter comme une conséquence automatique du deuil ; privilégier une écriture nuancée et sobre.

**À définir :** cause du réveil, source d'énergie, chronologie de l'abandon, objectif explicite initial de Nin0, nature des indices, lieu et forme de la révélation, conclusion du jeu.

**Question ouverte, non arbitrée [À DÉFINIR] :** l'articulation entre l'histoire du père et l'idée d'une **bonne fin où Nin0 sauve un homme**. Aucune des deux pistes ne doit être tranchée ni mise en œuvre sans décision explicite.

### 8.1 Souvenirs (archives fragmentées) [VALIDÉ]
- **Sept souvenirs** prévus, découverts avec la vision focalisée ; le premier (le dessin du placard) et le **deuxième (ticket froissé, labyrinthe gauche de la salle de bain)** sont développés.
- Souvenir n° 2 en jeu : ticket de caisse minuscule, froissé, à moitié plié, tombé de la poche d'un pantalon abandonné et déplacé par les fourmis ; texte presque illisible, seule la référence « NIN0 » ressort ; commentaire de Nin0 « Nin0… ? C'est mon nom… » puis perturbation. Activation uniquement par la vision focalisée.
- Les archives conservent l'historique des lectures et des commentaires (les premières réactions ne sont pas effacées quand la dégradation change).
- Les cinq autres ne sont **pas encore définis** (contenu, emplacement) : ne pas les placer arbitrairement.
- Leur accumulation améliore progressivement la compréhension de Nin0 (texte de moins en moins dégradé).
- Le jeu distingue déjà 7/7 et incomplet ; **aucune fin n'est développée**.

## 9. Direction artistique [VALIDÉ / À AFFINER]

- 3D stylisée et lisible, plutôt que photoréalisme imposé.
- Ambiance d'appartement ordinaire devenu un monde naturel, étrange, beau et dangereux.
- Nin0 : expressif, mignon et visiblement assemblé à la main ; les nouvelles pièces doivent être visibles.
- Créatures : direction **cartoon expressive** [VALIDÉ].
- Musique : un morceau d'introduction (≈ 1 min 33) est retenu **à titre de prototype interne**, joué une fois au démarrage ; droits commerciaux à régulariser. Musiques par zone prévues [PROPOSITION].
- [À DÉFINIR] Palette définitive, éclairage, matériaux, animations, interface.
- Modèles originaux privilégiés, y compris simples et low-poly ; vérifier les licences des éventuelles ressources externes.

## 10. Plan de développement [historique, PROPOSITION]

> Réalisé : lot 1 (contrôles), lots 2–3 (première démo complète du placard-hub), migration Godot 4.7, lot 4 (blockout de l'appartement), lot 5 (chapitre 2 : sas, salle de bain, reine, canon, cuisine). Le plan ci-dessous est le plan initial, conservé pour mémoire. Prochaine étape : à définir (cuisine, ouverture du salon [À DÉFINIR]).

**Principe :** une fonctionnalité à la fois, testée dans Godot avant d'avancer ; commits Git réguliers.

- **Lot 0 — Fondation :** dépôt GitHub, projet Godot 4, arborescence, README, GDD, .gitignore, conventions et procédure de test.
- **Lot 1 — Contrôles :** scène 3D grise, Nin0 provisoire, caméra, roues, escalade, collisions. **Pas de saut.**
- **Lot 2 — Level design :** atelier et zone attenante, obstacles, raccourci ouvrable.
- **Lot 3 — Fabrication :** imprimante interactive, obtention du module de deux jambes, transformation immobile, saut et mode jambes.
- **Lot 4 — Fourmis :** déplacements pacifiques autonomes, incident, agression collective, accumulation et fuite.
- **Lot 5 — Présentation :** modèle 3D original, animations, retours visuels et sonores, équilibrage.

**Critère de réussite de la première tranche jouable :** Nin0 peut explorer, revenir à l'imprimante par un raccourci, obtenir ses jambes, changer de mode, déclencher l'incident puis échapper aux fourmis.

## 11. Garde-fous pour Codex

1. Ne pas inventer de décisions de game design non validées.
2. Ne pas révéler les spoilers dans les textes visibles par le joueur.
3. Ne pas implémenter un saut avant le module de jambes.
4. Ne pas rendre les fourmis ouvrières agressives ; seuls les soldats gardent les galeries (chapitre 2).
5. Ne pas créer plusieurs imprimantes dans le périmètre initial.
6. Conserver le switch roues/jambes avec immobilisation et animation.
7. Préférer une architecture modulaire et des tests fréquents ; expliquer comment tester chaque lot dans Godot.
8. Ne pas confondre concept art et modèle 3D directement exploitable.

## 12. Journal des décisions

- Nom du jeu/personnage : **Nin0** (chiffre zéro) — remplace « NINO ».
- Taille : **environ 5 cm**.
- Origine : **robot éducatif intelligent**, cadeau jamais offert.
- Design : **hybride mignon / mécanique artisanal**.
- Mobilité initiale : **roues + escalade**, **pas de saut**.
- Premier module : **deux jambes articulées** ; plateformes/combat/saut.
- Transformation : **arrêt obligatoire + courte animation**.
- Progression : **une imprimante**, **raccourcis interconnectés**.
- Fourmis : **pacifiques puis hostiles après un incident involontaire**, accumulation sur le corps et fuite.
- Histoire : **enfant décédé avant le cadeau ; père décédé par suicide ; révélation finale du destin du père**.
- Lots 1–3 : modèle de Nin0 (roues et jambes) et imprimante **validés** ; intégrité, bouclier, réparation, fragments de filament, Renfort de châssis I, vision focalisée et premier souvenir **développés**.
- Migration : **Godot 4.7** seule version officielle.
- Appartement : **sept zones** et connexions validées ; salon en **deux étapes d'exploration** ; chambre derrière un rideau japonais, verrouillée jusqu'à la fin.
- Bestiaire de référence et architecture des améliorations : **validés en conception**.
- Lot 5 : ordre officiel **placard → sas → salle de bain → cuisine → salon → chambre** ; ouvrières pacifiques, **soldats** gardiens (remplace l'incident pour le chapitre 2) ; encyclopédie biologique ; **Armure I** (ouvrière) ; **reine** vaincue sans arme par la vidange ; **canon à projectiles plastiques** (majeure) ; deux plastiques ; réapparition des ressources ordinaires ; cuisine ouverte au canon ; salon fermé (ouverture À DÉFINIR) ; souvenir n° 2 = ticket ; inventaire à quatre onglets.

---

*Ce document est une base de travail, non un cahier des charges définitif. Toute modification des éléments [VALIDÉ] doit être discutée et reportée dans ce journal.*