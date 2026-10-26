bool IsDoor(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrEqual(classname, "func_door") || StrEqual(classname, "func_door_rotating") || StrEqual(classname, "prop_door_rotating");
}

bool IsLocked(int door)
{
	return HasEntProp(door, Prop_Data, "m_bLocked") && GetEntProp(door, Prop_Data, "m_bLocked") != 0;
}

void Doors_RoundStart()
{
	static const char classes[][] = { "func_door_rotating", "prop_door_rotating", "func_door" };
	for (int c = 0; c < sizeof(classes); c++)
	{
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, classes[c])) != -1)
		{
			AcceptEntityInput(ent, InZone(ent, ZONE_LOTO) ? "Unlock" : "Lock");
		}
	}
	PrintToChatAll("%s : Les portes du serveur ont été fermées à clef.", LOGO);

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "point_servercommand")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

bool HasKey(int client, int door)
{
	int job = g_Job[client];
	if (job >= 1 && job <= 3)
	{
		return true;
	}
	int zone = GROUP_ZONE[JOB_GROUP[job]];
	return zone != -1 && InZone(door, zone);
}

public Action Command_Lock(int client, int args)
{
	LockCommand(client, true);
	return Plugin_Handled;
}

public Action Command_Unlock(int client, int args)
{
	LockCommand(client, false);
	return Plugin_Handled;
}

static void LockCommand(int client, bool lock)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || InJail(client))
	{
		return;
	}
	int door = GetClientAimTarget(client, false);
	if (!IsDoor(door))
	{
		PrintToChat(client, "%s : Vous devez viser une porte.", LOGO);
		return;
	}
	if (DistanceTo(client, door) > REACH)
	{
		PrintToChat(client, "%s : Vous êtes trop loin de la porte.", LOGO);
		return;
	}
	if (!HasKey(client, door))
	{
		PrintToChat(client, "%s : Vous n'avez pas les clefs de cette porte.", LOGO);
		return;
	}
	if (lock)
	{
		if (IsLocked(door))
		{
			PrintToChat(client, "%s : La porte est déjà fermée à clef.", LOGO);
			return;
		}
		AcceptEntityInput(door, "Lock");
		EmitSoundToAll(SOUND_LOCK, door);
		PrintToChat(client, "%s : Vous avez fermé la porte à clef.", LOGO);
	}
	else
	{
		if (!IsLocked(door))
		{
			PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
			return;
		}
		AcceptEntityInput(door, "Unlock");
		EmitSoundToAll(SOUND_UNLOCK, door);
		PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
	}
	PrintToConsole(client, "[CSS-RP] : Porte %d %s.", door, lock ? "fermée à clef" : "ouverte");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	Action result = Flashball_OnRunCmd(client, buttons, vel);
	UseKey(client, buttons);
	return result;
}

static void UseKey(int client, int buttons)
{
	if (!(buttons & IN_USE))
	{
		g_UseHeld[client] = false;
		return;
	}
	if (g_UseHeld[client] || !IsPlayerAlive(client) || !g_Loaded[client])
	{
		return;
	}
	g_UseHeld[client] = true;

	int ent = GetClientAimTarget(client, false);
	if (ent <= MaxClients)
	{
		return;
	}
	if (IsDoor(ent))
	{
		char classname[32];
		GetEntityClassname(ent, classname, sizeof(classname));
		if (IsLocked(ent))
		{
			PrintToChat(client, "%s : La porte est fermée à clef.", LOGO);
		}
		else if (StrEqual(classname, "func_door"))
		{
			AcceptEntityInput(ent, "Toggle", client, client);
		}
		return;
	}
	Shops_OnUse(client, ent);
}

void Lockpick_Start(int client)
{
	int job = g_Job[client];
	if (JOB_GROUP[job] != GROUP_MAFIA)
	{
		PrintToChat(client, "%s : Vous devez être mafieux pour utiliser cet objet.", LOGO);
		return;
	}
	if (g_LockpickLeft[client] > 0)
	{
		PrintToChat(client, "%s : Vous êtes déjà en train de crocheter.", LOGO);
		return;
	}
	int door = GetClientAimTarget(client, false);
	if (!IsDoor(door))
	{
		PrintToChat(client, "%s : Veuillez viser une porte.", LOGO);
		return;
	}
	if (!IsLocked(door))
	{
		PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
		return;
	}
	int wait = g_LastLockpick[client] + 20 - GetTime();
	if (wait > 0)
	{
		PrintToChat(client, "%s : Vous devez attendre %d secondes avant de pouvoir crocheter une porte.", LOGO, wait);
		return;
	}
	if (DistanceTo(client, door) > 80.0)
	{
		PrintToChat(client, "%s : Vous êtes trop loin pour crocheter cette porte.", LOGO);
		return;
	}
	g_LastLockpick[client] = GetTime();
	g_LockpickLeft[client] = 8;
	g_LockpickDoor[client] = EntIndexToEntRef(door);
	g_Item[client][ITEM_KIT]--;
	SetEntityRenderColor(client, 255, 0, 0, 255);
	SetEntityMoveType(client, MOVETYPE_NONE);
	RingEffect(client, 50.0, 70.0, COLOR_RED);
	PrintToChat(client, "%s : Vous crochetez la porte.", LOGO);
	PrintToChat(client, "%s : Vous avez utilisé un kit de crochetage.", LOGO);
}

void Lockpick_Tick(int client)
{
	if (g_LockpickLeft[client] <= 0)
	{
		return;
	}
	if (!IsPlayerAlive(client))
	{
		g_LockpickLeft[client] = 0;
		return;
	}
	if (--g_LockpickLeft[client] > 0)
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		return;
	}
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	int door = EntRefToEntIndex(g_LockpickDoor[client]);
	if (door == INVALID_ENT_REFERENCE)
	{
		PrintToChat(client, "%s : La porte a disparu.", LOGO);
		return;
	}
	if (GetRandomInt(1, 2) == 2)
	{
		PrintToChat(client, "%s : Vous avez échoué le crochetage.", LOGO);
		return;
	}
	AcceptEntityInput(door, "Unlock");
	AcceptEntityInput(door, IsDoorRotatingProp(door) ? "Open" : "Toggle", client, client);
	PrintToChat(client, "%s : Vous avez crocheté la porte avec succès.", LOGO);

	g_Portes[client]++;
	static const int steps[3] = { 20, 50, 100 };
	static const char names[3][] = { "Crocheteur du dimanche", "Crocheteur expérimenté", "Crocheteur professionnel" };
	for (int i = 0; i < 3; i++)
	{
		if (g_Portes[client] == steps[i])
		{
			PrintToChatAll("%s : Le joueur %N a remporté le succès \x03%s\x01.", LOGO, client, names[i]);
			PlayCustomSound(client, 1, SOUND_SUCCESS);
			switch (i)
			{
				case 0: g_SuccesPorte20[client] = 1;
				case 1: g_SuccesPorte50[client] = 1;
				case 2: g_SuccesPorte100[client] = 1;
			}
		}
	}
}

static bool IsDoorRotatingProp(int door)
{
	char classname[32];
	GetEntityClassname(door, classname, sizeof(classname));
	return StrEqual(classname, "prop_door_rotating");
}
