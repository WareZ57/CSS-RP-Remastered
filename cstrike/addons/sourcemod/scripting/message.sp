#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Message teammate_attack",
	author = "",
	description = "Masque le message teammate_attack",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true);
}

public Action UserMessageHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (GetUserMessageType() != UM_BitBuf)
	{
		return Plugin_Continue;
	}
	char message[256];
	msg.ReadByte();
	msg.ReadString(message, sizeof(message));
	return StrContains(message, "teammate_attack") != -1 ? Plugin_Handled : Plugin_Continue;
}
