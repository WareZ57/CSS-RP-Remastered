#define JOB_COUNT 31

enum
{
	GROUP_NONE,
	GROUP_ETAT,
	GROUP_MAFIA,
	GROUP_DEALER,
	GROUP_COACH,
	GROUP_EBAY,
	GROUP_ARMU,
	GROUP_LOTO,
	GROUP_BANQUE,
	GROUP_HOSTO,
	GROUP_COUNT
}

char JOB_NAME[JOB_COUNT][] =
{
	"Sans-Emploi", "Chef d'état", "Agent CIA", "Agent du FBI", "Policier", "Gardien",
	"Chef Mafia", "Mafieux", "Apprenti Mafieux",
	"Chef Dealer", "Dealer", "Apprenti Dealer",
	"Chef Coach", "Coach", "Apprenti Coach",
	"Chef Ebay", "Vendeur Ebay", "Apprenti Vendeur Ebay",
	"Chef Armurie", "Armurier", "Apprenti Armurier",
	"Chef Loto", "Vendeur de Tickets", "Apprenti Vendeur de Tickets",
	"Chef Banquier", "Banquier", "Apprenti Banquier",
	"Chef Hôpital", "Médecin", "Infirmier", "Chirurgien"
};

char JOB_TAG[JOB_COUNT][] =
{
	"Sans emploi -", "C. Police -", "Agent CIA -", "Agent du FBI -", "Policier -", "Gardien -",
	"C. Mafia -", "Mafieux -", "A. Mafieux -",
	"C. Dealer -", "Dealer -", "A. Dealer -",
	"C. Coach -", "Coach -", "A. Coach -",
	"C. Ebay -", "V. Ebay -", "A.V. Ebay -",
	"C. Armurie -", "Armurier -", "A. Armurier -",
	"C. Loto -", "V. de Ticket -", "A.V. de Ticket -",
	"C. Banquier -", "Banquier -", "A. Banquier -",
	"C. Hôpital -", "Médecin -", "Infirmier -", "Chirurgien -"
};

int JOB_GROUP[JOB_COUNT] =
{
	GROUP_NONE, GROUP_ETAT, GROUP_ETAT, GROUP_ETAT, GROUP_ETAT, GROUP_ETAT,
	GROUP_MAFIA, GROUP_MAFIA, GROUP_MAFIA,
	GROUP_DEALER, GROUP_DEALER, GROUP_DEALER,
	GROUP_COACH, GROUP_COACH, GROUP_COACH,
	GROUP_EBAY, GROUP_EBAY, GROUP_EBAY,
	GROUP_ARMU, GROUP_ARMU, GROUP_ARMU,
	GROUP_LOTO, GROUP_LOTO, GROUP_LOTO,
	GROUP_BANQUE, GROUP_BANQUE, GROUP_BANQUE,
	GROUP_HOSTO, GROUP_HOSTO, GROUP_HOSTO, GROUP_HOSTO
};

int JOB_HEALTH[JOB_COUNT] =
{
	100, 500, 400, 300, 200, 150,
	100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
	100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100
};

int JOB_SALARY[JOB_COUNT] =
{
	50, 500, 400, 300, 200, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100,
	500, 300, 100, 100
};

char JOB_MODEL[6][] =
{
	"",
	"models/player/pil/re1/wesker/wesker_pil.mdl",
	"models/player/rocknrolla/ct_urban.mdl",
	"models/player/ics/ct_gign_fbi/ct_gign.mdl",
	"models/player/natalya/police/chp_male_jacket.mdl",
	"models/player/elis/po/police.mdl"
};

char T_MODELS[3][] =
{
	"models/player/slow/vin_diesel/slow.mdl",
	"models/player/slow/niko_bellic/slow.mdl",
	"models/player/slow/50cent/slow.mdl"
};

#define MODEL_DEFAULT_CT	"models/player/ct_gign.mdl"
#define MODEL_DEFAULT_T		"models/player/t_guerilla.mdl"

char GROUP_COMPANY[GROUP_COUNT][] =
{
	"Aucune", "Etat d'oviscity", "Mafia d'oviscity", "Dealer d'oviscity", "Coach d'oviscity",
	"Ebay d'oviscity", "Armurie d'oviscity", "Loto d'oviscity", "Banque d'oviscity", "Hôpital d'oviscity"
};

