# Musique — prototypes internes

Tous ces morceaux sont des **prototypes réservés aux essais internes** (générés avec Suno puis retravaillés) : leurs droits d'exploitation commerciale ne sont pas confirmés. Ne pas les distribuer dans une version publique.

| Fichier | Morceau | Utilisation | Boucle |
|---|---|---|---|
| `intro_prototype.ogg` | intro - Nin0 (≈ 1 min 33) | Écran titre, une fois par lancement ; s'efface au début du réveil | non |
| `petit_refuge.ogg` | Petit Refuge (`hub_sas_intro` + `hub_sas_loop`) | Placard-hub et sas | reprise à 3,737 s (après l'intro) |
| `ant_labyrinth.ogg` | ant labyrinth - Nin0 **V3** (`intro_v3` + `loop_v3`) | Salle de bain | reprise à 2,100 s (après l'intro) |
| `boss_fight.ogg` | boss fight - Nin0 **V2**, édité | Combat contre la reine | reprise à 47,984 s |
| `kitchen.ogg` | kitchen - Nin0 (de `kitchen_original.mp3`), édité | Cuisine (lot 6) | reprise à 25,496 s |
| `_reserve/living_room.mp3` | living room - Nin0 | **Hors du jeu** (dossier ignoré par Godot), salon plus tard | — |

## Éditions réalisées (lot 5.1, finitions)

- **Hub et labyrinthe** : l'intro et la boucle fournies séparément sont assemblées dans un seul fichier, sans silence ni fondu ; le point de reprise de la boucle est exactement la fin de l'intro (échantillon près). La boucle n'a pas été modifiée.
- **Reine (V2, 2 min 58)** : le morceau contient une intro et une fin, ce n'est pas une boucle. Analyse : trois sections de 47,03 s dont les attaques tombent à 48,00 s, 95,03 s et 142,06 s. Le fichier est coupé juste avant la troisième attaque (142,04 s) et boucle sur la première (47,98 s) : intro → sections 1 et 2 → retour à la section 1. **La fin du morceau n'est jamais jouée.** Le raccord se fait sur une attaque de section, après la respiration de la section précédente.
- **Cuisine (lot 6)** : le morceau commence par un fondu d'entrée (≈ 1 s, intro plus calme jusqu'à ≈ 9 s) et finit par un fondu de sortie (dès ≈ 84 s) : bouclé tel quel, il laissait un trou. Analyse (similarité spectrale sur 6 s autour des points, puis alignement des attaques rythmiques) : le passage qui précède 76,02 s est équivalent à celui qui précède 25,50 s (même niveau, −33 dB ; attaques alignées). Le fichier est coupé à 76,022 s, ses 0,35 dernières secondes sont fondues (puissance constante) vers la musique qui précède la reprise, et la boucle reprend à l'échantillon 1 124 374 (25,496 s) : intro → corps du morceau → boucle de 50,5 s. **Raccord à confirmer à l'écoute par le créateur.**
- Volumes équilibrés d'après la sonie mesurée (EBU R128) : hub −22,8 LUFS, labyrinthe −21,4, reine −21,7, cuisine −29,0 ; les gains de `scripts/core/music.gd` ramènent les pistes de zone à un niveau proche.
- Fichiers d'origine non versionnés (seules les versions éditées le sont) : ils restent dans le pack fourni par le créateur.
