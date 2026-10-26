#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#undef REQUIRE_PLUGIN
#include <basecomm>

#define PLUGIN_VERSION "2.0.0"
#define LOGO "\x04[CSS-RP] \x01"
#define MAX_CASH 65535
#define MAX_BANK 2000000000
#define REACH 150.0

#define SOUND_TAZER		"ambient/machines/zap1.wav"
#define SOUND_LOCK		"doors/default_locked.wav"
#define SOUND_UNLOCK	"doors/latchunlocked1.wav"
#define SOUND_SALAIRE	"roleplay_sm/salaire.wav"
#define SOUND_SUCCESS	"roleplay_sm/success.wav"
#define SOUND_NOTEAM	"roleplay_sm/noteam.wav"

#include "roleplay/data.sp"
#include "roleplay/map.sp"

public Plugin myinfo =
{
	name = "Roleplay",
	author = "Delachambre (CSS-RP 1.1.1, 2013), remasterisé par Panda",
	description = "Mod roleplay pour Counter-Strike: Source",
	version = PLUGIN_VERSION,
	url = "https://github.com/WareZ57/CSS-RP-Remastered"
};

bool g_Loaded[MAXPLAYERS + 1];
char g_SteamId[MAXPLAYERS + 1][32];
int g_Cash[MAXPLAYERS + 1];
int g_Bank[MAXPLAYERS + 1];
int g_Job[MAXPLAYERS + 1];
int g_JailTime[MAXPLAYERS + 1];
int g_PermisLourd[MAXPLAYERS + 1];
int g_PermisLeger[MAXPLAYERS + 1];
int g_CB[MAXPLAYERS + 1];
int g_RIB[MAXPLAYERS + 1];
int g_Item[MAXPLAYERS + 1][ITEM_COUNT];
int g_SuccesHeadshot[MAXPLAYERS + 1];
int g_Headshots[MAXPLAYERS + 1];
int g_SuccesPorte20[MAXPLAYERS + 1];
int g_SuccesPorte50[MAXPLAYERS + 1];
int g_SuccesPorte100[MAXPLAYERS + 1];
int g_Portes[MAXPLAYERS + 1];
int g_Capital;

bool g_Welcomed[MAXPLAYERS + 1];
bool g_Jailed[MAXPLAYERS + 1];
bool g_JailPending[MAXPLAYERS + 1];
int g_JailCop[MAXPLAYERS + 1];
int g_CautionCrime[MAXPLAYERS + 1];
int g_RespawnIn[MAXPLAYERS + 1];
int g_KillCash[MAXPLAYERS + 1];
int g_TazeLeft[MAXPLAYERS + 1];
int g_LockpickLeft[MAXPLAYERS + 1];
int g_LockpickDoor[MAXPLAYERS + 1];
int g_LastLockpick[MAXPLAYERS + 1];
int g_LastTheft[MAXPLAYERS + 1];
int g_DrugLeft[MAXPLAYERS + 1];
bool g_Invisible[MAXPLAYERS + 1];
int g_Grabbed[MAXPLAYERS + 1];
bool g_UseHeld[MAXPLAYERS + 1];
int g_Clock;

ConVar g_cvBlockRoundEnd;
ConVar g_cvGameDesc;
ConVar g_cvServerName;
ConVar g_cvGrabSpeed;
ConVar g_cvGrabDistance;
ConVar g_cvGrabSound;
ConVar g_cvSaveBots;

ArrayList g_Pub;
ArrayList g_Infos;
ArrayList g_LinkTitles;
ArrayList g_LinkUrls;

bool g_HasSound[3];
char g_GrabSound[PLATFORM_MAX_PATH];

#include "roleplay/db.sp"
#include "roleplay/jobs.sp"
#include "roleplay/jail.sp"
#include "roleplay/flashball.sp"
#include "roleplay/doors.sp"
#include "roleplay/items.sp"
#include "roleplay/shops.sp"
#include "roleplay/police.sp"
#include "roleplay/admin.sp"

