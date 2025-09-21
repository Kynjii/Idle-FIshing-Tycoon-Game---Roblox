local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Buffs = {}

export type BuffState = {
	Name: string,
	BaseValue: number,
	CurrentValue: number,
	Type: string,
}

local GROWTH_RATES = {
	Multiplier = { 1.08, 1.07, 1.06, 1.05, 1.04, 1.03, 1.03, 1.02, 1.02, 1.02, 1.02 },
	Production = { 2.2, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.08, 1.02 },
	QoL = { 1.5, 1.6, 1.7, 1.8, 1.9, 2, 2.1, 2.2, 2.3, 2.4, 2.5 },
	Loop = { 1.14, 1.12, 1.10, 1.08, 1.07, 1.06, 1.05, 1.04, 1.03, 1.03, 1.02 },
}

Buffs.Formulas = {
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

function Buffs.GeneratePlayerDataTemplate()
	return Buffs.Formulas
end

function Buffs.CalculateBuffValue(stage: number, buffState: BuffState): number
	local growthRate = GROWTH_RATES[buffState.Type][stage]
	local value = buffState.BaseValue * growthRate
	return FormatNumber(value)
end

function Buffs.GetBuffs(player: Player, buffNames: { string })
	return DataService.GetBuffState(player, buffNames)
end

return Buffs
