local TenderType = {}

export type TenderProps = {
	Id: string,
	Owner: number,
	RealmId: number,
	Tier: number,
	Name: string,
	Level: number,
	MaxLevel: number,
	BaseCost: number,
	UpgradeCost: number,
	isPurchased: boolean,
	UpgradeStage: number,
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	FishInStorage: number,
	StorageFull: boolean,
	BaseTravelSpeed: number,
	CurrentTravelSpeed: number,
	NextLvlTravelSpeed: number,
	GrowthRate: number,
	CostGrowthRate: number,
}

export type TenderInstance = {
	-- Props
	Id: string,
	Owner: number,
	RealmId: number,
	Tier: number,
	Name: string,
	Level: number,
	MaxLevel: number,
	BaseCost: number,
	UpgradeCost: number,
	isPurchased: boolean,
	UpgradeStage: number,
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	FishInStorage: number,
	StorageFull: boolean,
	BaseTravelSpeed: number,
	CurrentTravelSpeed: number,
	NextLvlTravelSpeed: number,
	GrowthRate: number,
	CostGrowthRate: number,

	-- (Not-Saved to DataStore) Props
	Model: Model,

	-- Core Tender Actions
	Purchase: (self: TenderInstance) -> (),
	Upgrade: (self: TenderInstance) -> (),
	IncreaseUpgradeStage: (self: TenderInstance, stage: number) -> (),

	-- Calculations
	CalculateBaseCost: (self: TenderInstance) -> number,
	CalculateUpgradeCost: (self: TenderInstance) -> number,
	CalculateBaseStorage: (self: TenderInstance) -> number,
	CalculateMaxStorage: (self: TenderInstance) -> (number, number),
	CalculateBaseTravelSpeed: (self: TenderInstance) -> number,
	CalculateTravelSpeed: (self: TenderInstance) -> (number, number),

	-- Travelling
	MoveToBoat: (self: TenderInstance, position: Vector3) -> (),
	AddFish: (self: TenderInstance, amount: number) -> (),
	RemoveFish: (self: TenderInstance, amount: number) -> (),
	UpdateStorageStatus: (self: TenderInstance, status: boolean) -> (),

	-- UI Setup
	Initialize: (self: TenderInstance) -> (),
	SetupPurchaseBoard: (self: TenderInstance) -> Part,
	UpdatePurchaseBoardUI: (self: TenderInstance) -> (),
	SetupProximityPrompt: (self: TenderInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: TenderInstance, proximityPrompt: ProximityPrompt) -> (),

	-- Visibility and Collision
	Show: (self: TenderInstance) -> (),
	Hide: (self: TenderInstance) -> (),
	CanCollide: (self: TenderInstance) -> (),
	CannotCollide: (self: TenderInstance) -> (),

	-- Utilities
	GetName: (self: TenderInstance) -> string,
	CanUpgrade: (self: TenderInstance) -> boolean,
	IsStorageFull: (self: TenderInstance) -> boolean,

	-- Saving and Loading
	Serialize: (self: TenderInstance) -> { [string]: any },
}

export type Tender = {
	New: (props: TenderProps, player: Player, model: Model) -> TenderInstance,
}

return TenderType
