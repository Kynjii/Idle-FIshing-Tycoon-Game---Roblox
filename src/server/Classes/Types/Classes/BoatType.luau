local ServerScriptService = game:GetService("ServerScriptService")
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local BoatType = {}

export type BoatProps = {
	Entity: string,
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
	Entity: string,

	-- (Not-Saved to DataStore) Props
	Model: Model,
	VisualRoot: Part,
	FishingInterval: thread,
	Player: Player,
	Animations: { [string]: Animation },
	VisualModels: { [string]: Model },
	CurrentVisualModel: Model | nil,
	Buffs: { [string]: Buffs.BuffState },
	PurchaseBoard: Model,
	PBDetails: { [string]: TextLabel | Frame },
	Description: string,

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
	RecalculateAll: (self: BoatInstance) -> (),

	-- Fishing
	StartFishing: (self: BoatInstance) -> (),
	AddFish: (self: BoatInstance, amount: number) -> (),
	RemoveFish: (self: BoatInstance, amount: number) -> (),
	UpdateStorageStatus: (self: BoatInstance, status: boolean) -> (),

	-- UI Setup
	Initialize: (self: BoatInstance) -> (),
	SetupPurchaseBoard: (self: BoatInstance) -> Model,
	UpdatePurchaseBoardUI: (self: BoatInstance) -> (),
	SetupProximityPrompt: (self: BoatInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: BoatInstance, proximityPrompt: ProximityPrompt) -> (),
	ShowFishPopUp: (self: BoatInstance) -> (),

	-- Buffs
	GetBuffs: (self: BoatInstance) -> { [string]: Buffs.BuffState },
	UpdateBuffs: (self: BoatInstance) -> (),

	-- Visibility and Collision
	Show: (self: BoatInstance) -> (),
	Hide: (self: BoatInstance) -> (),
	CanCollide: (self: BoatInstance) -> (),
	CannotCollide: (self: BoatInstance) -> (),

	-- Utilities
	GetName: (self: BoatInstance) -> string,
	CanUpgrade: (self: BoatInstance) -> boolean,
	IsStorageFull: (self: BoatInstance) -> boolean,
	ShowUpgradeStageUpgrade: (self: BoatInstance) -> boolean,

	-- Animations
	StartAnimation: (self: BoatInstance) -> (),

	-- Models
	UpdateVisualModel: (self: BoatInstance) -> (),
	GetVisualModels: (self: BoatInstance) -> { [string]: Model },
	RemovePreviousVisualModel: (self: BoatInstance) -> (),

	-- Cleaner Service
	_cleaner: (any) -> any,

	-- Saving and Loading
	Serialize: (self: BoatInstance) -> { [string]: any },
	Save: (self: BoatInstance) -> (),

	-- Cleanup
	ClearAllAttributes: (self: BoatInstance, instance: Instance) -> (),
	Destroy: (self: BoatInstance) -> (),
}

export type Boat = {
	New: (props: BoatProps, player: Player, model: Model) -> BoatInstance,
}

return BoatType
