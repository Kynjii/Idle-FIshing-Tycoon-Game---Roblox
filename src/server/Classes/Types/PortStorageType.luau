local PortStorageType = {}

export type StorageProps = {
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
	GrowthRate: number,
	CostGrowthRate: number,
}

export type StorageInstance = {
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
	GrowthRate: number,
	CostGrowthRate: number,

	-- (Not-Saved to DataStore) Props
	Model: Model,
	VisualRoot: Part,
	Player: Player,
	VisualModels: { [string]: Model },
	CurrentVisualModel: Model | nil,

	-- Core Boat Actions
	Purchase: (self: StorageInstance) -> (),
	Upgrade: (self: StorageInstance) -> (),
	IncreaseUpgradeStage: (self: StorageInstance, stage: number) -> (),

	-- Calculations
	CalculateBaseCost: (self: StorageInstance) -> number,
	CalculateUpgradeCost: (self: StorageInstance) -> number,
	CalculateBaseStorage: (self: StorageInstance) -> number,
	CalculateMaxStorage: (self: StorageInstance) -> (number, number),

	-- Storage Actions
	AddFish: (self: StorageInstance, amount: number) -> (),
	RemoveFish: (self: StorageInstance, amount: number) -> (),
	UpdateStorageStatus: (self: StorageInstance, status: boolean) -> (),

	-- UI Setup
	Initialize: (self: StorageInstance) -> (),
	SetupPurchaseBoard: (self: StorageInstance) -> Part,
	UpdatePurchaseBoardUI: (self: StorageInstance) -> (),
	SetupProximityPrompt: (self: StorageInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: StorageInstance, proximityPrompt: ProximityPrompt) -> (),

	-- Visibility and Collision
	Show: (self: StorageInstance) -> (),
	Hide: (self: StorageInstance) -> (),
	CanCollide: (self: StorageInstance) -> (),
	CannotCollide: (self: StorageInstance) -> (),

	-- Utilities
	GetName: (self: StorageInstance) -> string,
	CanUpgrade: (self: StorageInstance) -> boolean,
	IsStorageFull: (self: StorageInstance) -> boolean,
	ShowUpgradeStageUpgrade: (self: StorageInstance) -> boolean,

	-- Models
	UpdateVisualModel: (self: StorageInstance) -> (),
	GetVisualModels: (self: StorageInstance) -> { [string]: Model },
	RemovePreviousVisualModel: (self: StorageInstance) -> (),

	-- Cleaner Service
	_cleaner: (any) -> any,

	-- Saving and Loading
	Serialize: (self: StorageInstance) -> { [string]: any },
	Save: (self: StorageInstance) -> (),

	-- Cleanup
	ClearAllAttributes: (self: StorageInstance, instance: Instance) -> (),
	Destroy: (self: StorageInstance) -> (),
}

export type Storage = {
	New: (props: StorageProps, player: Player, model: Model) -> StorageInstance,
}

return PortStorageType
