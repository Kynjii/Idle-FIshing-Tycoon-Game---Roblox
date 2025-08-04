local FFGEnum = {}

FFGEnum.QUALITY_PROMOTION_LEVELS = {
	["Quality1"] = 9,
	["Quality2"] = 24,
	["Quality3"] = 49,
	["Quality4"] = 99,
	["Quality5"] = 149,
	["Quality6"] = 199,
	["Quality7"] = 249,
	["Quality8"] = 349,
	["Quality9"] = 449,
	["Quality10"] = 549,
	["Quality11"] = 700,
}

FFGEnum.BOAT = {
	NAME = {
		["Quality1"] = "Driftwood Skiff",
		["Quality2"] = "Netting Dory",
		["Quality3"] = "Herring Lugger",
		["Quality4"] = "Tidecaller Canoe",
		["Quality5"] = "Seablessed Punt",
		["Quality6"] = "Knight's Hull",
		["Quality7"] = "Crimson Cutter",
		["Quality8"] = "Ironhook Galley",
		["Quality9"] = "Mariner’s Galleon",
		["Quality10"] = "Wyrmcatcher",
		["Quality11"] = "The Flynnrunner",
	},
}

FFGEnum.TENDER = {
	NAME = {
		["Quality1"] = "Wooden Cart-Barge",
		["Quality2"] = "Barrel Barge",
		["Quality3"] = "Oarsman’s Ferry",
		["Quality4"] = "Courier Skiff",
		["Quality5"] = "Windcloak Sloop",
		["Quality6"] = "Seawarden’s Tender",
		["Quality7"] = "Crate Hauler",
		["Quality8"] = "Knight’s Courier",
		["Quality9"] = "Harbormaster’s Crest",
		["Quality10"] = "Starlit Barge",
		["Quality11"] = "Little Lucy",
	},
}

FFGEnum.QUALITY = {
	COMMON = {
		label = "Common",
		color = Color3.fromHex("#BFBFBF"),
	},
	UNCOMMON = {
		label = "Uncommon",
		color = Color3.fromHex("#3EFF3E"),
	},
	RARE = {
		label = "Rare",
		color = Color3.fromHex("#0070DD"),
	},
	EPIC = {
		label = "Epic",
		color = Color3.fromHex("#A335EE"),
	},
	LEGENDARY = {
		label = "Legendary",
		color = Color3.fromHex("#FF9A00"),
	},
	EXOTIC = {
		label = "Exotic",
		color = Color3.fromHex("#E6C266"),
	},
	ASCENDED = {
		label = "Ascended",
		color = Color3.fromHex("#FF66CC"),
	},
	MYTHIC = {
		label = "Mythic",
		color = Color3.fromHex("#00FFFF"),
	},
	DIVINE = {
		label = "Divine",
		color = Color3.fromHex("#FFD700"),
	},
	ETERNAL = {
		label = "Eternal",
		color = Color3.fromHex("#C0C0FF"),
	},
	TRANSCENDENT = {
		label = "Transcendent",
		color = Color3.fromHex("#F5E663"),
	},
}

return FFGEnum
