#include <sourcemod>
#include <system2>

#define MAX_PLAYER_NAME 256
#define API_URL "http://localhost/feed.php"

public Plugin myinfo = {
	name = "lacistat",
	author = "Piszkos12",
	description = "training dev for fun",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

enum struct GameClientStruct {
	int clientId;
	int userId;
	char name[MAX_PLAYER_NAME];
	int fireCount;
	int meleeCount;
	int SZTANPETCount;
	int witchKillingCount;
	int tankKillingCount;
	int chargerKillingCount;
	int spitterKillingCount;
	int jockeyKillingCount;

	bool disconnected;

	bool fireStatUpdateRequest;
}

GameClientStruct gameClients[MAXPLAYERS+1];
int clientCounter;
 
public void OnPluginStart() {
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("This plugin only supports left 4 dead 2!");
		return;
	}
	
	HookEvent("weapon_fire", Event_Weaponfire);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("player_transitioned", Event_PlayerTransitioned);
	HookEvent("friendly_fire", Event_SZTANPET);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("charger_killed", Event_ChargerKilled);
	HookEvent("spitter_killed", Event_SpitterKilled);
	HookEvent("jockey_killed", Event_JockeyKilled);

	PrintToServer("lacistat loaded :)");

	SendTelemetry("event=initSession");

	CreateTimer(1.0, fireStatUpdate, _, TIMER_REPEAT);
}

public Action fireStatUpdate(Handle timer) {
	for (int i=0; i<clientCounter; i++) {
		if (gameClients[i].fireStatUpdateRequest) {
			gameClients[i].fireStatUpdateRequest=false;
			char feed[256];
			Format(feed,256,"event=fireStatUpdate&clientId=%d&userId=%d&name=%s&fireCnt=%d&meleeCnt=%d",
				gameClients[clientCounter-1].clientId,
				gameClients[clientCounter-1].userId,
				gameClients[clientCounter-1].name,
				gameClients[clientCounter-1].fireCount,
				gameClients[clientCounter-1].meleeCount
			);
			SendTelemetry(feed);
		}
	}
	return Plugin_Continue;
}

public void OnClientConnected(int client) {
	char auth[32];
	GetClientAuthId(client,AuthId_Engine,auth,32,true);
	if (auth[0] == 'B' && auth[1] == 'O' && auth[2] == 'T') {
		char npc[MAX_PLAYER_NAME];
		GetClientName(client,npc,MAX_PLAYER_NAME);
		PrintToServer("lacistat NPC connected: %s",npc);
		char feed[256];
		Format(feed,256,"event=newNPC&name=%s",npc);
		SendTelemetry(feed);
		return;
	}

	// Create new client storage, init default values
	clientCounter++;
	gameClients[clientCounter-1].clientId=client;
	gameClients[clientCounter-1].userId=GetClientUserId(client);
	GetClientName(client,gameClients[clientCounter-1].name,MAX_PLAYER_NAME);
	gameClients[clientCounter-1].fireCount=0;
	gameClients[clientCounter-1].meleeCount=0;
	// gameClients[clientCounter-1].friendlyfireCount=0;
	// gameClients[clientCounter-1].witchKillingCount=0;
	// gameClients[clientCounter-1].tankKillingCount=0;
	// gameClients[clientCounter-1].chargerKillingCount=0;
	// gameClients[clientCounter-1].spitterKillingCount=0;
	// gameClients[clientCounter-1].jockeyKillingCount=0;
	gameClients[clientCounter-1].disconnected=false;
	gameClients[clientCounter-1].fireStatUpdateRequest=false;

	// DEBUG
	PrintToServer("lacistat player connected (clientID: %d userId: %d) %s",gameClients[clientCounter-1].clientId,gameClients[clientCounter-1].userId,gameClients[clientCounter-1].name);

	char feed[256];
	Format(feed,256,"event=newclient&clientId=%d&userId=%d&name=%s",gameClients[clientCounter-1].clientId,gameClients[clientCounter-1].userId,gameClients[clientCounter-1].name);
	SendTelemetry(feed);
}

