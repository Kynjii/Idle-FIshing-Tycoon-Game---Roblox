local FFGEnum = {}

FFGEnum.FONT = Enum.Font.FredokaOne

FFGEnum.QUALITY_PROMOTION_LEVELS = {
	[1] = 9,
	[2] = 24,
	[3] = 49,
	[4] = 99,
	[5] = 149,
	[6] = 199,
	[7] = 249,
	[8] = 349,
	[9] = 449,
	[10] = 549,
	[11] = 700,
}

FFGEnum.TENDER = {
	NAME = {
		[1] = "Wooden Cart-Barge",
		[2] = "Barrel Barge",
		[3] = "Oarsman’s Ferry",
		[4] = "Courier Skiff",
		[5] = "Windcloak Sloop",
		[6] = "Seawarden’s Tender",
		[7] = "Crate Hauler",
		[8] = "Knight’s Courier",
		[9] = "Harbormaster’s Crest",
		[10] = "Starlit Barge",
		[11] = "Little Lucy",
	},
}

FFGEnum.QUALITY = {
	[1] = {
		Label = "Common",
		Color = Color3.fromHex("#BFBFBF"),
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
	GENERAL = {
		["Name"] = "Name",
		["isUnlocked"] = "isUnlocked",
		["Id"] = "Id",
	},
	BOAT = {
		["Owner"] = "Owner",
		["Tier"] = "Tier",
		["Level"] = "Level",
		["UpgradeStage"] = "UpgradeStage",
		["Name"] = "Name",
		["isActive"] = "isActive",
		["isPurchased"] = "isPurchased",
		["Id"] = "Id",
		["CurrentMaxStorage"] = "CurrentMaxStorage",
		["NextLvlMaxStorage"] = "NextLvlMaxStorage",
		["RealmId"] = "RealmId",
		["MaxLevel"] = "MaxLevel",
		["BaseCost"] = "BaseCost",
		["UpgradeCost"] = "UpgradeCost",
		["FPS"] = "FPS",
		["FishInStorage"] = "FishInStorage",
		["StorageFull"] = "StorageFull",
		["BoatModel"] = "BoatModel",
		["GrowthRate"] = "GrowthRate",
		["CostGrowthRate"] = "CostGrowthRate",
		["BaseFPS"] = "BaseFPS",
		["BaseStorage"] = "BaseStorage",
	},
}

FFGEnum.CURRENCY_TYPES = {
	["Gold"] = "Gold",
}

FFGEnum.ENTITIES = {
	["Boat"] = "Boat",
	["Tender"] = "Tender",
}

return FFGEnum
