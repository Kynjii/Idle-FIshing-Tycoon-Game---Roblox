local TenderType = {}

export type TenderData = {
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
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number?,
	FishInStorage: number,
	StorageFull: boolean,
	BaseTravelTime: number,
	CurrentTravelTime: number,
	NextLvlTravelTime: number?,
	GrowthRate: number?,
	CostGrowthRate: number?,
	BaseLoadTime: number,
	Description: string,
	LoadTime: number,
	Model: Model,
	PortPos: CFrame,
	VisualRoot: any,
	BillBoard: BillboardGui?,
	Player: Player,
	MoveTween: Tween?,
	Animations: { [string]: Animation }?,
	VisualModels: { [number]: Model }?,
	CurrentVisualModel: Model?,
	Buffs: { [string]: any },
	PurchaseBoard: Model,
	PBDetails: { [string]: any }?,
	ClonedBillboard: Instance?,
	_cleaner: any?,
	ProgressTween: Tween?,
}

export type TenderInstance = {
	-- Essential Properties (accessed by other modules)
	Entity: string,
	Owner: string,
	Level: number,
	Tier: number,
	UpgradeStage: number,
	IsPurchased: boolean,
	FishInStorage: number?,
	CurrentMaxStorage: number?,
	StorageFull: boolean?,
	CurrentTravelTime: number?,
	LoadTime: number?,
	Buffs: { [string]: any }?,
	PBDetails: { [string]: any }?,

	-- Essential Methods (called by other modules)
	Initialize: (self: TenderInstance) -> (),
	Destroy: (self: TenderInstance) -> (),

	-- Allow any other properties/methods for internal use
	[string]: any,
}

export type TenderModule = {
	New: (state: { [string]: any }?, player: Player, model: Model) -> TenderInstance,
}

return TenderType
