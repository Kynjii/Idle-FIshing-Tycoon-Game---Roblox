--!strict
-- Server/Math/Formulas.lua

-- =========================
-- Core progression knobs
-- =========================

local MAX_LEVEL = 100

-- Level thresholds where you "promote" to the next stage (1-indexed stage)
local PROMO_LEVEL = { 1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }

-- Early stages: earnings > costs ; Later stages: costs > earnings
-- Per-stage geometric rates used to build cumulative level multipliers.
local EARN_RATE = { 1.25, 1.16, 1.12, 1.10, 1.08, 1.08, 1.07, 1.06, 1.05, 1.05 } -- FPS / Storage, etc.
local COST_RATE = { 1.14, 1.16, 1.18, 1.19, 1.20, 1.21, 1.22, 1.23, 1.24, 1.25 } -- Upgrade Cost

-- One-time bonus when ENTERING a stage (by stage index AFTER the bump).
-- Example: going 1 -> 2 at level 10 applies +7% immediately.
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

-- =========================
-- Helpers (internal)
-- =========================

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

-- =========================
-- Cumulative level multipliers
-- =========================

local EARN_MULT = buildMultipliers(EARN_RATE, EARN_BONUS) -- index by level
local COST_MULT = buildMultipliers(COST_RATE, nil) -- index by level

-- Derive a stage-based earning multiplier by sampling the cumulative at each promo level.
local STAGE_COUNT = #PROMO_LEVEL
local STAGE_EARN_MULT = table.create(STAGE_COUNT, 1)
for s = 1, STAGE_COUNT do
	local lvlAtStage = PROMO_LEVEL[s]
	STAGE_EARN_MULT[s] = EARN_MULT[lvlAtStage]
end

-- =========================
-- Economy baselines
-- =========================

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
	TENDER = { BaseCost = 100, BaseStorage = 60 },
	STORAGE = { BaseCost = 25, BaseStorage = 200 },
	BUILDING = { BaseCost = 1000 },

	-- Tier (rarity) curve used elsewhere in your economy
	TIER_MULTIPLIER = {
		[1] = 1,
		[2] = 8,
		[3] = 20,
		[4] = 45,
		[5] = 100,
		[6] = 200,
	},
}

-- =========================
-- Additive per-level growth (before Stage/Quality)
-- =========================

FORMULAS.PER_LEVEL_STORAGE_ADD = 3.0 -- +3 storage / level
FORMULAS.PER_LEVEL_FPS_ADD = 0.5 -- +0.5 FPS   / level

-- =========================
-- Time-stat tuning (Stage → % faster)
-- =========================

FORMULAS.STAGE_TIME_REDUCTION_COEFF = 0.20 -- each +1.0 of (stageMult-1) ≈ 20% faster
FORMULAS.MAX_STAGE_TIME_REDUCTION = 0.50 -- cap 50% faster from Stage
FORMULAS.TIME_MIN_FRACTION = 0.05 -- never below 5% of base

-- =========================
-- Helper system knobs
-- =========================

-- Quality (rarity) multiplier after Level & Stage
FORMULAS.QUALITY_MULT = {
	[1] = 1.00, -- Common
	[2] = 1.15, -- Uncommon
	[3] = 1.35, -- Rare
	[4] = 1.60, -- Epic
	[5] = 1.90, -- Legendary
	[6] = 2.30, -- Mythic
}

-- Base stats (defaults exist for all; per-jobCategory are exclusive)
FORMULAS.HELPER_BASE = {
	Defaults = {
		WalkSpeed = 10, -- “up”
		Storage = 50, -- “up”
	},
	PerJobCategory = {
		Fishing = { CatchRate = 5, Luck = 0, CastTime = 6 }, -- CastTime “timeDown”
		Woodcutting = { ChopRate = 5, Sturdiness = 0, SwingTime = 5 },
		Mining = { OreYield = 4, Prospecting = 0, SwingTime = 6 },
		Transport = { Throughput = 8, RouteSkill = 0, TravelTime = 12 },
	},
}

-- Per-level additive growth (small, before Stage/Quality)
FORMULAS.HELPER_PER_LEVEL_ADD = {
	Defaults = {
		WalkSpeed = 0.35,
		Storage = 3.00,
	},
	PerJobCategory = {
		Fishing = { CatchRate = 0.30, Luck = 0.15, CastTime = 0.00 },
		Woodcutting = { ChopRate = 0.30, Sturdiness = 0.15, SwingTime = 0.00 },
		Mining = { OreYield = 0.28, Prospecting = 0.15, SwingTime = 0.00 },
		Transport = { Throughput = 0.40, RouteSkill = 0.15, TravelTime = 0.00 },
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
	ChopRate = "up",
	Sturdiness = "up",
	SwingTime = "timeDown",
	-- Mining
	OreYield = "up",
	Prospecting = "up", -- SwingTime already defined
	-- Transport
	Throughput = "up",
	RouteSkill = "up",
	TravelTime = "timeDown",
}

-- =========================
-- Perks: slots, value ranges, selection weights
-- =========================

-- How many perk slots a Helper gets by quality
FORMULAS.QUALITY_PERK_COUNT = {
	[1] = 0, -- Common
	[2] = 0, -- Uncommon
	[3] = 1, -- Rare
	[4] = 2, -- Epic
	[5] = 2, -- Legendary
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

-- Perk value ranges (fractions unless noted). Keys must match your HelperCalculator’s PERKS_DEF.
FORMULAS.PERK_VALUE_RANGES = {
	Fleet = { min = 0.06, max = 0.12 }, -- +% WalkSpeed
	Organizer = { min = 0.08, max = 0.15 }, -- +% Storage
	SwiftHands = { min = 0.06, max = 0.12 }, -- -% time stats

	SeasonedAngler = { min = 0.10, max = 0.18 }, -- +% CatchRate (+flat Luck side bonus)
	TrueGrit = { min = 0.10, max = 0.18 }, -- +% ChopRate (+flat Sturdiness)
	StoneSense = { min = 0.10, max = 0.18 }, -- +% OreYield (+flat Prospecting)
	RoadCraft = { min = 0.10, max = 0.18 }, -- +% Throughput (+flat RouteSkill)
}

-- Small flat “side bonuses” paired with some perks
FORMULAS.PERK_FLAT_SIDE_BONUS = {
	SeasonedAngler = 3, -- +Luck
	TrueGrit = 3, -- +Sturdiness
	StoneSense = 3, -- +Prospecting
	RoadCraft = 3, -- +RouteSkill
}

-- Optional weighted selection for perks (higher = more likely). Omit for uniform.
FORMULAS.PERK_SELECTION_WEIGHTS = {
	-- Fleet = 1.0,
	-- Organizer = 1.0,
	-- SwiftHands = 0.8,
	-- SeasonedAngler = 1.2,
	-- TrueGrit = 1.2,
	-- StoneSense = 1.2,
	-- RoadCraft = 1.2,
}

return FORMULAS
