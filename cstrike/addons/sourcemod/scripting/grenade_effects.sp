#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.1"

#define FLASH 0
#define SMOKE 1

#define SOUND_FREEZE			"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

int FragColor[4] = { 255, 75, 75, 255 };
int FlashColor[4] = { 255, 255, 255, 255 };
int SmokeColor[4] = { 75, 255, 75, 255 };
int FreezeColor[4] = { 75, 75, 255, 255 };
float NULL_VELOCITY[3] = { 0.0, 0.0, 0.0 };

int BeamSprite, GlowSprite, g_beamsprite, g_halosprite;

ConVar h_greneffects_enable, h_greneffects_trails, h_greneffects_napalm_he, h_greneffects_napalm_he_duration,
	h_greneffects_smoke_freeze, h_greneffects_smoke_freeze_distance, h_greneffects_smoke_freeze_duration,
	h_greneffects_flash_light, h_greneffects_flash_light_distance, h_greneffects_flash_light_duration;
ConVar mp_friendlyfire;

Handle h_freeze_timer[MAXPLAYERS + 1];

GlobalForward h_fwdOnClientFreeze, h_fwdOnClientFreezed, h_fwdOnClientIgnite, h_fwdOnClientIgnited;

public Plugin myinfo =
{
	name = "Grenade Effects",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Adds Grenades Special Effects.",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	h_fwdOnClientFreeze = new GlobalForward("OnClientFreeze", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	h_fwdOnClientFreezed = new GlobalForward("OnClientFreezed", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	h_fwdOnClientIgnite = new GlobalForward("OnClientIgnite", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	h_fwdOnClientIgnited = new GlobalForward("OnClientIgnited", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_greneffect_version", PLUGIN_VERSION, "The plugin's version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	h_greneffects_enable = CreateConVar("sm_greneffect_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	h_greneffects_trails = CreateConVar("sm_greneffect_trails", "1", "Enables/Disables Grenade Trails", 0, true, 0.0, true, 1.0);
	h_greneffects_napalm_he = CreateConVar("sm_greneffect_napalm_he", "1", "Changes a he grenade to a napalm grenade", 0, true, 0.0, true, 1.0);
	h_greneffects_napalm_he_duration = CreateConVar("sm_greneffect_napalm_he_duration", "6", "The napalm duration", 0, true, 0.0);
	h_greneffects_smoke_freeze = CreateConVar("sm_greneffect_smoke_freeze", "1", "Changes a smoke grenade to a freeze grenade", 0, true, 0.0, true, 1.0);
	h_greneffects_smoke_freeze_distance = CreateConVar("sm_greneffect_smoke_freeze_distance", "600", "The freeze grenade distance", 0, true, 100.0);
	h_greneffects_smoke_freeze_duration = CreateConVar("sm_greneffect_smoke_freeze_duration", "4", "The freeze duration in seconds", 0, true, 1.0);
	h_greneffects_flash_light = CreateConVar("sm_greneffect_flash_light", "0", "Changes a flashbang to a flashlight", 0, true, 0.0, true, 1.0);
	h_greneffects_flash_light_distance = CreateConVar("sm_greneffect_flash_light_distance", "1000", "The light distance", 0, true, 100.0);
	h_greneffects_flash_light_duration = CreateConVar("sm_greneffect_flash_light_duration", "15.0", "The light duration in seconds", 0, true, 1.0);
	mp_friendlyfire = FindConVar("mp_friendlyfire");

	AutoExecConfig(true, "grenade_effects");

	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("hegrenade_detonate", OnHeDetonate);
	HookEvent("smokegrenade_detonate", OnSmokeDetonate);
	AddNormalSoundHook(NormalSHook);
}

public void OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
	PrecacheSound("items/nvg_on.wav");
}

public void OnClientDisconnect(int client)
{
	StopFreeze(client);
}

