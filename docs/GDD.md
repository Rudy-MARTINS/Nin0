# NINO — Game Design Document

**Version :** 0.1 — 15 octobre 2026  
**Statut :** document de conception initial, évolutif  
**Moteur envisagé :** Godot 4 (3D)  
**Outils :** VS Code, Codex, Git, GitHub  
**Cible initiale :** PC Windows

> **Convention :** [VALIDÉ] = décidé ensemble ; [PROPOSITION] = hypothèse à tester ; [À DÉFINIR] = décision ouverte. Ne pas transformer les propositions en exigences sans validation.

## 1. Vision du jeu [VALIDÉ]

Jeu d'exploration, de plateformes et de combats en 3D. Le joueur incarne **Nino**, un minuscule robot éducatif intelligent d'environ **5 cm**, dans un appartement abandonné où la nature a repris ses droits. L'environnement est devenu un écosystème d'insectes qui évoluent et s'affrontent indépendamment du joueur.

Le jeu repose sur trois piliers :
- **Échelle miniature :** objets domestiques ordinaires transformés en reliefs, obstacles et chemins.
- **Progression physique :** Nino imprime des améliorations pour modifier son corps et accéder à de nouvelles zones.
- **Monde vivant :** les insectes ont leurs propres comportements et peuvent devenir hostiles selon les événements.

Le récit est principalement environnemental, avec une révélation majeure à la fin.

## 2. Nino : personnage et identité [VALIDÉ]

- Robot éducatif intelligent, pensé comme un cadeau pour un enfant.
- Taille : environ **5 cm**.
- Design retenu : **hybride**, à la fois mignon et artisanal/mécanique ; yeux numériques expressifs, coque claire, pièces et articulations visibles, caractère de prototype unique.
- Le personnage **n'est pas stupide** : sa vocation éducative explique son format, pas une absence d'intelligence.
- Le nom **NINO** fait écho à *niño* (« enfant » en espagnol, avec un ñ).
- Le corps évolue visuellement lorsque de nouveaux modules sont installés.

**Référence visuelle :** concept hybride choisi dans les échanges. Le modèle 3D final reste à fabriquer ; le concept n'est pas encore une spécification géométrique.

## 3. Déplacements et transformation [VALIDÉ]

### Au début du jeu
- **Mode roues :** locomotion rapide pour parcourir les surfaces et fuir.
- **Escalade :** Nino peut grimper sur certaines surfaces adaptées, avec un système de préhension à concevoir.
- **Aucun saut initialement.**

### Première amélioration : deux jambes articulées
- Les jambes sont fabriquées avec l'imprimante 3D.
- Après installation, Nino peut alterner entre **mode roues** (rapide) et **mode jambes** (plateformes, saut, combat et précision).
- Le changement de mode déclenche une **courte animation durant laquelle Nino doit rester immobile**. C'est une contrainte tactique volontaire.
- **Durée de transformation :** [PROPOSITION] environ 0,8 seconde, à tester ; pas une valeur définitive.
- **Deux jambes**, pas quatre.

**À clarifier lors du prototype :** commandes, fonctionnement précis de l'escalade avant les jambes, surfaces escaladables, vulnérabilité pendant la transformation, sensations de contrôle et caméra.

## 4. Imprimante 3D et progression [VALIDÉ]

- **Une seule imprimante 3D pour le périmètre actuel**, située dans l'atelier, visible très tôt.
- Au départ, le joueur ne sait pas encore à quel point elle sera importante.
- Exploration → découverte d'un besoin / plan → récupération éventuelle de ressources → retour à l'imprimante → fabrication d'un module → ouverture de nouvelles possibilités.
- L'imprimante est un **objet physique dans le monde**, pas seulement un menu abstrait.
- Les modules majeurs ouvrent des chemins et font progresser l'aventure ; des améliorations défensives pourront venir plus tard.
- [À DÉFINIR] Économie des matériaux, plans, interface d'impression, installation des modules et contraintes éventuelles.

## 5. Appartement et level design [VALIDÉ]

- Appartement 3D interconnecté, avec zones pouvant jouer le rôle de niveaux sans séparation rigide.
- **Raccourcis organiques façon Dark Souls** : retour surprenant vers un lieu connu, réduction des trajets fastidieux jusqu'à l'imprimante.
- Exemples [PROPOSITIONS] : grilles de ventilation, conduits, tiroirs, câbles, fissures, meubles, espaces sous les plinthes.
- L'échelle réelle du mobilier et des insectes est une référence de conception ; ne pas grossir arbitrairement les insectes sans raison de gameplay.
- La progression est liée aux capacités physiques de Nino et à la découverte de raccourcis.

## 6. Écosystème d'insectes [VALIDÉ]

- Les insectes ne sont pas de simples ennemis statiques : ils se déplacent, réagissent et peuvent interagir ou se combattre entre espèces.
- **Fourmis pacifiques au début.** Elles poursuivent leurs activités et ne s'en prennent pas spontanément à Nino.
- Après la fabrication et l'installation des jambes, un incident **causé involontairement par une action du joueur** endommage leur installation / activité et déclenche leur hostilité.
- La première confrontation est une **fuite**, pas un combat classique.
- Les fourmis peuvent **grimper sur Nino, s'accumuler sur son corps, gêner ses mouvements et finir par l'immobiliser**.
- En s'éloignant, Nino perd progressivement les fourmis accrochées.
- Plus tard, des **outils ou armes défensives** pourront les faire fuir ou se décrocher.
- [PROPOSITION] Hostilité locale à la colonie concernée plutôt qu'à toutes les fourmis du monde.

