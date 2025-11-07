local HelperType = {}

export type HelperStats = {
	Storage: number,
	WalkSpeed: number,
	LoadTime: number,
	CatchRate: number?,
	Luck: number?,
	CastTime: number?,
	WoodYield: number?,
	CritChance: number?,
	SwingRate: number?,
	OreYield: number?,
	FishValue: number?,
	FishStorage: number?,
}

export type HelperData = {
	Entity: string,
	Id: string, -- unique
	RealmId: number,
	TeamId: number,
	Owner: number?,
	Name: string, -- display
	Level: number,
	MaxLevel: number,
	CurrencyType: string,
	ItemImage: string,
	JobCategory: string,
	QualityId: number,
	Stats: HelperStats,
	UpgradeStage: number?,
	ResourceInStorage: number,
	StorageFull: boolean?,
	CurrentAssignment: number,
	IsPurchased: boolean,
	BaseCost: number?,
	UpgradeCost: number?,
	Player: Player,
	Description: string,
	ResourceType: string,
}

export type HelperInstance = {
	Entity: string,
	Id: string, -- unique
	RealmId: number,
	TeamId: number,
	Owner: number?,
	Name: string, -- display
	Level: number,
	MaxLevel: number,
	CurrencyType: string,
	ItemImage: string,
	JobCategory: string,
	QualityId: number,
	Stats: { [string]: number }?,
	UpgradeStage: number?,
	ResourceInStorage: number,
	StorageFull: boolean?,
	CurrentAssignment: number,
	IsPurchased: boolean,
	BaseCost: number?,
	UpgradeCost: number?,
	Model: Model?,
	_cleaner: any?,
	ClearStorage: () -> (),
	Upgrade: () -> (),
	Purchasehelper: (number) -> (),
	ShowGoldPopUp: (self: HelperInstance) -> (),
}

export type HelperModule = {
	New: (state: { [string]: any }?, player: Player, teamId: number) -> HelperInstance,
}

return HelperType