char GROUP_KEY[GROUP_COUNT][] =
{
	"", "etat", "mafia", "dealer", "coach", "ebay", "armu", "loto", "banque", "hosto"
};

#define CRIME_COUNT 12

char CRIME_KEY[CRIME_COUNT][] =
{
	"meurtrep", "meurtrec", "tentative", "crochetage", "vol", "nuisances",
	"insultes", "permis", "intrusion", "tir", "obstruction", "evasion"
};

char CRIME_LABEL[CRIME_COUNT][] =
{
	"Meurtre sur Policier.", "Meurtre sur Civil.", "Tentative de Meurtre.", "Crochetage.", "Vol.",
	"Nuisances sonores", "Insultes.", "Possession d'armes illégales.", "Intrusion.", "Tir dans la rue.",
	"Obstruction envers les forces de l'ordres", "Tentative d'évasion"
};

char CRIME_REASON[CRIME_COUNT][] =
{
	"meurtre sur policier", "meurtre sur civil", "tentative de meurtre", "crochetage", "vol",
	"nuisances sonores", "insultes", "possession d'armes illégales", "intrusion", "tir dans la rue",
	"obstruction envers la police", "tentative d'évasion"
};

int CRIME_TIME[CRIME_COUNT] =		{ 480, 360, 300, 180, 180, 240, 240, 300, 180, 180, 120, 200 };
int CRIME_CAUTION[CRIME_COUNT] =	{ 1000, 800, 500, 200, 200, 500, 600, 600, 200, 250, 250, 400 };
int CRIME_REDUCED[CRIME_COUNT] =	{ 240, 180, 150, 90, 90, 120, 120, 150, 90, 90, 60, 100 };

#define JAIL_LIBERATION_TIME 10
#define JAIL_PENDING_TIME 60

enum
{
	ITEM_KIT, ITEM_AK47, ITEM_AWP, ITEM_M249, ITEM_SCOUT, ITEM_SG550, ITEM_SG552, ITEM_UMP, ITEM_TMP,
	ITEM_MP5, ITEM_DEAGLE, ITEM_USP, ITEM_GLOCK, ITEM_XM1014, ITEM_M3, ITEM_M4A1, ITEM_AUG, ITEM_GALIL,
	ITEM_MAC10, ITEM_FAMAS, ITEM_P90, ITEM_ELITE, ITEM_TICKET10, ITEM_TICKET100, ITEM_TICKET1000,
	ITEM_LEVELCUT, ITEM_CARTOUCHE, ITEM_PROPS1, ITEM_PROPS2, ITEM_HEROINE, ITEM_EXTA, ITEM_LSD, ITEM_COKE,
	ITEM_COUNT
}

char ITEM_COLUMN[ITEM_COUNT][] =
{
	"kitcrochetage", "ak47", "awp", "m249", "scout", "sg550", "sg552", "ump", "tmp", "mp5", "deagle", "usp",
	"glock", "xm1014", "m3", "m4a1", "aug", "galil", "mac10", "famas", "p90", "elite", "ticket10",
	"ticket100", "ticket1000", "levelcut", "cartouche", "props1", "props2", "heroine", "exta", "lsd", "coke"
};

char ITEM_LABEL[ITEM_COUNT][] =
{
	"Kit de crochetage", "AK47", "AWP", "M249", "SCOUT", "SG550", "SG552", "UMP45", "TMP", "MP5", "DEAGLE",
	"USP", "GLOCK", "XM1014", "M3", "M4A1", "AUG", "GALIL", "MAC10", "FAMAS", "P90", "ELITES", "Ticket 10$",
	"Ticket 100$", "Ticket 1000$", "Level cut", "Cartouche", "Canapé", "Table", "Héroïne", "Extasie", "LSD", "Coke"
};

