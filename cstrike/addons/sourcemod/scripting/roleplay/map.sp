enum
{
	ZONE_DISTRIB_EBAY, ZONE_DISTRIB_LOTO, ZONE_DISTRIB_MAFIA, ZONE_DISTRIB_BANQUE, ZONE_PLACE, ZONE_COMICO,
	ZONE_FBI, ZONE_ARMU, ZONE_HOSTO, ZONE_DEALER, ZONE_MAFIA, ZONE_LOTO, ZONE_BANK, ZONE_EBAY, ZONE_COACH,
	ZONE_JAIL1, ZONE_JAIL2, ZONE_JAIL3, ZONE_JAIL4,
	ZONE_COUNT
}

char ZONE_KEY[ZONE_COUNT][] =
{
	"distrib_ebay", "distrib_loto", "distrib_mafia", "distrib_banque", "place", "comico", "fbi", "armu",
	"hosto", "dealer", "mafia", "loto", "bank", "ebay", "coach", "jail1", "jail2", "jail3", "jail4"
};

char ZONE_NAME[ZONE_COUNT][] =
{
	"Distributeur Ebay", "Distributeur Atlantic", "Distributeur Mafia", "Distributeur Banque", "Place Marchande",
	"Commissariat", "F.B.I", "Armurerie", "Hôpital", "Planque des Dealers", "Planque Mafia", "Loto",
	"Banque d'oviscity", "Ebay", "Planque Coach", "Cellule n° 1", "Cellule n° 2", "Cellule n° 3", "Cellule n° 4"
};

int GROUP_ZONE[GROUP_COUNT] =
{
	-1, ZONE_COMICO, ZONE_MAFIA, ZONE_DEALER, ZONE_COACH, ZONE_EBAY, ZONE_ARMU, ZONE_LOTO, ZONE_BANK, ZONE_HOSTO
};

#define MAX_BOXES 4
#define MAX_POINTS 32
#define MAX_MAP_WEAPONS 16

float g_ZoneMin[ZONE_COUNT][MAX_BOXES][3];
float g_ZoneMax[ZONE_COUNT][MAX_BOXES][3];
int g_ZoneBoxes[ZONE_COUNT];

float g_Spawn[MAX_POINTS][3];
int g_SpawnCount;
float g_Cell[MAX_POINTS][3];
int g_CellCount;
float g_CssSpawn[MAX_POINTS][3];
int g_CssSpawnCount;
float g_Expel[GROUP_COUNT][3];
bool g_HasExpel[GROUP_COUNT];

char g_MapWeapon[MAX_MAP_WEAPONS][32];
float g_MapWeaponPos[MAX_MAP_WEAPONS][3];
int g_MapWeaponCount;
int g_MapWeaponEnt[MAX_MAP_WEAPONS];
int g_MapWeaponRespawn[MAX_MAP_WEAPONS];

int g_TourismHammerId;
float g_TourismDistance = 300.0;

