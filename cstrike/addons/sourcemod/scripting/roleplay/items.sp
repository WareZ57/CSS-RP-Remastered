enum
{
	DRUG_NONE,
	DRUG_HEROINE,
	DRUG_COKE,
	DRUG_LSD,
	DRUG_EXTA
}

int g_Drug[MAXPLAYERS + 1];

#define FURNITURE_PER_PLAYER 5
#define FURNITURE_MAX 50
int g_FurnitureRef[FURNITURE_MAX] = { INVALID_ENT_REFERENCE, ... };
int g_FurnitureOwner[FURNITURE_MAX];

public Action Command_Item(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous devez être en vie pour ouvrir votre sac.", LOGO);
		return Plugin_Handled;
	}
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas ouvrir votre sac en prison.", LOGO);
		return Plugin_Handled;
	}
	char info[24], display[64];
	if (args >= 1)
	{
		GetCmdArg(1, info, sizeof(info));
		for (int item = 0; item < ITEM_COUNT; item++)
		{
			if (StrEqual(info, ITEM_COLUMN[item], false) && item != ITEM_LEVELCUT)
			{
				if (g_Item[client][item] > 0)
				{
					UseItem(client, item);
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas cet objet.", LOGO);
				}
				return Plugin_Handled;
			}
		}
		PrintToChat(client, "%s : Objet inconnu : %s", LOGO, info);
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_Item);
	menu.SetTitle("Voici ce que contient ton sac :");
	for (int i = 0; i < sizeof(INVENTORY_ORDER); i++)
	{
		int item = INVENTORY_ORDER[i];
		if (g_Item[client][item] > 0)
		{
			IntToString(item, info, sizeof(info));
			FormatEx(display, sizeof(display), "%s [%d]", ITEM_LABEL[item], g_Item[client][item]);
			menu.AddItem(info, display);
		}
	}
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "Votre sac est vide.", ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Item(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int item = StringToInt(info);
		if (IsClientInGame(client) && IsPlayerAlive(client) && !g_Jailed[client] && item >= 0 && item < ITEM_COUNT && g_Item[client][item] > 0)
		{
			UseItem(client, item);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void UseItem(int client, int item)
{
	if (ITEM_WEAPON[item][0] != '\0')
	{
		GivePlayerItem(client, ITEM_WEAPON[item]);
		g_Item[client][item]--;
		PrintToChat(client, "%s : Vous avez utilisé : %s.", LOGO, ITEM_LABEL[item]);
		return;
	}
	switch (item)
	{
		case ITEM_KIT:
		{
			Lockpick_Start(client);
		}
		case ITEM_TICKET10:
		{
			Scratch(client, item, 30, 5);
		}
		case ITEM_TICKET100:
		{
			Scratch(client, item, 300, 70);
		}
		case ITEM_TICKET1000:
		{
			Scratch(client, item, 3000, 700);
		}
		case ITEM_CARTOUCHE:
		{
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weapon == -1)
			{
				weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			}
			if (weapon == -1)
			{
				PrintToChat(client, "%s : Vous n'avez pas d'arme à recharger.", LOGO);
				return;
			}
			int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			if (ammoType >= 0)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", 90, _, ammoType);
			}
			g_Item[client][item]--;
			PrintToChat(client, "%s : Vous avez utilisé une CARTOUCHE.", LOGO);
		}
		case ITEM_PROPS1, ITEM_PROPS2:
		{
			if (SpawnFurniture(client, item == ITEM_PROPS1 ? MODEL_PROPS1 : MODEL_PROPS2))
			{
				g_Item[client][item]--;
				PrintToChat(client, "%s : Vous avez posé : %s.", LOGO, ITEM_LABEL[item]);
			}
		}
		case ITEM_HEROINE:
		{
			TakeDrug(client, item, DRUG_HEROINE, 500, 1.0, 1.5);
		}
		case ITEM_COKE:
		{
			TakeDrug(client, item, DRUG_COKE, 300, 0.5, 1.0);
		}
		case ITEM_LSD:
		{
			TakeDrug(client, item, DRUG_LSD, 200, 0.5, 1.2);
		}
		case ITEM_EXTA:
		{
			TakeDrug(client, item, DRUG_EXTA, 150, 0.5, 1.2);
		}
	}
}

