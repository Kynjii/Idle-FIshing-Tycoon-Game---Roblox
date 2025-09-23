local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.Classes.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.Classes.TenderType)
local ChainManagerType = {}

export type ChainManagerInstance = {
	-- Props
	Owner: number,
	Tier: number,
	BoatModel: Model,
	LaneBoat: BoatType.BoatInstance,
	TenderModel: Model,
	LaneTender: TenderType.TenderInstance,
	LaneStorageModel: Model,
	LaneStorage: { [string]: any },
	Player: Player,
	TeamId: number,

	-- Derived Props
	Buildings: { [number]: { [string]: any } },

	-- Main Actions
	FindBoatModel: (self: ChainManagerInstance, player: Player, tier: number) -> Model | nil,
	FindTenderModel: (self: ChainManagerInstance, player: Player, tier: number) -> Model | nil,
	FindStorageModel: (self: ChainManagerInstance, player: Player, tier: number) -> Model | nil,
	Initialize: (self: ChainManagerInstance) -> (),

	-- Attribute listeners
	AttachAttListeners: (self: ChainManagerInstance) -> (),

	-- Building Events
	HandleBuildingEvent: (self: ChainManagerInstance) -> (),

	-- Handling Tender Service
	StartTenderCycle: (self: ChainManagerInstance) -> (),
	StartLoadingFish: (self: ChainManagerInstance) -> (),
	StartUnloadingFish: (self: ChainManagerInstance) -> (),

	ResetTravellingAttributes: (self: ChainManagerInstance) -> (),

	-- Cleanup
	Destroy: (self: ChainManagerInstance) -> (),
}

export type ChainManager = {
	New: (realmData: { [string]: any }, tier: number, player: Player, teamId: number, buildingClasses: { [number]: { [string]: any } }) -> ChainManagerInstance,
}

return ChainManagerType
