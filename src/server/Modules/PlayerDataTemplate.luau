local ServerScriptService = game:GetService("ServerScriptService")
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
return {
	CurrentRealm = 1,
	Realms = {
		[1] = {
			isUnlocked = true,
			maxBoats = 6,
			Lanes = {
				[1] = {
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
