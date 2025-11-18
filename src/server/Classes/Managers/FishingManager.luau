local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Fish = require(ServerScriptService.Server.Classes.Fish)
local Notification = require(ServerScriptService.Server.Classes.Modules.Notification)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)

-- //SECTION - Tagged Fishing Locations within Workspace
local taggedFishingLocs = CollectionService:GetTagged("FishingLocation")
-- //!SECTION

local FishingManager = {}
FishingManager.__index = FishingManager

type FishingManager = {
	Player: Player,
	Owner: number,
	TeamId: number,
	RealmId: number,
	CurrentFishingLocTier: number,
	FishingLocations: { Instance },
	GeneratedFish: { [string]: any },
	_cleaner: any,
	GetLocations: (self: FishingManager) -> { Instance },
	GetRandomFish: (self: FishingManager) -> any,
	SaveCaughtFish: (self: FishingManager, caughtFishId: string) -> (),
	GetPlayerRod: (self: FishingManager) -> { Name: string, QualityId: number, BaseDmg: number },
	SetupProximityPrompts: (self: FishingManager) -> (),
	AttachAttListeners: (self: FishingManager) -> (),
	Destroy: (self: FishingManager) -> (),
}

function FishingManager.New(player: Player, teamId: number, currentRealm: number)
	local self = setmetatable({}, FishingManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.RealmId = currentRealm
	self.CurrentFishingLocTier = 1
	self.FishingLocations = self:GetLocations()
	self.GeneratedFish = {}

	self._cleaner = Trove.new()

	self:SetupProximityPrompts()

	self:AttachAttListeners()

	return self
end

function FishingManager.GetLocations(self: FishingManager)
	local locations = {}

	local index = 1
	for _, location in pairs(taggedFishingLocs) do
		local taggedLocationTeamId = location:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedLocationTeamId and taggedLocationTeamId ~= self.TeamId then continue end

		locations[index] = location
		index += 1
	end

	return locations
end

function FishingManager.GetRandomFish(self: FishingManager, fishingLocTier: number)
	local fish = Fish.New({}, self.Player, self.TeamId, fishingLocTier, self.RealmId)
	if fish then self.GeneratedFish[fish.Id] = fish end
	return fish
end

function FishingManager.SaveCaughtFish(self: FishingManager, caughtFish: Fish.Fish)
	if not self.GeneratedFish[caughtFish.Id] then return end

	local fish = self.GeneratedFish[caughtFish.Id]
	fish:Save()

	local updateCaughtFishEvent = Events.GetBindableEvent(Events.BindableNames.UpdateCaughtFish)
	if updateCaughtFishEvent then updateCaughtFishEvent:Fire({ Fish = fish:Serialize(), Player = self.Player }) end

	Notification.SendSuccess(self.Player, `You caught a {fish.Name}`)
end

function FishingManager.GetPlayerRod(self: FishingManager)
	return { Name = "Fishing Rod of Doom", QualityId = 1, BaseDmg = 10 }
end

function FishingManager.SetupProximityPrompts(self: FishingManager)
	for _, location in pairs(self.FishingLocations) do
		local taggedLocationTeamId = location:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedLocationTeamId ~= self.TeamId then continue end

		local taggedLocationTier = location:GetAttribute(FFGEnum.ATTRIBUTES.Tier)

		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ObjectText = `Tier {taggedLocationTier}`
		proximityPrompt.ActionText = "Begin Fishing"
		proximityPrompt:SetAttribute(FFGEnum.ATTRIBUTES.Tier, taggedLocationTier)
		proximityPrompt.Parent = location

		self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			self.CurrentFishingLocTier = taggedLocationTier

			Events.FireEvent(Events.RemoteNames.StartFishingMiniGame, player, { Fish = self:GetRandomFish(taggedLocationTier, self.RealmId), Rod = self:GetPlayerRod(), Tier = taggedLocationTier })

			proximityPrompt.Enabled = false
		end))

		local gameEndedEvent = Events.GetRemote(Events.RemoteNames.GameEnded)
		if gameEndedEvent then
			self._cleaner:Add(gameEndedEvent.OnServerEvent:Connect(function(player: Player, tier: number)
				if self.Player ~= player or self.Owner ~= player.UserId then return end

				local promptTier = proximityPrompt:GetAttribute(FFGEnum.ATTRIBUTES.Tier)

				if tier ~= promptTier then return end

				proximityPrompt.Enabled = true
			end))
		end
	end
end

function FishingManager.AttachAttListeners(self: FishingManager)
	local getFishItemEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishItem)
	if getFishItemEvent then
		getFishItemEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			return { Fish = self:GetRandomFish(self.CurrentFishingLocTier, self.RealmId), Rod = self:GetPlayerRod() }
		end
		self._cleaner:Add(getFishItemEvent)
	end

	local caughtFishEvent = Events.GetRemote(Events.RemoteNames.FishCaught)
	if caughtFishEvent then
		self._cleaner:Add(caughtFishEvent.OnServerEvent:Connect(function(player: Player, fish: Fish.Fish)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			self:SaveCaughtFish(fish)
		end))
	end
end

-- //SECTION - Cleanup
function FishingManager.Destroy(self: FishingManager)
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
end
-- //!SECTION

return FishingManager
