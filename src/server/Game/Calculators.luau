local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
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
		FFGHelpers.PrintLog("Base Storage is either 0 or below, returning")
		return
	end

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

	local tierMultiplier = Formulas.TIER_MULTIPLIER[tier] :: number
	local maxStorage = baseStorage * math.pow(growthRate, level) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate, level + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

CALCULATOR.GetBaseCost = function(type: string, level: number, tier: number, RealmId: number): number
	if not type or not level or not tier then
		FFGHelpers("No type or entityState passed to GetBaseCost fn")
		return
	end

	local baseCost = 0

	if type == FFGEnum.ENTITIES.Boat then
		baseCost = Formulas.BOAT.BaseCost :: number
	else
		baseCost = Formulas.TENDER.BaseCost :: number
	end

	if baseCost <= 0 then
		FFGHelpers.PrintLog("Base Cost is either 0 or below, returning")
		return
	end

	FFGHelpers.PrintLog("Base Cost: ", baseCost)

	local boatTier = tier
	if boatTier == nil then
		FFGHelpers.PrintLog("Warning: Tier attribute is nil, defaulting to 1")
		boatTier = 1
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[boatTier] :: number
	FFGHelpers.PrintLog("Tier Multiplier: ", tierMultiplier)
	local realmMultiplier = math.pow(RealmId, 2.25) -- scaling curve

	local cost = baseCost * tierMultiplier * realmMultiplier

	return cost
end

CALCULATOR.UpgradeCost = function(type: string, level: number, tier: number, RealmId: number, baseCost: number): number
	if not type or not level or not tier then
		FFGHelpers("No type or entityState passed to UpgradeCost fn")
		return
	end

	local baseCostCalc = baseCost or CALCULATOR.GetBaseCost(type, level, tier, RealmId) :: number

	if baseCostCalc <= 0 then
		FFGHelpers.PrintLog("Base cost is either 0 or below, returning")
		return
	end

	FFGHelpers.PrintLog("Base Storage: ", baseCostCalc)

	local boatTier = tier
	if boatTier == nil then
		FFGHelpers.PrintLog("Warning: Tier attribute is nil, defaulting to 1")
		boatTier = 1
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[boatTier] :: number
	FFGHelpers.PrintLog("Tier Multiplier: ", tierMultiplier)

	local realmMultiplier = math.pow(RealmId, 2.25) -- scaling curve

	local growthRate = 0
	if type == FFGEnum.ENTITIES.Boat then
		growthRate = Formulas.BOAT.GrowthRate
	else
		growthRate = Formulas.TENDER.GrowthRate
	end

	FFGHelpers.PrintLog("Growth Rate: ", growthRate)

	local cost = baseCostCalc * math.pow(growthRate, level) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

CALCULATOR.FishPerSecond = function(level: number, tier: number, RealmId: number)
	-- //TODO - look into why i am not calulating base cost based on tier note: i get basecost from the upgradableentity but i dont have a calculation for baseFPS that's why
	local baseFPS = FFGDefaults.BOAT_STARTING_ATT[FFGEnum.ATTRIBUTES.BOAT.FPS] or 10
	local growthRate = Formulas.BOAT.GrowthRate
	local tierMultiplier = Formulas.TIER_MULTIPLIER[tier]

	local fpsCalc = baseFPS * math.pow(growthRate, level) * tierMultiplier
	local nextLvlFPS = baseFPS * math.pow(growthRate, level + 1) * tierMultiplier

	-- //TODO - handle boosts

	return fpsCalc, nextLvlFPS
end

return CALCULATOR
