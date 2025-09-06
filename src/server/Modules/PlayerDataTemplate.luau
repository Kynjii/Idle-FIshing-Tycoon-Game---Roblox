export type ProfileData = {
	CurrentRealm: number,
	Realms: {
		[number]: {
			Lanes: number,
			isUnlocked: boolean,
			Boats: {},
			Tenders: {},
		},
	},
	Currencies: {
		Gold: number,
	},
}

return {
	CurrentRealm = 1,
	Realms = {
		[1] = {
			Lanes = 6,
			isUnlocked = true,
			Boats = {},
			Tenders = {},
		},
		[2] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
		},
		[3] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
		},
		[4] = {
			Lanes = 6,
			isUnlocked = false,
			Boats = {},
			Tenders = {},
		},
	},
	Currencies = {
		Gold = 250,
	},
}
