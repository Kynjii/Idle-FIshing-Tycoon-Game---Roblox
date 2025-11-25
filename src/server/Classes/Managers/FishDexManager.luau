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

function FishDexManager.New(fishDexState, player: Player, teamId: number, currentRealm: number): FishDexManager
	local self = setmetatable({} :: FishDexManager, FishDexManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.RealmId = currentRealm

	self.FishDexState = fishDexState
	self._cleaner = Trove.new()

	self:AttachAttListeners()

	return self
end

local function findExistingFish(fishDexState, caughtFish)
	local existingFish = TableUtil.Find(fishDexState, function(fish): boolean
		local speciesName = fish.Species
		local variant = fish.Variant

		return speciesName == caughtFish.Species and variant == caughtFish.Variant
	end)

	if existingFish then
		return existingFish
	else
		return false
	end
end

function FishDexManager.CheckCaughtStatus(self: FishDexManager, caughtFish: Fish.Fish)
	local existing = findExistingFish(self.FishDexState, caughtFish)

	if existing and existing.Caught then
		return true
	else
		return false
	end
end

function FishDexManager.UpdateCaughtStatus(self: FishDexManager, caughtFish: Fish.Fish)
	local hasCaught = self:CheckCaughtStatus(caughtFish)
	if hasCaught then return end

	local existing = findExistingFish(self.FishDexState, caughtFish)

	if existing then
		TableUtil.Reconcile(existing, caughtFish)
		existing.Caught = true
	end

	self:Save()

	Events.FireEvent(Events.RemoteNames.LootNotification, self.Player, { ItemImage = "Fishing", Text = `Added {caughtFish.Name} to FishDex` })
end

function FishDexManager.AttachAttListeners(self: FishDexManager)
	local getFishDexFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishDex)
	if getFishDexFn then
		getFishDexFn.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			return self.FishDexState
		end
		self._cleaner:Add(getFishDexFn)
	end

	local updateInfoPanel = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanel then
		self._cleaner:Add(updateInfoPanel.OnServerEvent:Connect(function(player: Player, fish: Fish.Fish)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			local existing = findExistingFish(self.FishDexState, fish)
			if existing then Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, existing) end
		end))
	end

	local updateCaughtFishEvent = Events.GetBindableEvent(Events.BindableNames.UpdateCaughtFish)
	if updateCaughtFishEvent then
		self._cleaner:Add(updateCaughtFishEvent.Event:Connect(function(data: { Fish: Fish.Fish, Player: Player })
			if self.Player ~= data.Player or self.Owner ~= data.Player.UserId then return end

			self:UpdateCaughtStatus(data.Fish)
		end))
	end
end

function FishDexManager.Save(self: FishDexManager)
	DataService.SaveFishDex(self.Player, self.FishDexState)
end

-- //SECTION - Cleanup
function FishDexManager.Destroy(self: FishDexManager)
	print(self.FishDexState)
	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
	self.TeamId = nil
	self.RealmId = nil
end
-- //!SECTION

return FishDexManager
