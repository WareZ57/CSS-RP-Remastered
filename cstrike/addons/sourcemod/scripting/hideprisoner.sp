#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar g_cvEnable;

public Plugin myinfo =
{
	name = "Cachekill",
	author = "Delachambre",
	version = "1.1",
	description = "Plugin qui cache les kill",
	url = ""
};

public void OnPluginStart()
{
	g_cvEnable = CreateConVar("sm_hidekill", "1", "1 = les meurtres entre joueurs n'apparaissent pas dans le fil des kills", _, true, 0.0, true, 1.0);
	HookEvent("player_death", Event_HidePrisonerKill, EventHookMode_Pre);
}

public Action Event_HidePrisonerKill(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (g_cvEnable.BoolValue && victim != 0 && attacker != 0 && attacker != victim)
	{
		event.BroadcastDisabled = true;
	}
	return Plugin_Continue;
}
