# Systèmes préparés (lot 3) — données et principes, non développés

Ce document décrit ce qui est **préparé** dans les données ou l'architecture, sans être jouable dans la démo. Rien ici n'est annoncé comme terminé. Il ne remplace pas le GDD (`docs/GDD.md`), qui reste la référence.

## Améliorations : trois catégories

Chaque amélioration est une ressource `UpgradeData` (`scripts/upgrades/upgrade_data.gd`), fabriquée **uniquement à l'imprimante** du placard-hub. La liste des améliorations proposées est `UpgradeCatalog.PATHS`.

| Catégorie | Rôle | Dans la démo |
|---|---|---|
| `MAJOR` (majeures) | Grandes capacités d'exploration, permanentes : jambes, micro-réservoir / pulvérisateur… | Jambes (imprimées et installées, logique du lot 2) |
| `MODULE` (modules secondaires) | Équipables dans un emplacement, échangeables hors combat | Aucun |
| `EVOLUTION` (évolutions) | Renforcent un élément existant ; un niveau II **remplace** le niveau I (`replaces`) | **Renfort de châssis I** (facultatif) |

Champs : `id`, `title`, `description`, `category`, `family`, `tier`, `replaces`, `cost_fragments`, `required_discovery` (plan à trouver), `max_integrity_bonus` (seul effet appliqué aujourd'hui).

### Renfort de châssis I (jouable)

- Plan : « Plan roulé », caché au fond du tube en carton (découverte `plan_chassis`).
- Coût : 4 fragments de filament. Disponible **après la première réparation** (la machine répare avant de renforcer).
- Effet : +25 d'intégrité maximale (100 → 125), permanent, sauvegardé. Non obligatoire pour finir la démo.

### Modules secondaires (préparé, non développé)

- Cinq familles prévues : défense active, attaque, ailes / planage, défense passive, super saut.
- 2 emplacements au départ (`GameState.module_slots = 2`), un 3ᵉ plus tard.
- Échange libre hors combat, **sans retour obligatoire à l'imprimante** ; fabrication uniquement à l'imprimante.
- Le **bouclier** de Nin0 (lot 3) est une capacité de base, distincte du futur module « défense active ».

### Micro-réservoir / pulvérisateur (capacité documentée uniquement)

Amélioration majeure future : stocker un peu de liquide et le projeter (ex. interagir avec certains mécanismes ou créatures). Aucune simulation de fluide n'est prévue ni développée.

## Archives fragmentées (souvenirs)

- Paramètres communs : `assets/memories/archive.tres` (`MemoryArchive` : total = 7, dégradation avec 1 fragment puis avec 7).
- Un souvenir = une ressource `MemoryData` (`id`, `slot`, `title` neutre, `lines`) + une `FocusTarget` dans le niveau qui la référence (`memory`).
- Seul le **fragment 01** (le dessin du placard) existe. Les six autres ne sont pas inventés : il suffira d'ajouter des `MemoryData` et des cibles, sans code.
- Dégradation indépendante de l'ordre : elle dépend du **nombre** de fragments retrouvés.
- Fins : seule la donnée existe — `GameState.archive_state()` renvoie `&"complete"` (7/7) ou `&"incomplete"`. Aucune fin n'est développée, aucun contenu narratif n'est décidé.
- Le texte du fragment 01 reprend les exemples de ton fournis (« Bzzzt… », « …demain… »…) : **provisoire, à valider**.

## Observation (vision focalisée)

Règle unique pour toutes les observations : `ObservationProfile` (`max_distance`, `lock_time`, `min_aim_degrees`, `aim_scale`, `max_view_angle`, `require_line_of_sight`). Profils fournis : `landmark.tres` (repères lointains, ex. poignée) et `memory_detail.tres` (souvenirs : proche, angle, visée longue). Les futures cibles réutilisent ces profils.

## Intégrité, bouclier, fragments

Valeurs de départ (à équilibrer plus tard) : intégrité 100, bouclier 20 (recharge 8/s après 4 s sans dégâts), seuil de dégâts de chute à 18 u/s d'impact (une chute depuis la table n'entame que le bouclier), chute scriptée de la porte : 45 directs. À 0 : mise en veille et redémarrage au dernier point sûr avec 40 % (pas de mort). Réparation : 3 fragments ; 8 fragments dans la pièce, dont 3 sur le chemin de retour après la chute.

## Hors périmètre (connu, non construit)

Bestiaire (référence dans le GDD §6.1), combats, contenu des autres pièces, fins du jeu. Les pièces existent désormais en **blockout** (lot 4, `docs/APPARTEMENT.md`), vides et explorables uniquement en mode développement ; dans la démo, le sas reste un décor bloqué.

## Musique

Autoload `Music` (bus « Music », distinct des effets « Sfx ») : `play_once` (introduction, une fois par lancement), `play` / `stop` avec fondu, table `ZONE_TRACKS` à compléter pour des musiques par zone. Le morceau d'introduction est un prototype interne (droits commerciaux non régularisés).
