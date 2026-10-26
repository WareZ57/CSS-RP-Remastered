# CSS-RP Remastered

Si vous êtes né dans les années 90 et que vous jouiez à Counter-Strike: Source entre 2010 et 2013, vous avez sûrement
connu le « Roleplay CS:S ». J'y ai énormément joué pendant ma jeunesse, des heures durant.

Ceux qui s'en souviennent le savent : il y a eu beaucoup de choses sombres autour de ce mode de jeu, aussi bien IRL
qu'autour du script lui-même. J'ai conservé toutes ces années une copie des fichiers publiés à l'époque par
« Messiah93 » et la team « clan-family » (les pages d'origine sont archivées dans [`docs/archives/2013`](docs/archives/2013)).

En me promenant dans les tréfonds de mon cloud, j'ai retrouvé tous ces fichiers. Ayant du temps à perdre et l'envie
d'un petit retour en enfance, j'ai entièrement nettoyé les scripts que ce bon monsieur Delachambre avait truffés de
backdoors dans tous les sens : la liste juste en dessous vous montre cette belle époque !

Concrètement, tout a été refait à neuf : corrigé, débarrassé de toutes les cochonneries, débogué et amélioré. Je sais
que plus personne ne fait de RP sur Counter-Strike: Source, mais bon, c'est pour le fun : si quelqu'un veut s'amuser,
qu'il se fasse plaisir :)

## Les backdoors de la version de 2013

Trouvées en relisant ligne par ligne le `Roleplay.sp` d'origine (CSS-RP 1.1.1, publié en 2013). Toutes ont été
retirées ou corrigées. Le détail, avec les numéros de ligne et les autres scripts du serveur de l'époque :
[BACKDOORS.md](BACKDOORS.md).

| Backdoor | Ce qu'elle faisait |
|---|---|
| `STEAM_0:1:9857111` codé en dur | annoncé à tout le serveur comme « leader » à chaque connexion |
| `STEAM_0:1:29162242` codé en dur | annoncé comme « administrateur » à chaque connexion |
| `STEAM_0:1:15441843` codé en dur | clefs de deux portes précises de la map (« Bienvenue chez toi ») |
| `STEAM_0:0:34437348` (« Killer_One ») codé en dur | skin Kingpin réservé et annonce publique |
| Métier caché n° 37 | presque toute l'armurerie de la police, attribuable seulement en écrivant dans la base de données |
| Pseudo inséré tel quel dans les requêtes SQL | injection SQL : un pseudo piégé modifiait les requêtes envoyées à la base |
| Distributeur sans contrôle du solde | retrait possible avec une banque vide : solde négatif, argent créé à volonté |

## Le mode

Un serveur roleplay complet pour Counter-Strike: Source, sur la ville d'Oviscity :

- **31 métiers** : l'État en équipe CT (Chef d'état, Agent de la CIA, Agent du FBI, Policier, Gardien) et 8 entreprises
  en équipe T (Mafia, Dealers, Coach, Ebay, Armurerie, Loto, Banque, Hôpital), chacune avec un chef qui embauche et
  renvoie ;
- **économie** : salaire à minuit (horloge du jeu : 1 seconde = 1 minute), argent liquide et banque, RIB et carte bleue,
  ventes entre joueurs, capital des entreprises et impôts ;
- **police** : prison avec peines et cautions, taser, flashball, enquête, perquisition, armurerie selon le grade ;
- **vie de la ville** : sac (armes, drogues, tickets à gratter, kits de crochetage, meubles), vol, crochetage, PNJ
  (armurerie, loto, hôpital, dealer, distributeurs, agence de tourisme), portes à clef selon le métier ;
- **ambiance** : cadre d'informations en haut à droite, chat local (`say_team`), voix de proximité, meurtres absents du
  fil des kills, grenades spéciales (napalm, fumigène qui gèle) ;
- **sauvegarde** : SQLite par défaut, MySQL possible, mêmes tables qu'en 2013.

## Contenu du dépôt

```
cstrike/
├── addons/sourcemod/
│   ├── plugins/               plugins compilés (SourceMod 1.12)
│   ├── scripting/             sources des plugins
│   └── configs/roleplay/      positions par map, messages du chat, panneau !infos, liens
└── cfg/roleplay_server.cfg    réglages de partie indispensables
maps/                          les 4 maps (.bsp.bz2) et la navigation des bots (.nav)
docs/archives/2013/            les pages de 2013 de Messiah93 et de clan-family
```

