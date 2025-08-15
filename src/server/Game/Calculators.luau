local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Formulas = require(script.Parent.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local CALCULATOR = {}

CALCULATOR.MaxStorage = function(type: string, level: number, tier: number)
	if not type or not level or not tier then
		FFGHelpers("No type or entityState passed to MaxStorage fn")
		return
	end

	local baseStorage = 0

	if type == FFGEnum.ENTITIES.Boat then
		baseStorage = Formulas.BOAT.BaseStorage :: number
	else
		baseStorage = Formulas.TENDER.BaseStorage :: number
	end

	if baseStorage <= 0 then
		FFGHelpers.PrintLog("Base Store is either 0 or below, returning")
		return
	end

	FFGHelpers.PrintLog("Base Storage: ", baseStorage)

	local boatTier = tier
	if boatTier == nil then
		FFGHelpers.PrintLog("Warning: Tier attribute is nil, defaulting to 1")
		boatTier = 1
	end

	local growthRate = 0
	if type == FFGEnum.ENTITIES.Boat then
		growthRate = Formulas.BOAT.GrowthRate + tier * 0.02 :: number
	else
		growthRate = Formulas.TENDER.GrowthRate + tier * 0.02 :: number
	end

	FFGHelpers.PrintLog("Growth Rate: ", growthRate)

	local tierMultiplier = Formulas.TIER_MULTIPLIER[tier] :: number
	FFGHelpers.PrintLog("Tier Multiplier: ", tierMultiplier)

	local maxStorage = baseStorage * math.pow(growthRate, level) * tierMultiplier :: number

	local nextLvlMaxStorage = baseStorage * math.pow(growthRate, level + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

return CALCULATOR
