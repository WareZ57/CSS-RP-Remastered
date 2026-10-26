bool g_JobModelOk[sizeof(JOB_MODEL)];
bool g_TModelOk[sizeof(T_MODELS)];

int g_OfferFrom[MAXPLAYERS + 1];
int g_OfferJob[MAXPLAYERS + 1];
int g_OfferTime[MAXPLAYERS + 1];
float g_OfferShown[MAXPLAYERS + 1];
int g_MenuTarget[MAXPLAYERS + 1];

void Jobs_PrecacheModels()
{
	for (int i = 1; i < sizeof(JOB_MODEL); i++)
	{
		g_JobModelOk[i] = PrecacheIfExists(JOB_MODEL[i]);
	}
	for (int i = 0; i < sizeof(T_MODELS); i++)
	{
		g_TModelOk[i] = PrecacheIfExists(T_MODELS[i]);
	}
}

static bool PrecacheIfExists(const char[] model)
{
	if (!FileExists(model, true))
	{
		return false;
	}
	return PrecacheModel(model, true) != 0;
}

bool Jobs_IsChef(int job)
{
	return job == 6 || job == 9 || job == 12 || job == 15 || job == 18 || job == 21 || job == 24 || job == 27;
}

int JobTeam(int job)
{
	return JOB_GROUP[job] == GROUP_ETAT ? CS_TEAM_CT : CS_TEAM_T;
}

void ApplyModel(int client)
{
	int job = g_Job[client];
	if (GetClientTeam(client) == CS_TEAM_CT && job >= 1 && job <= 5)
	{
		SetEntityModel(client, g_JobModelOk[job] ? JOB_MODEL[job] : MODEL_DEFAULT_CT);
		return;
	}
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntityModel(client, MODEL_DEFAULT_CT);
		return;
	}
	int pick = GetRandomInt(0, sizeof(T_MODELS) - 1);
	SetEntityModel(client, g_TModelOk[pick] ? T_MODELS[pick] : MODEL_DEFAULT_T);
}

void ApplyTag(int client)
{
	CS_SetClientClanTag(client, JOB_TAG[g_Job[client]]);
}

public void OnClientSettingsChanged(int client)
{
	if (IsClientInGame(client) && g_Loaded[client])
	{
		ApplyTag(client);
	}
}

void SetJob(int client, int job)
{
	g_Job[client] = job;
	ApplyTag(client);
	int team = JobTeam(job);
	if (GetClientTeam(client) > CS_TEAM_SPECTATOR && GetClientTeam(client) != team)
	{
		CS_SwitchTeam(client, team);
		if (IsPlayerAlive(client))
		{
			ApplyModel(client);
		}
	}
}

