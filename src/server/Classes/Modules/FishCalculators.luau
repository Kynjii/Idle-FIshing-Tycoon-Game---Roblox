local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local FishCalculator = {}

local FISH_SPECIES = {
	Angelfish = "Angelfish",
	Arapaima = "Arapaima",
	Arowana = "Arowana",
	BarbelSteed = "Barbel Steed",
	BarredKnifejaw = "Barred Knifejaw",
	Bass = "Bass",
	Bitterling = "Bitterling",
	Bluegill = "Bluegill",
	BrookTrout = "Brook Trout",
	Carp = "Carp",
	Catfish = "Catfish",
	CherrySalmon = "Cherry Salmon",
	Coelacanth = "Coelacanth",
	Crawfish = "Crawfish",
	CrucianCarp = "Crucian Carp",
	Dace = "Dace",
	Eel = "Eel",
	FreshwaterGoby = "Freshwater Goby",
	Frog = "Frog",
	GiantCatfish = "Giant Catfish",
	GiantSnakehead = "Giant Snakehead",
	Goldfish = "Goldfish",
	Guppy = "Guppy",
	Jellyfish = "Jellyfish",
	Killifish = "Killifish",
	Koi = "Koi",
	LargeBass = "Large Bass",
	LargeChar = "Large Char",
	Loach = "Loach",
	PaleChub = "Pale Chub",
	Piranha = "Piranha",
	PondSmelt = "Pond Smelt",
	PopeyedGoldfish = "Popeyed Goldfish",
	RainbowTrout = "Rainbow Trout",
	RedSnapper = "Red Snapper",
	Salmon = "Salmon",
	SeaBass = "Sea Bass",
	SmallBass = "Small Bass",
	Stringfish = "Stringfish",
	Sweetfish = "Sweetfish",
}

local FISH_VARIANT = {
	NORMAL = "normal",
	ELEMENTAL = "elemental",
}

local FISH_ASSETS = {
	Angelfish = "rbxassetid://86530930916913",
	Arapaima = "rbxassetid://111671767238179",
	Arowana = "rbxassetid://108983393931009",
	BarbelSteed = "rbxassetid://102595507548669",
	BarredKnifejaw = "rbxassetid://72962993740810",
	Bass = "rbxassetid://90246099507682",
	Bitterling = "rbxassetid://134033945265675",
	Bluegill = "rbxassetid://82079624957321",
	BrookTrout = "rbxassetid://98287941099017",
	Carp = "rbxassetid://111160034327339",
	Catfish = "rbxassetid://120608521661152",
	CherrySalmon = "rbxassetid://86655108971369",
	Coelacanth = "rbxassetid://86888174125652",
	Crawfish = "rbxassetid://93301919634243",
	CrucianCarp = "rbxassetid://124081328496276",
	Dace = "rbxassetid://72442566434341",
	Eel = "rbxassetid://137912964469805",
	FreshwaterGoby = "rbxassetid://73075716714952",
	Frog = "rbxassetid://75076556447926",
	GiantCatfish = "rbxassetid://97608705235157",
	GiantSnakehead = "rbxassetid://108521102102921",
	Goldfish = "rbxassetid://116344850086061",
	Guppy = "rbxassetid://119927746171786",
	Jellyfish = "rbxassetid://137210949493537",
	Killifish = "rbxassetid://88472643540035",
	Koi = "rbxassetid://125780772181467",
	LargeBass = "rbxassetid://136571700180366",
	LargeChar = "rbxassetid://72112552667255",
	Loach = "rbxassetid://94282466239890",
	PaleChub = "rbxassetid://77005738686041",
	Piranha = "rbxassetid://91401134170565",
	PondSmelt = "rbxassetid://131664189781217",
	PopeyedGoldfish = "rbxassetid://71269017919182",
	RainbowTrout = "rbxassetid://106767459214394",
	RedSnapper = "rbxassetid://111244267622882",
	Salmon = "rbxassetid://139440277462943",
	SeaBass = "rbxassetid://86637772733086",
	SmallBass = "rbxassetid://112751745497790",
	Stringfish = "rbxassetid://132952116869650",
	Sweetfish = "rbxassetid://113656155322041",
}