**À définir :** espèces supplémentaires, relations entre espèces, IA, système de dégâts/réparation, quantité d'insectes affichables et règles de persistance de l'hostilité.

## 7. Début jouable / séquence de référence [PROPOSITION DE STRUCTURE]

1. **Réveil :** Nino démarre dans l'atelier ; découverte des commandes et du mode roues.
2. **Première exploration :** escalade et observation de l'imprimante 3D, sans encore comprendre sa fonction centrale.
3. **Monde vivant :** rencontre d'une colonie de fourmis pacifique ; découverte de comportements autonomes.
4. **Obstacle :** une zone nécessite une nouvelle capacité ; découverte du plan ou des éléments nécessaires aux jambes.
5. **Raccourci :** ouverture d'un passage ramenant près de l'imprimante.
6. **Fabrication :** impression et installation des **deux jambes articulées**.
7. **Nouveau gameplay :** passage roues ↔ jambes avec immobilisation ; premier saut.
8. **Incident :** saut/action du joueur causant involontairement du tort aux fourmis.
9. **Fuite :** les fourmis se ruent sur Nino, le recouvrent et le ralentissent ; le joueur s'éloigne pour s'en débarrasser.

L'ordre et la durée exacts de ces événements seront affinés lors du level design. Une durée initialement envisagée de 10–15 minutes **n'est pas une contrainte ferme**.

## 8. Scénario — SPOILERS / RÉSERVÉ À LA CONCEPTION [VALIDÉ]

> **Ne pas afficher ces révélations au joueur avant la fin.** Toute trace environnementale doit être conçue pour entretenir le mystère sans divulguer la solution.

Un père a entrepris de créer Nino comme **cadeau éducatif pour son enfant**. L'enfant est mort **avant que le robot puisse lui être offert**. Nino est donc un **cadeau jamais offert et un projet inachevé**. Le père, accablé par le deuil et le désespoir, a fini par se suicider. **Le destin du père constitue la révélation finale**, tandis que l'histoire de l'enfant peut être suggérée progressivement sans révéler prématurément l'ensemble.

Le parcours de Nino a un double sens : il fabrique lui-même les améliorations qui achèvent le travail de son créateur. Le suicide n'est pas à traiter comme une conséquence automatique du deuil ; privilégier une écriture nuancée et sobre.

**À définir :** cause du réveil, source d'énergie, chronologie de l'abandon, objectif explicite initial de Nino, nature des indices, lieu et forme de la révélation, conclusion du jeu.

## 9. Direction artistique [VALIDÉ / À AFFINER]

- 3D stylisée et lisible, plutôt que photoréalisme imposé.
- Ambiance d'appartement ordinaire devenu un monde naturel, étrange, beau et dangereux.
- Nino : expressif, mignon et visiblement assemblé à la main ; les nouvelles pièces doivent être visibles.
- [À DÉFINIR] Palette, éclairage, matériaux, animations, sons, interface et niveau de réalisme des insectes.
- Modèles originaux privilégiés, y compris simples et low-poly ; vérifier les licences des éventuelles ressources externes.

## 10. Plan de développement avec Codex [PROPOSITION]

**Principe :** une fonctionnalité à la fois, testée dans Godot avant d'avancer ; commits Git réguliers.

- **Lot 0 — Fondation :** dépôt GitHub, projet Godot 4, arborescence, README, GDD, .gitignore, conventions et procédure de test.
- **Lot 1 — Contrôles :** scène 3D grise, Nino provisoire, caméra, roues, escalade, collisions. **Pas de saut.**
- **Lot 2 — Level design :** atelier et zone attenante, obstacles, raccourci ouvrable.
- **Lot 3 — Fabrication :** imprimante interactive, obtention du module de deux jambes, transformation immobile, saut et mode jambes.
- **Lot 4 — Fourmis :** déplacements pacifiques autonomes, incident, agression collective, accumulation et fuite.
- **Lot 5 — Présentation :** modèle 3D original, animations, retours visuels et sonores, équilibrage.

**Critère de réussite de la première tranche jouable :** Nino peut explorer, revenir à l'imprimante par un raccourci, obtenir ses jambes, changer de mode, déclencher l'incident puis échapper aux fourmis.

## 11. Garde-fous pour Codex

1. Ne pas inventer de décisions de game design non validées.
2. Ne pas révéler les spoilers dans les textes visibles par le joueur.
3. Ne pas implémenter un saut avant le module de jambes.
4. Ne pas rendre les fourmis agressives dès le début.
5. Ne pas créer plusieurs imprimantes dans le périmètre initial.
6. Conserver le switch roues/jambes avec immobilisation et animation.
7. Préférer une architecture modulaire et des tests fréquents ; expliquer comment tester chaque lot dans Godot.
8. Ne pas confondre concept art et modèle 3D directement exploitable.

## 12. Journal des décisions

- Nom du jeu/personnage : **NINO**.
- Taille : **environ 5 cm**.
- Origine : **robot éducatif intelligent**, cadeau jamais offert.
- Design : **hybride mignon / mécanique artisanal**.
- Mobilité initiale : **roues + escalade**, **pas de saut**.
- Premier module : **deux jambes articulées** ; plateformes/combat/saut.
- Transformation : **arrêt obligatoire + courte animation**.
- Progression : **une imprimante**, **raccourcis interconnectés**.
- Fourmis : **pacifiques puis hostiles après un incident involontaire**, accumulation sur le corps et fuite.
- Histoire : **enfant décédé avant le cadeau ; père décédé par suicide ; révélation finale du destin du père**.

---

*Ce document est une base de travail, non un cahier des charges définitif. Toute modification des éléments [VALIDÉ] doit être discutée et reportée dans ce journal.*