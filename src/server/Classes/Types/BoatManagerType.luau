local BoatType = require(script.Parent.BoatType)
local TenderType = require(script.Parent.TenderType)
local BoatManagerType = {}

export type BoatManagerInstance = {
	-- Props
	Owner: number,
	Tier: number,
	BoatModel: Model,
	LaneBoat: BoatType.BoatInstance,
	TenderModel: Model,
	LaneTender: TenderType.TenderInstance,
	Player: Player,

	-- Main Actions
	FindBoatModel: (self: BoatManagerInstance, player: Player, tier: number) -> Model | nil,
	FindTenderModel: (self: BoatManagerInstance, player: Player, tier: number) -> Model | nil,
	Initialize: (self: BoatManagerInstance) -> (),

	-- Attribute listeners
	AttachAttListeners: (self: BoatManagerInstance) -> (),

	-- Handling Tender Service
	StartTenderCycle: (self: BoatManagerInstance, bool: boolean?) -> (),
	StartLoadingFish: (self: BoatManagerInstance) -> (),
	StartUnloadingFish: (self: BoatManagerInstance) -> (),

	ResetTravellingAttributes: (self: BoatManagerInstance) -> (),
}

export type BoatManager = {
	New: (boatProps: BoatType.BoatProps, tenderProps: TenderType.TenderProps, player: Player, model: Model) -> BoatManagerInstance,
}

return BoatManagerType
