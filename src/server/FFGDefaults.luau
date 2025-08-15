local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local httpService = game:GetService("HttpService")

local Formulas = require(ServerScriptService.Server.Game.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local FFGDefaults = {}

FFGDefaults.DebounceCD = 3

FFGDefaults.BOAT_STARTING_ATT = {
	[FFGEnum.ATTRIBUTES.BOAT.Id] = httpService:GenerateGUID(false),
	[FFGEnum.ATTRIBUTES.BOAT.Owner] = "",
	[FFGEnum.ATTRIBUTES.BOAT.Tier] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.Name] = "",
	[FFGEnum.ATTRIBUTES.BOAT.isActive] = false,
	[FFGEnum.ATTRIBUTES.BOAT.isPurchased] = false,
	[FFGEnum.ATTRIBUTES.BOAT.Level] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.UpgradeStage] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.CurrentMaxStorage] = Formulas.BOAT.BaseStorage,
	[FFGEnum.ATTRIBUTES.BOAT.NextLvlMaxStorage] = Formulas.BOAT.BaseStorage,
}

return FFGDefaults
