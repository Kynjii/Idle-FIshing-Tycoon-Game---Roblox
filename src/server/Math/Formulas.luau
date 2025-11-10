-- //SECTION - Progression knobs
local MAX_LEVEL = 100

local PROMO_LEVEL = { 1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }

local EARN_RATE = { 1.05, 1.04, 1.03, 1.025, 1.02, 1.015, 1.012, 1.01, 1.008, 1.006, 1.005 }
local COST_RATE = { 1.08, 1.10, 1.12, 1.14, 1.16, 1.18, 1.19, 1.20, 1.21, 1.22, 1.23 }

local EARN_BONUS = {
	[2] = 0.002,
	[3] = 0.003,
	[4] = 0.005,
	[5] = 0.008,
	[6] = 0.012,
	[7] = 0.015,
	[8] = 0.018,
	[9] = 0.022,
	[10] = 0.025,
	[11] = 0.030,
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

	-- Value of generic Fish (2 coins -> 1 Fish)

	FISH_BASEVALUE = 2,

	-- Entity baselines
	BOAT = { BaseCost = 100, BaseStorage = 20, BaseFPS = 1 },
	TENDER = { BaseCost = 110, BaseStorage = 25 },
	STORAGE = { BaseCost = 150, BaseStorage = 25 },
	BUILDING = { BaseCost = 1200 },
	HELPER = { BaseCost = 800 },
	JOBSLOT = { BaseCost = 1000 },

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

FORMULAS.PER_LEVEL_STORAGE_ADD = 8.0 -- +8 storage / level
FORMULAS.PER_LEVEL_FPS_ADD = 1 -- +1 FPS   / level

-- Add percentage-based per-level growth for compound excitement
FORMULAS.PER_LEVEL_MULT = 1.005 -- 0.5% compound growth per level

-- =========================
-- Time-stat tuning (Stage → % faster) - IMPROVED
-- =========================

FORMULAS.STAGE_TIME_REDUCTION_COEFF = 0.30 -- 30% per stage (was 20%)
FORMULAS.MAX_STAGE_TIME_REDUCTION = 0.80 -- cap 80% faster (was 50%)
FORMULAS.TIME_MIN_FRACTION = 0.02 -- never below 2% of base (was 5%)

-- Add breakthrough levels for major time reductions
FORMULAS.TIME_BREAKTHROUGH_LEVELS = {
	[20] = 0.10, -- -10% at level 20
	[40] = 0.20, -- -20% at level 40
	[60] = 0.30, -- -30% at level 60
	[80] = 0.40, -- -40% at level 80
	[100] = 0.50, -- -50% at level 100
}

-- =========================
-- Helper system knobs - IMPROVED
-- =========================

FORMULAS.QUALITY_MULT = {
	[1] = 1.00, -- Common
	[2] = 1.10, -- Uncommon
	[3] = 1.25, -- Rare
	[4] = 1.45, -- Epic
	[5] = 1.70, -- Legendary
	[6] = 2.00, -- Mythic
}

-- Base stats (defaults exist for all; per-jobCategory are exclusive)
FORMULAS.HELPER_BASE = {
	Defaults = {
		WalkSpeed = 5, -- "up"
		Storage = 30, -- "up"
		LoadTime = 12, -- "timeDown"
	},
	PerJobCategory = {
		Fishing = { CatchRate = 3, Luck = 0.015, CastTime = 8 }, -- CastTime "timeDown"
		Woodcutting = { WoodYield = 3, CritChance = 0.015, SwingRate = 8 },
		Mining = { OreYield = 3, CritChance = 0.015, SwingRate = 8 },
		Transporting = { Storage = 50, FishValue = 0.08, LoadTime = 10 },
	},
}

-- Per-level additive growth (small, before Stage/Quality)
FORMULAS.HELPER_PER_LEVEL_ADD = {
	Defaults = {
		WalkSpeed = 0.1,
		Storage = 5,
		LoadTime = 0.02,
	},
	PerJobCategory = {
		Fishing = { CatchRate = 0.08, Luck = 0.001, CastTime = 0.02 },
		Woodcutting = { WoodYield = 0.08, CritChance = 0.001, SwingRate = 0.02 },
		Mining = { OreYield = 0.08, CritChance = 0.001, SwingRate = 0.02 },
		Transporting = { Storage = 8, FishValue = 0.003, LoadTime = 0.025 },
	},
}

-- Stat types (decides math path for each stat)
-- "up" = integer stats that scale up (Storage, CatchRate, etc.)
-- "decimal" = decimal stats that should preserve precision (FishValue, Luck, CritChance, etc.)
-- "timeDown" = time stats that scale down with quality/stage
FORMULAS.HELPER_STAT_TYPES = {
	-- Defaults
	WalkSpeed = "up",
	Storage = "up",
	-- Fishing
	CatchRate = "up",
	Luck = "decimal",
	CastTime = "timeDown",
	-- Woodcutting
	WoodYield = "up",
	CritChance = "decimal",
	SwingRate = "timeDown",
	-- Mining
	OreYield = "up",
	-- Transport
	FishStorage = "up",
	FishValue = "decimal",
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
