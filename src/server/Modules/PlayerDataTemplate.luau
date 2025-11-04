local ServerScriptService = game:GetService("ServerScriptService")

local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local realmBuffs = {
	-- FISH
	Fish_Percent = { Name = "Fish_Percent", Label = "Fish Value", BaseValue = 0.05, Type = "Production", Scope = "Helper", IsPlus = true },
	Fish_Multi = { Name = "Fish_Multi", Label = "Fish Value", BaseValue = 1.15, Type = "Multiplier", Scope = "Helper", IsPlus = true },

	-- STORAGE
	BoatStorage_Percent = { Name = "BoatStorage_Percent", Label = "Boat Storage", BaseValue = 0.08, Type = "QoL", Scope = "Boat", IsPlus = true },
	TenderStorage_Percent = { Name = "TenderStorage_Percent", Label = "Tender Storage", BaseValue = 0.08, Type = "QoL", Scope = "Tender", IsPlus = true },
	PortStorage_Percent = { Name = "PortStorage_Percent", Label = "Port Storage", BaseValue = 0.08, Type = "QoL", Scope = "PortStorage", IsPlus = true },
	HelperStorage_Percent = { Name = "HelperStorage_Percent", Label = "Helper Storage", BaseValue = 0.08, Type = "QoL", Scope = "Helper", IsPlus = true },
	CaravanStorage_Percent = { Name = "CaravanStorage_Percent", Label = "Caravan Storage", BaseValue = 0.08, Type = "QoL", Scope = "Caravan", IsPlus = true },

	-- TRAVEL TIME
	HelperTravelTime_Percent = { Name = "HelperTravelTime_Percent", Label = "Helper Traveltime", BaseValue = 0.05, Type = "TimeReduction", Scope = "Helper", IsPlus = false },
	CaravanTravelTime_Percent = { Name = "CaravanTravelTime_Percent", Label = "Caravan Traveltime", BaseValue = 0.05, Type = "TimeReduction", Scope = "Caravan", IsPlus = false },
	TenderTravelTime_Percent = { Name = "TenderTravelTime_Percent", Label = "Tender Traveltime", BaseValue = 0.05, Type = "TimeReduction", Scope = "Tender", IsPlus = false },

	-- LOAD TIME
	TenderLoadTime_Percent = { Name = "TenderLoadTime_Percent", Label = "Tender Loadtime", BaseValue = 0.08, Type = "TimeReduction", Scope = "Tender", IsPlus = false },
	HelperLoadTime_Percent = { Name = "HelperLoadTime_Percent", Label = "Helper Loadtime", BaseValue = 0.08, Type = "TimeReduction", Scope = "Helper", IsPlus = false },

	-- FPS
	FPS_Percent = { Name = "FPS_Percent", Label = "Fish Per Second", BaseValue = 0.05, Type = "Production", Scope = "Boat", IsPlus = true },

	-- GOLD
	PassiveGold_Percent = { Name = "PassiveGold_Percent", Label = "Passive Gold", BaseValue = 0.03, Type = "Production", Scope = "Realm", IsPlus = true },
	Gold_Multi = { Name = "Gold_Multi", Label = "Gold", BaseValue = 1.15, Type = "Multiplier", Scope = "Realm", IsPlus = true },

	-- COSTS
	UpgradeCost_Percent = { Name = "UpgradeCost_Percent", Label = "Upgrade Costs", BaseValue = 0.04, Type = "Loop", Scope = "Realm", IsPlus = true },
}

return {
	CurrentRealm = 1,
	GlobalBuffs = {},
	Realms = {
		[1] = {
			Lanes = 6,
			isUnlocked = true,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
			Helpers = {},
			Shops = {},
			Jobs = Jobs.Data,
		},
		[2] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
			Helpers = {},
			Shops = {},
			Jobs = Jobs.Data,
		},
		[3] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
			Helpers = {},
			Shops = {},
			Jobs = Jobs.Data,
		},
		[4] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
			Helpers = {},
			Shops = {},
			Jobs = Jobs.Data,
		},
	},
	Currencies = {
		Gold = 1500,
	},
	CompletedTutorial = false,
	TutorialStageComplete = {
		[1] = false, -- Boats
		[2] = false, -- Tenders
		[3] = false, -- Storage
		[4] = false, -- Helpers
	},
}
