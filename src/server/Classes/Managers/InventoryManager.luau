local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Fish = require(ServerScriptService.Server.Classes.Fish)
local Emitter = require(ServerScriptService.Server.Modules.Emitters.Emitter)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)

local InventoryManager = {}
InventoryManager.__index = InventoryManager

type InventoryManager = typeof(setmetatable({}, InventoryManager))

function InventoryManager.New(InventoryState, player: Player, teamId: number): InventoryManager
	local self = setmetatable({} :: InventoryManager, InventoryManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Inventory = InventoryState or {}
	self.PlayerInventory = self:SetupInventory()

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function InventoryManager.SetupInventory(self: InventoryManager): { [any]: any }
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = self.Player

	for _, item in pairs(self.Inventory.Fish) do
		self:GrantTool(item)
	end

	for _, item in pairs(self.Inventory.Equipment) do
		self:GrantTool(item)
	end

	return inventory
end

function InventoryManager.RestoreInventoryToBackpack(self: InventoryManager)
	local backpack = self.Player:WaitForChild("Backpack")
	local inventory = self.Player:WaitForChild("Inventory")

	for _, tool in ipairs(inventory:GetChildren()) do
		local toolCopy = tool:Clone()
		toolCopy.Parent = backpack
	end
end

function InventoryManager.AttachEventListeners(self: InventoryManager)
	Players.PlayerAdded:Connect(function(player)
		if self.Player ~= player then return end

		player.CharacterAdded:Connect(function(character)
			self:RestoreInventoryToBackpack()
		end)
	end)

	local caughtFishEvent = Events.GetRemote(Events.RemoteNames.FishCaught)
	if caughtFishEvent then
		self._cleaner:Add(caughtFishEvent.OnServerEvent:Connect(function(player: Player, fish: Fish.Fish)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			self:GrantTool(fish)
		end))
	end
end

function InventoryManager.GrantTool(self: InventoryManager, item)
	local toolName = item.SpeciesKey or item.NameKey
	local toolTemplate = ServerStorage.Tools:FindFirstChild(toolName)
	if not toolTemplate then return end

	local invTool: Tool = toolTemplate:Clone()
	invTool.Parent = self.Player.Inventory

	local runtimeTool: Tool = invTool:Clone()
	runtimeTool.Parent = self.Player.Backpack

	if item.Variant == FishData.FISH_VARIANT.ELEMENTAL then
		local elementName = item.ElementName

		if elementName then
			Emitter.AttachElement(invTool.Handle or invTool:FindFirstChild("Handle"), elementName)
			Emitter.AttachElement(runtimeTool.Handle or runtimeTool:FindFirstChild("Handle"), elementName)

			invTool.ToolTip = item.Name
			runtimeTool.ToolTip = item.Name

			-- //TODO -  Change image to correct quality and image
		end
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
