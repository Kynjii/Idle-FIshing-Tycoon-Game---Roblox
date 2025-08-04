local FFGEnum = {}

FFGEnum.TIER_MAX_LEVEL = {
	["Tier1"] = 9,
	["Tier2"] = 24,
	["Tier3"] = 49,
	["Tier4"] = 99,
	["Tier5"] = 149,
	["Tier6"] = 199,
	["Tier7"] = 249,
	["Tier8"] = 349,
	["Tier9"] = 449,
	["Tier10"] = 549,
	["Tier11"] = 700,
}

FFGEnum.BOAT = {
	NAME = {
		["Tier1"] = "Driftwood Skiff",
		["Tier2"] = "Netting Dory",
		["Tier3"] = "Herring Lugger",
		["Tier4"] = "Tidecaller Canoe",
		["Tier5"] = "Seablessed Punt",
		["Tier6"] = "Knight's Hull",
		["Tier7"] = "Crimson Cutter",
		["Tier8"] = "Ironhook Galley",
		["Tier9"] = "Mariner’s Galleon",
		["Tier10"] = "Wyrmcatcher",
		["Tier11"] = "The Flynnrunner",
	},
}

FFGEnum.TENDER = {
	NAME = {
		["Tier1"] = "Wooden Cart-Barge",
		["Tier2"] = "Barrel Barge",
		["Tier3"] = "Oarsman’s Ferry",
		["Tier4"] = "Courier Skiff",
		["Tier5"] = "Windcloak Sloop",
		["Tier6"] = "Seawarden’s Tender",
		["Tier7"] = "Crate Hauler",
		["Tier8"] = "Knight’s Courier",
		["Tier9"] = "Harbormaster’s Crest",
		["Tier10"] = "Starlit Barge",
		["Tier11"] = "Little Lucy",
	},
}

FFGEnum.RARITY = {
	COMMON = {
		label = "Common",
		color = "#BFBFBF",
	},
	UNCOMMON = {
		label = "Uncommon",
		color = "#3EFF3E",
	},
	RARE = {
		label = "Rare",
		color = "#0070DD",
	},
	EPIC = {
		label = "Epic",
		color = "#A335EE",
	},
	LEGENDARY = {
		label = "Legendary",
		color = "#FF9A00",
	},
	EXOTIC = {
		label = "Exotic",
		color = "#E6C266",
	},
	ASCENDED = {
		label = "Ascended",
		color = "#FF66CC",
	},
	MYTHIC = {
		label = "Mythic",
		color = "#00FFFF",
	},
	DIVINE = {
		label = "Divine",
		color = "#FFD700",
	},
	ETERNAL = {
		label = "Eternal",
		color = "#C0C0FF",
	},
	TRANSCENDENT = {
		label = "Transcendent",
		color = "#F5E663",
	},
}

return FFGEnum
