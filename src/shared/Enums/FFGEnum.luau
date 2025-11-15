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
	[12] = { Color = Color3.fromHex("#936505"), Label = "Stage XII" },
	[13] = { Color = Color3.fromHex("#805300"), Label = "Stage XIII" },
	[14] = { Color = Color3.fromHex("#6D4200"), Label = "Stage XIV" },
	[15] = { Color = Color3.fromHex("#5A3200"), Label = "Stage XV" },
	[16] = { Color = Color3.fromHex("#472200"), Label = "Stage XVI" },
}

FFGEnum.ATTRIBUTES = {
	IsPurchased = "IsPurchased",
	atPort = "atPort",
	atBoat = "atBoat",
	finishedLoading = "finishedLoading",
	finishedUnloading = "finishedUnloading",
	Tier = "Tier",
	TeamId = "TeamId",
	BuildingId = "BuildingId",
	BuildingName = "BuildingName",
	JobId = "JobId",
	PathStep = "PathStep",
	UnloadLoc = "UnloadLoc",
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
		IsPurchased = "IsPurchased",
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
		Fish = "Fish",
	},
}

FFGEnum.JOB_CATEGORY = {
	Fishing = "Fishing",
	Woodcutting = "Woodcutting",
	Mining = "Mining",
	Transporting = "Transporting",
}

FFGEnum.RESOURCE_TYPE = {
	Fishing = "OpenFish",
	Woodcutting = "Wood",
	Mining = "Ore",
	Transporting = "Fish",
}

FFGEnum.JOB_NAMES = {
	Fishing = "Fisher",
	Woodcutting = "Woodcutter",
	Mining = "Miner",
	Transporting = "Transporter",
}

FFGEnum.JOB_STATE = {
	[1] = "Idle",
	[2] = "Gathering",
	[3] = "Travelling",
	[500] = "Stuck",
}

FFGEnum.JOB_ASSETS = {
	Fishing = "rbxassetid://119061574257660",
	Woodcutting = "rbxassetid://76234482123867",
	Mining = "rbxassetid://111187697712320",
	Transporting = "rbxassetid://135331905621652",
}

FFGEnum.CURRENCY_TYPES = {
	Gold = "Gold",
}