static void Scratch(int client, int item, int big, int small)
{
	g_Item[client][item]--;
	PrintToChat(client, "%s : Vous avez utilisé un %s.", LOGO, ITEM_LABEL[item]);
	switch (GetRandomInt(1, 10))
	{
		case 2:
		{
			AddCash(client, big);
			PrintToChat(client, "%s : Vous avez gagné %d$.", LOGO, big);
		}
		case 3:
		{
			AddCash(client, small);
			PrintToChat(client, "%s : Vous avez gagné %d$.", LOGO, small);
		}
		default:
		{
			PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
		}
	}
}

static void TakeDrug(int client, int item, int drug, int health, float gravity, float speed)
{
	if (g_DrugLeft[client] > 0)
	{
		PrintToChat(client, "%s : Vous êtes déjà en train d'utiliser une drogue.", LOGO);
		return;
	}
	g_Item[client][item]--;
	g_Drug[client] = drug;
	g_DrugLeft[client] = DRUG_DURATION;
	SetEntityHealth(client, health);
	SetEntityGravity(client, gravity);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
	PrintToChat(client, "%s : Vous avez pris : %s.", LOGO, ITEM_LABEL[item]);
}

void Items_TickDrug(int client)
{
	if (g_DrugLeft[client] <= 0 || --g_DrugLeft[client] > 0)
	{
		return;
	}
	g_Drug[client] = DRUG_NONE;
	if (IsPlayerAlive(client))
	{
		SetEntityGravity(client, 1.0);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		PrintToChat(client, "%s : Votre drogue ne fait plus d'effet.", LOGO);
	}
}

void Items_OnDeath(int client)
{
	g_DrugLeft[client] = 0;
	g_Drug[client] = DRUG_NONE;
	g_LockpickLeft[client] = 0;
}

void Furniture_RemoveAllOf(int client)
{
	if (!IsClientConnected(client))
	{
		return;
	}
	int userid = GetClientUserId(client);
	for (int i = 0; i < FURNITURE_MAX; i++)
	{
		int ent = EntRefToEntIndex(g_FurnitureRef[i]);
		if (ent != INVALID_ENT_REFERENCE && g_FurnitureOwner[i] == userid)
		{
			AcceptEntityInput(ent, "Kill");
		}
		if (ent == INVALID_ENT_REFERENCE || g_FurnitureOwner[i] == userid)
		{
			g_FurnitureRef[i] = INVALID_ENT_REFERENCE;
		}
	}
}

static int Furniture_FreeSlot(int client)
{
	int userid = GetClientUserId(client), owned = 0, free = -1;
	for (int i = 0; i < FURNITURE_MAX; i++)
	{
		if (EntRefToEntIndex(g_FurnitureRef[i]) == INVALID_ENT_REFERENCE)
		{
			if (free == -1)
			{
				free = i;
			}
		}
		else if (g_FurnitureOwner[i] == userid)
		{
			owned++;
		}
	}
	if (owned >= FURNITURE_PER_PLAYER)
	{
		PrintToChat(client, "%s : Vous avez déjà posé %d meubles.", LOGO, FURNITURE_PER_PLAYER);
		return -1;
	}
	if (free == -1)
	{
		PrintToChat(client, "%s : Trop de meubles sur le serveur.", LOGO);
	}
	return free;
}

static bool SpawnFurniture(int client, const char[] model)
{
	int slot = Furniture_FreeSlot(client);
	if (slot == -1)
	{
		return false;
	}

	float eyes[3], angles[3], forwardVec[3], pos[3];
	GetClientEyePosition(client, eyes);
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0;
	GetAngleVectors(angles, forwardVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(forwardVec, 64.0);
	AddVectors(eyes, forwardVec, pos);

	Handle trace = TR_TraceRayFilterEx(eyes, pos, MASK_SOLID, RayType_EndPoint, Filter_NotSelf, client);
	bool blocked = TR_DidHit(trace);
	delete trace;
	if (blocked)
	{
		PrintToChat(client, "%s : Pas assez de place ici.", LOGO);
		return false;
	}

	int ent = CreateEntityByName("prop_physics_override");
	if (ent == -1)
	{
		return false;
	}
	DispatchKeyValue(ent, "model", model);
	DispatchKeyValue(ent, "spawnflags", "256");
	DispatchSpawn(ent);
	pos[2] -= 40.0;
	TeleportEntity(ent, pos, angles, NULL_VECTOR);
	g_FurnitureRef[slot] = EntIndexToEntRef(ent);
	g_FurnitureOwner[slot] = GetClientUserId(client);
	return true;
}
