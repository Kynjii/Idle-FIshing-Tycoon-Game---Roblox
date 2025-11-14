local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Fish = require(ServerScriptService.Server.Classes.Fish)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(ReplicatedStorage.Shared.Events.Events)

local FishDexManager = {}
FishDexManager.__index = FishDexManager

type FishDexManager = {
	Player: Player,
	Owner: number,
	TeamId: number,
	RealmId: number,
	_cleaner: any,
	AttachAttListeners: () -> (),
	Destroy: (self: FishDexManager) -> (),
}

function FishDexManager.New(fishDexState, player: Player, teamId: number, currentRealm: number)
	local self = setmetatable({}, FishDexManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.RealmId = currentRealm

	self.FishDexState = fishDexState
	self._cleaner = Trove.new()

	self:AttachAttListeners()

	return self
end

function FishDexManager.CheckCaughtStatus(self: FishDexManager, caughtFish: Fish.Fish)
	local existing = TableUtil.Find(self.FishDexState, function(fish): boolean
		local speciesName = fish.Species
		local variant = fish.Variant

		return speciesName == caughtFish.Species and variant == caughtFish.Variant
	end)

	if existing and existing.Caught then
		return true
	else
		return false
	end
end

function FishDexManager.UpdateCaughtStatus(self: FishDexManager, caughtFish: Fish.Fish)
	local existing = TableUtil.Find(self.FishDexState, function(fish): boolean
		local speciesName = fish.Species
		local variant = fish.Variant

		return speciesName == caughtFish.Species and variant == caughtFish.Variant
	end)

	if existing then existing.Caught = true end

	self:Save()
end

function FishDexManager.AttachAttListeners(self: FishDexManager)
	local caughtFishEvent = Events.GetRemote(Events.RemoteNames.FishCaught)
	if caughtFishEvent then
		self._cleaner:Add(caughtFishEvent.OnServerEvent:Connect(function(player: Player, fish: Fish.Fish)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			local hasCaught = self:CheckCaughtStatus(fish)
			if hasCaught then return end

			self:UpdateCaughtStatus(fish)
		end))
	end
end

function FishDexManager.Save(self: FishDexManager)
	DataService.SaveFishDex(self.Player, self.FishDexState)
end

-- //SECTION - Cleanup
function FishDexManager.Destroy(self: FishDexManager)
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self:Save()

	self.Player = nil
	self.Owner = nil
end
-- //!SECTION

return FishDexManager
