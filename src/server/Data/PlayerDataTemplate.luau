local ServerScriptService = game:GetService("ServerScriptService")
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
return {
	Realms = {
		[1] = {
			isUnlocked = true,
			maxBoats = 6,
			Lanes = {
				[1] = {
					isPurchased = true,
					Boat = FFGDefaults.BOAT_STARTING_ATT,
				},
			},
		},
		[2] = {
			isUnlocked = false,
		},
		[3] = {
			isUnlocked = false,
		},
		[4] = {
			isUnlocked = false,
		},
	},
	Currencies = {
		Gold = 250,
	},
}