public void OnPluginStart()
{
	g_cvBlockRoundEnd = CreateConVar("sm_rp_block_roundend", "1", "1 = le round ne se termine jamais (sinon tout le monde réapparaît)", _, true, 0.0, true, 1.0);
	g_cvGameDesc = CreateConVar("sm_rp_gamedesc", "RolePlay", "Nom du jeu dans la liste des serveurs (extension SteamWorks)");
	g_cvServerName = CreateConVar("sm_rp_name", "", "Nom de la communauté dans les messages (« Bienvenue sur le Roleplay <nom> »)");
	g_cvGrabSpeed = CreateConVar("sm_grabber_speed", "10.0", "Vitesse à laquelle un objet porté suit le joueur");
	g_cvGrabDistance = CreateConVar("sm_grabber_distance", "80.0", "Distance de l'objet porté devant le joueur");
	g_cvGrabSound = CreateConVar("sm_grabber_sound", "weapons/physcannon/hold_loop.wav", "Son de /+force");
	Admin_Init();
	Flashball_Init();
	AutoExecConfig(true, "roleplay");

	RegConsoleCmd("sm_rp", Command_Roleplay, "Liste des commandes du roleplay");
	RegConsoleCmd("sm_infos", Command_Infos, "Informations sur le serveur");
	RegConsoleCmd("sm_ent", Command_Ent, "(admin) Infos sur l'entité visée");
	RegConsoleCmd("sm_lock", Command_Lock, "Fermer à clef la porte visée");
	RegConsoleCmd("sm_unlock", Command_Unlock, "Ouvrir la porte visée");
	RegConsoleCmd("sm_civil", Command_Civil, "Chef d'état, CIA, FBI : passer en civil / en service");
	RegConsoleCmd("sm_give", Command_Give, "Donner de l'argent au joueur visé : sm_give <montant>");
	RegConsoleCmd("sm_jail", Command_Jail, "Police : emprisonner le joueur visé");
	RegConsoleCmd("sm_taser", Command_Taser, "Police : taser le joueur visé");
	RegConsoleCmd("sm_vis", Command_Vis, "Chef d'état, CIA : invisible / visible");
	RegConsoleCmd("sm_jobmenu", Command_JobMenu, "(admin root) Donner un métier");
	RegConsoleCmd("sm_money", Command_Money, "Chef d'état : verser de l'argent en banque");
	RegConsoleCmd("sm_item", Command_Item, "Ouvrir son sac");
	RegConsoleCmd("sm_demission", Command_Demission, "Démissionner");
	RegConsoleCmd("sm_engager", Command_Engager, "Chef : engager un sans-emploi");
	RegConsoleCmd("sm_recruter", Command_Engager, "Chef : engager un sans-emploi");
	RegConsoleCmd("sm_recrute", Command_Engager, "Chef : engager un sans-emploi");
	RegConsoleCmd("sm_+force", Command_Grab, "Porter / lâcher l'objet ou le joueur visé");
	RegConsoleCmd("sm_force", Command_Grab, "Porter / lâcher l'objet ou le joueur visé");
	RegConsoleCmd("sm_enquete", Command_Enquete, "Police : enquêter sur le joueur visé");
	RegConsoleCmd("sm_del", Command_Del, "Police : supprimer l'arme au sol visée");
	RegConsoleCmd("sm_virer", Command_Virer, "Chef : renvoyer un employé");
	RegConsoleCmd("sm_licencier", Command_Virer, "Chef : renvoyer un employé");
	RegConsoleCmd("sm_exclure", Command_Virer, "Chef : renvoyer un employé");
	RegConsoleCmd("sm_vendre", Command_Vendre, "Vendre un article au joueur visé");
	RegConsoleCmd("sm_vol", Command_Vol, "Mafia : voler le joueur visé");
	RegConsoleCmd("sm_perquisition", Command_Perqui, "Police : annoncer une perquisition");
	RegConsoleCmd("sm_perqui", Command_Perqui, "Police : annoncer une perquisition");
	RegConsoleCmd("sm_armurerie", Command_Armurerie, "Police : armurerie");
	RegConsoleCmd("sm_armu", Command_Armurerie, "Police : armurerie");
	RegConsoleCmd("sm_changename", Command_ChangeName, "Chef d'état : changer de pseudo");
	RegConsoleCmd("sm_out", Command_Out, "Expulser le joueur visé de sa planque");
	RegConsoleCmd("sm_jaillist", Command_JailList, "Police : liste des prisonniers");
	RegConsoleCmd("sm_accepter", Command_Accepter, "Accepter la caution, la vente ou le job proposé");
	RegConsoleCmd("sm_refuser", Command_Refuser, "Refuser la caution, la vente ou le job proposé");

	AddCommandListener(Listener_Block, "kill");
	AddCommandListener(Listener_Block, "explode");
	AddCommandListener(Listener_JoinTeam, "jointeam");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMsg_TextMsg, true);

	ConVar startmoney = FindConVar("mp_startmoney");
	if (startmoney != null)
	{
		startmoney.SetBounds(ConVarBound_Lower, false);
	}

	g_Pub = new ArrayList(ByteCountToCells(192));
	g_Infos = new ArrayList(ByteCountToCells(128));
	g_LinkTitles = new ArrayList(ByteCountToCells(64));
	g_LinkUrls = new ArrayList(ByteCountToCells(192));

	DB_Connect();

	for (int client = 1; client <= MaxClients; client++)
	{
		g_Grabbed[client] = INVALID_ENT_REFERENCE;
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnPluginEnd()
{
	DB_SaveAll();
}

public void OnMapStart()
{
	PrecacheSound(SOUND_TAZER, true);
	PrecacheSound(SOUND_LOCK, true);
	PrecacheSound(SOUND_UNLOCK, true);
	g_cvGrabSound.GetString(g_GrabSound, sizeof(g_GrabSound));
	PrecacheSound(g_GrabSound, true);

	g_HasSound[0] = PrecacheCustomSound(SOUND_SALAIRE);
	g_HasSound[1] = PrecacheCustomSound(SOUND_SUCCESS);
	g_HasSound[2] = PrecacheCustomSound(SOUND_NOTEAM);

	PrecacheModel(MODEL_DEFAULT_CT, true);
	PrecacheModel(MODEL_DEFAULT_T, true);
	PrecacheModel(MODEL_PROPS1, true);
	PrecacheModel(MODEL_PROPS2, true);
	Jobs_PrecacheModels();
	Effects_Precache();

	SetConVarInt(FindConVar("ammo_flashbang_max"), 3);
	SetConVarInt(FindConVar("ammo_hegrenade_max"), 5);
	SetConVarInt(FindConVar("ammo_smokegrenade_max"), 3);

	Map_Load();
	LoadLines("pub.txt", g_Pub);
	LoadLines("infos.txt", g_Infos);
	LoadLinks();

	g_Clock = 0;
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_Hud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_Grab, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(90.0, Timer_Pub, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(300.0, Timer_AutoSave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
#if defined _SteamWorks_Included
	if (GetFeatureStatus(FeatureType_Native, "SteamWorks_SetGameDescription") == FeatureStatus_Available)
	{
		char desc[64];
		g_cvGameDesc.GetString(desc, sizeof(desc));
		SteamWorks_SetGameDescription(desc);
	}
#endif
}

public void OnMapEnd()
{
	DB_SaveAll();
}

static bool PrecacheCustomSound(const char[] sound)
{
	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "sound/%s", sound);
	if (!FileExists(path, true))
	{
		return false;
	}
	AddFileToDownloadsTable(path);
	return PrecacheSound(sound, true);
}

void PlayCustomSound(int client, int which, const char[] sound)
{
	if (g_HasSound[which])
	{
		EmitSoundToClient(client, sound);
	}
}

static void LoadLines(const char[] file, ArrayList list)
{
	list.Clear();
	char path[PLATFORM_MAX_PATH], line[192];
	BuildPath(Path_SM, path, sizeof(path), "configs/roleplay/%s", file);
	File f = OpenFile(path, "r");
	if (f == null)
	{
		return;
	}
	while (f.ReadLine(line, sizeof(line)))
	{
		TrimString(line);
		if (line[0] != '\0' && strncmp(line, "//", 2) != 0)
		{
			ReplaceString(line, sizeof(line), "\\x01", "\x01");
			ReplaceString(line, sizeof(line), "\\x03", "\x03");
			ReplaceString(line, sizeof(line), "\\x04", "\x04");
			list.PushString(line);
		}
	}
	delete f;
}

static void LoadLinks()
{
	ArrayList lines = new ArrayList(ByteCountToCells(192));
	LoadLines("liens.txt", lines);
	g_LinkTitles.Clear();
	g_LinkUrls.Clear();
	char line[192], parts[2][160];
	for (int i = 0; i < lines.Length; i++)
	{
		lines.GetString(i, line, sizeof(line));
		if (ExplodeString(line, "|", parts, sizeof(parts), sizeof(parts[])) == 2)
		{
			TrimString(parts[0]);
			TrimString(parts[1]);
			g_LinkTitles.PushString(parts[0]);
			g_LinkUrls.PushString(parts[1]);
		}
	}
	delete lines;
}

public void OnClientPutInServer(int client)
{
	ResetProfile(client);
	ResetState(client);
	SDKHook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientPostAdminCheck(int client)
{
	DB_LoadClient(client);
}

public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client))
	{
		DB_SaveClient(client);
	}
	Grab_ReleaseAllOf(client);
	ResetState(client);
	g_Loaded[client] = false;
	g_SteamId[client][0] = '\0';
}

