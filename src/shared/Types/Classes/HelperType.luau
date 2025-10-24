local HelperType = {}

export type HelperStats = {
	Storage: number?,
	WalkSpeed: number?,
}

export type HelperData = {
	Entity: string,
	Id: string, -- unique
	RealmId: number,
	Owner: number?,
	Name: string, -- display
	Level: number,
	CurrencyType: string,
	ItemImage: string,
	JobCategory: number,
	QualityId: number,
	Stats: HelperStats,
	UpgradeStage: number?,
	ResourceInStorage: number,
	StorageFull: boolean?,
	CurrentAssignment: number,
	IsPurchased: boolean,
	BaseCost: number?,
	UpgradeCost: number?,
	Model: Model?,
	_cleaner: any?,
	Player: Player,
	Description: string,
}

export type HelperInstance = {
	Entity: string,
	Id: string, -- unique
	RealmId: number,
	Owner: number?,
	Name: string, -- display
	Level: number,
	CurrencyType: string,
	ItemImage: string,
	JobCategory: number,
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
}

export type HelperModule = {
	New: (state: { [string]: any }?, player: Player, teamId: number) -> HelperInstance,
}

return HelperType
