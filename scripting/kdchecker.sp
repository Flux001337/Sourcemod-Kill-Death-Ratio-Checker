//////////////////////////////////////////////////////////////////
// Kill Death Ratio Checker By HSFighter / www.hsfighter.net
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.8.1"

#undef REQUIRE_PLUGIN
#include <updater>

/* Updater */
#define UPDATE_URL	"http://update.hsfighter.net/sourcemod/kdchecker/kdchecker.txt"

//////////////////////////////////////////////////////////////////
// Declaring variables and handles
//////////////////////////////////////////////////////////////////

ConVar KDCheckerVersion;
ConVar KDCheckerEnabled;
ConVar KDCheckerShowRoundEnd;
ConVar KDCheckerShowOnKill;
ConVar KDCheckerWatchEnabled;
ConVar KDCheckerEnabledCheckRate;
ConVar KDCheckerRate;
ConVar KDCheckerKills;
ConVar KDCheckerActionMode;
ConVar KDCheckerBanTime;
ConVar KDCheckerDebug;

bool g_bSBAvailable;
Handle g_hCheckTimer;

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin myinfo =
{
	name = "KDR Checker",
	author = "HSFighter",
	description = "Kill Death Ratio Checker",
	version = PLUGIN_VERSION,
	url = "http://www.hsfighter.net"
};

//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
	// Create convars
	// FCVAR_DONTRECORD: AutoExecConfig must not write the version into the cfg file
	KDCheckerVersion = CreateConVar("sm_kdrc_version", PLUGIN_VERSION, "KD Kicker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	KDCheckerEnabled          = CreateConVar("sm_kdrc_enable",          "1",    "Enable/Disable KD Checker", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowRoundEnd     = CreateConVar("sm_kdrc_show_roundend",   "1",    "Show KD Rate to player on roundend", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowOnKill       = CreateConVar("sm_kdrc_show_kill",   	"0",    "Show KD Rate to attacker on kill", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerWatchEnabled     = CreateConVar("sm_kdrc_watch_enable",    "0",    "Enable/Disable KD Rate watching", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerRate             = CreateConVar("sm_kdrc_watch_rate",      "4.0",  "KD Rate for a player before action", FCVAR_PLUGIN, true, 1.0);
	KDCheckerKills            = CreateConVar("sm_kdrc_watch_kills",     "15",   "Count of kills before a player is checked", FCVAR_PLUGIN, true, 1.0);
	KDCheckerEnabledCheckRate = CreateConVar("sm_kdrc_watch_checkrate", "30.0",	"Rate in seconds at players KD Rate are checked", FCVAR_PLUGIN, true, 1.0);
	KDCheckerActionMode       = CreateConVar("sm_kdrc_watch_action",    "0",    "Action for affected player (0 = kick, 1 = ban)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerBanTime          = CreateConVar("sm_kdrc_watch_bantime",   "60",   "Amount of time in Minutes to ban if using 'sm_kdrc_watch_action = 1' (0 = perm)", _, true, 0.0);
	KDCheckerDebug     		  = CreateConVar("sm_kdrc_debug",   		"0",    "Debug playercheck to serverlog", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Register Console Commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_kdr", ShowKDRateToClientCmd);
	RegAdminCmd("sm_kdrc_testaction", Command_TestAction, ADMFLAG_ROOT, "Test the configured kick/ban action on yourself");

	// Hook Events
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);

	// Updater
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	// Create Timer for delay
	KDCheckerEnabledCheckRate.AddChangeHook(OnCheckIntervalChanged);

	// Autoexec / Create Configfile
	AutoExecConfig(true, "plugin.kdcheck");
}

//////////////////////////////////////////////////////////////////
// Check if sourcebans present
//////////////////////////////////////////////////////////////////

public void OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans") || LibraryExists("sourcebans++"))
	{
		g_bSBAvailable = true;
	}
}

// SourceBans registers "sourcebans", SourceBans++ "sourcebans++"
bool IsSourceBansLibrary(const char[] name)
{
	return StrEqual(name, "sourcebans") || StrEqual(name, "sourcebans++");
}

public void OnLibraryAdded(const char[] name)
{
	if (IsSourceBansLibrary(name))
	{
		g_bSBAvailable = true;
	}

	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (IsSourceBansLibrary(name))
	{
		g_bSBAvailable = LibraryExists("sourcebans") || LibraryExists("sourcebans++");
	}
}

//////////////////////////////////////////////////////////////////
// Action: Say Command
//////////////////////////////////////////////////////////////////

