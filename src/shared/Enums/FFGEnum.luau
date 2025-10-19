local FFGEnum = {}

FFGEnum.QUALITIES = {
	[1] = {
		Label = "Common",
		Color = Color3.fromRGB(251, 245, 236),
		DropChance = 60,
	},
	[2] = {
		Label = "Uncommon",
		Color = Color3.fromHex("#3EFF3E"),
		DropChance = 25,
	},
	[3] = {
		Label = "Rare",
		Color = Color3.fromHex("#0070DD"),
		DropChance = 10,
	},
	[4] = {
		Label = "Epic",
		Color = Color3.fromHex("#A335EE"),
		DropChance = 4,
	},
	[5] = {
		Label = "Legendary",
		Color = Color3.fromHex("#FF9A00"),
		DropChance = 0.9,
	},
	[6] = {
		Label = "Mythic",
		Color = Color3.fromHex("#FF3B3B"),
		DropChance = 0.1,
	},
}

FFGEnum.STAGES = {
	[1] = { Color = Color3.fromHex("#B0B0B0"), Label = "Stage I" },
	[2] = { Color = Color3.fromHex("#C0C0C0"), Label = "Stage II" },
	[3] = { Color = Color3.fromHex("#D0D0D0"), Label = "Stage III" },
	[4] = { Color = Color3.fromHex("#E0E0E0"), Label = "Stage IV" },
	[5] = { Color = Color3.fromHex("#F0F0F0"), Label = "Stage V" },
	[6] = { Color = Color3.fromHex("#F5F2E7"), Label = "Stage VI" },
	[7] = { Color = Color3.fromHex("#E7D6A8"), Label = "Stage VII" },
	[8] = { Color = Color3.fromHex("#D8B970"), Label = "Stage VIII" },
	[9] = { Color = Color3.fromHex("#C9A242"), Label = "Stage IX" },
	[10] = { Color = Color3.fromHex("#B98C1F"), Label = "Stage X" },
	[11] = { Color = Color3.fromHex("#A67812"), Label = "Stage XI" },
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

FFGEnum.CATEGORIES = {
	[1] = "Fishing",
	[2] = "Woodcutting",
	[3] = "Mining",
	[4] = "Transport",
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

FFGEnum.THEME = {
	font = Enum.Font.FredokaOne,

	color = {
		panel = Color3.fromRGB(181, 136, 99), -- Oak
		border = Color3.fromRGB(180, 123, 65), -- Walnut frame
		text = Color3.fromRGB(250, 240, 210), -- Parchment
		subtle = Color3.fromRGB(95, 85, 80), -- Stone/secondary text

		red = Color3.fromRGB(249, 65, 68),
		orange = Color3.fromRGB(243, 114, 44),
		amber = Color3.fromRGB(248, 150, 30),
		coral = Color3.fromRGB(249, 132, 74),
		yellow = Color3.fromRGB(249, 199, 79),

		green = Color3.fromHex("#1dea2b"),
		teal = Color3.fromRGB(67, 170, 139),
		tealBlue = Color3.fromRGB(77, 144, 142),
		slateBlue = Color3.fromRGB(87, 117, 144),
		blue = Color3.fromRGB(39, 125, 161),

		white = Color3.fromRGB(255, 255, 255),
		black = Color3.fromRGB(20, 20, 20),
	},

	intent = {
		accent = Color3.fromRGB(67, 170, 139),
		success = Color3.fromRGB(144, 190, 109),
		info = Color3.fromRGB(39, 125, 161),
		warning = Color3.fromRGB(248, 150, 30),
		danger = Color3.fromRGB(249, 65, 68),
		notice = Color3.fromRGB(249, 199, 79),
		muted = Color3.fromRGB(87, 117, 144),
	},

	-- Sizing/styling
	radius = 8,
	padding = 10,
	strokeTransparency = 0.25,
	hoverStrokeColor = Color3.fromRGB(67, 170, 139),

	sizes = {
		button = UDim2.fromScale(0.40, 0.10),
		panel = UDim2.fromScale(0.80, 0.50),
	},

	button = {
		shopBuy = "rbxassetid://103266412720403",
		shopBuyHover = "rbxassetid://122918373699379",
		shopBuyDisabled = "rbxassetid://87220614829273",
		image = "rbxassetid://80427328338898",
		hoverImage = "rbxassetid://80427328338898",
		pressedImage = "rbxassetid://72623624680339",
		cornerRadius = UDim.new(0.1),
	},

	shopItem = {
		bgColor = Color3.fromRGB(23, 139, 241),
	},

	sounds = {
		clicks = game.Workspace.UISounds.Clicks:GetChildren(),
	},

	textColor = {
		[FFGEnum.CLASS.ENTITY_NAME.Boat] = Color3.fromRGB(249, 65, 68),
		[FFGEnum.CLASS.ENTITY_NAME.Tender] = Color3.fromRGB(88, 171, 65),
		[FFGEnum.CLASS.ENTITY_NAME.PortStorage] = Color3.fromRGB(250, 200, 10),
		[FFGEnum.CLASS.ENTITY_NAME.Building] = Color3.fromRGB(214, 121, 35),
	},
}

return FFGEnum
