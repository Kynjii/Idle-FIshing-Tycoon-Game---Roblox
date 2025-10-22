local HelperType = {}

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
	IsTutorialHelper: boolean?,
}

return HelperType
