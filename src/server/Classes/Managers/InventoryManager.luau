local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local InventoryManager = {}
InventoryManager.__index = InventoryManager

type InventoryManager = typeof(setmetatable({}, InventoryManager))

function InventoryManager.New(InventoryState: { HelperType.HelperData }, player: Player, teamId: number): InventoryManager
	local self = setmetatable({} :: InventoryManager, InventoryManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Inventory = InventoryState or {}

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function InventoryManager.AttachEventListeners(self: InventoryManager)
	local getPlayerInventoryEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
	if getPlayerInventoryEvent then
		getPlayerInventoryEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			print(self.Player, player)
			self.Inventory = DataService.GetPlayerInventory(self.Player)
			return self.Inventory
		end
		self._cleaner:Add(getPlayerInventoryEvent)
	end
end

-- //SECTION - Cleanup
function InventoryManager.Destroy(self: InventoryManager): ()
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
end
-- //!SECTION

return InventoryManager
