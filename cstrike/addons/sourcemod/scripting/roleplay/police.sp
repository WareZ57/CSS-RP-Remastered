public Action Command_Enquete(int client, int args)
{
	if (!PoliceCommand(client))
	{
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0)
	{
		PrintToChat(client, "%s : Vous devez viser un joueur.", LOGO);
		return Plugin_Handled;
	}
	char steamid[32];
	if (!GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		strcopy(steamid, sizeof(steamid), "inconnu");
	}
	PrintToChat(client, "%s : Pseudo : %N  ||  Steam ID : %s", LOGO, target, steamid);
	PrintToChat(client, "%s : Level CUT : %d  ||  HP : %d", LOGO, g_Item[target][ITEM_LEVELCUT], GetClientHealth(target));
	PrintToChat(client, "%s : Permis Lourd : %s  ||  Permis Léger : %s", LOGO,
		g_PermisLourd[target] > 0 ? "Oui" : "Non", g_PermisLeger[target] > 0 ? "Oui" : "Non");
	PrintToChat(client, "%s : Temps de prison : %d", LOGO, g_JailTime[target]);
	return Plugin_Handled;
}

public Action Command_Del(int client, int args)
{
	if (!PoliceCommand(client))
	{
		return Plugin_Handled;
	}
	int ent = GetClientAimTarget(client, false);
	char classname[32];
	if (ent > MaxClients && GetEntityClassname(ent, classname, sizeof(classname)) && StrContains(classname, "weapon_") == 0
	 && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == -1)
	{
		AcceptEntityInput(ent, "Kill");
		PrintToChat(client, "%s : Vous avez supprimé l'arme au sol.", LOGO);
	}
	else
	{
		PrintToChat(client, "%s : Ce n'est pas une arme au sol.", LOGO);
	}
	return Plugin_Handled;
}

public Action Command_Perqui(int client, int args)
{
	if (!PoliceCommand(client))
	{
		return Plugin_Handled;
	}
	PrintToChatAll("%s : Perquisition de la \x04Police ! \x03Pas de résistance !", LOGO);
	PrintToChatAll("%s : \x04%N \x03dirige la perquisition !", LOGO, client);
	return Plugin_Handled;
}

public Action Command_Armurerie(int client, int args)
{
	if (!PoliceCommand(client))
	{
		return Plugin_Handled;
	}
	int job = g_Job[client];
	if (job < 1 || job > 5)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	char steamid[32];
	if (args >= 1)
	{
		char arg[24], weapon[32];
		GetCmdArg(1, arg, sizeof(arg));
		FormatEx(weapon, sizeof(weapon), "weapon_%s", arg);
		if (!GivePoliceWeapon(client, weapon))
		{
			PrintToChat(client, "%s : Arme non disponible pour votre grade : %s", LOGO, arg);
		}
		return Plugin_Handled;
	}
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	Menu menu = new Menu(Menu_Armurerie);
	menu.SetTitle("Choisis ton arme : %N (%s) :", client, steamid);
	for (int i = ARMU_POLICE_FIRST[job]; i < sizeof(ARMU_POLICE_KEY); i++)
	{
		menu.AddItem(ARMU_POLICE_KEY[i], ARMU_POLICE_LABEL[i]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Armurerie(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char weapon[32];
		menu.GetItem(param2, weapon, sizeof(weapon));
		GivePoliceWeapon(client, weapon);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static bool GivePoliceWeapon(int client, const char[] weapon)
{
	int job = g_Job[client];
	if (!IsPlayerAlive(client) || g_Jailed[client] || GetClientTeam(client) != CS_TEAM_CT || job < 1 || job > 5)
	{
		return false;
	}
	for (int i = ARMU_POLICE_FIRST[job]; i < sizeof(ARMU_POLICE_KEY); i++)
	{
		if (StrEqual(weapon, ARMU_POLICE_KEY[i], false))
		{
			GivePlayerItem(client, ARMU_POLICE_KEY[i]);
			return true;
		}
	}
	return false;
}

static bool PoliceCommand(int client)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return false;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		return false;
	}
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return false;
	}
	return !InJail(client);
}

public Action Command_Out(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0)
	{
		PrintToChat(client, "%s : Vous devez viser un joueur.", LOGO);
		return Plugin_Handled;
	}
	if (g_Jailed[target])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas expulser un prisonnier.", LOGO);
		return Plugin_Handled;
	}
	int group = GetClientTeam(client) == CS_TEAM_CT ? GROUP_ETAT : JOB_GROUP[g_Job[client]];
	if (group == GROUP_NONE || (group == GROUP_ETAT && GetClientTeam(client) != CS_TEAM_CT))
	{
		PrintToChat(client, "%s : Vous n'avez pas de planque.", LOGO);
		return Plugin_Handled;
	}
	if (!InHome(client, group))
	{
		PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
		return Plugin_Handled;
	}
	if (!InHome(target, group))
	{
		PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, target);
		return Plugin_Handled;
	}
	if (!g_HasExpel[group])
	{
		PrintToChat(client, "%s : Aucun point d'expulsion n'est configuré pour cette carte.", LOGO);
		return Plugin_Handled;
	}
	Grab_ReleaseAllOf(target);
	TeleportEntity(target, g_Expel[group], NULL_VECTOR, NULL_VECTOR);
	PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, target);
	PrintToChat(target, "%s : Vous avez été expulsé par %N.", LOGO, client);
	return Plugin_Handled;
}

