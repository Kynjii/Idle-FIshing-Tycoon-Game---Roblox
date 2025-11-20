local FishingRods = {
	-- QUALITY 1 (Starter/Budget)
	{
		Name = "Bamboo Rod",
		QualityId = 1,
		BaseDmg = 5,
		Cost = 100,
		LevelRequirement = 1,
		Stats = {
			ReelPower = 1,
			LineControl = 2,
			Stability = 1,
		},
		Description = "A simple rod for beginners. Light and forgiving, but weak.",
	},

	{
		Name = "Apprentice Rod",
		QualityId = 1,
		BaseDmg = 8,
		Cost = 300,
		LevelRequirement = 3,
		Stats = {
			ReelPower = 2,
			LineControl = 1,
			Stability = 2,
		},
		Description = "A basic wooden rod with a bit more pull for novice anglers.",
	},

	{
		Name = "River Reed Rod",
		QualityId = 1,
		BaseDmg = 7,
		Cost = 450,
		LevelRequirement = 4,
		Stats = {
			ReelPower = 1,
			LineControl = 3,
			Stability = 1,
		},
		Description = "Favoured by calm fishers. Easier timing, low strength.",
	},

	{
		Name = "Worn Guild Rod",
		QualityId = 1,
		BaseDmg = 9,
		Cost = 550,
		LevelRequirement = 5,
		Stats = {
			ReelPower = 2,
			LineControl = 2,
			Stability = 1,
		},
		Description = "An old guild rod. Balanced but unimpressive.",
	},

	-- QUALITY 2 (Early Progression)
	{
		Name = "Steel Line Rod",
		QualityId = 2,
		BaseDmg = 12,
		Cost = 800,
		LevelRequirement = 6,
		Stats = {
			ReelPower = 2,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Steel line offers better control for modestly stronger fish.",
	},

	{
		Name = "Steady Fisher",
		QualityId = 2,
		BaseDmg = 10,
		Cost = 950,
		LevelRequirement = 7,
		Stats = {
			ReelPower = 1,
			LineControl = 2,
			Stability = 4,
		},
		Description = "Built for patience. The fish fights back slowly between hits.",
	},

	{
		Name = "Iron Hook Rod",
		QualityId = 2,
		BaseDmg = 13,
		Cost = 1200,
		LevelRequirement = 8,
		Stats = {
			ReelPower = 3,
			LineControl = 2,
			Stability = 2,
		},
		Description = "Extra bite at the hook. Stronger pulls but less forgiving.",
	},

	{
		Name = "Pond Whisper",
		QualityId = 2,
		BaseDmg = 11,
		Cost = 1350,
		LevelRequirement = 9,
		Stats = {
			ReelPower = 2,
			LineControl = 3,
			Stability = 3,
		},
		Description = "A gentle rod that feels the water’s flow, easing timing a bit.",
	},

	-- QUALITY 3 (Mid-game, Specialized)
	{
		Name = "Power Reeler",
		QualityId = 3,
		BaseDmg = 18,
		Cost = 2000,
		LevelRequirement = 12,
		Stats = {
			ReelPower = 5,
			LineControl = 2,
			Stability = 1,
		},
		Description = "Built for raw power. Great hits, but fights are wild and draining.",
	},

	{
		Name = "Precision Caster",
		QualityId = 3,
		BaseDmg = 16,
		Cost = 2300,
		LevelRequirement = 14,
		Stats = {
			ReelPower = 2,
			LineControl = 5,
			Stability = 3,
		},
		Description = "Engineered for accuracy. Big hit window for careful players.",
	},

	{
		Name = "Journeyman’s Balance",
		QualityId = 3,
		BaseDmg = 17,
		Cost = 2500,
		LevelRequirement = 15,
		Stats = {
			ReelPower = 3,
			LineControl = 3,
			Stability = 3,
		},
		Description = "A balanced rod for fishers exploring deeper waters.",
	},

	{
		Name = "Tide Breaker",
		QualityId = 3,
		BaseDmg = 19,
		Cost = 2800,
		LevelRequirement = 17,
		Stats = {
			ReelPower = 4,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Stronger pulls for mid-tier fish, at the cost of some control.",
	},

	-- QUALITY 4 (Advanced)
	{
		Name = "Balanced Master",
		QualityId = 4,
		BaseDmg = 22,
		Cost = 4000,
		LevelRequirement = 20,
		Stats = {
			ReelPower = 4,
			LineControl = 4,
			Stability = 4,
		},
		Description = "The classic choice of seasoned anglers. Strong and dependable.",
	},

	{
		Name = "Titan's Grip",
		QualityId = 4,
		BaseDmg = 25,
		Cost = 5000,
		LevelRequirement = 24,
		Stats = {
			ReelPower = 6,
			LineControl = 3,
			Stability = 2,
		},
		Description = "Brutal strength. Devastates fish stamina if you can handle it.",
	},

	{
		Name = "Moonlit Thread Rod",
		QualityId = 4,
		BaseDmg = 23,
		Cost = 5200,
		LevelRequirement = 26,
		Stats = {
			ReelPower = 3,
			LineControl = 5,
			Stability = 4,
		},
		Description = "Shines under pressure. Great for tricky timing challenges.",
	},

	{
		Name = "Anchorheart Rod",
		QualityId = 4,
		BaseDmg = 21,
		Cost = 4500,
		LevelRequirement = 22,
		Stats = {
			ReelPower = 3,
			LineControl = 3,
			Stability = 6,
		},
		Description = "Unshakable stability. Fish struggle to drain your progress.",
	},

	-- QUALITY 5 (Near-Legendary)
	{
		Name = "Whispering Current",
		QualityId = 5,
		BaseDmg = 28,
		Cost = 8000,
		LevelRequirement = 32,
		Stats = {
			ReelPower = 3,
			LineControl = 6,
			Stability = 5,
		},
		Description = "Flows with the water’s rhythm. Huge hit window and high stability.",
	},

	{
		Name = "Stormcaller Rod",
		QualityId = 5,
		BaseDmg = 30,
		Cost = 9000,
		LevelRequirement = 35,
		Stats = {
			ReelPower = 6,
			LineControl = 4,
			Stability = 4,
		},
		Description = "Harnesses violent surges. Tremendous power with decent control.",
	},

	{
		Name = "Deepsea Warden",
		QualityId = 5,
		BaseDmg = 29,
		Cost = 9500,
		LevelRequirement = 38,
		Stats = {
			ReelPower = 4,
			LineControl = 4,
			Stability = 6,
		},
		Description = "Forged for abyssal beasts. High stability keeps fights controlled.",
	},

	-- QUALITY 6 (End-Game)
	{
		Name = "Angler's Perfection",
		QualityId = 6,
		BaseDmg = 35,
		Cost = 15000,
		LevelRequirement = 45,
		Stats = {
			ReelPower = 6,
			LineControl = 5,
			Stability = 6,
		},
		Description = "A near-perfect rod. Even monsters of the deep feel manageable.",
	},

	{
		Name = "Celestial Tide Scepter",
		QualityId = 6,
		BaseDmg = 36,
		Cost = 17000,
		LevelRequirement = 50,
		Stats = {
			ReelPower = 5,
			LineControl = 6,
			Stability = 6,
		},
		Description = "Mastery of flow and stillness. Ultimate control and endurance.",
	},
}

return FishingRods
