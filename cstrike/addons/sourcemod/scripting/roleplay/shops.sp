int g_SaleFrom[MAXPLAYERS + 1];
int g_SaleIndex[MAXPLAYERS + 1];
int g_SaleTime[MAXPLAYERS + 1];
float g_SaleShown[MAXPLAYERS + 1];
int g_ShopEnt[MAXPLAYERS + 1];
float g_ShopDistance[MAXPLAYERS + 1];

#define SALE_DISTANCE 300.0
#define CHIRURGIE_MAX 500

void Sale_Reset(int client)
{
	g_SaleFrom[client] = 0;
	g_SaleIndex[client] = -1;
}

static void Shop_Remember(int client, int ent, float maxDistance)
{
	g_ShopEnt[client] = EntIndexToEntRef(ent);
	g_ShopDistance[client] = maxDistance;
}

static bool Shop_StillThere(int client)
{
	int ent = EntRefToEntIndex(g_ShopEnt[client]);
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_Jailed[client] || ent == INVALID_ENT_REFERENCE)
	{
		return false;
	}
	if (DistanceTo(client, ent) > g_ShopDistance[client])
	{
		PrintToChat(client, "%s : Vous êtes trop loin.", LOGO);
		return false;
	}
	return true;
}

void Shops_OnUse(int client, int ent)
{
	if (g_Jailed[client])
	{
		return;
	}
	if (InAnyDistributor(ent))
	{
		if (DistanceTo(client, ent) > 80.0)
		{
			PrintToChat(client, "%s : Vous êtes trop loin de la banque.", LOGO);
		}
		else if (g_RIB[client] <= 0)
		{
			PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
		}
		else
		{
			Shop_Remember(client, ent, 80.0);
			Menu menu = new Menu(Menu_Bank);
			menu.SetTitle("Banque Oviscity :");
			menu.AddItem("deposit", "Déposer de l'argent");
			menu.AddItem("withdraw", "Retirer de l'argent");
			menu.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (InZone(ent, ZONE_MAFIA))
	{
		if (JOB_GROUP[g_Job[client]] != GROUP_MAFIA)
		{
			PrintToChat(client, "%s : Vous devez être mafieux.", LOGO);
		}
		else if (DistanceTo(client, ent) > REACH)
		{
			PrintToChat(client, "%s : Vous êtes trop loin.", LOGO);
		}
		else if (g_Item[client][ITEM_KIT] >= KIT_MAX)
		{
			PrintToChat(client, "%s : Vous avez le maximum de kits de crochetage (%d).", LOGO, KIT_MAX);
		}
		else
		{
			g_Item[client][ITEM_KIT]++;
			PrintToChat(client, "%s : Vous avez pris un kit de crochetage [%d/%d].", LOGO, g_Item[client][ITEM_KIT], KIT_MAX);
		}
	}
	else if (InZone(ent, ZONE_ARMU))
	{
		OpenShop(client, ent, SHOP_ARMU, 300.0);
	}
	else if (g_TourismHammerId != 0 && GetEntProp(ent, Prop_Data, "m_iHammerID") == g_TourismHammerId)
	{
		OpenTourism(client, ent);
	}
	else if (InZone(ent, ZONE_LOTO))
	{
		OpenShop(client, ent, SHOP_LOTO, 200.0);
	}
	else if (InZone(ent, ZONE_HOSTO))
	{
		if (DistanceTo(client, ent) > 300.0)
		{
			PrintToChat(client, "%s : Vous êtes trop loin du PNJ.", LOGO);
			return;
		}
		Shop_Remember(client, ent, 300.0);
		Menu menu = new Menu(Menu_Hosto);
		menu.SetTitle("Hôpital de oviscity :");
		menu.AddItem("0", "Soin Partiel 200$");
		menu.AddItem("1", "Soin Complet 400$");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if (InZone(ent, ZONE_EBAY))
	{
		OpenShop(client, ent, SHOP_DROGUE, 400.0);
	}
}

public int Menu_Bank(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (!Shop_StillThere(client) || g_RIB[client] <= 0)
		{
			return 0;
		}
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		bool deposit = StrEqual(info, "deposit");
		static const int deposits[] = { 10, 50, 100, 200, 500, 1000, 2000, 5000 };
		static const int withdrawals[] = { 5, 10, 50, 100, 200, 500, 1000, 2000, 5000, 10000 };
		int cash = GetCash(client);
		Menu amounts = deposit ? new Menu(Menu_Deposit) : new Menu(Menu_Withdraw);
		amounts.SetTitle("Choisis la somme :");
		char value[16], display[16];
		if (deposit)
		{
			for (int i = 0; i < sizeof(deposits); i++)
			{
				if (cash >= deposits[i])
				{
					IntToString(deposits[i], value, sizeof(value));
					FormatEx(display, sizeof(display), "%d$", deposits[i]);
					amounts.AddItem(value, display);
				}
			}
			if (cash > 0)
			{
				amounts.AddItem("all", "Tout");
			}
		}
		else
		{
			for (int i = 0; i < sizeof(withdrawals); i++)
			{
				if (g_Bank[client] >= withdrawals[i])
				{
					IntToString(withdrawals[i], value, sizeof(value));
					FormatEx(display, sizeof(display), "%d$", withdrawals[i]);
					amounts.AddItem(value, display);
				}
			}
		}
		if (amounts.ItemCount == 0)
		{
			if (deposit)
			{
				PrintToChat(client, "%s : Vous n'avez pas d'argent à déposer.", LOGO);
			}
			else
			{
				PrintToChat(client, "%s : Tu n'as pas d'argent à retirer.", LOGO);
			}
			delete amounts;
			return 0;
		}
		amounts.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_Deposit(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (!Shop_StillThere(client) || g_RIB[client] <= 0)
		{
			return 0;
		}
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int cash = GetCash(client);
		int amount = StrEqual(info, "all") ? cash : StringToInt(info);
		if (amount > 0 && amount <= cash)
		{
			amount = AddBank(client, amount);
			SetCash(client, cash - amount);
			PrintToChat(client, "%s : Vous avez déposé %d$.", LOGO, amount);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_Withdraw(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (!Shop_StillThere(client) || g_RIB[client] <= 0)
		{
			return 0;
		}
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int amount = StringToInt(info);
		int room = MAX_CASH - GetCash(client);
		if (amount > g_Bank[client])
		{
			PrintToChat(client, "%s : Vous n'avez pas assez d'argent pour cette transaction.", LOGO);
		}
		else if (room <= 0)
		{
			PrintToChat(client, "%s : Tu ne peux pas avoir plus d'argent sur toi.", LOGO);
		}
		else
		{
			if (amount > room)
			{
				amount = room;
			}
			g_Bank[client] -= amount;
			SetCash(client, GetCash(client) + amount);
			PrintToChat(client, "%s : Tu as retiré %d$.", LOGO, amount);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void OpenShop(int client, int ent, int shop, float maxDistance)
{
	if (DistanceTo(client, ent) > maxDistance)
	{
		PrintToChat(client, "%s : Vous êtes trop loin du PNJ.", LOGO);
		return;
	}
	Shop_Remember(client, ent, maxDistance);
	char info[16], display[64];
	Menu menu = new Menu(Menu_Shop);
	menu.SetTitle("%s", SHOP_TITLE[shop]);
	int count = ShopSize(shop);
	for (int i = 0; i < count; i++)
	{
		int item, price, capital;
		ShopEntry(shop, i, item, price, capital);
		FormatEx(info, sizeof(info), "%d %d", shop, i);
		FormatEx(display, sizeof(display), "%s %d$", ITEM_LABEL[item], price);
		menu.AddItem(info, display);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

static int ShopSize(int shop)
{
	switch (shop)
	{
		case SHOP_ARMU: return sizeof(SHOP_ARMU_ITEM);
		case SHOP_DROGUE: return sizeof(SHOP_DROGUE_ITEM);
	}
	return sizeof(SHOP_LOTO_ITEM);
}

static void ShopEntry(int shop, int i, int &item, int &price, int &capital)
{
	switch (shop)
	{
		case SHOP_ARMU:
		{
			item = SHOP_ARMU_ITEM[i];
			price = SHOP_ARMU_PRICE[i];
			capital = SHOP_ARMU_CAPITAL[i];
		}
		case SHOP_DROGUE:
		{
			item = SHOP_DROGUE_ITEM[i];
			price = SHOP_DROGUE_PRICE[i];
			capital = SHOP_DROGUE_CAPITAL[i];
		}
		default:
		{
			item = SHOP_LOTO_ITEM[i];
			price = SHOP_LOTO_PRICE[i];
			capital = SHOP_LOTO_CAPITAL[i];
		}
	}
}

public int Menu_Shop(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16], parts[2][8];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info, " ", parts, sizeof(parts), sizeof(parts[]));
		int shop = StringToInt(parts[0]), index = StringToInt(parts[1]);
		if (!Shop_StillThere(client) || shop < 0 || shop >= SHOP_COUNT || index < 0 || index >= ShopSize(shop))
		{
			return 0;
		}
		int item, price, capital;
		ShopEntry(shop, index, item, price, capital);
		if (GetCash(client) < price)
		{
			PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
			return 0;
		}
		SetCash(client, GetCash(client) - price);
		g_Item[client][item]++;
		g_Capital += capital;
		PrintToChat(client, "%s : Vous avez acheté : %s.", LOGO, ITEM_LABEL[item]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Menu_Hosto(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param2, info, sizeof(info));
		int i = StringToInt(info);
		if (i < 0 || i > 1 || !Shop_StillThere(client))
		{
			return 0;
		}
		if (!NeedsCare(client))
		{
			PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
			return 0;
		}
		if (GetCash(client) < HOSTO_PRICE[i])
		{
			PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
			return 0;
		}
		SetCash(client, GetCash(client) - HOSTO_PRICE[i]);
		Heal(client, HOSTO_HEAL[i]);
		g_Capital += HOSTO_CAPITAL[i];
		RingEffect(client, 20.0, 100.0, i == 0 ? COLOR_BLUE : COLOR_ORANGE);
		PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static int CareMax(int client)
{
	return GetClientTeam(client) == CS_TEAM_CT ? 500 : 100;
}

static bool NeedsCare(int client)
{
	return GetClientHealth(client) < CareMax(client);
}

static void Heal(int client, int amount)
{
	int health = GetClientHealth(client) + amount;
	SetEntityHealth(client, health > CareMax(client) ? CareMax(client) : health);
}

static void OpenTourism(int client, int ent)
{
	if (DistanceTo(client, ent) > g_TourismDistance)
	{
		PrintToChat(client, "%s : Vous êtes trop loin du PNJ.", LOGO);
		return;
	}
	if (g_LinkTitles.Length == 0)
	{
		return;
	}
	Shop_Remember(client, ent, g_TourismDistance);
	char title[64], info[8];
	Menu menu = new Menu(Menu_Tourism);
	menu.SetTitle("Agence de tourisme d'oviscity :");
	for (int i = 0; i < g_LinkTitles.Length; i++)
	{
		g_LinkTitles.GetString(i, title, sizeof(title));
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, title);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Tourism(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8], title[64], url[192];
		menu.GetItem(param2, info, sizeof(info));
		int i = StringToInt(info);
		if (i >= 0 && i < g_LinkUrls.Length && Shop_StillThere(client))
		{
			g_LinkTitles.GetString(i, title, sizeof(title));
			g_LinkUrls.GetString(i, url, sizeof(url));
			ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Command_Vendre(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		return Plugin_Handled;
	}
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas vendre en prison.", LOGO);
		return Plugin_Handled;
	}
	int job = g_Job[client];
	if (job == 0)
	{
		PrintToChat(client, "%s : Vous n'avez pas de travail.", LOGO);
		return Plugin_Handled;
	}
	int buyer = AimedPlayer(client);
	if (buyer == 0)
	{
		PrintToChat(client, "%s : Tu dois viser un joueur.", LOGO);
		return Plugin_Handled;
	}
	if (DistanceTo(client, buyer) > SALE_DISTANCE)
	{
		PrintToChat(client, "%s : Vous êtes trop loin de ce joueur.", LOGO);
		return Plugin_Handled;
	}

	char info[24];
	if (args >= 1)
	{
		GetCmdArg(1, info, sizeof(info));
		int sale = -1;
		if (StrEqual(info, "chirurgie", false))
		{
			sale = SALE_CHIRURGIE;
		}
		for (int i = 0; i < SALE_COUNT && sale == -1; i++)
		{
			if (StrEqual(info, SALE_KEY[i], false))
			{
				sale = i;
			}
		}
		if (sale == -1 || !CanSell(job, sale) || (sale != SALE_CHIRURGIE && AlreadyOwned(buyer, sale)))
		{
			PrintToChat(client, "%s : Vous ne pouvez pas vendre « %s » à ce joueur.", LOGO, info);
			return Plugin_Handled;
		}
		Sale_Offer(client, buyer, sale);
		return Plugin_Handled;
	}
	Menu menu = new Menu(Menu_Vendre);
	menu.SetTitle("Choisis l'article à vendre :");
	for (int i = 0; i < SALE_COUNT; i++)
	{
		if (!CanSell(job, i) || AlreadyOwned(buyer, i))
		{
			continue;
		}
		FormatEx(info, sizeof(info), "%d %d", GetClientUserId(buyer), i);
		menu.AddItem(info, SALE_LABEL[i]);
	}
	if (job == 30)
	{
		FormatEx(info, sizeof(info), "%d %d", GetClientUserId(buyer), SALE_CHIRURGIE);
		menu.AddItem(info, "Chirurgie 1000$");
	}
	if (menu.ItemCount == 0)
	{
		PrintToChat(client, "%s : Votre métier n'a rien à vendre.", LOGO);
		delete menu;
		return Plugin_Handled;
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

static bool CanSell(int job, int sale)
{
	return sale == SALE_CHIRURGIE ? job == 30 : (job >= SALE_JOBMIN[sale] && job <= SALE_JOBMAX[sale]);
}

static bool AlreadyOwned(int buyer, int sale)
{
	switch (SALE_EFFECT[sale])
	{
		case EFFECT_PERMIS_LEGER: return g_PermisLeger[buyer] > 0;
		case EFFECT_PERMIS_LOURD: return g_PermisLourd[buyer] > 0;
		case EFFECT_RIB: return g_RIB[buyer] > 0;
		case EFFECT_CB: return g_CB[buyer] > 0;
	}
	return false;
}

public int Menu_Vendre(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24], parts[2][12];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info, " ", parts, sizeof(parts), sizeof(parts[]));
		int buyer = GetClientOfUserId(StringToInt(parts[0]));
		int sale = StringToInt(parts[1]);
		if (buyer == 0 || !IsPlayerAlive(buyer))
		{
			PrintToChat(client, "%s : L'acheteur n'est plus là.", LOGO);
			return 0;
		}
		Sale_Offer(client, buyer, sale);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

static void Sale_Offer(int seller, int buyer, int sale)
{
	if (!IsPlayerAlive(seller) || g_Jailed[seller] || sale < 0 || sale > SALE_CHIRURGIE || !CanSell(g_Job[seller], sale))
	{
		return;
	}
	if (DistanceTo(seller, buyer) > SALE_DISTANCE)
	{
		PrintToChat(seller, "%s : Vous êtes trop loin de ce joueur.", LOGO);
		return;
	}
	if (g_SaleFrom[buyer] != 0 && g_SaleFrom[buyer] != GetClientUserId(seller) && GetTime() - g_SaleTime[buyer] < 30)
	{
		PrintToChat(seller, "%s : Ce joueur a déjà une proposition en attente.", LOGO);
		return;
	}
	g_SaleFrom[buyer] = GetClientUserId(seller);
	g_SaleIndex[buyer] = sale;
	g_SaleTime[buyer] = GetTime();
	g_SaleShown[buyer] = GetGameTime();
	Sale_ShowMenu(buyer);
	PrintToChat(buyer, "%s : %N vous propose : %s. !accepter ou !refuser.", LOGO, seller,
		sale == SALE_CHIRURGIE ? "Chirurgie 1000$" : SALE_LABEL[sale]);
	PrintToChat(seller, "%s : Proposition envoyée à %N.", LOGO, buyer);
}

static void Sale_ShowMenu(int buyer)
{
	int sale = g_SaleIndex[buyer];
	char info[24];
	Menu confirm = new Menu(Menu_Achat);
	confirm.SetTitle("%s", sale == SALE_CHIRURGIE ? "Voulez-vous acheter une Chirurgie à 1000$ ?" : SALE_QUESTION[sale]);
	FormatEx(info, sizeof(info), "oui %d %d", g_SaleFrom[buyer], sale);
	confirm.AddItem(info, "Oui je veux");
	FormatEx(info, sizeof(info), "non %d %d", g_SaleFrom[buyer], sale);
	confirm.AddItem(info, "Non merci");
	confirm.Display(buyer, MENU_TIME_FOREVER);
}

public int Menu_Achat(Menu menu, MenuAction action, int buyer, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24], parts[3][12];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info, " ", parts, sizeof(parts), sizeof(parts[]));
		if (StringToInt(parts[1]) != g_SaleFrom[buyer] || StringToInt(parts[2]) != g_SaleIndex[buyer])
		{
			PrintToChat(buyer, "%s : Cette vente n'est plus valable.", LOGO);
			return 0;
		}
		Sale_Answer(buyer, StrEqual(parts[0], "oui"));
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

bool Sale_Pending(int buyer)
{
	return g_SaleFrom[buyer] != 0;
}

void Sale_Answer(int buyer, bool accept)
{
	if (accept && g_SaleFrom[buyer] != 0 && JustProposed(buyer, g_SaleShown[buyer]))
	{
		Sale_ShowMenu(buyer);
		return;
	}
	int seller = GetClientOfUserId(g_SaleFrom[buyer]);
	int sale = g_SaleIndex[buyer];
	Sale_Reset(buyer);
	if (seller == 0 || sale < 0 || sale > SALE_CHIRURGIE || !IsPlayerAlive(buyer))
	{
		PrintToChat(buyer, "%s : Cette vente n'est plus valable.", LOGO);
		return;
	}
	if (!accept)
	{
		PrintToChat(buyer, "%s : Vous avez refusé.", LOGO);
		PrintToChat(seller, "%s : Le client %N a refusé.", LOGO, buyer);
		return;
	}
	Sale_Complete(seller, buyer, sale);
}

static void Sale_Complete(int seller, int buyer, int sale)
{
	bool chirurgie = sale == SALE_CHIRURGIE;
	int effect = chirurgie ? EFFECT_CHIRURGIE : SALE_EFFECT[sale];
	int price = chirurgie ? SALE_CHIRURGIE_PRICE : SALE_PRICE[sale];
	int sellerShare = chirurgie ? SALE_CHIRURGIE_SELLER : SALE_SELLER[sale];
	int capital = chirurgie ? SALE_CHIRURGIE_CAPITAL : SALE_CAPITAL[sale];

	if (!CanSell(g_Job[seller], sale) || !IsPlayerAlive(seller) || g_Jailed[seller] || DistanceTo(seller, buyer) > SALE_DISTANCE)
	{
		PrintToChat(buyer, "%s : Cette vente n'est plus valable.", LOGO);
		return;
	}
	if (effect == EFFECT_SOIN && !NeedsCare(buyer))
	{
		PrintToChat(buyer, "%s : Vous avez déjà votre vie.", LOGO);
		return;
	}
	if (chirurgie && GetClientHealth(buyer) >= CHIRURGIE_MAX)
	{
		PrintToChat(buyer, "%s : Une chirurgie ne vous apporterait rien de plus.", LOGO);
		return;
	}
	if (!chirurgie && AlreadyOwned(buyer, sale))
	{
		PrintToChat(buyer, "%s : Vous l'avez déjà.", LOGO);
		return;
	}
	if (!Pay(buyer, price, effect == EFFECT_RIB || effect == EFFECT_CB))
	{
		PrintToChat(buyer, "%s : Vous n'avez pas assez d'argent.", LOGO);
		PrintToChat(seller, "%s : Le joueur n'a pas assez d'argent.", LOGO);
		return;
	}
	switch (effect)
	{
		case EFFECT_ITEM: g_Item[buyer][SALE_ITEM[sale]]++;
		case EFFECT_LEVELCUT: g_Item[buyer][ITEM_LEVELCUT] = 100;
		case EFFECT_PERMIS_LEGER: g_PermisLeger[buyer] = 1;
		case EFFECT_PERMIS_LOURD: g_PermisLourd[buyer] = 1;
		case EFFECT_RIB: g_RIB[buyer] = 1;
		case EFFECT_CB: g_CB[buyer] = 1;
		case EFFECT_SOIN: Heal(buyer, SALE_ITEM[sale]);
		case EFFECT_CHIRURGIE:
		{
			int health = GetClientHealth(buyer) + 150;
			SetEntityHealth(buyer, health > CHIRURGIE_MAX ? CHIRURGIE_MAX : health);
			SetEntPropFloat(buyer, Prop_Data, "m_flLaggedMovementValue", 1.4);
		}
	}
	AddCash(seller, sellerShare);
	g_Capital += capital;
	PrintToChat(seller, "%s : Le client %N a accepté.", LOGO, buyer);
	PrintToChat(buyer, "%s : Achat réalisé avec succès.", LOGO);
}

public Action Command_Give(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous ne pouvez pas utiliser cette commande quand vous êtes mort.", LOGO);
		return Plugin_Handled;
	}
	if (args < 1)
	{
		PrintToChat(client, "%s : Usage : sm_give <montant>", LOGO);
		return Plugin_Handled;
	}
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas donner de l'argent en prison.", LOGO);
		return Plugin_Handled;
	}
	char arg[16];
	GetCmdArg(1, arg, sizeof(arg));
	int amount = StringToInt(arg);
	if (amount <= 0)
	{
		PrintToChat(client, "%s : Vous ne pouvez pas donner une somme négative ou nulle.", LOGO);
		return Plugin_Handled;
	}
	if (amount > GetCash(client))
	{
		PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0)
	{
		PrintToChat(client, "%s : Tu dois regarder un joueur.", LOGO);
		return Plugin_Handled;
	}
	SetCash(client, GetCash(client) - amount);
	AddCash(target, amount);
	PrintToChat(client, "%s : Tu as donné %d$ à %N.", LOGO, amount, target);
	PrintToChat(target, "%s : Tu as reçu %d$ de %N.", LOGO, amount, client);
	return Plugin_Handled;
}

public Action Command_Vol(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s : Vous devez être en vie pour utiliser cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (JOB_GROUP[g_Job[client]] != GROUP_MAFIA)
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande.", LOGO);
		return Plugin_Handled;
	}
	if (g_Jailed[client])
	{
		PrintToChat(client, "%s : Vous ne pouvez pas voler en prison.", LOGO);
		return Plugin_Handled;
	}
	int target = AimedPlayer(client);
	if (target == 0)
	{
		PrintToChat(client, "%s : Vous devez viser un joueur.", LOGO);
		return Plugin_Handled;
	}
	int amount = GetRandomInt(1, 300);
	if (amount > GetCash(target))
	{
		PrintToChat(client, "%s : Le joueur n'a pas d'argent sur lui.", LOGO);
		return Plugin_Handled;
	}
	int wait = g_LastTheft[client] + 30 - GetTime();
	if (wait > 0)
	{
		PrintToChat(client, "%s : Vous devez attendre %d secondes avant de pouvoir voler.", LOGO, wait);
		return Plugin_Handled;
	}
	if (DistanceTo(client, target) > 80.0)
	{
		PrintToChat(client, "%s : Vous êtes trop loin pour voler cette personne.", LOGO);
		return Plugin_Handled;
	}
	g_LastTheft[client] = GetTime();
	SetCash(target, GetCash(target) - amount);
	AddCash(client, amount);
	g_Capital += 500;
	RingEffect(client, 5.0, 180.0, COLOR_GREEN);
	PrintToChat(client, "%s : Vous avez volé %d$.", LOGO, amount);
	PrintToChat(target, "%s : Vous avez perdu %d$ suite à un vol.", LOGO, amount);
	return Plugin_Handled;
}
