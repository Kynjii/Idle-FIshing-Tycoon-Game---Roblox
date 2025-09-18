local ServerScriptService = game:GetService("ServerScriptService")
local Formulas = require(ServerScriptService.Server.Math.Formulas)

local ClassCalculator = {}

local function clampLevel(level: number)
	level = tonumber(level) or 1
	return math.clamp(level, 1, Formulas.MAX_LEVEL or 100)
end

local function clampStage(s)
	s = tonumber(s) or 1
	return math.clamp(s, 1, Formulas.STAGE_COUNT or 1)
end

-- //SECTION - Boats
function ClassCalculator.CalculateBaseValue(baseValue: number, tier: number, realmNum: number)
	local tierMultiplier = Formulas.TIER_MULTIPLIER[tier] or 1
	local realmMultiplier = (realmNum and math.pow(realmNum, 2.25)) or 1
	return baseValue * tierMultiplier * realmMultiplier
end

function ClassCalculator.CalculateUpgradeCost(baseValue: number, level: number)
	level = clampLevel(level)
	local mult = (Formulas.COST_MULT and Formulas.COST_MULT[level]) or 1
	return baseValue * mult
end

function ClassCalculator.CalculateMaxStorage(baseValue: number, level: number, percentBuffValue: number?)
	local lvl = clampLevel(level)
	local nextLvl = clampLevel(level + 1)

	local earnNow = (Formulas.EARN_MULT and Formulas.EARN_MULT[lvl]) or 1
	local earnNext = (Formulas.EARN_MULT and Formulas.EARN_MULT[nextLvl]) or earnNow

	local maxStorage = baseValue * earnNow
	local nextLvlStorage = baseValue * earnNext

	if percentBuffValue then
		local buffedValue = percentBuffValue * maxStorage
		local buffedNxtvalue = percentBuffValue * nextLvlStorage
		maxStorage += buffedValue
		nextLvlStorage += buffedNxtvalue
	end

	return maxStorage, nextLvlStorage
end

function ClassCalculator.CalculateFPS(baseFPS: number, upgradeStage: number, percentBuffValue: number?)
	local sNow = clampStage(upgradeStage)
	local sNext = clampStage(upgradeStage + 1)

	local multNow = (Formulas.STAGE_EARN_MULT and Formulas.STAGE_EARN_MULT[sNow]) or 1
	local multNext = (Formulas.STAGE_EARN_MULT and Formulas.STAGE_EARN_MULT[sNext]) or multNow

	local fpsNow = baseFPS * multNow
	local fpsNext = baseFPS * multNext

	if percentBuffValue then
		local buffedValue = percentBuffValue * fpsNow
		local buffedNxtvalue = percentBuffValue * fpsNext
		fpsNow += buffedValue
		fpsNext += buffedNxtvalue
	end

	return fpsNow, fpsNext
end

function ClassCalculator.CalculateTravelTime(baseValue: number, percentBuffValue: number?)
	local travelTime = math.max(1, baseValue)

	if percentBuffValue then
		local buffedValue = percentBuffValue * travelTime
		travelTime -= buffedValue
	end

	return travelTime
end

function ClassCalculator.CalculateLoadTime(baseValue: number, percentBuffValue: number?)
	local loadTime = baseValue

	if percentBuffValue then
		local buffedValue = percentBuffValue * loadTime
		loadTime -= buffedValue
	end

	return loadTime
end

return ClassCalculator
