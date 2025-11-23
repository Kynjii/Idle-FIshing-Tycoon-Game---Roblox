local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)

local FishCalculator = {}

-- Species drop chances by tier - higher tiers unlock rarer species
local SPECIES_DROPS_BY_TIER = {
	[1] = { -- Starter fish - easy to catch
		Guppy = { dropChance = 0.25, minTier = 1 },
		Goldfish = { dropChance = 0.22, minTier = 1 },
		Bluegill = { dropChance = 0.20, minTier = 1 },
		PaleChub = { dropChance = 0.18, minTier = 1 },
		Bitterling = { dropChance = 0.15, minTier = 1 },
	},

	[2] = { -- Common freshwater fish
		Catfish = { dropChance = 0.25, minTier = 2 },
		Bass = { dropChance = 0.22, minTier = 2 },
		BrookTrout = { dropChance = 0.20, minTier = 2 },
		SmallBass = { dropChance = 0.18, minTier = 2 },
		Loach = { dropChance = 0.15, minTier = 2 },
	},

	[3] = { -- Advanced freshwater species
		Carp = { dropChance = 0.25, minTier = 3 },
		RainbowTrout = { dropChance = 0.22, minTier = 3 },
		LargeBass = { dropChance = 0.20, minTier = 3 },
		Sweetfish = { dropChance = 0.18, minTier = 3 },
		Angelfish = { dropChance = 0.15, minTier = 3 },
	},

	[4] = { -- Challenging species
		Salmon = { dropChance = 0.25, minTier = 4 },
		Koi = { dropChance = 0.22, minTier = 4 },
		CherrySalmon = { dropChance = 0.20, minTier = 4 },
		Piranha = { dropChance = 0.18, minTier = 4 },
		Eel = { dropChance = 0.15, minTier = 4 },
	},

	[5] = { -- Rare exotic fish
		Arapaima = { dropChance = 0.25, minTier = 5 },
		GiantCatfish = { dropChance = 0.22, minTier = 5 },
		Arowana = { dropChance = 0.20, minTier = 5 },
		GiantSnakehead = { dropChance = 0.18, minTier = 5 },
		LargeChar = { dropChance = 0.15, minTier = 5 },
	},

	[6] = { -- Legendary/mythical fish
		Coelacanth = { dropChance = 0.25, minTier = 6 },
		Stringfish = { dropChance = 0.22, minTier = 6 },
		PopeyedGoldfish = { dropChance = 0.20, minTier = 6 },
		BarbelSteed = { dropChance = 0.18, minTier = 6 },
		BarredKnifejaw = { dropChance = 0.15, minTier = 6 },
	},
}

