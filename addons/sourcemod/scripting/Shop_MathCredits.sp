#include <sourcemod>
#include <shop>
#include <sdktools_sound>
#include <sdktools_stringtables>
#include <multicolors>
#pragma newdecls required

#define PLUS				"+"
#define MINUS				"-"
#define DIVISOR				"/"
#define MULTIPL				"*"

char operators[][] = {PLUS, MINUS, DIVISOR, MULTIPL};

char Sound_download[]	=	"sound/shop/Applause.mp3";

char soundplay[sizeof(Sound_download) - 5] = "*";
int nbrmin;
int nbrmax;
int mincredits;
int maxcredits;
static int questionResult;
int credits;
float minquestion;
float maxquestion;
float timeanswer;

Handle timerQuestionEnd;

public Plugin myinfo = 
{
	name = "[Shop] Math Credits",
	author = "Arkarr / Psychologist21 & AlmazON",
	description = "Mathematical tasks for credits (competition)",
	version = "1.2.1",
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	ConVar cvar = CreateConVar("sm_MathCredits_minimum_number",				"1",	"Minimum number in math question.");
	HookConVarChange(cvar,	CVAR_MinimumNumber);
	nbrmin = cvar.IntValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_maximum_number",	"100",	"Maximum number in math question."),	CVAR_MaximumNumber);
	nbrmax = cvar.IntValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_minimum_credits",	"5",	"The minimum number of credits earned for the correct answer.", _, true, 1.0), CVAR_MinimumCredits);
	mincredits = cvar.IntValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_maximum_credits",	"100",	"The maximum number of credits earned for a correct answer.", _, true, 1.0), CVAR_MaximumCredits);
	maxcredits = cvar.IntValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_time_answer_questions",	"15",	"Time in seconds to answer the question.", _, true, 5.0),	CVAR_TimeAnswer);
	timeanswer = cvar.FloatValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_time_minamid_questions",	"100",	"The minimum time in seconds between each question.", _, true, 5.0),	CVAR_MinQuestion);
	minquestion = cvar.FloatValue;
	HookConVarChange(cvar = CreateConVar("sm_MathCredits_time_maxamid_questions",	"250",	"The maximum time in seconds between each question.", _, true, 10.0),	CVAR_MaxQuestion);
	maxquestion = cvar.FloatValue;
	AutoExecConfig(true);
	
	LoadTranslations("shop_mathcredits.phrases");

	strcopy(soundplay[view_as<int>(GetEngineVersion() == Engine_CSGO)], sizeof(soundplay), Sound_download[6]);
}

public void CVAR_MinimumNumber(ConVar convar, const char[] oldValue, const char[] newValue)
{
	nbrmin = convar.IntValue;
}
public void CVAR_MaximumNumber(ConVar convar, const char[] oldValue, const char[] newValue)
{
	nbrmax = convar.IntValue;
}
public void CVAR_MinimumCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	mincredits = convar.IntValue;
}
public void CVAR_MaximumCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	maxcredits = convar.IntValue;
}
public void CVAR_TimeAnswer(ConVar convar, const char[] oldValue, const char[] newValue)
{
	timeanswer = convar.FloatValue;
}
public void CVAR_MinQuestion(ConVar convar, const char[] oldValue, const char[] newValue)
{
	minquestion = convar.FloatValue;
}
public void CVAR_MaxQuestion(ConVar convar, const char[] oldValue, const char[] newValue)
{
	maxquestion = convar.FloatValue;
}

public void OnMapStart()
{
	PrecacheSound(soundplay, true);
	AddFileToDownloadsTable(Sound_download);
}

public void OnConfigsExecuted()
{
	timerQuestionEnd = null;
	CreateTimer(GetRandomFloat(minquestion, maxquestion), CreateQuestion, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CreateQuestion(Handle timer)
{
	char op[sizeof(operators[])];
	strcopy(op, sizeof(op), operators[GetRandomInt(0,sizeof(operators)-1)]);

	int nbr1, nbr2 = GetRandomInt(nbrmin, nbrmax);

	if(strcmp(op, DIVISOR))
	{
		nbr1 = GetRandomInt(nbrmin, nbrmax);
		questionResult = strcmp(op, PLUS) ? strcmp(op, MINUS) ? nbr1 * nbr2:nbr1 - nbr2:nbr1 + nbr2;
	}
	else questionResult = (nbr1 = GetRandomInt(nbrmin/nbr2, nbrmax/nbr2) * nbr2) / nbr2;

	timerQuestionEnd = CreateTimer(timeanswer, EndQuestion, _, TIMER_FLAG_NO_MAPCHANGE);

	credits = GetRandomInt(mincredits, maxcredits);
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i)) 
		{
			CPrintToChat(i, "%t", "MathQuestion", nbr1, op, nbr2, credits);
		}
	}
	return Plugin_Stop;
}

public Action EndQuestion(Handle timer)
{
	SendEndQuestion();
	return Plugin_Stop;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(timerQuestionEnd && StringToInt(sArgs) == questionResult && (questionResult || strcmp(sArgs, "0") == 0))
	{
		int clients[1];
		Shop_GiveClientCredits(clients[0] = client, credits);
		SendEndQuestion(clients[0]);
		EmitSound(clients, 1, soundplay);
	}
}

void SendEndQuestion(int client = 0)
{
	int i = MaxClients;
	if(client)
	{
		while(i)
		{
			if(IsClientInGame(i)) 
			{
				CPrintToChat(i, "%t", "Winner", client, credits);
				
			}
			--i;
		}
		delete timerQuestionEnd;
	}
	else
	{
		while(i)
		{
			if(IsClientInGame(i)) 
			{
				CPrintToChat(i, "%t", "NoAnswer");
			}
			--i;
		}
	}
	OnConfigsExecuted();
}
