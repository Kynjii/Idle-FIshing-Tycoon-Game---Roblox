-- //SECTION - Progression knobs
local MAX_LEVEL = 500

local PROMO_LEVEL = { 1, 5, 10, 20, 35, 55, 80, 110, 145, 185, 230, 280, 335, 395, 460, 500 }

local EARN_RATE = { 1.30, 1.25, 1.20, 1.18, 1.15, 1.12, 1.10, 1.08, 1.06, 1.05, 1.04, 1.04, 1.03, 1.03, 1.02, 1.02 }
local COST_RATE = { 1.18, 1.20, 1.22, 1.23, 1.24, 1.25, 1.26, 1.27, 1.28, 1.29, 1.30, 1.31, 1.32, 1.33, 1.34, 1.35 }

local EARN_BONUS = {
	[2] = 0.05,
	[3] = 0.05,
	[4] = 0.06,
	[5] = 0.06,
	[6] = 0.07,
	[7] = 0.07,
	[8] = 0.08,
	[9] = 0.08,
	[10] = 0.09,
	[11] = 0.09,
	[12] = 0.10,
	[13] = 0.10,
	[14] = 0.11,
	[15] = 0.11,
	[16] = 0.12,
}
-- //!SECTION

-- //SECTION - Helpers (internal)
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
-- //!SECTION

-- //SECTION - Cumulative level multipliers
local EARN_MULT = buildMultipliers(EARN_RATE, EARN_BONUS) -- index by level
local COST_MULT = buildMultipliers(COST_RATE, nil) -- index by level

-- Derive a stage-based earning multiplier by sampling the cumulative at each promo level.
local STAGE_COUNT = #PROMO_LEVEL
local STAGE_EARN_MULT = table.create(STAGE_COUNT, 1)
for s = 1, STAGE_COUNT do
	local lvlAtStage = PROMO_LEVEL[s]
	STAGE_EARN_MULT[s] = EARN_MULT[lvlAtStage]
end
-- //!SECTION

-- //SECTION - Economy baselines
local FORMULAS = {
	-- Core progression
	MAX_LEVEL = MAX_LEVEL,
	PROMO_LEVEL = PROMO_LEVEL,
	EARN_RATE = EARN_RATE,
	COST_RATE = COST_RATE,
	EARN_BONUS = EARN_BONUS,

	-- Level-indexed cumulative multipliers
	EARN_MULT = EARN_MULT,
	COST_MULT = COST_MULT,

	-- Stage-indexed (sampled from EARN_MULT at promo levels)
	STAGE_COUNT = STAGE_COUNT,
	STAGE_EARN_MULT = STAGE_EARN_MULT,

	-- Convenience helpers
	StageForLevel = stageForLevel,
	GetEarnMultiplier = function(level: number)
		return EARN_MULT[math.clamp(level, 1, MAX_LEVEL)]
	end,
	GetCostMultiplier = function(level: number)
		return COST_MULT[math.clamp(level, 1, MAX_LEVEL)]
	end,

	-- Entity baselines
	BOAT = { BaseCost = 100, BaseStorage = 100, BaseFPS = 5 },
	TENDER = { BaseCost = 100, BaseStorage = 200 },
	STORAGE = { BaseCost = 200, BaseStorage = 200 },
	BUILDING = { BaseCost = 1500 },
	HELPER = { BaseCost = 1000 },

	-- Tier (rarity) curve used elsewhere in the economy
	TIER_MULTIPLIER = {
		[1] = 1,
		[2] = 8,
		[3] = 20,
		[4] = 45,
		[5] = 100,
		[6] = 200,
	},
}
-- //!SECTION

-- =========================
-- Additive per-level growth (before Stage/Quality)
-- =========================

FORMULAS.PER_LEVEL_STORAGE_ADD = 30.0 -- +30 storage / level
FORMULAS.PER_LEVEL_FPS_ADD = 10 -- +10 FPS   / level

-- Add percentage-based per-level growth for compound excitement
FORMULAS.PER_LEVEL_MULT = 1.02 -- 2% compound growth per level

-- =========================
-- Time-stat tuning (Stage → % faster) - IMPROVED
-- =========================

FORMULAS.STAGE_TIME_REDUCTION_COEFF = 0.30 -- 30% per stage (was 20%)
FORMULAS.MAX_STAGE_TIME_REDUCTION = 0.80 -- cap 80% faster (was 50%)
FORMULAS.TIME_MIN_FRACTION = 0.02 -- never below 2% of base (was 5%)

-- Add breakthrough levels for major time reductions
FORMULAS.TIME_BREAKTHROUGH_LEVELS = {
	[25] = 0.15, -- -15% at level 25
	[50] = 0.25, -- -25% at level 50
	[100] = 0.40, -- -40% at level 100
	[200] = 0.55, -- -55% at level 200
	[350] = 0.70, -- -70% at level 350
}

-- =========================
-- Helper system knobs - IMPROVED
-- =========================

FORMULAS.QUALITY_MULT = {
	[1] = 1.00, -- Common
	[2] = 1.20, -- Uncommon
	[3] = 1.45, -- Rare
	[4] = 1.75, -- Epic
	[5] = 2.10, -- Legendary
	[6] = 2.50, -- Mythic
}