char ITEM_WEAPON[ITEM_COUNT][] =
{
	"", "weapon_ak47", "weapon_awp", "weapon_m249", "weapon_scout", "weapon_sg550", "weapon_sg552",
	"weapon_ump45", "weapon_tmp", "weapon_mp5navy", "weapon_deagle", "weapon_usp", "weapon_glock",
	"weapon_xm1014", "weapon_m3", "weapon_m4a1", "weapon_aug", "weapon_galil", "weapon_mac10",
	"weapon_famas", "weapon_p90", "weapon_elite", "", "", "", "", "", "", "", "", "", "", ""
};

int INVENTORY_ORDER[] =
{
	ITEM_KIT, ITEM_AWP, ITEM_M249, ITEM_AK47, ITEM_M4A1, ITEM_SG550, ITEM_SG552, ITEM_AUG, ITEM_GALIL,
	ITEM_FAMAS, ITEM_SCOUT, ITEM_MP5, ITEM_TMP, ITEM_UMP, ITEM_P90, ITEM_MAC10, ITEM_M3, ITEM_XM1014,
	ITEM_DEAGLE, ITEM_USP, ITEM_GLOCK, ITEM_ELITE, ITEM_TICKET10, ITEM_TICKET100, ITEM_TICKET1000,
	ITEM_CARTOUCHE, ITEM_PROPS1, ITEM_PROPS2, ITEM_HEROINE, ITEM_EXTA, ITEM_LSD, ITEM_COKE
};

#define MODEL_PROPS1 "models/props/cs_office/sofa.mdl"
#define MODEL_PROPS2 "models/props/cs_office/table_coffee.mdl"

#define KIT_MAX 20

enum
{
	SHOP_ARMU,
	SHOP_DROGUE,
	SHOP_LOTO,
	SHOP_COUNT
}

char SHOP_TITLE[SHOP_COUNT][] = { "Armurie de oviscity :", "Dealer de oviscity :", "Loto de oviscity :" };

int SHOP_ARMU_ITEM[] =
{
	ITEM_AWP, ITEM_M249, ITEM_AK47, ITEM_M4A1, ITEM_SG550, ITEM_SG552, ITEM_GALIL, ITEM_AUG, ITEM_FAMAS,
	ITEM_SCOUT, ITEM_M3, ITEM_XM1014, ITEM_MP5, ITEM_P90, ITEM_ELITE, ITEM_TMP, ITEM_UMP, ITEM_MAC10,
	ITEM_DEAGLE, ITEM_USP, ITEM_GLOCK, ITEM_CARTOUCHE
};
int SHOP_ARMU_PRICE[] =	{ 4000, 3000, 2000, 2000, 1500, 1500, 1300, 1100, 1000, 800, 800, 800, 700, 700, 650, 600, 600, 500, 400, 200, 200, 150 };
int SHOP_ARMU_CAPITAL[] =	{ 2000, 1500, 1000, 1000, 750, 750, 650, 550, 500, 400, 400, 400, 350, 350, 300, 300, 300, 250, 200, 100, 100, 100 };

int SHOP_DROGUE_ITEM[] =		{ ITEM_HEROINE, ITEM_EXTA, ITEM_LSD, ITEM_COKE };
int SHOP_DROGUE_PRICE[] =		{ 900, 600, 500, 700 };
int SHOP_DROGUE_CAPITAL[] =	{ 450, 300, 250, 350 };

int SHOP_LOTO_ITEM[] =		{ ITEM_TICKET10, ITEM_TICKET100, ITEM_TICKET1000 };
int SHOP_LOTO_PRICE[] =	{ 10, 100, 1000 };
int SHOP_LOTO_CAPITAL[] =	{ 5, 50, 500 };

int HOSTO_PRICE[2] = { 200, 400 };
int HOSTO_HEAL[2] = { 50, 100 };
int HOSTO_CAPITAL[2] = { 100, 200 };

enum
{
	EFFECT_ITEM,
	EFFECT_LEVELCUT,
	EFFECT_PERMIS_LEGER,
	EFFECT_PERMIS_LOURD,
	EFFECT_RIB,
	EFFECT_CB,
	EFFECT_SOIN,
	EFFECT_CHIRURGIE
}

#define SALE_COUNT 38