void ResetProfile(int client)
{
	g_Loaded[client] = false;
	g_Cash[client] = 0;
	g_Bank[client] = 0;
	g_Job[client] = 0;
	g_JailTime[client] = 0;
	g_PermisLourd[client] = 0;
	g_PermisLeger[client] = 0;
	g_CB[client] = 0;
	g_RIB[client] = 0;
	for (int i = 0; i < ITEM_COUNT; i++)
	{
		g_Item[client][i] = 0;
	}
	g_SuccesHeadshot[client] = 0;
	g_Headshots[client] = 0;
	g_SuccesPorte20[client] = 0;
	g_SuccesPorte50[client] = 0;
	g_SuccesPorte100[client] = 0;
	g_Portes[client] = 0;
}

static void ResetState(int client)
{
	g_Welcomed[client] = false;
	g_Jailed[client] = false;
	g_JailPending[client] = false;
	g_JailCop[client] = 0;
	g_CautionCrime[client] = -1;
	g_RespawnIn[client] = 0;
	g_KillCash[client] = -1;
	g_TazeLeft[client] = 0;
	Flashball_Reset(client);
	g_LockpickLeft[client] = 0;
	g_LockpickDoor[client] = INVALID_ENT_REFERENCE;
	g_LastLockpick[client] = 0;
	g_LastTheft[client] = 0;
	g_DrugLeft[client] = 0;
	g_Invisible[client] = false;
	g_Grabbed[client] = INVALID_ENT_REFERENCE;
	g_UseHeld[client] = false;
	g_OfferFrom[client] = 0;
	g_ShopEnt[client] = INVALID_ENT_REFERENCE;
	Sale_Reset(client);
	Furniture_RemoveAllOf(client);
}

