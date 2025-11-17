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
	print(fishDexState)
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

	print(self.FishDexState, existing)

	if existing and existing.Caught then
		return true
	else
		return false
	end
end

function FishDexManager.UpdateCaughtStatus(self: FishDexManager, caughtFish: Fish.Fish)
	local hasCaught = self:CheckCaughtStatus(caughtFish)
	if hasCaught then return end

	local existing = TableUtil.Find(self.FishDexState, function(fish): boolean
		local speciesName = fish.Species
		local variant = fish.Variant

		return speciesName == caughtFish.Species and variant == caughtFish.Variant
	end)
	print(existing)
	if existing then
		TableUtil.Reconcile(existing, caughtFish)
		existing.Caught = true
	end

	print(existing)

	self:Save()

	Events.FireEvent(Events.RemoteNames.LootNotification, self.Player, { ItemType = "Fishing", Text = `Added {caughtFish.Name} to FishDex` })
end

function FishDexManager.AttachAttListeners(self: FishDexManager)
	local getFishDexFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishDex)
	if getFishDexFn then getFishDexFn.OnServerInvoke = function(player: Player)
		if self.Player ~= player or self.Owner ~= player.UserId then return end

		return self.FishDexState
	end end
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
