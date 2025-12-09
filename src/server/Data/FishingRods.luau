local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROD_COLOR_RULES = {
	-- Natural / Beginner rods
	["Bamboo"] = Color3.fromRGB(148, 120, 83),
	["Reed"] = Color3.fromRGB(148, 120, 83),
	["Wood"] = Color3.fromRGB(148, 120, 83),
	["Guild"] = Color3.fromRGB(148, 120, 83),

	-- Metal rods
	["Steel"] = Color3.fromRGB(150, 161, 183),
	["Iron"] = Color3.fromRGB(150, 161, 183),
	["Hook"] = Color3.fromRGB(150, 161, 183),

	-- Water / Flow / gentle rods
	["River"] = Color3.fromRGB(69, 112, 171),
	["Pond"] = Color3.fromRGB(69, 112, 171),
	["Tide"] = Color3.fromRGB(69, 112, 171),
	["Current"] = Color3.fromRGB(69, 112, 171),
	["Whisper"] = Color3.fromRGB(69, 112, 171),

	-- Powerful or crafted rods
	["Power"] = Color3.fromRGB(132, 80, 162),
	["Precision"] = Color3.fromRGB(132, 80, 162),
	["Balance"] = Color3.fromRGB(132, 80, 162),
	["Master"] = Color3.fromRGB(132, 80, 162),

	-- High-tier magical rods
	["Storm"] = Color3.fromRGB(226, 178, 78),
	["Deepsea"] = Color3.fromRGB(226, 178, 78),
	["Celestial"] = Color3.fromRGB(56, 228, 221),
	["Angler"] = Color3.fromRGB(56, 228, 221),
	["Scepter"] = Color3.fromRGB(56, 228, 221),
}

local function getRodColorFromName(name: string)
	name = name:lower()

	for keyword, color in pairs(ROD_COLOR_RULES) do
		if string.find(name, keyword:lower()) then return color end
	end

	-- fallback
	return Color3.fromRGB(200, 200, 200)
