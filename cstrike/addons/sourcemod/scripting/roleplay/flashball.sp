ConVar g_cvFlashball;
ConVar g_cvFlashballTime;
float g_FlashUntil[MAXPLAYERS + 1];
float g_FlashImmune[MAXPLAYERS + 1];

void Flashball_Init()
{
	g_cvFlashball = CreateConVar("sm_rp_flashball", "1", "1 = l'USP avec silencieux est un flashball (aucun dégât, cible gelée et éblouie)", _, true, 0.0, true, 1.0);
	g_cvFlashballTime = CreateConVar("sm_rp_flashball_time", "1.5", "Durée du gel et de l'éblouissement du flashball (secondes)", _, true, 0.1, true, 10.0);
}

void Flashball_Reset(int client)
{
	g_FlashUntil[client] = 0.0;
	g_FlashImmune[client] = 0.0;
}

bool Flashball_Armed(int attacker)
{
	if (!g_cvFlashball.BoolValue)
	{
		return false;
	}
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1 || !HasEntProp(weapon, Prop_Send, "m_bSilencerOn"))
	{
		return false;
	}
	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	return StrEqual(classname, "weapon_usp") && GetEntProp(weapon, Prop_Send, "m_bSilencerOn") != 0;
}

void Flashball_Hit(int victim)
{
	float now = GetGameTime();
	if (now < g_FlashImmune[victim])
	{
		return;
	}
	float duration = g_cvFlashballTime.FloatValue;
	g_FlashUntil[victim] = now + duration;
	g_FlashImmune[victim] = now + 2.0 * duration;

	float velocity[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", velocity);
	velocity[0] = 0.0;
	velocity[1] = 0.0;
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);

	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", victim, USERMSG_RELIABLE));
	if (bf != null)
	{
		bf.WriteShort(RoundToFloor(duration * 2.0 / 3.0 * 512.0));
		bf.WriteShort(RoundToFloor(duration / 3.0 * 512.0));
		bf.WriteShort(0x0001 | 0x0010);
		bf.WriteByte(255);
		bf.WriteByte(255);
		bf.WriteByte(255);
		bf.WriteByte(180);
		EndMessage();
	}
}

Action Flashball_OnRunCmd(int client, int &buttons, float vel[3])
{
	if (GetGameTime() >= g_FlashUntil[client])
	{
		return Plugin_Continue;
	}
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 0.0;
	buttons &= ~(IN_JUMP | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT);
	return Plugin_Changed;
}