-- Variant drop chances - elemental variants are rarer, elder only in tier 6
local VARIANT_DROP_CHANCES = {
	-- Tiers 1-5: Only normal and elemental
	standard = {
		[FFGEnum.FISH_VARIANT.NORMAL] = 0.85, -- 85% chance for normal
		[FFGEnum.FISH_VARIANT.ELEMENTAL] = 0.15, -- 15% chance for elemental
	},
	-- Tier 6: Includes elder variant
	tier6 = {
		[FFGEnum.FISH_VARIANT.NORMAL] = 0.74, -- 74% chance for normal
		[FFGEnum.FISH_VARIANT.ELEMENTAL] = 0.25, -- 25% chance for elemental
		[FFGEnum.FISH_VARIANT.ELDER] = 0.01, -- 1% chance for elder
	},
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
	local baseMaxHP = 100 * qualityId
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

function FishCalculator.ChooseSpecie(fishingLocTier: number?, realmId: number): { Species: string, SpeciesKey: string, Variant: string, ItemImage: string, Name: string, NameKey: string }
	local tier = math.clamp(fishingLocTier or 1, 1, 6)
	local availableSpecies = SPECIES_DROPS_BY_TIER[tier]

	if not availableSpecies then availableSpecies = SPECIES_DROPS_BY_TIER[1] end

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

	local variantRoll = math.random()
	local chosenVariant = FFGEnum.FISH_VARIANT.NORMAL

	local dropTable = (tier == 6) and VARIANT_DROP_CHANCES.tier6 or VARIANT_DROP_CHANCES.standard

	local cumulativeChance = 0
	for variant, chance in pairs(dropTable) do
		cumulativeChance += chance
		if variantRoll <= cumulativeChance then
			chosenVariant = variant
			break
		end
	end

	-- Special check: Elder variants only for truly exclusive tier 6 species
	if chosenVariant == FFGEnum.FISH_VARIANT.ELDER then
		local tier6ExclusiveSpecies = {
			Coelacanth = true,
			Stringfish = true,
			PopeyedGoldfish = true,
			BarbelSteed = true,
			BarredKnifejaw = true,
		}

		if not tier6ExclusiveSpecies[chosenSpeciesKey] then
			-- Reroll to normal or elemental for non-exclusive species
			chosenVariant = (math.random() < 0.75) and FFGEnum.FISH_VARIANT.NORMAL or FFGEnum.FISH_VARIANT.ELEMENTAL
		end
	end

	local speciesName = FishData.FISH_SPECIES[chosenSpeciesKey] or chosenSpeciesKey
	local itemImage = FishData.FISH_ASSETS[chosenSpeciesKey].Basic or FishData.FISH_ASSETS.Guppy.Basic
	local itemImageMasked = FishData.FISH_ASSETS_MASKED[chosenSpeciesKey] or FishData.FISH_ASSETS_MASKED[chosenSpeciesKey].Guppy
	local name, nameKey = FishCalculator.GetFishName(speciesName, chosenSpeciesKey, chosenVariant, realmId)

	return {
		Species = speciesName,
		SpeciesKey = chosenSpeciesKey,
		Variant = chosenVariant,
		ItemImage = itemImage,
		itemImageMasked = itemImageMasked,
		Name = name,
		NameKey = nameKey,
	}
end

function FishCalculator.ChooseQuality(fishingLocTier: number?): number?
	return chooseQuality(fishingLocTier)
end

function FishCalculator.GetFishAsset(speciesKey: string): string?
	return FishData.FISH_ASSETS[speciesKey]
end

function FishCalculator.GetAllFishVariations(realmId: number): { { Species: string, Variant: string, ItemImage: string, SpeciesKey: string, Caught: boolean, Name: string, NameKey: string } }
	local variations = {}

	-- Only the 5 truly exclusive tier 6 species get elder variants
	local tier6ExclusiveSpecies = {
		Coelacanth = true,
		Stringfish = true,
		PopeyedGoldfish = true,
		BarbelSteed = true,
		BarredKnifejaw = true,
	}

	for speciesKey, speciesName in pairs(FishData.FISH_SPECIES) do
		local itemImage = FishData.FISH_ASSETS[speciesKey].Basic or FishData.FISH_ASSETS.Guppy.Basic
		local itemImageMasked = FishData.FISH_ASSETS_MASKED[speciesKey] or FishData.FISH_ASSETS_MASKED.Guppy

		-- Add normal variant (all species)
		local normalName, normalNameKey = FishCalculator.GetFishName(speciesName, speciesKey, FFGEnum.FISH_VARIANT.NORMAL, realmId)
		table.insert(variations, {
			Entity = FFGEnum.CLASS.ENTITY_NAME.Fish,
			Species = speciesName,
			Variant = FFGEnum.FISH_VARIANT.NORMAL,
			ItemImage = itemImage,
			ItemImageMasked = itemImageMasked,
			SpeciesKey = speciesKey,
			Name = normalName,
			NameKey = normalNameKey,
			Caught = false,
		})

		-- Add elemental variant (all species)

		local elementalName, elementalNameKey = FishCalculator.GetFishName(speciesName, speciesKey, FFGEnum.FISH_VARIANT.ELEMENTAL, realmId)
		table.insert(variations, {
			Entity = FFGEnum.CLASS.ENTITY_NAME.Fish,
			Species = speciesName,
			Variant = FFGEnum.FISH_VARIANT.ELEMENTAL,
			ItemImage = itemImage,
			ItemImageMasked = itemImageMasked,
			SpeciesKey = speciesKey,
			Name = elementalName,
			NameKey = elementalNameKey,
			ElementName = FFGEnum.REALM_ELEMENTS[realmId],
			ElementNum = realmId,
			Caught = false,
		})

		-- Add elder variant (only truly exclusive tier 6 species)
		local elderName, elderNameKey = FishCalculator.GetFishName(speciesName, speciesKey, FFGEnum.FISH_VARIANT.ELDER, realmId)
		if tier6ExclusiveSpecies[speciesKey] then
			table.insert(variations, {
				Entity = FFGEnum.CLASS.ENTITY_NAME.Fish,
				Species = speciesName,
				Variant = FFGEnum.FISH_VARIANT.ELDER,
				ItemImage = itemImage,
				ItemImageMasked = itemImageMasked,
				SpeciesKey = speciesKey,
				Name = elderName,
				NameKey = elderNameKey,
				Caught = false,
			})
		end
	end

	return variations
end

function FishCalculator.GetFishName(species: string, speciesKey: string, variant: string, realmId: number): string
	local baseName = species
	local baseNameKey = speciesKey

	if variant == FFGEnum.FISH_VARIANT.ELEMENTAL then
		local element = FFGEnum.REALM_ELEMENTS[realmId] or "Unknown"
		return `{element} {baseName}`, `{element}{baseName}`
	elseif variant == FFGEnum.FISH_VARIANT.ELDER then
		return `Elder {baseName}`, `Elder{baseName}`
	else
		return baseName, baseNameKey
	end
end

return FishCalculator
