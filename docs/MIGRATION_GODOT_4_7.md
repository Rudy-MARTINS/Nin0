# Migration vers Godot 4.7

Depuis cette migration, **Godot 4.7 (stable, version standard) est la seule version officielle** de développement de Nin0. Il n'existe qu'un projet, contenant tout le travail des lots 1, 2 et 3. Aucune fonctionnalité n'a été retirée, reconstruite ou ajoutée.

## Ce qui a changé

| Élément | Modification |
|---|---|
| `project.godot` | `config/features` passe de `4.3` à `4.7`. Réglage `animation/compatibility/default_parent_skeleton_in_mesh_instance_3d=true`, ajouté par Godot 4.7 aux projets migrés (sans effet ici : aucun squelette). Retrait d'une valeur égale au défaut (`use_nearest_mipmap_filter=false`). |
| Fichiers `.uid` | 60 fichiers `.uid` générés par Godot 4.7 à côté des scripts et shaders. **Ils sont versionnés** et ne doivent pas être supprimés ni ignorés. |
| Scènes et ressources (`.tscn`, `.tres`) | Chaque fichier reçoit un identifiant `uid://` dans son en-tête, et chaque `ext_resource` référence sa cible par `uid` **en plus** du chemin (137 références). Le reste du contenu est inchangé, ligne pour ligne. |
| Textures (`.png.import`) | Paramètres d'import complétés par Godot 4.7 (valeurs par défaut ; les identifiants et réglages existants sont conservés). |
| Code | Aucune adaptation d'API nécessaire. Seule correction : l'interface de jeu ne se réaffichait pas après « Continuer » (défaut antérieur à la migration, découvert pendant l'audit). |
| Tests | Fichier de sauvegarde dédié aux tests (la sauvegarde du joueur n'est plus jamais touchée), vérification de l'interface à la reprise, relecture d'une vraie sauvegarde du lot 3 écrite sous 4.3. |

## Méthode, et ce qui a été écarté

- Import complet sous 4.7 à partir de zéro (dossier `.godot/` régénéré) : aucune erreur, aucun avertissement.
- Le réenregistrement automatique de toutes les scènes par l'éditeur 4.7 sans affichage a été **essayé puis rejeté** : il supprimait des données (par exemple le texte du souvenir 1) et ajoutait des paramètres de shader vides, faute de rendu. Les `uid://` ont donc été ajoutés directement dans le texte des fichiers, sans rien modifier d'autre.
- Vérifications : chaque `uid://` se résout vers le bon fichier (137/137), suites de tests complètes sous 4.7.

## Sauvegardes

Le format (`user://nino_demo.cfg`, ConfigFile) ne change pas. Sous 4.7 sont relues : les sauvegardes du lot 2 (jambes et découvertes seulement) et une sauvegarde du lot 3 écrite par la version 4.3 du jeu (porte ouverte, blessure, souvenir, fragments). Le dossier des données utilisateur reste le même (nom du projet « Nin0 ») : une partie en cours se poursuit après la mise à jour.

## Règles pour la suite

- Ouvrir et enregistrer le projet uniquement avec Godot 4.7.
- Versionner les `.uid` avec les fichiers qu'ils accompagnent ; déplacer ou renommer les fichiers depuis l'éditeur Godot (les références `uid://` suivent).
- Ne pas versionner `.godot/` (déjà ignoré).