-- Species drop chances by tier - higher tiers unlock rarer species
local SPECIES_DROPS_BY_TIER = {
	[1] = { -- Basic tier
		Guppy = { dropChance = 0.20, minTier = 1 },
		Goldfish = { dropChance = 0.18, minTier = 1 },
		Catfish = { dropChance = 0.15, minTier = 1 },
		Bass = { dropChance = 0.12, minTier = 1 },
		Bluegill = { dropChance = 0.12, minTier = 1 },
		Carp = { dropChance = 0.10, minTier = 1 },
		Bitterling = { dropChance = 0.08, minTier = 1 },
		PaleChub = { dropChance = 0.05, minTier = 1 },
	},
	[2] = { -- Includes tier 1 + new species
		Guppy = { dropChance = 0.15, minTier = 1 },
		Goldfish = { dropChance = 0.14, minTier = 1 },
		Catfish = { dropChance = 0.12, minTier = 1 },
		Bass = { dropChance = 0.10, minTier = 1 },
		Bluegill = { dropChance = 0.10, minTier = 1 },
		Carp = { dropChance = 0.08, minTier = 1 },
		Bitterling = { dropChance = 0.06, minTier = 1 },
		PaleChub = { dropChance = 0.04, minTier = 1 },
		BrookTrout = { dropChance = 0.08, minTier = 2 },
		SmallBass = { dropChance = 0.07, minTier = 2 },
		Loach = { dropChance = 0.06, minTier = 2 },
	},
	[3] = { -- Includes previous tiers + new species
		Guppy = { dropChance = 0.10, minTier = 1 },
		Goldfish = { dropChance = 0.09, minTier = 1 },
		Catfish = { dropChance = 0.08, minTier = 1 },
		Bass = { dropChance = 0.08, minTier = 1 },
		Bluegill = { dropChance = 0.08, minTier = 1 },
		Carp = { dropChance = 0.06, minTier = 1 },
		Bitterling = { dropChance = 0.05, minTier = 1 },
		PaleChub = { dropChance = 0.03, minTier = 1 },
		BrookTrout = { dropChance = 0.07, minTier = 2 },
		SmallBass = { dropChance = 0.06, minTier = 2 },
		Loach = { dropChance = 0.05, minTier = 2 },
		RainbowTrout = { dropChance = 0.08, minTier = 3 },
		LargeBass = { dropChance = 0.07, minTier = 3 },
		Sweetfish = { dropChance = 0.06, minTier = 3 },
		Angelfish = { dropChance = 0.04, minTier = 3 },
	},
	[4] = { -- Includes previous tiers + new species
		Guppy = { dropChance = 0.08, minTier = 1 },
		Goldfish = { dropChance = 0.07, minTier = 1 },
		Catfish = { dropChance = 0.06, minTier = 1 },
		Bass = { dropChance = 0.06, minTier = 1 },
		Bluegill = { dropChance = 0.06, minTier = 1 },
		Carp = { dropChance = 0.05, minTier = 1 },
		Bitterling = { dropChance = 0.04, minTier = 1 },
		PaleChub = { dropChance = 0.02, minTier = 1 },
		BrookTrout = { dropChance = 0.06, minTier = 2 },
		SmallBass = { dropChance = 0.05, minTier = 2 },
		Loach = { dropChance = 0.04, minTier = 2 },
		RainbowTrout = { dropChance = 0.07, minTier = 3 },
		LargeBass = { dropChance = 0.06, minTier = 3 },
		Sweetfish = { dropChance = 0.05, minTier = 3 },
		Angelfish = { dropChance = 0.03, minTier = 3 },
		Salmon = { dropChance = 0.08, minTier = 4 },
		Koi = { dropChance = 0.06, minTier = 4 },
		CherrySalmon = { dropChance = 0.05, minTier = 4 },
		Piranha = { dropChance = 0.04, minTier = 4 },
		Eel = { dropChance = 0.03, minTier = 4 },
	},
	[5] = { -- Includes previous tiers + new species
		Guppy = { dropChance = 0.06, minTier = 1 },
		Goldfish = { dropChance = 0.05, minTier = 1 },
		Catfish = { dropChance = 0.05, minTier = 1 },
		Bass = { dropChance = 0.05, minTier = 1 },
		Bluegill = { dropChance = 0.05, minTier = 1 },
		Carp = { dropChance = 0.04, minTier = 1 },
		Bitterling = { dropChance = 0.03, minTier = 1 },
		PaleChub = { dropChance = 0.02, minTier = 1 },
		BrookTrout = { dropChance = 0.05, minTier = 2 },
		SmallBass = { dropChance = 0.04, minTier = 2 },
		Loach = { dropChance = 0.03, minTier = 2 },
		RainbowTrout = { dropChance = 0.06, minTier = 3 },
		LargeBass = { dropChance = 0.05, minTier = 3 },
		Sweetfish = { dropChance = 0.04, minTier = 3 },
		Angelfish = { dropChance = 0.03, minTier = 3 },
		Salmon = { dropChance = 0.07, minTier = 4 },
		Koi = { dropChance = 0.05, minTier = 4 },
		CherrySalmon = { dropChance = 0.04, minTier = 4 },
		Piranha = { dropChance = 0.03, minTier = 4 },
		Eel = { dropChance = 0.03, minTier = 4 },
		Arapaima = { dropChance = 0.06, minTier = 5 },
		GiantCatfish = { dropChance = 0.05, minTier = 5 },
		Arowana = { dropChance = 0.04, minTier = 5 },
		GiantSnakehead = { dropChance = 0.03, minTier = 5 },
		LargeChar = { dropChance = 0.03, minTier = 5 },
	},
	[6] = { -- Legendary tier - includes all previous + ultra rare
		Guppy = { dropChance = 0.04, minTier = 1 },
		Goldfish = { dropChance = 0.04, minTier = 1 },
		Catfish = { dropChance = 0.04, minTier = 1 },
		Bass = { dropChance = 0.04, minTier = 1 },
		Bluegill = { dropChance = 0.04, minTier = 1 },
		Carp = { dropChance = 0.03, minTier = 1 },
		Bitterling = { dropChance = 0.03, minTier = 1 },
		PaleChub = { dropChance = 0.02, minTier = 1 },
		BrookTrout = { dropChance = 0.04, minTier = 2 },
		SmallBass = { dropChance = 0.03, minTier = 2 },
		Loach = { dropChance = 0.03, minTier = 2 },
		RainbowTrout = { dropChance = 0.05, minTier = 3 },
		LargeBass = { dropChance = 0.04, minTier = 3 },
		Sweetfish = { dropChance = 0.03, minTier = 3 },
		Angelfish = { dropChance = 0.03, minTier = 3 },
		Salmon = { dropChance = 0.06, minTier = 4 },
		Koi = { dropChance = 0.04, minTier = 4 },
		CherrySalmon = { dropChance = 0.03, minTier = 4 },
		Piranha = { dropChance = 0.03, minTier = 4 },
		Eel = { dropChance = 0.03, minTier = 4 },
		Arapaima = { dropChance = 0.05, minTier = 5 },
		GiantCatfish = { dropChance = 0.04, minTier = 5 },
		Arowana = { dropChance = 0.03, minTier = 5 },
		GiantSnakehead = { dropChance = 0.03, minTier = 5 },
		LargeChar = { dropChance = 0.03, minTier = 5 },
		Coelacanth = { dropChance = 0.04, minTier = 6 },
		Stringfish = { dropChance = 0.03, minTier = 6 },
		PopeyedGoldfish = { dropChance = 0.025, minTier = 6 },
		BarbelSteed = { dropChance = 0.02, minTier = 6 },
		BarredKnifejaw = { dropChance = 0.015, minTier = 6 },
	},
}

