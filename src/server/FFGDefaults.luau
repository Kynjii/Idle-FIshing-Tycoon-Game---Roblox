local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local FFGDefaults = {}

FFGDefaults.DebounceCD = 3

FFGDefaults.BOAT_STARTING_ATT = {
	[FFGEnum.ATTRIBUTES.BOAT.Tier] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.Name] = "Default Name",
	[FFGEnum.ATTRIBUTES.BOAT.isActive] = false,
	[FFGEnum.ATTRIBUTES.BOAT.isPurchased] = false,
	[FFGEnum.ATTRIBUTES.BOAT.Level] = 1,
	[FFGEnum.ATTRIBUTES.BOAT.UpgradeStage] = 1,
}

return FFGDefaults
