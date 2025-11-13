local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)

-- //SECTION - Tagged Fishing Locations within Workspace
local taggedFishingLocs = CollectionService:GetTagged("FishingLocation")
-- //!SECTION

local FishingManager = {}
FishingManager.__index = FishingManager

-- number index for testing, use proper random algo (use helper quality algo)
local fishArray = {
	[1] = {
		Name = "Flynn",
		QualityId = 1,
		MaxHP = 100,
	},
	[2] = {
		Name = "Lucy",
		QualityId = 2,
		MaxHP = 150,
	},
	[3] = {
		Name = "Imke",
		QualityId = 3,
		MaxHP = 200,
	},
	[4] = {
		Name = "Dean",
		QualityId = 4,
		MaxHP = 250,
	},
	[5] = {
		Name = "Charlie",
		QualityId = 5,
		MaxHP = 300,
	},
	[6] = {
		Name = "Luey",
		QualityId = 6,
		MaxHP = 400,
	},
}

type FishingManager = typeof(setmetatable({}, FishingManager))

function FishingManager.New(player: Player, teamId: number)
	local self = setmetatable({}, FishingManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.FishingLocations = self:GetLocations()

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

function FishingManager.GetRandomFish(self: FishingManager)
	return fishArray[math.random(1, #fishArray)]
end

function FishingManager.GetPlayerRod(self: FishingManager)
	return { Name = "Fishing Rod of Doom", QualityId = 1, BaseDmg = 10 }
end

function FishingManager.SetupProximityPrompts(self: FishingManager)
	for _, location in pairs(self.FishingLocations) do
		local taggedLocationTeamId = location:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ObjectText = `Tier {taggedLocationTeamId}`
		proximityPrompt.ActionText = "Begin Fishing"
		proximityPrompt.Parent = location

		self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			Events.FireEvent(Events.RemoteNames.StartFishingMiniGame, player, { Fish = self:GetRandomFish(), Rod = self:GetPlayerRod() })
		end))
	end
end

function FishingManager.AttachAttListeners(self: FishingManager)
	local getFishItemEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishItem)
	if getFishItemEvent then
		getFishItemEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			return { Fish = self:GetRandomFish(), Rod = self:GetPlayerRod() }
		end
		self._cleaner:Add(getFishItemEvent)
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
