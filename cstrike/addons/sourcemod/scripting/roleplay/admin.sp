void Admin_Init()
{
	RegAdminCmd("sm_rp_set", Command_RpSet, ADMFLAG_ROOT,
		"sm_rp_set <#userid|nom> <job|cash|bank|jail|rib|cb|permislourd|permisleger|<objet>> <valeur> | sm_rp_set clock <minutes>");
	RegAdminCmd("sm_rp_save", Command_RpSave, ADMFLAG_ROOT, "Sauvegarde tout de suite tous les joueurs et le capital");
	RegAdminCmd("sm_rp_capital", Command_RpCapital, ADMFLAG_ROOT, "sm_rp_capital [valeur] : affiche ou règle le capital des entreprises");
	g_cvSaveBots = CreateConVar("sm_rp_save_bots", "0", "Tests : 1 = les bots ont un profil en base (steam_id BOT_<nom>)", _, true, 0.0, true, 1.0);
}

public Action Command_RpSet(int client, int args)
{
	char arg[MAX_NAME_LENGTH], field[32], value[16];
	GetCmdArg(1, arg, sizeof(arg));
	if (StrEqual(arg, "clock") && args >= 2)
	{
		GetCmdArg(2, value, sizeof(value));
		int minutes = StringToInt(value);
		g_Clock = minutes < 0 ? 0 : minutes % (24 * 60);
		ReplyToCommand(client, "[CSS-RP] Horloge : %02d:%02d", g_Clock / 60, g_Clock % 60);
		return Plugin_Handled;
	}
	if (args < 3)
	{
		ReplyToCommand(client, "[CSS-RP] Usage : sm_rp_set <#userid|nom> <champ> <valeur> | sm_rp_set clock <minutes>");
		return Plugin_Handled;
	}
	GetCmdArg(2, field, sizeof(field));
	GetCmdArg(3, value, sizeof(value));
	int v = StringToInt(value);

	int target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	if (!g_Loaded[target])
	{
		ReplyToCommand(client, "[CSS-RP] Le profil de %N n'est pas encore chargé.", target);
		return Plugin_Handled;
	}

	if (StrEqual(field, "job"))
	{
		if (v < 0 || v >= JOB_COUNT)
		{
			ReplyToCommand(client, "[CSS-RP] Métier entre 0 et %d.", JOB_COUNT - 1);
			return Plugin_Handled;
		}
		SetJob(target, v);
	}
	else if (StrEqual(field, "cash"))
	{
		SetCash(target, v);
	}
	else if (StrEqual(field, "bank"))
	{
		g_Bank[target] = v < 0 ? 0 : (v > MAX_BANK ? MAX_BANK : v);
	}
	else if (StrEqual(field, "jail"))
	{
		if (v > 0)
		{
			g_Jailed[target] = true;
			g_JailPending[target] = false;
			g_CautionCrime[target] = -1;
			g_JailTime[target] = v;
			if (IsPlayerAlive(target))
			{
				Grab_ReleaseAllOf(target);
				TeleportToRandomCell(target);
			}
			SetVoice(target, false);
		}
		else if (g_Jailed[target])
		{
			g_JailTime[target] = 1;
		}
	}
	else if (StrEqual(field, "rib"))
	{
		g_RIB[target] = v;
	}
	else if (StrEqual(field, "cb"))
	{
		g_CB[target] = v;
	}
	else if (StrEqual(field, "permislourd"))
	{
		g_PermisLourd[target] = v;
	}
	else if (StrEqual(field, "permisleger"))
	{
		g_PermisLeger[target] = v;
	}
	else
	{
		int item = -1;
		for (int i = 0; i < ITEM_COUNT; i++)
		{
			if (StrEqual(field, ITEM_COLUMN[i]))
			{
				item = i;
				break;
			}
		}
		if (item == -1)
		{
			ReplyToCommand(client, "[CSS-RP] Champ inconnu : %s", field);
			return Plugin_Handled;
		}
		g_Item[target][item] = Max(v, 0);
	}
	ReplyToCommand(client, "[CSS-RP] %N : %s = %d", target, field, v);
	LogAction(client, target, "\"%L\" a mis %s = %d pour \"%L\"", client, field, v, target);
	return Plugin_Handled;
}

public Action Command_RpSave(int client, int args)
{
	DB_SaveAll();
	ReplyToCommand(client, "[CSS-RP] Sauvegarde envoyée à la base.");
	return Plugin_Handled;
}

public Action Command_RpCapital(int client, int args)
{
	if (args >= 1)
	{
		char value[16];
		GetCmdArg(1, value, sizeof(value));
		g_Capital = Max(StringToInt(value), 0);
		DB_SaveCapital();
		LogAction(client, -1, "\"%L\" a réglé le capital à %d$", client, g_Capital);
	}
	ReplyToCommand(client, "[CSS-RP] Capital : %d$", g_Capital);
	return Plugin_Handled;
}
