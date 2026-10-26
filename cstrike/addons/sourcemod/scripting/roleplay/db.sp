Database g_DB;

#define LOAD_PLAYER 1
#define LOAD_ITEMS 2
#define LOAD_SUCCES 4
#define LOAD_ALL 7

int g_LoadParts[MAXPLAYERS + 1];

void DB_Connect()
{
	if (!SQL_CheckConfig("roleplay"))
	{
		LogError("Section « roleplay » absente de configs/databases.cfg : rien ne sera sauvegardé");
		return;
	}
	Database.Connect(DB_OnConnect, "roleplay");
}

public void DB_OnConnect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Connexion à la base roleplay impossible : %s", error);
		return;
	}
	g_DB = db;
	g_DB.SetCharset("utf8");

	char driver[16];
	g_DB.Driver.GetIdentifier(driver, sizeof(driver));
	bool sqlite = StrEqual(driver, "sqlite");

	Transaction txn = new Transaction();
	txn.AddQuery("CREATE TABLE IF NOT EXISTS Roleplay_Players (steam_id VARCHAR(32) NOT NULL PRIMARY KEY, "
		... "pseudo VARCHAR(100) NOT NULL DEFAULT '', cash INT NOT NULL DEFAULT 0, bank INT NOT NULL DEFAULT 0, "
		... "jobid INT NOT NULL DEFAULT 0, jailtime INT NOT NULL DEFAULT 0, isinjail INT NOT NULL DEFAULT 0, "
		... "permislourd INT NOT NULL DEFAULT 0, permisleger INT NOT NULL DEFAULT 0, cb INT NOT NULL DEFAULT 0, "
		... "rib INT NOT NULL DEFAULT 0, rankid INT NOT NULL DEFAULT 0)");

	char query[2048];
	int len = FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS Roleplay_item (steam_id VARCHAR(32) NOT NULL PRIMARY KEY, pseudo VARCHAR(100) NOT NULL DEFAULT ''");
	for (int i = 0; i < ITEM_COUNT; i++)
	{
		len += FormatEx(query[len], sizeof(query) - len, ", %s INT NOT NULL DEFAULT 0", ITEM_COLUMN[i]);
	}
	FormatEx(query[len], sizeof(query) - len, ", pack INT NOT NULL DEFAULT 0, kevlar INT NOT NULL DEFAULT 0)");
	txn.AddQuery(query);

	txn.AddQuery("CREATE TABLE IF NOT EXISTS Roleplay_Job (id INT NOT NULL PRIMARY KEY, capital INT NOT NULL DEFAULT 0)");
	txn.AddQuery("CREATE TABLE IF NOT EXISTS Roleplay_Succes (steam_id VARCHAR(32) NOT NULL PRIMARY KEY, "
		... "pseudo VARCHAR(50) NOT NULL DEFAULT '', headshot INT NOT NULL DEFAULT 0, countheadshot INT NOT NULL DEFAULT 0, "
		... "porte20 INT NOT NULL DEFAULT 0, porte50 INT NOT NULL DEFAULT 0, porte100 INT NOT NULL DEFAULT 0, "
		... "countporte INT NOT NULL DEFAULT 0)");

	FormatEx(query, sizeof(query), "INSERT %s INTO Roleplay_Job (id, capital) VALUES (1, 999421), (0, 734767), "
		... "(2, 1012006), (3, 993538), (4, 1000500), (5, 1000000), (6, 1002818), (7, 1000000), (8, 1006000), "
		... "(9, 1000000), (10, 1000000), (11, 1000000)", sqlite ? "OR IGNORE" : "IGNORE");
	txn.AddQuery(query);

	g_DB.Execute(txn, DB_OnSchemaReady, DB_OnSchemaError);
}

public void DB_OnSchemaReady(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	LogMessage("Base roleplay prête");
	g_DB.Query(DB_OnCapitalLoaded, "SELECT capital FROM Roleplay_Job WHERE id = 1");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsClientAuthorized(client) && !g_Loaded[client])
		{
			DB_LoadClient(client);
		}
	}
}

public void DB_OnSchemaError(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Création des tables roleplay impossible (requête %d) : %s", failIndex, error);
}

public void DB_OnCapitalLoaded(Database db, DBResultSet results, const char[] error, any data)
{
	if (results != null && results.FetchRow())
	{
		g_Capital = results.FetchInt(0);
	}
	else if (error[0] != '\0')
	{
		LogError("Lecture du capital impossible : %s", error);
	}
}

