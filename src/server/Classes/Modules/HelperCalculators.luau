local ServerScriptService = game:GetService("ServerScriptService")
local Formulas = require(ServerScriptService.Server.Math.Formulas)

local HelperCalculator = {}

-- //SECTION -  Utility: clamps & lookups

export type StatsTable = { [string]: number }

local function clampLevel(level: number): number
	level = tonumber(level) or 1
	return math.clamp(level, 1, Formulas.MAX_LEVEL or 100)
end

local function clampStage(stageIndex: number): number
	stageIndex = tonumber(stageIndex) or 1
	return math.clamp(stageIndex, 1, Formulas.STAGE_COUNT or 1)
end

local function getStageForLevel(level: number): number
	return Formulas.StageForLevel(level)
end

local function getStageMult(stageIndex: number): number
	local s = clampStage(stageIndex)
	local base = Formulas.STAGE_EARN_MULT[1] or 1
	local raw = Formulas.STAGE_EARN_MULT[s] or base
	return (base ~= 0) and (raw / base) or 1
end

local function getStageTimeReductionFraction(stageIndex: number): number
	local stageMult = getStageMult(stageIndex) -- normalized (Stage 1 == 1.0)
	local coeff = Formulas.STAGE_TIME_REDUCTION_COEFF or 0.20
	local cap = Formulas.MAX_STAGE_TIME_REDUCTION or 0.50
	local r = (stageMult - 1) * coeff
	if r > cap then r = cap end
	if r < 0 then r = 0 end
	return r
end

local function getQualityMult(qualityId: number?): number
	if not qualityId then return 1 end
	return (Formulas.QUALITY_MULT and Formulas.QUALITY_MULT[qualityId]) or 1
end
-- //!SECTION

-- //SECTION -  Perks (jobjobCategory-aware, value-driven)

type PerkDef = {
	Key: string,
	MinQuality: number,
	Allowed: { [string]: boolean },
	Apply: (stats: StatsTable, value: number) -> (),
}

local PERKS_DEF: { PerkDef } = {
	{
		Key = "Fleet",
		MinQuality = 3,
		Allowed = { Fishing = true, Woodcutting = true, Mining = true, Transport = true },
		Apply = function(stats, value)
			if stats.WalkSpeed then stats.WalkSpeed = math.floor(stats.WalkSpeed * (1 + value) + 0.5) end
		end,
	},
	{
		Key = "Organizer",
		MinQuality = 4,
		Allowed = { Fishing = true, Woodcutting = true, Mining = true, Transport = true },
		Apply = function(stats, value)
			if stats.Storage then stats.Storage = math.floor(stats.Storage * (1 + value) + 0.5) end
		end,
	},
	{
		Key = "SwiftHands",
		MinQuality = 5,
		Allowed = { Fishing = true, Woodcutting = true, Mining = true, Transport = true },
		Apply = function(stats, value)
			-- value is a fraction: 0.10 => 10% faster (lower time)
			local factor = math.max(0.05, 1 - value) -- never reduce more than 95% in one go
			if stats.CastTime then stats.CastTime = math.max(1, math.floor(stats.CastTime * factor + 0.5)) end
			if stats.SwingTime then stats.SwingTime = math.max(1, math.floor(stats.SwingTime * factor + 0.5)) end
			if stats.TravelTime then stats.TravelTime = math.max(1, math.floor(stats.TravelTime * factor + 0.5)) end
		end,
	},
	{
		Key = "SeasonedAngler",
		MinQuality = 4,
		Allowed = { Fishing = true },
		Apply = function(stats, value)
			if stats.CatchRate then stats.CatchRate = math.floor(stats.CatchRate * (1 + value) + 0.5) end
			local flat = (Formulas.PERK_FLAT_SIDE_BONUS and Formulas.PERK_FLAT_SIDE_BONUS.SeasonedAngler) or 0
			if stats.Luck then stats.Luck = stats.Luck + flat end
		end,
	},
	{
		Key = "TrueGrit",
		MinQuality = 4,
		Allowed = { Woodcutting = true },
		Apply = function(stats, value)
			if stats.ChopRate then stats.ChopRate = math.floor(stats.ChopRate * (1 + value) + 0.5) end
			local flat = (Formulas.PERK_FLAT_SIDE_BONUS and Formulas.PERK_FLAT_SIDE_BONUS.TrueGrit) or 0
			if stats.Sturdiness then stats.Sturdiness = stats.Sturdiness + flat end
		end,
	},
	{
		Key = "StoneSense",
		MinQuality = 4,
		Allowed = { Mining = true },
		Apply = function(stats, value)
			if stats.OreYield then stats.OreYield = math.floor(stats.OreYield * (1 + value) + 0.5) end
			local flat = (Formulas.PERK_FLAT_SIDE_BONUS and Formulas.PERK_FLAT_SIDE_BONUS.StoneSense) or 0
			if stats.Prospecting then stats.Prospecting = stats.Prospecting + flat end
		end,
	},
	{
		Key = "RoadCraft",
		MinQuality = 4,
		Allowed = { Transport = true },
		Apply = function(stats, value)
			if stats.Throughput then stats.Throughput = math.floor(stats.Throughput * (1 + value) + 0.5) end
			local flat = (Formulas.PERK_FLAT_SIDE_BONUS and Formulas.PERK_FLAT_SIDE_BONUS.RoadCraft) or 0
			if stats.RouteSkill then stats.RouteSkill = stats.RouteSkill + flat end
		end,
	},
}

