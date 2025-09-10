local BoatType = {}

export type BoatProps = {
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
	BaseFPS: number,
	CurrentFPS: number,
	NextFPS: number,
	GrowthRate: number,
	CostGrowthRate: number,
}

export type BoatInstance = {
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
	BaseStorage: number,
	UpgradeStage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	FishInStorage: number,
	StorageFull: boolean,
	BaseFPS: number,
	CurrentFPS: number,
	NextFPS: number,
	GrowthRate: number,
	CostGrowthRate: number,

	-- (Not-Saved to DataStore) Props
	Model: Model,
	FishingInterval: thread,
	Player: Player,

	-- Core Boat Actions
	Purchase: (self: BoatInstance) -> (),
	Upgrade: (self: BoatInstance) -> (),
	IncreaseUpgradeStage: (self: BoatInstance, stage: number) -> (),

	-- Calculations
	CalculateBaseCost: (self: BoatInstance) -> number,
	CalculateUpgradeCost: (self: BoatInstance) -> number,
	CalculateBaseStorage: (self: BoatInstance) -> number,
	CalculateMaxStorage: (self: BoatInstance) -> (number, number),
	CalculateBaseFPS: (self: BoatInstance) -> number,
	CalculateFPS: (self: BoatInstance) -> (number, number),

	-- Fishing
	StartFishing: (self: BoatInstance) -> (),
	AddFish: (self: BoatInstance, amount: number) -> (),
	RemoveFish: (self: BoatInstance, amount: number) -> (),
	UpdateStorageStatus: (self: BoatInstance, status: boolean) -> (),

	-- UI Setup
	Initialize: (self: BoatInstance) -> (),
	SetupPurchaseBoard: (self: BoatInstance) -> Part,
	UpdatePurchaseBoardUI: (self: BoatInstance) -> (),
	SetupProximityPrompt: (self: BoatInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: BoatInstance, proximityPrompt: ProximityPrompt) -> (),
	UpdateBillboardGUI: (self: BoatInstance) -> (),

	-- Visibility and Collision
	Show: (self: BoatInstance) -> (),
	Hide: (self: BoatInstance) -> (),
	CanCollide: (self: BoatInstance) -> (),
	CannotCollide: (self: BoatInstance) -> (),

	-- Utilities
	GetName: (self: BoatInstance) -> string,
	CanUpgrade: (self: BoatInstance) -> boolean,
	IsStorageFull: (self: BoatInstance) -> boolean,

	-- Cleaner Service
	_cleaner: (any) -> any,

	-- Saving and Loading
	Serialize: (self: BoatInstance) -> { [string]: any },
	Save: (self: BoatInstance) -> (),
}

export type Boat = {
	New: (props: BoatProps, player: Player, model: Model) -> BoatInstance,
}

return BoatType
