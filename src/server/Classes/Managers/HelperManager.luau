local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local HelperManager = {}
HelperManager.__index = HelperManager

type HelperManager = typeof(setmetatable({}, HelperManager))

function HelperManager.New(InventoryState: { HelperType.HelperData }, player: Player, teamId: number): HelperManager
	local self = setmetatable({} :: HelperManager, HelperManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Inventory = InventoryState or {}

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function HelperManager.AttachEventListeners(self: HelperManager)
	local getHelperInventoryEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetHelperInventory)
	if getHelperInventoryEvent then
		getHelperInventoryEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			self.Inventory = DataService.GetHelperInventory(self.Player)
			return self.Inventory
		end
		self._cleaner:Add(getHelperInventoryEvent)
	end

	-- //TODO - Add event for getting infopanel update etc.
end

-- //SECTION - Cleanup
function HelperManager.Destroy(self: HelperManager): ()
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
	self.TeamId = nil
end
-- //!SECTION

return HelperManager
