local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Boat: Boat = require(ServerScriptService.Server.Classes.Boat)
local Tender: Tender = require(ServerScriptService.Server.Classes.Tender)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)

local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")

type Boat = BoatType.Boat
type Tender = TenderType.Tender

local BoatManager = {}
BoatManager.__index = BoatManager

function BoatManager.New(playerState, tier, player: Player)
	local self = setmetatable({}, BoatManager)

	self.Tier = tier
	self.BoatModel = self:FindBoatModel(player, tier) :: Model
	self.LaneBoat = Boat.New(playerState, player, self.BoatModel)

	self.TenderModel = self:FindTenderModel(player, tier)
	self.LaneTender = Tender.New(playerState, player, self.TenderModel)

	return self
end

function BoatManager:FindBoatModel(player, tier)
	for _, taggedBoat in ipairs(taggedBoats) do
		local taggedBoatTier = taggedBoat:GetAttribute("Tier")
		if taggedBoatTier == tier then return taggedBoat end
	end

	return nil
end

function BoatManager:FindTenderModel(player, tier)
	for _, taggedTender in ipairs(taggedTenders) do
		local taggedTenderTier = taggedTender:GetAttribute("Tier")
		if taggedTenderTier == tier then return taggedTender end
	end

	return nil
end

return BoatManager
