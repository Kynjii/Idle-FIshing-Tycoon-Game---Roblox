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
	Multiplier = { 1.15, 1.12, 1.10, 1.08, 1.07, 1.06, 1.05, 1.04, 1.03, 1.02, 1.01 },
	Production = { 3.0, 2.5, 2.0, 1.8, 1.6, 1.4, 1.3, 1.2, 1.15, 1.10, 1.05 },
	QoL = { 2.0, 2.2, 2.4, 2.6, 2.8, 3.0, 3.2, 3.4, 3.6, 3.8, 4.0 },
	Loop = { 1.20, 1.18, 1.15, 1.12, 1.10, 1.08, 1.06, 1.05, 1.04, 1.03, 1.02 },
}

local LEVEL_GROWTH_RATES = {
	Multiplier = 1.08,
	Production = 1.12,
	QoL = 1.06,
	Loop = 1.10,
}

function Buffs.CalculateStageBuffValue(stage: number, buffState: BuffState): number
	local growthRate = GROWTH_RATES[buffState.Type][stage]
	return buffState.BaseValue * growthRate
end

function Buffs.CalculateLevelBuffValue(stage: number, level: number, buffState: BuffState): number
	local stageGrowthRate = GROWTH_RATES[buffState.Type][stage] or 1
	local levelGrowthRate = LEVEL_GROWTH_RATES[buffState.Type] or 1.1

	local stageValue = buffState.BaseValue * stageGrowthRate
	local levelMultiplier = math.pow(levelGrowthRate, level - 1)

	return stageValue * levelMultiplier
end

function Buffs.GetBuffs(player: Player, buffNames: { string })
	return DataService.GetBuffState(player, buffNames)
end

return Buffs