| Plugin | Rôle |
|---|---|
| `roleplay.smx` | le mode |
| `grenade_effects.smx` | grenade HE au napalm, fumigène qui gèle, traînées de couleur |
| `localtalk.smx` | voix de proximité : on n'entend que les joueurs vivants à moins de 500 unités |
| `message.smx` | cache le message « Un coéquipier attaque ! » |
| `hideprisoner.smx` | cache les meurtres du fil des kills |

## Installation

Prérequis : un serveur dédié Counter-Strike: Source (Linux ou Windows), [Metamod:Source 1.12](https://www.sourcemm.net/downloads.php?branch=stable)
et [SourceMod 1.12](https://www.sourcemod.net/downloads.php?branch=stable). Testé avec SourceMod 1.12.0.7259 et
Metamod:Source 1.12.0-git1228. L'extension [SteamWorks](https://github.com/KyleSanderson/SteamWorks/releases) est
facultative : elle affiche « RolePlay » comme nom du jeu dans la liste des serveurs.

1. **Fichiers** : copier le dossier `cstrike/` du dépôt par-dessus le dossier `cstrike/` du serveur.
2. **Maps** : décompresser les maps et les copier, avec leurs `.nav`, dans `cstrike/maps/` du serveur :
   ```sh
   bunzip2 -k maps/*.bsp.bz2
   cp maps/*.bsp maps/*.nav /chemin/du/serveur/cstrike/maps/
   ```
   Sous Windows, 7-Zip ouvre les `.bz2`.
3. **Base de données** : ajouter cette section dans `cstrike/addons/sourcemod/configs/databases.cfg`, à l'intérieur de
   `"Databases"` ; les tables sont créées au premier démarrage :
   ```
   "roleplay"
   {
       "driver"    "sqlite"
       "database"  "roleplay"
   }
   ```
   Pour MySQL : `"driver" "mysql"`, avec `"host"`, `"database"`, `"user"` et `"pass"`.
4. **Réglages** : ajouter cette ligne à la fin de `cstrike/cfg/server.cfg` :
   ```
   exec roleplay_server.cfg
   ```
5. **Démarrage** : lancer le serveur sur la map de référence, par exemple
   `./srcds_run -game cstrike +map rp_oviscity_frez_v1 +maxplayers 32`.
6. **Téléchargement des maps** : les maps dépassent la limite d'envoi du serveur de jeu ; il faut un FastDL. Déposer les
   `.bsp.bz2` dans un dossier `maps/` d'un serveur web, puis dans `server.cfg` : `sv_downloadurl "http://votre-site/chemin/"`.
7. **Admins** : comme d'habitude avec SourceMod (`configs/admins_simple.ini`). Les commandes d'administration du mode
   demandent le droit root (`z`) ; `sm_ent` demande le droit admin (`b`).

Vérification : `sm plugins list` dans la console du serveur doit lister Roleplay, Grenade Effects, Local-Talk,
Message teammate_attack et Cachekill.

## Commandes en jeu

Dans le chat : `!commande`, ou `/commande` sans que le message s'affiche ; dans la console : `sm_commande`.
« Visé » désigne le joueur ou l'objet que l'on regarde.

| Commande | Qui | Effet |
|---|---|---|
| `sm_rp` | tous | liste des commandes |
| `sm_infos` | tous | panneau d'informations |
| `sm_item` [objet] | tous | ouvrir son sac ; `!item awp` utilise l'objet sans menu |
| `sm_give` montant | tous | donner de l'argent liquide au joueur visé |
| `sm_vendre` [article] | métiers qui vendent | proposer un article au joueur visé ; `!vendre awp` sans menu |
| `sm_accepter` / `sm_refuser` | tous | répondre à une caution, une vente ou une offre d'emploi |
| `sm_demission` [oui] | employés | quitter son métier |
| `sm_lock` / `sm_unlock` | selon le métier | fermer à clef ou ouvrir la porte visée |
| `sm_+force` (`sm_force`) | police et chefs (joueurs) ; tous (objets) | porter ou lâcher l'objet ou le joueur visé |
| `sm_engager` (`sm_recruter`, `sm_recrute`) [joueur métier] | chefs | proposer un métier de l'entreprise à un sans-emploi |
| `sm_virer` (`sm_licencier`, `sm_exclure`) [joueur] | chefs | renvoyer un employé |
| `sm_out` | police, entreprises | expulser le joueur visé de ses locaux |
| `sm_vol` | mafia | voler 1 à 300 $ au joueur visé (toutes les 30 s) |
| `sm_jail` [crime] | police | emprisonner le joueur visé ; peine au menu, ou `!jail vol` |
| `sm_jaillist` | police | prisonniers et temps restant |
| `sm_taser` | police | immobiliser 10 s le joueur visé |
| `sm_enquete` | police | pseudo, SteamID, PV, permis et peine du joueur visé |
| `sm_perquisition` (`sm_perqui`) | police | annoncer une perquisition |
| `sm_del` | police | supprimer l'arme au sol visée |
| `sm_armurerie` (`sm_armu`) [arme] | police | armes gratuites selon le grade ; `!armurerie m4a1` sans menu |
| `sm_civil` | Chef d'état, CIA, FBI | passer en civil ou en service |
| `sm_vis` | Chef d'état, CIA | devenir invisible ou visible |
| `sm_money` [joueur montant] | Chef d'état | verser 1 000 à 1 000 000 $ en banque à un joueur (journalisé) |
| `sm_changename` pseudo | Chef d'état | changer de pseudo (journalisé) |
| `sm_jobmenu` | admin root | donner un métier |
| `sm_ent` | admin | entité visée : numéro, classe, hammerid, nom, modèle, position |
| `sm_rp_set` joueur champ valeur | admin root, console | régler `job`, `cash`, `bank`, `jail`, `rib`, `cb`, `permislourd`, `permisleger` ou un objet ; `sm_rp_set clock 1439` règle l'horloge |
| `sm_rp_save` | admin root | sauvegarder tout le monde tout de suite |
| `sm_rp_capital` [valeur] | admin root | afficher ou régler le capital des entreprises |

Crimes de `!jail` : `meurtrep`, `meurtrec`, `tentative`, `crochetage`, `vol`, `nuisances`, `insultes`, `permis`,
`intrusion`, `tir`, `obstruction`, `evasion`.

**Touche Utiliser (E)** : sur un distributeur (dépôt et retrait, RIB obligatoire), l'armurerie, le loto, l'hôpital, le
dealer, les kits de crochetage de la mafia, l'agence de tourisme (une fois son PNJ configuré, voir « Ajouter une
map ») ; sur une porte non verrouillée pour l'ouvrir.

**Flashball** : l'USP avec silencieux (clic droit) tire des balles en caoutchouc, sans dégât ; la cible est éblouie et
ne peut plus bouger pendant 1,5 s, puis elle a autant de temps libre avant de pouvoir être regelée. Sans silencieux,
l'USP tire de vraies balles.

**Métiers et salaires** : Sans-emploi 50 $. État : Chef d'état 500 $, Agent de la CIA 400 $, Agent du FBI 300 $,
Policier 200 $, Gardien 100 $. Entreprises : chef 500 $, employé 300 $, apprenti 100 $ (Hôpital : Médecin 300 $,
Infirmier et Chirurgien 100 $). Les morts et les prisonniers ne touchent pas leur salaire.

## Réglages

`sm_rp_*` et `sm_grabber_*` sont créés au premier démarrage dans `cstrike/cfg/sourcemod/roleplay.cfg`, `sm_greneffect_*`
dans `cstrike/cfg/sourcemod/grenade_effects.cfg` ; `sm_hidekill` se règle dans `server.cfg`.

| Cvar | Défaut | Rôle |
|---|---|---|
| `sm_rp_block_roundend` | `1` | le round ne se termine jamais (sinon tout le monde réapparaît aux points de CS:S) |
| `sm_rp_gamedesc` | `RolePlay` | nom du jeu dans la liste des serveurs (extension SteamWorks) |
| `sm_rp_name` | vide | nom de la communauté dans le message de bienvenue |
| `sm_rp_flashball` | `1` | l'USP avec silencieux est un flashball |
| `sm_rp_flashball_time` | `1.5` | durée du gel et de l'éblouissement du flashball (secondes) |
| `sm_rp_save_bots` | `0` | tests : les bots ont un profil en base |
| `sm_grabber_speed`, `sm_grabber_distance`, `sm_grabber_sound` | `10`, `80`, son du gravity gun | objet porté avec `!+force` |
| `sm_hidekill` | `1` | meurtres absents du fil des kills |
| `sm_greneffect_*` | | grenades (napalm, gel, traînées), décrites dans `grenade_effects.cfg` |

Textes, dans `cstrike/addons/sourcemod/configs/roleplay/` : `pub.txt` (un message au hasard dans le chat toutes les
90 secondes, couleurs `\x01` normal, `\x03` équipe, `\x04` vert), `infos.txt` (lignes du panneau `!infos`), `liens.txt`
(liens de l'agence de tourisme, une ligne `Titre|URL` par lien).

## Maps fournies

| Map | Taille | Notes |
|---|---|---|
| `rp_oviscity_frez_v1` | 79 Mo (29 Mo compressée) | map de référence, la plus complète |
| `rp_oviscity_gmc5` | 55 Mo (23 Mo) | version de Garry's Mod (DarkRP), même ville |
| `rp_oviscity_b4` | 32 Mo (13 Mo) | version de Garry's Mod plus ancienne : ni FBI ni planque des dealers |
| `rp_oviscity_sp7b` | 56 Mo (22 Mo) | version de Garry's Mod où toute la ville est décalée ; pas de `.nav` pour les bots |

## Ajouter une map

Chaque map a son fichier `cstrike/addons/sourcemod/configs/roleplay/<nom de la map>.cfg`, relu à chaque changement de
map ; sans lui, le mode tourne sans zones, apparitions ni prison. Le plus simple est de partir d'une config fournie.

| Section | Contenu |
|---|---|
| `zones` | boîtes `"xmin ymin zmin xmax ymax zmax"` (plusieurs par zone possibles) : `place`, `comico` (commissariat), `fbi`, `armu`, `hosto`, `dealer`, `mafia`, `loto`, `bank`, `ebay`, `coach`, `jail1` à `jail4` (cellules), `distrib_ebay`, `distrib_loto`, `distrib_mafia`, `distrib_banque` (distributeurs) |
| `apparitions` | points `"x y z"` où les joueurs apparaissent (au hasard) |
| `cellules` | points `"x y z"` où les prisonniers sont envoyés |
| `expulsions` | où `!out` envoie un intrus, par groupe : `etat`, `mafia`, `dealer`, `coach`, `ebay`, `armu`, `loto`, `banque`, `hosto` |
| `armes` | armes posées à chaque round et reposées 10 s après avoir été ramassées : `"arme"` et `"position"` |
| `tourisme` | PNJ de l'agence de tourisme : `"hammerid"` (donné par `!ent` en le visant ; `0` = pas d'agence, le cas des maps fournies) et `"distance"` |
| `apparitions_css` | facultatif : points d'apparition CS:S à créer, pour une map qui n'en a pas |

Les zones décident des clefs : chaque entreprise ouvre les portes de sa zone, le Chef d'état, la CIA et le FBI ouvrent
tout. Pour relever une position, `getpos` dans la console donne celle des yeux : retirer 64 à la hauteur pour celle des
pieds.

## Ce qui manque

Les skins et les sons du serveur de 2013 n'ont pas été conservés (`models/player/pil/re1/wesker/`, `slow/50cent/`… ;
`sound/roleplay_sm/salaire.wav`, `success.wav`, `noteam.wav`). Sans eux, le mode utilise les skins de CS:S et reste
muet ; déposés dans `cstrike/models/` et `cstrike/sound/` du serveur (et sur le FastDL), ils sont utilisés
automatiquement.

## Historique

Toutes les corrections et améliorations par rapport à 2013 : [CHANGELOG.md](CHANGELOG.md).

## Crédits

- **CSS-RP 1.1.1** (2012-2013) : Delachambre ; selon les pages de 2013, avec Sphex.
- **Cachekill** : Delachambre. **Grenade Effects** : FrozDark (HLModders.ru). **Local-Talk** : KoSSoLaX.
- **Maps** : rp_oviscity et ses variantes appartiennent à leurs auteurs respectifs.
- **Remaster** (2026) : Panda.

## Licence

[GNU GPL v3](LICENSE), comme SourceMod ; les pages de 2013 publiaient déjà ces sources sous cette licence. Les maps
restent la propriété de leurs auteurs.
