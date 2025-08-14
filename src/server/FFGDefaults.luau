local ReplicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local FFGDefaults = {}

FFGDefaults.DebounceCD = 3

FFGDefaults.BOAT_STARTING_ATT = {
	[FFGEnum.ATTRIBUTES.GENERAL.Id] = httpService:GenerateGUID(false),
	[FFGEnum.ATTRIBUTES.BOAT.Owner] = "",
	[FFGEnum.ATTRIBUTES.BOAT.Tier] = 1,
	[FFGEnum.ATTRIBUTES.GENERAL.Name] = "",
	[FFGEnum.ATTRIBUTES.BOAT.isActive] = false,
	[FFGEnum.ATTRIBUTES.BOAT.isPurchased] = false,
	[FFGEnum.ATTRIBUTES.BOAT.Level] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.UpgradeStage] = 1,
}

return FFGDefaults