public void OnClientDisconnect(int client) {
	char auth[32];
	GetClientAuthId(client,AuthId_Engine,auth,32,true);
	if (auth[0] == 'B' && auth[1] == 'O' && auth[2] == 'T') {
		PrintToServer("lacistat NPC connected");
		return;
	}

	int deletedIndex;
	// Mark disconnected client record
	for (int i=0; i<clientCounter; i++) {
		if (client == gameClients[i].clientId) {
			PrintToServer("lacistat player disconnected (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
			gameClients[i].disconnected = true;

			char feed[256];
			Format(feed,256,"event=closeClient&clientId=%d&userId=%d&name=%s",gameClients[clientCounter-1].clientId,gameClients[clientCounter-1].userId,gameClients[clientCounter-1].name);
			SendTelemetry(feed);

			deletedIndex = i;
		}
	}
	// Reindexing
	for (int i=deletedIndex; i<clientCounter-1; i++) {
			gameClients[i]=gameClients[i+1];
	}
	clientCounter--;	
} 

public void OnMapStart() {
	char feed[128];
	char map[128];
	GetCurrentMap(map,128);
	Format(feed,128,"event=setMap&map=%s",map);
	SendTelemetry(feed);
	PrintToServer("lacistat OnMapEnd");
}

public void OnMapEnd() {
	SendTelemetry("event=endMap");
	PrintToServer("lacistat OnMapEnd");
}

public void Event_Weaponfire(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("userid");
	int client = GetClientOfUserId(user);
	char weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			if (strncmp(weapon, "weapon_melee",12)) {
				gameClients[i].fireCount++;
				gameClients[i].fireStatUpdateRequest=true;
				PrintToServer("lacistat player bullet count:%d bullets (clientID: %d userId: %d) %s",gameClients[i].fireCount,gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
			} else {
				gameClients[i].meleeCount++;
				gameClients[i].fireStatUpdateRequest=true;
				PrintToServer("lacistat player melee count:%d (clientID: %d userId: %d) %s",gameClients[i].fireCount,gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
			}
		}
	}
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	SendTelemetry("event=mapTransition");
	PrintToServer("lacistat map transition");
}

public void Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast) {
	SendTelemetry("event=playerTransitioned");
	PrintToServer("lacistat map transition");
}

public void Event_SZTANPET(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].SZTANPETCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat player SZTANPET count:%d bullets (clientID: %d userId: %d) %s",gameClients[i].fireCount,gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].witchKillingCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat witch killed by (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].tankKillingCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat tank killed by (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

public void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].chargerKillingCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat charger killed by (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

public void Event_SpitterKilled(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].spitterKillingCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat spitter killed by (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

public void Event_JockeyKilled(Event event, const char[] name, bool dontBroadcast) {
	int user = event.GetInt("attacker");
	int client = GetClientOfUserId(user);
	for (int i=0; i<clientCounter; i++) {
		if (user == gameClients[i].userId) {
			gameClients[i].jockeyKillingCount++;
			gameClients[i].fireStatUpdateRequest=true;
			PrintToServer("lacistat jockey killed by (clientID: %d userId: %d) %s",gameClients[i].clientId,gameClients[i].userId,gameClients[i].name);
		}
	}
}

void SendTelemetry(char[] data) {
	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, API_URL);
	httpRequest.Timeout = 1;
	httpRequest.SetData(data);
	httpRequest.POST(); 
	delete httpRequest;
}

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
	return;

	//FOR  DEBUG

    char url[256];
    request.GetURL(url, sizeof(url));

    if (!success) {
        PrintToServer("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
        PrintToServer("");
        PrintToServer("INFO: Finished");
        PrintToServer("");

        return;
    }

    response.GetLastURL(url, sizeof(url));

    PrintToServer("INFO: Successfully retrieved URL %s in %.0f milliseconds", url, response.TotalTime * 1000.0);
    PrintToServer("");
    PrintToServer("INFO: HTTP Version: %s", (response.HTTPVersion == VERSION_1_0 ? "1.0" : "1.1"));
    PrintToServer("INFO: Status Code: %d", response.StatusCode);
    PrintToServer("INFO: Downloaded %d bytes with %d bytes/seconds", response.DownloadSize, response.DownloadSpeed);
    PrintToServer("INFO: Uploaded %d bytes with %d bytes/seconds", response.UploadSize, response.UploadSpeed);
    PrintToServer("");
    PrintToServer("INFO: Retrieved the following headers:");

    char name[128];
    char value[128];
    ArrayList headers = response.GetHeaders();

    for (int i = 0; i < headers.Length; i++) {
        headers.GetString(i, name, sizeof(name));
        response.GetHeader(name, value, sizeof(value));
        PrintToServer("\t%s: %s", name, value);
    }
    
    PrintToServer("");
    PrintToServer("INFO: Content (%d bytes):", response.ContentLength);
    PrintToServer("");
    
    char content[128];
    for (int found = 0; found < response.ContentLength;) {
        found += response.GetContent(content, sizeof(content), found);
        PrintToServer(content);
    }

    PrintToServer("");
    PrintToServer("INFO: Finished");
    PrintToServer("");
    
    delete headers;
}