void OnProfileLoaded(int client)
{
	g_Loaded[client] = true;
	g_Jailed[client] = g_JailTime[client] > 0;
	if (!IsClientInGame(client))
	{
		return;
	}
	SetCash(client, g_Cash[client]);
	CreateTimer(1.0, Timer_Join, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Join(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0 && IsClientInGame(client))
	{
		Jobs_Join(client);
	}
	return Plugin_Stop;
}

int Max(int a, int b)
{
	return a > b ? a : b;
}

int ClampCash(int amount)
{
	return amount < 0 ? 0 : (amount > MAX_CASH ? MAX_CASH : amount);
}

int GetCash(int client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

void SetCash(int client, int amount)
{
	g_Cash[client] = ClampCash(amount);
	SetEntProp(client, Prop_Send, "m_iAccount", g_Cash[client]);
}

void AddCash(int client, int amount)
{
	int total = GetCash(client) + amount;
	if (total > MAX_CASH)
	{
		AddBank(client, total - MAX_CASH);
		total = MAX_CASH;
	}
	SetCash(client, total);
}

int AddBank(int client, int amount)
{
	if (amount > MAX_BANK - g_Bank[client])
	{
		amount = MAX_BANK - g_Bank[client];
	}
	g_Bank[client] += amount;
	return amount;
}

bool Pay(int client, int price, bool bankOnly = false)
{
	if (!bankOnly && GetCash(client) >= price)
	{
		SetCash(client, GetCash(client) - price);
		return true;
	}
	if ((bankOnly || g_CB[client] > 0) && g_Bank[client] >= price)
	{
		g_Bank[client] -= price;
		return true;
	}
	return false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Doors_RoundStart();
	MapWeapons_SpawnAll();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && g_Loaded[client] && GetCash(client) != g_Cash[client])
		{
			SetCash(client, g_Cash[client]);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client != 0)
	{
		ClientCommand(client, "cl_radaralpha 0");
		RequestFrame(Frame_AfterSpawn, userid);
	}
}

public void Frame_AfterSpawn(any userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client) && g_Loaded[client] && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		Jobs_ApplySpawn(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	if (victim == 0)
	{
		return;
	}

	if (killer != 0 && killer != victim && IsClientInGame(killer))
	{
		if (g_KillCash[killer] == -1)
		{
			g_KillCash[killer] = GetCash(killer);
		}
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(killer));
		pack.WriteCell(GetClientUserId(victim));
		RequestFrame(Frame_ResetScores, pack);

		char weapon[32];
		event.GetString("weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "knife") && g_Item[killer][ITEM_LEVELCUT] > 0)
		{
			g_Item[killer][ITEM_LEVELCUT]--;
		}

		if (event.GetBool("headshot") && ++g_Headshots[killer] == 30)
		{
			PrintToChatAll("%s : Le joueur %N a remporté le succès \x03Headshot attitude\x01.", LOGO, killer);
			PlayCustomSound(killer, 1, SOUND_SUCCESS);
			g_SuccesHeadshot[killer] = 1;
		}
	}

	Jail_OnDeath(victim);
	Items_OnDeath(victim);
	Grab_ReleaseAllOf(victim);
	g_RespawnIn[victim] = 12;
}

public void Frame_ResetScores(DataPack pack)
{
	pack.Reset();
	int killer = GetClientOfUserId(pack.ReadCell());
	int victim = GetClientOfUserId(pack.ReadCell());
	delete pack;
	if (killer != 0 && IsClientInGame(killer))
	{
		if (g_KillCash[killer] != -1)
		{
			SetCash(killer, g_KillCash[killer]);
			g_KillCash[killer] = -1;
		}
		SetEntProp(killer, Prop_Data, "m_iFrags", 0);
	}
	if (victim != 0 && IsClientInGame(victim))
	{
		SetEntProp(victim, Prop_Data, "m_iDeaths", 0);
	}
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	return Plugin_Handled;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if (g_cvBlockRoundEnd.BoolValue)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Listener_Block(int client, const char[] command, int argc)
{
	if (client != 0)
	{
		PrintToConsole(client, "[CSS-RP] : Cette commande est désactivée.");
	}
	return Plugin_Handled;
}

public Action Listener_JoinTeam(int client, const char[] command, int argc)
{
	if (client == 0 || !g_Loaded[client] || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return Plugin_Handled;
	}
	PrintToChat(client, "%s : Votre équipe dépend de votre métier.", LOGO);
	PlayCustomSound(client, 2, SOUND_NOTEAM);
	return Plugin_Handled;
}

public Action UserMsg_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (GetUserMessageType() != UM_BitBuf)
	{
		return Plugin_Continue;
	}
	char text[256];
	msg.ReadByte();
	msg.ReadString(text, sizeof(text), false);
	if (StrContains(text, "damage", false) != -1 || StrContains(text, "-------", false) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client == 0 || !IsClientInGame(client) || sArgs[0] == '\0')
	{
		return Plugin_Continue;
	}
	bool trigger = sArgs[0] == '!' || sArgs[0] == '/';
	bool dead = !IsPlayerAlive(client);
	if (dead || g_Jailed[client])
	{
		if (!trigger || !IsChatCommand(sArgs[1]))
		{
			PrintToChat(client, dead ? "%s : Vous devez être en vie pour parler." : "%s : Vous ne pouvez pas parler en prison.", LOGO);
		}
		return Plugin_Handled;
	}
	if (trigger)
	{
		return Plugin_Continue;
	}
	if (StrEqual(command, "say_team"))
	{
		float origin[3], other[3];
		GetClientAbsOrigin(client, origin);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, other);
				if (GetVectorDistance(origin, other) < 500.0)
				{
					PrintToChat(i, "%s : (LOCAL) %N : %s", LOGO, client, sArgs);
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

static bool IsChatCommand(const char[] text)
{
	char name[64];
	BreakString(text, name, sizeof(name));
	if (name[0] == '\0')
	{
		return false;
	}
	if (CommandExists(name))
	{
		return true;
	}
	Format(name, sizeof(name), "sm_%s", name);
	return CommandExists(name);
}

bool JustProposed(int client, float since)
{
	if (GetGameTime() - since < 1.5)
	{
		PrintToChat(client, "%s : La proposition vient de changer : relisez-la avant de répondre.", LOGO);
		return true;
	}
	return false;
}

bool InJail(int client)
{
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas faire cela en prison.", LOGO);
		return true;
	}
	return false;
}

void SetVoice(int client, bool talk)
{
	bool adminMuted = LibraryExists("basecomm") && BaseComm_IsClientMuted(client);
	SetClientListeningFlags(client, talk && !adminMuted ? VOICE_NORMAL : VOICE_MUTED);
}

public void BaseComm_OnClientMute(int client, bool muteState)
{
	if (!muteState && g_Jailed[client] && IsClientInGame(client))
	{
		SetClientListeningFlags(client, VOICE_MUTED);
	}
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if ((damagetype & DMG_FALL) || (damagetype & DMG_BLAST))
	{
		return Plugin_Handled;
	}
	if (attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	char weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if ((StrEqual(weapon, "weapon_knife") && g_Item[attacker][ITEM_LEVELCUT] <= 0)
	 || g_TazeLeft[attacker] > 0
	 || InZone(attacker, ZONE_COMICO) || InZone(attacker, ZONE_FBI) || InZone(attacker, ZONE_HOSTO))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	if ((damagetype & DMG_BULLET) && Flashball_Armed(attacker))
	{
		Flashball_Hit(victim);
		damage = 0.0;
		return Plugin_Changed;
	}
	if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
	{
		damage *= 0.25;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Hook_WeaponEquip(int client, int weapon)
{
	MapWeapons_OnEquip(weapon);
	return Plugin_Continue;
}

public Action Timer_Second(Handle timer)
{
	if (++g_Clock >= 24 * 60)
	{
		g_Clock = 0;
		PaySalaries();
	}
	MapWeapons_Tick();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		Jobs_TickRespawn(client);
		Jail_Tick(client);
		Taser_Tick(client);
		Lockpick_Tick(client);
		Items_TickDrug(client);
	}
	return Plugin_Continue;
}

static void PaySalaries()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !g_Loaded[client] || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		{
			continue;
		}
		if (!IsPlayerAlive(client))
		{
			PrintToChat(client, "%s : Vous devez être vivant pour avoir votre salaire.", LOGO);
		}
		else if (g_Jailed[client])
		{
			PrintToChat(client, "%s : Vous êtes en prison, vous n'avez pas votre salaire.", LOGO);
		}
		else
		{
			AddCash(client, JOB_SALARY[g_Job[client]]);
			PrintToChat(client, "%s : Vous avez reçu votre paie de %d$.", LOGO, JOB_SALARY[g_Job[client]]);
			PlayCustomSound(client, 0, SOUND_SALAIRE);
		}
	}

	int tax = GetRandomInt(1, 800);
	if (g_Capital > 0)
	{
		g_Capital = Max(g_Capital - tax, 0);
	}
	else
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && Jobs_IsChef(g_Job[client]))
			{
				PrintToChat(client, "%s : Vous n'avez pas assez d'argent pour payer les impôts s'élevant à %d$.", LOGO, tax);
			}
		}
	}
	DB_SaveCapital();
}

