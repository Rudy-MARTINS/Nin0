# Première démo jouable — le placard-hub (lots 2 et 3)

Ce document décrit la démo telle qu'elle est implémentée : déroulement, level design, systèmes, choix provisoires et limites connues. Le GDD reste la référence de conception et ce document ne le modifie pas.

> Ce document ne contient pas de spoiler du scénario. Les indices de la pièce (dessin d'enfant, cadre retourné, photos neutres, croquis technique) sont volontairement ambigus.

## Lancer la démo

1. Ouvrir le projet dans **Godot 4.7** (version officielle du projet depuis la migration ; voir [MIGRATION_GODOT_4_7.md](MIGRATION_GODOT_4_7.md)).
2. Appuyer sur **F5**. L'écran titre apparaît au-dessus de Nin0 endormi.
3. **Commencer** lance une nouvelle partie. **Continuer** n'apparaît que si les jambes ont déjà été obtenues ; la reprise se fait au bon endroit (imprimante, ou pied de la porte si Nin0 attend sa réparation).
4. **Échap** ouvre la pause : reprendre, **recommencer la démo** (efface la progression), quitter. La pause indique aussi les découvertes et, après le premier souvenir, les **archives fragmentées** (consultables).

| Touche (AZERTY) | Action |
|---|---|
| Z Q S D ou flèches | Se déplacer ; sur une paroi : monter / descendre / se décaler |
| Souris | Caméra |
| E (ou Entrée) | Interagir, examiner |
| Clic droit ou Maj (maintenir) | Vision focalisée (débloquée au rebord de la fenêtre) |
| C | Lâcher une paroi |
| F | Roues ↔ jambes (à l'arrêt, au sol, une fois les jambes installées) |
| Espace | Sauter (mode jambes uniquement) |
| R | Revenir au dernier point sûr (replace aussi les bobines déplacées) |
| Échap | Pause |

## Déroulement

1. **Réveil.** Nin0 est éteint sur son socle. Une touche de déplacement l'allume : son écran vacille, une pensée « … » traduit sa confusion, puis « ? » quand il regarde autour de lui.
2. **Mini-tutoriel.** Trois petites indications successives : avancer, reculer, orienter la caméra. Chacune n'est validée que par l'action réelle. À la fin, Nin0 remarque l'imprimante (pensée œil + imprimante).
3. **Exploration de la table.** On y trouve des obstacles simples et des objets à examiner, tous facultatifs (voir « Découvertes »).
4. **L'imprimante ne répond pas.** Son interface indique « Alimentation : coupée ». À la fermeture, Nin0 pense « imprimante ✖ énergie, Pas d'énergie… », son regard suit le câble, puis « prise ? Le câble… ».
5. **Le câble.** Il longe la table, passe sur la pile de boîtes de filament puis descend au sol. Près de lui, Nin0 se demande « prise ↓ Où va-t-il ? Plus bas ? ».
6. **La multiprise**, sous la table, dans la pénombre. Nin0 la remarque (« prise ! »), le joueur appuie sur l'interrupteur : clic, bourdonnement de mise sous tension et voyant rouge allumé. Nin0 est d'abord surpris (« ? »). L'imprimante s'éveille alors avec un petit carillon, Nin0 lève les yeux et fait le lien (« prise → imprimante ⚡ »), puis jette un regard vers la planche à repasser (« ↑ ? »), sans indication écrite. L'objectif devient « Retourner à l'imprimante ».
7. **Le retour, sur roues, sans escalade.**
   - Une planche à repasser appuyée contre le mur de droite mène à une pile de boîtes de filament.
   - Une encoche coupe le chemin. Une bobine vide et légère attend devant elle (pensée « bobine → ? Légère ? ») : Nin0 la pousse en roulant contre elle et elle s'encastre dans l'encoche (« bobine ✔ »).
   - Une planche mène ensuite à une seconde pile, à la hauteur de la table.
   - Une autre bobine, posée au sol près de la planche à repasser, permet de découvrir librement qu'on peut pousser les bobines.
8. **Comprendre l'imprimante.** Sous tension, Nin0 l'observe (« œil imprimante »), puis comprend (« imprimante → engrenage, Elle fabrique… »). L'interface montre l'alimentation, le plan disponible (« Jambes mécaniques ») et le bouton Imprimer. Au lancement, Nin0 pense « jambes → robot, Pour moi ? ».
9. **Impression.** Chauffe de la buse, puis la tête et le plateau bougent et les jambes apparaissent couche par couche. La progression s'affiche sur l'écran de la machine et dans l'objectif (« Impression en cours… 42 % »). Un signal sonore marque la fin et le plateau s'avance.
10. **Accès à la plateforme.** Nin0 se demande comment monter (« ↑ ? »). Un carnet est posé debout devant l'imprimante : « Pousser le carnet » le fait basculer, et il forme une rampe jusqu'au plateau.
11. **Installation.** Dès que Nin0 est sur le plateau, la machine le détecte. Le plateau le transporte sous la tête, qui saisit chaque jambe imprimée et l'emboîte sur ses fixations (clic, étincelle), puis le ramène à l'avant.
12. **Premiers pas.** À la première transformation (F, à l'arrêt), Nin0 est surpris, regarde ses jambes et pense « jambes ! », puis se réjouit.
13. **La fenêtre.** Des marches (boîte d'allumettes, livres) mènent au rebord, au-dessus de la table. Courte mise en scène : la caméra se tourne vers la porte, Nin0 remarque quelque chose au loin (« œil ? »), plisse les yeux à deux reprises, force sa vue ; son système optique réagit (son, grésillement du visage) et se calibre à l'écran (balayage, réticule qui se resserre, « SYSTÈME OPTIQUE · CALIBRAGE » puis « VISION FOCALISÉE »). Annonce « Nouvelle capacité : vision focalisée » et rappel de la touche.
14. **Observer.** En maintenant clic droit ou Maj, la vue passe « à travers ses yeux » : zoom, masque de jumelles, réticule et repère discret sur la poignée. Garder la poignée au centre quelques instants l'identifie (« Poignée repérée »). Nin0 comprend qu'il peut l'atteindre ; son regard passe des boîtes à l'étagère (aucun texte d'itinéraire).
15. **Le parcours final, en jambes.** Une boîte et deux livres au bout gauche de la table mènent sur l'étagère de rangement. On la longe en sautant par-dessus un rouleau d'adhésif et une boîte, jusqu'à la poignée.
16. **La porte et la chute.** « Saisir la poignée » : Nin0 s'élance (bulle « LEEEROOOY JENKINS ! »), bondit sur le levier, l'abaisse de son poids (clac du pêne). La porte se déverrouille et s'entrouvre (20°, juste assez pour Nin0) : secousse, Nin0 lâche prise et **tombe réellement jusqu'au sol** (chute physique, sifflet cartoon). Choc lourd, gerbe d'étincelles, écran du visage parasité, yeux en spirale, grincement mécanique ; il reste couché sur le flanc, rate un premier relevé puis se redresse. Il se regarde (« robot ⚡ … »), puis pense à la machine qui l'a assemblé (« imprimante 🔧 »). La jauge d'intégrité apparaît (55 / 100). Objectif : « Se faire réparer à l'imprimante ». La porte reste ouverte.
17. **Retour avec les jambes.** Juste à côté, derrière la chaise : un carton de rangement (escaladable), puis une pile de livres posée sur l'assise, en escalier jusqu'à la table. Court, lisible, impossible en roues (sauts). Trois fragments de filament jalonnent ce chemin. Les anciennes énigmes restent résolues ; le chemin de la planche à repasser reste possible.
18. **Réparation.** L'imprimante est de nouveau utilisable : sa carte « Réparation » indique l'intégrité et le coût (3 fragments). Nin0 saute sur le plateau, qui le glisse sous la tête ; la buse balaie son corps (étincelles, sons de soudure) pendant que la jauge remonte. Première réparation : 6 s ; les suivantes : 3 s. « Intégrité restaurée ».
19. **Facultatif : Renfort de châssis I.** Avec le plan roulé trouvé dans le tube en carton et 4 fragments, l'imprimante le fabrique et l'installe de la même façon (+25 d'intégrité max., la jauge s'allonge).
20. **Fin.** Objectif « Franchir la porte ». Sur le seuil, la caméra se tourne vers le sas, Nin0 regarde, curieux, puis heureux : « Nin0 — Fin de la première démo ». Le sas n'est pas jouable.

Aucune fourmi, aucun combat ni aucun événement de la suite. Le sas n'est qu'un décor entrevu.

### Facultatif pendant toute la démo

- **Souvenir 1** (archives fragmentées) : le dessin d'enfant du mur de gauche. Avant la vision, Nin0 le remarque sans rien obtenir. Après la fenêtre, son visage grésille faiblement en passant devant (petit signal sonore). Observé avec la vision focalisée, d'assez près, sous un angle valable et assez longtemps : signal détecté, parasites plein écran, fragments de mots dégradés, « ENREGISTREMENT INCOMPLET », « Fragment mémorisé · Archives fragmentées — 1/7 », puis Nin0 cherche à comprendre (« ? … »). Le dessin reste observable après coup (le chemin de l'étagère passe dessous ; retour possible à tout moment).
- **Fragments de filament** : 8 petits bouts de fil enroulés, lumineux, dans des recoins crédibles (sous la table, coin des boîtes de filament, coffre à jouets, derrière le pot du rebord, bout de l'étagère, et 3 sur le chemin de la chaise). Compteur discret en haut à droite, apparu au premier.
- **Plan roulé** dans le tube en carton (découverte, emportée).

## Changements de level design

- **Identité de la pièce : un placard-hub.** Il contient une grande porte, une table (l'établi), une chaise et l'imprimante unique.
- **La fenêtre** passe du mur de gauche au **mur du fond, au-dessus de la table**. Le mur de gauche reçoit la **grande porte** vers le sas (zone 2), ce qui évite qu'une porte intérieure s'ouvre dans le même mur qu'une fenêtre extérieure.
- **Le retour à l'imprimante** n'est plus une escalade de cartons : ces cartons ont été remplacés par la planche à repasser, les boîtes de filament, la bobine à pousser et la planche.
- **Accès au plateau** par le carnet renversé ; l'imprimante a été légèrement reculée pour laisser la place à la rampe.
- **Étagère de rangement** contre le mur gauche, accolée à la table : c'est le chemin vers la poignée.
- **Mobilier déplacé** : le fauteuil et sa peluche, ainsi que la bibliothèque, passent contre le mur avant.
- **Lot 3** : la plante quitte le devant de la porte pour le mur avant, entre la bibliothèque et le fauteuil (ses feuilles mortes la suivent) ; la touffe d'herbe au pied du tube en carton est retirée ; le servomoteur de rechange est remodelé (boîtier, pattes de fixation, tourelle, palonnier en croix, étiquette, câble trois fils et connecteur) ; la planche à repasser ressemble à une vraie planche mal rangée (extrémité large contre la pile de boîtes, nez arrondi au sol, pieds en ciseaux à moitié repliés avec embouts, trace de fer) avec la même pente et la même largeur utile qu'au lot 2 ; carton et pile de livres sur la chaise pour le retour en jambes ; seuil du sas bloqué.
- **Décor narratif autour de l'imprimante** : croquis des jambes, deux photos encadrées (un paysage et des fleurs, volontairement neutres), tableau en liège avec des notes vierges, tasse au thé séché, lunettes, bac de pièces détachées, fiche d'instructions en pictogrammes, cadre posé face contre la table.
- L'escalade reste disponible (coffre à jouets, bac à sable), mais elle n'est plus obligatoire.

## Systèmes ajoutés (réutilisables)

| Système | Fichiers | Rôle |
|---|---|---|
| Pensées | `scripts/ui/thought_bubbles.gd`, `thought_icon.gd`, `thought_bubble_frame.gd`, `scenes/ui/thought_bubbles.tscn` | Bulles au-dessus de Nin0. Pictogrammes vectoriels (24 symboles) et texte très court facultatif. Une bulle à la fois, file courte ; une réaction à un événement remplace la bulle en cours. |
| Découvertes | `scripts/discovery/discovery_data.gd`, `scripts/interaction/examinable.gd`, `assets/discoveries/*.tres` | Un fichier `.tres` par objet : titre, pensée, déduction, objet emportable ou non. Sauvegardées. |
| Objets poussables | `scripts/props/pushable_spool.gd`, `spool_slot.gd` | Bobines légères qui restent à plat et emplacement qui les encastre. Elles se réinitialisent si elles tombent ou au retour au point sûr. |
| Rampe à renverser | `scripts/props/topple_ramp.gd` | Objet debout qui bascule en rampe (collision synchronisée avec l'animation). |
| Vision focalisée | `scripts/focus/focus_vision.gd`, `focus_target.gd`, `scripts/ui/focus_overlay.gd`, `assets/shaders/focus_mask.gdshader` | Maintenir pour observer ; viser une `FocusTarget` l'identifie. Repères facultatifs pour les éléments peu visibles. |
| Porte du placard | `scripts/level/closet_door.gd`, `scenes/props/closet_door.tscn` | Levier abaissé par le poids de Nin0, puis ouverture de la porte. |
| Installation sur le plateau | `scripts/level/printer_3d.gd` | Plateau avec collision, zone de détection, pose assistée des pièces. Lot 3 : `service()` (réparation, renfort) réutilise la même mécanique. |
| Observation (lot 3) | `scripts/focus/observation_profile.gd`, `assets/observation/*.tres` | Règle commune : portée, temps de visée, tolérance, angle de la face observée, obstacles (rayon contre le décor). États « trop loin » / « angle insuffisant » affichés sous le réticule ; une cible cachée n'est pas vue du tout. |
| Archives fragmentées (lot 3) | `scripts/memory/*.gd`, `assets/memories/*.tres`, `scripts/ui/memory_player.gd`, `assets/shaders/memory_glitch.gdshader` | Souvenirs obtenus uniquement par observation ; dégradation selon le nombre retrouvé ; identifiants uniques ; consultables en pause. |
| Intégrité et bouclier (lot 3) | `scripts/player/nino_integrity.gd`, `scripts/ui/integrity_gauge.gd`, `GameState` | Dégâts des grosses chutes seulement, bouclier rechargeable, mise en veille sans mort, effets visibles (étincelles, parasites, yeux étourdis). |
| Fragments de filament (lot 3) | `scripts/props/filament_pickup.gd` | Ressource simple (compteur), identifiants uniques, sauvegardée. |
| Améliorations (lot 3) | `scripts/upgrades/*.gd`, `assets/upgrades/*.tres` | Catégories majeures / modules / évolutions ; voir [SYSTEMES_FUTURS.md](SYSTEMES_FUTURS.md). |

Le directeur de la pièce (`scripts/level/workshop_director.gd`) relie ces systèmes selon le principe **observer → comprendre → agir**.

L'objectif (en haut à gauche) dit ce que le joueur cherche à faire ; les pensées disent ce que Nin0 remarque ou déduit. Les deux ne se répètent pas.

## Découvertes (facultatives)

| Objet | Où | Pensée |
|---|---|---|
| Croquis de jambes | Mur, au-dessus de l'imprimante (s'examine depuis la table, à sa droite) | œil + jambes, « Des jambes ? » → « …comme les miennes ? » |
| Fiche de l'imprimante | Contre le flanc gauche de l'imprimante | imprimante → engrenage → « Elle fabrique des pièces. » |
| Petit servomoteur (emporté) | Bac de pièces, sous la fenêtre | engrenage ? → « Une pièce comme moi. » |
| Cadre retourné | Sur la table, à droite de l'imprimante | cadre ? « Il est retourné. » |
| Plan roulé (emporté, lot 3) | Au fond du tube en carton | livre ? → « imprimante engrenage, Un plan… » |

Le dessin du mur de gauche n'est plus une découverte à examiner : c'est le souvenir 1, obtenu uniquement par la vision focalisée (pas de double récompense). Une ancienne sauvegarde où il avait été examiné ne donne pas le souvenir.

## ADN de la démo-tutoriel (lot 3)

| Mécanique | Où elle est apprise |
|---|---|
| Déplacement (roues) | Réveil et mini-tutoriel sur la table |
| Observation | Pensées, regards de Nin0, découvertes |
| Interaction | Découvertes, multiprise, imprimante, carnet, poignée |
| Énigme physique | Bobine poussée dans l'encoche |
| Fabrication | Impression des jambes |
| Installation | Pose des jambes sur le plateau |
| Transformation | Roues ↔ jambes (F) |
| Plateformes | Marches vers la fenêtre, étagère, pile de livres |
| Vision focalisée | Calibrage au rebord, poignée |
| Souvenirs | Le dessin (facultatif) |
| Ressources | Fragments de filament |
| Intégrité | Chute de la porte, jauge, bouclier |
| Réparation | Imprimante, après la chute |
| Amélioration complémentaire | Renfort de châssis I (facultatif) |

## Choix à valider [PROPOSITION]

- **Architecture de la pièce** : fenêtre au fond, porte vers le sas à gauche. Comme le prévoit le plan, la porte-fenêtre du jardin et le rideau de la chambre sont ailleurs.
- **Énigme du retour** : une seule bobine utile (la seconde sert à découvrir la poussée) ; planche à repasser et planche de bois comme rampes.
- **Accès au plateau** : carnet à pousser (touche E) plutôt qu'une poussée physique.
- **Installation** : assistance de la tête d'impression ; les jambes s'installent repliées.
- **Vision focalisée** : touche clic droit ou Maj, vue subjective, Nin0 immobile pendant l'observation, repère discret sur la poignée.
- **Porte** : poignée à levier abaissée par le poids de Nin0 ; la porte s'ouvre vers le sas.
- **Contenu des photos et du cadre** : neutre et provisoire (paysage, fleurs ; cadre retourné jamais révélé).
- **Textes des pensées** : très courts, en français, à relire (« Pas d'énergie… », « Le câble… », « Où va-t-il ? Plus bas ? », « Légère ? », « Elle fabrique… », « Pour moi ? », « Je peux l'atteindre ? »). Les indications d'itinéraire écrites du lot 2 sont remplacées par des regards de Nin0.
- **Lot 3 — valeurs** : intégrité 100, bouclier 20, chute de la porte −45 (directe), seuil de dégâts de chute 18 u/s (une chute depuis la table n'entame que le bouclier), réparation 3 fragments, renfort 4 fragments (+25), 8 fragments dans la pièce.
- **Lot 3 — souvenir 1** : texte provisoire reprenant les exemples de ton (« Bzzzt… », « …demain… », « Bzzz… pourquoi… ? ») ; profil d'observation : 7 unités max., face observée à moins de 65°, 1,6 s de visée.
- **Lot 3 — retour en jambes** par le carton escaladable et la pile de livres sur la chaise ; renfort disponible seulement après la première réparation.
- **Lot 3 — fin** : sur le seuil de la porte ouverte (le sas reste bloqué).
- **Hauteur de saut** : inchangée (1 unité = 10 cm) ; le parcours n'exige aucun saut de plus de 0,7 unité.

## Ce qui reste provisoire

- Modèle de Nin0 (non validé artistiquement) et décor générés dans Godot.
- Sons synthétisés : à remplacer par un vrai sound design.
- L'ours en peluche est fait de sphères ; la vue extérieure et le sas sont de simples décors.
- Pictogrammes des pensées dessinés en vectoriel simple ; ils pourront être redessinés.

## Tests

### Automatiques (sans affichage, Godot 4.7)

```
Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tests/test_demo_flow.tscn
Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tests/test_lot1_movement.tscn
```

- `test_demo_flow` (134 vérifications) couvre :
  - le réveil, les pensées, le tutoriel (chaque étape exige l'action, et tourner ne valide pas « avancer ») ;
  - les découvertes, les passages du sol, la visibilité de Nin0 sous le fauteuil ;
  - l'imprimante hors tension, le câble, la multiprise et le lien compris par Nin0 ;
  - **le retour réel sur roues** (planche à repasser, bobine poussée dans l'encoche, planche, table) ;
  - la compréhension de l'imprimante, l'impression et sa progression ;
  - **le carnet renversé et la montée réelle sur le plateau**, l'installation et la sauvegarde ;
  - les refus de transformation, l'immobilité, l'absence de téléportation, la réaction aux premiers pas, le saut et la vitesse ;
  - **la montée réelle jusqu'au rebord par sauts**, la vision focalisée sur la poignée ;
  - **le parcours réel sur l'étagère**, l'ouverture de la porte et l'écran de fin ;
  - « Continuer » (jambes, bobine et carnet en place, découvertes conservées), « Nouvelle partie » (tout réinitialisé), la réinitialisation d'une bobine tombée et la touche R ;
  - **lot 3** : plan dans le tube, fragment ramassé une seule fois, pot hors du passage, dessin non examinable ; calibrage de la vision ; règles d'observation (trop loin, angle rasant, mur, table, visée à côté) ; souvenir obtenu seulement après une visée assez longue, séquence, aucun doublon, archives en pause ; chute réelle au sol, dégâts directs, jauge, réaction, objectif ; bouclier qui absorbe et se recharge, petite chute sans coût ; **retour réel en jambes** (escalade du carton, sauts sur les livres), fragments suffisants ; réparation sur le plateau, coût, jambes conservées ; renfort fabriqué (125) ; fin sur le seuil ; reprise complète (porte ouverte, souvenir, renfort, fragments, objets emportés) ; ancienne sauvegarde sans souvenir automatique ; dégradation décroissante avec données fictives, 7/7 distinguable.
- `test_lot1_movement` (18 vérifications) couvre les roues, l'escalade et les nouveautés d'escalade : contourner un angle, s'accrocher en quittant le bord d'un carton, redescendre.
- Les tests utilisent leur propre fichier de sauvegarde (`user://nino_test.cfg`) : la sauvegarde du joueur (`user://nino_demo.cfg`) n'est jamais modifiée, et le test le vérifie.
- `tests/fixtures/save_lot3_godot43.cfg` est une vraie sauvegarde du lot 3 écrite par la version 4.3 du jeu ; le test vérifie qu'elle est relue intégralement sous 4.7.
- Sans affichage, la souris ne peut pas être capturée : pour l'étape « caméra » du tutoriel, le test fait tourner la caméra comme le ferait la souris.

- `test_apartment` (51 vérifications) : blockout de l'appartement en mode développement (voir [APPARTEMENT.md](APPARTEMENT.md)).
- Lot 4 dans `test_demo_flow` : musique d'introduction lancée une seule fois, commentaire après le souvenir, bulle avant le saut, porte réellement entrouverte.

### Manuels, à faire sur PC

1. **Sensations** : roues inchangées, poussée de la bobine, montée de la planche à repasser et du carnet en roues, précision des sauts sur l'étagère.
2. **Lisibilité** : taille et durée des bulles de pensée, compréhension des pictogrammes, indications du tutoriel.
3. **Vision focalisée** : confort du zoom et de la sensibilité, repérage de la poignée depuis le rebord.
4. **Caméra** : sous la table, sous le fauteuil, dans le tube, le long de l'étagère, pendant l'installation et l'ouverture de la porte.
5. **Son** : volume relatif des nouveaux effets (multiprise, bobine, carnet, installation, porte, chute, parasites, réparation).
8. **Lot 3** : lisibilité des fragments de filament, de la jauge, du texte du souvenir ; durée ressentie de la chute et du relevé ; confort de la visée du dessin ; sauts sur la pile de livres.
6. **Blocages** : essayer de faire tomber la bobine, de tomber dans l'encoche, de chuter de l'étagère, puis utiliser R.
7. **Sauvegarde** : obtenir les jambes, quitter, relancer et « Continuer » ; puis « Recommencer la démo » depuis la pause.

## Limites connues

- Les captures de contrôle ont été faites avec un rendu logiciel. Le rendu réel sur carte graphique, la prise en main et les sons restent à vérifier sur PC.
- Pendant la vision focalisée, Nin0 est immobile et masqué (vue subjective).
- Lot 3 : la séquence de souvenir et la chute ne peuvent pas être passées. Pendant la chute scriptée, la caméra suit Nin0 sans gestion particulière des murs proches.
- Lot 3 : les états d'intégrité inférieurs à 80 % ajoutent des parasites et des étincelles occasionnels jusqu'à la réparation (aucun ralentissement).
- Les bulles de pensée suivent la tête de Nin0 à l'écran et peuvent être partiellement cachées près des bords.
- L'escalade reste simple (surfaces planes) ; les transitions d'angle et la descente fonctionnent sur des blocs rectangulaires.
- Si Nin0 tombe dans l'encoche avant d'y avoir poussé la bobine, il peut en ressortir par le côté ouvert (chute sans dégât) ou utiliser R.
- Correction (lot 4) : le battant de la porte du placard ne suivait pas la rotation de sa charnière (corps animé synchronisé à la physique) ; il tourne désormais réellement et laisse passer Nin0.
- Les fichiers `.uid` (à côté des scripts et shaders) sont versionnés : ils font partie du projet Godot 4.7 et ne doivent pas être supprimés.
- Message sans gravité en mode headless : `Parameter "m" is null` apparaît uniquement avec le pilote graphique factice.
