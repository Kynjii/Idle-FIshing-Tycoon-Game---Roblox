local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local BoatData = {}

BoatData.Default_Attributes = {
	["Level"] = 1,
	["UpgradeStage"] = 1,
	["Name"] = FFGEnum.BOAT.NAME[1],
	["isUnlocked"] = false,
	["isActive"] = false,
}

return BoatData
