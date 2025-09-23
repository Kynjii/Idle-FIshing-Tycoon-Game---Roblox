local ServerScriptService = game:GetService("ServerScriptService")
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local TenderType = {}

export type TenderProps = {
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
	BaseTravelTime: number,
	CurrentTravelTime: number,
	NextLvlTravelTime: number,
	GrowthRate: number,
	CostGrowthRate: number,
	Entity: string,

	-- (Not-Saved to DataStore) Props
	Model: Model,
	PortPos: CFrame,
	BillBoard: BillboardGui,
	ProgressBar: Frame,
	Player: Player,
	ProgressTween: Tween | nil,
	MoveTween: Tween | nil,
	Animations: { [string]: Animation },
	VisualModels: { [string]: Model },
	CurrentVisualModel: Model | nil,
	Buffs: { [string]: Buffs.BuffState },
	LoadTime: number?,
	PBDetails: { [string]: TextLabel | Frame },
	Description: string,

	-- Core Tender Actions
	Purchase: (self: TenderInstance) -> (),
	Upgrade: (self: TenderInstance) -> (),
	IncreaseUpgradeStage: (self: TenderInstance, stage: number) -> (),

	-- Calculations
	CalculateBaseCost: (self: TenderInstance) -> number,
	CalculateUpgradeCost: (self: TenderInstance) -> number,
	CalculateBaseStorage: (self: TenderInstance) -> number,
	CalculateMaxStorage: (self: TenderInstance) -> (number, number),
	CalculateTravelTime: (self: TenderInstance) -> number,
	CalculateLoadTime: (self: TenderInstance) -> number,
	RecalculateAll: (self: TenderInstance) -> (),

	-- Travelling
	MoveToBoat: (self: TenderInstance, position: Vector3) -> (),
	MoveToPort: (self: TenderInstance) -> (),
	StartLoadingFish: (self: TenderInstance) -> (),
	AddFish: (self: TenderInstance, amount: number) -> boolean,
	RemoveFish: (self: TenderInstance, amount: number) -> boolean,
	UpdateStorageStatus: (self: TenderInstance, status: boolean) -> (),
	UpdateProgressBar: (self: TenderInstance) -> (),
	AttachAttListeners: (self: TenderInstance) -> (),

	-- Buffs
	GetBuffs: (self: TenderInstance) -> { [string]: Buffs.BuffState },
	UpdateBuffs: (self: TenderInstance) -> (),

	-- Setup
	Initialize: (self: TenderInstance) -> (),
	SetupPurchaseBoard: (self: TenderInstance) -> Model,
	UpdatePurchaseBoardUI: (self: TenderInstance) -> (),
	SetupProximityPrompt: (self: TenderInstance, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: TenderInstance, proximityPrompt: ProximityPrompt) -> (),
	ShowFishPopUp: (self: TenderInstance) -> (),

	-- Visibility and Collision
	Show: (self: TenderInstance) -> (),
	Hide: (self: TenderInstance) -> (),
	CanCollide: (self: TenderInstance) -> (),
	CannotCollide: (self: TenderInstance) -> (),
	ShowProgressBar: (self: TenderInstance) -> (),
	HideProgressBar: (self: TenderInstance) -> (),

	-- Utilities
	GetName: (self: TenderInstance) -> string,
	CanUpgrade: (self: TenderInstance) -> boolean,
	IsStorageFull: (self: TenderInstance) -> boolean,
	ShowUpgradeStageUpgrade: (self: TenderInstance) -> boolean,

	-- Animation
	StartAnimation: (self: TenderInstance) -> (),

	-- Models
	UpdateVisualModel: (self: TenderInstance) -> (),
	GetVisualModels: (self: TenderInstance) -> { [string]: Model },
	RemovePreviousVisualModel: (self: TenderInstance) -> (),

	-- Saving and Loading
	Serialize: (self: TenderInstance) -> { [string]: any },
	Save: (self: TenderInstance) -> (),

	-- Cleanup
	ClearAllAttributes: (self: TenderInstance, instance: Instance) -> (),
	Destroy: (self: TenderInstance) -> (),
}

export type Tender = {
	New: (props: TenderProps, player: Player, model: Model) -> TenderInstance,
}

return TenderType
