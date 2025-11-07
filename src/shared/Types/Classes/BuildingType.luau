local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local BuildingType = {}

export type BuildingData = {
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
	IsPurchased: boolean,
	UpgradeStage: number,
	Description: string,
	Model: Model,
	Player: Player,
	BaseStorage: number?,
	CurrentMaxStorage: number?,
	NextLvlMaxStorage: number?,
	FishInStorage: number?,
	StorageFull: boolean?,
	BaseTravelTime: number?,
	CurrentTravelTime: number?,
	NextLvlTravelTime: number?,
	BuildingBuff: any?,
	GrowthRate: number?,
	CostGrowthRate: number?,
	BuildingName: string?,
	BuildingId: number?,
	VisualRoot: any,
	VisualModels: { [number]: Model }?,
	CurrentVisualModel: Model?,
	purchaseButton: Model,
	PBDetails: { [string]: any }?,
	_cleaner: any?,
	Buffs: { [string]: any },
	-- Signals
	Upgraded: typeof(Signal.new())?,
	Purchased: typeof(Signal.new())?,
}

export type BuildingInstance = {
	-- Essential Properties (accessed by other modules)
	Entity: string,
	Owner: string,
	Level: number,
	Tier: number,
	UpgradeStage: number,
	IsPurchased: boolean,
	FishInStorage: number?,
	CurrentMaxStorage: number?,
	PBDetails: { [string]: any }?,
	BuildingBuff: { CurrentValue: number? }?,

	-- Essential Methods (called by other modules)
	Initialize: (self: BuildingInstance) -> (),
	Destroy: (self: BuildingInstance) -> (),

	-- Allow any other properties/methods for internal use
	[string]: any,
} & BuildingData

export type BuildingModule = {
	New: (state: { [string]: any }?, player: Player, model: Model) -> BuildingInstance,
}

return BuildingType