char SALE_LABEL[SALE_COUNT][] =
{
	"LSD 300$", "EXTASY 400$", "COKE 500$", "HEROINE 700$",
	"Levels cut au maximum 1000$",
	"CANAPE 1500$", "TABLE 1000$",
	"AWP 2500$", "M249 1500$", "AK47 1500$", "M4A1 1500$", "SG550 1300$", "SG552 1300$", "GALIL 1200$",
	"AUG 1000$", "FAMAS 900$", "SCOUT 700$", "M3 700$", "XM1014 700$", "MP5 600$", "P90 600$", "ELITES 450$",
	"TMP 500$", "UMP 500$", "MAC10 400$", "DEAGLE 300$", "GLOCK 100$", "USP 100$", "CARTOUCHE 100$",
	"Permis Leger 1000$", "Permis Lourd 2000$",
	"Ticket 10$", "Ticket 100$", "Ticket 1000$",
	"RIB 1500$", "CB 1500$",
	"Soin Partiel 100$", "Soin Complet 300$"
};

char SALE_KEY[SALE_COUNT][] =
{
	"lsd", "exta", "coke", "heroine", "levelcut", "props1", "props2",
	"awp", "m249", "ak47", "m4a1", "sg550", "sg552", "galil", "aug", "famas", "scout", "m3", "xm1014", "mp5", "p90",
	"elite", "tmp", "ump", "mac10", "deagle", "glock", "usp", "cartouche", "permisleger", "permislourd",
	"ticket10", "ticket100", "ticket1000", "rib", "cb", "partiel", "complet"
};

char SALE_QUESTION[SALE_COUNT][] =
{
	"Voulez-vous acheter du LSD à 300$ ?", "Voulez-vous acheter de l'Extasie à 400$ ?",
	"Voulez-vous acheter de la Coke à 500$ ?", "Voulez-vous acheter une Héroïne à 700$ ?",
	"Voulez-vous acheter des levels cut (100) à 1000$ ?",
	"Voulez-vous acheter un Canapé à 1500$ ?", "Voulez-vous acheter une Table à 1000$ ?",
	"Voulez-vous acheter une AWP à 2500$ ?", "Voulez-vous acheter une M249 à 1500$ ?",
	"Voulez-vous acheter une AK47 à 1500$ ?", "Voulez-vous acheter une M4A1 à 1500$ ?",
	"Voulez-vous acheter un SG550 à 1300$ ?", "Voulez-vous acheter un SG552 à 1300$ ?",
	"Voulez-vous acheter un Galil à 1200$ ?", "Voulez-vous acheter un AUG à 1000$ ?",
	"Voulez-vous acheter un Famas à 900$ ?", "Voulez-vous acheter un Scout à 700$ ?",
	"Voulez-vous acheter un M3 à 700$ ?", "Voulez-vous acheter un XM1014 à 700$ ?",
	"Voulez-vous acheter une MP5 à 600$ ?", "Voulez-vous acheter une P90 à 600$ ?",
	"Voulez-vous acheter des Élites à 450$ ?", "Voulez-vous acheter un TMP à 500$ ?",
	"Voulez-vous acheter un UMP à 500$ ?", "Voulez-vous acheter un MAC10 à 400$ ?",
	"Voulez-vous acheter un Deagle à 300$ ?", "Voulez-vous acheter un Glock à 100$ ?",
	"Voulez-vous acheter un USP à 100$ ?", "Voulez-vous acheter une Cartouche à 100$ ?",
	"Voulez-vous acheter un Permis léger à 1000$ ?", "Voulez-vous acheter un Permis lourd à 2000$ ?",
	"Voulez-vous acheter un ticket à 10$ ?", "Voulez-vous acheter un ticket à 100$ ?",
	"Voulez-vous acheter un ticket à 1000$ ?",
	"Voulez-vous acheter un RIB à 1500$ (payé par la banque) ?",
	"Voulez-vous acheter une Carte Bleue à 1500$ (payée par la banque) ?",
	"Voulez-vous acheter un Soin partiel à 100$ ?", "Voulez-vous acheter un Soin complet à 300$ ?"
};

