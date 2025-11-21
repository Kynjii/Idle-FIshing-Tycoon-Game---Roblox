local MAX_FISHING_LEVEL = 100

-- Tunable curve parameters
local BASE_XP = 30 -- minimum XP per level
local SCALE_XP = 20 -- growth factor
local GROWTH_XP = 1.25 -- exponent: controls how steep it gets late-game

local FishingXP = {}

-- Cumulative XP required to reach each level (1..MAX_FISHING_LEVEL)
-- Level 1 = 0 XP (starting level)
local CUMULATIVE_XP = {}

-- XP needed to go from level N -> N+1
local function GetDeltaXPForLevel(level: number): number
	if level <= 0 then return 0 end

	local xp = BASE_XP + SCALE_XP * (level ^ GROWTH_XP)
	return math.floor(xp + 0.5) -- round to nearest
end

do
	local total = 0
	for level = 1, MAX_FISHING_LEVEL do
		CUMULATIVE_XP[level] = total
		total += GetDeltaXPForLevel(level)
	end
end

-- PUBLIC API --------------------------------------------

function FishingXP.GetMaxLevel(): number
	return MAX_FISHING_LEVEL
end

-- Total XP required to reach 'level'
function FishingXP.GetTotalForLevel(level: number): number
	if level <= 1 then return 0 end
	if level > MAX_FISHING_LEVEL then return CUMULATIVE_XP[MAX_FISHING_LEVEL] end
	return CUMULATIVE_XP[level]
end

-- XP needed to go from currentLevel -> next level
function FishingXP.GetXPToNextLevel(currentLevel: number, currentXP: number): number
	if currentLevel >= MAX_FISHING_LEVEL then return 0 end

	local nextLevel = currentLevel + 1
	local requiredTotal = FishingXP.GetTotalForLevel(nextLevel)
	local missing = requiredTotal - currentXP

	return math.max(missing, 0)
end

-- Add XP and compute new level + XP (no data store inside!)
function FishingXP.AddXP(currentLevel: number, currentXP: number, xpGained: number)
	local level = currentLevel
	local xp = currentXP + xpGained

	while level < MAX_FISHING_LEVEL do
		local nextLevel = level + 1
		local requiredTotal = FishingXP.GetTotalForLevel(nextLevel)

		if xp >= requiredTotal then
			level = nextLevel
		else
			break
		end
	end

	return level, xp
end

return FishingXP
