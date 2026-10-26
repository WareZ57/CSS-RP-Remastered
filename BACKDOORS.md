# Backdoors et pièges de la version de 2013

Ce qui a été trouvé en relisant ligne par ligne les scripts du serveur roleplay de 2013. Les numéros de ligne renvoient
au `Roleplay.sp` d'origine (CSS-RP 1.1.1, 13 815 lignes), celui que Messiah93 et clan-family ont publié en 2013
([pages archivées](docs/archives/2013)). Tout ce qui suit a été retiré ou corrigé dans CSS-RP Remastered.

## 1. Backdoors et privilèges cachés (`Roleplay.sp`)

| Ligne(s) | Code d'origine | Effet |
|---|---|---|
| 981 | `STEAM_0:1:9857111` | à sa connexion, tout le serveur lit « Le leader … viens de se connecter » |
| 985 | `STEAM_0:1:29162242` | à sa connexion, tout le serveur lit « L'administrateur … » |
| 2222, 2621 | `STEAM_0:1:15441843` | a les clefs des portes n° 1275 et 1276 de la map (« Bienvenue chez toi ») |
| 12985, 12997 | `STEAM_0:0:34437348` (« Killer_One ») | reçoit le skin Kingpin et une annonce publique |
| 13063 | métier n° 37 | métier absent de tous les menus, qui donne presque toute l'armurerie de la police ; on ne l'obtient qu'en écrivant son numéro dans la base de données |
| 2218, 5315 | portes 1275 et 1276, PNJ 1317 | désignés par leur numéro d'entité, qui change avec la map et le nombre de slots |

Dans le remaster, aucun SteamID n'est écrit dans le code, le métier 37 n'existe plus (un métier inconnu trouvé en base
redevient Sans-emploi, et c'est noté dans les logs) et le PNJ de l'agence de tourisme est désigné par son hammerid dans
la config de la map.

## 2. Failles et bugs graves (`Roleplay.sp`)

| Ligne(s) | Faille | Correction |
|---|---|---|
| 1752, 1816, 1936 | pseudo du joueur inséré tel quel dans les requêtes SQL : **injection SQL** avec un pseudo piégé | requêtes échappées et asynchrones |
| 2143 | retrait au distributeur sans vérifier le solde : banque négative, argent créé à volonté | retrait limité au solde et à 65 535 $ sur soi |
| 3626 | `/give` sur une entité qui n'est pas un joueur : l'argent disparaît, avec une erreur du plugin | il faut viser un joueur vivant |
| 3000 | HUD : message réseau démarré pour un joueur parti et jamais terminé, qui bloque tous les messages suivants | corrigé |
| | requêtes SQL bloquantes pendant la partie, base fermée au premier changement de map, ticket à 1 000 $ jamais sauvegardé | base asynchrone, tout est sauvegardé |
| | un prisonnier restait coincé en cellule si le policier fermait le menu des peines | peine provisoire de 60 s dès `/jail` |
| | le vendeur touchait 100 % du prix pour 28 articles sur 38 : deux complices s'échangeaient les armes gratuitement et un ticket à 10 $ revendu en boucle rapportait de l'argent | le vendeur touche la moitié du prix |
| | meubles d'Ebay sans limite : un sac plein suffisait à saturer les entités du serveur | 5 par joueur, 50 en tout |
| | `/civil` rendait tous les PV à chaque passage en service ; les soins dépassaient la vie maximale ; les chirurgies s'empilaient sans fin | ni soin en changeant de tenue, ni dépassement, chirurgie plafonnée à 500 PV |
| | un tueur avec plus de 16 000 $ perdait de l'argent à chaque meurtre (CS:S plafonne l'argent quand il compte un kill) | l'argent du tueur est rendu tel quel |

D'autres abus possibles dans la logique de 2013 ont été fermés pendant le remaster ; ils sont listés dans
[CHANGELOG.md](CHANGELOG.md), section « Sécurité ».

## 3. Protections d'origine, conservées

- les commandes `kill` et `explode` (suicide) sont bloquées, et `jointeam` aussi : l'équipe dépend du métier ;
- les entités `point_servercommand` des maps sont supprimées (elles permettent à une map d'envoyer des commandes au
  serveur ; `rp_oviscity_frez_v1` et `rp_oviscity_gmc5` en contiennent une, « gdmde », que rien ne déclenche).

## 4. Le reste du serveur de 2013

Le dossier du serveur contenait aussi des scripts d'autres auteurs, jamais installés en même temps que le mode et absents
de ce dépôt. Pour mémoire :

- **`ARGENT/SQL.sp`**, un autre mode roleplay inachevé (de Natalya) :
  - ligne 1667 (et `policier commands.sp:176`) : `ServerCommand("sm_hp \"%s\" 100", nom)` avec le pseudo du joueur
    menotté, donc **un pseudo piégé exécute des commandes sur le serveur** ;
  - ligne 284 : tue tous les joueurs au chargement du plugin ;
  - ligne 829 : `=` au lieu de `==` dans une boucle, **serveur gelé** quand le fichier d'apparitions manque ;
  - ligne 6265 : affiche le SteamID de chaque joueur à tout le serveur à chaque sauvegarde ; ligne 1857 : `sm_ent`
    ouvert à tous ; ligne 2050 : test admin inversé ; ligne 3685 : équipe VIP accessible à tous.
- **`gamedesc/st_gamedesc_override.sp`** (lignes 9, 45, 62) : **télécharge du code en HTTP** puis se recharge tout seul ;
  la cvar censée l'empêcher est mal orthographiée (`st_gamedesc_override_auto_upadte`), donc sans effet.
- **`jail/jail.sp`** (ligne 59) : téléporte le gardien en prison au lieu du prisonnier.
- **`sm_weapons.sp`** : armes gratuites pour tout le monde.