-- Variant drop chances - elemental variants are rarer
local VARIANT_DROP_CHANCES = {
	[FISH_VARIANT.NORMAL] = 0.85, -- 85% chance for normal
	[FISH_VARIANT.ELEMENTAL] = 0.15, -- 15% chance for elemental
}

-- Quality drops by fishing location tier
local TIER_QUALITY_DROPS = {
	[1] = {
		[1] = 0.75,
		[2] = 0.25,
		[3] = 0.00,
		[4] = 0.00,
		[5] = 0.00,
		[6] = 0.00,
	},
	[2] = {
		[1] = 0.65,
		[2] = 0.25,
		[3] = 0.10,
		[4] = 0.00,
		[5] = 0.00,
		[6] = 0.00,
	},
	[3] = {
		[1] = 0.58,
		[2] = 0.25,
		[3] = 0.13,
		[4] = 0.04,
		[5] = 0.00,
		[6] = 0.00,
	},
	[4] = {
		[1] = 0.55,
		[2] = 0.25,
		[3] = 0.14,
		[4] = 0.05,
		[5] = 0.01,
		[6] = 0.00,
	},
	[5] = {
		[1] = 0.50,
		[2] = 0.26,
		[3] = 0.16,
		[4] = 0.06,
		[5] = 0.015,
		[6] = 0.005,
	},
	[6] = {
		[1] = 0.45,
		[2] = 0.27,
		[3] = 0.18,
		[4] = 0.07,
		[5] = 0.025,
		[6] = 0.005,
	},
}