int SALE_JOBMIN[SALE_COUNT] =
{
	9, 9, 9, 9, 12, 15, 15,
	18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
	21, 21, 21, 24, 24, 27, 27
};
int SALE_JOBMAX[SALE_COUNT] =
{
	11, 11, 11, 11, 14, 17, 17,
	20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
	23, 23, 23, 26, 26, 29, 29
};
int SALE_EFFECT[SALE_COUNT] =
{
	EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_LEVELCUT, EFFECT_ITEM, EFFECT_ITEM,
	EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM,
	EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM,
	EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM,
	EFFECT_PERMIS_LEGER, EFFECT_PERMIS_LOURD,
	EFFECT_ITEM, EFFECT_ITEM, EFFECT_ITEM, EFFECT_RIB, EFFECT_CB, EFFECT_SOIN, EFFECT_SOIN
};
int SALE_ITEM[SALE_COUNT] =
{
	ITEM_LSD, ITEM_EXTA, ITEM_COKE, ITEM_HEROINE, 0, ITEM_PROPS1, ITEM_PROPS2,
	ITEM_AWP, ITEM_M249, ITEM_AK47, ITEM_M4A1, ITEM_SG550, ITEM_SG552, ITEM_GALIL, ITEM_AUG, ITEM_FAMAS,
	ITEM_SCOUT, ITEM_M3, ITEM_XM1014, ITEM_MP5, ITEM_P90, ITEM_ELITE, ITEM_TMP, ITEM_UMP, ITEM_MAC10,
	ITEM_DEAGLE, ITEM_GLOCK, ITEM_USP, ITEM_CARTOUCHE, 0, 0,
	ITEM_TICKET10, ITEM_TICKET100, ITEM_TICKET1000, 0, 0, 50, 100
};
int SALE_PRICE[SALE_COUNT] =
{
	300, 400, 500, 700, 1000, 1500, 1000,
	2500, 1500, 1500, 1500, 1300, 1300, 1200, 1000, 900, 700, 700, 700, 600, 600, 450, 500, 500, 400, 300,
	100, 100, 100, 1000, 2000,
	10, 100, 1000, 1500, 1500, 100, 300
};
int SALE_SELLER[SALE_COUNT] =
{
	150, 200, 250, 350, 500, 750, 500,
	1250, 750, 750, 750, 650, 650, 600, 500, 450, 350, 350, 350, 300, 300, 225, 250, 250, 200, 150,
	50, 50, 50, 500, 1000,
	5, 50, 500, 750, 750, 50, 150
};
int SALE_CAPITAL[SALE_COUNT] =
{
	150, 200, 250, 350, 500, 750, 500,
	1250, 750, 750, 750, 650, 650, 600, 500, 450, 350, 350, 350, 300, 300, 225, 250, 250, 200, 150,
	50, 50, 50, 500, 1000,
	10, 50, 500, 750, 750, 50, 150
};

#define SALE_CHIRURGIE_PRICE	1000
#define SALE_CHIRURGIE_SELLER	500
#define SALE_CHIRURGIE_CAPITAL	500
#define SALE_CHIRURGIE			SALE_COUNT

char ARMU_POLICE_KEY[][] =
{
	"weapon_awp", "weapon_m249", "weapon_m4a1", "weapon_ak47", "weapon_aug", "weapon_scout", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_tmp", "weapon_mac10", "weapon_m3", "weapon_xm1014", "weapon_galil",
	"weapon_famas", "weapon_deagle", "weapon_glock", "weapon_usp", "weapon_flashbang", "weapon_hegrenade"
};
char ARMU_POLICE_LABEL[][] =
{
	"AWP", "M249", "M4A1", "AK47", "AUG", "SCOUT", "MP5", "P90", "UMP45", "TMP", "MAC10", "M3", "XM1014",
	"GALIL", "FAMAS", "DEAGLE", "GLOCK", "USP", "FLASH", "HE"
};
int ARMU_POLICE_FIRST[6] = { -1, 0, 2, 5, 9, 12 };

#define DRUG_DURATION 60

int COLOR_RED[4] = { 255, 75, 75, 255 };
int COLOR_GREEN[4] = { 75, 255, 75, 255 };
int COLOR_BLUE[4] = { 75, 75, 255, 255 };
int COLOR_ORANGE[4] = { 255, 128, 0, 255 };