public Action Timer_AutoSave(Handle timer)
{
	DB_SaveAll();
	return Plugin_Continue;
}

public Action Timer_Pub(Handle timer)
{
	if (g_Pub.Length > 0)
	{
		char line[192];
		g_Pub.GetString(GetRandomInt(0, g_Pub.Length - 1), line, sizeof(line));
		PrintToChatAll("%s : %s", LOGO, line);
	}
	return Plugin_Continue;
}

public Action Timer_Hud(Handle timer)
{
	char text[250], zone[32], capital[32], hour[8];
	FormatEx(hour, sizeof(hour), "%02d:%02d", g_Clock / 60, g_Clock % 60);
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || !g_Loaded[client])
		{
			continue;
		}
		g_Cash[client] = GetCash(client);
		int job = g_Job[client];
		ZoneName(client, zone, sizeof(zone));
		if (g_Jailed[client])
		{
			FormatEx(text, sizeof(text), "Argent : %d$\nEn banque : %d$\nMétier : %s\nSalaire : %d$\nHorloge : %s\nZone : %s\nTemps de prison : %ds",
				g_Cash[client], g_Bank[client], JOB_NAME[job], JOB_SALARY[job], hour, zone, g_JailTime[client]);
		}
		else
		{
			capital[0] = '\0';
			if (job == 1 || Jobs_IsChef(job))
			{
				FormatEx(capital, sizeof(capital), "Capital : %d$\n", g_Capital);
			}
			FormatEx(text, sizeof(text), "Argent : %d$\nEn banque : %d$\nMétier : %s\nEntreprise : %s\nSalaire : %d$\n%sHorloge : %s\nZone : %s\nLevel cut : %d\nPermis Lourd : %s\nPermis Léger : %s",
				g_Cash[client], g_Bank[client], JOB_NAME[job], GROUP_COMPANY[JOB_GROUP[job]], JOB_SALARY[job], capital, hour,
				zone, g_Item[client][ITEM_LEVELCUT], g_PermisLourd[client] > 0 ? "Oui" : "Non", g_PermisLeger[client] > 0 ? "Oui" : "Non");
		}
		BfWrite bf = UserMessageToBfWrite(StartMessageOne("KeyHintText", client));
		if (bf != null)
		{
			bf.WriteByte(1);
			bf.WriteString(text);
			EndMessage();
		}
	}
	return Plugin_Continue;
}

