local FFGEnum = {}

FFGEnum.QUALITY = {
	[1] = {
		Label = "Common",
		Color = Color3.fromRGB(251, 245, 236),
	},
	[2] = {
		Label = "Uncommon",
		Color = Color3.fromHex("#3EFF3E"),
	},
	[3] = {
		Label = "Rare",
		Color = Color3.fromHex("#0070DD"),
	},
	[4] = {
		Label = "Epic",
		Color = Color3.fromHex("#A335EE"),
	},
	[5] = {
		Label = "Legendary",
		Color = Color3.fromHex("#FF9A00"),
	},
	[6] = {
		Label = "Exotic",
		Color = Color3.fromHex("#E6C266"),
	},
	[7] = {
		Label = "Ascended",
		Color = Color3.fromHex("#FF66CC"),
	},
	[8] = {
		Label = "Mythic",
		Color = Color3.fromHex("#00FFFF"),
	},
	[9] = {
		Label = "Divine",
		Color = Color3.fromHex("#FFD700"),
	},
	[10] = {
		Label = "Eternal",
		Color = Color3.fromHex("#C0C0FF"),
	},
	[11] = {
		Label = "Transcendent",
		Color = Color3.fromHex("#F5E663"),
	},
}

FFGEnum.ATTRIBUTES = {
	isPurchased = "isPurchased",
	atPort = "atPort",
	atBoat = "atBoat",
	finishedLoading = "finishedLoading",
	finishedUnloading = "finishedUnloading",
	Tier = "Tier",
	TeamId = "TeamId",
	BuildingId = "BuildingId",
	BuildingName = "BuildingName",
}

FFGEnum.CLASS = {
	PROPERTIES = {
		Id = "Id",
		Owner = "Owner",
		RealmId = "RealmId",
		Tier = "Tier",
		Name = "Name",
		Level = "Level",
		MaxLevel = "MaxLevel",
		BaseCost = "BaseCost",
		UpgradeCost = "UpgradeCost",
		isPurchased = "isPurchased",
		BaseStorage = "BaseStorage",
		UpgradeStage = "UpgradeStage",
		CurrentMaxStorage = "CurrentMaxStorage",
		NextLvlMaxStorage = "NextLvlMaxStorage",
		FishInStorage = "FishInStorage",
		StorageFull = "StorageFull",
		BaseFPS = "BaseFPS",
		CurrentFPS = "CurrentFPS",
		NextFPS = "NextFPS",
		CurrentTravelTime = "CurrentTravelTime",
		NextLvlTravelTime = "NextLvlTravelTime",
		BuildingId = "BuildingId",
		BuildingName = "BuildingName",
	},
	ENTITY_NAME = {
		Boat = "Boat",
		Tender = "Tender",
		PortStorage = "Storage",
		Building = "Building",
		Shop = "Shop",
		Helper = "Helper",
	},
}

FFGEnum.CURRENCY_TYPES = {
	Gold = "Gold",
}

FFGEnum.BUFFS = {
	FISH = {
		Fish_Percent = "Fish_Percent",
		Fish_Multi = "Fish_Multi",
	},
	STORAGE = {
		Boat_Percent = "BoatStorage_Percent",
		Tender_Percent = "TenderStorage_Percent",
		Port_Percent = "PortStorage_Percent",
		Helper_Percent = "HelperStorage_Percent",
		Caravan_Percent = "CaravanStorage_Percent",
	},
	TRAVEL_TIME = {
		Helper_Percent = "HelperTravelTime_Percent",
		Caravan_Percent = "CaravanTravelTime_Percent",
		Tender_Percent = "TenderTravelTime_Percent",
	},
	LOAD_TIME = {
		Tender_Percent = "TenderLoadTime_Percent",
		Helper_Percent = "HelperLoadTime_Percent",
	},
	FPS = {
		FPS_Percent = "FPS_Percent",
	},
	GOLD = {
		PassiveGold_Percent = "PassiveGold_Percent",
		Gold_Multi = "Gold_Multi",
	},
	DURATION = {
		Permanent = "Permanent",
		Temporary = "Temporary",
	},
	SCOPE = {
		Boat = "Boat",
		Tender = "Tender",
		PortStorage = "PortStorage",
		Helper = "Helper",
		Building = "Building",
		Global = "Global",
	},
}

return FFGEnum
