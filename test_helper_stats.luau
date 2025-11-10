-- Quick test script to verify helper stats
local ServerScriptService = game:GetService("ServerScriptService")
local Formulas = require(ServerScriptService.Server.Math.Formulas)

-- Mock functions for testing
local function clampLevel(level: number): number
	level = tonumber(level) or 1
	return math.clamp(level, 1, Formulas.MAX_LEVEL or 100)
end

local function getStageForLevel(level: number): number
	return Formulas.StageForLevel(level)
end

local function getStageMult(stageIndex: number): number
	local s = math.clamp(stageIndex, 1, Formulas.STAGE_COUNT or 1)
	local base = Formulas.STAGE_EARN_MULT[1] or 1
	local raw = Formulas.STAGE_EARN_MULT[s] or base
	return (base ~= 0) and (raw / base) or 1
end

local function getQualityMult(qualityId: number?): number
	if not qualityId then return 1 end
	return (Formulas.QUALITY_MULT and Formulas.QUALITY_MULT[qualityId]) or 1
end

-- Test helper calculations for Transporting at level 10, quality 1
local level = 10
local jobCategory = "Transporting"
local qualityId = 1

local lvl = clampLevel(level)
local stgIndex = getStageForLevel(lvl)
local rawStageMult = getStageMult(stgIndex)
local helperStageMult = 1 + (math.sqrt(rawStageMult) - 1) * 0.3
local qualityMult = getQualityMult(qualityId)

print("=== HELPER STATS TEST ===")
print("Level:", lvl)
print("Stage Index:", stgIndex)
print("Raw Stage Mult:", rawStageMult)
print("Helper Stage Mult:", helperStageMult)
print("Quality Mult:", qualityMult)

-- Calculate some stats manually
local helperBase = Formulas.HELPER_BASE.PerJobCategory[jobCategory]
local helperAdd = Formulas.HELPER_PER_LEVEL_ADD.PerJobCategory[jobCategory]

-- WalkSpeed (from defaults)
local walkSpeedBase = Formulas.HELPER_BASE.Defaults.WalkSpeed
local walkSpeedAdd = Formulas.HELPER_PER_LEVEL_ADD.Defaults.WalkSpeed
local walkSpeedLeveled = walkSpeedBase + walkSpeedAdd * (lvl - 1)
local walkSpeedFinal = walkSpeedLeveled * helperStageMult * qualityMult
print("WalkSpeed:", math.floor(walkSpeedFinal + 0.5))

-- FishValue
local fishValueBase = helperBase.FishValue
local fishValueAdd = helperAdd.FishValue
local fishValueLeveled = fishValueBase + fishValueAdd * (lvl - 1)
local fishValueFinal = fishValueLeveled * helperStageMult * qualityMult
print("FishValue:", math.floor(fishValueFinal * 1000 + 0.5) / 1000)

-- LoadTime
local loadTimeBase = helperBase.LoadTime
local loadTimeAdd = helperAdd.LoadTime
local loadTimeLeveled = loadTimeBase + loadTimeAdd * (lvl - 1)
-- Time reduction logic would go here, but let's see base first
print("LoadTime (before time reduction):", loadTimeLeveled)