public Action Command_Roleplay(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	static const char lines[][] =
	{
		"/virer => Virer un employé", "/engager => Engager un joueur", "/vendre => Vendre un article",
		"/infos => Informations sur le serveur", "/unlock => Déverrouiller une porte", "/lock => Verrouiller une porte",
		"/civil => Se mettre en civil", "/jail => Mettre un joueur en prison", "/give => Donner de l'argent à un joueur",
		"/taser => Taser un joueur", "/vol => Voler un joueur", "/demission => Démissionner de son travail",
		"/enquete => Faire une enquête", "/+force => Porter un objet ou un joueur", "/del => Supprimer l'arme au sol visée",
		"/vis => Devenir invisible", "/jobmenu => Donner un métier (admin)", "/money => Verser de l'argent à un joueur",
		"/item => Ouvrir son sac", "/perquisition => Faire une perquisition", "/armurerie => Ouvrir l'armurerie",
		"/changename => Changer de pseudo", "/out => Expulser de chez vous", "/jaillist => Joueurs en prison",
		"/accepter, /refuser => Répondre à une offre"
	};
	Menu menu = new Menu(Menu_Close);
	menu.SetTitle("Commandes du Roleplay :");
	for (int i = 0; i < sizeof(lines); i++)
	{
		menu.AddItem("", lines[i], ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_Accepter(int client, int args)
{
	Answer(client, true);
	return Plugin_Handled;
}

public Action Command_Refuser(int client, int args)
{
	Answer(client, false);
	return Plugin_Handled;
}

static void Answer(int client, bool yes)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
	if (Caution_Pending(client))
	{
		Caution_Answer(client, yes);
	}
	else if (Sale_Pending(client))
	{
		Sale_Answer(client, yes);
	}
	else if (Offer_Pending(client))
	{
		Offer_Answer(client, yes);
	}
	else
	{
		PrintToChat(client, "%s : Aucune proposition en attente.", LOGO);
	}
}

public int Menu_Close(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Command_Infos(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	char name[64], line[128];
	g_cvServerName.GetString(name, sizeof(name));
	Panel panel = new Panel();
	Format(name, sizeof(name), name[0] != '\0' ? "%s Roleplay :" : "%sRoleplay :", name);
	panel.SetTitle(name);
	for (int i = 0; i < g_Infos.Length; i++)
	{
		g_Infos.GetString(i, line, sizeof(line));
		panel.DrawText(line);
	}
	panel.DrawText("Plugin RolePlay : CSS-RP " ... PLUGIN_VERSION ... " (Delachambre, 2013)");
	panel.DrawText("Modifié, corrigé et nettoyé");
	panel.DrawItem("Fermer");
	panel.Send(client, Panel_Close, 50);
	delete panel;
	return Plugin_Handled;
}

public int Panel_Close(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

public Action Command_Grab(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas porter en prison.", LOGO);
		return Plugin_Handled;
	}
	if (EntRefToEntIndex(g_Grabbed[client]) != INVALID_ENT_REFERENCE)
	{
		Grab_Release(client);
		return Plugin_Handled;
	}
	int ent = TraceToEntity(client);
	if (ent <= 0)
	{
		PrintToChat(client, "%s : Vous ne portez aucun objet ni personne.", LOGO);
		return Plugin_Handled;
	}
	if (DistanceTo(client, ent) > REACH)
	{
		PrintToChat(client, "%s : Vous êtes trop loin pour porter cela.", LOGO);
		return Plugin_Handled;
	}
	char classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	if (StrContains(classname, "prop_physics") == 0)
	{
		Grab_Start(client, ent);
	}
	else if (ent <= MaxClients)
	{
		if (GetClientTeam(client) != CS_TEAM_CT && !Jobs_IsChef(g_Job[client]))
		{
			PrintToChat(client, "%s : Vous ne pouvez pas porter un joueur.", LOGO);
		}
		else if (GetClientTeam(ent) == CS_TEAM_CT)
		{
			PrintToChat(client, "%s : Vous ne pouvez pas porter un policier.", LOGO);
		}
		else if (g_Jailed[ent] && GetClientTeam(client) != CS_TEAM_CT)
		{
			PrintToChat(client, "%s : Vous ne pouvez pas porter un prisonnier.", LOGO);
		}
		else
		{
			Grab_Start(client, ent);
		}
	}
	return Plugin_Handled;
}

static void Grab_Start(int client, int ent)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (EntRefToEntIndex(g_Grabbed[i]) == ent)
		{
			PrintToChat(client, "%s : Quelqu'un porte déjà cela.", LOGO);
			return;
		}
	}
	g_Grabbed[client] = EntIndexToEntRef(ent);
	EmitSoundToAll(g_GrabSound, client);
}

void Grab_Release(int client)
{
	if (g_Grabbed[client] != INVALID_ENT_REFERENCE)
	{
		g_Grabbed[client] = INVALID_ENT_REFERENCE;
		if (IsClientInGame(client))
		{
			StopSound(client, SNDCHAN_AUTO, g_GrabSound);
		}
	}
}

void Grab_ReleaseAllOf(int client)
{
	Grab_Release(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_Grabbed[i] != INVALID_ENT_REFERENCE && EntRefToEntIndex(g_Grabbed[i]) == client)
		{
			Grab_Release(i);
		}
	}
}

