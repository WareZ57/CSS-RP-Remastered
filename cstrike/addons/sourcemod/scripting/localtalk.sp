#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAX_AREA_DIST 500.0

public Plugin myinfo =
{
	name = "Local-Talk",
	author = "KoSSoLaX",
	description = "LocalTalk based from Voice Proximity Plugin",
	version = "1.2c",
	url = ""
};

bool g_bIsConnected[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateTimer(0.1, Timer_UpdateListeners, _, TIMER_REPEAT);
	for (int client = 1; client <= MaxClients; client++)
	{
		g_bIsConnected[client] = IsClientInGame(client) && IsClientAuthorized(client);
	}
}

public void OnClientDisconnect(int client)
{
	g_bIsConnected[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	g_bIsConnected[client] = true;
}

public Action Timer_UpdateListeners(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client))
		{
			continue;
		}
		bool alive = IsPlayerAlive(client);
		for (int id = 1; id <= MaxClients; id++)
		{
			if (id == client || !IsValidClient(id))
			{
				continue;
			}
			bool hear = alive && IsPlayerAlive(id) && EntityDistance(client, id) <= MAX_AREA_DIST;
			SetListenOverride(client, id, hear ? Listen_Yes : Listen_No);
		}
	}
	return Plugin_Continue;
}

float EntityDistance(int ent1, int ent2)
{
	float orig1[3], orig2[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);
	return GetVectorDistance(orig1, orig2);
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && g_bIsConnected[client] && IsClientInGame(client) && IsClientAuthorized(client);
}
