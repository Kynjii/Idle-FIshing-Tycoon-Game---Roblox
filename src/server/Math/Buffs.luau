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
	Multiplier = { 1.08, 1.07, 1.06, 1.05, 1.04, 1.03, 1.03, 1.02, 1.02, 1.02 },
	Production = { 2.2, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.08 },
	QoL = { 1.18, 1.15, 1.12, 1.10, 1.08, 1.07, 1.06, 1.05, 1.04, 1.03 },
	Loop = { 1.14, 1.12, 1.10, 1.08, 1.07, 1.06, 1.05, 1.04, 1.03, 1.03 },
}

Buffs.Formulas = {
	-- FISH
	Fish_Percent = { Name = "Fish_Percent", BaseValue = 0.04, Type = "Production" },
	Fish_Multi = { Name = "Fish_Multi", BaseValue = 1.15, Type = "Multiplier" },

	-- STORAGE
	BoatStorage_Percent = { Name = "BoatStorage_Percent", BaseValue = 0.08, Type = "QoL" },
	TenderStorage_Percent = { Name = "TenderStorage_Percent", BaseValue = 0.08, Type = "QoL" },
	PortStorage_Percent = { Name = "PortStorage_Percent", BaseValue = 0.08, Type = "QoL" },
	HelperStorage_Percent = { Name = "HelperStorage_Percent", BaseValue = 0.08, Type = "QoL" },
	CaravanStorage_Percent = { Name = "CaravanStorage_Percent", BaseValue = 0.08, Type = "QoL" },

	-- TRAVEL TIME
	HelperTravelTime_Percent = { Name = "HelperTravelTime_Percent", BaseValue = 0.03, Type = "Loop" },
	CaravanTravelTime_Percent = { Name = "CaravanTravelTime_Percent", BaseValue = 0.03, Type = "Loop" },
	TenderTravelTime_Percent = { Name = "TenderTravelTime_Percent", BaseValue = 0.03, Type = "Loop" },

	-- LOAD TIME
	TenderLoadTime_Percent = { Name = "TenderLoadTime_Percent", BaseValue = 0.03, Type = "Loop" },
	HelperLoadTime_Percent = { Name = "HelperLoadTime_Percent", BaseValue = 0.03, Type = "Loop" },

	-- FPS
	FPS_Percent = { Name = "FPS_Percent", BaseValue = 0.05, Type = "Production" },

	-- GOLD
	PassiveGold_Percent = { Name = "PassiveGold_Percent", BaseValue = 0.03, Type = "Production" },
	Gold_Multi = { Name = "Gold_Multi", BaseValue = 1.15, Type = "Multiplier" },

	-- COSTS
	UpgradeCost_Percent = { Name = "UpgradeCost_Percent", BaseValue = 0.04, Type = "Loop" },
}

function Buffs.CalculateBuffValue(stage: number, buffState: BuffState): number
	local growthRate = GROWTH_RATES[buffState.Type][stage]

	return FormatNumber(buffState.BaseValue * growthRate)
end

function Buffs.GetBuffs(player: Player, buffNames: { string })
	return DataService.GetBuffState(player, buffNames)
end

return Buffs
