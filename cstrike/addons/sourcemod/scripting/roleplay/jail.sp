int g_SpriteLaser;
int g_SpriteHalo;
int g_SpriteLightning;
int g_SpriteBeam;

float g_CautionShown[MAXPLAYERS + 1];

static const int TAZER_COLORS[5][4] =
{
	{ 255, 128, 0, 255 }, { 255, 75, 75, 255 }, { 75, 255, 75, 255 }, { 128, 128, 128, 255 }, { 75, 75, 255, 255 }
};

void Effects_Precache()
{
	g_SpriteLaser = PrecacheModel("sprites/laser.vmt");
	g_SpriteHalo = PrecacheModel("materials/sprites/halo01.vmt");
	g_SpriteLightning = PrecacheModel("sprites/lgtning.vmt");
	g_SpriteBeam = PrecacheModel("materials/sprites/laser.vmt");
}

void RingEffect(int client, float start, float end, const int color[4])
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 10.0;
	TE_SetupBeamRingPoint(pos, start, end, g_SpriteBeam, g_SpriteHalo, 0, 15, 0.6, 15.0, 0.0, color, 10, 0);
	TE_SendToAll();
}

public Action Command_Jail(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (g_Invisible[client])
	{
		PrintToChat(client, "%s : Vous devez être visible pour emprisonner.", LOGO);
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0)
	{
		PrintToChat(client, "%s : Vous devez viser un joueur.", LOGO);
		return Plugin_Handled;
	}
	if (GetClientTeam(target) != CS_TEAM_T)
	{
		PrintToChat(client, "%s : Vous ne pouvez pas emprisonner un policier.", LOGO);
		return Plugin_Handled;
	}
	if (DistanceTo(client, target) > 1000.0)
	{
		PrintToChat(client, "%s : Vous êtes trop loin pour emprisonner.", LOGO);
		return Plugin_Handled;
	}

	Grab_ReleaseAllOf(target);
	g_Jailed[target] = true;
	g_JailPending[target] = true;
	g_JailTime[target] = JAIL_PENDING_TIME;
	g_CautionCrime[target] = -1;
	g_JailCop[target] = GetClientUserId(client);
	TeleportToRandomCell(target);
	Disarm(target);
	GivePlayerItem(target, "weapon_knife");
	SetVoice(target, false);
	PrintToChat(client, "%s : Tu as emprisonné le joueur : %N", LOGO, target);
	PrintToChat(target, "%s : Tu as été emprisonné par : %N", LOGO, client);

	char info[16];
	if (args >= 1)
	{
		GetCmdArg(1, info, sizeof(info));
		for (int i = 0; i < CRIME_COUNT; i++)
		{
			if (StrEqual(info, CRIME_KEY[i]))
			{
				Crime_Apply(client, target, i);
				return Plugin_Handled;
			}
		}
		PrintToChat(client, "%s : Crime inconnu « %s » : choisissez la peine dans le menu.", LOGO, info);
	}
	Menu menu = new Menu(Menu_Crime);
	menu.SetTitle("Choisis la peine pour %N (provisoire : %d s) :", target, JAIL_PENDING_TIME);
	for (int i = 0; i < CRIME_COUNT; i++)
	{
		FormatEx(info, sizeof(info), "%d %d", GetClientUserId(target), i);
		menu.AddItem(info, CRIME_LABEL[i]);
	}
	FormatEx(info, sizeof(info), "%d -1", GetClientUserId(target));
	menu.AddItem(info, "Libérer le joueur");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Crime(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16], parts[2][8];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info, " ", parts, sizeof(parts), sizeof(parts[]));
		int target = GetClientOfUserId(StringToInt(parts[0]));
		int crime = StringToInt(parts[1]);
		if (target == 0 || !g_Jailed[target] || !g_JailPending[target] || GetClientTeam(client) != CS_TEAM_CT)
		{
			return 0;
		}
		if (crime < 0 || crime >= CRIME_COUNT)
		{
			g_JailPending[target] = false;
			g_JailTime[target] = JAIL_LIBERATION_TIME;
			return 0;
		}
		Crime_Apply(client, target, crime);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void Crime_Apply(int cop, int target, int crime)
{
	g_JailPending[target] = false;
	g_JailTime[target] = CRIME_TIME[crime];
	g_CautionCrime[target] = crime;
	PrintToChat(target, "%s : Vous avez été emprisonné pour %s.", LOGO, CRIME_REASON[crime]);
	PrintToChat(cop, "%s : La peine a bien été mise.", LOGO);
	g_CautionShown[target] = GetGameTime();
	Caution_ShowMenu(target);
	PrintToChat(target, "%s : Caution de %d$ : !accepter ou !refuser.", LOGO, CRIME_CAUTION[crime]);
}