void Jobs_Join(int client)
{
	int team = JobTeam(g_Job[client]);
	if (GetClientTeam(client) != team)
	{
		CS_SwitchTeam(client, team);
	}
	CS_RespawnPlayer(client);

	if (!g_Welcomed[client] && !IsFakeClient(client))
	{
		g_Welcomed[client] = true;
		char line[96], name[64];
		Menu menu = new Menu(Menu_Close);
		menu.SetTitle("Bienvenue sur le Roleplay %N", client);
		FormatEx(line, sizeof(line), "Votre job est : %s.", JOB_NAME[g_Job[client]]);
		menu.AddItem("", line, ITEMDRAW_DISABLED);
		menu.AddItem("", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED);
		menu.AddItem("", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED);
		menu.AddItem("", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		menu.Display(client, MENU_TIME_FOREVER);

		g_cvServerName.GetString(name, sizeof(name));
		if (name[0] != '\0')
		{
			PrintToChat(client, "%s : Bienvenue sur le Roleplay %s.", LOGO, name);
		}
		else
		{
			PrintToChat(client, "%s : Bienvenue sur le Roleplay.", LOGO);
		}
	}
}

void Jobs_ApplySpawn(int client)
{
	g_RespawnIn[client] = 0;
	g_TazeLeft[client] = 0;
	Flashball_Reset(client);
	g_DrugLeft[client] = 0;
	g_Invisible[client] = false;
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityGravity(client, 1.0);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	SetEntityHealth(client, GetClientTeam(client) == JobTeam(g_Job[client]) ? JOB_HEALTH[g_Job[client]] : 100);
	ApplyModel(client);
	ApplyTag(client);
	Disarm(client);
	GivePlayerItem(client, "weapon_knife");

	if (g_Jailed[client])
	{
		TeleportToRandomCell(client);
	}
	else
	{
		TeleportToRandomSpawn(client);
	}
	SetVoice(client, !g_Jailed[client]);
}

void Disarm(int client)
{
	for (int slot = 0; slot < 6; slot++)
	{
		int weapon;
		while ((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}

void Jobs_TickRespawn(int client)
{
	if (g_RespawnIn[client] <= 0 || !g_Loaded[client] || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return;
	}
	if (IsPlayerAlive(client))
	{
		g_RespawnIn[client] = 0;
		return;
	}
	if (--g_RespawnIn[client] > 0)
	{
		PrintCenterText(client, "Respawn dans : %d secondes", g_RespawnIn[client]);
		return;
	}
	int team = JobTeam(g_Job[client]);
	if (GetClientTeam(client) != team)
	{
		CS_SwitchTeam(client, team);
	}
	CS_RespawnPlayer(client);
	PrintToChat(client, "%s : Vous avez été respawn.", LOGO);
}

public Action Command_Civil(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	int job = g_Job[client];
	if (job < 1 || job > 3)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		CS_SetClientClanTag(client, JOB_TAG[0]);
		ApplyModel(client);
		if (GetClientHealth(client) > 100)
		{
			SetEntityHealth(client, 100);
		}
		PrintToChat(client, "%s : Vous êtes désormais en civil.", LOGO);
	}
	else
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
		ApplyTag(client);
		ApplyModel(client);
		PrintToChat(client, "%s : Vous êtes désormais en service.", LOGO);
	}
	return Plugin_Handled;
}

public Action Command_Demission(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	if (g_Job[client] == 0)
	{
		PrintToChat(client, "%s : Vous n'avez pas de job.", LOGO);
		return Plugin_Handled;
	}
	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	if (StrEqual(arg, "oui"))
	{
		Demission(client);
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_Demission);
	menu.SetTitle("Veux-tu démissionner ?");
	menu.AddItem("oui", "Oui je veux.");
	menu.AddItem("non", "Non je me suis trompé.");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Demission(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "oui"))
		{
			Demission(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void Demission(int client)
{
	if (g_Job[client] != 0)
	{
		SetJob(client, 0);
		PrintToChat(client, "%s : Vous avez quitté votre travail.", LOGO);
	}
}

public Action Command_Engager(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	if (!Jobs_IsChef(g_Job[client]))
	{
		PrintToChat(client, "%s : Vous devez être chef.", LOGO);
		return Plugin_Handled;
	}
	if (args >= 2)
	{
		char arg[MAX_NAME_LENGTH], jobArg[8];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, jobArg, sizeof(jobArg));
		int target = FindTarget(client, arg, false, false);
		if (target != -1)
		{
			Offer_Send(client, target, StringToInt(jobArg));
		}
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_EngagerPlayer);
	menu.SetTitle("Choisis le joueur :");
	AddPlayers(menu, client, 0, 0, true);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_EngagerPlayer(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		g_MenuTarget[client] = StringToInt(info);
		int chef = g_Job[client];
		Menu jobs = new Menu(Menu_EngagerJob);
		jobs.SetTitle("Choisis le job :");
		for (int job = chef + 1; job < JOB_COUNT && JOB_GROUP[job] == JOB_GROUP[chef]; job++)
		{
			IntToString(job, info, sizeof(info));
			jobs.AddItem(info, JOB_NAME[job]);
		}
		jobs.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_EngagerJob(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(g_MenuTarget[client]);
		if (target == 0)
		{
			PrintToChat(client, "%s : Ce joueur n'est plus disponible.", LOGO);
			return 0;
		}
		Offer_Send(client, target, StringToInt(info));
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void Offer_Send(int chef, int target, int job)
{
	if (!IsPlayerAlive(chef) || g_Jailed[chef])
	{
		return;
	}
	if (g_OfferFrom[target] != 0 && g_OfferFrom[target] != GetClientUserId(chef) && GetTime() - g_OfferTime[target] < 30)
	{
		PrintToChat(chef, "%s : Ce joueur a déjà une proposition en attente.", LOGO);
		return;
	}
	if (target == chef || !IsClientInGame(target) || !IsPlayerAlive(target) || !g_Loaded[target] || g_Job[target] != 0)
	{
		PrintToChat(chef, "%s : Ce joueur n'est pas disponible (vivant et sans emploi).", LOGO);
		return;
	}
	if (!Jobs_IsChef(g_Job[chef]) || job <= g_Job[chef] || job >= JOB_COUNT || JOB_GROUP[job] != JOB_GROUP[g_Job[chef]])
	{
		PrintToChat(chef, "%s : Vous ne pouvez proposer que les métiers de votre entreprise.", LOGO);
		return;
	}
	g_OfferFrom[target] = GetClientUserId(chef);
	g_OfferJob[target] = job;
	g_OfferTime[target] = GetTime();
	g_OfferShown[target] = GetGameTime();
	Offer_ShowMenu(target);
	PrintToChat(target, "%s : %N vous propose le job %s : !accepter ou !refuser.", LOGO, chef, JOB_NAME[job]);
	PrintToChat(chef, "%s : Offre envoyée à %N.", LOGO, target);
}

static void Offer_ShowMenu(int target)
{
	int job = g_OfferJob[target];
	char info[24];
	Menu offer = new Menu(Menu_EngagerOffer);
	offer.SetTitle("Veux-tu devenir %s ?", JOB_NAME[job]);
	FormatEx(info, sizeof(info), "oui %d %d", g_OfferFrom[target], job);
	offer.AddItem(info, "Oui je veux");
	FormatEx(info, sizeof(info), "non %d %d", g_OfferFrom[target], job);
	offer.AddItem(info, "Non merci");
	offer.Display(target, MENU_TIME_FOREVER);
}

public int Menu_EngagerOffer(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24], parts[3][12];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info, " ", parts, sizeof(parts), sizeof(parts[]));
		if (StringToInt(parts[1]) != g_OfferFrom[client] || StringToInt(parts[2]) != g_OfferJob[client])
		{
			PrintToChat(client, "%s : Cette offre n'est plus valable.", LOGO);
			return 0;
		}
		Offer_Answer(client, StrEqual(parts[0], "oui"));
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

bool Offer_Pending(int client)
{
	return g_OfferFrom[client] != 0;
}

void Offer_Answer(int client, bool accept)
{
	if (accept && g_OfferFrom[client] != 0 && JustProposed(client, g_OfferShown[client]))
	{
		Offer_ShowMenu(client);
		return;
	}
	int chef = GetClientOfUserId(g_OfferFrom[client]);
	int job = g_OfferJob[client];
	g_OfferFrom[client] = 0;
	if (chef == 0 || job <= 0 || !Jobs_IsChef(g_Job[chef]) || JOB_GROUP[g_Job[chef]] != JOB_GROUP[job] || g_Job[client] != 0)
	{
		PrintToChat(client, "%s : Cette offre n'est plus valable.", LOGO);
		return;
	}
	if (accept)
	{
		SetJob(client, job);
		PrintToChat(client, "%s : Vous êtes désormais %s.", LOGO, JOB_NAME[job]);
		PrintToChat(chef, "%s : %N a accepté de devenir %s.", LOGO, client, JOB_NAME[job]);
	}
	else
	{
		PrintToChat(client, "%s : Vous avez refusé le job.", LOGO);
		PrintToChat(chef, "%s : %N a refusé le job.", LOGO, client);
	}
}

public Action Command_Virer(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	int chef = g_Job[client];
	if (!Jobs_IsChef(chef))
	{
		PrintToChat(client, "%s : Vous devez être chef.", LOGO);
		return Plugin_Handled;
	}
	if (args >= 1)
	{
		char arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		int target = FindTarget(client, arg, false, false);
		if (target != -1)
		{
			Virer(client, target);
		}
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_Virer);
	menu.SetTitle("Choisis le joueur :");
	AddPlayers(menu, client, chef + 1, chef == 27 ? 30 : chef + 2, false);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Virer(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if (target != 0)
		{
			Virer(client, target);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void Virer(int chef, int target)
{
	int job = g_Job[chef];
	if (!IsPlayerAlive(chef) || g_Jailed[chef])
	{
		return;
	}
	if (target == chef || !Jobs_IsChef(job) || g_Job[target] == 0 || JOB_GROUP[g_Job[target]] != JOB_GROUP[job])
	{
		PrintToChat(chef, "%s : Ce joueur n'est pas un employé de votre entreprise.", LOGO);
		return;
	}
	SetJob(target, 0);
	PrintToChat(target, "%s : Vous avez été viré de votre job.", LOGO);
	PrintToChat(chef, "%s : Vous avez viré %N.", LOGO, target);
}

static void AddPlayers(Menu menu, int exclude, int jobMin, int jobMax, bool aliveOnly)
{
	char userid[12], display[MAX_NAME_LENGTH + 16];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == exclude || !IsClientInGame(i) || !g_Loaded[i] || g_Job[i] < jobMin || g_Job[i] > jobMax
		 || (aliveOnly && !IsPlayerAlive(i)))
		{
			continue;
		}
		IntToString(GetClientUserId(i), userid, sizeof(userid));
		FormatEx(display, sizeof(display), "%N (%s)", i, userid);
		menu.AddItem(userid, display);
	}
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "Personne", ITEMDRAW_DISABLED);
	}
}

public Action Command_JobMenu(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "sm_rp_jobmenu", ADMFLAG_ROOT))
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_JobMenuPlayer);
	menu.SetTitle("Choisis le joueur :");
	AddPlayers(menu, 0, 0, JOB_COUNT - 1, false);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_JobMenuPlayer(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		g_MenuTarget[client] = StringToInt(info);
		int target = GetClientOfUserId(g_MenuTarget[client]);
		if (target == 0)
		{
			return 0;
		}
		Menu jobs = new Menu(Menu_JobMenuJob);
		jobs.SetTitle("Choisis le job de : %N :", target);
		for (int job = 1; job < JOB_COUNT; job++)
		{
			IntToString(job, info, sizeof(info));
			jobs.AddItem(info, JOB_NAME[job]);
		}
		jobs.AddItem("0", JOB_NAME[0]);
		jobs.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_JobMenuJob(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(g_MenuTarget[client]);
		int job = StringToInt(info);
		if (target != 0 && job >= 0 && job < JOB_COUNT && CheckCommandAccess(client, "sm_rp_jobmenu", ADMFLAG_ROOT))
		{
			SetJob(target, job);
			PrintToChat(target, "%s : Vous êtes désormais %s.", LOGO, JOB_NAME[job]);
			PrintToChat(client, "%s : %N est désormais %s.", LOGO, target, JOB_NAME[job]);
			LogAction(client, target, "\"%L\" a donné le métier %s à \"%L\"", client, JOB_NAME[job], target);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Command_Money(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	if (g_Job[client] != 1)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (args >= 2)
	{
		char arg[MAX_NAME_LENGTH], amount[12];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, amount, sizeof(amount));
		int target = FindTarget(client, arg, false, false);
		if (target != -1)
		{
			GiveBankMoney(client, target, StringToInt(amount));
		}
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_MoneyPlayer);
	menu.SetTitle("Choisis le joueur :");
	AddPlayers(menu, 0, 0, JOB_COUNT - 1, true);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_MoneyPlayer(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		g_MenuTarget[client] = StringToInt(info);
		int target = GetClientOfUserId(g_MenuTarget[client]);
		if (target == 0)
		{
			return 0;
		}
		Menu amounts = new Menu(Menu_MoneyAmount);
		amounts.SetTitle("Choisis le montant : %N :", target);
		amounts.AddItem("1000", "1000");
		amounts.AddItem("10000", "10000");
		amounts.AddItem("100000", "100000");
		amounts.AddItem("1000000", "1000000");
		amounts.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_MoneyAmount(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[12];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(g_MenuTarget[client]);
		if (target != 0)
		{
			GiveBankMoney(client, target, StringToInt(info));
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void GiveBankMoney(int client, int target, int amount)
{
	if (g_Job[client] != 1 || g_Jailed[client] || !g_Loaded[target])
	{
		return;
	}
	if (amount != 1000 && amount != 10000 && amount != 100000 && amount != 1000000)
	{
		PrintToChat(client, "%s : Montant possible : 1000, 10000, 100000 ou 1000000.", LOGO);
		return;
	}
	if (amount > MAX_BANK - g_Bank[target])
	{
		PrintToChat(client, "%s : La banque de %N est pleine.", LOGO, target);
		return;
	}
	g_Bank[target] += amount;
	PrintToChat(target, "%s : Vous avez reçu %d$ en banque par %N.", LOGO, amount, client);
	PrintToChat(client, "%s : Vous avez donné %d$ à %N.", LOGO, amount, target);
	LogAction(client, target, "\"%L\" (Chef d'état) a versé %d$ en banque à \"%L\"", client, amount, target);
}