void Map_Load()
{
	g_SpawnCount = 0;
	g_CellCount = 0;
	g_CssSpawnCount = 0;
	g_MapWeaponCount = 0;
	g_TourismHammerId = 0;
	for (int z = 0; z < ZONE_COUNT; z++)
	{
		g_ZoneBoxes[z] = 0;
	}
	for (int g = 0; g < GROUP_COUNT; g++)
	{
		g_HasExpel[g] = false;
	}

	char map[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, path, sizeof(path), "configs/roleplay/%s.cfg", map);

	KeyValues kv = new KeyValues("Roleplay");
	if (!kv.ImportFromFile(path))
	{
		LogMessage("Pas de configuration pour la carte %s (%s) : ni zones, ni apparitions, ni cellules", map, path);
		delete kv;
		return;
	}

	char buffer[128];
	if (kv.JumpToKey("zones"))
	{
		for (int z = 0; z < ZONE_COUNT; z++)
		{
			if (!kv.JumpToKey(ZONE_KEY[z]))
			{
				continue;
			}
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetString(NULL_STRING, buffer, sizeof(buffer));
					float v[6];
					if (g_ZoneBoxes[z] < MAX_BOXES && ParseFloats(buffer, v, 6))
					{
						int b = g_ZoneBoxes[z]++;
						for (int i = 0; i < 3; i++)
						{
							g_ZoneMin[z][b][i] = v[i] < v[i + 3] ? v[i] : v[i + 3];
							g_ZoneMax[z][b][i] = v[i] < v[i + 3] ? v[i + 3] : v[i];
						}
					}
					else
					{
						LogError("%s : boîte invalide pour la zone %s : « %s »", path, ZONE_KEY[z], buffer);
					}
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
		kv.GoBack();
	}

	g_SpawnCount = ReadPoints(kv, "apparitions", g_Spawn, path);
	g_CellCount = ReadPoints(kv, "cellules", g_Cell, path);
	g_CssSpawnCount = ReadPoints(kv, "apparitions_css", g_CssSpawn, path);

	if (kv.JumpToKey("expulsions"))
	{
		for (int g = 1; g < GROUP_COUNT; g++)
		{
			kv.GetString(GROUP_KEY[g], buffer, sizeof(buffer));
			if (buffer[0] != '\0')
			{
				g_HasExpel[g] = ParseFloats(buffer, g_Expel[g], 3);
			}
		}
		kv.GoBack();
	}

	if (kv.JumpToKey("armes") && kv.GotoFirstSubKey())
	{
		do
		{
			if (g_MapWeaponCount >= MAX_MAP_WEAPONS)
			{
				break;
			}
			int w = g_MapWeaponCount;
			kv.GetString("arme", g_MapWeapon[w], sizeof(g_MapWeapon[]));
			kv.GetString("position", buffer, sizeof(buffer));
			if (StrContains(g_MapWeapon[w], "weapon_") == 0 && ParseFloats(buffer, g_MapWeaponPos[w], 3))
			{
				g_MapWeaponEnt[w] = INVALID_ENT_REFERENCE;
				g_MapWeaponRespawn[w] = 0;
				g_MapWeaponCount++;
			}
		}
		while (kv.GotoNextKey());
		kv.Rewind();
	}
	kv.Rewind();

	if (kv.JumpToKey("tourisme"))
	{
		g_TourismHammerId = kv.GetNum("hammerid", 0);
		g_TourismDistance = kv.GetFloat("distance", 300.0);
		kv.GoBack();
	}

	delete kv;

	int boxes = 0;
	for (int z = 0; z < ZONE_COUNT; z++)
	{
		boxes += g_ZoneBoxes[z];
	}
	LogMessage("Carte %s : %d boîtes de zones, %d apparitions, %d cellules, %d armes posées", map, boxes,
		g_SpawnCount, g_CellCount, g_MapWeaponCount);
	CreateCssSpawns(map);
}

static void CreateCssSpawns(const char[] map)
{
	static const char classes[][] = { "info_player_terrorist", "info_player_counterterrorist" };
	for (int c = 0; c < sizeof(classes); c++)
	{
		if (g_CssSpawnCount == 0 || FindEntityByClassname(-1, classes[c]) != -1)
		{
			continue;
		}
		int created = 0;
		for (int i = 0; i < g_CssSpawnCount; i++)
		{
			int ent = CreateEntityByName(classes[c]);
			if (ent != -1)
			{
				DispatchKeyValueVector(ent, "origin", g_CssSpawn[i]);
				DispatchSpawn(ent);
				created++;
			}
		}
		LogMessage("Carte %s sans %s : %d créés (apparitions_css)", map, classes[c], created);
	}
}

static int ReadPoints(KeyValues kv, const char[] section, float points[MAX_POINTS][3], const char[] path)
{
	int count = 0;
	if (kv.JumpToKey(section))
	{
		if (kv.GotoFirstSubKey(false))
		{
			char buffer[128];
			do
			{
				kv.GetString(NULL_STRING, buffer, sizeof(buffer));
				if (count < MAX_POINTS && ParseFloats(buffer, points[count], 3))
				{
					count++;
				}
				else
				{
					LogError("%s : point invalide dans « %s » : « %s »", path, section, buffer);
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	return count;
}

static bool ParseFloats(const char[] text, float[] out, int count)
{
	char parts[6][24];
	if (ExplodeString(text, " ", parts, sizeof(parts), sizeof(parts[])) != count)
	{
		return false;
	}
	for (int i = 0; i < count; i++)
	{
		if (StringToFloatEx(parts[i], out[i]) == 0)
		{
			return false;
		}
	}
	return true;
}

bool PointInZone(const float pos[3], int zone)
{
	for (int b = 0; b < g_ZoneBoxes[zone]; b++)
	{
		if (pos[0] >= g_ZoneMin[zone][b][0] && pos[0] <= g_ZoneMax[zone][b][0]
		 && pos[1] >= g_ZoneMin[zone][b][1] && pos[1] <= g_ZoneMax[zone][b][1]
		 && pos[2] >= g_ZoneMin[zone][b][2] && pos[2] <= g_ZoneMax[zone][b][2])
		{
			return true;
		}
	}
	return false;
}

bool InZone(int entity, int zone)
{
	float pos[3];
	EntityCenter(entity, pos);
	return PointInZone(pos, zone);
}

void EntityCenter(int entity, float pos[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	if (entity > MaxClients && HasEntProp(entity, Prop_Send, "m_vecMins"))
	{
		float mins[3], maxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
		for (int i = 0; i < 3; i++)
		{
			pos[i] += (mins[i] + maxs[i]) / 2.0;
		}
	}
}

void ZoneName(int client, char[] name, int maxlen)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	for (int z = 0; z < ZONE_COUNT; z++)
	{
		if (PointInZone(pos, z))
		{
			strcopy(name, maxlen, ZONE_NAME[z]);
			return;
		}
	}
	strcopy(name, maxlen, "Extérieur");
}

bool InAnyDistributor(int entity)
{
	return InZone(entity, ZONE_DISTRIB_MAFIA) || InZone(entity, ZONE_DISTRIB_LOTO)
		|| InZone(entity, ZONE_DISTRIB_BANQUE) || InZone(entity, ZONE_DISTRIB_EBAY);
}

void TeleportToRandomSpawn(int client)
{
	if (g_SpawnCount > 0)
	{
		TeleportEntity(client, g_Spawn[GetRandomInt(0, g_SpawnCount - 1)], NULL_VECTOR, NULL_VECTOR);
	}
}

void TeleportToRandomCell(int client)
{
	if (g_CellCount > 0)
	{
		TeleportEntity(client, g_Cell[GetRandomInt(0, g_CellCount - 1)], NULL_VECTOR, NULL_VECTOR);
	}
}

void MapWeapons_SpawnAll()
{
	for (int w = 0; w < g_MapWeaponCount; w++)
	{
		int ent = EntRefToEntIndex(g_MapWeaponEnt[w]);
		if (ent != INVALID_ENT_REFERENCE && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == -1)
		{
			AcceptEntityInput(ent, "Kill");
		}
		MapWeapons_Spawn(w);
	}
}

static void MapWeapons_Spawn(int w)
{
	g_MapWeaponRespawn[w] = 0;
	int ent = CreateEntityByName(g_MapWeapon[w]);
	if (ent == -1)
	{
		g_MapWeaponEnt[w] = INVALID_ENT_REFERENCE;
		return;
	}
	DispatchSpawn(ent);
	TeleportEntity(ent, g_MapWeaponPos[w], NULL_VECTOR, NULL_VECTOR);
	g_MapWeaponEnt[w] = EntIndexToEntRef(ent);
}

void MapWeapons_OnEquip(int weapon)
{
	for (int w = 0; w < g_MapWeaponCount; w++)
	{
		if (g_MapWeaponEnt[w] != INVALID_ENT_REFERENCE && EntRefToEntIndex(g_MapWeaponEnt[w]) == weapon)
		{
			g_MapWeaponEnt[w] = INVALID_ENT_REFERENCE;
			g_MapWeaponRespawn[w] = 10;
		}
	}
}

void MapWeapons_Tick()
{
	for (int w = 0; w < g_MapWeaponCount; w++)
	{
		if (g_MapWeaponRespawn[w] > 0 && --g_MapWeaponRespawn[w] == 0)
		{
			MapWeapons_Spawn(w);
		}
	}
}
