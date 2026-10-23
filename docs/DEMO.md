# Première démo jouable — le placard-hub (lot 2)

Ce document décrit la démo telle qu'elle est implémentée : déroulement, level design, systèmes, choix provisoires et limites connues. Le GDD reste la référence de conception et ce document ne le modifie pas.

> Ce document ne contient pas de spoiler du scénario. Les indices de la pièce (dessin d'enfant, cadre retourné, photos neutres, croquis technique) sont volontairement ambigus.

## Lancer la démo

1. Ouvrir le projet dans Godot 4.x. Le projet a été créé avec 4.3 et vérifié avec 4.3 et 4.7.
2. Appuyer sur **F5**. L'écran titre apparaît au-dessus de NINO endormi.
3. **Commencer** lance une nouvelle partie. **Continuer** n'apparaît que si les jambes ont déjà été obtenues.
4. **Échap** ouvre la pause : reprendre, **recommencer la démo** (efface la progression), quitter. La pause indique aussi le nombre de découvertes.

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

1. **Réveil.** NINO est éteint sur son socle. Une touche de déplacement l'allume : son écran vacille, une pensée « … » traduit sa confusion, puis « ? » quand il regarde autour de lui.
2. **Mini-tutoriel.** Trois petites indications successives : avancer, reculer, orienter la caméra. Chacune n'est validée que par l'action réelle. À la fin, NINO remarque l'imprimante (pensée œil + imprimante).
3. **Exploration de la table.** On y trouve des obstacles simples et des objets à examiner, tous facultatifs (voir « Découvertes »).
4. **L'imprimante ne répond pas.** Son interface indique « Alimentation : coupée ». À la fermeture, NINO pense « imprimante ✖ énergie », puis « prise ? D'où vient l'énergie ? ».
5. **Le câble.** Il longe la table, passe sur la pile de boîtes de filament puis descend au sol. Près de lui, NINO pense « prise ↓ Le câble descend… ».
6. **La multiprise**, sous la table, dans la pénombre. NINO la remarque (« prise ! »), le joueur appuie sur l'interrupteur : clic, bourdonnement de mise sous tension et voyant rouge allumé. NINO est d'abord surpris (« ? »). L'imprimante s'éveille alors avec un petit carillon, NINO lève les yeux et fait le lien (« prise → imprimante ⚡ »). L'objectif devient « Retourner à l'imprimante ».
7. **Le retour, sur roues, sans escalade.**
   - Une planche à repasser appuyée contre le mur de droite mène à une pile de boîtes de filament.
   - Une encoche coupe le chemin. Une bobine vide et légère attend devant elle (pensée « bobine → ? ») : NINO la pousse en roulant contre elle et elle s'encastre dans l'encoche (« bobine ✔ »).
   - Une planche mène ensuite à une seconde pile, à la hauteur de la table.
   - Une autre bobine, posée au sol près de la planche à repasser, permet de découvrir librement qu'on peut pousser les bobines.
8. **Comprendre l'imprimante.** Sous tension, NINO l'observe (« œil imprimante »), puis comprend (« imprimante → engrenage, Elle fabrique… »). L'interface montre l'alimentation, le plan disponible (« Jambes mécaniques ») et le bouton Imprimer. Au lancement, NINO pense « jambes → robot, Pour moi ? ».
9. **Impression.** Chauffe de la buse, puis la tête et le plateau bougent et les jambes apparaissent couche par couche. La progression s'affiche sur l'écran de la machine et dans l'objectif (« Impression en cours… 42 % »). Un signal sonore marque la fin et le plateau s'avance.
10. **Accès à la plateforme.** NINO se demande comment monter (« ↑ ? »). Un carnet est posé debout devant l'imprimante : « Pousser le carnet » le fait basculer, et il forme une rampe jusqu'au plateau.
11. **Installation.** Dès que NINO est sur le plateau, la machine le détecte. Le plateau le transporte sous la tête, qui saisit chaque jambe imprimée et l'emboîte sur ses fixations (clic, étincelle), puis le ramène à l'avant.
12. **Premiers pas.** À la première transformation (F, à l'arrêt), NINO est surpris, regarde ses jambes et pense « jambes ! », puis se réjouit.
13. **La fenêtre.** Des marches (boîte d'allumettes, livres) mènent au rebord, au-dessus de la table. NINO y remarque la grande porte du placard (« porte ? ») et la **vision focalisée** est débloquée.
14. **Observer.** En maintenant clic droit ou Maj, la vue passe « à travers ses yeux » : zoom, masque de jumelles, réticule et repère discret sur la poignée. Garder la poignée au centre quelques instants l'identifie (« Poignée repérée »). NINO comprend alors qu'il peut l'atteindre.
15. **Le parcours final, en jambes.** Une boîte et deux livres au bout gauche de la table mènent sur l'étagère de rangement. On la longe en sautant par-dessus un rouleau d'adhésif et une boîte, jusqu'à la poignée.
16. **La porte.** « Saisir la poignée » : NINO bondit sur le levier, l'abaisse de son poids (clac du pêne) et se laisse retomber sur l'étagère. La porte, déverrouillée, s'ouvre lentement sur le sas, à peine éclairé. Puis : « NINO — Fin de la première démo ».

Aucune fourmi, aucun combat ni aucun événement de la suite. Le sas n'est qu'un décor entrevu.

## Changements de level design

- **Identité de la pièce : un placard-hub.** Il contient une grande porte, une table (l'établi), une chaise et l'imprimante unique.
- **La fenêtre** passe du mur de gauche au **mur du fond, au-dessus de la table**. Le mur de gauche reçoit la **grande porte** vers le sas (zone 2), ce qui évite qu'une porte intérieure s'ouvre dans le même mur qu'une fenêtre extérieure.
- **Le retour à l'imprimante** n'est plus une escalade de cartons : ces cartons ont été remplacés par la planche à repasser, les boîtes de filament, la bobine à pousser et la planche.
- **Accès au plateau** par le carnet renversé ; l'imprimante a été légèrement reculée pour laisser la place à la rampe.
- **Étagère de rangement** contre le mur gauche, accolée à la table : c'est le chemin vers la poignée.
- **Mobilier déplacé** : le fauteuil et sa peluche, ainsi que la bibliothèque, passent contre le mur avant ; la plante va près de la porte.
- **Décor narratif autour de l'imprimante** : croquis des jambes, deux photos encadrées (un paysage et des fleurs, volontairement neutres), tableau en liège avec des notes vierges, tasse au thé séché, lunettes, bac de pièces détachées, fiche d'instructions en pictogrammes, cadre posé face contre la table.
- L'escalade reste disponible (coffre à jouets, bac à sable), mais elle n'est plus obligatoire.

## Systèmes ajoutés (réutilisables)

| Système | Fichiers | Rôle |
|---|---|---|
| Pensées | `scripts/ui/thought_bubbles.gd`, `thought_icon.gd`, `thought_bubble_frame.gd`, `scenes/ui/thought_bubbles.tscn` | Bulles au-dessus de NINO. Pictogrammes vectoriels (24 symboles) et texte très court facultatif. Une bulle à la fois, file courte ; une réaction à un événement remplace la bulle en cours. |
| Découvertes | `scripts/discovery/discovery_data.gd`, `scripts/interaction/examinable.gd`, `assets/discoveries/*.tres` | Un fichier `.tres` par objet : titre, pensée, déduction, objet emportable ou non. Sauvegardées. |
| Objets poussables | `scripts/props/pushable_spool.gd`, `spool_slot.gd` | Bobines légères qui restent à plat et emplacement qui les encastre. Elles se réinitialisent si elles tombent ou au retour au point sûr. |
| Rampe à renverser | `scripts/props/topple_ramp.gd` | Objet debout qui bascule en rampe (collision synchronisée avec l'animation). |
| Vision focalisée | `scripts/focus/focus_vision.gd`, `focus_target.gd`, `scripts/ui/focus_overlay.gd`, `assets/shaders/focus_mask.gdshader` | Maintenir pour observer ; viser une `FocusTarget` l'identifie. Repères facultatifs pour les éléments peu visibles. |
| Porte du placard | `scripts/level/closet_door.gd`, `scenes/props/closet_door.tscn` | Levier abaissé par le poids de NINO, puis ouverture de la porte. |
| Installation sur le plateau | `scripts/level/printer_3d.gd` | Plateau avec collision, zone de détection, pose assistée des pièces. |

Le directeur de la pièce (`scripts/level/workshop_director.gd`) relie ces systèmes selon le principe **observer → comprendre → agir**.

L'objectif (en haut à gauche) dit ce que le joueur cherche à faire ; les pensées disent ce que NINO remarque ou déduit. Les deux ne se répètent pas.

## Découvertes (facultatives)

| Objet | Où | Pensée |
|---|---|---|
| Croquis de jambes | Mur, au-dessus de l'imprimante (s'examine depuis la table, à sa droite) | œil + jambes, « Des jambes ? » → « …comme les miennes ? » |
| Fiche de l'imprimante | Contre le flanc gauche de l'imprimante | imprimante → engrenage → « Elle fabrique des pièces. » |
| Petit servomoteur (emporté) | Bac de pièces, sous la fenêtre | engrenage ? → « Une pièce comme moi. » |
| Cadre retourné | Sur la table, à droite de l'imprimante | cadre ? « Il est retourné. » |
| Dessin | Mur de gauche, au-dessus du socle | œil + maison, « Un dessin… » |

## Choix à valider [PROPOSITION]

- **Architecture de la pièce** : fenêtre au fond, porte vers le sas à gauche. Comme le prévoit le plan, la porte-fenêtre du jardin et le rideau de la chambre sont ailleurs.
- **Énigme du retour** : une seule bobine utile (la seconde sert à découvrir la poussée) ; planche à repasser et planche de bois comme rampes.
- **Accès au plateau** : carnet à pousser (touche E) plutôt qu'une poussée physique.
- **Installation** : assistance de la tête d'impression ; les jambes s'installent repliées.
- **Vision focalisée** : touche clic droit ou Maj, vue subjective, NINO immobile pendant l'observation, repère discret sur la poignée.
- **Porte** : poignée à levier abaissée par le poids de NINO ; la porte s'ouvre vers le sas.
- **Contenu des photos et du cadre** : neutre et provisoire (paysage, fleurs ; cadre retourné jamais révélé).
- **Textes des pensées** : très courts, en français, à relire (« D'où vient l'énergie ? », « Elle fabrique… », « Pour moi ? », « Je peux l'atteindre ? »).
- **Hauteur de saut** : inchangée (1 unité = 10 cm) ; le parcours n'exige aucun saut de plus de 0,7 unité.

## Ce qui reste provisoire

- Modèle de NINO (non validé artistiquement) et décor générés dans Godot.
- Sons synthétisés : à remplacer par un vrai sound design.
- L'ours en peluche est fait de sphères ; la vue extérieure et le sas sont de simples décors.
- Pictogrammes des pensées dessinés en vectoriel simple ; ils pourront être redessinés.

## Tests

### Automatiques (sans affichage, Godot 4.3 et 4.7)

```
godot --headless --fixed-fps 60 --path . res://tests/test_demo_flow.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_lot1_movement.tscn
```

- `test_demo_flow` (70 vérifications) couvre :
  - le réveil, les pensées, le tutoriel (chaque étape exige l'action, et tourner ne valide pas « avancer ») ;
  - les découvertes, les passages du sol, la visibilité de NINO sous le fauteuil ;
  - l'imprimante hors tension, le câble, la multiprise et le lien compris par NINO ;
  - **le retour réel sur roues** (planche à repasser, bobine poussée dans l'encoche, planche, table) ;
  - la compréhension de l'imprimante, l'impression et sa progression ;
  - **le carnet renversé et la montée réelle sur le plateau**, l'installation et la sauvegarde ;
  - les refus de transformation, l'immobilité, l'absence de téléportation, la réaction aux premiers pas, le saut et la vitesse ;
  - **la montée réelle jusqu'au rebord par sauts**, la vision focalisée sur la poignée ;
  - **le parcours réel sur l'étagère**, l'ouverture de la porte et l'écran de fin ;
  - « Continuer » (jambes, bobine et carnet en place, découvertes conservées), « Nouvelle partie » (tout réinitialisé), la réinitialisation d'une bobine tombée et la touche R.
- `test_lot1_movement` (18 vérifications) couvre les roues, l'escalade et les nouveautés d'escalade : contourner un angle, s'accrocher en quittant le bord d'un carton, redescendre.
- Sans affichage, la souris ne peut pas être capturée : pour l'étape « caméra » du tutoriel, le test fait tourner la caméra comme le ferait la souris.

### Manuels, à faire sur PC

1. **Sensations** : roues inchangées, poussée de la bobine, montée de la planche à repasser et du carnet en roues, précision des sauts sur l'étagère.
2. **Lisibilité** : taille et durée des bulles de pensée, compréhension des pictogrammes, indications du tutoriel.
3. **Vision focalisée** : confort du zoom et de la sensibilité, repérage de la poignée depuis le rebord.
4. **Caméra** : sous la table, sous le fauteuil, dans le tube, le long de l'étagère, pendant l'installation et l'ouverture de la porte.
5. **Son** : volume relatif des nouveaux effets (multiprise, bobine, carnet, installation, porte).
6. **Blocages** : essayer de faire tomber la bobine, de tomber dans l'encoche, de chuter de l'étagère, puis utiliser R.
7. **Sauvegarde** : obtenir les jambes, quitter, relancer et « Continuer » ; puis « Recommencer la démo » depuis la pause.

## Limites connues

- Les captures de contrôle ont été faites avec un rendu logiciel. Le rendu réel sur carte graphique, la prise en main et les sons restent à vérifier sur PC.
- Pendant la vision focalisée, NINO est immobile et masqué (vue subjective).
- Les bulles de pensée suivent la tête de NINO à l'écran et peuvent être partiellement cachées près des bords.
- L'escalade reste simple (surfaces planes) ; les transitions d'angle et la descente fonctionnent sur des blocs rectangulaires.
- Si NINO tombe dans l'encoche avant d'y avoir poussé la bobine, il peut en ressortir par le côté ouvert (chute sans dégât) ou utiliser R.
- **Godot 4.7** ouvre le projet sans erreur mais génère des fichiers `.uid` à côté des scripts. Ils ne sont pas versionnés ici : il est possible de les ajouter au dépôt ou de les ignorer, cela ne change rien au fonctionnement.
- Message sans gravité en mode headless : `Parameter "m" is null` apparaît uniquement avec le pilote graphique factice.
