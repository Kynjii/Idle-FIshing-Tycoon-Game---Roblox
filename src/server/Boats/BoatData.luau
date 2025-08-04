local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local BoatData = {}

BoatData.Default_Attributes = {
	["Level"] = 1,
	["UpgradeLevel"] = 1,
	["Name"] = FFGEnum.BOAT.NAME.Quality1,
	["isUnlocked"] = false,
}

return BoatData
