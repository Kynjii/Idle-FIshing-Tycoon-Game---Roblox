local realmBuffs = {
	-- FISH
	Fish_Percent = { Name = "Fish_Percent", BaseValue = 0.04, Type = "Production", Scope = "Helper" },
	Fish_Multi = { Name = "Fish_Multi", BaseValue = 1.15, Type = "Multiplier", Scope = "Helper" },

	-- STORAGE
	BoatStorage_Percent = { Name = "BoatStorage_Percent", BaseValue = 0.08, Type = "QoL", Scope = "Boat" },
	TenderStorage_Percent = { Name = "TenderStorage_Percent", BaseValue = 0.08, Type = "QoL", Scope = "Tender" },
	PortStorage_Percent = { Name = "PortStorage_Percent", BaseValue = 0.08, Type = "QoL", Scope = "PortStorage" },
	HelperStorage_Percent = { Name = "HelperStorage_Percent", BaseValue = 0.08, Type = "QoL", Scope = "Helper" },
	CaravanStorage_Percent = { Name = "CaravanStorage_Percent", BaseValue = 0.08, Type = "QoL", Scope = "Caravan" },

	-- TRAVEL TIME
	HelperTravelTime_Percent = { Name = "HelperTravelTime_Percent", BaseValue = 0.03, Type = "Loop", Scope = "Helper" },
	CaravanTravelTime_Percent = { Name = "CaravanTravelTime_Percent", BaseValue = 0.03, Type = "Loop", Scope = "Caravan" },
	TenderTravelTime_Percent = { Name = "TenderTravelTime_Percent", BaseValue = 0.03, Type = "Loop", Scope = "Tender" },

	-- LOAD TIME
	TenderLoadTime_Percent = { Name = "TenderLoadTime_Percent", BaseValue = 0.03, Type = "Loop", Scope = "Tender" },
	HelperLoadTime_Percent = { Name = "HelperLoadTime_Percent", BaseValue = 0.03, Type = "Loop", Scope = "Helper" },

	-- FPS
	FPS_Percent = { Name = "FPS_Percent", BaseValue = 0.05, Type = "Production", Scope = "Boat" },

	-- GOLD
	PassiveGold_Percent = { Name = "PassiveGold_Percent", BaseValue = 0.03, Type = "Production", Scope = "Realm" },
	Gold_Multi = { Name = "Gold_Multi", BaseValue = 1.15, Type = "Multiplier", Scope = "Global" },

	-- COSTS
	UpgradeCost_Percent = { Name = "UpgradeCost_Percent", BaseValue = 0.04, Type = "Loop", Scope = "Global" },
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
		},
		[2] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
		},
		[3] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
		},
		[4] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
			Storages = {},
			Buildings = {},
			Buffs = realmBuffs,
		},
	},
	Currencies = {
		Gold = 1000,
	},
}