local function chooseQuality(fishingLocTier: number?): number?
	local tier = math.clamp(fishingLocTier or 1, 1, 6)

	local function getRandomQuality(): number?
		local tierDrops = TIER_QUALITY_DROPS[tier]
		if not tierDrops then
			local totalWeight: number = 0
			for _, data in pairs(FFGEnum.QUALITIES) do
				totalWeight += data.DropChance
			end

			local randomValue: number = math.random() * totalWeight
			local cumulative: number = 0

			for qualityId, data in pairs(FFGEnum.QUALITIES) do
				cumulative += data.DropChance
				if randomValue <= cumulative then return qualityId end
			end
			return 1
		end

		-- Use tier-specific drop chances
		local totalWeight: number = 0
		for _, dropChance in pairs(tierDrops) do
			totalWeight += dropChance
		end

		local randomValue: number = math.random() * totalWeight
		local cumulative: number = 0

		for qualityId, dropChance in pairs(tierDrops) do
			cumulative += dropChance
			if randomValue <= cumulative then return qualityId end
		end

		return 1
	end

	local qualityId: number? = getRandomQuality()
	return qualityId
end

-- //SECTION -  Utility: clamps & lookups
local function addDeviance(value, range)
	local randomFactor = 1 + (math.random() - 0.5) * 2 * range
	return value * randomFactor
end

local function getQualityMult(qualityId: number?): number
	if not qualityId then return 1 end
	return (Formulas.QUALITY_MULT and Formulas.QUALITY_MULT[qualityId]) or 1
end
-- //!SECTION

function FishCalculator.GenerateStats(qualityId: number): (number, number)
	local qualityMult = getQualityMult(qualityId)

	-- Base values for fish stats
	local baseMaxHP = 100
	local baseWeight = 1.0

	-- Apply quality multiplier
	local maxHP = baseMaxHP * qualityMult
	local weight = baseWeight * qualityMult

	-- Add variance to make each fish unique (±10% variance)
	maxHP = addDeviance(maxHP, 0.10)
	weight = addDeviance(weight, 0.10)

	-- Round/clamp to reasonable values
	maxHP = math.max(1, math.floor(maxHP + 0.5))
	weight = math.max(0.1, math.floor(weight * 100 + 0.5) / 100) -- Round to 2 decimal places

	return maxHP, weight
end

function FishCalculator.ChooseSpecie(fishingLocTier: number?): { Species: string, Variant: string, ItemImage: string }
	local tier = math.clamp(fishingLocTier or 1, 1, 6)
	local availableSpecies = SPECIES_DROPS_BY_TIER[tier]

	if not availableSpecies then
		-- Fallback to basic tier if tier not found
		availableSpecies = SPECIES_DROPS_BY_TIER[1]
	end

	-- Calculate total weight for species drops
	local totalWeight = 0
	for _, data in pairs(availableSpecies) do
		totalWeight += data.dropChance
	end

	-- Select species based on weighted random
	local randomValue = math.random() * totalWeight
	local cumulative = 0
	local chosenSpeciesKey = "Guppy" -- fallback

	for speciesKey, data in pairs(availableSpecies) do
		cumulative += data.dropChance
		if randomValue <= cumulative then
			chosenSpeciesKey = speciesKey
			break
		end
	end

	-- Determine variant (normal vs elemental)
	local variantRoll = math.random()
	local chosenVariant = FISH_VARIANT.NORMAL

	if variantRoll <= VARIANT_DROP_CHANCES[FISH_VARIANT.ELEMENTAL] then chosenVariant = FISH_VARIANT.ELEMENTAL end

	-- Get the display name and asset from mappings
	local speciesName = FISH_SPECIES[chosenSpeciesKey] or chosenSpeciesKey
	local itemImage = FISH_ASSETS[chosenSpeciesKey] or FISH_ASSETS.Guppy -- fallback to Guppy asset

	return {
		Species = speciesName,
		Variant = chosenVariant,
		ItemImage = itemImage,
	}
end

function FishCalculator.ChooseQuality(fishingLocTier: number?): number?
	return chooseQuality(fishingLocTier)
end

function FishCalculator.GetFishAsset(speciesKey: string): string?
	return FISH_ASSETS[speciesKey]
end

return FishCalculator