static void Caution_ShowMenu(int target)
{
	int crime = g_CautionCrime[target];
	char info[8];
	Menu caution = new Menu(Menu_Caution);
	caution.SetTitle("Voulez-vous payer votre caution de %d$ ?", CRIME_CAUTION[crime]);
	IntToString(crime, info, sizeof(info));
	caution.AddItem(info, "Oui je veux.");
	caution.AddItem("non", "Non merci.");
	caution.Display(target, MENU_TIME_FOREVER);
}

public int Menu_Caution(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "non") || StringToInt(info) == g_CautionCrime[client])
		{
			Caution_Answer(client, !StrEqual(info, "non"));
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

bool Caution_Pending(int client)
{
	return g_CautionCrime[client] >= 0 && g_Jailed[client] && g_JailTime[client] > 0;
}

void Caution_Answer(int client, bool pay)
{
	if (pay && Caution_Pending(client) && JustProposed(client, g_CautionShown[client]))
	{
		Caution_ShowMenu(client);
		return;
	}
	int crime = g_CautionCrime[client];
	g_CautionCrime[client] = -1;
	if (crime < 0 || crime >= CRIME_COUNT || !g_Jailed[client] || g_JailTime[client] <= 0)
	{
		return;
	}
	int cop = GetClientOfUserId(g_JailCop[client]);
	if (!pay)
	{
		PrintToChat(client, "%s : Vous avez refusé de payer votre caution.", LOGO);
		if (cop != 0)
		{
			PrintToChat(cop, "%s : Le joueur %N a refusé de payer sa caution.", LOGO, client);
		}
		return;
	}
	if (Pay(client, CRIME_CAUTION[crime]))
	{
		int share = CRIME_CAUTION[crime] / 2;
		g_JailTime[client] = CRIME_REDUCED[crime];
		g_Capital += share;
		PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO);
		if (cop != 0)
		{
			AddCash(cop, share);
			PrintToChat(cop, "%s : Le joueur %N a payé sa caution.", LOGO, client);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
		if (cop != 0)
		{
			PrintToChat(cop, "%s : Le joueur n'a pas assez d'argent.", LOGO);
		}
	}
}

void Jail_Tick(int client)
{
	if (!g_Jailed[client] || g_JailTime[client] <= 0 || --g_JailTime[client] > 0)
	{
		return;
	}
	g_Jailed[client] = false;
	g_JailPending[client] = false;
	g_CautionCrime[client] = -1;
	SetVoice(client, true);
	PrintToChat(client, "%s : Vous avez été libéré de prison.", LOGO);
	if (IsPlayerAlive(client))
	{
		TeleportToRandomSpawn(client);
	}
}

void Jail_OnDeath(int client)
{
	g_TazeLeft[client] = 0;
}

public Action Command_JailList(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	char display[MAX_NAME_LENGTH + 16];
	Menu menu = new Menu(Menu_Close);
	menu.SetTitle("Liste des prisonniers");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_Jailed[i])
		{
			FormatEx(display, sizeof(display), "%N => %d s", i, g_JailTime[i]);
			menu.AddItem("", display, ITEMDRAW_DISABLED);
		}
	}
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "Aucun prisonnier", ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_Taser(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0 || GetClientTeam(target) == CS_TEAM_CT || g_TazeLeft[target] > 0)
	{
		return Plugin_Handled;
	}
	if (DistanceTo(client, target) > 10000.0)
	{
		PrintToChat(client, "%s : Vous êtes trop loin pour taser.", LOGO);
		return Plugin_Handled;
	}
	g_TazeLeft[target] = 10;
	EmitSoundToAll(SOUND_TAZER, client, _, _, _, 1.0);
	float from[3], to[3];
	GetClientAbsOrigin(client, from);
	GetClientAbsOrigin(target, to);
	from[2] += 45.0;
	to[2] += 45.0;
	TE_SetupBeamPoints(from, to, g_SpriteLightning, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORS[GetRandomInt(0, 4)], 3);
	TE_SendToAll();
	SetEntityMoveType(target, MOVETYPE_NONE);
	return Plugin_Handled;
}

void Taser_Tick(int client)
{
	if (g_TazeLeft[client] <= 0)
	{
		return;
	}
	if (!IsPlayerAlive(client) || --g_TazeLeft[client] == 0)
	{
		g_TazeLeft[client] = 0;
		if (IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		return;
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	float pos[3];
	GetClientAbsOrigin(client, pos);
	for (int i = 1; i < 8; i++)
	{
		pos[2] += i * 9;
		TE_SetupBeamRingPoint(pos, 45.0, 45.1, g_SpriteLaser, g_SpriteHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORS[GetRandomInt(0, 4)], 1, 0);
		TE_SendToAll();
		pos[2] -= i * 9;
	}
}