void DB_SaveCapital()
{
	if (g_DB == null)
	{
		return;
	}
	char query[128];
	FormatEx(query, sizeof(query), "UPDATE Roleplay_Job SET capital = %d WHERE id = 1", g_Capital);
	g_DB.Query(DB_OnWriteDone, query);
}

void DB_LoadClient(int client)
{
	if (IsFakeClient(client))
	{
		if (!g_cvSaveBots.BoolValue || g_DB == null)
		{
			ResetProfile(client);
			OnProfileLoaded(client);
			return;
		}
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		FormatEx(g_SteamId[client], sizeof(g_SteamId[]), "BOT_%s", name);
	}
	else if (g_DB == null)
	{
		LogError("Base roleplay indisponible : profil vierge non sauvegardé pour %N", client);
		g_SteamId[client][0] = '\0';
		ResetProfile(client);
		OnProfileLoaded(client);
		return;
	}
	else if (!GetClientAuthId(client, AuthId_Steam2, g_SteamId[client], sizeof(g_SteamId[])))
	{
		return;
	}
	g_LoadParts[client] = 0;
	int userid = GetClientUserId(client);

	char query[1024];
	g_DB.Format(query, sizeof(query), "SELECT cash, bank, jobid, jailtime, isinjail, permislourd, permisleger, cb, rib "
		... "FROM Roleplay_Players WHERE steam_id = '%s'", g_SteamId[client]);
	g_DB.Query(DB_OnPlayerLoaded, query, userid);

	int len = FormatEx(query, sizeof(query), "SELECT ");
	for (int i = 0; i < ITEM_COUNT; i++)
	{
		len += FormatEx(query[len], sizeof(query) - len, "%s%s", i ? ", " : "", ITEM_COLUMN[i]);
	}
	char where[96];
	g_DB.Format(where, sizeof(where), " FROM Roleplay_item WHERE steam_id = '%s'", g_SteamId[client]);
	StrCat(query, sizeof(query), where);
	g_DB.Query(DB_OnItemsLoaded, query, userid);

	g_DB.Format(query, sizeof(query), "SELECT headshot, countheadshot, porte20, porte50, porte100, countporte "
		... "FROM Roleplay_Succes WHERE steam_id = '%s'", g_SteamId[client]);
	g_DB.Query(DB_OnSuccesLoaded, query, userid);
}

public void DB_OnPlayerLoaded(Database db, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	if (results == null)
	{
		LogError("Chargement de %N impossible : %s", client, error);
		return;
	}
	if (results.FetchRow())
	{
		g_Cash[client] = ClampCash(results.FetchInt(0));
		g_Bank[client] = Max(results.FetchInt(1), 0);
		if (g_Bank[client] > MAX_BANK)
		{
			g_Bank[client] = MAX_BANK;
		}
		g_Job[client] = results.FetchInt(2);
		g_JailTime[client] = Max(results.FetchInt(3), 0);
		if (results.FetchInt(4) != 0 && g_JailTime[client] == 0)
		{
			g_JailTime[client] = JAIL_PENDING_TIME;
		}
		g_PermisLourd[client] = results.FetchInt(5);
		g_PermisLeger[client] = results.FetchInt(6);
		g_CB[client] = results.FetchInt(7);
		g_RIB[client] = results.FetchInt(8);
		if (g_Job[client] < 0 || g_Job[client] >= JOB_COUNT)
		{
			LogMessage("%N (%s) avait le métier inconnu %d : remis sans emploi", client, g_SteamId[client], g_Job[client]);
			g_Job[client] = 0;
		}
	}
	else
	{
		g_Cash[client] = 0;
		g_Bank[client] = 10000;
		char name[MAX_NAME_LENGTH], query[512];
		GetClientName(client, name, sizeof(name));
		g_DB.Format(query, sizeof(query), "INSERT INTO Roleplay_Players (steam_id, pseudo, cash, bank) VALUES ('%s', '%s', 0, 10000)",
			g_SteamId[client], name);
		g_DB.Query(DB_OnWriteDone, query);
		PrintToChatAll("%s : Un nouveau joueur a rejoint la population.", LOGO);
		PrintToChatAll("%s : Bienvenue à \x04%s\x01.", LOGO, name);
	}
	DB_PartLoaded(client, LOAD_PLAYER);
}

