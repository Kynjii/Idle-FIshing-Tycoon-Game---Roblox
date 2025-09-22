local realmBuffs = {
	-- FISH
	Fish_Percent = { Unlocked = false, Name = "Fish_Percent", Label = "Fish Value", BaseValue = 0.04, Type = "Production", Scope = "Helper", IsPlus = true },
	Fish_Multi = { Unlocked = false, Name = "Fish_Multi", Label = "Fish Value", BaseValue = 1.15, Type = "Multiplier", Scope = "Helper", IsPlus = true },

	-- STORAGE
	BoatStorage_Percent = { Unlocked = false, Name = "BoatStorage_Percent", Label = "Boat Storage", BaseValue = 0.08, Type = "QoL", Scope = "Boat", IsPlus = true },
	TenderStorage_Percent = { Unlocked = false, Name = "TenderStorage_Percent", Label = "Tender Storage", BaseValue = 0.08, Type = "QoL", Scope = "Tender", IsPlus = true },
	PortStorage_Percent = { Unlocked = false, Name = "PortStorage_Percent", Label = "Port Storage", BaseValue = 0.08, Type = "QoL", Scope = "PortStorage", IsPlus = true },
	HelperStorage_Percent = { Unlocked = false, Name = "HelperStorage_Percent", Label = "Helper Storage", BaseValue = 0.08, Type = "QoL", Scope = "Helper", IsPlus = true },
	CaravanStorage_Percent = { Unlocked = false, Name = "CaravanStorage_Percent", Label = "Caravan Storage", BaseValue = 0.08, Type = "QoL", Scope = "Caravan", IsPlus = true },

	-- TRAVEL TIME
	HelperTravelTime_Percent = { Unlocked = false, Name = "HelperTravelTime_Percent", Label = "Helper Travel Times", BaseValue = 0.03, Type = "Loop", Scope = "Helper", IsPlus = false },
	CaravanTravelTime_Percent = { Unlocked = false, Name = "CaravanTravelTime_Percent", Label = "Caravan Travel Times", BaseValue = 0.03, Type = "Loop", Scope = "Caravan", IsPlus = false },
	TenderTravelTime_Percent = { Unlocked = false, Name = "TenderTravelTime_Percent", Label = "Tender Travel Times", BaseValue = 0.03, Type = "Loop", Scope = "Tender", IsPlus = false },

	-- LOAD TIME
	TenderLoadTime_Percent = { Unlocked = false, Name = "TenderLoadTime_Percent", Label = "Tender Load Times", BaseValue = 0.03, Type = "Loop", Scope = "Tender", IsPlus = false },
	HelperLoadTime_Percent = { Unlocked = false, Name = "HelperLoadTime_Percent", Label = "Helper Load Times", BaseValue = 0.03, Type = "Loop", Scope = "Helper", IsPlus = false },

	-- FPS
	FPS_Percent = { Unlocked = false, Name = "FPS_Percent", Label = "Fish Per Second", BaseValue = 0.05, Type = "Production", Scope = "Boat", IsPlus = true },

	-- GOLD
	PassiveGold_Percent = { Unlocked = false, Name = "PassiveGold_Percent", Label = "Passive Gold", BaseValue = 0.03, Type = "Production", Scope = "Realm", IsPlus = true },
	Gold_Multi = { Unlocked = false, Name = "Gold_Multi", Label = "Gold", BaseValue = 1.15, Type = "Multiplier", Scope = "Global", IsPlus = true },

	-- COSTS
	UpgradeCost_Percent = { Unlocked = false, Name = "UpgradeCost_Percent", Label = "Upgrade Costs", BaseValue = 0.04, Type = "Loop", Scope = "Global", IsPlus = true },
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
		Gold = 1100,
	},
}
