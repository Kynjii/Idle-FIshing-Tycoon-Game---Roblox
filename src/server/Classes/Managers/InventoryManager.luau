local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Fish = require(ServerScriptService.Server.Classes.Fish)
local FishingRods = require(ServerScriptService.Server.Data.FishingRods)
local Emitter = require(ServerScriptService.Server.Modules.Emitters.Emitter)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)
local RodType = require(ReplicatedStorage.Shared.Types.RodType)
local Format = require(ReplicatedStorage.Shared.Utils.Format)

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
		self:GrantTool(item, "Fish")
	end

	for _, item in pairs(self.Inventory.Equipment) do
		self:GrantTool(item, "Equipment")
	end

	return inventory
end

function InventoryManager.RemoveTool(self: InventoryManager, item, type: "Equipment" | "Fish")
	local existing = self.Inventory[type][item.Id]
	if existing then
		self.Inventory[type][item.Id] = nil

		local backpack = self.Player:WaitForChild("Backpack")
		local inventory = self.Player:WaitForChild("Inventory")

		local backpackItem = backpack:FindFirstChild(item.Id)
		if backpackItem then backpackItem:Destroy() end

		local inventoryItem = inventory:FindFirstChild(item.Id)
		if inventoryItem then inventoryItem:Destroy() end

		Events.FireEvent(Events.RemoteNames.UpdateMarketUI, self.Player, item.Id)
	end
end

function InventoryManager.RemoveManyTools(self: InventoryManager, items)
	-- //TODO -
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

			local fishCopy = TableUtil.Copy(data.Fish, true)
			self:GrantTool(fishCopy, "Fish")
			self.Inventory.Fish[fishCopy.Id] = fishCopy
		end))
	end

	local updateInfoPanel = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanel then
		self._cleaner:Add(updateInfoPanel.OnServerEvent:Connect(function(player: Player, data: { Item: Fish.Fish, isFishDex: boolean? })
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if data.isFishDex then return end

			local existing = self.Inventory.Fish[data.Item.Id]
			if existing then Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, { Item = existing }) end
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

			local itemType = item.Entity
			if itemType == "Fish" then
				if not self.Inventory.Fish[item.Id] then return end
			end

			if itemType == "Equipment" then
				if not self.Inventory.Equipment[item.Id] then return end
			end

			local sellAmount = item.SellPrice
			if sellAmount then DataService.Earn(player, "Gold", tonumber(Format.CurrencyNumber(sellAmount, true)), "SoldFish", item) end

			self:RemoveTool(item, itemType)
		end))
	end

	local rodPurchasedEvent = Events.GetBindableEvent(Events.BindableNames.PurchasedRod)
	if rodPurchasedEvent then
		self._cleaner:Add(rodPurchasedEvent.Event:Connect(function(playerData: { Player: Player, Rod: RodType.FishingRodType })
			local player = playerData.Player
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			local rodKey = playerData.Rod and playerData.Rod.Key
			if self.Inventory.Equipment[rodKey] then return end

			local associatedRod = TableUtil.Find(FishingRods, function(rod)
				return rod.Id == playerData.Rod.Id
			end)

			local rodCopy = nil
			if associatedRod then
				rodCopy = TableUtil.Copy(associatedRod, true)
				self.Inventory.Equipment[rodCopy.Key] = rodCopy
			else
				error(`No Fishing Rod found with id of: {playerData.Rod.Id}`)
			end

			self:SaveRod(self.Inventory.Equipment[rodCopy])

			if rodCopy then self:GrantTool(rodCopy, "Equipment") end
		end))
	end
end

function InventoryManager.SaveRod(self: InventoryManager, rod)
	if not rod then return end

	DataService.SaveRod(self.Player, rod)
end

function InventoryManager.GrantTool(self: InventoryManager, item, type: "Equipment" | "Fish")
	local toolName = nil
	if type == "Fish" then
		toolName = item.SpeciesKey or item.NameKey
	else
		toolName = item.Id
	end

	local toolTemplate = nil
	if type == "Fish" then
		toolTemplate = ServerStorage.FishTools:FindFirstChild(toolName)
	else
		toolTemplate = ServerStorage.RodTools:FindFirstChild(toolName)
	end

	if not toolTemplate then return end

	local invTool: Tool = toolTemplate:Clone()
	invTool.Parent = self.Player.Inventory

	local runtimeTool: Tool = invTool:Clone()
	runtimeTool.Parent = self.Player.Backpack

	if type == "Equipment" then
		runtimeTool.Equipped:Connect(function()
			Events.FireBindableEvent(Events.BindableNames.EquippedRod, { Player = self.Player, RodId = tonumber(runtimeTool.Name) })
		end)

		runtimeTool.Unequipped:Connect(function()
			Events.FireBindableEvent(Events.BindableNames.EquippedRod, { Player = self.Player, RodId = nil })
		end)
	end

	if type == "Fish" then
		invTool.ToolTip = item.Name or item.Species
		invTool.Name = item.Id
		runtimeTool.ToolTip = item.Name or item.Species
		runtimeTool.Name = item.Id

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