void StopFreeze(int client)
{
	if (IsClientInGame(client))
	{
		ExtinguishEntity(client);
	}
	delete h_freeze_timer[client];
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		delete h_freeze_timer[client];
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!h_greneffects_enable.BoolValue || !h_greneffects_napalm_he.BoolValue)
	{
		return;
	}
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (!StrEqual(weapon, "hegrenade", false))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
	if (!mp_friendlyfire.BoolValue && attacker != 0 && GetClientTeam(client) == GetClientTeam(attacker))
	{
		return;
	}
	float duration = h_greneffects_napalm_he_duration.FloatValue;
	Action result = Forward_OnClientIgnite(client, attacker, duration);
	if (result == Plugin_Handled || result == Plugin_Stop)
	{
		return;
	}
	if (result == Plugin_Continue)
	{
		duration = h_greneffects_napalm_he_duration.FloatValue;
	}
	IgniteEntity(client, duration);
	Forward_OnClientIgnited(client, attacker, duration);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0)
	{
		StopFreeze(client);
	}
}

public void OnHeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	if (!h_greneffects_enable.BoolValue || !h_greneffects_napalm_he.BoolValue)
	{
		return;
	}
	float origin[3];
	origin[0] = event.GetFloat("x");
	origin[1] = event.GetFloat("y");
	origin[2] = event.GetFloat("z");
	TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FragColor, 0, 0);
	TE_SendToAll();
}

public void OnSmokeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	if (!h_greneffects_enable.BoolValue || !h_greneffects_smoke_freeze.BoolValue)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	float origin[3];
	origin[0] = event.GetFloat("x");
	origin[1] = event.GetFloat("y");
	origin[2] = event.GetFloat("z");

	int index = MaxClients + 1;
	float xyz[3];
	while ((index = FindEntityByClassname(index, "smokegrenade_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == origin[0] && xyz[1] == origin[1] && xyz[2] == origin[2])
		{
			AcceptEntityInput(index, "kill");
		}
	}

	origin[2] += 10.0;
	int clientteam = (client != 0 && IsClientInGame(client)) ? GetClientTeam(client) : 0;
	float distance = h_greneffects_smoke_freeze_distance.FloatValue;
	float targetOrigin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		if (!mp_friendlyfire.BoolValue && GetClientTeam(i) == clientteam)
		{
			continue;
		}
		GetClientAbsOrigin(i, targetOrigin);
		targetOrigin[2] += 2.0;
		if (GetVectorDistance(origin, targetOrigin) > distance)
		{
			continue;
		}
		if (CanSee(origin, targetOrigin, i))
		{
			Freeze(i, client, h_greneffects_smoke_freeze_duration.FloatValue);
			continue;
		}
		GetClientEyePosition(i, targetOrigin);
		targetOrigin[2] -= 2.0;
		if (CanSee(origin, targetOrigin, i))
		{
			Freeze(i, client, h_greneffects_smoke_freeze_duration.FloatValue);
		}
	}

	TE_SetupBeamRingPoint(origin, 10.0, distance, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FreezeColor, 0, 0);
	TE_SendToAll();
	LightCreate(SMOKE, origin);
}

static bool CanSee(const float from[3], const float to[3], int target)
{
	if (GetVectorDistance(from, to) <= 100.0)
	{
		return true;
	}
	Handle trace = TR_TraceRayFilterEx(from, to, MASK_SOLID, RayType_EndPoint, FilterTarget, target);
	bool hit = TR_DidHit(trace) && TR_GetEntityIndex(trace) == target;
	delete trace;
	return hit;
}

public bool FilterTarget(int entity, int contentsMask, any data)
{
	return data == entity;
}

public Action DoFlashLight(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (StrEqual(classname, "flashbang_projectile", false))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		origin[2] += 50.0;
		LightCreate(FLASH, origin);
		AcceptEntityInput(entity, "kill");
	}
	return Plugin_Stop;
}

bool Freeze(int client, int attacker, float time)
{
	float duration = time;
	Action result = Forward_OnClientFreeze(client, attacker, duration);
	if (result == Plugin_Handled || result == Plugin_Stop)
	{
		return false;
	}
	if (result == Plugin_Continue)
	{
		duration = time;
	}

	delete h_freeze_timer[client];
	SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);

	float vec[3];
	GetClientEyePosition(client, vec);
	vec[2] -= 50.0;
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	TE_SetupGlowSprite(vec, GlowSprite, duration, 2.0, 50);
	TE_SendToAll();

	h_freeze_timer[client] = CreateTimer(duration, Unfreeze, client, TIMER_FLAG_NO_MAPCHANGE);
	Forward_OnClientFreezed(client, attacker, duration);
	return true;
}

