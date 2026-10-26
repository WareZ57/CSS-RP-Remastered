# Historique des versions

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Sauf mention contraire, les règles, prix,
salaires, peines, cautions et messages sont ceux de la version de 2013.

## [2.0.0] - 2026-10-26

Remaster complet de CSS-RP 1.1.1 (2013), réécrit pour SourceMod 1.12.

### Sécurité

- Retiré : les 4 SteamID privilégiés codés en dur et le métier caché n° 37 (voir [BACKDOORS.md](BACKDOORS.md)) ; un
  métier inconnu trouvé en base redevient Sans-emploi et c'est noté dans les logs.
- Requêtes SQL échappées et asynchrones : plus d'injection SQL par le pseudo, plus de blocage du serveur à chaque
  sauvegarde.
- Distributeur : impossible de retirer plus que son solde (la banque pouvait passer en négatif).
- Prison : peine provisoire de 60 s dès `/jail`, sauvegardée en base, remplacée par celle du crime choisi ; se
  déconnecter pendant que le policier choisit la peine ne fait plus sortir de prison.
- Prisonniers : plus de chat (même en commençant le message par `!`), plus de commande de métier ; impossible de les
  expulser (`/out`) ou de les porter (`/+force`) hors de leur cellule.
- Un mute d'admin (`sm_mute`) n'est plus annulé par la prison ou par la réapparition.
- Menu d'achat de CS:S (touche B) fermé : il vendait des armes pendant 90 s après chaque démarrage de map, sans
  passer par les PNJ.
- Propositions (vente, métier, caution) : le « Oui » ne vaut que pour la proposition affichée, une proposition n'est
  acceptée que 1,5 s après son arrivée et un autre joueur ne peut pas la remplacer pendant 30 s (avant, une vente
  pouvait être remplacée par une plus chère juste avant l'appui sur « Oui »).
- Menus de banque, de PNJ et de vente revérifiés au moment du choix : vivant, libre, toujours à portée.
- Portées : 150 unités pour `/lock`, `/unlock`, `/+force` et les kits de la mafia, 300 pour `/vendre` (avant :
  illimitées, `/+force` attrapait un joueur à l'autre bout de la map) ; un objet porté coincé derrière un mur est lâché.
- Meubles : 5 par joueur et 50 en tout, retirés quand leur propriétaire se déconnecte.
- Soins plafonnés à la vie maximale, chirurgie plafonnée à 500 PV, `/civil` ne soigne plus.
- Banque plafonnée à 2 milliards (débordement d'entier possible avec `/money`).
- `/changename` : ni caractères de contrôle ni pseudo d'un autre joueur présent, et chaque changement est journalisé,
  comme chaque versement de `/money`.
- Un `%` dans un pseudo ne casse plus les titres de menus.
- `sm_ent` réservé aux admins (droit `b`).

### Corrigé

- L'argent liquide n'était pas relu avant les achats (montants désynchronisés).
- La base de données était fermée au premier changement de map ; le ticket à 1 000 $ n'était jamais sauvegardé.
- Un menu « Non » fermé deux fois faisait planter le plugin.
- `/give` sur une entité qui n'est pas un joueur faisait disparaître l'argent.
- Le HUD pouvait bloquer tous les messages du serveur (message réseau jamais terminé pour un joueur parti).
- Les succès des 50 et 100 portes crochetées ne se déclenchaient jamais.
- Le XM1014 coûtait 800 $ mais en débitait 500.
- Le canapé et la table d'Ebay donnaient un USP et ne faisaient rien : ils posent maintenant un meuble.
- Le soin payé par carte bleue débitait l'argent liquide.
- `/changename` écrivait un nombre à la place du pseudo.
- Un prisonnier restait coincé en cellule si le policier fermait le menu des peines.
- Les scores n'étaient jamais remis à zéro (CS:S compte le kill après l'événement).
- Argent des kills : CS:S plafonne l'argent du tueur à 16 000 $, un joueur riche perdait donc de l'argent à chaque
  meurtre ; sous 300 $, un policier en gagnait. L'argent du tueur est maintenant rendu tel quel.
- Le round se terminait (temps écoulé, équipe éliminée, « Game Commencing » quand une équipe vide recevait son premier
  joueur) et tout le monde réapparaissait aux points de CS:S.
- Les positions de 2013 avaient été relevées à hauteur des yeux : on tombait de 64 unités en apparaissant. La 4e cellule
  était une copie de la 1re et la zone de la cellule 3 avait une largeur nulle.
- Cachekill ne cachait aucun meurtre.
- Grenade Effects : la durée du napalm ne suivait pas sa cvar ; erreurs quand le monde blesse un joueur ou quand le
  lanceur d'un fumigène s'est déconnecté.

### Ajouté

- Portage complet en syntaxe SourceMod 1.12, code découpé en modules (métiers, prison, portes, sac, commerces, police,
  administration, base de données, map) ; métiers, prix et peines rangés en tables.
- Positions propres à chaque map dans `configs/roleplay/<map>.cfg` (en 2013, elles étaient écrites dans le code) ; 4
  maps fournies avec leur config.
- Points d'apparition CS:S créés au chargement des maps de Garry's Mod, qui n'en ont pas.
- Flashball : l'USP avec silencieux tire des balles en caoutchouc (comme sur le serveur de 2013, dont ce code n'avait
  pas été conservé).
- Raccourcis sans menu : `!item awp`, `!vendre awp`, `!jail vol`, `!engager joueur métier`, `!virer joueur`,
  `!armurerie m4a1`, `!money joueur montant`, `!demission oui`, et `!accepter` / `!refuser` pour répondre.
- Commandes d'administration `sm_rp_set`, `sm_rp_save` et `sm_rp_capital`.
- Nom du jeu « RolePlay » dans la liste des serveurs (extension SteamWorks, facultative).
- SQLite ou MySQL ; sauvegarde à la déconnexion, au changement de map et toutes les 5 minutes.
- Messages du chat, panneau `!infos` et liens de l'agence de tourisme dans des fichiers texte.
- Réglages `sm_rp_*` (fin de round, nom du jeu, nom de la communauté, flashball).
- Compilation automatique des plugins à chaque modification (GitHub Actions).

### Modifié

- Ventes entre joueurs : le vendeur touche la moitié du prix (en 2013, le prix entier pour 28 articles sur 38, ce qui
  permettait à deux complices de créer de l'argent).
- Le round ne se termine et ne redémarre jamais ; un admin peut toujours le relancer avec `mp_restartgame 1`.
- Cachekill cache vraiment les meurtres du fil des kills (`sm_hidekill 0` pour les montrer).

### Retiré

- La publicité « codé par Delachambre » diffusée dans le chat.
