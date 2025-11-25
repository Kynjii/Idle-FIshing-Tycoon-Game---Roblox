local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Fish = require(ServerScriptService.Server.Classes.Fish)
local Emitter = require(ServerScriptService.Server.Modules.Emitters.Emitter)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)

local InventoryManager = {}
InventoryManager.__index = InventoryManager

type InventoryManager = typeof(setmetatable(
	{} :: {
		Player: Player,
		Owner: number,
		TeamId: number,
		Inventory: { [any]: any },
		_cleaner: any,
	},
	InventoryManager
))

function InventoryManager.New(InventoryState, player: Player, teamId: number): InventoryManager
	local self = setmetatable({}, InventoryManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Inventory = InventoryState or {}
	self:SetupInventory()

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

	local caughtFishEvent = Events.GetBindableEvent(Events.BindableNames.FishCaught)
	if caughtFishEvent then
		self._cleaner:Add(caughtFishEvent.Event:Connect(function(data: { Player: Player, Fish: Fish.Fish })
			if self.Player ~= data.Player or self.Owner ~= data.Player.UserId then return end
			self:GrantTool(data.Fish)
			self.Inventory[data.Fish.Id] = data.Fish
		end))
	end

	local getPlayerInventoryEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
	if getPlayerInventoryEvent then
		getPlayerInventoryEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			return self.Inventory
		end

		self._cleaner:Add(getPlayerInventoryEvent)
	end

	local sellInventoryItemEvent = Events.GetRemote(Events.RemoteNames.SellItem)
	if sellInventoryItemEvent then
		self._cleaner:Add(sellInventoryItemEvent.OnServerEvent:Connect(function(player: Player, item)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if not self.Inventory[item.Id] then return end

			print(`Found the item: {self.Inventory[item.Id]}`)
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

	invTool.ToolTip = item.Name or item.Species
	runtimeTool.ToolTip = item.Name or item.Species

	local image = nil
	if item.Variant == FFGEnum.FISH_VARIANT.NORMAL then
		image = FishData.FISH_ASSETS[item.SpeciesKey].Normal[item.QualityId]
	elseif item.Variant == FFGEnum.FISH_VARIANT.ELEMENTAL then
		image = FishData.FISH_ASSETS[item.SpeciesKey].Elemental[item.RealmId or item.ElementNum or 1][item.QualityId]
		local elementName = item.ElementName
		if elementName then
			Emitter.AttachElement(invTool.Handle or invTool:FindFirstChild("Handle"), elementName, item.QualityId)
			Emitter.AttachElement(runtimeTool.Handle or runtimeTool:FindFirstChild("Handle"), elementName, item.QualityId)
		end
	elseif item.Variant == FFGEnum.FISH_VARIANT.ELDER then
		image = FishData.FISH_ASSETS[item.SpeciesKey].Elder[item.QualityId]
	else
		image = FishData.FISH_ASSETS[item.SpeciesKey].Basic
	end

	if image then
		invTool.TextureId = image
		runtimeTool.TextureId = image
	end
end

-- //SECTION - Cleanup
function InventoryManager.Destroy(self: InventoryManager): ()
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
	self.TeamId = nil
	self.Inventory = nil
	self.PlayerInventory = nil
end
-- //!SECTION

return InventoryManager