public Action Unfreeze(Handle timer, any client)
{
	h_freeze_timer[client] = null;
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Stop;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!h_greneffects_enable.BoolValue)
	{
		return;
	}
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		BeamFollowCreate(entity, FragColor);
		if (h_greneffects_napalm_he.BoolValue)
		{
			IgniteEntity(entity, 2.0);
		}
	}
	else if (StrEqual(classname, "flashbang_projectile"))
	{
		if (h_greneffects_flash_light.BoolValue)
		{
			CreateTimer(1.3, DoFlashLight, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		BeamFollowCreate(entity, FlashColor);
	}
	else if (StrEqual(classname, "smokegrenade_projectile"))
	{
		if (h_greneffects_smoke_freeze.BoolValue)
		{
			BeamFollowCreate(entity, FreezeColor);
			CreateTimer(1.3, CreateEvent_SmokeDetonate, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			BeamFollowCreate(entity, SmokeColor);
		}
	}
	else if (h_greneffects_smoke_freeze.BoolValue && StrEqual(classname, "env_particlesmokegrenade"))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action CreateEvent_SmokeDetonate(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (StrEqual(classname, "smokegrenade_projectile", false) && thrower > 0 && thrower <= MaxClients && IsClientInGame(thrower))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		Event event = CreateEvent("smokegrenade_detonate");
		if (event != null)
		{
			event.SetInt("userid", GetClientUserId(thrower));
			event.SetFloat("x", origin[0]);
			event.SetFloat("y", origin[1]);
			event.SetFloat("z", origin[2]);
			event.Fire();
		}
	}
	return Plugin_Stop;
}

void BeamFollowCreate(int entity, int color[4])
{
	if (h_greneffects_trails.BoolValue)
	{
		TE_SetupBeamFollow(entity, BeamSprite, 0, 1.0, 10.0, 10.0, 5, color);
		TE_SendToAll();
	}
}

void LightCreate(int grenade, float pos[3])
{
	int iEntity = CreateEntityByName("light_dynamic");
	if (iEntity == -1)
	{
		return;
	}
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	if (grenade == FLASH)
	{
		DispatchKeyValue(iEntity, "_light", "255 255 255 255");
		DispatchKeyValueFloat(iEntity, "distance", h_greneffects_flash_light_distance.FloatValue);
		EmitSoundToAll("items/nvg_on.wav", iEntity, SNDCHAN_WEAPON);
		CreateTimer(h_greneffects_flash_light_duration.FloatValue, Delete, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		DispatchKeyValue(iEntity, "_light", "75 75 255 255");
		DispatchKeyValueFloat(iEntity, "distance", h_greneffects_smoke_freeze_distance.FloatValue);
		EmitSoundToAll(SOUND_FREEZE_EXPLODE, iEntity, SNDCHAN_WEAPON);
		CreateTimer(0.2, Delete, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
	}
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action Delete(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "kill");
	}
	return Plugin_Stop;
}

public Action NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel,
	float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (h_greneffects_smoke_freeze.BoolValue && StrEqual(sample, "^weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Forward_OnClientFreeze(int client, int attacker, float &time)
{
	Action result = Plugin_Continue;
	Call_StartForward(h_fwdOnClientFreeze);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);
	return result;
}

void Forward_OnClientFreezed(int client, int attacker, float time)
{
	Call_StartForward(h_fwdOnClientFreezed);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}

Action Forward_OnClientIgnite(int client, int attacker, float &time)
{
	Action result = Plugin_Continue;
	Call_StartForward(h_fwdOnClientIgnite);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);
	return result;
}

void Forward_OnClientIgnited(int client, int attacker, float time)
{
	Call_StartForward(h_fwdOnClientIgnited);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}
