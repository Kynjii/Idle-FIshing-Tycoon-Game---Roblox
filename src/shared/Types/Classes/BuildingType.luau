local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local BuffType = require(ReplicatedStorage.Shared.Types.BuffType)
local BuildingType = {}

export type BuildingProps = {
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
	BaseTravelTime: number,
	CurrentTravelTime: number,
	NextLvlTravelTime: number,
	GrowthRate: number,
	CostGrowthRate: number,
	Description: string,
	BuildingName: string,
}

export type BuildingInstance = {
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
	GrowthRate: number,
	CostGrowthRate: number,
	Entity: string,
	BuildingName: string,

	-- (Not-Saved to DataStore) Props
	Model: Model,
	Player: Player,
	VisualModels: { [string]: Model },
	CurrentVisualModel: Model | nil,
	BuildingId: number,
	Description: string,
	PurchaseBoard: Model,
	BuildingBuff: { BuffType.BuffState },
	PBDetails: { [string]: TextLabel | ImageLabel },

	-- Core Building Actions
	Purchase: (self: BuildingInstance) -> (),
	Upgrade: (self: BuildingInstance) -> (),
	IncreaseUpgradeStage: (self: BuildingInstance, stage: number) -> (),

	-- Calculations
	CalculateBaseCost: (self: BuildingInstance) -> number,
	CalculateUpgradeCost: (self: BuildingInstance) -> number,

	-- Buffs
	UpdateBuffValue: (self: BuildingInstance) -> (),

	-- Setup
	Initialize: (self: BuildingInstance) -> (),
	SetupPurchaseBoard: (self: BuildingInstance) -> Model,
	UpdatePurchaseBoardUI: (self: BuildingInstance) -> (),
	SetupProximityPrompt: (self: BuildingInstance, purchaseBoard: Part) -> ProximityPrompt,

	-- Visibility and Collision
	Show: (self: BuildingInstance) -> (),
	Hide: (self: BuildingInstance) -> (),
	CanCollide: (self: BuildingInstance) -> (),
	CannotCollide: (self: BuildingInstance) -> (),

	-- Utilities
	GetName: (self: BuildingInstance) -> string,
	CanUpgrade: (self: BuildingInstance) -> boolean,

	-- Event Listeners
	AttachEventListeners: (self: BuildingInstance) -> (),

	-- Signals
	Upgraded: Signal.Connection,
	Purchased: Signal.Connection,

	-- Models
	UpdateVisualModel: (self: BuildingInstance) -> (),
	GetVisualModels: (self: BuildingInstance) -> { [string]: Model },
	RemovePreviousVisualModel: (self: BuildingInstance) -> (),

	-- Saving and Loading
	Serialize: (self: BuildingInstance) -> { [string]: any },
	Save: (self: BuildingInstance) -> (),

	-- Cleanup
	ClearAllAttributes: (self: BuildingInstance, instance: Instance) -> (),
	Destroy: (self: BuildingInstance) -> (),
}

export type Building = {
	New: (props: BuildingProps, player: Player, model: Model) -> BuildingInstance,
}

return BuildingType
