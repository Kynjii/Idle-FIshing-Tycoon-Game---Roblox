local BoatType = {}

export type BoatData = {
	Entity: string,
	Id: string,
	TeamId: number,
	Owner: number,
	RealmId: number,
	Tier: number,
	Name: string,
	Level: number,
	MaxLevel: number,
	BaseCost: number,
	UpgradeCost: number,
	IsPurchased: boolean,
	UpgradeStage: number,
	Description: string,
	Model: Model,
	Player: Player,
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	FishInStorage: number,
	StorageFull: boolean,
	BaseFPS: number,
	CurrentFPS: number,
	NextFPS: number,
	GrowthRate: number?,
	CostGrowthRate: number?,
	VisualRoot: Part,
	FishingInterval: any?,
	Animations: { [string]: any }?,
	VisualModels: { [number]: Model }?,
	CurrentVisualModel: Model?,
	PurchaseButton: Model,
	Nameplate: BillboardGui?,
	ClonedBillboard: Instance?,
	_cleaner: any,
	Buffs: { [string]: any },
}

export type BoatInstance = {
	-- Essential Properties (accessed by other modules)
	Entity: string,
	Owner: string,
	Level: number,
	Tier: number,
	UpgradeStage: number,
	IsPurchased: boolean,
	FishInStorage: number?,
	CurrentMaxStorage: number?,
	CurrentFPS: number,
	StorageFull: boolean,
	Buffs: { [string]: any }?,
	Nameplate: BillboardGui?,

	-- Essential Methods (called by other modules)
	Initialize: (self: BoatInstance) -> (),
	Destroy: (self: BoatInstance) -> (),

	-- Allow any other properties/methods for internal use
	[string]: any,
} & BoatData

export type BoatModule = {
	New: (state: { [string]: any }?, player: Player, model: Model) -> BoatInstance,
}

return BoatType