static bool InHome(int client, int group)
{
	if (group == GROUP_ETAT)
	{
		return InZone(client, ZONE_COMICO) || InZone(client, ZONE_FBI);
	}
	return GROUP_ZONE[group] != -1 && InZone(client, GROUP_ZONE[group]);
}

public Action Command_Vis(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (g_Job[client] != 1 && g_Job[client] != 2)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous devez être en vie pour utiliser cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (InJail(client))
	{
		return Plugin_Handled;
	}
	g_Invisible[client] = !g_Invisible[client];
	RenderMode mode = g_Invisible[client] ? RENDER_NONE : RENDER_NORMAL;
	int alpha = g_Invisible[client] ? 0 : 255;
	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, 255, 255, 255, alpha);
	for (int slot = 0; slot < 6; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon != -1)
		{
			SetEntityRenderMode(weapon, mode);
			SetEntityRenderColor(weapon, 255, 255, 255, alpha);
		}
	}
	PrintToChat(client, g_Invisible[client] ? "%s : Vous êtes désormais invisible." : "%s : Vous êtes désormais visible.", LOGO);
	return Plugin_Handled;
}

public Action Command_ChangeName(int client, int args)
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
	if (args < 1)
	{
		ReplyToCommand(client, "[CSS-RP] Usage : sm_changename <pseudo>");
		return Plugin_Handled;
	}
	char name[MAX_NAME_LENGTH], old[MAX_NAME_LENGTH];
	GetCmdArgString(name, sizeof(name));
	StripQuotes(name);
	for (int i = 0; name[i] != '\0'; i++)
	{
		if (name[i] > 0 && name[i] < 32)
		{
			name[i] = ' ';
		}
	}
	if (strlen(name) > 31)
	{
		int cut = 31;
		while (cut > 0 && (name[cut] & 0xC0) == 0x80)
		{
			cut--;
		}
		name[cut] = '\0';
	}
	TrimString(name);
	if (name[0] == '\0')
	{
		return Plugin_Handled;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i))
		{
			GetClientName(i, old, sizeof(old));
			if (StrEqual(old, name, false))
			{
				PrintToChat(client, "%s : Ce pseudo est déjà pris.", LOGO);
				return Plugin_Handled;
			}
		}
	}
	GetClientName(client, old, sizeof(old));
	SetClientName(client, name);
	LogAction(client, -1, "\"%L\" (Chef d'état) a changé de pseudo : « %s » → « %s »", client, old, name);
	return Plugin_Handled;
}

public Action Command_Ent(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "sm_rp_ent", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	int ent = GetClientAimTarget(client, false);
	if (ent <= 0)
	{
		PrintToChat(client, "%s : Aucune entité visée.", LOGO);
		return Plugin_Handled;
	}
	char classname[64], targetname[64], model[PLATFORM_MAX_PATH];
	float pos[3];
	GetEntityClassname(ent, classname, sizeof(classname));
	GetEntPropString(ent, Prop_Data, "m_iName", targetname, sizeof(targetname));
	GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
	EntityCenter(ent, pos);
	int hammerid = GetEntProp(ent, Prop_Data, "m_iHammerID");
	PrintToChat(client, "%s : Entité <=> %d (%s), hammerid %d", LOGO, ent, classname, hammerid);
	PrintToConsole(client, "[CSS-RP] Entité %d : classe %s, hammerid %d, nom « %s », modèle %s, centre %.1f %.1f %.1f",
		ent, classname, hammerid, targetname, model, pos[0], pos[1], pos[2]);
	return Plugin_Handled;
}