public Action Timer_Grab(Handle timer)
{
	float speed = g_cvGrabSpeed.FloatValue, distance = g_cvGrabDistance.FloatValue;
	float angles[3], dir[3], pos[3], target[3], vel[3];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_Grabbed[client] == INVALID_ENT_REFERENCE)
		{
			continue;
		}
		int ent = EntRefToEntIndex(g_Grabbed[client]);
		if (ent == INVALID_ENT_REFERENCE || !IsClientInGame(client) || !IsPlayerAlive(client)
		 || (ent <= MaxClients && (!IsClientInGame(ent) || !IsPlayerAlive(ent))))
		{
			Grab_Release(client);
			continue;
		}
		GetClientEyeAngles(client, angles);
		GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, pos);
		ScaleVector(dir, distance);
		AddVectors(pos, dir, pos);
		GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", target);
		SubtractVectors(pos, target, vel);
		if (GetVectorLength(vel) > 4.0 * REACH)
		{
			Grab_Release(client);
			continue;
		}
		ScaleVector(vel, speed);
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vel);
	}
	return Plugin_Continue;
}

int TraceToEntity(int client)
{
	float pos[3], angles[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angles);
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, Filter_NotSelf, client);
	int ent = TR_DidHit(trace) ? TR_GetEntityIndex(trace) : -1;
	delete trace;
	return ent;
}

public bool Filter_NotSelf(int entity, int mask, any data)
{
	return entity != data;
}

int AimedPlayer(int client)
{
	int target = GetClientAimTarget(client, true);
	return (target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target)) ? target : 0;
}

float DistanceTo(int client, int entity)
{
	float a[3], b[3];
	GetClientAbsOrigin(client, a);
	EntityCenter(entity, b);
	return GetVectorDistance(a, b);
}