public void DB_OnItemsLoaded(Database db, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	if (results == null)
	{
		LogError("Chargement des objets de %N impossible : %s", client, error);
		return;
	}
	if (results.FetchRow())
	{
		for (int i = 0; i < ITEM_COUNT; i++)
		{
			g_Item[client][i] = Max(results.FetchInt(i), 0);
		}
	}
	else
	{
		char name[MAX_NAME_LENGTH], query[256];
		GetClientName(client, name, sizeof(name));
		g_DB.Format(query, sizeof(query), "INSERT INTO Roleplay_item (steam_id, pseudo) VALUES ('%s', '%s')", g_SteamId[client], name);
		g_DB.Query(DB_OnWriteDone, query);
	}
	DB_PartLoaded(client, LOAD_ITEMS);
}

public void DB_OnSuccesLoaded(Database db, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	if (results == null)
	{
		LogError("Chargement des succès de %N impossible : %s", client, error);
		return;
	}
	if (results.FetchRow())
	{
		g_SuccesHeadshot[client] = results.FetchInt(0);
		g_Headshots[client] = results.FetchInt(1);
		g_SuccesPorte20[client] = results.FetchInt(2);
		g_SuccesPorte50[client] = results.FetchInt(3);
		g_SuccesPorte100[client] = results.FetchInt(4);
		g_Portes[client] = results.FetchInt(5);
	}
	else
	{
		char name[MAX_NAME_LENGTH], query[256];
		GetClientName(client, name, sizeof(name));
		g_DB.Format(query, sizeof(query), "INSERT INTO Roleplay_Succes (steam_id, pseudo) VALUES ('%s', '%s')", g_SteamId[client], name);
		g_DB.Query(DB_OnWriteDone, query);
	}
	DB_PartLoaded(client, LOAD_SUCCES);
}

static void DB_PartLoaded(int client, int part)
{
	g_LoadParts[client] |= part;
	if (g_LoadParts[client] == LOAD_ALL)
	{
		OnProfileLoaded(client);
	}
}

void DB_SaveClient(int client)
{
	if (g_DB == null || !g_Loaded[client] || g_SteamId[client][0] == '\0')
	{
		return;
	}
	if (IsClientInGame(client))
	{
		g_Cash[client] = GetCash(client);
	}

	char name[MAX_NAME_LENGTH], query[2048];
	GetClientName(client, name, sizeof(name));
	g_DB.Format(query, sizeof(query), "UPDATE Roleplay_Players SET pseudo = '%s', cash = %d, bank = %d, jobid = %d, "
		... "jailtime = %d, isinjail = %d, permislourd = %d, permisleger = %d, cb = %d, rib = %d WHERE steam_id = '%s'",
		name, g_Cash[client], g_Bank[client], g_Job[client], g_JailTime[client], g_Jailed[client],
		g_PermisLourd[client], g_PermisLeger[client], g_CB[client], g_RIB[client], g_SteamId[client]);
	g_DB.Query(DB_OnWriteDone, query);

	int len = g_DB.Format(query, sizeof(query), "UPDATE Roleplay_item SET pseudo = '%s'", name);
	for (int i = 0; i < ITEM_COUNT; i++)
	{
		len += FormatEx(query[len], sizeof(query) - len, ", %s = %d", ITEM_COLUMN[i], g_Item[client][i]);
	}
	char where[96];
	g_DB.Format(where, sizeof(where), " WHERE steam_id = '%s'", g_SteamId[client]);
	StrCat(query, sizeof(query), where);
	g_DB.Query(DB_OnWriteDone, query);

	g_DB.Format(query, sizeof(query), "UPDATE Roleplay_Succes SET pseudo = '%s', headshot = %d, countheadshot = %d, "
		... "porte20 = %d, porte50 = %d, porte100 = %d, countporte = %d WHERE steam_id = '%s'",
		name, g_SuccesHeadshot[client], g_Headshots[client], g_SuccesPorte20[client], g_SuccesPorte50[client],
		g_SuccesPorte100[client], g_Portes[client], g_SteamId[client]);
	g_DB.Query(DB_OnWriteDone, query);
}

void DB_SaveAll()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			DB_SaveClient(client);
		}
	}
	DB_SaveCapital();
}

public void DB_OnWriteDone(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Écriture dans la base roleplay impossible : %s", error);
	}
}
