export type BoatState = {
	Id: string,
	Level: number,
	Tier: number,
	RealmId: number,
	BaseCost: number,
	UpgradeCost: number?,
	isPurchased: boolean,
	isActive: boolean,
	Name: string?,
	Owner: number?,
	MaxLevel: number,
	UpgradeStage: number,
	CurrentMaxStorage: number?,
	NextLvlMaxStorage: number?,
	FPS: number?,
	FishInStorage: number?,
	StorageFull: boolean,
	GrowthRate: number,
	CostGrowthRate: number,
	BaseFPS: number,
	BaseStorage: number,
}

export type BoatInstance = BoatState & {
	-- Constructor
	New: (self: BoatInstance, state: BoatState, ownerId: number, model: Model, currentrealm: number?) -> BoatInstance,

	-- Core boat actions
	Purchase: (self: BoatInstance) -> (),
	Upgrade: (self: BoatInstance) -> (),

	-- Calculations
	CalculateBaseCost: (self: BoatInstance) -> number,
	CalculateUpgradeCost: (self: BoatInstance) -> number,
	GetMaxStorage: (self: BoatInstance) -> number,

	-- Visibility and collision
	Hide: (self: BoatInstance) -> (),
	CannotCollide: (self: BoatInstance) -> (),
	Show: (self: BoatInstance) -> (),
	CanCollide: (self: BoatInstance) -> (),

	-- UI Setup (new methods)
	Initialize: (self: BoatInstance) -> (),
	SetupPurchaseBoard: (self: BoatInstance) -> Part,
	SetupProximityPrompt: (self: BoatInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: BoatInstance, proximityPrompt: ProximityPrompt) -> (),

	-- Utilities
	GetName: (self: BoatInstance) -> string,
}

return {}
