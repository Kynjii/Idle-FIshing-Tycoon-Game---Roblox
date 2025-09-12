local MAX_LEVEL = 100

-- Promotion start levels (stage 1 begins at 1, stage 2 at 10, etc.)
local PROMO_LEVEL = { 1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }

-- Per-level multipliers INSIDE each stage
-- Early stages: earnings > costs
-- Later stages: costs > earnings
local EARN_RATE = { 1.25, 1.16, 1.12, 1.10, 1.08, 1.08, 1.07, 1.06, 1.05, 1.05 } -- FPS / Storage
local COST_RATE = { 1.14, 1.16, 1.18, 1.19, 1.20, 1.21, 1.22, 1.23, 1.24, 1.25 } -- Upgrade Cost

-- One-time bonus when ENTERING a stage (by stage index after the bump).
-- Example: when a Boat goes from stage 1 -> 2 (at level 10), apply +7% immediately.
local EARN_BONUS = {
	[2] = 0.07,
	[3] = 0.07,
	[4] = 0.08,
	[5] = 0.08,
	[6] = 0.10,
	[7] = 0.10,
	[8] = 0.12,
	[9] = 0.12,
	[10] = 0.15,
}

local function stageForLevel(level: number): number
	level = math.clamp(level, 1, MAX_LEVEL)
	local stage = 1
	for i = 2, #PROMO_LEVEL do
		if level >= PROMO_LEVEL[i] then
			stage = i
		else
			break
		end
	end
	return stage
end

local function buildMultipliers(ratePerStage: { number }, bonusPerStage: { [number]: number }?)
	local mult = table.create(MAX_LEVEL + 1, 1)
	local cur = 1
	local stage = stageForLevel(1)
	local nextPromoIdx = stage + 1
	local nextPromoLevel = PROMO_LEVEL[nextPromoIdx] or math.huge

	for lvl = 1, MAX_LEVEL do
		if lvl == nextPromoLevel then
			stage += 1
			if bonusPerStage and bonusPerStage[stage] then
				cur *= (1 + bonusPerStage[stage])
			end
			nextPromoIdx += 1
			nextPromoLevel = PROMO_LEVEL[nextPromoIdx] or math.huge
		end
		local r = ratePerStage[stage] or ratePerStage[#ratePerStage]
		cur *= r
		mult[lvl] = cur
	end
	return mult
end

local EARN_MULT = buildMultipliers(EARN_RATE, EARN_BONUS)
local COST_MULT = buildMultipliers(COST_RATE, nil)

local FORMULAS = {
	MAX_LEVEL = MAX_LEVEL,
	PROMO_LEVEL = PROMO_LEVEL,
	EARN_RATE = EARN_RATE, -- per-stage rates (for tuning UI/debug)
	COST_RATE = COST_RATE,
	EARN_BONUS = EARN_BONUS, -- optional

	-- Cumulative products
	EARN_MULT = EARN_MULT, -- EARN_MULT[level]
	COST_MULT = COST_MULT, -- COST_MULT[level]

	-- Helper queries
	StageForLevel = stageForLevel,
	GetEarnMultiplier = function(level: number)
		return EARN_MULT[math.clamp(level, 1, MAX_LEVEL)]
	end,
	GetCostMultiplier = function(level: number)
		return COST_MULT[math.clamp(level, 1, MAX_LEVEL)]
	end,

	BOAT = {
		BaseCost = 100,
		BaseStorage = 100,
		BaseFPS = 10,
	},
	TENDER = {
		BaseCost = 100,
		BaseStorage = 95,
	},
	TIER_MULTIPLIER = {
		[1] = 1,
		[2] = 10,
		[3] = 25,
		[4] = 60,
		[5] = 150,
		[6] = 300,
	},
}

local STAGE_COUNT = #PROMO_LEVEL
local STAGE_EARN_MULT = table.create(STAGE_COUNT, 1)

for s = 1, STAGE_COUNT do
	local lvlAtStage = PROMO_LEVEL[s] -- e.g., 1,10,20,...
	STAGE_EARN_MULT[s] = EARN_MULT[lvlAtStage] -- use the cumulative at that level
end

FORMULAS.STAGE_COUNT = STAGE_COUNT
FORMULAS.STAGE_EARN_MULT = STAGE_EARN_MULT

-- Optional: allow hot-reload tuning in Studio without restart.
function FORMULAS.Rebuild()
	FORMULAS.EARN_MULT = buildMultipliers(FORMULAS.EARN_RATE, FORMULAS.EARN_BONUS)
	FORMULAS.COST_MULT = buildMultipliers(FORMULAS.COST_RATE, nil)

	-- Rebuild stage tables as well
	FORMULAS.STAGE_COUNT = #FORMULAS.PROMO_LEVEL
	local stageMult = table.create(FORMULAS.STAGE_COUNT, 1)
	for s = 1, FORMULAS.STAGE_COUNT do
		local lvlAtStage = FORMULAS.PROMO_LEVEL[s]
		stageMult[s] = FORMULAS.EARN_MULT[lvlAtStage]
	end
	FORMULAS.STAGE_EARN_MULT = stageMult
end

return FORMULAS