-- Base stats (defaults exist for all; per-jobCategory are exclusive)
FORMULAS.HELPER_BASE = {
	Defaults = {
		WalkSpeed = 5, -- "up"
		Storage = 50, -- "up"
		LoadTime = 15, -- "timeDown"
	},
	PerJobCategory = {
		Fishing = { CatchRate = 5, Luck = 0.02, CastTime = 6 }, -- CastTime "timeDown"
		Woodcutting = { WoodYield = 5, CritChance = 0.02, SwingRate = 6 },
		Mining = { OreYield = 5, CritChance = 0.02, SwingRate = 6 },
		Transporting = { Storage = 100, FishValue = 12, LoadTime = 10 },
	},
}

-- Per-level additive growth (small, before Stage/Quality)
FORMULAS.HELPER_PER_LEVEL_ADD = {
	Defaults = {
		WalkSpeed = 0.35,
		Storage = 30,
		LoadTime = 0.01,
	},
	PerJobCategory = {
		Fishing = { CatchRate = 0.30, Luck = 1, CastTime = 0.01 },
		Woodcutting = { WoodYield = 0.30, CritChance = 1, SwingRate = 0.01 },
		Mining = { OreYield = 0.30, CritChance = 1, SwingRate = 0.01 },
		Transporting = { Storage = 0.50, FishValue = 1, LoadTime = 0.03 },
	},
}

-- Stat types (decides math path for each stat)
FORMULAS.HELPER_STAT_TYPES = {
	-- Defaults
	WalkSpeed = "up",
	Storage = "up",
	-- Fishing
	CatchRate = "up",
	Luck = "up",
	CastTime = "timeDown",
	-- Woodcutting
	WoodYield = "up",
	CritChance = "up",
	SwingRate = "timeDown",
	-- Mining
	OreYield = "up",
	-- Transport
	FishStorage = "up",
	FishValue = "up",
	LoadTime = "timeDown",
}

-- =========================
-- Perks: slots, value ranges, selection weights - IMPROVED
-- =========================

-- Everyone gets perks now for more interesting gameplay
FORMULAS.QUALITY_PERK_COUNT = {
	[1] = 1, -- Common
	[2] = 1, -- Uncommon
	[3] = 2, -- Rare
	[4] = 2, -- Epic
	[5] = 3, -- Legendary
	[6] = 3, -- Mythic
}

-- Slight magnitude scaling by quality (kept modest for balance)
FORMULAS.QUALITY_PERK_VALUE_MULT = {
	[1] = 1.00,
	[2] = 1.00,
	[3] = 1.05,
	[4] = 1.08,
	[5] = 1.10,
	[6] = 1.12,
}

-- Perk value ranges (fractions unless noted). Keys must match HelperCalculator's PERKS_DEF.
FORMULAS.PERK_VALUE_RANGES = {
	Fleet = { min = 0.06, max = 0.12 }, -- +% WalkSpeed
	Organizer = { min = 0.08, max = 0.15 }, -- +% Storage
	SwiftHands = { min = 0.06, max = 0.12 }, -- -% time stats

	SeasonedAngler = { min = 0.10, max = 0.18 }, -- +% CatchRate (+flat Luck side bonus)
	TrueGrit = { min = 0.10, max = 0.18 }, -- +% WoodYield (+flat Sturdiness)
	StoneSense = { min = 0.10, max = 0.18 }, -- +% OreYield (+flat Prospecting)
	FishMonger = { min = 0.10, max = 0.18 }, -- +% FishValue (+flat RouteSkill)
}

-- Small flat "side bonuses" paired with some perks
FORMULAS.PERK_FLAT_SIDE_BONUS = {
	SeasonedAngler = 3, -- +Luck
	TrueGrit = 3, -- +Sturdiness
	StoneSense = 3, -- +Prospecting
	FishMonger = 3, -- +RouteSkill
}

-- Optional weighted selection for perks (higher = more likely).
FORMULAS.PERK_SELECTION_WEIGHTS = {
	-- Fleet = 1.0,
	-- Organizer = 1.0,
	-- SwiftHands = 0.8,
	-- SeasonedAngler = 1.2,
	-- TrueGrit = 1.2,
	-- StoneSense = 1.2,
	-- FishMonger = 1.2,
}

-- =========================
-- Resource Scaling Improvements (#6)
-- =========================

-- Milestone bonuses to break up progression walls
FORMULAS.MILESTONE_BONUSES = {
	-- Level milestones
	[10] = { type = "cost_reduction", value = 0.10 }, -- -10% costs
	[25] = { type = "earn_boost", value = 0.25 }, -- +25% earnings
	[50] = { type = "helper_slots", value = 1 }, -- +1 helper slot
	[75] = { type = "cost_reduction", value = 0.15 }, -- -15% costs
	[100] = { type = "earn_boost", value = 0.50 }, -- +50% earnings
	[150] = { type = "helper_slots", value = 2 }, -- +2 helper slots
	[200] = { type = "cost_reduction", value = 0.20 }, -- -20% costs
	[250] = { type = "earn_boost", value = 0.75 }, -- +75% earnings
	[300] = { type = "helper_slots", value = 2 }, -- +2 helper slots
	[400] = { type = "cost_reduction", value = 0.25 }, -- -25% costs
	[500] = { type = "earn_boost", value = 1.00 }, -- +100% earnings
}

return FORMULAS
