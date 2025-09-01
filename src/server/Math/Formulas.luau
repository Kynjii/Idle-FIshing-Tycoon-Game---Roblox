local FORMULAS = {
	BOAT = {
		BaseCost = 100,
		GrowthRate = 1.1,
		CostGrowthRate = 1.4,
		BaseStorage = 100,
		BaseFPS = 10,
	},
	TENDER = {
		BaseCost = 100,
		GrowthRate = 1.4,
		CostGrowthRate = 1.4,
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

return FORMULAS