FFGEnum.UI = {
	Icons = {
		Transporting = "rbxassetid://95580835468179",
		Mining = "rbxassetid://74868423178075",
		Woodcutting = "rbxassetid://83412324614307",
		Fishing = "rbxassetid://77902342248833",
		Inventory = "rbxassetid://103276014090684",
		CrewManagement = "rbxassetid://118792170900331",
		Gold = "rbxassetid://113802680310061",
		PadLock = "rbxassetid://78382217391272",
		Minus = "rbxassetid://84352522067310",
		Purchase = "rbxassetid://107460233002169",
		Alert = "rbxassetid://85527034084832",
		ThumbsUp = "rbxassetid://117741528720677",
	},
	Frames = {
		MainUIPanel = "rbxassetid://95574095879865",
		InnerPanel = "rbxassetid://132276661423012",
		ListItem = "rbxassetid://94314557664644",
		NameplateBackground = "rbxassetid://86748504086845",
		LootNotificationBackground = "rbxassetid://84064232013782",
	},
	Tabs = {
		RightTab = "rbxassetid://132317085020730",
		RightHoverTab = "rbxassetid://117556452240179",
		LeftTab = "rbxassetid://93554848747790",
		LeftHoverTab = "rbxassetid://122393201136941",
		BaseColor = Color3.fromRGB(152, 0, 5),
		SelectedColor = Color3.fromRGB(235, 16, 23),
	},
	Buttons = {
		Green = {
			ScaleType = Rect.new(25, 64, 39, 161),
			Image = "rbxassetid://128292351912310",
		},
		ButtonImages = {
			SquareColor = {
				Green = "rbxassetid://117523854412152",
				Blue = "rbxassetid://106924732482845", -- pressed/hovered
				BlueGray = "rbxassetid://97163201361197",
				Gray = "rbxassetid://120715593495406", -- disabled
				Orange = "rbxassetid://83441298838791",
				Purple = "rbxassetid://125793396941611",
				Red = "rbxassetid://94099958341252",
				SkyBlue = "rbxassetid://130856420084871",
				White = "rbxassetid://136257301484168",
				Yellow = "rbxassetid://122172302659103",
			},
			Assign = "rbxassetid://130413344361128",
			Unassign = "rbxassetid://113359020701380",
		},
	},
	Items = {
		Hovered = "rbxassetid://119714101000238",
		BackgroundQualityId = {
			[1] = "rbxassetid://116550160036557",
			[2] = "rbxassetid://79683515767790",
			[3] = "rbxassetid://91830357643705",
			[4] = "rbxassetid://138089822484721",
			[5] = "rbxassetid://120034088685825",
			[6] = "rbxassetid://127554426008778",
		},
	},
	ProgressBar = {
		BackgroundWhite = { Asset = "rbxassetid://79661382966531", SliceCenter = Rect.new(62, 72, 72, 77) },
		BackgroundColor = Color3.fromRGB(6, 38, 65),
		InnerBar = {
			White = { Asset = "rbxassetid://79661382966531", SliceCenter = Rect.new(62, 72, 72, 77) },
			Green = { Asset = "rbxassetid://94055042028287", SliceCenter = Rect.new(19, 74, 26, 77) },
			BlueTrape = { Asset = "rbxassetid://77539319651665", SliceCenter = Rect.new(0, 9, 308, 33) },
		},
	},
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
	bigFont = Enum.Font.Bangers,
	normalFont = Enum.Font.FredokaOne,

	color = {
		primary_900 = Color3.fromHex("#fc8500"),
		primary_800 = Color3.fromHex("#fdaf00"),
		primary_700 = Color3.fromHex("#fdc80e"),
		primary_600 = Color3.fromHex("#fce01d"),
		primary_500 = Color3.fromHex("#f2ea14"),
		primary_400 = Color3.fromHex("#f5ef43"),
		primary_300 = Color3.fromHex("#f8f467"),
		primary_200 = Color3.fromHex("#fbf890"),
		primary_100 = Color3.fromHex("#fdfcb7"),
		primary_50 = Color3.fromHex("#ffffdd"),

		complementary_900 = Color3.fromHex("#6d4eb4"),
		complementary_800 = Color3.fromHex("#7a62cb"),
		complementary_700 = Color3.fromHex("#816dd7"),
		complementary_600 = Color3.fromHex("#8c79e6"),
		complementary_500 = Color3.fromHex("#9483f2"),
		complementary_400 = Color3.fromHex("#a199f7"),
		complementary_300 = Color3.fromHex("#b2b0fc"),
		complementary_200 = Color3.fromHex("#c8c8fe"),
		complementary_100 = Color3.fromHex("#ddddff"),
		complementary_50 = Color3.fromHex("#f2f2ff"),

		orange_900 = Color3.fromHex("#d41912"),
		orange_800 = Color3.fromHex("#df4110"),
		orange_700 = Color3.fromHex("#e6540d"),
		orange_600 = Color3.fromHex("#ed6408"),
		orange_500 = Color3.fromHex("#f17002"),
		orange_400 = Color3.fromHex("#f58420"),
		orange_300 = Color3.fromHex("#f89a44"),
		orange_200 = Color3.fromHex("#fbb777"),
		orange_100 = Color3.fromHex("#fed4ac"),
		orange_50 = Color3.fromHex("#ffeedd"),

		green_900 = Color3.fromHex("#639950"),
		green_800 = Color3.fromHex("#86bd63"),
		green_700 = Color3.fromHex("#99d26e"),
		green_600 = Color3.fromHex("#afe97a"),
		green_500 = Color3.fromHex("#bdf781"),
		green_400 = Color3.fromHex("#c8fa95"),
		green_300 = Color3.fromHex("#d4fcab"),
		green_200 = Color3.fromHex("#e1fec5"),
		green_100 = Color3.fromHex("#eeffdd"),
		green_50 = Color3.fromHex("#f8fff2"),

		teal_900 = Color3.fromHex("#298782"),
		teal_800 = Color3.fromHex("#2eacaf"),
		teal_700 = Color3.fromHex("#31c1c7"),
		teal_600 = Color3.fromHex("#35d9e3"),
		teal_500 = Color3.fromHex("#38eaf7"),
		teal_400 = Color3.fromHex("#46eff7"),
		teal_300 = Color3.fromHex("#61f4f9"),
		teal_200 = Color3.fromHex("#8af9fb"),
		teal_100 = Color3.fromHex("#b4fcfc"),
		teal_50 = Color3.fromHex("#ddffff"),

		panel = Color3.fromHex("#bdae92"),
		border = Color3.fromHex("#bfb893"),
		text = Color3.fromHex("#5e777c"),
		buttons = Color3.fromHex("#e88f57"),
		subtle = Color3.fromRGB(95, 85, 80),

		red = Color3.fromRGB(249, 65, 68),
		orange = Color3.fromRGB(243, 114, 44),
		amber = Color3.fromRGB(248, 150, 30),
		coral = Color3.fromRGB(249, 132, 74),
		Yellow = Color3.fromRGB(249, 199, 79),

		Green = Color3.fromHex("#3EFF3E"),
		teal = Color3.fromRGB(67, 170, 139),
		tealBlue = Color3.fromRGB(77, 144, 142),
		slateBlue = Color3.fromRGB(87, 117, 144),
		Blue = Color3.fromHex("#0070DD"),

		white = Color3.fromRGB(255, 255, 255),
		black = Color3.fromRGB(20, 20, 20),
		textBody = Color3.fromHex("#F2F4F8"),
		textMuted = Color3.fromHex("#C8D4E8"),
		textGold = Color3.fromHex("#FFD54F"),
		textOrange = Color3.fromHex("#FFB74D"),
		textMagenta = Color3.fromHex("#F26DF9"),
	},

	intent = {
		accent = Color3.fromRGB(67, 170, 139),
		success = Color3.fromRGB(144, 190, 109),
		info = Color3.fromRGB(39, 125, 161),
		warning = Color3.fromRGB(248, 150, 30),
		danger = Color3.fromRGB(249, 65, 68),
		notice = Color3.fromRGB(249, 199, 79),
		disabled = Color3.fromRGB(108, 146, 179),
	},

	-- Sizing/styling
	radius = 8,
	padding = 10,
	strokeTransparency = 0.25,
	hoverStrokeColor = Color3.fromRGB(67, 170, 139),

	Nameplate = {
		MaxDistance = 100,
	},

	sizes = {
		button = UDim2.fromScale(0.40, 0.10),
		panel = UDim2.fromScale(0.80, 0.50),
	},

	button = {
		disabledColor = Color3.fromRGB(87, 117, 144),
		pressedColor = Color3.fromHex("1976D2"),
		white = "rbxassetid://118445227667136",
		shopBuy = "rbxassetid://103266412720403",
		shopBuyHover = "rbxassetid://122918373699379",
		shopBuyDisabled = "rbxassetid://87220614829273",
		image = "rbxassetid://80427328338898",
		hoverImage = "rbxassetid://80427328338898",
		pressedImage = "rbxassetid://72623624680339",
		cornerRadius = UDim.new(0.1),
	},

	tab = {
		red = Color3.fromRGB(152, 0, 5),
	},

	shop = {
		shopItem = {
			buttonColor = Color3.fromHex("e88f57"),
			bgColor = Color3.fromHex("ffffdd"),
			outline = Color3.fromHex("b9bc98"),
			element = Color3.fromHex("f6c794"),
			outlineThickness = 3,
		},
		shopTooltip = {
			frameTriangle = "rbxassetid://108183848038135",
			outlineThickness = 5,
			border = Color3.fromHex("ffffdd"),
		},
	},

	frameEffects = {
		CircleBloom = "rbxassetid://91163708935372",
	},

	alignment = {
		position = {
			center = UDim2.fromScale(0.5, 0.5),
			frameHeader = UDim2.fromScale(0.5, 0),
			top = UDim2.fromScale(0.5, 0),
			bottom = UDim2.fromScale(0.5, 1),
			textCenter = UDim2.fromScale(0.5, 0.45),
			textFrameHeaderCenter = UDim2.fromScale(0.5, 0.35),
		},
		anchor = {
			frameHeader = Vector2.new(0.5, 0),
			top = Vector2.new(0.5, 0),
			bottom = Vector2.new(0.5, 1),
			center = Vector2.new(0.5, 0.5),
			left = Vector2.new(0, 0.5),
		},
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