end

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FishingRods = {
	-- QUALITY 1 (Starter/Budget)
	BambooRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Bamboo Rod",
		Color = getRodColorFromName("Bamboo Rod"),
		Key = "BambooRod",
		Id = 1,
		QualityId = 1,
		BaseDmg = 5,
		Cost = 100000,
		CurrencyType = "Gold",
		LevelRequirement = 1,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 1,
			LineControl = 2,
			Stability = 1,
		},
		Description = "A simple rod for beginners. Light and forgiving, but weak.",
	},

	ApprenticeRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Apprentice Rod",
		Color = getRodColorFromName("Apprentice Rod"),
		Key = "ApprenticeRod",
		Id = 10,
		QualityId = 1,
		BaseDmg = 8,
		Cost = 300000,
		CurrencyType = "Gold",
		LevelRequirement = 3,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 2,
			LineControl = 1,
			Stability = 2,
		},
		Description = "A basic wooden rod with a bit more pull for novice anglers.",
	},

	RiverReedRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "River Reed Rod",
		Color = getRodColorFromName("River Reed Rod"),
		Key = "RiverReedRod",
		Id = 15,
		QualityId = 1,
		BaseDmg = 7,
		Cost = 450000,
		CurrencyType = "Gold",
		LevelRequirement = 4,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 1,
			LineControl = 3,
			Stability = 1,
		},
		Description = "Favoured by calm fishers. Easier timing, low strength.",
	},

	WornGuildRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Worn Guild Rod",
		Color = getRodColorFromName("Worn Guild Rod"),
		Key = "WornGuildRod",
		Id = 18,
		QualityId = 1,
		BaseDmg = 9,
		Cost = 550000,
		CurrencyType = "Gold",
		LevelRequirement = 5,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 2,
			LineControl = 2,
			Stability = 1,
		},
		Description = "An old guild rod. Balanced but unimpressive.",
	},

	-- QUALITY 2 (Early Progression)
	SteelLineRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Steel Line Rod",
		Color = getRodColorFromName("Steel Line Rod"),
		Key = "SteelLineRod",
		Id = 19,
		QualityId = 2,
		BaseDmg = 12,
		Cost = 800000,
		CurrencyType = "Gold",
		LevelRequirement = 6,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 2,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Steel line offers better control for modestly stronger fish.",
	},

	SteadyFisher = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Steady Fisher",
		Color = getRodColorFromName("Steady Fisher"),
		Key = "SteadyFisher",
		Id = 21,
		QualityId = 2,
		BaseDmg = 10,
		Cost = 950000,
		CurrencyType = "Gold",
		LevelRequirement = 7,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 1,
			LineControl = 2,
			Stability = 4,
		},
		Description = "Built for patience. The fish fights back slowly between hits.",
	},

	IronHookRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Iron Hook Rod",
		Color = getRodColorFromName("Iron Hook Rod"),
		Key = "IronHookRod",
		Id = 25,
		QualityId = 2,
		BaseDmg = 13,
		Cost = 1200000,
		CurrencyType = "Gold",
		LevelRequirement = 8,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 3,
			LineControl = 2,
			Stability = 2,
		},
		Description = "Extra bite at the hook. Stronger pulls but less forgiving.",
	},

	PondWhisper = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Pond Whisper",
		Color = getRodColorFromName("Pond Whisper"),
		Key = "PondWhisper",
		Id = 30,
		QualityId = 2,
		BaseDmg = 11,
		Cost = 1350000,
		CurrencyType = "Gold",
		LevelRequirement = 9,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 2,
			LineControl = 3,
			Stability = 3,
		},
		Description = "A gentle rod that feels the water’s flow, easing timing a bit.",
	},

	-- QUALITY 3 (Mid-game, Specialized)
	PowerReeler = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Power Reeler",
		Color = getRodColorFromName("Power Reeler"),
		Key = "PowerReeler",
		Id = 37,
		QualityId = 3,
		BaseDmg = 18,
		Cost = 2000000,
		CurrencyType = "Gold",
		LevelRequirement = 12,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 5,
			LineControl = 2,
			Stability = 1,
		},
		Description = "Built for raw power. Great hits, but fights are wild and draining.",
	},

	PrecisionCaster = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Precision Caster",
		Color = getRodColorFromName("Precision Caster"),
		Key = "PrecisionCaster",
		Id = 39,
		QualityId = 3,
		BaseDmg = 16,
		Cost = 2300000,
		CurrencyType = "Gold",
		LevelRequirement = 14,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 2,
			LineControl = 5,
			Stability = 3,
		},
		Description = "Engineered for accuracy. Big hit window for careful players.",
	},

	JourneymansBalance = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Journeyman's Balance",
		Color = getRodColorFromName("Journeyman's Balance"),
		Key = "JourneymansBalance",
		Id = 41,
		QualityId = 3,
		BaseDmg = 17,
		Cost = 2500000,
		CurrencyType = "Gold",
		LevelRequirement = 15,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 3,
			LineControl = 3,
			Stability = 3,
		},
		Description = "A balanced rod for fishers exploring deeper waters.",
	},

	TideBreaker = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Tide Breaker",
		Color = getRodColorFromName("Tide Breaker"),
		Key = "TideBreaker",
		Id = 44,
		QualityId = 3,
		BaseDmg = 19,
		Cost = 2800000,
		CurrencyType = "Gold",
		LevelRequirement = 17,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 4,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Stronger pulls for mid-tier fish, at the cost of some control.",
	},

	-- QUALITY 4 (Advanced)
	BalancedMaster = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Balanced Master",
		Color = getRodColorFromName("Balanced Master"),
		Key = "BalancedMaster",
		Id = 58,
		QualityId = 4,
		BaseDmg = 22,
		Cost = 4000000,
		CurrencyType = "Gold",
		LevelRequirement = 20,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 4,
			LineControl = 4,
			Stability = 4,
		},
		Description = "The classic choice of seasoned anglers. Strong and dependable.",
	},

	TitansGrip = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Titan's Grip",
		Color = getRodColorFromName("Titan's Grip"),
		Key = "TitansGrip",
		Id = 59,
		QualityId = 4,
		BaseDmg = 25,
		Cost = 5000000,
		CurrencyType = "Gold",
		LevelRequirement = 24,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 6,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Brutal strength. Devastates fish stamina if you can handle it.",
	},

	MoonlitThreadRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Moonlit Thread Rod",
		Color = getRodColorFromName("Moonlit Thread Rod"),
		Key = "MoonlitThreadRod",
		Id = 63,
		QualityId = 4,
		BaseDmg = 23,
		Cost = 5200000,
		CurrencyType = "Gold",
		LevelRequirement = 26,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 3,
			LineControl = 5,
			Stability = 4,
		},
		Description = "Shines under pressure. Great for tricky timing challenges.",
	},

	AnchorheartRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Anchorheart Rod",
		Color = getRodColorFromName("Anchorheart Rod"),
		Key = "AnchorheartRod",
		Id = 65,
		QualityId = 4,
		BaseDmg = 21,
		Cost = 4500000,
		CurrencyType = "Gold",
		LevelRequirement = 22,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 3,
			LineControl = 3,
			Stability = 6,
		},
		Description = "Unshakable stability. Fish struggle to drain your progress.",
	},

	-- QUALITY 5 (Near-Legendary)
	WhisperingCurrent = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Whispering Current",
		Color = getRodColorFromName("Whispering Current"),
		Key = "WhisperingCurrent",
		Id = 66,
		QualityId = 5,
		BaseDmg = 28,
		Cost = 8000000,
		CurrencyType = "Gold",
		LevelRequirement = 32,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 3,
			LineControl = 6,
			Stability = 5,
		},
		Description = "Flows with the water’s rhythm. Huge hit window and high stability.",
	},

	StormcallerRod = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Stormcaller Rod",
		Color = getRodColorFromName("Stormcaller Rod"),
		Key = "StormcallerRod",
		Id = 68,
		QualityId = 5,
		BaseDmg = 30,
		Cost = 9000000,
		CurrencyType = "Gold",
		LevelRequirement = 35,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 6,
			LineControl = 4,
			Stability = 4,
		},
		Description = "Harnesses violent surges. Tremendous power with decent control.",
	},

	DeepseaWarden = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Deepsea Warden",
		Color = getRodColorFromName("Deepsea Warden"),
		Key = "DeepseaWarden",
		Id = 70,
		QualityId = 5,
		BaseDmg = 29,
		Cost = 95000000,
		CurrencyType = "Gold",
		LevelRequirement = 38,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 4,
			LineControl = 4,
			Stability = 6,
		},
		Description = "Forged for abyssal beasts. High stability keeps fights controlled.",
	},

	-- QUALITY 6 (End-Game)
	AnglersPerfection = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Angler's Perfection",
		Color = getRodColorFromName("Angler's Perfection"),
		Key = "AnglersPerfection",
		Id = 71,
		QualityId = 6,
		BaseDmg = 35,
		Cost = 150000000,
		CurrencyType = "Gold",
		LevelRequirement = 45,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 6,
			LineControl = 5,
			Stability = 6,
		},
		Description = "A near-perfect rod. Even monsters of the deep feel manageable.",
	},

	CelestialTideScepter = {
		Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRod,
		Name = "Celestial Tide Scepter",
		Color = getRodColorFromName("Celestial Tide Scepter"),
		Key = "CelestialTideScepter",
		Id = 76,
		QualityId = 6,
		BaseDmg = 36,
		Cost = 170000000,
		CurrencyType = "Gold",
		LevelRequirement = 50,
		ItemImage = "rbxassetid://107401856051981",
		Stats = {
			ReelPower = 5,
			LineControl = 6,
			Stability = 6,
		},
		Description = "Mastery of flow and stillness. Ultimate control and endurance.",
	},
}

table.freeze(FishingRods)

return FishingRods