-- //!SECTION

-- //SECTION - RNG Helpers
local function makeRng(seed: number?)
	local s = seed or math.random(1, 1e9)
	return function()
		s = (1664525 * s + 1013904223) % 2 ^ 32
		return (s / 2 ^ 32)
	end
end

-- Weighted choice without replacement
local function weightedDraw(rng, items: { any }, getWeight): any
	local total = 0
	for _, it in ipairs(items) do
		total += math.max(0, getWeight(it))
	end
	if total <= 0 then return items[math.max(1, math.floor(rng() * #items) + 1)] end
	local r = rng() * total
	local acc = 0
	for _, it in ipairs(items) do
		acc += math.max(0, getWeight(it))
		if r <= acc then return it end
	end
	return items[#items]
end
-- //!SECTION

-- ========= Build eligible perk pool for (jobCategory, quality) =========
local function buildPerkPool(jobCategory: string, qualityId: number)
	local pool = {}
	for _, perk in ipairs(PERKS_DEF) do
		if perk.MinQuality <= qualityId and perk.Allowed[jobCategory] then table.insert(pool, perk) end
	end
	return pool
end

-- ========= Randomly choose perk KEYS (no duplicates), seeded =========
-- Returns up to slotCount keys from the eligible pool. If pool < slots, returns all.
function HelperCalculator.ChooseRandomPerkKeys(jobCategory: string, qualityId: number, seed: number?): { string }
	local slotCount = (Formulas.QUALITY_PERK_COUNT and Formulas.QUALITY_PERK_COUNT[qualityId]) or 0
	if slotCount <= 0 then return {} end

	local pool = buildPerkPool(jobCategory, qualityId)
	if #pool == 0 then return {} end

	local weights = Formulas.PERK_SELECTION_WEIGHTS or {}
	local function getWeight(perkDef: PerkDef)
		return weights[perkDef.Key] or 1.0
	end

	local rng = makeRng(seed)
	local chosen: { string } = {}
	-- copy pool so we can remove drawn items
	local bag = table.clone(pool)

	for _ = 1, math.min(slotCount, #bag) do
		local pick = weightedDraw(rng, bag, getWeight)
		table.insert(chosen, pick.Key)
		-- remove chosen from bag
		for i, it in ipairs(bag) do
			if it == pick then
				table.remove(bag, i)
				break
			end
		end
	end

	return chosen
end

-- ========= Roll magnitudes for the chosen keys (seeded) =========
function HelperCalculator.RollPerkValuesForKeys(perkKeys: { string }, qualityId: number, seed: number?): { [string]: number }
	local ranges = Formulas.PERK_VALUE_RANGES or {}
	local qMults = Formulas.QUALITY_PERK_VALUE_MULT or {}
	local qMult = qMults[qualityId] or 1.0

	local rng = makeRng(seed)
	local values: { [string]: number } = {}

	for _, key in ipairs(perkKeys) do
		local r = ranges[key]
		if r then
			local roll = r.min + (r.max - r.min) * rng()
			values[key] = roll * qMult
		else
			values[key] = 0
		end
	end
	return values
end

-- ========= Apply exact (key -> value) set; stable for previews =========
function HelperCalculator.GenerateStatsWithPerkValues(jobCategory: string, level: number, qualityId: number, perkValues: { [string]: number }): ({ [string]: number }, { string })
	-- Base stats (deterministic)
	local stats = select(1, HelperCalculator.CalculateStats(jobCategory, level, qualityId))
	local applied: { string } = {}

	-- Apply in PERKS_DEF order for consistent stacking
	for _, perk in ipairs(PERKS_DEF) do
		local value = perkValues[perk.Key]
		if value and perk.MinQuality <= qualityId and perk.Allowed[jobCategory] then
			perk.Apply(stats, value)
			table.insert(applied, string.format("%s (+%d%%)", perk.Key, math.floor(value * 100 + 0.5)))
		end
	end

	return stats, applied
end

-- ========= Compare current vs next with SAME locked perks/values =========
function HelperCalculator.CompareLevelsWithPerks(jobCategory: string, level: number, qualityId: number, perkValues: { [string]: number })
	local cur = select(1, HelperCalculator.GenerateStatsWithPerkValues(jobCategory, level, qualityId, perkValues))
	local nxt = select(1, HelperCalculator.GenerateStatsWithPerkValues(jobCategory, level + 1, qualityId, perkValues))

	local delta: { [string]: number } = {}
	for k, v in pairs(cur) do
		delta[k] = (nxt[k] or 0) - v
	end
	for k, v in pairs(nxt) do
		if delta[k] == nil then delta[k] = v - (cur[k] or 0) end
	end

	return { current = cur, next = nxt, delta = delta, perks = perkValues }
end

-- ========= Upgrading quality: add new slots without touching existing picks =========
function HelperCalculator.AddSlotsOnQualityUpgrade(jobCategory: string, oldQualityId: number, newQualityId: number, existingKeys: { string }, existingValues: { [string]: number }, seed: number?): ({ string }, { [string]: number })
	local oldSlots = (Formulas.QUALITY_PERK_COUNT and Formulas.QUALITY_PERK_COUNT[oldQualityId]) or 0
	local newSlots = (Formulas.QUALITY_PERK_COUNT and Formulas.QUALITY_PERK_COUNT[newQualityId]) or 0
	if newSlots <= oldSlots then
		return existingKeys, existingValues -- nothing to add
	end
	local need = newSlots - oldSlots

	-- Build pool for NEW quality, remove already-chosen keys
	local pool = buildPerkPool(jobCategory, newQualityId)
	local taken = {}
	for _, k in ipairs(existingKeys) do
		taken[k] = true
	end

	local available = {}
	for _, p in ipairs(pool) do
		if not taken[p.Key] then table.insert(available, p) end
	end
	if #available == 0 then return existingKeys, existingValues end

	local weights = Formulas.PERK_SELECTION_WEIGHTS or {}
	local function getWeight(perkDef: PerkDef)
		return weights[perkDef.Key] or 1.0
	end
	local rng = makeRng(seed)

	local newKeys: { string } = {}
	for _ = 1, math.min(need, #available) do
		local pick = weightedDraw(rng, available, getWeight)
		table.insert(newKeys, pick.Key)
		for i, it in ipairs(available) do
			if it == pick then
				table.remove(available, i)
				break
			end
		end
	end

	-- Roll values for just the new keys
	local newValues = HelperCalculator.RollPerkValuesForKeys(newKeys, newQualityId, seed)

	-- Merge
	local mergedKeys = table.clone(existingKeys)
	for _, k in ipairs(newKeys) do
		table.insert(mergedKeys, k)
	end

	local mergedValues = table.clone(existingValues)
	for k, v in pairs(newValues) do
		mergedValues[k] = v
	end

	return mergedKeys, mergedValues
end

-- Main API (BASE STATS ONLY — no RNG, no perks)

-- Returns base stats (Defaults + this jobCategory’s stats) with:
-- (base + perLevelAdd*(level-1)) × stageMult × qualityMult  for “up” stats
-- base × (1 - stageReduction(stage)) × (1 / qualityMult) with a floor for “timeDown”
function HelperCalculator.CalculateStats(jobCategory: string, level: number, qualityId: number?): (StatsTable, { string })
	local lvl = clampLevel(level)
	local stgIndex = getStageForLevel(lvl)
	local stageMult = getStageMult(stgIndex)
	local qualityMult = getQualityMult(qualityId)

	local baseDefs = Formulas.HELPER_BASE
	local addDefs = Formulas.HELPER_PER_LEVEL_ADD
	local typeMap = Formulas.HELPER_STAT_TYPES

	local defaults = (baseDefs and baseDefs.Defaults) or {}
	local catBase = (baseDefs and baseDefs.PerjobCategory and baseDefs.PerjobCategory[jobCategory]) or {}

	local defaultsAdd = (addDefs and addDefs.Defaults) or {}
	local catAdd = (addDefs and addDefs.PerjobCategory and addDefs.PerjobCategory[jobCategory]) or {}

	local stats: StatsTable = {}

	-- Defaults
	for key, baseValue in pairs(defaults) do
		local perLevel = defaultsAdd[key] or 0
		local statType = typeMap[key] or "up"
		local leveled = baseValue + perLevel * (lvl - 1)

		if statType == "up" then
			local v = leveled * stageMult * qualityMult
			stats[key] = math.floor(v + 0.5)
		else -- "timeDown"
			local stageReduction = getStageTimeReductionFraction(stgIndex)
			local combined = (1 - stageReduction) * (1 / qualityMult)
			local minFrac = Formulas.TIME_MIN_FRACTION or 0.05
			local reduced = math.max(leveled * minFrac, leveled * combined)
			stats[key] = math.floor(reduced + 0.5)
		end
	end

	-- jobCategory-only
	for key, baseValue in pairs(catBase) do
		local perLevel = (catAdd and catAdd[key]) or 0
		local statType = typeMap[key] or "up"
		local leveled = baseValue + perLevel * (lvl - 1)

		if statType == "up" then
			local v = leveled * stageMult * qualityMult
			stats[key] = math.floor(v + 0.5)
		else -- "timeDown"
			local stageReduction = getStageTimeReductionFraction(stgIndex)
			local combined = (1 - stageReduction) * (1 / qualityMult)
			local minFrac = Formulas.TIME_MIN_FRACTION or 0.05
			local reduced = math.max(leveled * minFrac, leveled * combined)
			stats[key] = math.floor(reduced + 0.5)
		end
	end

	-- No perks here; second return is the “applied” list for compatibility with old callers.
	return stats, {}
end

return HelperCalculator
