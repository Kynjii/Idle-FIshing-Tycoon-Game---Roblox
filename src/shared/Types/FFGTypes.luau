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

export type BoatClass = BoatState & {
	-- Constructor
	New: (self: BoatClass, state: BoatState, ownerId: number, model: Model, currentrealm: number?) -> BoatClass,

	-- Core boat actions
	Purchase: (self: BoatClass) -> (),
	Upgrade: (self: BoatClass) -> (),

	-- Calculations
	CalculateBaseCost: (self: BoatClass) -> number,
	CalculateUpgradeCost: (self: BoatClass) -> number,
	GetMaxStorage: (self: BoatClass) -> number,

	-- Visibility and collision
	Hide: (self: BoatClass) -> (),
	CannotCollide: (self: BoatClass) -> (),
	Show: (self: BoatClass) -> (),
	CanCollide: (self: BoatClass) -> (),

	-- UI Setup (new methods)
	Initialize: (self: BoatClass) -> (),
	SetupPurchaseBoard: (self: BoatClass) -> Part,
	SetupProximityPrompt: (self: BoatClass, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: BoatClass, proximityPrompt: ProximityPrompt) -> (),

	-- Utilities
	GetName: (self: BoatClass) -> string,
}

export type GameSave = {
	CurrentRealm: number,
	Realms: {
		[number]: {
			isUnlocked: boolean,
			Boats: {},
		},
	},
	Currencies: {
		Gold: number,
	},
}

return {}