public Action Command_Say(int client, int args)
{

    // Check if plugin is disbaled
	if(GetConVarInt(KDCheckerEnabled) != 1)
	{
		return Plugin_Continue;
	}

	// Check if player ok
	if (!IsRealPlayer(client))
	{
		return Plugin_Continue;
	}

	// Declaring variables
	char text[192], command[64];
	int startidx = 0;

	// Check saycommand is valid
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	// Check saycommand type
	GetCmdArg(0, command, sizeof(command));
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	// Is saycommand "kdr" show KD-Rate to player
	if (strcmp(text[startidx], "kdr", false) == 0)
	{
		ShowKDRateToClient(client);

	}

	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Action: Test the configured action on the calling admin (root only)
//////////////////////////////////////////////////////////////////

public Action Command_TestAction(int client, int args)
{
	if (!IsRealPlayer(client))
	{
		ReplyToCommand(client, "[SM] This command requires an in-game player.");
		return Plugin_Handled;
	}
	if (!KDCheckerEnabled.BoolValue)
	{
		ReplyToCommand(client, "[SM] KDR Checker is disabled.");
		return Plugin_Handled;
	}
	KDRateAction(client);
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client Cmd
//////////////////////////////////////////////////////////////////

public Action ShowKDRateToClientCmd(int client, int args)
{
    if (!IsRealPlayer(client))
    {
        ReplyToCommand(client, "[SM] This command requires an in-game player.");
        return Plugin_Handled;
    }
    if (!KDCheckerEnabled.BoolValue)
    {
        return Plugin_Handled;
    }
    return ShowKDRateToClient(client);
}

//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client
//////////////////////////////////////////////////////////////////

public Action ShowKDRateToClient(int client){
    if (!IsRealPlayer(client)) return Plugin_Handled;

	// Get Deaths, Kills and KD Rate
	int Deaths = GetClientDeaths(client);
	int Frags = GetClientFrags(client);
	float KDRate = CalculateKDR(Frags, Deaths);

	// Print KDR to Client
	PrintToChat(client, "[SM] Your KDRate is \x04%.2f \x01(\x04%i \x01Kills / \x04%i \x01Deaths)", KDRate, Frags, Deaths);
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Action: Event Roundend
//////////////////////////////////////////////////////////////////

public Action EventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// Check if "Plugin" is disbaled or "show kdr on roundend" is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowRoundEnd) != 1)) return Plugin_Continue;

	// Get all clients on the server
	for (int i = 1; i <= MaxClients; i++)
	{
		//Check if player ok
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ShowKDRateToClient(i);
		}
	}
	return Plugin_Continue;

}

//////////////////////////////////////////////////////////////////
// Action: Event Player Die
//////////////////////////////////////////////////////////////////

public Action hookPlayerDie(Event event, const char[] name, bool dontBroadcast)
{
	// Check if "Plugin" is disbaled or "show kdr on kill" is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowOnKill) != 1)) return Plugin_Continue;

	int attacker = GetEventInt(event, "attacker");
	int id =  GetClientOfUserId(attacker);

	// Check if player ok
	if (IsRealPlayer(id))
	{
        RequestFrame(ShowKDRNextFrame, GetClientSerial(id));
	}
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Action: Timerloop
//////////////////////////////////////////////////////////////////

public Action Checktime(Handle timer){

	// Check if Plugin is disbaled or Watching is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1)) return Plugin_Continue;

	// Get all clients on the server
	for (int i = 1; i <= MaxClients; i++)
	{
		// Check if player ok
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			// Get playername
			char f_sPlayer_Name[65];
			GetClientName(i, f_sPlayer_Name, sizeof(f_sPlayer_Name));

			// Get Player ID and IP
			char f_sAuthID[64], f_sIP[64];

			if (!GetClientAuthId(i, AuthId_Steam2, f_sAuthID, sizeof(f_sAuthID)))
            {
                strcopy(f_sAuthID, sizeof(f_sAuthID), "UNKNOWN");
            }
			GetClientIP(i, f_sIP, sizeof(f_sIP));

			// Check if player ist bot
			if (!IsClientBot(i))
			{
				if(GetConVarInt(KDCheckerWatchEnabled) == 1) GetClientKillDeathRatio(i);
				if(GetConVarInt(KDCheckerDebug) != 0) LogAction(i, -1,"[KDR Check] Check %s (ID: %s | IP: %s) is PLAYER", f_sPlayer_Name, f_sAuthID, f_sIP);
			}else{
				if(GetConVarInt(KDCheckerDebug) != 0) LogAction(i, -1,"[KDR Check] Ignore %s (ID: %s | IP: %s) is BOT", f_sPlayer_Name, f_sAuthID, f_sIP);
			}
		}
	}

	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Action: Get KillDeathRatio
//////////////////////////////////////////////////////////////////

public Action GetClientKillDeathRatio(int client)
{
    if (!IsRealPlayer(client)) return Plugin_Continue;
	// Get Deaths, Kills and KD Rate
	int Deaths = GetClientDeaths(client);
	int Frags = GetClientFrags(client);
	float KDRate = CalculateKDR(Frags, Deaths);

	{
		// If frags less than kill threshold return
		if ((Frags) < GetConVarInt(KDCheckerKills)) return Plugin_Continue;
		// Calc KD-Rate and exec action if necessary
		if (KDRate >= GetConVarFloat(KDCheckerRate))
		{
			// Exec Action
			KDRateAction(client);
	    }
    }
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Action: Exec KillDeathRatio watch event for a client
//////////////////////////////////////////////////////////////////

public Action KDRateAction(int client)
{
    if (!IsRealPlayer(client) || IsClientInKickQueue(client)) return Plugin_Continue;

	// Get Player ID
	char f_sAuthID[64];
	if (!GetClientAuthId(client, AuthId_Steam2, f_sAuthID, sizeof(f_sAuthID)))
    {
        strcopy(f_sAuthID, sizeof(f_sAuthID), "UNKNOWN");
    }

	// Get Player IP
	char f_sIP[64];
	GetClientIP(client, f_sIP, sizeof(f_sIP));

	// Get client name
	char f_sPlayer_Name[65];
	GetClientName(client, f_sPlayer_Name, sizeof(f_sPlayer_Name));

	// Select Action Mode
	switch (GetConVarInt(KDCheckerActionMode))
	{
		// If Kick
		case 0:
		{
			// Kick client
			KickClient(client, "You were kicked due high KD Rate!");
			// Show message to all other clients
			PrintToChatAll("[SM] Name: %s was KICKED for a high KD Rate", f_sPlayer_Name);
			// Log Action
			LogAction(client, -1, "%s (ID: %s | IP: %s) was KICKED for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP);
		}
		// If Ban
		case 1:
		{
			// Check if Sourcebans aviable
			if (g_bSBAvailable)
			{
				// Ban client
				ServerCommand("sm_ban #%d %i \"To high KD Rate!\"",GetClientUserId(client), GetConVarInt(KDCheckerBanTime));

			}else{
				// Ban client
				BanClient(client,
					GetConVarInt(KDCheckerBanTime),
					BANFLAG_AUTO,
					"High KD Rate",
					"You were banned due high KD Rate!",
					"KDRCheck",
					0);
			}

			if (GetConVarInt(KDCheckerBanTime) == 0)
			{
				// Show message permanent ban to all other clients
				PrintToChatAll("[SM] Name: %s was BANNED for a high KD Rate", f_sPlayer_Name);
				// Log Action
				LogAction(client, -1, "%s (ID: %s | IP: %s) was BANNED permanently for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP);
			}else{
				// Show message temp ban to all other clients
				PrintToChatAll("[SM] Name: %s was BANNED %i Minutes for a high KD Rate", f_sPlayer_Name, GetConVarInt(KDCheckerBanTime));
				// Log Action
				LogAction(client, -1, "%s (ID: %s | IP: %s) was BANNED %i Minutes for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP, GetConVarInt(KDCheckerBanTime));
			}
		}
    }
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Function: Is client a bot
//////////////////////////////////////////////////////////////////

bool IsClientBot(int client)
{
    return IsFakeClient(client);
}

bool IsRealPlayer(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

float CalculateKDR(int frags, int deaths)
{
    if (frags <= 0) return 0.0;
    return deaths > 0 ? float(frags) / float(deaths) : float(frags);
}

public void ShowKDRNextFrame(any serial)
{
    int client = GetClientFromSerial(serial);
    if (IsRealPlayer(client) && KDCheckerEnabled.BoolValue && KDCheckerShowOnKill.BoolValue)
    {
        ShowKDRateToClient(client);
    }
}

public void OnConfigsExecuted()
{
    // Older cfg files still contain sm_kdrc_version; restore the real version after they ran
    KDCheckerVersion.SetString(PLUGIN_VERSION);
    RestartCheckTimer();
}

public void OnCheckIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RestartCheckTimer();
}

void RestartCheckTimer()
{
    delete g_hCheckTimer;
    g_hCheckTimer = CreateTimer(KDCheckerEnabledCheckRate.FloatValue, Checktime, _, TIMER_REPEAT);
}

//////////////////////////////////////////////////////////////////
// End Plugin
//////////////////////////////////////////////////////////////////

public void OnPluginEnd()
{
    delete g_hCheckTimer;
}

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
